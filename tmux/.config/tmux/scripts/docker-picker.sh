#!/usr/bin/env bash
# Pick a running container and open a shell in it (zsh > bash > sh).
#   enter  → new tmux window   ctrl-v → vsplit   ctrl-o → here
set -euo pipefail

command -v docker >/dev/null || { echo "docker not found"; sleep 1; exit 1; }

out=$(docker ps --format '{{.Names}}\t{{.Image}}\t{{.Status}}' |
  column -t -s $'\t' |
  fzf --prompt="  " --height=100% --reverse --border=none \
    --expect=ctrl-v,ctrl-o \
    --header="enter: window · ctrl-v: vsplit · ctrl-o: here" \
    --preview='docker logs --tail 40 {1} 2>&1' --preview-window=down:45%) || exit 0

key=$(head -1 <<<"$out")
name=$(tail -1 <<<"$out" | awk '{print $1}')
[[ -z $name ]] && exit 0

cmd="$HOME/.config/tmux/scripts/denter.sh $name"
if [[ -z ${TMUX:-} || $key == ctrl-o ]]; then exec $cmd; fi
case "$key" in
  ctrl-v) tmux split-window -h "$cmd" ;;
  *) tmux new-window -n " $name" "$cmd" ;;
esac
