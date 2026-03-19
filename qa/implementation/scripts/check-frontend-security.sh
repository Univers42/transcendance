#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCAN_STAGED=0
declare -a INPUT_PATHS=()

usage() {
  cat <<'EOF'
Usage:
  bash qa/implementation/scripts/check-frontend-security.sh
  bash qa/implementation/scripts/check-frontend-security.sh --staged
  bash qa/implementation/scripts/check-frontend-security.sh <path> [path...]
EOF
}

while (($#)); do
  case "$1" in
    --staged)
      SCAN_STAGED=1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      INPUT_PATHS+=("$1")
      ;;
  esac
  shift
done

has_command() {
  command -v "$1" >/dev/null 2>&1
}

search_pattern() {
  local pattern="$1"
  shift

  if has_command rg; then
    rg -n -H -i -e "$pattern" -- "$@" 2>/dev/null || true
  else
    grep -RInE "$pattern" "$@" 2>/dev/null || true
  fi
}

is_frontend_target() {
  local path="$1"

  if [[ "$path" == "apps/frontend/index.html" ]]; then
    return 0
  fi

  if [[ "$path" != apps/frontend/src/* ]]; then
    return 1
  fi

  case "$path" in
    *.ts|*.tsx|*.js|*.jsx|*.html)
      return 0
      ;;
    *)
      return 1
      ;;
  esac
}

declare -a TARGETS=()

if (( SCAN_STAGED )); then
  while IFS= read -r staged_path; do
    [[ -n "$staged_path" ]] || continue
    if is_frontend_target "$staged_path" && [[ -e "$ROOT_DIR/$staged_path" ]]; then
      TARGETS+=("$ROOT_DIR/$staged_path")
    fi
  done < <(git -C "$ROOT_DIR" diff --cached --name-only --diff-filter=ACMR)
elif ((${#INPUT_PATHS[@]})); then
  for input_path in "${INPUT_PATHS[@]}"; do
    if [[ -d "$input_path" || -f "$input_path" ]]; then
      TARGETS+=("$input_path")
    elif [[ -d "$ROOT_DIR/$input_path" || -f "$ROOT_DIR/$input_path" ]]; then
      TARGETS+=("$ROOT_DIR/$input_path")
    fi
  done
else
  TARGETS+=("$ROOT_DIR/apps/frontend/src" "$ROOT_DIR/apps/frontend/index.html")
fi

if ((${#TARGETS[@]} == 0)); then
  printf 'Frontend security guard: no matching frontend files to scan.\n'
  exit 0
fi

declare -a FINDINGS=()

collect_findings() {
  local label="$1"
  local pattern="$2"
  local result

  result="$(search_pattern "$pattern" "${TARGETS[@]}")"
  if [[ -n "$result" ]]; then
    FINDINGS+=("$label"$'\n'"$result")
  fi
}

collect_findings "Raw React HTML sink" 'dangerouslySetInnerHTML'
collect_findings "Direct DOM HTML assignment" '(\.innerHTML\s*=|\.outerHTML\s*=|insertAdjacentHTML\s*\()'
collect_findings "Dynamic code execution" '(\beval\s*\(|new Function\s*\()'
collect_findings "Legacy document.write usage" 'document\.write\s*\('
collect_findings "Wildcard postMessage target" 'postMessage\s*\([^,]+,\s*["'\'']\*["'\'']'
collect_findings "Auth-like token stored in localStorage" 'localStorage\.(setItem|getItem)\s*\([^)]*(token|jwt|auth|session|refresh)'
collect_findings "Auth-like token stored in sessionStorage" 'sessionStorage\.(setItem|getItem)\s*\([^)]*(token|jwt|auth|session|refresh)'

if ((${#FINDINGS[@]} > 0)); then
  printf 'Frontend security guard failed.\n\n'
  for finding in "${FINDINGS[@]}"; do
    printf '[%s]\n\n' "$finding"
  done
  exit 1
fi

printf 'Frontend security guard passed.\n'
