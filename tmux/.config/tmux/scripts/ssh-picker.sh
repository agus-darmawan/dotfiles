#!/usr/bin/env bash
# Pick a host from ~/.ssh/config (+ config.d/*) and connect.
#   enter   → new tmux window named after the host
#   ctrl-v  → vertical split in current window
#   ctrl-s  → horizontal split
#   ctrl-o  → connect in this pane (outside tmux: always this)
set -euo pipefail

hosts() {
  local files=("$HOME/.ssh/config")
  [[ -d $HOME/.ssh/config.d ]] && files+=("$HOME"/.ssh/config.d/*)
  awk 'tolower($1)=="host" {for (i=2;i<=NF;i++) if ($i !~ /[*?!]/) print $i}' "${files[@]}" 2>/dev/null | awk '!seen[$0]++'
}

out=$(hosts | fzf --prompt="󰣀  " --height=100% --reverse --border=none \
  --expect=ctrl-v,ctrl-s,ctrl-o \
  --header="enter: window · ctrl-v: vsplit · ctrl-s: split · ctrl-o: here" \
  --preview='ssh -G {} 2>/dev/null | grep -E "^(hostname|user|port|identityfile|proxyjump) " | column -t' \
  --preview-window=right:50%) || exit 0

key=$(head -1 <<<"$out")
host=$(tail -1 <<<"$out")
[[ -z $host ]] && exit 0

if [[ -z ${TMUX:-} || $key == ctrl-o ]]; then
  exec ssh "$host"
fi

case "$key" in
  ctrl-v) tmux split-window -h "ssh $host" ;;
  ctrl-s) tmux split-window -v "ssh $host" ;;
  *) tmux new-window -n "󰣀 $host" "ssh $host" ;;
esac
