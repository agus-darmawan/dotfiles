#!/usr/bin/env bash
# tmux status segments — works on macOS and Linux (dev containers, Jetson).
# usage: status.sh <cpu|mem|docker|net|battery>

OS=$(uname -s)

cpu() {
  if [[ $OS == Darwin ]]; then
    local n
    n=$(sysctl -n hw.ncpu)
    ps -A -o %cpu= | awk -v n="$n" '{s+=$1} END {printf "%2d%%", s/n}'
  else
    local _ u ni sy id wa irq sirq st total idle cache pt pi pct=0
    read -r _ u ni sy id wa irq sirq st _ </proc/stat
    total=$((u + ni + sy + id + wa + irq + sirq + st))
    idle=$((id + wa))
    cache="${TMPDIR:-/tmp}/.tmux_cpu_${UID}"
    if [[ -f $cache ]]; then
      read -r pt pi <"$cache"
      local dt=$((total - pt)) di=$((idle - pi))
      ((dt > 0)) && pct=$(((100 * (dt - di)) / dt))
    fi
    echo "$total $idle" >"$cache"
    printf "%2d%%" "$pct"
  fi
}

mem() {
  if [[ $OS == Darwin ]]; then
    local ps total
    ps=$(sysctl -n hw.pagesize)
    total=$(sysctl -n hw.memsize)
    vm_stat | awk -v ps="$ps" -v t="$total" '
      /Pages active/              {a=$3}
      /Pages wired down/          {w=$4}
      /occupied by compressor/    {c=$5}
      END {printf "%.1f/%.0fG", (a+w+c)*ps/1073741824, t/1073741824}'
  else
    free -b | awk '/^Mem:/ {printf "%.1f/%.0fG", $3/1073741824, $2/1073741824}'
  fi
}

docker_seg() {
  command -v docker >/dev/null 2>&1 || return 0
  local ids
  ids=$(docker ps -q 2>/dev/null) || return 0 # daemon down → hide segment
  printf " %s " "$(grep -c . <<<"$ids")"
}

net() {
  local ip=""
  if [[ $OS == Darwin ]]; then
    ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
  else
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi
  [[ -n $ip ]] && printf "󰩟 %s " "$ip"
}

battery() {
  local pct="" ac=""
  if [[ $OS == Darwin ]]; then
    local out
    out=$(pmset -g batt 2>/dev/null) || return 0
    pct=$(grep -Eo '[0-9]+%' <<<"$out" | head -1 | tr -d '%')
    grep -q "AC Power" <<<"$out" && ac=1
  else
    local b
    for b in /sys/class/power_supply/BAT*; do
      [[ -r $b/capacity ]] || continue
      pct=$(<"$b/capacity")
      [[ $(<"$b/status") != Discharging ]] && ac=1
      break
    done
  fi
  [[ -z $pct ]] && return 0
  local icon
  if [[ -n $ac ]]; then icon="󰂄"
  elif ((pct > 80)); then icon="󰁹"
  elif ((pct > 50)); then icon="󰂀"
  elif ((pct > 20)); then icon="󰁾"
  else icon="󰂃"; fi
  printf "%s %s%% " "$icon" "$pct"
}

case "$1" in
  cpu) cpu ;;
  mem) mem ;;
  docker) docker_seg ;;
  net) net ;;
  battery) battery ;;
  *) echo "usage: $0 <cpu|mem|docker|net|battery>" >&2; exit 1 ;;
esac
