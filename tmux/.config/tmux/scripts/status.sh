#!/usr/bin/env bash
# tmux status segments, plain ASCII. tmux runs on the Mac; SSH panes show remote shells inside it.
# usage: status.sh <cpu|gpu|mem|temp|netspeed|docker|tunnel|net|battery>
#
# gpu: ioreg (no extra tools). temp: macmon (brew install macmon, Apple Silicon), hidden without it.
# A few segments keep a Linux fallback for when tmux is started on a Linux box.

OS=$(uname -s)
CACHE="${TMPDIR:-/tmp}"
CACHE=${CACHE%/}

cpu() {
  if [[ $OS == Darwin ]]; then
    local n
    n=$(sysctl -n hw.ncpu)
    ps -A -o %cpu= | awk -v n="$n" '{s+=$1} END {printf "CPU %d%% ", s/n}'
  else
    local _ u ni sy id wa irq sirq st total idle cache pt pi pct=0
    read -r _ u ni sy id wa irq sirq st _ </proc/stat
    total=$((u + ni + sy + id + wa + irq + sirq + st))
    idle=$((id + wa))
    cache="$CACHE/.tmux_cpu_${UID}"
    if [[ -f $cache ]]; then
      read -r pt pi <"$cache"
      local dt=$((total - pt)) di=$((idle - pi))
      ((dt > 0)) && pct=$(((100 * (dt - di)) / dt))
    fi
    echo "$total $idle" >"$cache"
    printf "CPU %d%% " "$pct"
  fi
}

# GPU busy %: Apple Silicon and Intel Macs expose it in the IOAccelerator statistics
gpu() {
  [[ $OS == Darwin ]] || return 0
  local pct
  pct=$(ioreg -r -d 1 -w 0 -c IOAccelerator 2>/dev/null |
    grep -o '"Device Utilization %"=[0-9]*' | head -1 | cut -d= -f2)
  [[ -n $pct ]] && printf "GPU %d%% " "$pct"
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
      END {printf "RAM %.1f/%.0fG ", (a+w+c)*ps/1073741824, t/1073741824}'
  else
    awk '/^MemTotal:/ {t=$2} /^MemAvailable:/ {a=$2} END {printf "RAM %.1f/%.0fG ", (t-a)/1048576, t/1048576}' /proc/meminfo
  fi
}

mtime() { stat -c %Y "$1" 2>/dev/null || stat -f %m "$1" 2>/dev/null || echo 0; } # GNU, then BSD (macOS)

# CPU temperature (°C). macmon needs ~1 s per sample, so it refreshes a cache in the
# background and the segment prints the last value.
temp() {
  if [[ $OS == Darwin ]]; then
    command -v macmon >/dev/null 2>&1 || return 0
    local f="$CACHE/.tmux_macmon_${UID}.json" now
    now=$(date +%s)
    if ((now - $(mtime "$f") > 8)); then
      touch "$f" # one refresh at a time
      (macmon pipe -s 1 -i 500 >"$f.tmp" 2>/dev/null && mv "$f.tmp" "$f") </dev/null >/dev/null 2>&1 &
    fi
    [[ -s $f ]] || return 0
    jq -r '.temp.cpu_temp_avg // empty | floor | "\(.)C "' "$f" 2>/dev/null
  else
    local z t max=0
    for z in /sys/class/thermal/thermal_zone*/temp; do
      [[ -r $z ]] || continue
      t=$(<"$z")
      ((t > max)) && max=$t
    done
    ((max > 0)) && printf "%dC " $((max / 1000))
  fi
}

# download / upload speed of the default interface since the last refresh
netspeed() {
  local iface rx tx
  if [[ $OS == Darwin ]]; then
    iface=$(route -n get default 2>/dev/null | awk '/interface:/ {print $2; exit}')
    [[ -n $iface ]] || return 0
    read -r rx tx < <(netstat -ibn 2>/dev/null | awk -v i="$iface" '$1 == i && $3 ~ /^<Link/ {print $7, $10; exit}')
  else
    iface=$(ip route show default 2>/dev/null | awk '{print $5; exit}')
    [[ -r /sys/class/net/$iface/statistics/rx_bytes ]] || return 0
    rx=$(<"/sys/class/net/$iface/statistics/rx_bytes")
    tx=$(<"/sys/class/net/$iface/statistics/tx_bytes")
  fi
  [[ -n $rx && -n $tx ]] || return 0

  local f="$CACHE/.tmux_net_${UID}" now pt prx ptx
  now=$(date +%s)
  if [[ -f $f ]]; then
    read -r pt prx ptx <"$f"
    echo "$now $rx $tx" >"$f"
    local dt=$((now - pt))
    ((dt > 0 && rx >= prx && tx >= ptx)) || return 0
    awk -v d=$(((rx - prx) / dt)) -v u=$(((tx - ptx) / dt)) '
      function h(b) {
        if (b >= 1048576) return sprintf("%.1fM", b / 1048576)
        if (b >= 1024) return sprintf("%.0fK", b / 1024)
        return b "B"
      }
      END {printf "D %s U %s ", h(d), h(u)}' </dev/null
  else
    echo "$now $rx $tx" >"$f"
  fi
}

docker_seg() {
  command -v docker >/dev/null 2>&1 || return 0
  local ids
  ids=$(docker ps -q 2>/dev/null) || return 0 # daemon down: hide the segment
  printf "docker %s " "$(grep -c . <<<"$ids")"
}

# Cloudflare Tunnel up? (hidden when cloudflared is not running)
tunnel() {
  pgrep -x cloudflared >/dev/null 2>&1 && printf "tunnel "
}

net() {
  local ip=""
  if [[ $OS == Darwin ]]; then
    ip=$(ipconfig getifaddr en0 2>/dev/null || ipconfig getifaddr en1 2>/dev/null)
  else
    ip=$(hostname -I 2>/dev/null | awk '{print $1}')
  fi
  [[ -n $ip ]] && printf "%s " "$ip"
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
  printf "BAT %s%%%s " "$pct" "${ac:++}"
}

case "$1" in
  cpu) cpu ;;
  gpu) gpu ;;
  mem) mem ;;
  temp) temp ;;
  netspeed) netspeed ;;
  docker) docker_seg ;;
  tunnel) tunnel ;;
  net) net ;;
  battery) battery ;;
  *) echo "usage: $0 <cpu|gpu|mem|temp|netspeed|docker|tunnel|net|battery>" >&2; exit 1 ;;
esac
exit 0 # a hidden segment is not an error
