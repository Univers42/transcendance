#!/usr/bin/env bash
# ============================================================================
# apply_schema.sh — Apply all schema files in correct dependency order
# ============================================================================
# Executes all schema SQL files, then triggers, optimization, and views
# in the correct order defined by the domain dependency chain.
#
# Order:
#   1. schema.user.sql          (users, roles, permissions, sessions)
#   2. schema.organization.sql  (organizations, projects, workspaces)
#   3. schema.billing.sql       (plans, subscriptions, invoices)
#   4. schema.collection.sql    (collections, fields, relations)
#   5. schema.dashboard.sql     (dashboards, views, templates)
#   6. schema.resource.sql      (resources, permissions, versions)
#   7. schema.connectivity.sql  (connections, sync channels)
#   8. schema.adapter.sql       (adapters, mappings, executions)
#   9. schema.system.sql        (webhooks, notifications, policies, files)
#  10. schema.abac.sql          (enhanced ABAC engine: rules, groups, policies)
#  11. triggers.utility.sql     (shared trigger functions)
#  12. triggers.user.sql        (user/auth triggers)
#  13. triggers.organization.sql
#  14. triggers.billing.sql
#  15. triggers.collection.sql
#  16. triggers.dashboard.sql
#  17. triggers.resource.sql
#  18. triggers.connectivity.sql
#  19. triggers.adapter.sql
#  20. triggers.system.sql
#  21. triggers.abac.sql        (ABAC engine triggers)
#  22. optimization.sql         (indexes)
#  23. views.sql                (SQL views)
#
# Usage: ./manager/apply_schema.sh [DATABASE_URL]
# ============================================================================
set -euo pipefail

DB_URL="${1:-${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/transcendence}}"
SQL_DIR="$(cd "$(dirname "$0")/.." && pwd)"

echo "════════════════════════════════════════════════════════════════"
echo "  APPLY ALL SCHEMAS"
echo "════════════════════════════════════════════════════════════════"
echo "  Target: $DB_URL"
echo "  SQL Dir: $SQL_DIR"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Schema files in dependency order
SCHEMA_FILES=(
    "schema.user.sql"
    "schema.organization.sql"
    "schema.billing.sql"
    "schema.collection.sql"
    "schema.dashboard.sql"
    "schema.resource.sql"
    "schema.connectivity.sql"
    "schema.adapter.sql"
    "schema.system.sql"
    "schema.abac.sql"
)

# Trigger files in dependency order
TRIGGER_FILES=(
    "triggers/triggers.utility.sql"
    "triggers/triggers.user.sql"
    "triggers/triggers.organization.sql"
    "triggers/triggers.billing.sql"
    "triggers/triggers.collection.sql"
    "triggers/triggers.dashboard.sql"
    "triggers/triggers.resource.sql"
    "triggers/triggers.connectivity.sql"
    "triggers/triggers.adapter.sql"
    "triggers/triggers.system.sql"
    "triggers/triggers.abac.sql"
)

# Post-schema files
POST_FILES=(
    "optimization.sql"
    "views.sql"
)

TOTAL_FILES=$(( ${#SCHEMA_FILES[@]} + ${#TRIGGER_FILES[@]} + ${#POST_FILES[@]} ))
CURRENT=0
FAILED=0

apply_file() {
    local file="$1"
    local path="$SQL_DIR/$file"
    CURRENT=$((CURRENT + 1))

    if [ ! -f "$path" ]; then
        echo "  [$CURRENT/$TOTAL_FILES] SKIP  $file (not found)"
        return
    fi

    printf "  [%2d/%d] " "$CURRENT" "$TOTAL_FILES"
    if psql "$DB_URL" -f "$path" -v ON_ERROR_STOP=1 > /dev/null 2>&1; then
        echo "OK    $file"
    else
        echo "FAIL  $file"
        FAILED=$((FAILED + 1))
        # Show the error
        psql "$DB_URL" -f "$path" -v ON_ERROR_STOP=1 2>&1 | tail -5 || true
    fi
}

echo "── Phase 1: Schema Tables ──"
for f in "${SCHEMA_FILES[@]}"; do
    apply_file "$f"
done

echo ""
echo "── Phase 2: Triggers ──"
for f in "${TRIGGER_FILES[@]}"; do
    apply_file "$f"
done

echo ""
echo "── Phase 3: Indexes & Views ──"
for f in "${POST_FILES[@]}"; do
    apply_file "$f"
done

echo ""
if [ "$FAILED" -eq 0 ]; then
    echo "✓ All $TOTAL_FILES files applied successfully."
else
    echo "✗ $FAILED/$TOTAL_FILES files failed. Check output above."
    exit 1
fi
