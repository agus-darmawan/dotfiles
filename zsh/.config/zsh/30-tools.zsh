# ── Tool integrations ────────────────────────────────────────

# fzf (catppuccin mocha)
export FZF_DEFAULT_OPTS="\
--height=45% --layout=reverse --border=rounded --info=inline-right \
--prompt='❯ ' --pointer='▶' --marker='✓' \
--color=bg+:#313244,bg:-1,spinner:#f5e0dc,hl:#f38ba8 \
--color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc \
--color=marker:#b4befe,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8 \
--color=selected-bg:#45475a,border:#6c7086,label:#cdd6f4"

if (( $+commands[fd] )); then
  export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git --exclude node_modules'
elif (( $+commands[fdfind] )); then
  export FZF_DEFAULT_COMMAND='fdfind --type f --hidden --follow --exclude .git --exclude node_modules'
fi
export FZF_CTRL_T_COMMAND=$FZF_DEFAULT_COMMAND
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:300 {} 2>/dev/null || cat {}'"
export FZF_ALT_C_OPTS="--preview 'eza --tree --level=2 --icons --color=always {} 2>/dev/null || ls {}'"

if (( $+commands[fzf] )); then
  source <(fzf --zsh 2>/dev/null) 2>/dev/null
fi

# zoxide: `cd` learns your dirs, `cdi` = interactive
(( $+commands[zoxide] )) && eval "$(zoxide init zsh --cmd cd)"

# atuin: ctrl-r full-screen history search (synced optional)
(( $+commands[atuin] )) && eval "$(atuin init zsh --disable-up-arrow)"

# starship prompt
(( $+commands[starship] )) && eval "$(starship init zsh)"

# yazi: `y` changes dir to where you quit
y() {
  local tmp cwd
  tmp="$(mktemp -t yazi-cwd.XXXXXX)"
  yazi "$@" --cwd-file="$tmp"
  if cwd="$(<"$tmp")" && [[ -n $cwd && $cwd != $PWD ]]; then builtin cd -- "$cwd"; fi
  rm -f -- "$tmp"
}
