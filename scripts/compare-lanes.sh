#!/usr/bin/env bash
# Compares every linked worktree ("lane") of this repo: acceptance test, unit
# tests, typecheck, and size of change. Inside Orca it also opens each lane's
# app as a browser tab in the main checkout so they can sit side by side.
#
# Run from the main checkout:  bash scripts/compare-lanes.sh [--no-tabs]
set -u

open_tabs=1
[ "${1:-}" = "--no-tabs" ] && open_tabs=0

git rev-parse --is-inside-work-tree >/dev/null 2>&1 || { echo "Run this inside the Tabby repo." >&2; exit 1; }
abs() { (cd "$1" && pwd -P); }
if [ "$(abs "$(git rev-parse --git-dir)")" != "$(abs "$(git rev-parse --git-common-dir)")" ]; then
  echo "Run this from the main checkout, not from a lane." >&2
  exit 1
fi
main="$(git rev-parse --show-toplevel)"
have_orca=0
command -v orca >/dev/null 2>&1 && have_orca=1

# The reference copy of the test harness: local main, else origin/main.
ref=""
for r in refs/heads/main refs/remotes/origin/main; do
  git rev-parse --verify --quiet "$r" >/dev/null && { ref="$r"; break; }
done

strip_ansi() { sed $'s/\x1b\\[[0-9;]*m//g'; }

# Turns Vitest output into "passed/total". Says "error" when no summary
# appears, and flags a test file that failed to load while every counted test passed.
score() {
  local out line passed total
  out="$(strip_ansi)"
  line="$(printf '%s\n' "$out" | grep -E '^[[:space:]]*Tests[[:space:]]+[0-9]' | tail -1)"
  total="$(printf '%s' "$line" | grep -oE '\([0-9]+\)' | tr -d '()')"
  [ -z "$total" ] && { echo "error"; return; }
  passed="$(printf '%s' "$line" | grep -oE '[0-9]+ passed' | grep -oE '[0-9]+')"
  if [ "${passed:-0}" = "$total" ] && printf '%s\n' "$out" | grep -qE '^[[:space:]]*Test Files.*failed'; then
    echo "${passed:-0}/$total + file error"
  else
    echo "${passed:-0}/$total"
  fi
}

harness_changed() {
  local f
  [ -z "$ref" ] && return 1
  for f in scripts/acceptance.sh vitest.acceptance.config.ts vitest.config.ts; do
    git show "$ref:$f" 2>/dev/null | cmp -s - "$1/$f" || return 0
  done
  return 1
}

lane_url() {
  local url
  [ "$have_orca" -eq 1 ] || return 0
  url="$(orca tab list --worktree "path:$1" --json 2>/dev/null \
    | grep -oE '"url": *"http://localhost:[0-9]+/?"' | head -1 \
    | grep -oE 'http://localhost:[0-9]+')"
  [ -n "$url" ] && curl -fsS -m 2 -o /dev/null "$url/" 2>/dev/null && echo "$url/"
}

lanes=()
while IFS= read -r line; do
  case "$line" in
    "worktree "*)
      path="${line#worktree }"
      [ "$path" = "$main" ] && continue
      if [ -d "$path" ]; then lanes+=("$path"); else echo "Skipped (folder missing): $path" >&2; fi ;;
  esac
done < <(git worktree list --porcelain)

if [ "${#lanes[@]}" -eq 0 ]; then
  echo "No lanes found. Create worktrees first."
  exit 0
fi

fmt="%-20s %-16s %-16s %-10s %-24s %s\n"
printf "$fmt" "Lane" "Acceptance" "Unit tests" "Typecheck" "Changes" "App"
printf "$fmt" "----" "----------" "----------" "---------" "-------" "---"

tabs_opened=0
for path in "${lanes[@]}"; do
  name="$(basename "$path")"

  if [ ! -e "$path/node_modules" ]; then
    acc="no node_modules"; unit="no node_modules"; tsc="-"
  elif harness_changed "$path"; then
    acc="SKIPPED: changed"; unit="SKIPPED: changed"; tsc="-"
  else
    acc="$(cd "$path" && bash scripts/acceptance.sh 2>&1 | score)"
    unit="$(cd "$path" && npx --no-install vitest run 2>&1 | score)"
    if (cd "$path" && npx --no-install tsc --noEmit >/dev/null 2>&1); then tsc="pass"; else tsc="FAIL"; fi
  fi

  base=""
  for r in refs/heads/main refs/remotes/origin/main; do
    base="$(git -C "$path" merge-base HEAD "$r" 2>/dev/null)" && [ -n "$base" ] && break
  done
  if [ -z "$base" ]; then
    changes="? (no main)"
  else
    stat="$(git -C "$path" diff --shortstat "$base" 2>/dev/null)"
    files="$(printf '%s' "$stat" | grep -oE '[0-9]+ file' | grep -oE '[0-9]+')"
    ins="$(printf '%s' "$stat" | grep -oE '[0-9]+ insertion' | grep -oE '[0-9]+')"
    del="$(printf '%s' "$stat" | grep -oE '[0-9]+ deletion' | grep -oE '[0-9]+')"
    new="$(git -C "$path" ls-files --others --exclude-standard | wc -l | tr -d ' ')"
    changes="${files:-0} files +${ins:-0} -${del:-0}, ${new} new"
  fi

  url="$(lane_url "$path")"
  printf "$fmt" "$name" "$acc" "$unit" "$tsc" "$changes" "${url:-no running app}"

  if [ "$open_tabs" -eq 1 ] && [ -n "$url" ]; then
    if orca tab list --worktree "path:$main" --json 2>/dev/null | grep -qF "\"$url\""; then
      tabs_opened=$((tabs_opened + 1))
    elif orca tab create --worktree "path:$main" --url "$url" --json >/dev/null 2>&1 </dev/null; then
      tabs_opened=$((tabs_opened + 1))
    else
      echo "  Could not open $url in the main checkout."
    fi
  fi
done

echo
echo "Acceptance and unit tests show passed/total. Changes are measured from where each lane started."
[ -z "$ref" ] && echo "Warning: no main or origin/main branch found, so the test harness was not checked for changes."
if [ "$open_tabs" -eq 1 ] && [ "$have_orca" -eq 1 ]; then
  echo "$tabs_opened of ${#lanes[@]} lanes have their app open as a browser tab in the main checkout."
fi
exit 0
