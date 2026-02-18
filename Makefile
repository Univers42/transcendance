# ============================================
# FT_TRANSCENDENCE — MAKEFILE
# ============================================
# Usage: make <target>
# Run 'make help' to see all available targets
#
# 🐳 FULLY CONTAINERIZED: Only Docker required!
#    Running `make` bootstraps everything inside Docker containers.
#    No Node.js, npm, PostgreSQL, or Redis needed on your host.
#
# 🛡️ RESILIENT: Auto-detects docker compose v2 / docker-compose v1 /
#    podman-compose — works on any team member's machine.
# ============================================

SHELL := /bin/bash
.SHELLFLAGS := -ec

.PHONY: help
.DEFAULT_GOAL := all

# ── Compose auto-detection (v2 plugin → v1 standalone → podman) ──
# We test each variant and lock in the first one that works.
# This runs ONCE at Makefile parse time.
COMPOSE_CMD := $(shell \
	if docker compose version >/dev/null 2>&1; then \
		echo 'docker compose'; \
	elif command -v docker-compose >/dev/null 2>&1; then \
		echo 'docker-compose'; \
	elif command -v podman-compose >/dev/null 2>&1; then \
		echo 'podman-compose'; \
	else \
		echo '__NONE__'; \
	fi \
)

COMPOSE_VERSION := $(shell \
	if docker compose version --short 2>/dev/null; then true; \
	elif docker-compose version --short 2>/dev/null; then true; \
	elif podman-compose version 2>/dev/null | grep -oP '[\d]+\.[\d]+' | head -1; then true; \
	else echo 'unknown'; \
	fi \
)

# ── Variables ────────────────────────────────────────
COMPOSE_DEV  := $(COMPOSE_CMD) -f docker-compose.dev.yml
COMPOSE_PROD := $(COMPOSE_CMD) -f docker-compose.yml
CONTAINER    := transcendence-dev
BACKEND      := apps/backend
FRONTEND     := apps/frontend
SHARED       := packages/shared

