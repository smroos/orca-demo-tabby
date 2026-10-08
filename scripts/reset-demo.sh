#!/usr/bin/env bash
set -euo pipefail

yes=0
for arg in "$@"; do
  case "$arg" in
    --yes) yes=1 ;;
    *) echo "Unknown argument: $arg" >&2; echo "Usage: bash scripts/reset-demo.sh [--yes]" >&2; exit 2 ;;
  esac
done

root="$(git rev-parse --show-toplevel 2>/dev/null || true)"
if [ -z "$root" ] || [ "$root" != "$(pwd -P)" ]; then
  echo "Run this from the root of the main worktree." >&2
  exit 1
fi

name="$(node -p "require('./package.json').name" 2>/dev/null || true)"
if [ "$name" != "tabby" ]; then
  echo "package.json name is not tabby. Refusing to run." >&2
  exit 1
fi

git_common="$(cd "$(git rev-parse --git-common-dir)" && pwd -P)"
if [ "$git_common" != "$root/.git" ]; then
  echo "This is a linked worktree, not the main one. Refusing to run." >&2
  exit 1
fi

[ "$(git symbolic-ref --short HEAD 2>/dev/null)" = main ] || { echo "Check out main in the main worktree first." >&2; exit 1; }

if git rev-parse --verify --quiet refs/remotes/origin/main >/dev/null \
  && [ "$(git rev-parse refs/heads/main)" != "$(git rev-parse refs/remotes/origin/main)" ]; then
  echo "WARNING: local main differs from origin/main. Reset main to match origin/main before the next run." >&2
  echo
fi

worktrees=()
while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      path="${line#worktree }"
      if [ "$path" != "$root" ]; then
        worktrees+=("$path")
      fi
      ;;
  esac
done < <(git worktree list --porcelain)

branches=()
while IFS= read -r branch; do
  case "$branch" in
    main|demo/*) ;;
    *) branches+=("$branch") ;;
  esac
done < <(git for-each-ref --format='%(refname:lstrip=2)' refs/heads)

echo "Worktrees to remove:"
if [ "${#worktrees[@]}" -eq 0 ]; then echo "  (none)"; else printf '  %s\n' "${worktrees[@]}"; fi
echo "Branches to delete:"
if [ "${#branches[@]}" -eq 0 ]; then echo "  (none)"; else printf '  %s\n' "${branches[@]}"; fi

if [ "$yes" -ne 1 ]; then
  echo
  echo "Dry run only. Re-run with --yes to apply."
  exit 0
fi

failed=0
if [ "${#worktrees[@]}" -gt 0 ]; then
  for path in "${worktrees[@]}"; do
    git worktree remove --force --force "$path" || failed=1
  done
fi
if [ "${#branches[@]}" -gt 0 ]; then
  for branch in "${branches[@]}"; do
    git branch -D "$branch" || failed=1
  done
fi
git worktree prune

echo
echo "Reset finished. Refresh Orca so it drops the removed worktrees."
[ "$failed" -eq 0 ] || { echo "Some steps failed; see messages above." >&2; exit 1; }
