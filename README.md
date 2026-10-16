# dotfiles

My daily **macOS** terminal setup: Ghostty + tmux + zsh + Neovim.
Built for ROS 2 (C++/Python), web (Next.js), Flutter, Docker, and SSH into robots.

One theme (**Catppuccin Mocha**), one font (**JetBrainsMono Nerd Font**).

## Install

```bash
git clone https://github.com/agus-darmawan/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

The installer:
- installs everything in the [`Brewfile`](Brewfile) (Ghostty, tmux, Neovim, fzf, lazygit, …)
- backs up your old configs to `~/.dotfiles-backup/`
- symlinks the configs with `stow`
- sets up `~/.ssh/config` and `~/.ssh/config.d/robots`
- installs tmux, zsh and Neovim plugins

Then open **Ghostty** and type `t`.

> The first time you open `nvim`, give it a minute: Mason installs the language servers in the background (`:Mason` to watch).

## What's inside

| Tool | What it does |
|---|---|
| **Ghostty** | Terminal, drop-down quick terminal on `cmd+\`` |
| **tmux** | Status bar on top (CPU, RAM, Docker, IP, battery, ROS domain), popups for lazygit/btop/lazydocker, SSH and container pickers |
| **zsh** | starship, fzf-tab, autosuggestions, zoxide, atuin, plus ROS/Docker/SSH helpers |
| **Neovim** | LSP, completion, debugger, ROS 2 build → quickfix, Flutter, web |
| **git** | lazygit + delta |

## Most-used keys

tmux prefix = `Ctrl-a` · Neovim leader = `Space`

| Keys | Action |
|---|---|
| `t` | open tmux session `main` |
| `C-a \|` / `C-a -` | split right / down |
| `C-h/j/k/l` | move between tmux panes and Neovim splits |
| `C-a f` / `C-a s` | open project / switch session |
| `C-a S` / `C-a d` | SSH to a host / shell into a container |
| `C-a g` / `C-a b` | lazygit / btop |
| `Space Space` / `Space /` | find file / grep |
| `gd` / `K` / `Space ca` | definition / docs / code action |
| `Space rb` / `Space rt` | build ROS package / browse topics |
| `Space gg` | lazygit |

All keys: [docs/KEYMAPS.md](docs/KEYMAPS.md)

## Docs

- [Tutorial](docs/TUTORIAL.md) — learn it step by step (Bahasa Indonesia)
- [Keymaps](docs/KEYMAPS.md) — full shortcut list
- [Containers & robots](docs/CONTAINER.md) — same config inside Docker / on a Jetson

## Personal overrides (not in git)

- `~/.zshrc.local` — private env vars and aliases
- `~/.config/git/config.local` — work email, etc.
- `~/.ssh/config.d/` — robot and server hosts

## Update

```bash
cd ~/dotfiles && git pull && ./install.sh --no-brew
```

Remove the symlinks: `./install.sh --unlink`
