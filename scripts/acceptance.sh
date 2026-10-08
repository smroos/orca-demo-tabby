#!/usr/bin/env bash
set -euo pipefail

cd "$(dirname "$0")/.."

if git rev-parse --verify --quiet "refs/heads/demo/acceptance" >/dev/null; then
  ref="demo/acceptance"
elif git rev-parse --verify --quiet "refs/remotes/origin/demo/acceptance" >/dev/null; then
  ref="origin/demo/acceptance"
else
  echo "Cannot find demo/acceptance or origin/demo/acceptance. Run git fetch and try again." >&2
  exit 2
fi

mkdir -p .acceptance
git show "$ref:acceptance/split.acceptance.test.ts" > .acceptance/split.acceptance.test.ts

status=0
npx --no-install vitest run --config vitest.acceptance.config.ts || status=$?
exit "$status"
