# ── SSH ──────────────────────────────────────────────────────
#   s            fuzzy pick host (enter=new tmux window, ctrl-v split, ctrl-o here)
#   dev <host>   tmux session for a host: windows code / build / run, all over SSH
#   sall <hosts> one tmux window, one pane per host, panes synced
#   sfwd host p  forward remote port p → localhost:p (web dashboards, foxglove)

alias s='~/.config/tmux/scripts/ssh-picker.sh'

dev() {
  local host=${1:?usage: dev <ssh-host>}
  if ! tmux has-session -t="$host" 2>/dev/null; then
    tmux new-session -d -s "$host" -n code "ssh $host"
    tmux new-window -d -t "$host:" -n build "ssh $host"
    tmux new-window -d -t "$host:" -n run "ssh $host"
  fi
  if [[ -n $TMUX ]]; then tmux switch-client -t="$host"; else tmux attach -t="$host"; fi
}

sall() {
  (( $# )) || { echo "usage: sall host1 host2 ..."; return 1; }
  [[ -n $TMUX ]] || { echo "run inside tmux"; return 1; }
  tmux new-window -n multi "ssh $1"
  shift
  local h
  for h in "$@"; do tmux split-window "ssh $h"; tmux select-layout tiled; done
  tmux setw synchronize-panes on
}

sfwd() {
  local host=${1:?usage: sfwd <host> <port> [local_port]} port=${2:?port} lport=${3:-$2}
  echo "localhost:$lport → $host:$port  (ctrl-c to stop)"
  ssh -N -L $lport:localhost:$port $host
}

# copy my pubkey to a robot
skey() { ssh-copy-id -i ~/.ssh/id_ed25519.pub ${1:?usage: skey <host>}; }

[[ -d ~/.ssh/sockets ]] || mkdir -p ~/.ssh/sockets 2>/dev/null
