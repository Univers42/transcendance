# ============================================================================
# Makefile — SQL Database Management (Schema, Seeds, Verification)
# ============================================================================
#
# Single entry-point for all database operations. Every target uses
# scripts inside manager/ to keep this file lean and maintainable.
#
# ┌────────────────────────────────────────────────────────────────────┐
# │  QUICK START                                                       │
# │                                                                    │
# │  make all          — Full reset + schema + seeds + verify          │
# │  make seed         — Just reseed (reset + schema + seed + verify)  │
# │  make verify       — Check integrity of current data              │
# │  make help         — Show all available targets                    │
# └────────────────────────────────────────────────────────────────────┘
#
# CONFIGURATION:
#   Override DATABASE_URL to target a different database:
#     make all DATABASE_URL=postgresql://user:pass@host:5432/dbname
#
#   Override ROWS to change the number of rows per table:
#     make all ROWS=20
#
# ============================================================================

# ── Configuration ────────────────────────────────────────────────────────────

DATABASE_URL ?= postgresql://postgres:postgres@localhost:5432/transcendence
ROWS         ?= 5
MANAGER      := manager
SEEDS        := seeds

# Ensure scripts are executable
SHELL := /bin/bash
.SHELLFLAGS := -euo pipefail -c

# ── Phony targets ────────────────────────────────────────────────────────────

.PHONY: all help reset schema triggers indexes views seeds seed-static \
        seed-auto seed verify introspect query clean status \
        fresh debug setup permissions

# ── Default target ───────────────────────────────────────────────────────────

all: setup reset schema seed-static seed-auto verify  ## Full pipeline: reset → schema → seed → verify
	@echo ""
	@echo "════════════════════════════════════════════════════════════════"
	@echo "  ✓ COMPLETE — Database is fully seeded and verified."
	@echo "════════════════════════════════════════════════════════════════"

# ── Help ─────────────────────────────────────────────────────────────────────

help:  ## Show this help
	@echo ""
	@echo "╔════════════════════════════════════════════════════════════════╗"
	@echo "║  SQL Database Manager — Available Targets                     ║"
	@echo "╠════════════════════════════════════════════════════════════════╣"
	@echo "║                                                               ║"
	@echo "║  LIFECYCLE                                                    ║"
	@echo "║  ─────────                                                    ║"
	@echo "║  make all            Full pipeline (reset+schema+seed+verify) ║"
	@echo "║  make fresh          Alias for 'all'                          ║"
	@echo "║  make seed           Reset + apply schema + seed + verify     ║"
	@echo "║  make reset          Drop and recreate the public schema      ║"
	@echo "║  make clean          Alias for 'reset'                        ║"
	@echo "║                                                               ║"
	@echo "║  SCHEMA                                                       ║"
	@echo "║  ──────                                                       ║"
	@echo "║  make schema         Apply all schema files in order          ║"
	@echo "║  make triggers       Apply trigger files only                 ║"
	@echo "║  make indexes        Apply optimization.sql indexes           ║"
	@echo "║  make views          Apply views.sql                          ║"
	@echo "║                                                               ║"
	@echo "║  SEEDING                                                      ║"
	@echo "║  ───────                                                      ║"
	@echo "║  make seed-static    Apply static seed data (perms, roles)    ║"
	@echo "║  make seed-auto      Run dynamic auto-seeder                  ║"
	@echo "║  make seed-auto ROWS=20  Auto-seed with 20 rows per table     ║"
	@echo "║                                                               ║"
	@echo "║  INSPECTION                                                   ║"
	@echo "║  ──────────                                                   ║"
	@echo "║  make verify         Run full integrity verification          ║"
	@echo "║  make status         Show database statistics                 ║"
	@echo "║  make introspect     Show all tables and FK map               ║"
	@echo "║  make introspect T=users  Inspect a specific table            ║"
	@echo "║                                                               ║"
	@echo "║  QUERIES                                                      ║"
	@echo "║  ───────                                                      ║"
	@echo "║  make query Q=users      List all users                       ║"
	@echo "║  make query Q=orgs       Organizations with member count      ║"
	@echo "║  make query Q=hierarchy  Full org→project→ws→collection tree  ║"
	@echo "║  make query Q=rbac       All user-role assignments            ║"
	@echo "║  make query Q=billing    Subscription status per org          ║"
	@echo "║  make query Q=adapters   Adapter list with health             ║"
	@echo "║  make query Q=connections Database connections                 ║"
	@echo "║  make query Q=stats      Overall DB statistics                ║"
	@echo "║                                                               ║"
	@echo "║  CONFIGURATION                                                ║"
	@echo "║  ─────────────                                                ║"
	@echo "║  DATABASE_URL=...    Override database connection             ║"
	@echo "║  ROWS=N             Rows per table for auto-seed (default: 5) ║"
	@echo "║                                                               ║"
	@echo "╚════════════════════════════════════════════════════════════════╝"
	@echo ""

