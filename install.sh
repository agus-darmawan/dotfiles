#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  agus-darmawan/dotfiles — macOS installer
#
#  ./install.sh              full install (brew bundle + symlinks + plugins)
#  ./install.sh --no-brew    symlinks + plugins only
#  ./install.sh --link       symlinks only
#  ./install.sh --unlink     remove symlinks
# ─────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PACKAGES=(ghostty zsh tmux nvim starship git lazygit)
BACKUP="$HOME/.dotfiles-backup/$(date +%Y%m%d-%H%M%S)"

c_blue=$'\033[34m' c_green=$'\033[32m' c_yellow=$'\033[33m' c_red=$'\033[31m' c_off=$'\033[0m'
step() { printf "\n%s==>%s %s\n" "$c_blue" "$c_off" "$*"; }
ok() { printf "  %s✓%s %s\n" "$c_green" "$c_off" "$*"; }
warn() { printf "  %s!%s %s\n" "$c_yellow" "$c_off" "$*"; }
die() { printf "%s✗ %s%s\n" "$c_red" "$*" "$c_off" >&2; exit 1; }

DO_BREW=1 DO_PLUGINS=1 MODE=install
case "${1:-}" in
  --no-brew) DO_BREW=0 ;;
  --link) DO_BREW=0 DO_PLUGINS=0 ;;
  --unlink) MODE="unlink" ;;
  "") ;;
  *) die "unknown option: $1" ;;
esac

[[ $(uname -s) == Darwin ]] || warn "Not macOS — for Linux/containers use container/install.sh"

if [[ $MODE == unlink ]]; then
  step "Removing symlinks"
  stow -d "$DOTFILES" -t "$HOME" -D "${PACKAGES[@]}"
  ok "done"
  exit 0
fi

# ── Homebrew ─────────────────────────────────────────────────
if ((DO_BREW)); then
  step "Homebrew"
  if ! command -v brew >/dev/null 2>&1; then
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
  fi
  if brew bundle --file "$DOTFILES/Brewfile"; then
    ok "packages installed"
  else
    warn "some packages failed — re-run: brew bundle --file ~/dotfiles/Brewfile"
  fi
fi

command -v stow >/dev/null 2>&1 || die "GNU stow missing (brew install stow)"

# ── Backup conflicting files, then link ─────────────────────
step "Linking configs → \$HOME"
mkdir -p "$HOME/.config"
backup() { # move a real (non-symlink) path out of the way
  local rel=$1
  if [[ -e $HOME/$rel && ! -L $HOME/$rel ]]; then
    mkdir -p "$BACKUP/$(dirname "$rel")"
    mv "$HOME/$rel" "$BACKUP/$rel"
    warn "backed up ~/$rel"
  fi
}
# whole config dirs (avoid mixing old + new nvim plugins etc.)
for d in ghostty tmux nvim zsh lazygit git; do backup ".config/$d"; done
backup ".zshrc"
backup ".config/starship.toml"
stow -d "$DOTFILES" -t "$HOME" --restow "${PACKAGES[@]}"
ok "linked: ${PACKAGES[*]}"
[[ -d $BACKUP ]] && warn "old files saved in $BACKUP"

# ── macOS terminfo for tmux (system ncurses lacks tmux-256color) ──
if ! infocmp tmux-256color >/dev/null 2>&1; then
  for ic in /opt/homebrew/opt/ncurses/bin/infocmp /usr/local/opt/ncurses/bin/infocmp; do
    if [[ -x $ic ]]; then
      "$ic" -x tmux-256color >/tmp/tmux-256color.info && tic -x -o "$HOME/.terminfo" /tmp/tmux-256color.info &&
        ok "installed tmux-256color terminfo"
      break
    fi
  done
fi

# ── SSH skeleton ─────────────────────────────────────────────
step "SSH"
mkdir -p "$HOME/.ssh/sockets" "$HOME/.ssh/config.d"
chmod 700 "$HOME/.ssh"
if [[ ! -f $HOME/.ssh/config ]]; then
  cp "$DOTFILES/ssh/config.example" "$HOME/.ssh/config"
  chmod 600 "$HOME/.ssh/config"
  ok "created ~/.ssh/config (multiplexing on)"
else
  grep -q "config.d" "$HOME/.ssh/config" || warn "add 'Include ~/.ssh/config.d/*' at the top of ~/.ssh/config"
fi
for f in robots containers; do
  [[ -f $HOME/.ssh/config.d/$f ]] && continue
  cp "$DOTFILES/ssh/config.d/$f.example" "$HOME/.ssh/config.d/$f"
  ok "created ~/.ssh/config.d/$f — edit hosts and ports there"
done

# ── App list for `app` ───────────────────────────────────────
if [[ ! -f $HOME/.config/apps ]]; then
  cp "$DOTFILES/templates/apps.example" "$HOME/.config/apps"
  ok "created ~/.config/apps — list your web apps there"
fi

# ── Plugins ──────────────────────────────────────────────────
if ((DO_PLUGINS)); then
  step "zsh plugins"
  zsh -ic 'exit 0' >/dev/null 2>&1 && ok "fzf-tab, autosuggestions, syntax-highlighting" || warn "open a new shell to finish"

  step "Neovim plugins (first run takes a minute)"
  if command -v nvim >/dev/null 2>&1; then
    nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 && ok "plugins installed at the versions in lazy-lock.json" || warn "open nvim once to finish"
  fi

  if command -v bat >/dev/null 2>&1; then
    bat cache --build >/dev/null 2>&1 || true
  fi
fi

[[ ${SHELL:-} == */zsh ]] || warn "default shell is $SHELL — run: chsh -s $(command -v zsh)"

step "Done 🚀"
cat <<EOF
  1. Open Ghostty (font + theme are already set)
  2. Run: t          → tmux session 'main' (status bar on top)
  3. In tmux: C-a f  → sessionizer · C-a S → ssh picker · C-a d → docker shell
  4. nvim            → Mason installs LSPs in the background (:Mason)
  5. Read docs/TUTORIAL.md
EOF
