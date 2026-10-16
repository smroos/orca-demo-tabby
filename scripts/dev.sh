#!/usr/bin/env bash
# Runs the Vite dev server. In a linked git worktree it labels the page footer
# with the worktree's name. In an Orca worktree terminal it also opens that
# worktree's browser tab on whichever port Vite picked.
set -u

toplevel="$(git rev-parse --show-toplevel)"
abs() { (cd "$1" && pwd -P); }
if [ "$(abs "$(git rev-parse --git-dir)")" != "$(abs "$(git rev-parse --git-common-dir)")" ]; then
  export VITE_TABBY_LANE="${VITE_TABBY_LANE:-$(basename "$toplevel")}"
fi

if [ -z "${ORCA_WORKTREE_ID:-}" ] || ! command -v orca >/dev/null 2>&1; then
  exec npx --no-install vite "$@"
fi

worktree="path:$toplevel"
opened=0

npx --no-install vite "$@" 2>&1 | while IFS= read -r line; do
  printf '%s\n' "$line"
  if [ "$opened" -eq 0 ]; then
    clean=$(printf '%s' "$line" | sed $'s/\x1b\\[[0-9;]*m//g')
    if [[ "$clean" =~ Local:[[:space:]]+(http://localhost:[0-9]+/?) ]]; then
      opened=1
      url="${BASH_REMATCH[1]}"
      if ! orca tab create --worktree "$worktree" --url "$url" --json >/dev/null 2>&1 </dev/null; then
        echo "Could not open an Orca browser tab. Open $url yourself."
      fi
    fi
  fi
done
