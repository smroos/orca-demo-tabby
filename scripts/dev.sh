#!/usr/bin/env bash
# Runs the Vite dev server. In an Orca worktree terminal it also opens
# that worktree's browser tab on whichever port Vite picked.
set -u

if [ -z "${ORCA_WORKTREE_ID:-}" ] || ! command -v orca >/dev/null 2>&1; then
  exec npx --no-install vite "$@"
fi

worktree="path:$(git rev-parse --show-toplevel)"
opened=0

npx --no-install vite "$@" 2>&1 | while IFS= read -r line; do
  printf '%s\n' "$line"
  if [ "$opened" -eq 0 ]; then
    clean=$(printf '%s' "$line" | sed $'s/\x1b\\[[0-9;]*m//g')
    if [[ "$clean" =~ Local:[[:space:]]+(http://localhost:[0-9]+/?) ]]; then
      opened=1
      url="${BASH_REMATCH[1]}"
      if ! orca tab create --worktree "$worktree" --url "$url" --json >/dev/null 2>&1; then
        echo "Could not open an Orca browser tab. Open $url yourself."
      fi
    fi
  fi
done
