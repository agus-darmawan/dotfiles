# ── Docker ───────────────────────────────────────────────────

alias d=docker
alias dc='docker compose'
alias dcu='docker compose up -d'
alias dcd='docker compose down'
alias dcl='docker compose logs -f --tail=200'
alias dcb='docker compose build'
alias dps='docker ps --format "table {{.Names}}\t{{.Status}}\t{{.Image}}\t{{.Ports}}"'
alias dpsa='docker ps -a --format "table {{.Names}}\t{{.Status}}\t{{.Image}}"'
alias di='docker images'
alias lzd=lazydocker

_dpick() {
  docker ps ${1:-} --format '{{.Names}}\t{{.Image}}\t{{.Status}}' | awk -F'\t' '{printf "%-28s %-36s %s\n", $1, $2, $3}' |
    fzf --prompt=" ${2:-container} ❯ " ${3:-} --preview 'docker logs --tail 30 {1} 2>&1' --preview-window=down:40% |
    awk '{print $1}'
}

# shell into container (zsh > bash > sh), optional workdir
dsh() {
  local c=${1:-$(_dpick)}
  [[ -n $c ]] && ~/.config/tmux/scripts/denter.sh $c ${2-}
}
dlog()  { local c=${1:-$(_dpick)}; [[ -n $c ]] && docker logs -f --tail 200 $c; }
dstop() { local c; c=($(_dpick "" stop --multi)); (( ${#c} )) && docker stop $c; }
drm()   { local c; c=($(_dpick -a rm --multi)); (( ${#c} )) && docker rm $c; }
dstat() { docker stats --format "table {{.Name}}\t{{.CPUPerc}}\t{{.MemUsage}}\t{{.NetIO}}"; }
dclean() { docker system prune -f && docker volume prune -f; }

# run a GUI-less throwaway ROS container quickly
drosrun() {
  local distro=${1:-humble}
  docker run --rm -it --net=host -e ROS_DOMAIN_ID=${ROS_DOMAIN_ID:-0} ros:$distro bash
}
