#!/usr/bin/env bash
# denter.sh <container> [workdir]
# Enter a container with the best shell available. Empty container → local shell in workdir.
container=${1:-}
dir=${2:-}

if [[ -z $container ]]; then
  [[ -n $dir ]] && { cd "$dir" || exit 1; }
  exec "${SHELL:-/bin/bash}" -l
fi

args=(-it -e "TERM=${TERM_CONTAINER:-xterm-256color}" -e "COLORTERM=truecolor")
[[ -n $dir ]] && args+=(-w "$dir")

exec docker exec "${args[@]}" "$container" sh -c \
  'if command -v zsh >/dev/null 2>&1; then exec zsh -l; elif command -v bash >/dev/null 2>&1; then exec bash -l; else exec sh; fi'
