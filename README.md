<div align="center">

# ⚡ dotfiles

**Ghostty · tmux · zsh · Neovim** — a terminal workspace for robotics, web and mobile development on macOS,
that works the same inside Docker dev containers, on Jetsons and on robots over SSH.

`ROS 2` · `C++/clangd` · `Python` · `TypeScript/Next.js` · `Flutter` · `Docker` · `SSH multi-robot`

</div>

---

## What you get

```
╭─ tmux (top) ───────────────────────────────────────────────────────────────────────╮
│ elips │ 1 code  2 build  3 run │ humble:42  cpu 23%  ram 11/24G  docker 3    01:10 │
├────────────────────────────────────────────────────────────────────────────────────┤
│  buffer tabs                                                                       │
│                                                                                    │
│  Neovim — LSP · treesitter · DAP · colcon build → quickfix · topic/node pickers    │
│                                                                                    │
│ NOR │ main +2 ~1 │ src/patrol_node.cpp    elips_patrol · clangd │ 42% │ 118:7      │
╰─ lualine (bottom) ─────────────────────────────────────────────────────────────────╯
```

| Layer | Tool | Highlights |
|---|---|---|
| Terminal | **Ghostty** | GPU, native macOS, Catppuccin, drop-down quick terminal (`cmd+\``), auto terminfo over SSH |
| Multiplexer | **tmux** | Status bar **on top** with CPU / RAM / Docker / IP / battery / ROS domain, popups for lazygit / lazydocker / btop, session + SSH + container pickers, nested-tmux toggle (`F12`), session restore |
| Layouts | **tmuxp** | `tros` (ROS2 inside a container) · `trobot` (field session on a robot) · `tweb` (web/Flutter) |
| Shell | **zsh** + starship | fzf-tab, autosuggestions, syntax highlight, zoxide, atuin, ROS/colcon/docker/ssh helpers — no framework, ~0 startup cost |
| Editor | **Neovim** | Own modular config, single **language registry**, blink.cmp, snacks.nvim, Mason, conform, nvim-lint, DAP (C++/Python/ROS2 nodes), flutter-tools, ROS2 build → quickfix |
| Git | lazygit + delta | Catppuccin, side panels, `C-a g` popup anywhere |

Everything shares one palette (**Catppuccin Mocha**) and one font (**JetBrainsMono Nerd Font**).

---

## Install (macOS)

```bash
git clone https://github.com/agus-darmawan/dotfiles ~/dotfiles
cd ~/dotfiles && ./install.sh
```

The installer:

1. installs everything in the [`Brewfile`](Brewfile) (Ghostty, fonts, tmux, neovim, CLI tools…)
2. **backs up** existing configs to `~/.dotfiles-backup/<timestamp>/`
3. symlinks configs with GNU Stow
4. creates `~/.ssh/config` with connection multiplexing + `~/.ssh/config.d/robots`
5. installs tmux / zsh / Neovim plugins

| Command | Does |
|---|---|
| `./install.sh --no-brew` | skip Homebrew, only link + plugins |
| `./install.sh --link` | only (re)link |
| `./install.sh --unlink` | remove all symlinks |

Then open **Ghostty** → type `t`.

## Inside a dev container / Jetson / robot

```bash
# mount the repo into the container (see docs/CONTAINER.md), then:
~/dotfiles/container/install.sh
```

Ubuntu 22.04+, x86_64 **and** arm64. Installs latest Neovim, fzf, starship, zoxide, lazygit, Node (for Mason), tree-sitter CLI, links the configs and pre-installs plugins.
Full guide: [docs/CONTAINER.md](docs/CONTAINER.md).

---

## Layout

```
dotfiles/
├── Brewfile                     macOS packages
├── install.sh                   macOS installer
├── container/install.sh         Linux / container / Jetson installer
├── ghostty/  .config/ghostty/config
├── tmux/     .config/tmux/tmux.conf
│             .config/tmux/scripts/   status.sh · sessionizer · ssh/docker/session pickers · denter
│             .config/tmuxp/          ros2.yaml · robot.yaml · web.yaml
├── zsh/      .zshrc → .config/zsh/   00-env 10-options 20-plugins 30-tools 40-aliases 50-ros 60-docker 70-ssh
├── starship/ .config/starship.toml
├── git/      .config/git/            config (delta, aliases) · global ignore
├── lazygit/  .config/lazygit/config.yml
├── nvim/     .config/nvim/
│   ├── lua/config/   options · keymaps · autocmds · lazy · languages (registry)
│   ├── lua/plugins/  lsp · completion · formatting · treesitter · snacks · ui · editor · git · dap · flutter · colorscheme
│   ├── lua/util/ros.lua    colcon, compile_commands, topic/node/launch pickers
│   └── syntax/rosmsg.vim   .msg / .srv / .action highlighting
├── ssh/      config.example · config.d/robots.example   (copied, never stowed)
├── templates/ros2/         .clangd · .clang-format · colcon_defaults.yaml
└── docs/     TUTORIAL.md · KEYMAPS.md · CONTAINER.md
```

