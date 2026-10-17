# ── ROS 2 (only where /opt/ros exists: containers, robots — never the Mac) ──
# Base ROS is auto-sourced (set ROS_AUTO=0 to skip).
#   ros [distro]      source base + nearest workspace overlay
#   rosws             print nearest colcon workspace root
#   rosdomain <id>    set ROS_DOMAIN_ID (shows in the prompt)
#   rmw <cyclone|fast|zenoh>
#   cb / cbp / cbu / ct / rcl   colcon helpers (always run from ws root)
#   rtopic rnode rsrv rif rparam   fzf pickers
[[ -d /opt/ros ]] || return 0

_ros_detect_distro() {
  local d
  for d in ${ROS_DISTRO:-} jazzy humble iron rolling kilted; do
    [[ -n $d && -f /opt/ros/$d/setup.zsh ]] && { echo $d; return; }
  done
}

rosws() {
  local d=${1:-$PWD}
  while [[ $d != / ]]; do
    [[ -d $d/src && ( -d $d/install || -d $d/build || -f $d/colcon.meta ) ]] && { echo $d; return 0; }
    d=${d:h}
  done
  return 1
}

ros() {
  local distro=${1:-$(_ros_detect_distro)}
  [[ -f /opt/ros/$distro/setup.zsh ]] || { print -P "%F{red}✗ ROS '$distro' not found in /opt/ros%f"; return 1; }
  source /opt/ros/$distro/setup.zsh
  local ws; ws=$(rosws) && [[ -f $ws/install/setup.zsh ]] && {
    source $ws/install/setup.zsh
    print -P "%F{cyan}󰚩 $distro%f + overlay %F{green}${ws/#$HOME/~}%f"
  } || print -P "%F{cyan}󰚩 $distro%f"
}

rosdomain() {
  export ROS_DOMAIN_ID=${1:?usage: rosdomain <0-101>}
  print -P "%F{cyan}ROS_DOMAIN_ID=%f$ROS_DOMAIN_ID"
}

rmw() {
  case $1 in
    cyclone) export RMW_IMPLEMENTATION=rmw_cyclonedds_cpp ;;
    fast)    export RMW_IMPLEMENTATION=rmw_fastrtps_cpp ;;
    zenoh)   export RMW_IMPLEMENTATION=rmw_zenoh_cpp ;;
    *) echo "RMW_IMPLEMENTATION=${RMW_IMPLEMENTATION:-<default>}  (rmw cyclone|fast|zenoh)"; return ;;
  esac
  echo "RMW_IMPLEMENTATION=$RMW_IMPLEMENTATION"
}

# merge build/*/compile_commands.json → ws root (for clangd)
_ros_compdb() {
  local ws=${1:-$(rosws)} files
  files=($ws/build/*/compile_commands.json(N))
  (( ${#files} )) || return 0
  if (( $+commands[jq] )); then
    jq -s 'add' $files > $ws/compile_commands.json
  else
    python3 -c 'import json,sys; print(json.dumps(sum((json.load(open(f)) for f in sys.argv[1:]), [])))' $files > $ws/compile_commands.json
  fi
  print -P "%F{8}compile_commands.json: ${#files} pkgs merged%f"
}

cb() {
  local ws; ws=$(rosws) || { print -P "%F{red}✗ not inside a colcon workspace%f"; return 1; }
  (
    cd $ws &&
    colcon build --symlink-install "$@" \
      --cmake-args -DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-RelWithDebInfo}
  ) && _ros_compdb $ws && [[ -f $ws/install/setup.zsh ]] && source $ws/install/setup.zsh
}
cbp() { cb --packages-select "$@"; }
cbu() { cb --packages-up-to "$@"; }
ct() {
  local ws; ws=$(rosws) || return 1
  ( cd $ws && colcon test --packages-select "$@" && colcon test-result --verbose )
}
rcl() {
  local ws; ws=$(rosws) || return 1
  read -q "?remove build/ install/ log/ in ${ws/#$HOME/~}? [y/N] " && rm -rf $ws/{build,install,log} && echo "\ncleaned"
}

# pickers ------------------------------------------------------
_ros_need() { (( $+commands[ros2] )) || { print -P "%F{red}✗ ros2 not found — run 'ros' first%f"; return 1; }; }

rtopic() {
  _ros_need || return
  local t; t=$(ros2 topic list -t | fzf --prompt='󰚩 topic ❯ ' \
    --preview 'ros2 topic info -v {1}' --preview-window=right:55%:wrap | awk '{print $1}') || return
  [[ -n $t ]] && { print -s "ros2 topic echo $t"; ros2 topic echo $t "$@"; }
}
rhz()   { _ros_need || return; local t; t=$(ros2 topic list | fzf --prompt='hz ❯ ') && ros2 topic hz $t; }
rnode() {
  _ros_need || return
  local n; n=$(ros2 node list | fzf --prompt='󰚩 node ❯ ' --preview 'ros2 node info {}' --preview-window=right:60%) || return
  ros2 node info $n
}
rsrv()  { _ros_need || return; local s; s=$(ros2 service list -t | fzf --prompt='srv ❯ ' | awk '{print $1}') && ros2 service type $s; }
rif()   { _ros_need || return; local i; i=$(ros2 interface list | sed 's/^ *//' | grep / | fzf --prompt='iface ❯ ' --preview 'ros2 interface show {}') && ros2 interface show $i; }
rparam() {
  _ros_need || return
  local n; n=$(ros2 node list | fzf --prompt='params of ❯ ') || return
  ros2 param dump $n
}

alias rtl='ros2 topic list -t'
alias rte='ros2 topic echo'
alias rnl='ros2 node list'
alias rl='ros2 launch'
alias rr='ros2 run'
alias rbag='ros2 bag'
alias rdoc='ros2 doctor --report'
alias rqt-graph='ros2 run rqt_graph rqt_graph'

# auto-source base ROS (inside containers / robots)
if [[ ${ROS_AUTO:-1} == 1 && -z $AMENT_PREFIX_PATH ]]; then
  _d=$(_ros_detect_distro)
  [[ -n $_d ]] && source /opt/ros/$_d/setup.zsh
  unset _d
fi

# colcon / ros2 argcomplete
if (( $+commands[register-python-argcomplete3] )); then
  autoload -U bashcompinit && bashcompinit
  eval "$(register-python-argcomplete3 ros2 2>/dev/null)"
  eval "$(register-python-argcomplete3 colcon 2>/dev/null)"
fi
