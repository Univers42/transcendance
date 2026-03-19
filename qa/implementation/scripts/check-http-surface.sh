#!/usr/bin/env bash
set -euo pipefail

declare -a URLS=()
declare -a COOKIE_NAMES=()

usage() {
  cat <<'EOF'
Usage:
  bash qa/implementation/scripts/check-http-surface.sh [--cookie-name NAME] <url> [url...]
EOF
}

while (($#)); do
  case "$1" in
    --cookie-name)
      shift
      [[ $# -gt 0 ]] || {
        printf 'Missing cookie name after --cookie-name\n' >&2
        exit 1
      }
      COOKIE_NAMES+=("$1")
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      URLS+=("$1")
      ;;
  esac
  shift
done

if ((${#URLS[@]} == 0)); then
  usage
  exit 1
fi

require_header() {
  local header_file="$1"
  local header_name="$2"

  grep -qi "^${header_name}:" "$header_file"
}

require_value() {
  local header_file="$1"
  local header_name="$2"
  local expected="$3"

  grep -Eiq "^${header_name}:[[:space:]]*${expected}\$" "$header_file"
}

for url in "${URLS[@]}"; do
  header_file="$(mktemp)"
  trap 'rm -f "$header_file"' EXIT

  if ! curl -fsSL -D "$header_file" -o /dev/null "$url"; then
    printf 'Failed to request %s\n' "$url" >&2
    rm -f "$header_file"
    exit 1
  fi

  failures=0

  if ! require_header "$header_file" 'content-security-policy' && ! require_header "$header_file" 'content-security-policy-report-only'; then
    printf '[%s] Missing Content-Security-Policy or Content-Security-Policy-Report-Only\n' "$url"
    failures=1
  fi

  if ! require_value "$header_file" 'x-content-type-options' 'nosniff'; then
    printf '[%s] Missing X-Content-Type-Options: nosniff\n' "$url"
    failures=1
  fi

  if ! require_header "$header_file" 'referrer-policy'; then
    printf '[%s] Missing Referrer-Policy\n' "$url"
    failures=1
  fi

  if ! require_header "$header_file" 'x-frame-options' && ! grep -Eiq '^content-security-policy:.*frame-ancestors' "$header_file"; then
    printf '[%s] Missing X-Frame-Options or CSP frame-ancestors\n' "$url"
    failures=1
  fi

  if [[ "$url" == https://* ]] && ! require_header "$header_file" 'strict-transport-security'; then
    printf '[%s] Missing Strict-Transport-Security for HTTPS endpoint\n' "$url"
    failures=1
  fi

  for cookie_name in "${COOKIE_NAMES[@]}"; do
    cookie_line="$(grep -Ei "^set-cookie:[[:space:]]*${cookie_name}=" "$header_file" | head -n 1 || true)"
    if [[ -z "$cookie_line" ]]; then
      printf '[%s] Missing Set-Cookie for %s\n' "$url" "$cookie_name"
      failures=1
      continue
    fi

    if ! grep -Eiq ';[[:space:]]*Secure([;[:space:]]|$)' <<<"$cookie_line"; then
      printf '[%s] Cookie %s is missing Secure\n' "$url" "$cookie_name"
      failures=1
    fi

    if ! grep -Eiq ';[[:space:]]*HttpOnly([;[:space:]]|$)' <<<"$cookie_line"; then
      printf '[%s] Cookie %s is missing HttpOnly\n' "$url" "$cookie_name"
      failures=1
    fi

    if ! grep -Eiq ';[[:space:]]*SameSite=' <<<"$cookie_line"; then
      printf '[%s] Cookie %s is missing SameSite\n' "$url" "$cookie_name"
      failures=1
    fi
  done

  rm -f "$header_file"
  trap - EXIT

  if (( failures )); then
    exit 1
  fi

  printf '[%s] HTTP surface checks passed.\n' "$url"
done