---

## Neovim language support

All languages are declared in **one file**: [`nvim/.config/nvim/lua/config/languages.lua`](nvim/.config/nvim/lua/config/languages.lua).

| Area | LSP | Format | Extra |
|---|---|---|---|
| C / C++ / CUDA (ROS 2) | clangd (system first, Mason fallback) | clang-format *(only if `.clang-format` exists)* | codelldb DAP, compile_commands merge, header/source switch |
| Python (rclpy) | basedpyright + ruff | ruff | debugpy, auto `install/*/site-packages` paths |
| CMake | neocmakelsp | gersemi *(if `.gersemirc`)* | |
| launch.xml · URDF · xacro · SDF · package.xml | lemminx | lemminx | |
| .msg / .srv / .action | — | — | syntax + `ros2 interface show` under cursor |
| TS / JS / React / Next.js | vtsls, eslint, tailwind, emmet | biome *(if configured)* → prettierd | |
| HTML / CSS / JSON / YAML / TOML | html, cssls, jsonls+SchemaStore, yamlls+SchemaStore, taplo | prettierd / taplo | compose & GH-actions schemas |
| Flutter / Dart | dartls via flutter-tools | dart format | run, hot reload, devices, widget outline, DAP |
| Docker | dockerls, docker-compose LS | — | hadolint |
| Bash / zsh | bashls | shfmt | shellcheck |
| Go · Rust · Swift · Lua · Markdown | gopls · rust_analyzer · sourcekit · lua_ls · marksman | gofumpt · rustfmt · swiftformat · stylua · prettierd | |

**Add a language** → add the parser to `M.treesitter`, the server to `M.servers()`, the formatter to `M.formatters_by_ft`. Done.

---

## Daily cheatsheet

> Leader = `Space` in Neovim · Prefix = `Ctrl-a` in tmux. Full list: [docs/KEYMAPS.md](docs/KEYMAPS.md)

**tmux**

| Keys | Action |
|---|---|
| `C-a \|` / `C-a -` | split right / down |
| `C-h/j/k/l` | move between panes **and** Neovim splits |
| `C-a f` | project sessionizer (loads `.tmuxp.yaml` if present) |
| `C-a s` | switch session |
| `C-a S` | SSH picker (new window / split) |
| `C-a d` | shell into a running container |
| `C-a g` / `C-a D` / `C-a b` | lazygit / lazydocker / btop popup |
| `C-a t` | floating scratch terminal |
| `C-a y` | sync panes (type into all robots at once) |
| `F12` | disable outer tmux (for tmux on the robot) |

**Neovim**

| Keys | Action |
|---|---|
| `Space Space` · `Space /` · `Space ,` | files · grep · buffers |
| `Space e` · `-` | explorer · oil (edit dirs as text) |
| `gd` `gr` `K` `Space ca` `Space cr` | definition · refs · hover · code action · rename |
| `Space rb` · `Space rB` | colcon build this package · whole workspace → quickfix |
| `Space rt` · `Space rn` · `Space rl` · `Space rr` | topics · nodes · launch · run |
| `Space db` · `F5` | breakpoint · debug (ROS node from install/) |
| `Space gg` | lazygit |
| `Space Fr` · `Space Fh` | flutter run · hot reload |

**Shell**

| Command | Action |
|---|---|
| `t` | attach/create tmux session `main` |
| `ros` · `rosdomain 42` · `rmw cyclone` | source ROS + overlay · domain id (shows in tmux) · RMW |
| `cb` · `cbp pkg` · `cbu pkg` · `ct pkg` | colcon build all / select / up-to / test (+ compile_commands) |
| `rtopic` `rnode` `rif` `rhz` | fzf ROS pickers |
| `tros <container>` · `trobot go2` · `tweb` | tmux layouts |
| `s` · `sall go2 lite3` · `sfwd host 8080` | SSH picker · synced multi-robot · port forward |
| `dsh` `dlog` `dps` `lzd` | docker helpers |

---

## Customise without touching the repo

| File | For |
|---|---|
| `~/.zshrc.local` | machine-specific env, secrets, extra aliases |
| `~/.config/tmux/tmux.local.conf` | tmux overrides |
| `~/.config/git/config.local` | e.g. work email via `includeIf "gitdir:~/work/"` |
| `~/.ssh/config.d/*` | robot / server hosts |

## Requirements

- macOS 14+ (Apple Silicon or Intel) or Ubuntu 22.04+ for containers
- Neovim **0.11+** (installers fetch the latest)
- A Nerd Font in the terminal (installed by the Brewfile)

## License

MIT
