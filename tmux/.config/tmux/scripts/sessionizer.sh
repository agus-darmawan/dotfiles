#!/usr/bin/env bash
# Fuzzy-pick a project dir → create/switch to a tmux session named after it.
#
# Search roots: $TMUX_SESSIONIZER_PATHS (space separated) or sensible defaults.

set -euo pipefail

roots=()
if [[ -n ${TMUX_SESSIONIZER_PATHS:-} ]]; then
  read -r -a roots <<<"$TMUX_SESSIONIZER_PATHS"
else
  for d in "$HOME/apps" "$HOME/web" "$HOME/Projects" "$HOME/projects" "$HOME/dev" "$HOME/workspace" \
    "$HOME/Developer" "$HOME/ros2_ws" "$HOME/dotfiles" "$HOME/Documents/GitHub"; do
    [[ -d $d ]] && roots+=("$d")
  done
fi

list() {
  # existing sessions first
  tmux list-sessions -F "  #{session_name}" 2>/dev/null | grep -v "_scratch" || true
  ((${#roots[@]})) || return 0
  if command -v fd >/dev/null 2>&1; then
    fd . "${roots[@]}" --type d --max-depth 2 --min-depth 1 --exclude node_modules \
      --exclude build --exclude install --exclude log 2>/dev/null
  else
    find "${roots[@]}" -mindepth 1 -maxdepth 2 -type d -not -path '*/.*' 2>/dev/null
  fi
  printf '%s\n' "${roots[@]}"
}

if [[ $# -eq 1 ]]; then
  sel=$1
else
  sel=$(list | awk '!seen[$0]++' | sed "s|^$HOME|~|" | fzf \
    --prompt="  " --height=100% --reverse --border=none \
    --preview='p={}; p=${p/#\~/$HOME}; [[ -d $p ]] && (eza -1 --icons --group-directories-first "$p" 2>/dev/null || ls -1 "$p") || tmux capture-pane -ep -t "${p#  }" 2>/dev/null' \
    --preview-window=right:45%) || exit 0
fi

# existing session?
if [[ $sel == "  "* ]]; then
  name=${sel#  }
else
  dir=${sel/#\~/$HOME}
  name=$(basename "$dir" | tr '.:' '__')
  if ! tmux has-session -t="$name" 2>/dev/null; then
    tmux new-session -d -s "$name" -c "$dir"
  fi
fi

if [[ -n ${TMUX:-} ]]; then
  tmux switch-client -t="$name"
else
  tmux attach -t="$name"
fi
