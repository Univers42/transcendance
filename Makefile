SHELL := /bin/bash
.SHELLFLAGS := -ec
.DEFAULT_GOAL := all
.PHONY: all up down logs ps pull db-init db-seed db-reset db-status \
        clean fclean re help

# ── Docker Hub ───────────────────────────────────────
DOCKER_USER  ?= dlesieur
IMAGE_API    := $(DOCKER_USER)/prismatica-api
IMAGE_FRONT  := $(DOCKER_USER)/prismatica-frontend
TAG          ?= latest

# ── Compose ──────────────────────────────────────────
COMPOSE_CMD := $(shell \
	if docker compose version >/dev/null 2>&1; then echo 'docker compose'; \
	elif command -v docker-compose >/dev/null 2>&1; then echo 'docker-compose'; \
	else echo '__NONE__'; fi)
COMPOSE := $(COMPOSE_CMD) -f docker-compose.yml

# ── Containers ───────────────────────────────────────
API_CTR   := transcendence-api
DB_CTR    := transcendence-db
MONGO_CTR := transcendence-mongo

# ── Colors ───────────────────────────────────────────
B := \033[1m
G := \033[0;32m
C := \033[0;36m
R := \033[0;31m
D := \033[2m
N := \033[0m


all: pull up  ## 🚀 Pull images and start the stack
	@echo ""
	@echo -e "$(G)╔══════════════════════════════════════════╗$(N)"
	@echo -e "$(G)║$(N)  ✅  $(B)Transcendence is running!$(N)          $(G)║$(N)"
	@echo -e "$(G)╠══════════════════════════════════════════╣$(N)"
	@echo -e "$(G)║$(N)  Frontend → http://localhost:8080        $(G)║$(N)"
	@echo -e "$(G)║$(N)  API      → http://localhost:3001        $(G)║$(N)"
	@echo -e "$(G)╚══════════════════════════════════════════╝$(N)"
	@echo ""

pull:  ## 🐳 Pull latest images from Docker Hub (parallel)
	@echo -e "  $(C)ℹ$(N)  Pulling latest images..."
	@docker pull $(IMAGE_API):$(TAG) & docker pull $(IMAGE_FRONT):$(TAG) & wait
	@echo -e "  $(G)✓$(N)  Images up to date"

up:  ## 🐳 Start the full stack
	@echo -e "  $(C)ℹ$(N)  Starting containers..."
	@$(COMPOSE) up -d
	@echo -e "  $(G)✓$(N)  Stack running"

down:  ## 🐳 Stop all containers
	@$(COMPOSE) down
	@echo -e "  $(G)✓$(N)  Stack stopped"

logs:  ## 🐳 Tail all container logs
	@$(COMPOSE) logs -f

ps:  ## 🐳 Show running containers
	@$(COMPOSE) ps

# ============================================
#  🗄️ DATABASE
# ============================================

db-init:  ## 🗄️ Apply schemas + seeds (PG + Mongo)
	@echo -e "  $(C)ℹ$(N)  Initializing databases..."
	@docker exec $(API_CTR) sh -c "cd /app/Model/sql && bash manager/apply_schema.sh" 2>/dev/null || true
	@docker exec $(API_CTR) sh -c "cd /app/Model/sql && bash manager/apply_seeds.sh" 2>/dev/null || true
	@docker exec $(API_CTR) tar -cf - -C /app Model 2>/dev/null | docker exec -i $(MONGO_CTR) tar -xf - -C /tmp/ 2>/dev/null || true
	@docker exec $(MONGO_CTR) bash -c "cd /tmp/Model/sql && bash manager/mongo_setup.sh mongodb://localhost:27017 transcendence" 2>/dev/null || true
	@docker exec $(MONGO_CTR) bash -c "cd /tmp/Model/sql && bash manager/mongo_seed.sh mongodb://localhost:27017 transcendence" 2>/dev/null || true
	@echo -e "  $(G)✓$(N)  Databases initialized"

db-seed:  ## 🗄️ Re-seed databases
	@docker exec $(API_CTR) sh -c "cd /app/Model/sql && bash manager/apply_seeds.sh" 2>/dev/null || true
	@docker exec $(API_CTR) tar -cf - -C /app Model 2>/dev/null | docker exec -i $(MONGO_CTR) tar -xf - -C /tmp/ 2>/dev/null || true
	@docker exec $(MONGO_CTR) bash -c "cd /tmp/Model/sql && bash manager/mongo_seed.sh mongodb://localhost:27017 transcendence" 2>/dev/null || true
	@echo -e "  $(G)✓$(N)  Databases seeded"

db-reset:  ## 🗄️ Reset databases (drop + reinit)
	@echo -e "$(R)⚠  This will DROP all data$(N)"
	@read -p "Are you sure? [y/N] " c && [ "$$c" = "y" ] || exit 1
	@docker exec $(API_CTR) sh -c "cd /app/Model/sql && bash manager/reset.sh" 2>/dev/null || true
	@docker exec $(MONGO_CTR) mongosh --quiet --eval 'db.dropDatabase()' mongodb://localhost:27017/transcendence 2>/dev/null || true
	@$(MAKE) db-init

db-status:  ## 🗄️ Show database status
	@docker exec $(DB_CTR) psql -U transcendence -c "SELECT count(*) AS tables FROM information_schema.tables WHERE table_schema='public';" 2>/dev/null || echo "PostgreSQL: not running"
	@docker exec $(MONGO_CTR) mongosh --quiet --eval "db.getCollectionNames().length + ' collections'" transcendence 2>/dev/null || echo "MongoDB: not running"

clean:  ## 🧹 Stop stack and remove containers + volumes
	@$(COMPOSE) down -v --remove-orphans 2>/dev/null || true
	@echo -e "  $(G)✓$(N)  Clean"

fclean: clean  ## 🧹 Full clean (+ remove pulled images)
	@docker rmi $(IMAGE_API):$(TAG) $(IMAGE_FRONT):$(TAG) 2>/dev/null || true
	@echo -e "  $(G)✓$(N)  Images removed"

re: fclean all  ## 🔄 Full rebuild from scratch

help:  ## ❓ Show this help
	@echo ""
	@echo -e "$(B)Transcendence — Available Commands$(N)"
	@echo ""
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | \
		awk 'BEGIN {FS = ":.*?## "}; {printf "  $(G)%-18s$(N) %s\n", $$1, $$2}'
	@echo ""
