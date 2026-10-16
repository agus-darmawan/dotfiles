# ── Environment ──────────────────────────────────────────────

# Homebrew (Apple Silicon / Intel / Linuxbrew)
for _b in /opt/homebrew/bin/brew /usr/local/bin/brew /home/linuxbrew/.linuxbrew/bin/brew; do
  [[ -x $_b ]] && { eval "$($_b shellenv)"; break; }
done
unset _b

typeset -U path PATH
path=(
  $HOME/.local/bin
  $HOME/.fzf/bin
  $HOME/.cargo/bin
  $HOME/go/bin
  $HOME/.pub-cache/bin
  $HOME/development/flutter/bin
  $path
)
export PATH

export EDITOR=nvim
export VISUAL=nvim
export PAGER=less
export LESS="-R --mouse"
export MANPAGER="nvim +Man!"
export LANG=${LANG:-en_US.UTF-8}
export LC_ALL=${LC_ALL:-en_US.UTF-8}
export COLORTERM=truecolor

export XDG_CONFIG_HOME="$HOME/.config"
export XDG_DATA_HOME="$HOME/.local/share"
export XDG_CACHE_HOME="$HOME/.cache"
export XDG_STATE_HOME="$HOME/.local/state"

# Ubuntu ships bat/fd under different names
(( $+commands[batcat] && ! $+commands[bat] )) && alias bat=batcat
(( $+commands[fdfind] && ! $+commands[fd] )) && alias fd=fdfind

# Container detection (used by prompt / helpers)
if [[ -f /.dockerenv || -f /run/.containerenv ]]; then
  export IN_CONTAINER=1
fi
