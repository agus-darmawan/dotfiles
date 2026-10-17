# ── Web apps: app launcher, Cloudflare Tunnel, PM2 ───────────
#
#   app                 pick an app → new tmux window in its folder, started
#   app ls              list registered apps
#   app up|down|logs|cd <name>
#
#   tun                 tunnel status + hostname → service routes
#   tun add <host> <port|url>   add a route, create the DNS record, restart
#   tun rm <host>       remove a route, restart
#   tun share <port>    temporary public URL for a local port (trycloudflare)
#   tun log | restart | edit | test <host>
#
# Apps are registered in ~/.config/apps (see templates/apps.example):
#   name   folder   [command]
# Without a command the folder decides: ecosystem.config.* → PM2,
# compose file → docker compose, package.json → <pm> dev.

APPS_FILE=${APPS_FILE:-$XDG_CONFIG_HOME/apps}

_apps() { [[ -f $APPS_FILE ]] && awk '!/^[[:space:]]*(#|$)/' "$APPS_FILE" }

# app name → APP_DIR, APP_CMD, APP_KIND
_app_resolve() {
  local line
  line=$(_apps | awk -v n="$1" '$1 == n {print; exit}')
  if [[ -z $line ]]; then
    print -u2 "app: '$1' is not in $APPS_FILE"
    return 1
  fi
  local -a f=(${(z)line})
  APP_DIR=${f[2]/#\~/$HOME}
  APP_CMD=${(j: :)f[3,-1]}
  [[ -d $APP_DIR ]] || { print -u2 "app: folder $APP_DIR does not exist"; return 1 }

  local -a pm2f=($APP_DIR/ecosystem.config.(js|cjs|json)(N))
  local -a composef=($APP_DIR/(docker-|)compose.y(a|)ml(N))
  if [[ -n $APP_CMD ]]; then APP_KIND=cmd
  elif (( $#pm2f )); then APP_KIND=pm2 APP_PM2=${pm2f[1]:t}
  elif (( $#composef )); then APP_KIND=compose
  elif [[ -f $APP_DIR/package.json ]]; then APP_KIND=node
  else APP_KIND=shell; fi
}

_app_node_cmd() {
  if [[ -f $1/pnpm-lock.yaml ]]; then echo "pnpm dev"
  elif [[ -f $1/bun.lock || -f $1/bun.lockb ]]; then echo "bun run dev"
  elif [[ -f $1/yarn.lock ]]; then echo "yarn dev"
  else echo "npm run dev"; fi
}

# the command that starts the app (and, for background services, follows its logs)
_app_start_cmd() {
  case $APP_KIND in
    cmd) echo "$APP_CMD" ;;
    pm2) echo "pm2 start $APP_PM2 && pm2 logs --lines 50" ;;
    compose) echo "docker compose up -d && docker compose logs -f --tail 100" ;;
    node) _app_node_cmd "$APP_DIR" ;;
    shell) echo "" ;;
  esac
}

app() {
  local sub=${1:-} name=${2:-}
  case $sub in
    ls)
      [[ -f $APPS_FILE ]] || { echo "no apps yet: cp ~/dotfiles/templates/apps.example $APPS_FILE"; return 1 }
      local n
      for n in $(_apps | awk '{print $1}'); do
        if _app_resolve $n 2>/dev/null; then
          printf "%-16s %-8s %s\n" $n $APP_KIND "${APP_DIR/#$HOME/~}"
        else
          printf "%-16s %-8s %s\n" $n missing "-"
        fi
      done
      ;;
    up)
      _app_resolve "${name:?usage: app up <name>}" || return
      case $APP_KIND in
        pm2) (cd $APP_DIR && pm2 start $APP_PM2) ;;
        compose) (cd $APP_DIR && docker compose up -d) ;;
        shell) echo "app: nothing to start in $APP_DIR (add a command in $APPS_FILE)" ;;
        *) (cd $APP_DIR && eval "$(_app_start_cmd)") ;;
      esac
      ;;
    down)
      _app_resolve "${name:?usage: app down <name>}" || return
      case $APP_KIND in
        pm2) (cd $APP_DIR && pm2 stop $APP_PM2) ;;
        compose) (cd $APP_DIR && docker compose down) ;;
        *) echo "app: $name runs in the foreground — stop it with Ctrl-C in its window" ;;
      esac
      ;;
    logs)
      _app_resolve "${name:?usage: app logs <name>}" || return
      case $APP_KIND in
        pm2) pm2 logs --lines 100 ;;
        compose) (cd $APP_DIR && docker compose logs -f --tail 200) ;;
        *) echo "app: $name logs are in its window" ;;
      esac
      ;;
    cd)
      _app_resolve "${name:?usage: app cd <name>}" && cd $APP_DIR
      ;;
    "")
      [[ -f $APPS_FILE ]] || { app ls; return 1 }
      local pick
      local -a look=(--height=50%)
      [[ -n $TMUX_POPUP ]] && look=(--height=100% --border=none)  # C-a a popup
      pick=$(app ls | fzf --prompt='app ❯ ' $look \
        --header='enter: open in a new tmux window' \
        --preview='d=$(echo {} | awk "{print \$3}"); eval ls -la "$d" 2>/dev/null | head -30' | awk '{print $1}') || return
      [[ -n $pick ]] && app open $pick
      ;;
    open)
      _app_resolve "${name:?usage: app open <name>}" || return
      local cmd
      cmd=$(_app_start_cmd)
      if [[ -n $TMUX ]]; then
        if [[ -n $cmd ]]; then
          tmux new-window -n $name -c $APP_DIR "zsh -ic '$cmd'; exec zsh"
        else
          tmux new-window -n $name -c $APP_DIR
        fi
      else
        cd $APP_DIR && [[ -n $cmd ]] && eval "$cmd"
      fi
      ;;
    *)
      app open $sub
      ;;
  esac
}