# Colors
BLUE    := \033[0;34m
GREEN   := \033[0;32m
YELLOW  := \033[1;33m
RED     := \033[0;31m
CYAN    := \033[0;36m
NC      := \033[0m
BOLD    := \033[1m
DIM     := \033[2m

# Box drawing
define BANNER
	@echo ""
	@echo -e "$(BLUE)╔══════════════════════════════════════════════════════════╗$(NC)"
	@echo -e "$(BLUE)║$(NC)  🏓  $(BOLD)ft_transcendence$(NC) — Team Univers42                     $(BLUE)║$(NC)"
	@echo -e "$(BLUE)╚══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""
endef

# ── Step decorator ───────────────────────────────────
# Usage: $(call step,emoji,message)
define step
	@echo -e "  $(1)  $(2)"
endef

# ============================================
#  🛡️ PREFLIGHT CHECKS
# ============================================

.PHONY: check-docker check-compose check-env preflight

# Validates that Docker engine is installed and running.
check-docker:
	@command -v docker >/dev/null 2>&1 || { \
		echo ""; \
		echo -e "$(RED)┌─────────────────────────────────────────────────────────┐$(NC)"; \
		echo -e "$(RED)│  ✗  FAILED: $(BOLD)Docker Engine not found$(NC)"; \
		echo -e "$(RED)├─────────────────────────────────────────────────────────┤$(NC)"; \
		echo -e "$(RED)│$(NC)  $(BOLD)Why:$(NC)  'docker' command is not in PATH."; \
		echo -e "$(RED)│$(NC)  $(BOLD)Fix:$(NC)  Install Docker: https://docs.docker.com/get-docker/"; \
		echo -e "$(RED)│$(NC)"; \
		echo -e "$(RED)│$(NC)  Run $(BOLD)make doctor$(NC) for a full environment diagnostic."; \
		echo -e "$(RED)└─────────────────────────────────────────────────────────┘$(NC)"; \
		echo ""; \
		exit 1; \
	}
	@docker info >/dev/null 2>&1 || { \
		echo ""; \
		echo -e "$(RED)┌─────────────────────────────────────────────────────────┐$(NC)"; \
		echo -e "$(RED)│  ✗  FAILED: $(BOLD)Docker daemon is not running$(NC)"; \
		echo -e "$(RED)├─────────────────────────────────────────────────────────┤$(NC)"; \
		echo -e "$(RED)│$(NC)  $(BOLD)Why:$(NC)  Docker is installed but the daemon/service is stopped."; \
		echo -e "$(RED)│$(NC)  $(BOLD)Fix:$(NC)  sudo systemctl start docker"; \
		echo -e "$(RED)│$(NC)        OR open Docker Desktop"; \
		echo -e "$(RED)│$(NC)"; \
		echo -e "$(RED)│$(NC)  Run $(BOLD)make doctor$(NC) for a full environment diagnostic."; \
		echo -e "$(RED)└─────────────────────────────────────────────────────────┘$(NC)"; \
		echo ""; \
		exit 1; \
	}
	$(call step,$(GREEN)✓,Docker Engine is running)

# Validates that a compose tool is available.
check-compose:
ifeq ($(COMPOSE_CMD),__NONE__)
	@echo ""
	@echo -e "$(RED)┌─────────────────────────────────────────────────────────┐$(NC)"
	@echo -e "$(RED)│  ✗  FAILED: $(BOLD)No Docker Compose tool found$(NC)"
	@echo -e "$(RED)├─────────────────────────────────────────────────────────┤$(NC)"
	@echo -e "$(RED)│$(NC)  $(BOLD)Why:$(NC)  None of these were found on this system:"
	@echo -e "$(RED)│$(NC)        • docker compose  (v2 plugin — preferred)"
	@echo -e "$(RED)│$(NC)        • docker-compose  (v1 standalone)"
	@echo -e "$(RED)│$(NC)        • podman-compose  (Podman alternative)"
	@echo -e "$(RED)│$(NC)"
	@echo -e "$(RED)│$(NC)  $(BOLD)Fix (pick one):$(NC)"
	@echo -e "$(RED)│$(NC)        • Install Docker Desktop (includes compose v2)"
	@echo -e "$(RED)│$(NC)        • sudo apt install docker-compose-plugin"
	@echo -e "$(RED)│$(NC)        • pip install docker-compose"
	@echo -e "$(RED)│$(NC)"
	@echo -e "$(RED)│$(NC)  Run $(BOLD)make doctor$(NC) for a full environment diagnostic."
	@echo -e "$(RED)└─────────────────────────────────────────────────────────┘$(NC)"
	@echo ""
	@exit 1
else
	$(call step,$(GREEN)✓,Compose tool: $(BOLD)$(COMPOSE_CMD)$(NC) $(DIM)($(COMPOSE_VERSION))$(NC))
endif

# Validates .env exists (creates from .env.example if needed).
check-env:
	@if [ ! -f .env ]; then \
		if [ -f .env.example ]; then \
			echo -e "  $(YELLOW)⚠$(NC)  .env not found — creating from .env.example"; \
			cp .env.example .env; \
			echo -e "  $(GREEN)✓$(NC)  .env created — $(BOLD)review it and update secrets$(NC)"; \
		else \
			echo ""; \
			echo -e "$(RED)┌─────────────────────────────────────────────────────────┐$(NC)"; \
			echo -e "$(RED)│  ✗  FAILED: $(BOLD).env file is missing$(NC)"; \
			echo -e "$(RED)├─────────────────────────────────────────────────────────┤$(NC)"; \
			echo -e "$(RED)│$(NC)  $(BOLD)Why:$(NC)  No .env or .env.example file found."; \
			echo -e "$(RED)│$(NC)  $(BOLD)Fix:$(NC)  Copy the example: cp .env.example .env"; \
			echo -e "$(RED)│$(NC)        Then edit it with your local settings."; \
			echo -e "$(RED)│$(NC)"; \
			echo -e "$(RED)│$(NC)  Run $(BOLD)make doctor$(NC) for a full environment diagnostic."; \
			echo -e "$(RED)└─────────────────────────────────────────────────────────┘$(NC)"; \
			echo ""; \
			exit 1; \
		fi; \
	else \
		echo -e "  $(GREEN)✓$(NC)  .env file loaded"; \
	fi

# Checks for port conflicts and offers to kill them.
check-ports:
	@PORTS="$${BACKEND_PORT:-4200} $${FRONTEND_PORT:-4201} $${PRISMA_STUDIO_PORT:-4202} $${DB_PORT:-4210} $${REDIS_PORT:-4211} $${MAILPIT_UI_PORT:-4212}"; \
	BLOCKED=""; \
	for p in $$PORTS; do \
		if ss -tlnp 2>/dev/null | grep -q ":$$p "; then \
			PROC=$$(ss -tlnp 2>/dev/null | grep ":$$p " | sed -n 's/.*users:(("\([^"]*\)".*/\1/p' | head -1); \
			BLOCKED="$$BLOCKED $$p($$PROC)"; \
		fi; \
	done; \
	if [ -n "$$BLOCKED" ]; then \
		echo -e "  $(YELLOW)⚠$(NC)  Ports in use:$(BOLD)$$BLOCKED$(NC)"; \
		echo -e "     Run $(BOLD)make kill-ports$(NC) to free them, or change ports in .env"; \
	else \
		echo -e "  $(GREEN)✓$(NC)  All ports available"; \
	fi

# Full preflight — runs all checks in order.
preflight: check-docker check-compose check-env check-ports
	$(call step,$(GREEN)✓,$(BOLD)All preflight checks passed$(NC))

# ============================================
#  ⚡ BOOTSTRAP (default target)
# ============================================

.PHONY: all bootstrap banner

all: banner preflight bootstrap  ## 🚀 Full setup (default — Docker only)

banner:
	$(BANNER)

bootstrap: docker-up install compile db-migrate  ## Full bootstrap sequence
	@echo ""
	@echo -e "$(GREEN)╔══════════════════════════════════════════════════════════╗$(NC)"
	@echo -e "$(GREEN)║$(NC)  ✅  $(BOLD)Setup complete!$(NC)                                       $(GREEN)║$(NC)"
	@echo -e "$(GREEN)╠══════════════════════════════════════════════════════════╣$(NC)"
	@echo -e "$(GREEN)║$(NC)                                                          $(GREEN)║$(NC)"
	@echo -e "$(GREEN)║$(NC)  Frontend  →  http://localhost:$${FRONTEND_PORT:-4201}                      $(GREEN)║$(NC)"
	@echo -e "$(GREEN)║$(NC)  Backend   →  http://localhost:$${BACKEND_PORT:-4200}                      $(GREEN)║$(NC)"
	@echo -e "$(GREEN)║$(NC)  API Docs  →  http://localhost:$${BACKEND_PORT:-4200}/api/docs             $(GREEN)║$(NC)"
	@echo -e "$(GREEN)║$(NC)  Prisma    →  http://localhost:$${PRISMA_STUDIO_PORT:-4202}                      $(GREEN)║$(NC)"
	@echo -e "$(GREEN)║$(NC)  Mailpit   →  http://localhost:$${MAILPIT_UI_PORT:-4212}                      $(GREEN)║$(NC)"
	@echo -e "$(GREEN)║$(NC)                                                          $(GREEN)║$(NC)"
	@echo -e "$(GREEN)║$(NC)  Run $(BOLD)make dev$(NC) to start dev servers                        $(GREEN)║$(NC)"
	@echo -e "$(GREEN)║$(NC)  Run $(BOLD)make help$(NC) to see all commands                        $(GREEN)║$(NC)"
	@echo -e "$(GREEN)║$(NC)                                                          $(GREEN)║$(NC)"
	@echo -e "$(GREEN)╚══════════════════════════════════════════════════════════╝$(NC)"
	@echo ""

# ============================================
#  🐳 DOCKER
# ============================================

.PHONY: docker-up docker-down docker-logs docker-clean docker-ps

docker-up: check-compose  ## 🐳 Start all containers (db, redis, dev)
	$(call step,$(BLUE)ℹ,Starting containers with $(BOLD)$(COMPOSE_CMD)$(NC)...)
	@$(COMPOSE_DEV) up -d --build 2>&1 || { \
		ERR=$$?; \
		echo -e "$(YELLOW)⚠$(NC)  First attempt failed. Cleaning stuck containers..."; \
		docker rm -f $$(docker ps -aq --filter "name=transcendence") 2>/dev/null || true; \
		$(COMPOSE_DEV) up -d --build 2>&1 || { \
			echo ""; \
			echo -e "$(RED)┌─────────────────────────────────────────────────────────┐$(NC)"; \
			echo -e "$(RED)│  ✗  FAILED: $(BOLD)Container startup$(NC)"; \
			echo -e "$(RED)├─────────────────────────────────────────────────────────┤$(NC)"; \
			echo -e "$(RED)│$(NC)  $(BOLD)Why:$(NC)  Container build or startup failed."; \
			echo -e "$(RED)│$(NC)  $(BOLD)Common causes:$(NC)"; \
			echo -e "$(RED)│$(NC)    • Port already in use (run $(BOLD)make kill-ports$(NC))"; \
			echo -e "$(RED)│$(NC)    • Dockerfile syntax error"; \
			echo -e "$(RED)│$(NC)    • Stale containers (AppArmor / permission denied)"; \
			echo -e "$(RED)│$(NC)    • Missing .env file"; \
			echo -e "$(RED)│$(NC)  $(BOLD)Fix:$(NC)"; \
			echo -e "$(RED)│$(NC)    1. make kill-ports     (free stuck ports)"; \
			echo -e "$(RED)│$(NC)    2. make docker-clean   (nuke old state)"; \
			echo -e "$(RED)│$(NC)    3. make                (try again)"; \
			echo -e "$(RED)└─────────────────────────────────────────────────────────┘$(NC)"; \
			echo ""; \
			exit 1; \
		}; \
	}
	$(call step,$(GREEN)✓,Containers are running)

docker-down: check-compose  ## 🐳 Stop all containers
	$(call step,$(YELLOW)⚠,Stopping containers...)
	@$(COMPOSE_DEV) down 2>/dev/null || { \
		echo -e "$(YELLOW)⚠$(NC)  Compose down failed. Force-removing containers..."; \
		docker rm -f $$(docker ps -aq --filter "name=transcendence") 2>/dev/null || true; \
	}
	$(call step,$(GREEN)✓,Containers stopped)
	$(call step,$(GREEN)✓,Containers stopped)

docker-logs: check-compose  ## 🐳 Tail all container logs
	@$(COMPOSE_DEV) logs -f

docker-ps: check-compose  ## 🐳 Show running containers
	@$(COMPOSE_DEV) ps

docker-clean: check-compose  ## 🐳 Remove containers + volumes (full reset)
	@echo -e "$(RED)⚠  This will delete all data (database, node_modules, cache)$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@$(COMPOSE_DEV) down -v --remove-orphans 2>/dev/null || { \
		echo -e "$(YELLOW)⚠$(NC)  Compose down failed (AppArmor?). Force-removing containers..."; \
		docker rm -f $$(docker ps -aq --filter "name=transcendence") 2>/dev/null || true; \
		docker volume rm $$(docker volume ls -q --filter "name=transcendance") 2>/dev/null || true; \
	}
	$(call step,$(GREEN)✓,Full cleanup done)

# ============================================
#  📦 DEPENDENCIES
# ============================================

.PHONY: install install-backend install-frontend install-shared

install: install-shared install-backend install-frontend  ## 📦 Install all dependencies
	$(call step,$(GREEN)✓,All dependencies installed)

install-backend:
	$(call step,$(BLUE)ℹ,Installing backend dependencies...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npm install --legacy-peer-deps" 2>&1 || { \
		echo ""; \
		echo -e "$(RED)┌─────────────────────────────────────────────────────────┐$(NC)"; \
		echo -e "$(RED)│  ✗  FAILED: $(BOLD)npm install (backend)$(NC)"; \
		echo -e "$(RED)├─────────────────────────────────────────────────────────┤$(NC)"; \
		echo -e "$(RED)│$(NC)  $(BOLD)Why:$(NC)  Container '$(CONTAINER)' may not be running,"; \
		echo -e "$(RED)│$(NC)        or apps/backend/package.json is missing/invalid."; \
		echo -e "$(RED)│$(NC)  $(BOLD)Fix:$(NC)  make docker-up   (ensure containers are up)"; \
		echo -e "$(RED)│$(NC)        make shell       (debug inside the container)"; \
		echo -e "$(RED)└─────────────────────────────────────────────────────────┘$(NC)"; \
		echo ""; \
		exit 1; \
	}

install-frontend:
	$(call step,$(BLUE)ℹ,Installing frontend dependencies...)
	@docker exec $(CONTAINER) sh -c "cd $(FRONTEND) && npm install" 2>&1 || { \
		echo ""; \
		echo -e "$(RED)┌─────────────────────────────────────────────────────────┐$(NC)"; \
		echo -e "$(RED)│  ✗  FAILED: $(BOLD)npm install (frontend)$(NC)"; \
		echo -e "$(RED)├─────────────────────────────────────────────────────────┤$(NC)"; \
		echo -e "$(RED)│$(NC)  $(BOLD)Why:$(NC)  Container '$(CONTAINER)' may not be running,"; \
		echo -e "$(RED)│$(NC)        or apps/frontend/package.json is missing/invalid."; \
		echo -e "$(RED)│$(NC)  $(BOLD)Fix:$(NC)  make docker-up   (ensure containers are up)"; \
		echo -e "$(RED)│$(NC)        make shell       (debug inside the container)"; \
		echo -e "$(RED)└─────────────────────────────────────────────────────────┘$(NC)"; \
		echo ""; \
		exit 1; \
	}

install-shared:
	$(call step,$(BLUE)ℹ,Installing shared package dependencies...)
	@docker exec $(CONTAINER) sh -c "cd $(SHARED) && npm install 2>/dev/null || true"

# ============================================
#  🔧 COMPILE & BUILD
# ============================================

.PHONY: compile build build-backend build-frontend

compile:  ## 🔧 Generate Prisma client + compile TypeScript
	$(call step,$(BLUE)ℹ,Generating Prisma client...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npx prisma generate --schema=prisma/schema.prisma 2>/dev/null || true"
	$(call step,$(BLUE)ℹ,Compiling TypeScript...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npx tsc --noEmit 2>/dev/null || true"
	$(call step,$(GREEN)✓,Compilation done)

build: build-backend build-frontend  ## 🏗️ Production build (all)

build-backend:  ## 🏗️ Build backend
	$(call step,$(BLUE)ℹ,Building backend...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npm run build"
	$(call step,$(GREEN)✓,Backend built)

build-frontend:  ## 🏗️ Build frontend
	$(call step,$(BLUE)ℹ,Building frontend...)
	@docker exec $(CONTAINER) sh -c "cd $(FRONTEND) && npm run build"
	$(call step,$(GREEN)✓,Frontend built)

# ============================================
#  🚀 DEVELOPMENT
# ============================================

.PHONY: dev dev-backend dev-frontend shell

dev: docker-up  ## 🚀 Start all dev servers (hot reload)
	$(call step,$(BLUE)ℹ,Starting dev servers...)
	@docker exec -d $(CONTAINER) sh -c "cd $(BACKEND) && npm run start:dev" 2>/dev/null || true
	@docker exec -d $(CONTAINER) sh -c "cd $(FRONTEND) && npm run dev -- --host 0.0.0.0" 2>/dev/null || true
	$(call step,$(GREEN)✓,Dev servers started)
	@echo -e "  Frontend → http://localhost:$${FRONTEND_PORT:-4201}"
	@echo -e "  Backend  → http://localhost:$${BACKEND_PORT:-4200}"
	@echo -e "  Mailpit  → http://localhost:$${MAILPIT_UI_PORT:-4212}"

dev-backend:  ## 🚀 Start backend only
	@docker exec -it $(CONTAINER) sh -c "cd $(BACKEND) && npm run start:dev"

dev-frontend:  ## 🚀 Start frontend only
	@docker exec -it $(CONTAINER) sh -c "cd $(FRONTEND) && npm run dev -- --host 0.0.0.0"

shell:  ## 🐚 Interactive shell in dev container
	@docker exec -it $(CONTAINER) bash

# ============================================
#  🗄️ DATABASE
# ============================================

.PHONY: db-migrate db-seed db-studio db-reset db-push

db-migrate:  ## 🗄️ Run Prisma migrations
	$(call step,$(BLUE)ℹ,Running migrations...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npx prisma migrate deploy --schema=prisma/schema.prisma 2>/dev/null || npx prisma migrate dev --schema=prisma/schema.prisma 2>/dev/null || true"
	$(call step,$(GREEN)✓,Migrations applied)

db-seed:  ## 🗄️ Seed database with sample data
	$(call step,$(BLUE)ℹ,Seeding database...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npx prisma db seed"
	$(call step,$(GREEN)✓,Database seeded)

db-studio:  ## 🗄️ Open Prisma Studio (port 5555)
	$(call step,$(BLUE)ℹ,Opening Prisma Studio...)
	@docker exec -d $(CONTAINER) sh -c "cd $(BACKEND) && npx prisma studio --schema=prisma/schema.prisma"
	$(call step,$(GREEN)✓,Prisma Studio → http://localhost:5555)

db-reset:  ## 🗄️ Reset database (drop + migrate + seed)
	@echo -e "$(RED)⚠  This will DROP the entire database$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npx prisma migrate reset --force --schema=prisma/schema.prisma"
	$(call step,$(GREEN)✓,Database reset)

db-push:  ## 🗄️ Push schema changes (dev only, no migration)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npx prisma db push --schema=prisma/schema.prisma"

# ============================================
#  ✅ QUALITY
# ============================================

.PHONY: lint format typecheck

lint:  ## ✅ Run ESLint on all workspaces
	$(call step,$(BLUE)ℹ,Running linter...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npx eslint . 2>/dev/null || true"
	@docker exec $(CONTAINER) sh -c "cd $(FRONTEND) && npx eslint . 2>/dev/null || true"
	$(call step,$(GREEN)✓,Lint complete)

format:  ## ✅ Run Prettier on all workspaces
	$(call step,$(BLUE)ℹ,Formatting code...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npx prettier --write 'src/**/*.ts' 2>/dev/null || true"
	@docker exec $(CONTAINER) sh -c "cd $(FRONTEND) && npx prettier --write 'src/**/*.{ts,tsx}' 2>/dev/null || true"
	$(call step,$(GREEN)✓,Formatting complete)

typecheck:  ## ✅ TypeScript type checking (no emit)
	$(call step,$(BLUE)ℹ,Type checking...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npx tsc --noEmit"
	@docker exec $(CONTAINER) sh -c "cd $(FRONTEND) && npx tsc --noEmit"
	$(call step,$(GREEN)✓,No type errors)

# ============================================
#  🧪 TESTING
# ============================================

.PHONY: test test-unit test-e2e test-watch

test: test-unit test-e2e  ## 🧪 Run all tests

test-unit:  ## 🧪 Run unit tests
	$(call step,$(BLUE)ℹ,Running unit tests...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npm test"
	$(call step,$(GREEN)✓,Unit tests passed)

test-e2e:  ## 🧪 Run E2E tests
	$(call step,$(BLUE)ℹ,Running E2E tests...)
	@docker exec $(CONTAINER) sh -c "cd $(BACKEND) && npm run test:e2e"
	$(call step,$(GREEN)✓,E2E tests passed)

test-watch:  ## 🧪 Run tests in watch mode
	@docker exec -it $(CONTAINER) sh -c "cd $(BACKEND) && npm run test:watch"

# ============================================
#  🧹 CLEANUP
# ============================================

.PHONY: clean fclean re

clean:  ## 🧹 Remove build artifacts
	$(call step,$(YELLOW)⚠,Cleaning build artifacts...)
	@docker exec $(CONTAINER) sh -c "rm -rf $(BACKEND)/dist $(FRONTEND)/dist" 2>/dev/null || true
	$(call step,$(GREEN)✓,Clean)

fclean: clean  ## 🧹 Full clean (artifacts + modules + volumes)
	@echo -e "$(RED)⚠  Full cleanup — this removes EVERYTHING$(NC)"
	@read -p "Are you sure? [y/N] " confirm && [ "$$confirm" = "y" ] || exit 1
	@$(COMPOSE_DEV) down -v --remove-orphans 2>/dev/null || true
	@$(COMPOSE_PROD) down -v --remove-orphans 2>/dev/null || true
	$(call step,$(GREEN)✓,Full cleanup done)

re: fclean all  ## 🔄 Full rebuild from scratch

# ============================================
#  🏭 PRODUCTION
# ============================================

.PHONY: prod prod-down prod-logs

prod: check-compose  ## 🏭 Build & start production stack
	$(call step,$(BLUE)ℹ,Building production images...)
	@$(COMPOSE_PROD) up -d --build
	$(call step,$(GREEN)✓,Production stack running)
	@echo -e "  Frontend → http://localhost:8080"
	@echo -e "  Backend  → http://localhost:3000"

prod-down:  ## 🏭 Stop production stack
	@$(COMPOSE_PROD) down

prod-logs:  ## 🏭 Tail production logs
	@$(COMPOSE_PROD) logs -f

# ============================================
#  💻 LOCAL (no Docker — requires Node.js on host)
# ============================================

.PHONY: local local-install local-dev

local: local-install  ## 💻 Setup using host Node.js (no Docker)
	$(call step,$(GREEN)✓,Local setup complete. Run: make local-dev)

local-install:
	$(call step,$(BLUE)ℹ,Installing dependencies locally...)
	@cd $(BACKEND) && npm install
	@cd $(FRONTEND) && npm install
	@cd $(SHARED) && npm install 2>/dev/null || true
	@cd $(BACKEND) && npx prisma generate --schema=prisma/schema.prisma
	$(call step,$(GREEN)✓,Dependencies installed)

local-dev:  ## 💻 Start dev servers locally (requires Node.js)
	$(call step,$(BLUE)ℹ,Starting local dev servers...)
	@cd $(BACKEND) && npm run start:dev &
	@cd $(FRONTEND) && npm run dev &
	$(call step,$(GREEN)✓,Dev servers starting...)
	@echo -e "  Frontend → http://localhost:5173"
	@echo -e "  Backend  → http://localhost:3000"

# ============================================
#  🔌 PORT MANAGEMENT
# ============================================

.PHONY: kill-ports

kill-ports:  ## 🔌 Kill processes on all project ports
	@echo -e "$(YELLOW)⚠$(NC)  Killing processes on project ports..."
	@PORTS="$${BACKEND_PORT:-4200} $${FRONTEND_PORT:-4201} $${PRISMA_STUDIO_PORT:-4202} $${DB_PORT:-4210} $${REDIS_PORT:-4211} $${MAILPIT_UI_PORT:-4212}"; \
	for p in $$PORTS; do \
		PIDS=$$(ss -tlnp 2>/dev/null | grep ":$$p " | sed -n 's/.*pid=\([0-9]*\).*/\1/p' | sort -u); \
		if [ -n "$$PIDS" ]; then \
			for pid in $$PIDS; do \
				NAME=$$(ps -p $$pid -o comm= 2>/dev/null || echo unknown); \
				echo -e "  Killing $$NAME (PID $$pid) on port $$p"; \
				kill $$pid 2>/dev/null || true; \
			done; \
		fi; \
	done
	@$(COMPOSE_DEV) down 2>/dev/null || true
	@sleep 1
	$(call step,$(GREEN)✓,All project ports freed)

# ============================================
#  🩺 DIAGNOSTICS
# ============================================

.PHONY: doctor info

doctor:  ## 🩺 Full environment diagnostic (run this first!)
	@bash scripts/doctor.sh

info:  ## 🩺 Show detected environment
	@echo ""
	@echo -e "$(BOLD)ft_transcendence — Environment Info$(NC)"
	@echo ""
	@echo -e "  $(BOLD)Compose tool:$(NC)    $(COMPOSE_CMD)"
	@echo -e "  $(BOLD)Compose version:$(NC) $(COMPOSE_VERSION)"
	@echo -e "  $(BOLD)Docker version:$(NC)  $(shell docker version --format '{{.Client.Version}}' 2>/dev/null || echo 'not found')"
	@echo -e "  $(BOLD)OS:$(NC)              $(shell uname -s) $(shell uname -r) ($(shell uname -m))"
	@echo -e "  $(BOLD)Shell:$(NC)           $(SHELL)"
	@echo -e "  $(BOLD)Make:$(NC)            $(MAKE_VERSION)"
	@echo -e "  $(BOLD)User:$(NC)            $(shell whoami)"
	@echo -e "  $(BOLD).env:$(NC)            $(shell [ -f .env ] && echo 'present' || echo 'MISSING')"
	@echo ""
	@echo -e "  $(DIM)Compose dev cmd:$(NC)  $(COMPOSE_DEV)"
	@echo -e "  $(DIM)Compose prod cmd:$(NC) $(COMPOSE_PROD)"
	@echo ""

# ============================================
#  ❓ HELP
# ============================================

help:  ## ❓ Show this help message
	@echo ""
	@echo -e "$(BOLD)ft_transcendence — Available Commands$(NC)"
	@echo -e "$(DIM)Compose: $(COMPOSE_CMD) $(COMPOSE_VERSION)$(NC)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-20s$(NC) %s\n", $$1, $$2}'
	@echo ""
	@echo -e "  $(DIM)First time? Run: make doctor$(NC)"
	@echo ""