# ── Setup (ensure scripts are executable) ────────────────────────────────────

setup:  ## Ensure all manager scripts are executable
	@chmod +x $(MANAGER)/*.sh 2>/dev/null || true

# ── Database Reset ───────────────────────────────────────────────────────────

reset: setup  ## Drop all tables and recreate clean public schema
	@$(MANAGER)/reset.sh "$(DATABASE_URL)"

clean: reset  ## Alias for reset

# ── Schema Application ──────────────────────────────────────────────────────

schema: setup  ## Apply all schema files (tables + triggers + indexes + views)
	@$(MANAGER)/apply_schema.sh "$(DATABASE_URL)"

triggers: setup  ## Apply trigger files only
	@echo "── Applying triggers ──"
	@for f in triggers/triggers.utility.sql triggers/triggers.user.sql \
	          triggers/triggers.organization.sql triggers/triggers.billing.sql \
	          triggers/triggers.collection.sql triggers/triggers.dashboard.sql \
	          triggers/triggers.resource.sql triggers/triggers.connectivity.sql \
	          triggers/triggers.adapter.sql triggers/triggers.system.sql; do \
	    if [ -f "$$f" ]; then \
	        printf "  "; \
	        psql "$(DATABASE_URL)" -f "$$f" -v ON_ERROR_STOP=1 > /dev/null 2>&1 \
	            && echo "OK    $$f" \
	            || echo "FAIL  $$f"; \
	    fi; \
	done

indexes: setup  ## Apply optimization.sql indexes
	@echo "── Applying indexes ──"
	@psql "$(DATABASE_URL)" -f optimization.sql -v ON_ERROR_STOP=1 > /dev/null 2>&1 \
	    && echo "✓ Indexes applied." \
	    || echo "✗ Index application failed."

views: setup  ## Apply views.sql
	@echo "── Applying views ──"
	@psql "$(DATABASE_URL)" -f views.sql -v ON_ERROR_STOP=1 > /dev/null 2>&1 \
	    && echo "✓ Views applied." \
	    || echo "✗ View application failed."

# ── Seeding ──────────────────────────────────────────────────────────────────

seed-static: setup  ## Apply static seed data (permissions, roles, plans, meters)
	@$(MANAGER)/apply_seeds.sh "$(DATABASE_URL)"

seed-auto: setup  ## Run dynamic auto-seeder (discovers schema + generates mock data)
	@$(MANAGER)/seed.sh "$(DATABASE_URL)" "$(ROWS)"

seed: reset schema seed-static seed-auto verify  ## Full reseed pipeline
	@echo ""
	@echo "✓ Database reseeded with $(ROWS) rows per table."

# ── Verification & Inspection ────────────────────────────────────────────────

verify: setup  ## Run full integrity verification
	@$(MANAGER)/verify.sh "$(DATABASE_URL)"

status: setup  ## Show quick database statistics
	@$(MANAGER)/query.sh "$(DATABASE_URL)" stats

introspect: setup  ## Introspect database schema (use T=tablename for specific table)
	@$(MANAGER)/introspect.sh "$(DATABASE_URL)" "$(or $(T),)"

# ── Query Shortcuts ──────────────────────────────────────────────────────────

Q ?= stats

query: setup  ## Run a named query (Q=users|orgs|hierarchy|rbac|billing|adapters|connections|stats)
	@$(MANAGER)/query.sh "$(DATABASE_URL)" "$(Q)"

# ── Convenience aliases ──────────────────────────────────────────────────────

fresh: all  ## Alias for 'all'

debug: introspect verify  ## Debug: introspect + verify

permissions: setup  ## Show all permissions in the database
	@psql "$(DATABASE_URL)" -c "SELECT name, resource_type, action FROM permissions ORDER BY resource_type, action;"
