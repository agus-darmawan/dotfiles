#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────
#  Linux / dev-container / Jetson installer (Ubuntu 20.04+ · x86_64 & arm64)
#  ROS 1 Noetic (20.04) and ROS 2 Humble/Jazzy containers; tmux stays on the Mac.
#
#  Inside the container (dotfiles mounted at ~/dotfiles):
#     ~/dotfiles/container/install.sh
#  Options:
#     --no-apt     skip apt packages (already in image)
#     --minimal    nvim + zsh only (no node / extras)
# ─────────────────────────────────────────────────────────────
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PACKAGES=(zsh nvim starship git lazygit)
BIN="$HOME/.local/bin"
mkdir -p "$BIN"
export PATH="$BIN:$PATH"

SUDO=""
[[ $EUID -ne 0 ]] && command -v sudo >/dev/null && SUDO="sudo"

DO_APT=1 MINIMAL=0
for a in "$@"; do
  case $a in
    --no-apt) DO_APT=0 ;;
    --minimal) MINIMAL=1 ;;
  esac
done

case "$(uname -m)" in
  x86_64 | amd64) ARCH=x86_64 ;;
  aarch64 | arm64) ARCH=arm64 ;;
  *) echo "unsupported arch $(uname -m)"; exit 1 ;;
esac

step() { printf "\n\033[34m==>\033[0m %s\n" "$*"; }
ok() { printf "  \033[32m✓\033[0m %s\n" "$*"; }

# glibc of this system, e.g. 2.31 on Ubuntu 20.04
GLIBC=$(ldd --version 2>/dev/null | head -1 | grep -oE '[0-9]+\.[0-9]+$')
glibc_at_least() { [[ $(printf '%s\n%s\n' "$1" "$GLIBC" | sort -V | head -1) == "$1" ]]; }

gh_latest() { # owner/repo → newest semver tag without the leading v (no API rate limits)
  git ls-remote --tags --refs "https://github.com/$1" |
    grep -oE 'refs/tags/v?[0-9]+\.[0-9]+\.[0-9]+$' | sed -E 's#refs/tags/v?##' | sort -V | tail -1
}

# ── apt ──────────────────────────────────────────────────────
if ((DO_APT)); then
  step "apt packages"
  export DEBIAN_FRONTEND=noninteractive
  $SUDO apt-get update -qq
  $SUDO apt-get install -y -qq --no-install-recommends \
    zsh git curl wget ca-certificates unzip xz-utils gzip tar file less \
    build-essential ripgrep fd-find bat jq stow \
    python3-venv python3-pip clangd clang-format locales >/dev/null
  $SUDO apt-get install -y -qq btop >/dev/null 2>&1 || true
  $SUDO locale-gen en_US.UTF-8 >/dev/null 2>&1 || true
  ok "apt"
fi

# ── Neovim (latest stable release) ──────────────────────────
step "Neovim"
NV_DIR="$HOME/.local/opt/nvim"
# official builds need glibc 2.34+; neovim-releases builds the same version for older systems
NV_REPO=neovim/neovim
glibc_at_least 2.34 || NV_REPO=neovim/neovim-releases
curl -fsSL "https://github.com/$NV_REPO/releases/latest/download/nvim-linux-${ARCH}.tar.gz" -o /tmp/nvim.tgz
rm -rf "$NV_DIR" && mkdir -p "$NV_DIR"
tar -xzf /tmp/nvim.tgz -C "$NV_DIR" --strip-components=1 && rm /tmp/nvim.tgz
ln -sf "$NV_DIR/bin/nvim" "$BIN/nvim"
ok "$(nvim --version | head -1)"

# ── fzf (apt version is too old for `fzf --zsh`) ────────────
step "fzf"
if [[ ! -d $HOME/.fzf ]]; then
  git clone -q --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
fi
"$HOME/.fzf/install" --bin >/dev/null
ln -sf "$HOME/.fzf/bin/fzf" "$BIN/fzf"
ok "fzf $(fzf --version | cut -d' ' -f1)"

