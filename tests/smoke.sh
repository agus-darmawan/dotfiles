#!/usr/bin/env bash
# Post-install checks. Run after ./install.sh (or container/install.sh):
#   ~/dotfiles/tests/smoke.sh
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$(mktemp)"
NVIM_LOG="$(mktemp)"
fail=0

# failures also become GitHub Actions annotations (visible in the run summary)
annotate() {
  [[ -n ${GITHUB_ACTIONS:-} ]] || return 0
  local msg=$2
  msg=${msg//'%'/'%25'}
  msg=${msg//$'\r'/'%0D'}
  msg=${msg//$'\n'/'%0A'}
  echo "::error title=$1::$msg"
}

check() {
  local name=$1
  shift
  if "$@" >"$LOG" 2>&1; then
    printf '  \033[32m✓\033[0m %s\n' "$name"
  else
    printf '  \033[31m✗\033[0m %s\n' "$name"
    sed 's/^/      /' "$LOG" | tail -25
    annotate "smoke: $name" "$(tail -15 "$LOG")"
    fail=1
  fi
}

tmux_config() {
  local rc=0
  tmux -L dotfiles-smoke -f /dev/null new-session -d ';' source-file "$HOME/.config/tmux/tmux.conf" || rc=1
  tmux -L dotfiles-smoke kill-server 2>/dev/null
  return $rc
}

echo "==> dotfiles smoke test"
check "configs are linked" test -L "$HOME/.config/nvim" -a -L "$HOME/.config/tmux" -a -L "$HOME/.zshrc"
for bin in nvim tmux zsh git fzf starship zoxide lazygit; do
  check "$bin installed" command -v "$bin"
done
check "tmux config loads without errors" tmux_config
check "tmux status segments" bash -c '
  s="$HOME/.config/tmux/scripts/status.sh"
  [[ -n "$("$s" cpu)" && -n "$("$s" mem)" ]]'
check "zsh starts with helpers" zsh -ic 'for f in app dev dsh sall plug; do whence -w $f >/dev/null || exit 1; done'
if [[ -d /opt/ros ]]; then
  check "zsh ROS helpers" zsh -ic 'for f in ros rosws cb cbp ct rtopic rnode; do whence -w $f >/dev/null || exit 1; done'
else
  check "no ROS helpers outside ROS machines" zsh -ic '! whence -w ros >/dev/null'
fi

echo "==> neovim"
nvim_rc=0
NVIM_OFFLINE=1 nvim --headless "+lua dofile('$DOTFILES/tests/smoke.lua')" >"$NVIM_LOG" 2>&1 || nvim_rc=1
cat "$NVIM_LOG"
if grep -q "✗" "$NVIM_LOG"; then
  nvim_rc=1
  annotate "smoke: neovim" "$(grep -A8 "✗" "$NVIM_LOG" | head -60)"
elif ((nvim_rc)); then
  annotate "smoke: neovim" "$(tail -15 "$NVIM_LOG")"
fi
((nvim_rc)) && fail=1

rm -f "$LOG" "$NVIM_LOG"
if ((fail)); then
  echo "==> FAILED"
  exit 1
fi
echo "==> all good"
