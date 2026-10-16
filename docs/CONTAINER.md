# Dev containers, Jetson & robots

The same Neovim / zsh / tmux config runs on the Mac **and** inside Linux containers.
The trick: share the **config** (mount the repo), never the **data** (plugins, Mason binaries are per-OS).

## 1. Mount the repo

`docker-compose.yml` of your ROS workspace:

```yaml
services:
  dev:
    image: osrf/ros:humble-desktop        # or your own image
    container_name: elips_dev
    network_mode: host
    stdin_open: true
    tty: true
    working_dir: /home/dev/elips_ws
    environment:
      - TERM=xterm-256color
      - COLORTERM=truecolor
      - ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
    volumes:
      - ./:/home/dev/elips_ws
      - ~/dotfiles:/home/dev/dotfiles              # config (shared with the Mac)
      - nvim-data:/home/dev/.local/share/nvim     # lazy plugins + Mason (Linux binaries)
      - zsh-data:/home/dev/.local/share/zsh       # zsh plugins + history
      - ~/.ssh:/home/dev/.ssh:ro                  # optional: reach robots from inside
volumes:
  nvim-data:
  zsh-data:
```

> Don't mount the Mac's `~/.local/share/nvim` — Mason/treesitter binaries are compiled for macOS.

## 2. Install once inside the container

```bash
docker exec -it elips_dev bash
~/dotfiles/container/install.sh          # ~2–4 min, x86_64 or arm64
exec zsh
```

Or bake it into your image:

```dockerfile
COPY --chown=dev:dev dotfiles /home/dev/dotfiles
USER dev
RUN /home/dev/dotfiles/container/install.sh
```

## 3. Work from the Mac

The recommended setup: **tmux runs on the Mac**, panes enter the container.

```bash
tros elips_dev                     # workdir taken from the container
tros elips_dev /home/dev/elips_ws  # explicit
```

You get windows `code` (nvim), `build`, `run` (4 panes), `sys` — every pane already inside the container,
ROS sourced. The tmux bar shows Mac CPU/RAM + running containers.

Single shells: `dsh` (fzf pick) or `C-a d` from anywhere.

## Clipboard

Yanks inside the container travel via **OSC52** → tmux → Ghostty → macOS clipboard. Nothing to install.

## clangd + colcon

Build with `cb` / `cbp <pkg>` in the shell or `Space rb` in Neovim. Both:

- pass `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo`
- merge every `build/*/compile_commands.json` into `<ws>/compile_commands.json`
- (Neovim) restart clangd and send compiler errors to the quickfix list

Optional: copy `templates/ros2/.clangd` and `.clang-format` into the workspace root.
`container/install.sh` also writes `~/.colcon/defaults.yaml`, so plain `colcon build` exports compile commands too.

## Jetson / robot (no Docker)

```bash
git clone https://github.com/agus-darmawan/dotfiles ~/dotfiles
~/dotfiles/container/install.sh --minimal     # nvim + zsh + tmux, no Node
```

`--minimal` skips Node — Mason servers that need npm (pyright, json, yaml…) won't install, clangd/lua still work.

When you SSH into a robot that runs its own tmux, press **F12** on the Mac to turn the outer tmux off.
The robot's tmux keeps its default `C-b` prefix, yours is `C-a`, so they never clash.
