# ── Plugins (tiny loader, no framework) ──────────────────────
# Cloned on first use into ~/.local/share/zsh/plugins. Update: plug-update

ZPLUGDIR="$XDG_DATA_HOME/zsh/plugins"

plug() {
  local repo=$1 name=${1:t} dir="$ZPLUGDIR/${1:t}" f
  if [[ ! -d $dir ]]; then
    (( $+commands[git] )) || return
    print -P "%F{blue}󰏗 installing $repo%f"
    git clone --depth=1 -q "https://github.com/$repo" "$dir" || return
  fi
  for f in "$dir/$name.plugin.zsh" "$dir/$name.zsh"; do
    [[ -f $f ]] && { source "$f"; return; }
  done
}

plug-update() {
  local d
  for d in "$ZPLUGDIR"/*(/N); do
    git -C "$d" pull -q --ff-only && print -P "%F{green}✓%f ${d:t}"
  done
}

plug Aloxaf/fzf-tab
plug zsh-users/zsh-autosuggestions
plug zdharma-continuum/fast-syntax-highlighting

ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=40
bindkey '^ ' autosuggest-accept   # ctrl-space accepts suggestion

# fzf-tab look
zstyle ':fzf-tab:*' fzf-flags --height=50% --border=rounded
zstyle ':fzf-tab:*' switch-group '<' '>'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --icons --color=always $realpath 2>/dev/null || ls -1 $realpath'
zstyle ':fzf-tab:complete:__zoxide_z:*' fzf-preview 'eza -1 --icons --color=always $realpath 2>/dev/null || ls -1 $realpath'
zstyle ':fzf-tab:complete:(nvim|vim|bat|cat):*' fzf-preview 'bat --color=always --style=numbers --line-range=:200 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:docker-(exec|logs|stop|start|restart):*' fzf-preview 'docker logs --tail 20 $word 2>&1'
zstyle ':fzf-tab:complete:ssh:*' fzf-preview 'ssh -G $word 2>/dev/null | grep -E "^(hostname|user|port) "'
