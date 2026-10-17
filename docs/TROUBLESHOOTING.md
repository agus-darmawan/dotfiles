# Troubleshooting

Run `~/dotfiles/tests/smoke.sh` first: it usually points at the broken part.

## Terminal

| Problem | Fix |
|---|---|
| Icons show as boxes or `?` | The Nerd Font is missing or not selected: `brew install --cask font-jetbrains-mono-nerd-font`, restart the terminal. In VS Code set `terminal.integrated.fontFamily` ([vscode/](../vscode/README.md)) |
| `` cmd+` `` does nothing | Give Ghostty Accessibility permission (System Settings → Privacy & Security → Accessibility) and restart it |
| `M-c`, `M-b` type characters like `ç`, `∫` | Use the **left** ⌥ key. iTerm2: select the *dotfiles* profile. VS Code: `terminal.integrated.macOptionIsMeta` |
| Tab title shows `zsh` instead of `host:path` | iTerm2: use the *dotfiles* profile (title from the shell). VS Code: `"terminal.integrated.tabs.title": "${sequence}"` |
| iTerm2 has no *dotfiles* profile | Re-run `./install.sh --no-brew`; it copies `iterm2/dotfiles.json` to `~/Library/Application Support/iTerm2/DynamicProfiles/` |
| Colors or backspace wrong over SSH | Ghostty installs its terminfo on the remote host; if a host refuses, add `export TERM=xterm-256color` to that host's shell rc |

## tmux

| Problem | Fix |
|---|---|
| `missing or unsuitable terminal: tmux-256color` | Re-run `./install.sh --no-brew` (compiles the terminfo into `~/.terminfo`) |
| `C-h/j/k/l` in an SSH pane doesn't leave the pane | On purpose: the key goes to Neovim or tmux on the remote side. `C-a h/j/k/l` always moves the local pane |
| Keys go to the wrong tmux when SSH'd into a host running tmux | `F12` turns the outer tmux off (status bar shows `OFF(F12)`), `F12` again turns it back on |
| An SSH window keeps the Mac's name instead of the host's | The remote shell doesn't set a title. Hosts with these dotfiles do; elsewhere rename the window with `C-a ,` |
| Copy from Neovim inside a container doesn't reach the Mac | It uses OSC 52 through tmux: check `clipboard-write = allow` in the Ghostty config (iTerm2: *Applications in terminal may access clipboard*) |
| A status segment is empty | Run it by hand: `~/.config/tmux/scripts/status.sh cpu` (or `mem`, `docker`, `tunnel`, `net`, `battery`) |

## Shell

| Problem | Fix |
|---|---|
| `zsh compinit: insecure directories` | `compaudit \| xargs chmod g-w,o-w` |
| Plugins not loading | `ls ~/.local/share/zsh/plugins`; delete a broken one and open a new shell to re-clone it |
| `cd` behaves oddly | `cd` is zoxide; `builtin cd <path>` changes literally |
| Startup feels slow | `time zsh -ic exit`; the usual suspect is `~/.zshrc.local` |
| `ros`, `cb`, … not found on the Mac | On purpose: ROS helpers exist only where `/opt/ros` exists. Use them in a container (`dev humble`) |

## Web apps and tunnel

| Problem | Fix |
|---|---|
| `app: 'x' is not in ~/.config/apps` | Add a line `x  ~/path/to/x  [command]`; `app ls` shows what is registered |
| `app` opens a window but nothing runs | The folder has no `package.json`, compose file or PM2 ecosystem file: add the start command to its line |
| `tun add` says there is no catch-all rule | The config needs `- service: http_status:404` as the last ingress rule; `tun` adds routes above it |
| `tun add` worked but the hostname doesn't resolve | The DNS step needs `~/.cloudflared/cert.pem` (`cloudflared tunnel login`) for the zone of that hostname |
| `tun restart` doesn't fit how cloudflared runs here | Set `CLOUDFLARED_RESTART` in `~/.zshrc.local`, see [WEB.md](WEB.md#settings) |

## Containers and robots

| Problem | Fix |
|---|---|
| `ssh humble` is refused | The container must run an SSH server published on `127.0.0.1:2222`; see [CONTAINER.md](CONTAINER.md#3-ssh-into-the-container) |
| `Host key verification failed` after rebuilding a container | Container hosts don't pin keys; for other hosts remove the old key with `ssh-keygen -R <host>` |
| Neovim fails with `GLIBC_2.34 not found` | Re-run `container/install.sh`: it picks the build for older glibc (Ubuntu 20.04) |
| `git diff` says `delta: not found` | Pull the latest dotfiles; git falls back to `less` without delta |

## Neovim

| Problem | Fix |
|---|---|
| No completion / `gd` does nothing | `:checkhealth vim.lsp`; is the server installed in `:Mason`? |
| clangd doesn't know ROS headers | Build once (`cbp <pkg>` or `Space rb`) so `compile_commands.json` exists in the workspace root, then `Space rc` |
| `Space r…` keys are missing | They appear only where ROS is available (a sourced distro or colcon/catkin on PATH) |
| `colcon not found` / `catkin_make not found` from `Space rb` | Start Neovim from a shell where ROS is sourced |
| Treesitter parsers don't install | Needs the tree-sitter CLI and a C compiler: `brew install tree-sitter-cli`, `xcode-select --install`, then `:TSUpdate`. On old Ubuntu the CLI is skipped and the bundled parsers are used |
| Mason install fails | Mason needs `node`, `python3`, `curl`, `unzip`; `:MasonLog` shows the error |
| Format on save changes too much | C/C++ only formats when a `.clang-format` exists; `Space uf` toggles format on save |
| Something broke after `:Lazy sync` | `:Lazy restore` goes back to the versions in `lazy-lock.json` |

## Installer

| Problem | Fix |
|---|---|
| `brew bundle` reports a failed package | Read the error (often a cask installed by hand already), fix it, then `brew bundle --file ~/dotfiles/Brewfile` |
| `stow` reports a conflict | A real file sits where a link should go; move it away and run `./install.sh --link` |
| Want the old configs back | They are in `~/.dotfiles-backup/<date-time>/`, see [INSTALL-MACOS.md](INSTALL-MACOS.md#9-uninstall) |
