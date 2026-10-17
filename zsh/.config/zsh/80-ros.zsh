# ── ROS 1 + ROS 2 (only where /opt/ros exists: containers, robots) ──
#   ros [distro]       source the distro + the nearest workspace overlay
#   rosws              print the workspace root (colcon or catkin)
#   cb / cbp <pkg>     build workspace / packages (colcon for ROS 2, catkin for ROS 1)
#   ct <pkg>           run tests
#   rcl                remove build/ install/ devel/ log/
#   rosdomain <id>     ROS 2: ROS_DOMAIN_ID
#   rosmaster <host>   ROS 1: ROS_MASTER_URI (+ ROS_IP of this machine)
#   rtopic rnode       fzf pickers (rostopic / ros2 topic …)
[[ -d /opt/ros ]] || return 0

_ros_detect() {
  local d
  for d in ${ROS_DISTRO:-} jazzy humble iron rolling kilted noetic melodic; do
    [[ -n $d && -f /opt/ros/$d/setup.zsh ]] && { echo $d; return }
  done
}

rosws() {
  local d=${1:-$PWD} p pkg=
  # inside a package: the workspace is the folder whose src/ holds it (also before the first build)
  p=$d
  while [[ $p != / ]]; do
    [[ -f $p/package.xml ]] && { pkg=$p; break }
    p=${p:h}
  done
  local -a pkgs
  while [[ $d != / ]]; do
    if [[ -d $d/src ]]; then
      if [[ -n $pkg ]]; then
        [[ $pkg == $d/src/* ]] && { echo $d; return 0 }
      else
        pkgs=($d/src/*/package.xml(N) $d/src/*/*/package.xml(N))
        if (( $#pkgs )) || [[ -d $d/install || -d $d/build || -d $d/devel || -d $d/.catkin_tools || -f $d/.catkin_workspace ]]; then
          echo $d; return 0
        fi
      fi
    fi
    d=${d:h}
  done
  return 1
}

ros() {
  local distro=${1:-$(_ros_detect)}
  [[ -f /opt/ros/$distro/setup.zsh ]] || { print -P "%F{red}✗ no ROS '$distro' in /opt/ros%f"; return 1 }
  source /opt/ros/$distro/setup.zsh
  local ws overlay
  ws=$(rosws)
  for overlay in $ws/install/setup.zsh $ws/devel/setup.zsh; do
    [[ -n $ws && -f $overlay ]] && { source $overlay; print -P "%F{cyan}󰚩 $distro%f + %F{green}${overlay/#$HOME/~}%f"; return }
  done
  print -P "%F{cyan}󰚩 $distro%f"
}

rosdomain() { export ROS_DOMAIN_ID=${1:?usage: rosdomain <0-101>}; echo "ROS_DOMAIN_ID=$ROS_DOMAIN_ID" }

rosmaster() {
  local host=${1:-localhost}
  export ROS_MASTER_URI="http://$host:11311"
  export ROS_IP=$(hostname -I 2>/dev/null | awk '{print $1}')
  [[ $host == localhost ]] && unset ROS_MASTER || export ROS_MASTER=$host
  echo "ROS_MASTER_URI=$ROS_MASTER_URI  ROS_IP=$ROS_IP"
}

# build/*/compile_commands.json (+ catkin_make's build/compile_commands.json) → ws root, for clangd
_ros_compdb() {
  local ws=$1 files
  files=($ws/build/*/compile_commands.json(N) $ws/build/compile_commands.json(N))
  (( ${#files} )) || return 0
  python3 -c 'import json,sys; print(json.dumps(sum((json.load(open(f)) for f in sys.argv[1:]), [])))' $files >$ws/compile_commands.json
}

_ros_build() { # [packages...]
  local ws; ws=$(rosws) || { print -P "%F{red}✗ not inside a workspace%f"; return 1 }
  local -a cm=(-DCMAKE_EXPORT_COMPILE_COMMANDS=ON -DCMAKE_BUILD_TYPE=${CMAKE_BUILD_TYPE:-RelWithDebInfo})
  (
    cd $ws || exit 1
    if [[ ${ROS_VERSION:-2} == 1 ]]; then
      if (( $+commands[catkin] )) && [[ -d .catkin_tools || ! -d devel ]]; then
        catkin build "$@" --cmake-args $cm
      else
        catkin_make $cm -DCATKIN_WHITELIST_PACKAGES="${(j:;:)@}"
      fi
    else
      colcon build --symlink-install ${@:+--packages-up-to} "$@" --cmake-args $cm
    fi
  ) || return
  _ros_compdb $ws
  local overlay
  for overlay in $ws/install/setup.zsh $ws/devel/setup.zsh; do
    [[ -f $overlay ]] && { source $overlay; break }
  done
}
cb() { _ros_build }
cbp() { _ros_build "${@:?usage: cbp <pkg> [pkg...]}" }

ct() {
  local ws; ws=$(rosws) || return 1
  if [[ ${ROS_VERSION:-2} == 1 ]]; then
    (cd $ws && catkin_make run_tests ${1:+-DCATKIN_WHITELIST_PACKAGES=$1} && catkin_test_results build/test_results)
  else
    (cd $ws && colcon test ${1:+--packages-select $1} && colcon test-result --verbose)
  fi
}

rcl() {
  local ws; ws=$(rosws) || return 1
  read -q "?remove build/ install/ devel/ log/ in ${ws/#$HOME/~}? [y/N] " &&
    rm -rf $ws/{build,install,devel,log,.catkin_tools} && echo "\ncleaned"
}

# pickers (ROS 1 or 2, depending on the sourced distro)
rtopic() {
  local t
  if [[ ${ROS_VERSION:-2} == 1 ]]; then
    t=$(rostopic list | fzf --prompt='topic ❯ ' --preview 'rostopic info {}') && rostopic echo $t
  else
    t=$(ros2 topic list | fzf --prompt='topic ❯ ' --preview 'ros2 topic info -v {}') && ros2 topic echo $t
  fi
}
rnode() {
  local n
  if [[ ${ROS_VERSION:-2} == 1 ]]; then
    n=$(rosnode list | fzf --prompt='node ❯ ' --preview 'rosnode info {}') && rosnode info $n
  else
    n=$(ros2 node list | fzf --prompt='node ❯ ' --preview 'ros2 node info {}') && ros2 node info $n
  fi
}

# source the distro automatically (ROS_AUTO=0 to skip)
if [[ ${ROS_AUTO:-1} == 1 && -z $ROS_DISTRO$AMENT_PREFIX_PATH$ROS_PACKAGE_PATH ]]; then
  _d=$(_ros_detect)
  [[ -n $_d ]] && source /opt/ros/$_d/setup.zsh
  unset _d
elif [[ -n $ROS_DISTRO && -z $ROS_VERSION && -f /opt/ros/$ROS_DISTRO/setup.zsh ]]; then
  source /opt/ros/$ROS_DISTRO/setup.zsh   # image only set ROS_DISTRO (official ros images)
fi

if [[ ${ROS_VERSION:-} == 1 ]]; then
  alias rl=roslaunch rr=rosrun rtl='rostopic list' rte='rostopic echo' rnl='rosnode list' rbag=rosbag
else
  alias rl='ros2 launch' rr='ros2 run' rtl='ros2 topic list -t' rte='ros2 topic echo' rnl='ros2 node list' rbag='ros2 bag'
fi

# ros2 / colcon tab completion
if (( $+commands[register-python-argcomplete3] || $+commands[register-python-argcomplete] )); then
  autoload -U bashcompinit && bashcompinit
  _rac=${commands[register-python-argcomplete3]:-register-python-argcomplete}
  (( $+commands[ros2] )) && eval "$($_rac ros2 2>/dev/null)"
  (( $+commands[colcon] )) && eval "$($_rac colcon 2>/dev/null)"
  unset _rac
fi
