# ── Aliases & small helpers ──────────────────────────────────

# editor
alias v=nvim vi=nvim vim=nvim
alias vc='nvim ~/dotfiles'

# ls → eza
if (( $+commands[eza] )); then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --git --group-directories-first --time-style=relative'
  alias la='eza -la --icons --git --group-directories-first --time-style=relative'
  alias lt='eza --tree --level=2 --icons --git-ignore'
  alias lT='eza --tree --level=4 --icons --git-ignore'
else
  alias ll='ls -lh' la='ls -lah'
fi

(( $+commands[bat] || $+commands[batcat] )) && alias cat='bat --paging=never --style=plain'

# git
alias g=git
alias lg=lazygit
alias gs='git status -sb'
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gca='git commit --amend --no-edit'
alias gd='git diff'
alias gds='git diff --staged'
alias gco='git checkout'
alias gsw='git switch'
alias gcb='git switch -c'
alias gl='git pull'
alias gf='git fetch --all --prune'
alias glog='git log --graph --oneline --decorate -20'
alias gst='git stash'
alias gstp='git stash pop'

# tmux
alias t='tmux new-session -A -s main'
alias ta='tmux attach'
alias tl='tmux ls'
alias tk='tmux kill-session -t'
alias ts='~/.config/tmux/scripts/sessionizer.sh'

# system
alias zr='exec zsh'
alias dot='cd ~/dotfiles'
(( $+commands[btop] )) && alias top='btop'
alias ports='lsof -iTCP -sTCP:LISTEN -n -P'
alias path='print -l $path'
alias serve='python3 -m http.server'
alias rsy='rsync -avhP'
alias mkd='mkdir -p'

if [[ $OSTYPE == darwin* ]]; then
  alias brewup='brew update && brew upgrade && brew cleanup'
  alias flushdns='sudo dscacheutil -flushcache && sudo killall -HUP mDNSResponder'
fi

# local IPs (handy on robot LANs)
myip() {
  if [[ $OSTYPE == darwin* ]]; then
    ifconfig | awk '/inet / && $2 != "127.0.0.1" {print $2}'
  else
    hostname -I | tr ' ' '\n' | sed '/^$/d'
  fi
}

# mkdir + cd
take() { mkdir -p "$1" && cd "$1"; }

# extract anything
ex() {
  case $1 in
    *.tar.bz2|*.tbz2) tar xjf "$1" ;;
    *.tar.gz|*.tgz)   tar xzf "$1" ;;
    *.tar.xz)         tar xJf "$1" ;;
    *.tar.zst)        tar --zstd -xf "$1" ;;
    *.tar)            tar xf "$1" ;;
    *.zip)            unzip "$1" ;;
    *.gz)             gunzip "$1" ;;
    *.7z)             7z x "$1" ;;
    *) echo "ex: don't know how to extract '$1'" ;;
  esac
}
