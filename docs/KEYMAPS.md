# Keymaps

Leader = `Space` · tmux prefix = `Ctrl-a`. In Neovim, press `Space` and wait — **which-key** shows everything.

## Ghostty

| Keys | Action |
|---|---|
| `` cmd+` `` | quick terminal (drop-down, global) |
| `cmd+t` / `cmd+w` | new / close tab |
| `cmd+d` / `cmd+shift+d` | native split right / down |
| `cmd+alt+h/j/k/l` | move between native splits |
| `cmd+shift+enter` | zoom split |
| `cmd+shift+,` | reload config |

## tmux (`C-a` = prefix)

| Keys | Action |
|---|---|
| `C-a c` | new window in the same folder (windows are named after their folder, or the host in SSH panes) |
| `C-a \|` (or `C-a \`) · `C-a -` | split right · split down |
| `C-h/j/k/l` | move pane (seamless with Neovim; in SSH panes the key goes to the remote side) |
| `C-a H/J/K/L` | resize pane (repeatable) |
| `C-a m` | zoom pane |
| `C-a Tab` | last window |
| `C-a n` / `C-a p` | next / prev window |
| `C-a <` / `C-a >` | move window left / right |
| `C-a x` / `C-a X` / `C-a Q` | kill pane / window / session |
| `C-a y` | toggle synchronize-panes |
| `C-a v` | copy mode (`v` select, `C-v` block, `y` copy → Mac clipboard) |
| `C-a C-l` | clear screen |
| `C-a r` | reload config |
| `C-a h/j/k/l` | move pane (always tmux, also from SSH panes) |
| **Popups** | |
| `C-a f` | sessionizer (projects) |
| `C-a s` | sessions and windows as a tree (`x` kills the selected one) |
| `C-a S` | SSH hosts (enter window · `ctrl-v` vsplit · `ctrl-s` split · `ctrl-o` here) |
| `C-a d` | docker containers → shell |
| `C-a a` | web apps → open one in a new window (`app`) |
| `C-a g` | lazygit (current dir) |
| `C-a D` | lazydocker |
| `C-a b` | btop |
| `C-a t` | persistent scratch terminal |
| `F12` | outer tmux off/on (nested tmux on robot) |

## Neovim

### Find / search
| Keys | Action |
|---|---|
| `Space Space` | smart file finder |
| `Space /` | live grep |
| `Space ,` | buffers |
| `Space :` | command history |
| `Space e` | explorer (right) |
| `Space ff` `fg` `fr` `fp` `fc` | files · git files · recent · projects · config |
| `Space fy` | copy file path |
| `Space sw` | grep word / selection |
| `Space sb` `sh` `sk` `sc` | buffer lines · help · keymaps · commands |
| `Space sd` `sD` | diagnostics · buffer diagnostics |
| `Space su` `sr` `sq` | undo history · resume picker · quickfix |

### Code
| Keys | Action |
|---|---|
| `gd` `gD` `gr` `gI` `gy` | definition · declaration · references · implementation · type |
| `K` / `gK` / `C-k` (insert) | hover / signature |
| `Space ca` | code action |
| `Space cr` | rename symbol |
| `Space cR` | rename file (updates imports) |
| `Space cf` | format |
| `Space cd` | line diagnostics |
| `Space ch` | switch header/source (clangd) |
| `Space ss` / `Space sS` | symbols buffer / workspace |
| `]d` `[d` / `]e` `[e` | next/prev diagnostic / error |
| `]]` `[[` | next/prev reference of word |
| `Space xx` / `Space xq` | diagnostics picker / toggle quickfix |
| `Space cm` | Mason |

### Editing
| Keys | Action |
|---|---|
| `s` / `S` | flash jump / treesitter select |
| `gsa` `gsd` `gsr` | surround add / delete / replace (e.g. `gsaiw"`) |
| `gc` / `gcc` | comment |
| `A-j` / `A-k` | move line(s) |
| `C-s` | save |
| `Tab` / `S-Tab` / `CR` | completion next / prev / accept |
| `C-Space` | open completion |

### Buffers / windows
| Keys | Action |
|---|---|
| `S-h` / `S-l` | prev / next buffer |
| `Space bd` `bD` `bb` | delete · delete others · alternate buffer |
| `Space -` / `Space \|` | split below / right |
| `Space wd` / `Space wo` | close window / only |
| `C-arrows` | resize |

### ROS (`Space r`) — only where ROS is available (containers, robots)
| Keys | Action |
|---|---|
| `Space rb` | build **this package** in the background → quickfix, `compile_commands.json`, clangd restart |
| `Space rB` | build the whole workspace |
| `Space rL` | last build log |
| `Space rc` | merge `compile_commands.json` |
| `Space rt` | topics → echo / hz / info |
| `Space rn` | nodes → info |
| `Space rl` | pick a launch file → `ros2 launch` / `roslaunch` |
| `Space rr` | pick an executable → `ros2 run` / `rosrun` |

ROS 2 builds with colcon (`--packages-up-to`), ROS 1 with `catkin build` (catkin_tools) or `catkin_make`.
Commands: `:RosBuild [pkg]` `:RosLog` `:RosCompileDb`

### Git (`Space g`)
| Keys | Action |
|---|---|
| `Space gg` | lazygit |
| `Space gl` / `Space gf` | lazygit log / file history |
| `Space gs` / `Space gb` | status / branches |
| `]h` / `[h` | next / prev hunk |
| `Space ghs` `ghr` `ghp` `ghb` | stage · reset · preview · blame hunk |
| `Space ub` | inline blame |
| `Space go` | open on GitHub |

### Terminal / tools (`Space t`)
| Keys | Action |
|---|---|
| `C-/` | toggle bottom terminal |
| `Space tt` / `Space tv` | float / side terminal |
| `Space td` / `Space tb` | lazydocker / btop |
| `Esc Esc` | terminal → normal mode |

### UI toggles (`Space u`)
`uf` format-on-save · `uh` inlay hints · `ud` diagnostics · `uw` wrap · `us` spell · `ul`/`uL` numbers · `ug` indent guides · `uD` dim · `uT` treesitter · `uC` colorscheme · `un` dismiss notifications

`Space qq` quits everything.
