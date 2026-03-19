#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"

if [[ -d "$ROOT_DIR/vendor/scripts/hooks" ]]; then
  HOOKS_PATH="vendor/scripts/hooks"
else
  HOOKS_PATH="qa/implementation/hooks"
fi

git -C "$ROOT_DIR" config --local core.hooksPath "$HOOKS_PATH"
find "$ROOT_DIR/$HOOKS_PATH" -maxdepth 1 -type f -exec chmod +x {} +

printf 'Activated git hooks at %s\n' "$HOOKS_PATH"
