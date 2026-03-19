#!/usr/bin/env bash
set -euo pipefail

if [[ "${SKIP_PRE_PUSH:-0}" == "1" ]]; then
  exit 0
fi

ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
SCRIPT_DIR="$ROOT_DIR/qa/implementation/scripts"
CONTAINER_NAME="${QA_DEV_CONTAINER:-transcendence-dev}"
RUN_TESTS="${QA_PRE_PUSH_RUN_TESTS:-0}"

printf 'Running pre-push guardrails...\n'

bash "$SCRIPT_DIR/check-frontend-security.sh"

validate_commit_range() {
  local range="$1"
  local tmp_file
  tmp_file="$(mktemp)"
  trap 'rm -f "$tmp_file"' RETURN

  while IFS=$'\t' read -r commit_hash subject; do
    [[ -n "$commit_hash" ]] || continue
    printf '%s\n' "$subject" > "$tmp_file"
    if ! bash "$SCRIPT_DIR/check-commit-message.sh" "$tmp_file" >/dev/null; then
      printf 'Outgoing commit failed commit-msg rules: %s %s\n' "$commit_hash" "$subject" >&2
      rm -f "$tmp_file"
      trap - RETURN
      exit 1
    fi
  done < <(git -C "$ROOT_DIR" log --format='%H%x09%s' "$range")

  rm -f "$tmp_file"
  trap - RETURN
}

CURRENT_BRANCH="$(git -C "$ROOT_DIR" branch --show-current)"

if UPSTREAM_REF="$(git -C "$ROOT_DIR" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null)"; then
  if [[ -n "$(git -C "$ROOT_DIR" rev-list "${UPSTREAM_REF}..HEAD" 2>/dev/null)" ]]; then
    validate_commit_range "${UPSTREAM_REF}..HEAD"
  fi
elif [[ -n "$CURRENT_BRANCH" ]] && git -C "$ROOT_DIR" show-ref --verify --quiet "refs/remotes/origin/$CURRENT_BRANCH"; then
  if [[ -n "$(git -C "$ROOT_DIR" rev-list "origin/$CURRENT_BRANCH..HEAD" 2>/dev/null)" ]]; then
    validate_commit_range "origin/$CURRENT_BRANCH..HEAD"
  fi
else
  tmp_file="$(mktemp)"
  trap 'rm -f "$tmp_file"' EXIT
  git -C "$ROOT_DIR" log -1 --format='%s' HEAD > "$tmp_file"
  bash "$SCRIPT_DIR/check-commit-message.sh" "$tmp_file" >/dev/null
  rm -f "$tmp_file"
  trap - EXIT
fi

require_docker_container() {
  if ! command -v docker >/dev/null 2>&1; then
    printf 'Pre-push guard requires Docker, but `docker` is not available in PATH.\n' >&2
    exit 1
  fi

  if ! docker info >/dev/null 2>&1; then
    DOCKER_INFO_ERR="$(docker info 2>&1 >/dev/null || true)"
    if grep -qi 'permission denied' <<<"$DOCKER_INFO_ERR"; then
      printf 'Pre-push guard requires Docker socket access.\n' >&2
      printf 'User `%s` cannot access /var/run/docker.sock.\n' "$(whoami)" >&2
      printf 'Fix Docker access, then retry the push.\n' >&2
    else
      printf 'Pre-push guard requires a running Docker daemon.\n' >&2
      printf 'Start Docker and retry the push.\n' >&2
    fi
    exit 1
  fi

  if ! docker ps --format '{{.Names}}' | grep -qx "$CONTAINER_NAME"; then
    printf 'Pre-push guard requires the `%s` container to be running.\n' "$CONTAINER_NAME" >&2
    printf 'Run `make docker-up` or `make dev` before pushing.\n' >&2
    exit 1
  fi
}

run_docker_checks() {
  printf 'Using Docker dev container `%s` for lint and typecheck.\n' "$CONTAINER_NAME"
  docker exec "$CONTAINER_NAME" sh -lc 'cd /app/apps/backend && pnpm exec prisma generate --schema=prisma/schema.prisma'
  docker exec "$CONTAINER_NAME" sh -lc 'cd /app/apps/backend && pnpm exec eslint .'
  docker exec "$CONTAINER_NAME" sh -lc 'cd /app/apps/frontend && pnpm exec eslint .'
  docker exec "$CONTAINER_NAME" sh -lc 'cd /app/apps/backend && pnpm exec tsc --noEmit'
  docker exec "$CONTAINER_NAME" sh -lc 'cd /app/apps/frontend && pnpm exec tsc --noEmit'

  if [[ "$RUN_TESTS" == "1" ]]; then
    docker exec "$CONTAINER_NAME" sh -lc 'cd /app/apps/backend && pnpm test'
  fi
}

require_docker_container
run_docker_checks

printf 'Pre-push guard passed.\n'
