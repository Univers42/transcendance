#!/usr/bin/env bash
# ============================================
# ft_transcendence — Environment Doctor 🩺
# ============================================
# Runs a full diagnostic of the host machine to
# ensure it can build & run the project.
#
# Usage:
#   make doctor          (recommended)
#   bash scripts/doctor.sh
# ============================================

set -uo pipefail

# ── Colors & symbols ────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
DIM='\033[2m'
NC='\033[0m'

OK="${GREEN}✓${NC}"
FAIL="${RED}✗${NC}"
WARN="${YELLOW}⚠${NC}"
INFO="${BLUE}ℹ${NC}"

PASS=0
TOTAL=0
WARNINGS=0
ERRORS=0

# ── Resolve project root early (needed for .env loading) ──
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Note: using PASS=$((PASS+1)) instead of ((PASS++)) because
# ((0)) returns exit code 1 in bash, which kills `set -e`.
check_pass()  { PASS=$((PASS+1)); TOTAL=$((TOTAL+1)); echo -e "  ${OK}  $1"; }
check_fail()  { ERRORS=$((ERRORS+1)); TOTAL=$((TOTAL+1)); echo -e "  ${FAIL}  ${RED}$1${NC}"; echo -e "     ${DIM}→ $2${NC}"; }
check_warn()  { WARNINGS=$((WARNINGS+1)); TOTAL=$((TOTAL+1)); echo -e "  ${WARN}  ${YELLOW}$1${NC}"; echo -e "     ${DIM}→ $2${NC}"; }
section()     { echo ""; echo -e "${BOLD}${CYAN}── $1 ──${NC}"; }

# ── Header ──────────────────────────────────────────
echo ""
echo -e "${BLUE}╔══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║${NC}  🩺  ${BOLD}ft_transcendence — Environment Doctor${NC}                ${BLUE}║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "  ${DIM}Machine:   $(uname -s) $(uname -r) ($(uname -m))${NC}"
echo -e "  ${DIM}User:      $(whoami)${NC}"
echo -e "  ${DIM}Hostname:  $(hostname 2>/dev/null || echo 'unknown')${NC}"
echo -e "  ${DIM}Date:      $(date '+%Y-%m-%d %H:%M %Z')${NC}"
echo -e "  ${DIM}Shell:     ${SHELL:-unknown} ($(bash --version 2>/dev/null | head -1 | sed 's/.*version \([0-9.]*\).*/\1/' || echo 'unknown'))${NC}"

# ============================================
#  1. DOCKER ENGINE
# ============================================
section "Docker Engine"

if command -v docker >/dev/null 2>&1; then
    DOCKER_VERSION="$(docker version --format '{{.Client.Version}}' 2>/dev/null | head -1)"
    if [[ -z "$DOCKER_VERSION" ]]; then
        DOCKER_VERSION="$(docker --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)"
    fi
    DOCKER_VERSION="${DOCKER_VERSION:-unknown}"
    DOCKER_MAJOR=$(echo "$DOCKER_VERSION" | cut -d. -f1 2>/dev/null || echo "0")
    # Ensure DOCKER_MAJOR is numeric
    case "$DOCKER_MAJOR" in
        ''|*[!0-9]*) DOCKER_MAJOR=0 ;;
    esac

    if [[ "$DOCKER_MAJOR" -ge 20 ]]; then
        check_pass "Docker Engine $DOCKER_VERSION"
    elif [[ "$DOCKER_MAJOR" -ge 17 ]]; then
        check_warn "Docker Engine $DOCKER_VERSION (old — recommend ≥ 20.x)" \
                   "Upgrade: https://docs.docker.com/engine/install/"
    else
        check_fail "Docker Engine $DOCKER_VERSION (too old)" \
                   "Minimum required: 17.x — Upgrade: https://docs.docker.com/engine/install/"
    fi
else
    check_fail "Docker is NOT installed" \
               "Install: https://docs.docker.com/get-docker/"
