# VS Code integrated terminal

The shell config is global, so VS Code's terminal gets the same zsh, prompt and tools as Ghostty.
Two things VS Code needs from its own settings:

1. **The Nerd Font**, or prompt icons show as boxes.
2. **The escape-sequence title**, so terminal tabs show `host:path` like Ghostty and iTerm2.

Open *Preferences: Open User Settings (JSON)* (`cmd+shift+p`) and merge in
[`settings.json`](settings.json):

| Setting | Why |
|---|---|
| `terminal.integrated.fontFamily` | `JetBrainsMono Nerd Font Mono` for the prompt and `eza` icons |
| `terminal.integrated.tabs.title` = `${sequence}` | tab shows the `host:path` title set by zsh |
| `terminal.integrated.macOptionIsMeta` | ⌥ works as Alt (`M-b`, `M-f`, fzf `M-c`) |
| `terminal.integrated.minimumContrastRatio` = `1` | keeps Catppuccin colours as they are |
| `terminal.integrated.defaultProfile.osx` = `zsh` | |

tmux is optional inside VS Code; plain zsh works fine there. VS Code keeps some `ctrl` keys for itself
(for example `ctrl+p`); add them to `terminal.integrated.commandsToSkipShell` with a leading `-`
if you want the shell to receive them.