# ── Cloudflare Tunnel ────────────────────────────────────────
CF_CONFIG=${CLOUDFLARED_CONFIG:-$HOME/.cloudflared/config.yml}

_tun_name() { awk -F': *' '$1 == "tunnel" {print $2; exit}' "$CF_CONFIG" }
_tun_routes() {
  awk '/^[[:space:]]*-[[:space:]]*hostname:/ {h=$3}
       /^[[:space:]]*service:/ && h != "" {print h "\t" $2; h=""}' "$CF_CONFIG"
}
_tun_validate() { cloudflared tunnel --config "$CF_CONFIG" ingress validate >/dev/null }

_tun_restart() {
  local cmd=${CLOUDFLARED_RESTART:-}
  if [[ -z $cmd ]]; then
    if [[ $OSTYPE == darwin* ]]; then cmd="sudo brew services restart cloudflared"
    else cmd="sudo systemctl restart cloudflared"; fi
  fi
  echo "→ $cmd"
  eval "$cmd"
}

_tun_add() {
  local host=${1:?usage: tun add <hostname> <port|url>} target=${2:?usage: tun add <hostname> <port|url>}
  [[ $target == <-> ]] && target="http://localhost:$target"
  if _tun_routes | awk -v h="$host" '$1 == h {f=1} END {exit !f}'; then
    print -u2 "tun: $host is already routed"; return 1
  fi
  cp "$CF_CONFIG" "$CF_CONFIG.bak"
  awk -v h="$host" -v s="$target" '
    !done && /^[[:space:]]*-[[:space:]]*service:[[:space:]]*http_status/ {
      match($0, /^[[:space:]]*/); ind = substr($0, 1, RLENGTH)
      print ind "- hostname: " h; print ind "  service: " s; done = 1
    }
    {print}
    END {exit !done}' "$CF_CONFIG.bak" >"$CF_CONFIG" || {
    cp "$CF_CONFIG.bak" "$CF_CONFIG"
    print -u2 "tun: no catch-all rule (- service: http_status:404) in $CF_CONFIG"; return 1
  }
  if ! _tun_validate; then
    cp "$CF_CONFIG.bak" "$CF_CONFIG"
    print -u2 "tun: config invalid after the change, restored"; return 1
  fi
  echo "✓ $host → $target"
  cloudflared tunnel route dns "$(_tun_name)" "$host" || print -u2 "tun: DNS record not created (check cert.pem / the zone)"
  _tun_restart
}

_tun_rm() {
  local host=${1:?usage: tun rm <hostname>}
  cp "$CF_CONFIG" "$CF_CONFIG.bak"
  awk -v h="$host" '
    function indent(s) { match(s, /^[[:space:]]*/); return RLENGTH }
    skip && (indent($0) > ind || $0 ~ /^[[:space:]]*$/) { next }
    { skip = 0 }
    $1 == "-" && $2 == "hostname:" && $3 == h { skip = 1; ind = indent($0); found = 1; next }
    {print}
    END {exit !found}' "$CF_CONFIG.bak" >"$CF_CONFIG" || {
    cp "$CF_CONFIG.bak" "$CF_CONFIG"
    print -u2 "tun: $host not found"; return 1
  }
  _tun_validate || { cp "$CF_CONFIG.bak" "$CF_CONFIG"; print -u2 "tun: config invalid, restored"; return 1 }
  echo "✓ removed $host (delete its DNS record in the Cloudflare dashboard if no longer needed)"
  _tun_restart
}

_tun_log() {
  local f
  for f in ${HOMEBREW_PREFIX:-/opt/homebrew}/var/log/cloudflared.log \
    /Library/Logs/com.cloudflare.cloudflared.err.log /var/log/cloudflared.log; do
    [[ -r $f ]] && { tail -n 100 -f "$f"; return }
  done
  (( $+commands[journalctl] )) && { journalctl -u cloudflared -f; return }
  print -u2 "tun: no cloudflared log found"
}

tun() {
  (( $+commands[cloudflared] )) || { print -u2 "cloudflared is not installed (brew install cloudflared)"; return 1 }
  case ${1:-} in
    share) cloudflared tunnel --url "http://localhost:${2:?usage: tun share <port>}" ;;
    add) _tun_add "$2" "$3" ;;
    rm) _tun_rm "$2" ;;
    restart) _tun_restart ;;
    log) _tun_log ;;
    edit) ${EDITOR:-nvim} "$CF_CONFIG" ;;
    test) cloudflared tunnel --config "$CF_CONFIG" ingress rule "https://${2:?usage: tun test <hostname>}" ;;
    ""|ls|status)
      if pgrep -x cloudflared >/dev/null; then print -P "%F{green}●%f cloudflared running"
      else print -P "%F{red}●%f cloudflared not running"; fi
      if [[ -f $CF_CONFIG ]]; then
        echo "tunnel: $(_tun_name)   config: ${CF_CONFIG/#$HOME/~}"
        _tun_routes | awk -F'\t' '{printf "  %-36s → %s\n", $1, $2}'
      else
        echo "no config at $CF_CONFIG (set CLOUDFLARED_CONFIG)"
      fi
      ;;
    *) echo "usage: tun [ls|add|rm|share|log|restart|edit|test]"; return 1 ;;
  esac
}

# ── PM2 ──────────────────────────────────────────────────────
if (( $+commands[pm2] )); then
  alias pml='pm2 ls'
  alias pmlog='pm2 logs --lines 100'
  alias pmr='pm2 restart'
  alias pms='pm2 save'
fi
