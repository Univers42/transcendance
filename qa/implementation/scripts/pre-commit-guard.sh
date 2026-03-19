#!/usr/bin/env bash
set -euo pipefail

if [[ "${SKIP_PRE_COMMIT:-0}" == "1" ]]; then
  exit 0
fi

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT_DIR="$ROOT_DIR/qa/implementation/scripts"

mapfile -t STAGED_FILES < <(git -C "$ROOT_DIR" diff --cached --name-only --diff-filter=ACMR)

if ((${#STAGED_FILES[@]} == 0)); then
  printf 'Pre-commit guard: no staged files.\n'
  exit 0
fi

printf 'Running pre-commit guardrails...\n'

git -C "$ROOT_DIR" diff --cached --check

for staged_file in "${STAGED_FILES[@]}"; do
  case "$staged_file" in
    .env|.env.*|*/.env|*/.env.*)
      printf 'Blocked staged file: %s\n' "$staged_file" >&2
      printf 'Commit environment files through reviewed examples only.\n' >&2
      exit 1
      ;;
    *.pem|*.key|*.p12|*.pfx)
      printf 'Blocked secret-like file: %s\n' "$staged_file" >&2
      exit 1
      ;;
    playwright/.auth/*|*/playwright/.auth/*)
      printf 'Blocked Playwright auth state file: %s\n' "$staged_file" >&2
      exit 1
      ;;
  esac

  if [[ -f "$ROOT_DIR/$staged_file" ]]; then
    file_size="$(wc -c < "$ROOT_DIR/$staged_file")"
    if (( file_size > 512000 )); then
      printf 'Blocked large staged file over 500 KB: %s\n' "$staged_file" >&2
      exit 1
    fi
  fi
done

declare -a DEBUG_TARGETS=()
for staged_file in "${STAGED_FILES[@]}"; do
  case "$staged_file" in
    *.ts|*.tsx|*.js|*.jsx)
      [[ -f "$ROOT_DIR/$staged_file" ]] && DEBUG_TARGETS+=("$ROOT_DIR/$staged_file")
      ;;
  esac
done

if ((${#DEBUG_TARGETS[@]} > 0)); then
  if command -v rg >/dev/null 2>&1; then
    if rg -n -H '\bdebugger\b' -- "${DEBUG_TARGETS[@]}"; then
      printf 'Remove debugger statements before committing.\n' >&2
      exit 1
    fi
  else
    if grep -nHE '\bdebugger\b' "${DEBUG_TARGETS[@]}"; then
      printf 'Remove debugger statements before committing.\n' >&2
      exit 1
    fi
  fi
fi

bash "$SCRIPT_DIR/check-frontend-security.sh" --staged

printf 'Pre-commit guard passed.\n'
