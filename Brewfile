# brew bundle --file ~/dotfiles/Brewfile

# ── Terminal & fonts ─────────────────────────────────────────
cask "ghostty"
# cask "iterm2"             # optional: the profile in iterm2/ is installed either way
cask "font-jetbrains-mono-nerd-font"
cask "font-symbols-only-nerd-font"

# ── Shell & multiplexer ──────────────────────────────────────
brew "tmux"
brew "ncurses"            # tmux-256color terminfo for macOS
brew "starship"
brew "zoxide"
brew "fzf"
brew "stow"

# ── Modern CLI ───────────────────────────────────────────────
brew "eza"
brew "bat"
brew "fd"
brew "ripgrep"
brew "jq"
brew "yq"
brew "btop"
brew "macmon" if Hardware::CPU.arm?   # CPU temperature for the tmux bar (Apple Silicon)

# ── Editor & toolchains ──────────────────────────────────────
brew "neovim"
brew "tree-sitter-cli"
brew "node"
brew "python"

# ── Git ──────────────────────────────────────────────────────
brew "git"
brew "git-delta"
brew "lazygit"
brew "gh"

# ── Web: tunnels, containers ─────────────────────────────────
brew "cloudflared"
brew "lazydocker"
# cask "orbstack"        # lighter/faster Docker runtime for macOS
# cask "docker-desktop"

# ── Mobile (optional) ────────────────────────────────────────
# cask "flutter"
