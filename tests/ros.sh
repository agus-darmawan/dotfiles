#!/usr/bin/env bash
# ROS integration test (ROS 1 or ROS 2, e.g. the ros:noetic / ros:humble images):
# build a real package from Neovim, then use the zsh helpers on it.
set -eo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
distro=${ROS_DISTRO:-humble}
# shellcheck disable=SC1090
source "/opt/ros/$distro/setup.bash"

WS="$(mktemp -d)/ws"
export WS
mkdir -p "$WS/src"

if [[ $ROS_VERSION == 1 ]]; then
  pkg=demo_patrol
  mkdir -p "$WS/src/$pkg/src"
  cat >"$WS/src/$pkg/package.xml" <<EOF
<?xml version="1.0"?>
<package format="2">
  <name>$pkg</name>
  <version>0.0.1</version>
  <description>test</description>
  <maintainer email="ci@example.com">ci</maintainer>
  <license>MIT</license>
  <buildtool_depend>catkin</buildtool_depend>
</package>
EOF
  cat >"$WS/src/$pkg/CMakeLists.txt" <<EOF
cmake_minimum_required(VERSION 3.0.2)
project($pkg)
find_package(catkin REQUIRED)
catkin_package()
add_executable(patrol_node src/patrol_node.cpp)
EOF
  echo 'int main() { return 0; }' >"$WS/src/$pkg/src/patrol_node.cpp"
  tool=catkin
else
  command -v colcon >/dev/null || { apt-get update -qq && apt-get install -y -qq python3-colcon-common-extensions >/dev/null; }
  pkg=demo_patrol
  (cd "$WS/src" && ros2 pkg create --build-type ament_cmake --node-name patrol_node $pkg >/dev/null)
  tool=colcon
fi

echo "==> zsh: workspace found before the first build"
(cd "$WS/src/$pkg" && zsh -ic '[[ "$(rosws)" == "$WS" ]]' && echo "  ✓ rosws")

echo "==> neovim: $tool build from the editor (ROS $ROS_VERSION, $distro)"
log="$(mktemp)"
if ! NVIM_OFFLINE=1 nvim --headless "+lua dofile('$DOTFILES/tests/ros.lua')" >"$log" 2>&1; then
  cat "$log"
  [[ -n ${GITHUB_ACTIONS:-} ]] && echo "::error title=ros: neovim $tool build::$(tail -20 "$log" | sed 's/%/%25/g' | awk '{printf "%s%%0A", $0}')"
  exit 1
fi
cat "$log"

echo "==> zsh: ros helpers"
(cd "$WS/src/$pkg" && zsh -ic 'ros >/dev/null && [[ "$(rosws)" == "$WS" ]] && cbp '"$pkg"' >/dev/null' && echo "  ✓ ros · rosws · cbp")
