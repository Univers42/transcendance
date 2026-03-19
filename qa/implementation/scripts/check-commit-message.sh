#!/usr/bin/env bash
set -euo pipefail

if [[ "${SKIP_COMMIT_MSG:-0}" == "1" ]]; then
  exit 0
fi

MESSAGE_FILE="${1:-}"
[[ -n "$MESSAGE_FILE" ]] || {
  printf 'commit-msg hook requires the commit message file path.\n' >&2
  exit 1
}

SUBJECT_LINE="$(head -n 1 "$MESSAGE_FILE" | tr -d '\r')"

if [[ -z "$SUBJECT_LINE" ]]; then
  printf 'Commit message subject cannot be empty.\n' >&2
  exit 1
fi

if [[ "$SUBJECT_LINE" =~ ^Merge[[:space:]] ]] || [[ "$SUBJECT_LINE" =~ ^Revert[[:space:]]\" ]]; then
  exit 0
fi

if ! [[ "$SUBJECT_LINE" =~ ^(feat|fix|docs|style|refactor|test|chore|perf|ci|build|revert)\([a-z0-9][a-z0-9._/-]*\):[[:space:]].+ ]]; then
  printf 'Invalid commit message format.\n' >&2
  printf 'Expected: type(scope): Description starting with uppercase\n' >&2
  exit 1
fi

DESCRIPTION="${SUBJECT_LINE#*: }"
DESCRIPTION_LENGTH=${#DESCRIPTION}

if (( DESCRIPTION_LENGTH < 25 || DESCRIPTION_LENGTH > 170 )); then
  printf 'Commit description must be between 25 and 170 characters.\n' >&2
  exit 1
fi

if ! [[ "${DESCRIPTION:0:1}" =~ [A-Z] ]]; then
  printf 'Commit description must start with an uppercase letter.\n' >&2
  exit 1
fi

if [[ "$DESCRIPTION" == *. ]]; then
  printf 'Commit description must not end with a period.\n' >&2
  exit 1
fi

if grep -Eiq '(^fixup!|^squash!|\bWIP\b|\bdebug\b|\btemporary\b)' <<<"$SUBJECT_LINE"; then
  printf 'Commit message contains forbidden words or prefixes.\n' >&2
  exit 1
fi

printf 'Commit message check passed.\n'
