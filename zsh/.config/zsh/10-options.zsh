# ── Options, history, completion, keys ──────────────────────

HISTFILE="$XDG_STATE_HOME/zsh/history"
[[ -d ${HISTFILE:h} ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=100000
SAVEHIST=100000

setopt auto_cd auto_pushd pushd_ignore_dups pushd_silent
setopt extended_history share_history hist_ignore_all_dups hist_ignore_space hist_reduce_blanks hist_verify
setopt interactive_comments no_beep correct
setopt complete_in_word always_to_end
setopt glob_dots extended_glob

# completion
_zcomp="$XDG_CACHE_HOME/zsh/zcompdump"
[[ -d ${_zcomp:h} ]] || mkdir -p "${_zcomp:h}"
autoload -Uz compinit
if [[ -n $_zcomp(#qN.mh+24) ]]; then compinit -d "$_zcomp"; else compinit -C -d "$_zcomp"; fi
unset _zcomp

zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*'
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' menu no
zstyle ':completion:*:descriptions' format '[%d]'
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path "$XDG_CACHE_HOME/zsh/zcompcache"

# emacs-style line editing, plus a few vim-ish niceties
bindkey -e
bindkey '^[[A' history-search-backward
bindkey '^[[B' history-search-forward
bindkey '^P' history-search-backward
bindkey '^N' history-search-forward
bindkey '^[[1;3C' forward-word   # alt-right
bindkey '^[[1;3D' backward-word  # alt-left
bindkey '^[f' forward-word
bindkey '^[b' backward-word

# ctrl-x ctrl-e: edit command in nvim
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey '^X^E' edit-command-line
