# Shell commands

Aliases and functions from [`zsh/.config/zsh/`](../zsh/.config/zsh/). Key bindings are in
[KEYMAPS.md](KEYMAPS.md).

## Prompt and title

```text
agus@macbook:~/apps/molly  main !2  22.11.0
❯

 dev@humble:~/ros2_ws/src/patrol  main 󰚩 humble #42
❯
```

The first line is always `user@host:path`, then the git branch and changes, the ROS distro with
`ROS_DOMAIN_ID` or the ROS 1 master (only where ROS is sourced), Python and Node versions, and how
long the last command took. zsh also sets the window and tab title to
`host:path`; Ghostty, iTerm2, VS Code and tmux all show it, and a tmux window inside an SSH pane is
named after the remote host.

## Line editing

| Keys | Action |
|---|---|
| `Tab` | completion menu with fzf-tab (preview of folders, files, containers, hosts); `<` / `>` switch groups |
| `→` or `C-Space` | accept the grey autosuggestion |
| `↑` / `↓`, `C-p` / `C-n` | history search for what you already typed |
| `C-r` | fuzzy history search (fzf) |
| `C-t` | fuzzy-find a file and paste its path |
| `M-c` | fuzzy `cd` into a subfolder |
| `C-x C-e` | edit the current command in Neovim |
| `M-←` / `M-→`, `M-b` / `M-f` | jump a word |

## Navigation and files

| Command | Action |
|---|---|
| `cd <part>` | zoxide: jump to the best match among visited folders (`cd molly`) |
| `cdi` | zoxide, interactive |
| `..` | `cd ..` (a folder typed alone changes into it) |
| `ls` · `ll` · `la` | eza with icons · long · long with hidden files and git status |
| `lt` · `lT` | tree, 2 or 4 levels, git-ignored files hidden |
| `cat <file>` | bat without pager |
| `take <dir>` | `mkdir -p` and `cd` |
| `ex <archive>` | extract tar/zip/gz/xz/zst/7z |
| `v` / `vi` / `vim` | Neovim |
| `vc` · `dot` | open the dotfiles in Neovim · `cd ~/dotfiles` |

## tmux

| Command | Action |
|---|---|
| `t` | attach or create session `main` |
| `ta` · `tl` · `tk <name>` | attach · list · kill session |
| `ts` | project sessionizer (same as `C-a f`) |
| `dev <host>` | session named after an SSH host with windows `code`, `build`, `run`, each already on that host |

## Web apps

| Command | Action |
|---|---|
| `app` · `app <name>` | open a web app in its own tmux window and start it |
| `app ls` · `app up/down/logs/cd <name>` | list · start · stop · logs · go to its folder |
| `tun` | Cloudflare Tunnel status and routes |
| `tun add <host> <port>` · `tun rm <host>` | add or remove a public hostname |
| `tun share <port>` | temporary public URL for a local port |
| `tun log` · `tun restart` · `tun edit` · `tun test <host>` | log · restart · edit the config · which rule matches |
| `pml` · `pmlog` · `pmr <name>` · `pms` | `pm2 ls` · logs · restart · save |

## Docker

| Command | Action |
|---|---|
| `dsh [container] [dir]` | shell into a container (zsh › bash › sh), fuzzy pick if no name |
| `dlog` · `dstat` | follow logs · live CPU/RAM per container |
| `dps` · `dpsa` · `di` | containers · all containers · images |
| `dstop` · `drm` | stop / remove containers (multi-select with `Tab`) |
| `d` · `dc` `dcu` `dcd` `dcl` `dcb` | `docker` · `docker compose` · up -d · down · logs -f · build |
| `dclean` | prune stopped containers, networks, dangling images and volumes |
| `lzd` | lazydocker |

## SSH

| Command | Action |
|---|---|
| `s` | pick a host from `~/.ssh/config` and `config.d/` (`enter` window · `ctrl-v` / `ctrl-s` split · `ctrl-o` here) |
| `dev <host>` | tmux session on the host (see [tmux](#tmux)) |
| `sall <h1> <h2> …` | one window, one pane per host, typing goes to all of them |
| `sfwd <host> <port> [local]` | forward a remote port (dashboards, Foxglove) to localhost |
| `skey <host>` | copy your ed25519 key to a host |

## ROS (containers and robots only)

Defined only where `/opt/ros` exists, so the Mac has none of these. The installed distro is
sourced automatically (`export ROS_AUTO=0` in `~/.zshrc.local` turns that off). ROS 2 uses colcon
and `ros2`; ROS 1 uses catkin (`catkin build` when catkin_tools is installed, otherwise
`catkin_make`) and the `ros*` tools.

| Command | Action |
|---|---|
| `ros [distro]` | source `/opt/ros/<distro>` and the nearest workspace overlay |
| `rosws` | print the workspace root above the current folder |
| `rosdomain <id>` | ROS 2: set `ROS_DOMAIN_ID` (shown in the prompt) |
| `rosmaster <host>` | ROS 1: set `ROS_MASTER_URI` and `ROS_IP` (shown in the prompt) |
| `cb` · `cbp <pkg…>` | build the workspace · build packages (with their dependencies); writes `compile_commands.json` for clangd |
| `ct [pkg]` | run the tests and print the results |
| `rcl` | remove `build/ install/ devel/ log/` (asks first) |
| `rtopic` · `rnode` | pick a topic → echo · pick a node → info |
| `rtl` `rte` `rnl` | topic list · topic echo · node list |
| `rl` `rr` `rbag` | launch · run · bag |

## git

| Alias | Command |
|---|---|
| `g` · `lg` | git · lazygit |
| `gs` · `gd` · `gds` | status · diff · staged diff |
| `ga` · `gaa` · `gc` · `gcm "msg"` · `gca` | add · add all · commit · commit -m · amend without editing |
| `gco` · `gsw` · `gcb <name>` | checkout · switch · new branch |
| `gl` · `gf` | pull · fetch all + prune |
| `glog` | graph of the last 20 commits |
| `gst` · `gstp` | stash · stash pop |

Diffs go through delta when it is installed, plain `less` otherwise.

## System

| Command | Action |
|---|---|
| `myip` | local IP addresses (handy on robot networks) |
| `ports` | listening TCP ports and their processes |
| `serve` | static HTTP server in the current folder |
| `rsy <src> <dst>` | `rsync -avhP` |
| `top` | btop |
| `path` | one `$PATH` entry per line |
| `zr` | reload zsh |
| `brewup` · `flushdns` | update Homebrew packages · flush the macOS DNS cache |
| `plug-update` | update the zsh plugins |
