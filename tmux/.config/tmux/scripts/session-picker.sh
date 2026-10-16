#!/usr/bin/env bash
# Switch / kill tmux sessions with fzf (ctrl-x kills).
set -euo pipefail

sel=$(tmux list-sessions -F "#{session_name}  #{session_windows}w#{?session_attached, (attached),}" |
  grep -v "^_scratch" |
  fzf --prompt="  " --height=100% --reverse --border=none \
    --header="enter: switch · ctrl-x: kill" \
    --bind="ctrl-x:execute-silent(tmux kill-session -t {1})+reload(tmux list-sessions -F '#{session_name}  #{session_windows}w')" \
    --preview="tmux capture-pane -ep -t {1}" --preview-window=right:55%) || exit 0

tmux switch-client -t="${sel%%  *}"
