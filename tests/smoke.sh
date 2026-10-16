#!/usr/bin/env bash
# Post-install checks. Run after ./install.sh (or container/install.sh):
#   ~/dotfiles/tests/smoke.sh
set -uo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
LOG="$(mktemp)"
fail=0

check() {
  local name=$1
  shift
  if "$@" >"$LOG" 2>&1; then
    printf '  \033[32m✓\033[0m %s\n' "$name"
  else
    printf '  \033[31m✗\033[0m %s\n' "$name"
    sed 's/^/      /' "$LOG" | tail -25
    fail=1
  fi
}

echo "==> dotfiles smoke test"
check "configs are linked" test -L "$HOME/.config/nvim" -a -L "$HOME/.config/tmux" -a -L "$HOME/.zshrc"
for bin in nvim tmux zsh git fzf starship zoxide lazygit; do
  check "$bin installed" command -v "$bin"
done
check "tmux config loads" tmux -L dotfiles-smoke -f "$HOME/.config/tmux/tmux.conf" new-session -d ';' kill-server
check "tmux status segments" bash -c '
  s="$HOME/.config/tmux/scripts/status.sh"
  [[ -n "$("$s" cpu)" && -n "$("$s" mem)" ]]'
check "zsh starts with helpers" zsh -ic 'for f in ros cb cbp tros trobot dsh sall plug; do whence -w $f >/dev/null || exit 1; done'
echo "==> neovim"
NVIM_OFFLINE=1 nvim --headless "+lua dofile('$DOTFILES/tests/smoke.lua')" 2>&1 || fail=1

rm -f "$LOG"
if ((fail)); then
  echo "==> FAILED"
  exit 1
fi
echo "==> all good"
