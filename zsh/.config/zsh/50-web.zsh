# ── Web apps: app launcher ───────────────────────────────────
#
#   app                 pick an app → new tmux window in its folder, started
#   app ls              list registered apps
#   app up|down|logs|cd <name>
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
      pick=$(app ls | fzf --prompt='app ❯ ' --height=50% \
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
