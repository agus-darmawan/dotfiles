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
| `C-a s` | sessions (`ctrl-x` kills) |
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
| `-` | oil: parent directory as a buffer |
| `Space fo` | oil float |
| `Space ff` `fg` `fr` `fp` `fc` | files · git files · recent · projects · config |
| `Space fy` | copy file path |
| `Space sw` | grep word / selection |
| `Space sb` `sh` `sk` `sc` | buffer lines · help · keymaps · commands |
| `Space sd` `sD` | diagnostics · buffer diagnostics |
| `Space su` `sr` `st` | undo tree · resume picker · TODOs |
| `Space sR` | search & replace (grug-far) |

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
| `Space xx` `xX` `xs` `xq` | trouble: project · buffer · symbols · quickfix |
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
| `Space 1..5` | go to buffer N |
| `Space bd` `bD` `bo` `bp` | delete · delete others · close others · pin |
| `Space -` / `Space \|` | split below / right |
| `Space wd` / `Space wo` | close window / only |
| `C-arrows` | resize |

### ROS 2 (`Space r`)
| Keys | Action |
|---|---|
| `Space rb` | colcon build **this package** (background → quickfix, merges compile_commands, restarts clangd) |
| `Space ru` | build up-to this package |
| `Space rB` | build whole workspace |
| `Space rT` | colcon test this package |
| `Space rL` | last colcon log |
| `Space rc` | merge compile_commands.json |
| `Space rt` | topics → echo / hz / bw / info |
| `Space rn` | nodes → info / params |
| `Space rs` | services → type / interface |
| `Space ri` / `Space rI` | interface under cursor / all interfaces |
| `Space rl` | pick launch file → `ros2 launch` |
| `Space rr` | pick executable → `ros2 run` |
| `Space rp` | package / workspace info |

Commands: `:Colcon [pkg]` `:ColconTest` `:ColconLog` `:RosTopics` `:RosNodes` `:RosLaunch` `:RosRun` `:RosCompileDb`

### Debug (`Space d`)
| Keys | Action |
|---|---|
| `Space db` / `Space dB` | breakpoint / conditional |
| `F5` / `Space dc` | start / continue (pick ROS2 executable, file, or attach) |
| `F10` `F11` `F12` | over · into · out |
| `Space dC` | run to cursor |
| `Space du` / `Space de` | UI / eval |
| `Space dt` | terminate |

### Flutter (`Space F`)
| Keys | Action |
|---|---|
| `Space Fr` / `Space Fq` | run / quit |
| `Space Fh` / `Space FR` | hot reload / hot restart |
| `Space Fd` / `Space Fe` | devices / emulators |
| `Space Fo` / `Space Fl` | widget outline / dev log |
| `Space Fp` | pub get |

### Git (`Space g`)
| Keys | Action |
|---|---|
| `Space gg` | lazygit |
| `Space gl` / `Space gf` | lazygit log / file history |
| `Space gs` / `Space gb` | status / branches |
| `]h` / `[h` | next / prev hunk |
| `Space ghs` `ghr` `ghp` `ghb` | stage · reset · preview · blame hunk |
| `Space ub` | inline blame |
| `Space gd` / `Space gH` / `Space gm` | diffview / file history / vs origin/main |
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

### Sessions (`Space q`)
`qs` restore (cwd) · `ql` last · `qS` select · `qd` don't save · `qq` quit all
