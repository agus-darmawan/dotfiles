# Dev containers and robots

ROS lives in Ubuntu containers (ROS 1 Noetic on 20.04, ROS 2 Humble on 22.04, Jazzy on 24.04) and
on the robots. The Mac has no ROS at all. **tmux runs on the Mac**; its panes SSH into a container
or a robot, where zsh, Neovim and the ROS helpers from this repo are installed.

| Where | What runs there |
|---|---|
| Mac | Ghostty (or iTerm2, VS Code), tmux, the SSH and container pickers |
| Container `humble` / `jazzy` | zsh, Neovim, colcon, `ros2` |
| Container `noetic` | zsh, Neovim, catkin, `rostopic` and friends |
| Robot | zsh, Neovim, its own ROS |

Every prompt starts with `user@host:path`, and the tmux window is named after the host, so it is
always clear where a pane is.

- [1. The container](#1-the-container)
- [2. Install the dotfiles inside](#2-install-the-dotfiles-inside)
- [3. SSH into the container](#3-ssh-into-the-container)
- [4. Work from the Mac](#4-work-from-the-mac)
- [5. Build with clangd support](#5-build-with-clangd-support)
- [6. Robots and Jetsons](#6-robots-and-jetsons)

## 1. The container

Share the **config** (mount the repo), never the **data**: plugins and Mason binaries are built
per OS, so they live in volumes.

```yaml
# compose.yaml in the ROS workspace
services:
  humble:
    build: .
    container_name: humble
    network_mode: host                        # ROS discovery on the robot network
    working_dir: /home/dev/ros2_ws
    environment:
      - ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0}
    volumes:
      - ./:/home/dev/ros2_ws
      - ~/dotfiles:/home/dev/dotfiles         # config, shared with the Mac
      - nvim-data:/home/dev/.local/share/nvim # lazy plugins + Mason (Linux binaries)
      - zsh-data:/home/dev/.local/share/zsh   # zsh plugins + history
volumes:
  nvim-data:
  zsh-data:
```

The image needs a `dev` user and an SSH server. With `network_mode: host` give sshd its own port
(2222 humble, 2223 jazzy, 2224 noetic). With bridge networking keep port 22 and publish it on
localhost only: `ports: ["127.0.0.1:2222:22"]`.

```dockerfile
FROM ros:humble                              # or ros:jazzy, ros:noetic
RUN apt-get update && apt-get install -y openssh-server sudo && \
    useradd -m -s /bin/bash -G sudo dev && echo "dev ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/dev && \
    mkdir -p /run/sshd && sed -i 's/^#\?Port .*/Port 2222/' /etc/ssh/sshd_config
COPY --chown=dev:dev authorized_keys /home/dev/.ssh/authorized_keys   # your id_ed25519.pub
CMD ["/usr/sbin/sshd", "-D"]
```

Host networking on a Mac works out of the box in OrbStack; Docker Desktop needs it switched on in
its settings.

## 2. Install the dotfiles inside

Once per container (the volumes keep the result across rebuilds):

```bash
docker exec -it -u dev humble bash
~/dotfiles/container/install.sh          # 2–4 min, x86_64 or arm64
```

It installs zsh, Neovim, fzf, starship, zoxide, lazygit, Node and eza, links the `zsh`, `nvim`,
`starship`, `git` and `lazygit` configs, installs the plugins and makes zsh the login shell.

| Option | Use it when |
|---|---|
| `--no-apt` | the image already has the apt packages (zsh, git, stow, ripgrep, …) |
| `--minimal` | no Node and extras: faster, but Mason servers that need npm (pyright, JSON, YAML) won't install; clangd and Lua still work |

Ubuntu 20.04 has glibc 2.31: the installer then takes Neovim from `neovim/neovim-releases` (built for
old glibc) and skips the tree-sitter CLI, so Neovim uses its bundled parsers.

To bake it into the image instead, copy the repo in and run the installer as `dev`:

```dockerfile
COPY --chown=dev:dev dotfiles /home/dev/dotfiles
USER dev
RUN /home/dev/dotfiles/container/install.sh
```

## 3. SSH into the container

`install.sh` on the Mac created `~/.ssh/config.d/containers` from
[`ssh/config.d/containers.example`](../ssh/config.d/containers.example):

| Host | Port | Image |
|---|---|---|
| `humble` | 2222 | ROS 2 Humble, Ubuntu 22.04 |
| `jazzy` | 2223 | ROS 2 Jazzy, Ubuntu 24.04 |
| `noetic` | 2224 | ROS 1 Noetic, Ubuntu 20.04 |

All of them connect as `dev@localhost`, forward your SSH agent (so `git push` works inside) and
don't pin host keys, because containers are rebuilt often. Adjust users and ports there, then:

```bash
ssh humble
```

## 4. Work from the Mac

```bash
dev humble        # tmux session "humble": windows code, build, run, each already in the container
```

| Keys / command | Action |
|---|---|
| `dev <host>` | create or switch to the session for that host |
| `C-a S` or `s` | pick any host; `enter` new window, `ctrl-v` / `ctrl-s` split, `ctrl-o` here |
| `C-a d` or `dsh` | `docker exec` shell in a running container, no SSH needed |
| `C-h/j/k/l` | in an SSH pane the key goes to Neovim inside the container; `C-a h/j/k/l` moves the Mac pane |
| `F12` | hand every key to a tmux running on the remote side |

Yanks in Neovim inside the container reach the macOS clipboard over OSC 52 (container → SSH → tmux
→ Ghostty); nothing to install.

Inside, ROS is sourced automatically and the helpers know which ROS they are in:

| | ROS 2 (Humble, Jazzy) | ROS 1 (Noetic) |
|---|---|---|
| Build workspace / package | `cb` / `cbp <pkg>` → colcon | `cb` / `cbp <pkg>` → `catkin build` or `catkin_make` |
| Tests | `ct [pkg]` → `colcon test` | `ct [pkg]` → `catkin_make run_tests` |
| Network | `rosdomain 42` → `ROS_DOMAIN_ID` | `rosmaster go2` → `ROS_MASTER_URI`, `ROS_IP` |
| Topics, nodes | `rtopic`, `rnode` | `rtopic`, `rnode` |

The prompt shows the distro and the domain ID or master: `󰚩 humble #42`, `󰚩 noetic @go2`. The full
list is in [COMMANDS.md](COMMANDS.md#ros-containers-and-robots-only).

## 5. Build with clangd support

`cb` / `cbp` in the shell and `Space rb` in Neovim:

- pass `-DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=RelWithDebInfo`
- merge every `build/*/compile_commands.json` (and catkin_make's `build/compile_commands.json`) into
  `<workspace>/compile_commands.json`
- in Neovim, also restart clangd and put compiler errors in the quickfix list

Optional: copy [`templates/ros2/.clangd`](../templates/ros2/.clangd) and
[`.clang-format`](../templates/ros2/.clang-format) into the workspace root. `container/install.sh`
also writes `~/.colcon/defaults.yaml`, so a plain `colcon build` exports compile commands too.

## 6. Robots and Jetsons

The same installer works directly on the robot (no Docker):

```bash
git clone https://github.com/agus-darmawan/dotfiles ~/dotfiles
~/dotfiles/container/install.sh --minimal
```

Add the robot to `~/.ssh/config.d/robots` on the Mac, copy your key once with `skey go2`, then
`dev go2` or `sall go2 lite3` (one pane per robot, typing goes to all of them).

On a robot without internet, add `export NVIM_OFFLINE=1` to `~/.zshrc.local`: Neovim then skips
automatic parser, LSP and plugin-update downloads.

When the robot runs its own tmux, press **F12** on the Mac to turn the outer tmux off. The robot's
tmux keeps its default `C-b` prefix and yours is `C-a`, so they never clash.
