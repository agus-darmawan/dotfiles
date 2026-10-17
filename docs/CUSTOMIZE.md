# Customize

Two ways to change things:

- **Edit the repo** for changes you want on every machine. Configs are symlinked, so editing
  `~/.config/nvim/...` edits `~/dotfiles/...`; commit and push as usual.
- **Local files** for one machine only. They are not in git:

| File | Loaded by |
|---|---|
| `~/.zshrc.local` | zsh, last |
| `~/.config/tmux/tmux.local.conf` | tmux, after the main config |
| `~/.config/git/config.local` | git, included at the end |
| `~/.config/nvim/lua/config/local.lua` | Neovim, after everything else |
| `~/.ssh/config.d/*` | ssh |
| `~/.config/apps` | `app` |

## Shell

```zsh
# ~/.zshrc.local
export TMUX_SESSIONIZER_PATHS="$HOME/apps $HOME/web $HOME/ros2_ws"   # roots for C-a f
export CLOUDFLARED_CONFIG=~/.cloudflared/home.yml                    # another tunnel config
export ROS_AUTO=0                                                     # containers: don't source ROS
export NVIM_OFFLINE=1                                                 # robots without internet
alias deploy='ssh homeserver "cd ~/apps/molly && git pull && pm2 restart molly"'
```

- Shared aliases go into [`zsh/.config/zsh/40-aliases.zsh`](../zsh/.config/zsh/40-aliases.zsh).
  Files in `zsh/.config/zsh/` load in name order.
- Prompt: [`starship/.config/starship.toml`](../starship/.config/starship.toml)
  ([module reference](https://starship.rs/config/)). It is kept ASCII-only on purpose; add
  `$hostname` to `format` if you want the host back in the prompt.
- More zsh plugins: add `plug <github-user>/<repo>` to `zsh/.config/zsh/20-plugins.zsh`.

## tmux

```tmux
# ~/.config/tmux/tmux.local.conf
set -g prefix C-b                 # back to the default prefix
bind C-b send-prefix
set -g status-position bottom     # status bar at the bottom
```

**Status bar segments.** `status-right` in [`tmux.conf`](../tmux/.config/tmux/tmux.conf) calls
[`scripts/status.sh`](../tmux/.config/tmux/scripts/status.sh) once per segment: `tunnel`, `cpu`,
`mem`, `docker`, `net`, `battery`. To add one, write a function in `status.sh` and a line for it
in the `case` at the bottom:

```bash
pm2_seg() { # online PM2 processes
  command -v pm2 >/dev/null || return 0
  printf '⚙ %s ' "$(pm2 jlist | jq '[.[] | select(.pm2_env.status == "online")] | length')"
}

case "$1" in
  pm2) pm2_seg ;;
  # …
```

then add `#($S/status.sh pm2)` to `status-right`. Remove a segment by deleting its
`#($S/status.sh …)` part. `C-a r` reloads.

## Neovim

### Add a language

Everything a language needs is registered in
[`lua/config/languages.lua`](../nvim/.config/nvim/lua/config/languages.lua). Example for Go:

```lua
-- 1. syntax: Treesitter parser
M.treesitter = { ..., "go" }

-- 2. language server (inside M.servers()); mason = false uses a binary already on PATH
gopls = {},

-- 3. formatter (conform.nvim)
M.formatters_by_ft = { ..., go = { "gofmt" } }
```

Restart Neovim: Mason installs the server, the parser compiles, format-on-save picks it up.
`:checkhealth vim.lsp` shows what attached.

### Add a plugin

Create a file in `nvim/.config/nvim/lua/plugins/` that returns a lazy.nvim spec; it is loaded
automatically:

```lua
-- lua/plugins/copilot.lua
return {
  { "zbirenbaum/copilot.lua", cmd = "Copilot", event = "InsertEnter", opts = {} },
}
```

`:Lazy` installs it and `lazy-lock.json` records the version; commit both.

### Where things are

| What | Where |
|---|---|
| General keymaps | `lua/config/keymaps.lua` |
| Keymaps of a plugin | the `keys = { … }` of its spec in `lua/plugins/` |
| LSP keymaps (`gd`, `K`, …) | `lua/plugins/lsp.lua` |
| ROS keymaps and commands | `lua/util/ros.lua`, `M.setup()` |
| Editor options | `lua/config/options.lua` |
| Theme | `lua/plugins/colorscheme.lua` (`flavour`: latte, frappe, macchiato, mocha) |
| Statusline | `lua/plugins/ui.lua` (lualine) |

### This machine only

```lua
-- ~/.config/nvim/lua/config/local.lua
vim.g.autoformat = false        -- no format on save here (Space uf toggles it for the session)
vim.opt.relativenumber = false
```

## Ghostty

[`ghostty/.config/ghostty/config`](../ghostty/.config/ghostty/config); `cmd+shift+,` reloads it.

| Setting | Example |
|---|---|
| Font size | `font-size = 15` |
| Transparency | `background-opacity = 0.9` |
| Theme | `theme = Catppuccin Macchiato` (list: `ghostty +list-themes`) |

The theme for iTerm2 lives in [`iterm2/dotfiles.json`](../iterm2/dotfiles.json); run
`./install.sh --no-brew` after changing it so the copy in iTerm2's DynamicProfiles folder updates.

## SSH hosts

```sshconfig
# ~/.ssh/config.d/robots
Host go2
  HostName 192.168.123.18
  User unitree

Host go2-jetson
  HostName 192.168.123.15
  User unitree
  ProxyJump go2
```

Any file in `~/.ssh/config.d/` is read, so you can split hosts by project. Every host shows up in
`s` and `C-a S`.

## git

The shared config is [`git/.config/git/config`](../git/.config/git/config). A different identity for
work repositories:

```ini
# ~/.config/git/config.local
[includeIf "gitdir:~/ezra/"]
    path = ~/.config/git/work
```

```ini
# ~/.config/git/work
[user]
    email = you@company.com
```