# ── starship · zoxide · lazygit ─────────────────────────────
step "starship, zoxide, lazygit"
command -v starship >/dev/null ||
  curl -fsSL "https://github.com/starship/starship/releases/latest/download/starship-${ARCH/arm64/aarch64}-unknown-linux-musl.tar.gz" | tar -xz -C "$BIN" starship
if ! command -v zoxide >/dev/null; then # release tarball: the install script queries the rate-limited API
  v=$(gh_latest ajeetdsouza/zoxide)
  curl -fsSL "https://github.com/ajeetdsouza/zoxide/releases/download/v${v}/zoxide-${v}-${ARCH/arm64/aarch64}-unknown-linux-musl.tar.gz" | tar -xz -C "$BIN" zoxide
fi
if ! command -v lazygit >/dev/null; then
  v=$(gh_latest jesseduffield/lazygit)
  curl -fsSL "https://github.com/jesseduffield/lazygit/releases/download/v${v}/lazygit_${v}_Linux_${ARCH}.tar.gz" | tar -xz -C "$BIN" lazygit
fi
ok "starship · zoxide · lazygit"

if ((!MINIMAL)); then
  # ── Node (Mason needs npm for many LSPs) ──────────────────
  step "Node.js"
  if ! command -v node >/dev/null; then
    curl -fsSL https://deb.nodesource.com/setup_22.x | ${SUDO:+$SUDO -E} bash - >/dev/null
    $SUDO apt-get install -y -qq nodejs >/dev/null
  fi
  ok "node $(node --version)"

  # ── tree-sitter CLI (compiles parsers; its binary needs glibc 2.39+) ──
  step "tree-sitter CLI"
  if glibc_at_least 2.39; then
    npm install -g --prefix "$HOME/.local" tree-sitter-cli >/dev/null 2>&1 && ok "tree-sitter $(tree-sitter --version | cut -d' ' -f2)"
  else
    ok "skipped (glibc $GLIBC): Neovim uses its bundled parsers and regex syntax"
  fi

  # ── eza ───────────────────────────────────────────────────
  if ! command -v eza >/dev/null; then
    curl -fsSL "https://github.com/eza-community/eza/releases/latest/download/eza_${ARCH/arm64/aarch64}-unknown-linux-gnu.tar.gz" | tar -xz -C "$BIN" 2>/dev/null && ok "eza" || true
  fi
fi

# ── Link configs ─────────────────────────────────────────────
step "Linking configs"
for d in nvim zsh lazygit git; do
  [[ -d $HOME/.config/$d && ! -L $HOME/.config/$d ]] && mv "$HOME/.config/$d" "$HOME/.config/$d.bak.$(date +%s)"
done
[[ -f $HOME/.zshrc && ! -L $HOME/.zshrc ]] && mv "$HOME/.zshrc" "$HOME/.zshrc.bak.$(date +%s)"
[[ -f $HOME/.config/starship.toml && ! -L $HOME/.config/starship.toml ]] && rm -f "$HOME/.config/starship.toml"
mkdir -p "$HOME/.config"
stow -d "$DOTFILES" -t "$HOME" --restow "${PACKAGES[@]}"
ok "linked: ${PACKAGES[*]}"

# ── Plugins ──────────────────────────────────────────────────
step "Plugins"
zsh -ic 'exit 0' >/dev/null 2>&1 || true
nvim --headless "+Lazy! restore" +qa >/dev/null 2>&1 || true
ok "zsh · nvim plugins"

# ROS colcon defaults (compile_commands + debug symbols)
if [[ -d /opt/ros ]] && [[ ! -f $HOME/.colcon/defaults.yaml ]]; then
  mkdir -p "$HOME/.colcon"
  cp "$DOTFILES/templates/ros2/colcon_defaults.yaml" "$HOME/.colcon/defaults.yaml"
  ok "colcon defaults (compile_commands + RelWithDebInfo)"
fi

if [[ ${SHELL:-} != */zsh ]]; then
  $SUDO chsh -s "$(command -v zsh)" "$(id -un)" 2>/dev/null && ok "default shell → zsh" ||
    echo "  ! set default shell manually: chsh -s $(command -v zsh)"
fi

step "Done — run: exec zsh"
