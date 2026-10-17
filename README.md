<div align="center">

<img src="assets/logo.svg" width="112" alt="dotfiles logo">

# dotfiles

**My daily macOS terminal: Ghostty, tmux, zsh and Neovim for running web apps on the Mac and
working on ROS 1 / ROS 2 inside Docker containers and robots over SSH.**

[![ci](https://img.shields.io/github/actions/workflow/status/agus-darmawan/dotfiles/ci.yml?branch=main&label=ci&logo=github)](https://github.com/agus-darmawan/dotfiles/actions/workflows/ci.yml)
![macOS](https://img.shields.io/badge/macOS-daily%20driver-000000?logo=apple&logoColor=white)
![Ghostty](https://img.shields.io/badge/terminal-Ghostty-3551F3?logo=ghostty&logoColor=white)
![tmux](https://img.shields.io/badge/tmux-3.4%2B-1BB91F?logo=tmux&logoColor=white)
![zsh](https://img.shields.io/badge/shell-zsh-F15A24?logo=zsh&logoColor=white)
![Neovim](https://img.shields.io/badge/Neovim-0.11%2B-57A143?logo=neovim&logoColor=white)
![ROS](https://img.shields.io/badge/ROS-Noetic%20%7C%20Humble%20%7C%20Jazzy-22314E?logo=ros&logoColor=white)
![Theme](https://img.shields.io/badge/theme-Catppuccin%20Mocha-CBA6F7)
[![License](https://img.shields.io/badge/license-MIT-blue)](LICENSE)

[Install](#install) · [Features](#features) · [Keys](#keys) · [Documentation](#documentation) ·
[Develop](#develop)

<img src="assets/demo.gif" alt="app launcher, Cloudflare Tunnel status, SSH picker into a ROS 2 container, build and Neovim there" width="100%">

</div>

---

One repository for the whole terminal: the emulator, the multiplexer, the shell and the editor share
one theme and one font, and know about each other. The prompt and every tab title say where you
are (`agus@macbook:~/apps/molly`, `dev@humble:~/ros2_ws`), `Ctrl-h/j/k/l` moves between tmux panes
and Neovim splits, and yanks reach the macOS clipboard from inside containers and SSH sessions.

## Install

```bash
git clone git@github.com:agus-darmawan/dotfiles.git ~/dotfiles
cd ~/dotfiles && ./install.sh
```

The installer runs the [`Brewfile`](Brewfile), backs up existing configs to `~/.dotfiles-backup/`,
links everything with GNU Stow, adds an iTerm2 profile, prepares `~/.ssh/config` with the
`containers` and `robots` host files and `~/.config/apps`, and installs the zsh and Neovim plugins.
Then open **Ghostty** and type `t`. Check the result with `~/dotfiles/tests/smoke.sh`.
Step by step: [docs/INSTALL-MACOS.md](docs/INSTALL-MACOS.md).

Inside a dev container (Ubuntu 20.04+), a Jetson or a robot: `~/dotfiles/container/install.sh`
([guide](docs/CONTAINER.md)).

## Features

**Terminal and tmux**
- Ghostty with Catppuccin Mocha, JetBrainsMono Nerd Font and a drop-down quick terminal on `` cmd+` ``.
- Prefer iTerm2? `install.sh` adds a matching profile: Preferences → Profiles → **dotfiles (Catppuccin Mocha)** → *Set as Default*.
- The VS Code terminal uses the same shell; add the font and title settings from [vscode/](vscode/README.md).
- tmux status bar on top: session, windows (named after the folder, or the host in SSH panes), Cloudflare Tunnel, running containers, CPU, RAM, IP, battery, time.
- No tmux plugins. Popups for lazygit, lazydocker and btop; fuzzy pickers for projects, sessions, SSH hosts, containers and web apps.
- `dev <host>` opens a session on a container or robot over SSH (windows code, build, run).
  `F12` hands every key to a tmux running on the robot.

<img src="assets/tmux.png" alt="tmux: a web app window and a container window with Neovim, a file tree and the tunnel routes" width="100%">

**Web apps**
- `app molly` (or `C-a a`) opens a registered app in its own tmux window and starts it: PM2,
  docker compose or `pnpm dev`, picked from what the folder contains.
- `tun` shows what the Cloudflare Tunnel serves; `tun add gcs.example.com 5173` adds a hostname with
  its DNS record, `tun share 3000` gives a temporary public URL.
- PM2 and Docker shortcuts: `pml`, `pmlog`, `dps`, `dcu`, `dcl`, lazydocker on `C-a D`.
  Guide: [docs/WEB.md](docs/WEB.md).

**Neovim**
- Own modular config, every language in one registry file: LSP, formatter, linter and parser.
- C++ (clangd), Python, CMake, ROS launch/URDF/xacro XML, `.msg`/`.srv`, TypeScript and Next.js,
  Dart, Docker, Bash, Lua, Markdown.
- 20 plugins: blink.cmp completion, snacks.nvim pickers and explorer, which-key, gitsigns, lazygit.

<img src="assets/nvim.png" alt="clangd completion in Neovim inside a container" width="100%">

**ROS 1 and ROS 2 (containers and robots)**
- `Space rb` builds the package you are editing with colcon or catkin: errors land in the quickfix
  list, `compile_commands.json` is merged and clangd restarts.
- Pickers for topics, nodes, launch files and executables (`ros2 launch` / `roslaunch`, `ros2 run` /
  `rosrun`); syntax for `.msg`, `.srv` and `.action` files.
- Shell helpers inside containers and on robots (never on the Mac), for ROS 2 (colcon) and ROS 1 (catkin):
  `ros`, `rosdomain`/`rosmaster`, `cb`/`cbp`/`ct`, `rtopic`, `rnode`.

<img src="assets/ros-build.gif" alt="colcon build from Neovim in a container: error in quickfix, fix, rebuild" width="100%">

**Containers and robots**
- `ssh humble`, `ssh jazzy`, `ssh noetic`: host entries for the dev containers are ready in `~/.ssh/config.d/containers`.
- `dsh` / `C-a d` opens the best shell in any running container; `dev <host>` opens a full session in it over SSH.
- SSH multiplexing: extra panes on the same robot connect instantly; `sall go2 lite3` types into
  several robots at once.
- `NVIM_OFFLINE=1` on machines without internet skips every automatic download.

## Keys

tmux prefix `Ctrl-a` · Neovim leader `Space`

| Keys | Action |
|---|---|
| `t` | attach or create the tmux session `main` |
| `C-a \|` · `C-a -` | split right · split down |
| `C-h/j/k/l` | move between tmux panes and Neovim splits |
| `C-a f` · `C-a s` | open a project · switch session |
| `C-a S` · `C-a d` | SSH to a host · shell into a container |
| `C-a a` | open a web app in a new window |
| `C-a g` · `C-a b` | lazygit · btop |
| `Space Space` · `Space /` | find files · grep |
| `gd` · `K` · `Space ca` | definition · hover · code action |
| `Space rb` · `Space rt` | build this ROS package · ROS topics (containers) |
| `Space gg` | lazygit |

Every key: [docs/KEYMAPS.md](docs/KEYMAPS.md)

## Documentation

| For | Document |
|---|---|
| Installing on the Mac, iTerm2 and VS Code | [INSTALL-MACOS.md](docs/INSTALL-MACOS.md) |
| Learning the setup step by step (Bahasa Indonesia) | [TUTORIAL.md](docs/TUTORIAL.md) |
| All shortcuts: Ghostty, tmux, Neovim | [KEYMAPS.md](docs/KEYMAPS.md) |
| Shell commands: web apps, Docker, SSH, ROS, git | [COMMANDS.md](docs/COMMANDS.md) |
| Web apps, Cloudflare Tunnel, PM2 | [WEB.md](docs/WEB.md) |
| ROS dev containers over SSH, robots | [CONTAINER.md](docs/CONTAINER.md) |
| Local overrides, status bar, languages | [CUSTOMIZE.md](docs/CUSTOMIZE.md) |
| Something broken | [TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) |

All guides: [docs/](docs/README.md).

Personal overrides stay out of git: `~/.zshrc.local`, `~/.config/tmux/tmux.local.conf`,
`~/.config/git/config.local`, `~/.config/nvim/lua/config/local.lua`, `~/.ssh/config.d/`.

## Develop

```bash
~/dotfiles/tests/smoke.sh     # links, tmux, zsh helpers, every Neovim plugin
```

The `ci` workflow runs on every push: ShellCheck, StyLua and syntax checks; a full `install.sh` on
macOS followed by the smoke test; and `container/install.sh` inside the `ros:noetic`, `ros:humble`
and `ros:jazzy` images, where Neovim builds a real catkin or ament package.

Update with `git pull && ./install.sh --no-brew`; remove the links with `./install.sh --unlink`.

Released under the [MIT License](LICENSE).