fi

# ── Docker daemon running / accessible? ──
if docker info >/dev/null 2>&1; then
    check_pass "Docker daemon is running"
else
    DOCKER_INFO_ERR="$(docker info 2>&1 >/dev/null || true)"
    if printf '%s' "$DOCKER_INFO_ERR" | grep -qi "permission denied"; then
        check_fail "Docker socket access is denied" \
                   "Fix: sudo usermod -aG docker $(whoami) && newgrp docker  OR  use sudo temporarily"
    else
        check_fail "Docker daemon is NOT running" \
                   "Start it: sudo systemctl start docker  OR  open Docker Desktop"
    fi
fi

# ── User in docker group? (Linux only) ──
if [[ "$(uname -s)" == "Linux" ]]; then
    if groups 2>/dev/null | grep -qw docker; then
        check_pass "User '$(whoami)' is in 'docker' group"
    else
        check_warn "User '$(whoami)' is NOT in 'docker' group (may need sudo)" \
                   "Fix: sudo usermod -aG docker $(whoami) && newgrp docker"
    fi
fi

# ============================================
#  2. DOCKER COMPOSE
# ============================================
section "Docker Compose"

COMPOSE_CMD=""
COMPOSE_V=""

# Try v2 plugin first
if docker compose version >/dev/null 2>&1; then
    COMPOSE_V=$(docker compose version --short 2>/dev/null || docker compose version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    COMPOSE_CMD="docker compose"
    check_pass "Docker Compose v2 plugin — $COMPOSE_V"
fi

# Try v1 standalone
if command -v docker-compose >/dev/null 2>&1; then
    V1_VERSION=$(docker-compose version --short 2>/dev/null || docker-compose version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
    if [[ -z "$COMPOSE_CMD" ]]; then
        COMPOSE_CMD="docker-compose"
        COMPOSE_V="$V1_VERSION"
    fi
    check_pass "docker-compose (standalone) — $V1_VERSION"

    # Warn if v1 is very old
    V1_MAJOR=$(echo "$V1_VERSION" | cut -d. -f1 2>/dev/null || echo 0)
    V1_MINOR=$(echo "$V1_VERSION" | cut -d. -f2 2>/dev/null || echo 0)
    if [[ "$V1_MAJOR" -le 1 && "$V1_MINOR" -lt 25 ]]; then
        check_warn "docker-compose $V1_VERSION is quite old" \
                   "Recommend upgrading to v2: https://docs.docker.com/compose/install/"
    fi
fi

# Try podman-compose
if [[ -z "$COMPOSE_CMD" ]] && command -v podman-compose >/dev/null 2>&1; then
    PC_VERSION=$(podman-compose version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1 || echo "unknown")
    COMPOSE_CMD="podman-compose"
    COMPOSE_V="$PC_VERSION"
    check_warn "Using podman-compose $PC_VERSION (community — some features may differ)" \
               "For full compatibility consider Docker: https://docs.docker.com/get-docker/"
fi

if [[ -z "$COMPOSE_CMD" ]]; then
    check_fail "No docker compose tool found!" \
               "Install Docker Compose: https://docs.docker.com/compose/install/"
else
    echo -e "  ${INFO}  Makefile will use: ${BOLD}${COMPOSE_CMD}${NC}"
fi

# ============================================
#  3. REQUIRED PORTS
# ============================================
section "Required Ports"

check_port() {
    local PORT=$1
    local SERVICE=$2

    # If our own project containers are using the port, that's expected — not a warning
    local OUR_CONTAINER=""
    OUR_CONTAINER=$(docker ps --filter "name=transcendence" --format '{{.Ports}}' 2>/dev/null | grep -o "0.0.0.0:${PORT}->" | head -1 || true)
    if [[ -n "$OUR_CONTAINER" ]]; then
        check_pass "Port $PORT ($SERVICE) — in use by our container"
        return
    fi

    if command -v ss >/dev/null 2>&1; then
        if ss -tlnp 2>/dev/null | grep -q ":${PORT} "; then
            local PROC
            PROC=$(ss -tlnp 2>/dev/null | grep ":${PORT} " | sed -n 's/.*users:(("\([^"]*\)".*/\1/p' | head -1)
            PROC=${PROC:-unknown}
            check_warn "Port $PORT ($SERVICE) is IN USE by: $PROC" \
                       "Either stop '$PROC' or change the port in .env"
        else
            check_pass "Port $PORT ($SERVICE) is available"
        fi
    elif command -v lsof >/dev/null 2>&1; then
        if lsof -i :"$PORT" -sTCP:LISTEN >/dev/null 2>&1; then
            check_warn "Port $PORT ($SERVICE) is IN USE" \
                       "Either stop the process or change the port in .env"
        else
            check_pass "Port $PORT ($SERVICE) is available"
        fi
    elif command -v netstat >/dev/null 2>&1; then
        if netstat -tlnp 2>/dev/null | grep -q ":${PORT} "; then
            check_warn "Port $PORT ($SERVICE) is IN USE" \
                       "Either stop the process or change the port in .env"
        else
            check_pass "Port $PORT ($SERVICE) is available"
        fi
    else
        check_warn "Cannot check port $PORT ($SERVICE) — no ss/lsof/netstat" \
                   "Install: sudo apt install iproute2"
    fi
}

# Load .env if it exists so we pick up custom ports
if [[ -f "$PROJECT_ROOT/.env" ]]; then
    set -a; source "$PROJECT_ROOT/.env" 2>/dev/null; set +a
fi

check_port "${BACKEND_PORT:-3000}"      "Backend (NestJS)"
check_port "${FRONTEND_PORT:-5173}"     "Frontend (Vite)"
check_port "${PRISMA_STUDIO_PORT:-5555}" "Prisma Studio"
check_port "${DB_PORT:-5432}"           "PostgreSQL"
check_port "${REDIS_PORT:-6379}"        "Redis"
check_port "${MAILPIT_UI_PORT:-8025}"   "Mailpit UI"

# ============================================
#  4. ENVIRONMENT FILE
# ============================================
section "Environment File"

if [[ -f "$PROJECT_ROOT/.env" ]]; then
    check_pass ".env file exists"

    # Check for dangerous defaults in non-dev contexts
    if grep -q 'dev-secret-change-me' "$PROJECT_ROOT/.env" 2>/dev/null; then
        check_warn "JWT_SECRET is still the default placeholder" \
                   "Generate a real secret: openssl rand -base64 32"
    fi
    if grep -q 'POSTGRES_PASSWORD=transcendence' "$PROJECT_ROOT/.env" 2>/dev/null; then
        check_warn "POSTGRES_PASSWORD is still the default" \
                   "Change it before deploying"
    fi
elif [[ -f "$PROJECT_ROOT/.env.example" ]]; then
    check_warn ".env file is missing (but .env.example exists)" \
               "Create it: cp .env.example .env"
else
    check_fail ".env file is missing AND no .env.example found" \
               "Create a .env file — see docs/SETUP.md"
fi

# ============================================
#  5. DISK & MEMORY
# ============================================
section "System Resources"

# Disk space
AVAIL_GB=$(df -BG "$PROJECT_ROOT" 2>/dev/null | awk 'NR==2 {gsub("G",""); print $4}' || echo 0)
if [[ "$AVAIL_GB" -ge 10 ]]; then
    check_pass "Disk space: ${AVAIL_GB}GB available"
elif [[ "$AVAIL_GB" -ge 5 ]]; then
    check_warn "Disk space: ${AVAIL_GB}GB available (low — Docker images need space)" \
               "Free up space or run: docker system prune"
else
    check_fail "Disk space: ${AVAIL_GB}GB available (critically low!)" \
               "Docker needs at least 5GB. Run: docker system prune -a"
fi

# RAM
if [[ -f /proc/meminfo ]]; then
    TOTAL_RAM_KB=$(grep MemTotal /proc/meminfo | awk '{print $2}')
    TOTAL_RAM_GB=$((TOTAL_RAM_KB / 1024 / 1024))
    AVAIL_RAM_KB=$(grep MemAvailable /proc/meminfo | awk '{print $2}')
    AVAIL_RAM_GB=$((AVAIL_RAM_KB / 1024 / 1024))

    if [[ "$AVAIL_RAM_GB" -ge 4 ]]; then
        check_pass "Available RAM: ${AVAIL_RAM_GB}GB / ${TOTAL_RAM_GB}GB total"
    elif [[ "$AVAIL_RAM_GB" -ge 2 ]]; then
        check_warn "Available RAM: ${AVAIL_RAM_GB}GB / ${TOTAL_RAM_GB}GB (tight for Docker)" \
                   "Close other applications to free memory"
    else
        check_fail "Available RAM: ${AVAIL_RAM_GB}GB / ${TOTAL_RAM_GB}GB (insufficient!)" \
                   "Docker + PostgreSQL + Redis + Node need ~4GB minimum"
    fi
elif command -v sysctl >/dev/null 2>&1; then
    TOTAL_RAM_BYTES=$(sysctl -n hw.memsize 2>/dev/null || echo 0)
    TOTAL_RAM_GB=$((TOTAL_RAM_BYTES / 1024 / 1024 / 1024))
    if [[ "$TOTAL_RAM_GB" -gt 0 ]]; then
        check_pass "Total RAM: ${TOTAL_RAM_GB}GB"
    fi
fi

# ============================================
#  6. OPTIONAL TOOLS
# ============================================
section "Optional Tools"

for tool in make git curl; do
    if command -v "$tool" >/dev/null 2>&1; then
        VER=$($tool --version 2>&1 | head -1 | grep -oE '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1 || echo "")
        check_pass "$tool $VER"
    else
        check_fail "$tool is NOT installed" \
                   "Install: sudo apt install $tool"
    fi
done

# Node.js (optional — only for local dev)
if command -v node >/dev/null 2>&1; then
    NODE_V=$(node --version 2>/dev/null || echo "unknown")
    check_pass "Node.js $NODE_V (local — optional, Docker has its own)"
else
    echo -e "  ${INFO}  Node.js not on host (fine — Docker containers have Node 22)"
fi

# ============================================
#  7. DEPENDENCY HEALTH (inside container)
# ============================================
section "Dependency Health"

if docker ps --filter "name=transcendence-dev" --format '{{.Names}}' 2>/dev/null | grep -q transcendence-dev; then
    # Check pnpm is available
    PNPM_V=$(docker exec transcendence-dev pnpm --version 2>/dev/null || echo "")
    if [[ -n "$PNPM_V" ]]; then
        check_pass "pnpm $PNPM_V (inside container)"
    else
        check_fail "pnpm not found in dev container" \
                   "Rebuild: make docker-clean && make"
    fi

    # Check for peer dependency issues in backend
    BACKEND_PEERS=$(docker exec transcendence-dev sh -c 'cd /app/apps/backend && pnpm ls --depth 0 2>&1 | grep -i "WARN.*peer\|ERR.*peer\|missing peer" | head -5' 2>/dev/null || echo "")
    if [[ -z "$BACKEND_PEERS" ]]; then
        check_pass "Backend: no peer dependency issues"
    else
        check_warn "Backend has peer dependency warnings" \
                   "Run: make shell → cd apps/backend && pnpm ls"
    fi

    # Check for peer dependency issues in frontend
    FRONTEND_PEERS=$(docker exec transcendence-dev sh -c 'cd /app/apps/frontend && pnpm ls --depth 0 2>&1 | grep -i "WARN.*peer\|ERR.*peer\|missing peer" | head -5' 2>/dev/null || echo "")
    if [[ -z "$FRONTEND_PEERS" ]]; then
        check_pass "Frontend: no peer dependency issues"
    else
        check_warn "Frontend has peer dependency warnings" \
                   "Run: make shell → cd apps/frontend && pnpm ls"
    fi

    # Check for deprecated packages
    DEPRECATED=$(docker exec transcendence-dev sh -c 'cd /app/apps/backend && pnpm audit --json 2>/dev/null | grep -c "\"severity\"" || echo 0' 2>/dev/null || echo "0")
    DEPRECATED=${DEPRECATED:-0}
    case "$DEPRECATED" in
        ''|*[!0-9]*) DEPRECATED=0 ;;
    esac
    if [[ "$DEPRECATED" -eq 0 ]]; then
        check_pass "No known security vulnerabilities"
    elif [[ "$DEPRECATED" -le 3 ]]; then
        check_warn "$DEPRECATED security advisory(ies) found" \
                   "Run: make shell → cd apps/backend && pnpm audit"
    else
        check_warn "$DEPRECATED security advisories found" \
                   "Run: make shell → pnpm audit for details"
    fi
else
    echo -e "  ${INFO}  Dev container not running — skipping dependency checks"
    echo -e "     ${DIM}→ Run: make docker-up${NC}"
fi

# ============================================
#  8. DOCKER STATE
# ============================================
section "Docker State"

# Running containers from this project
RUNNING=$(docker ps --filter "name=transcendence" --format '{{.Names}} ({{.Status}})' 2>/dev/null || true)
if [[ -n "$RUNNING" ]]; then
    echo -e "  ${INFO}  Running project containers:"
    echo "$RUNNING" | while read -r line; do
        echo -e "     ${GREEN}▸${NC} $line"
    done
else
    echo -e "  ${INFO}  No project containers running"
fi

# Docker disk usage
DOCKER_DISK=$(docker system df --format 'Images: {{.Size}}' 2>/dev/null | head -1 || echo "")
if [[ -n "$DOCKER_DISK" ]]; then
    echo -e "  ${INFO}  Docker disk: $DOCKER_DISK"
fi

# Dangling images
DANGLING="$(docker images -f "dangling=true" -q 2>/dev/null | wc -l | tr -d '[:space:]')"
DANGLING="${DANGLING:-0}"
if [[ "$DANGLING" -gt 5 ]]; then
    check_warn "$DANGLING dangling Docker images (wasting space)" \
               "Clean up: docker image prune"
elif [[ "$DANGLING" -gt 0 ]]; then
    echo -e "  ${INFO}  $DANGLING dangling image(s) — run 'docker image prune' to clean"
fi

# ============================================
#  REPORT
# ============================================
echo ""
echo -e "${BOLD}── Summary ──${NC}"
echo ""
echo -e "  Checks:   ${TOTAL}"
echo -e "  Passed:   ${GREEN}${PASS}${NC}"
echo -e "  Warnings: ${YELLOW}${WARNINGS}${NC}"
echo -e "  Errors:   ${RED}${ERRORS}${NC}"
echo ""

if [[ "$ERRORS" -eq 0 && "$WARNINGS" -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}🎉 All clear! Your environment is ready.${NC}"
    echo -e "  Run ${BOLD}make${NC} to bootstrap the project."
elif [[ "$ERRORS" -eq 0 ]]; then
    echo -e "  ${YELLOW}${BOLD}⚡ Good to go with ${WARNINGS} warning(s).${NC}"
    echo -e "  Run ${BOLD}make${NC} to bootstrap — warnings won't block you."
else
    echo -e "  ${RED}${BOLD}🚫 ${ERRORS} error(s) must be fixed before running the project.${NC}"
    echo -e "  Fix the issues above and re-run: ${BOLD}make doctor${NC}"
fi
echo ""

exit "$ERRORS"
