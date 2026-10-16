#!/usr/bin/env bash
# ROS 2 integration test (needs a sourced ROS 2 install, e.g. the ros:humble image).
set -eo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
distro=${ROS_DISTRO:-humble}
# shellcheck disable=SC1090
source "/opt/ros/$distro/setup.bash"

command -v colcon >/dev/null || { apt-get update -qq && apt-get install -y -qq python3-colcon-common-extensions >/dev/null; }

WS="$(mktemp -d)/ros2_ws"
export WS
mkdir -p "$WS/src"
(cd "$WS/src" && ros2 pkg create --build-type ament_cmake --node-name patrol_node demo_patrol >/dev/null)

echo "==> neovim: colcon build from the editor"
NVIM_OFFLINE=1 nvim --headless "+lua dofile('$DOTFILES/tests/ros.lua')"

echo "==> zsh: ros helpers"
(cd "$WS/src/demo_patrol" && zsh -ic 'ros >/dev/null && [[ "$(rosws)" == "$WS" ]] && cbp demo_patrol >/dev/null' && echo "  ✓ ros · rosws · cbp")
