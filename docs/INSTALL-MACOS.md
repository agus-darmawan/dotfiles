# Install on macOS

Step-by-step setup on a Mac (Apple Silicon or Intel, macOS 14 or newer). Most of the 10–20
minutes are Homebrew downloads.

- [1. Before you start](#1-before-you-start)
- [2. Install](#2-install)
- [3. First launch](#3-first-launch)
- [4. iTerm2 and the VS Code terminal](#4-iterm2-and-the-vs-code-terminal)
- [5. SSH: containers and robots](#5-ssh-containers-and-robots)
- [6. Web apps and Cloudflare Tunnel](#6-web-apps-and-cloudflare-tunnel)
- [7. Verify](#7-verify)
- [8. Update](#8-update)
- [9. Uninstall](#9-uninstall)

## 1. Before you start

**Command Line Tools** (git, clang, make). Homebrew asks for them too; installing them first avoids
a second prompt:

```bash
xcode-select --install
```

**Homebrew** is installed by the installer if it is missing. To install it yourself:

```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
eval "$(/opt/homebrew/bin/brew shellenv)"   # Apple Silicon; Intel uses /usr/local/bin/brew
```

**Close running terminals and tmux** if you already have configs for them: the installer moves the
old files away, and new shells should start from the new config.

## 2. Install

```bash
git clone git@github.com:agus-darmawan/dotfiles.git ~/dotfiles   # or https://github.com/agus-darmawan/dotfiles
cd ~/dotfiles && ./install.sh
```

Keep the repo at `~/dotfiles`: `dot`, `vc` and the docs point there.

### What `install.sh` does

| Step | Details |
|---|---|
| Homebrew bundle | everything in the [`Brewfile`](../Brewfile): Ghostty, JetBrainsMono Nerd Font, tmux, starship, zoxide, fzf, eza, bat, fd, ripgrep, btop, Neovim + tree-sitter CLI, node, python, git, delta, lazygit, gh, cloudflared, lazydocker, macmon (CPU temperature for the status bar, Apple Silicon). A failed package is reported and the install continues |
| Backup | moves existing `~/.config/{ghostty,tmux,nvim,zsh,lazygit,git}`, `~/.zshrc` and `~/.config/starship.toml` to `~/.dotfiles-backup/<date-time>/` |
| Link | symlinks every package with GNU Stow, so editing `~/.config/nvim/...` edits the repo |
| tmux terminfo | compiles `tmux-256color` into `~/.terminfo` (macOS ships without it) |
| iTerm2 | copies the profile *dotfiles (Catppuccin Mocha)* into iTerm2's DynamicProfiles folder |
| SSH | creates `~/.ssh/config` (connection multiplexing), `~/.ssh/config.d/robots` and `~/.ssh/config.d/containers` if they do not exist; never overwrites |
| Apps | creates `~/.config/apps`, the list of web apps for `app` |
| Plugins | zsh plugins, and Neovim plugins at the versions pinned in `lazy-lock.json` |

Docker is not in the Brewfile: install [OrbStack](https://orbstack.dev) (`brew install --cask orbstack`)
or Docker Desktop yourself, or uncomment one of them in the `Brewfile`.

### Options

| Command | Use it when |
|---|---|
| `./install.sh` | first install, or to pick up new Brewfile entries |
| `./install.sh --no-brew` | after `git pull`: re-link and refresh plugins, skip Homebrew |
| `./install.sh --link` | only (re)create the symlinks |
| `./install.sh --unlink` | remove the symlinks (see [Uninstall](#9-uninstall)) |

## 3. First launch

1. **Open Ghostty** from Applications. Font and theme are already set. If icons look like boxes,
   the font is missing: `brew install --cask font-jetbrains-mono-nerd-font`.
2. **Quick terminal.** System Settings → Privacy & Security → Accessibility → enable **Ghostty**.
   After that, `` cmd+` `` drops a terminal from the top of the screen in any app.
3. **Default shell.** macOS already uses zsh. If `echo $SHELL` shows something else:
   `chsh -s /bin/zsh`.
4. **The prompt** is plain ASCII: the current folder and the git branch (`molly main*`, then `>`).
   The window and tab title is `host:path`, so you can tell the Mac, a container and a robot apart.
5. **Start tmux** with `t` (session `main`). The status bar is on top. tmux has no plugins: nothing
   to install inside it.
6. **Start Neovim** with `nvim`. In the background Mason installs the language servers and tools,
   and Treesitter compiles its parsers (needs the Command Line Tools). Watch with `:Mason` and
   `:Lazy`; it takes a minute or two, once.
7. **Option key.** The left ⌥ works as Alt (`M-c`, `M-b`, …); the right ⌥ still types special
   characters.

## 4. iTerm2 and the VS Code terminal

The shell config is global, so every terminal app gets the same zsh, prompt and tools. Only the
font and the title need setting per app.

**iTerm2.** `install.sh` already installed the profile. Open iTerm2 → Settings → Profiles, select
**dotfiles (Catppuccin Mocha)** → *Other Actions…* → *Set as Default*. It brings the theme, the
Nerd Font, left ⌥ as Alt and the `host:path` title. iTerm2 itself is not in the Brewfile:
`brew install --cask iterm2`.

**VS Code.** Merge [`vscode/settings.json`](../vscode/settings.json) into your user settings
(`cmd+shift+p` → *Preferences: Open User Settings (JSON)*). It sets the Nerd Font, ⌥ as Alt and
makes terminal tabs show the `host:path` title. Details in [vscode/README.md](../vscode/README.md).

## 5. SSH: containers and robots

```bash
ssh-keygen -t ed25519 -C "darmawandeveloper@gmail.com"   # skip if ~/.ssh/id_ed25519 exists
gh auth login
```

Two host files were created; edit addresses, ports and users there:

| File | Hosts |
|---|---|
| `~/.ssh/config.d/containers` | `humble`, `jazzy`, `noetic`: dev containers on `localhost:2222–2224` |
| `~/.ssh/config.d/robots` | `go2`, `lite3`, `genisom`, `jetson`, `homeserver` (examples) |

```bash
skey go2          # copy your key to the robot once
s                 # fuzzy host picker
dev humble        # tmux session in the container: windows code / build / run
```

Thanks to `ControlMaster`, the first connection authenticates and every other pane to the same
host opens instantly. Setting up the containers themselves: [CONTAINER.md](CONTAINER.md).

## 6. Web apps and Cloudflare Tunnel

List your apps in `~/.config/apps` (one line each: name, folder, optional start command), then
`app` or `C-a a` opens one in its own tmux window. For a Cloudflare Tunnel, log in once:

```bash
cloudflared tunnel login      # opens the browser, writes ~/.cloudflared/cert.pem
tun                           # status and hostname → port routes
```

The full guide: [WEB.md](WEB.md).

## 7. Verify

```bash
~/dotfiles/tests/smoke.sh
```

It checks the links, the binaries, the tmux config, the zsh helpers and loads every Neovim plugin.
Every line should show ✓. In Neovim, `:checkhealth` gives the detailed picture.

## 8. Update

```bash
cd ~/dotfiles && git pull
./install.sh --no-brew      # re-link, plugins at the pinned versions
brew bundle --file ~/dotfiles/Brewfile && brew upgrade
```

| Component | Update |
|---|---|
| Neovim plugins | `:Lazy sync` (updates `lazy-lock.json`; commit it after testing) |
| LSP servers / tools | `:MasonUpdate`, then `:Mason` → `U` |
| Treesitter parsers | `:TSUpdate` |
| zsh plugins | `plug-update` |

## 9. Uninstall

```bash
cd ~/dotfiles && ./install.sh --unlink           # remove the symlinks
ls ~/.dotfiles-backup/                           # pick the backup to restore
cp -R ~/.dotfiles-backup/<date-time>/. ~/        # restore the old configs
```

Plugin data lives in `~/.local/share/nvim`, `~/.local/state/nvim` and `~/.local/share/zsh`; delete
those folders too if you want a clean slate. Homebrew packages stay installed; remove what you do
not want with `brew uninstall <name>`.

---

Problems? See [TROUBLESHOOTING.md](TROUBLESHOOTING.md).
