#!/usr/bin/env bash
# ============================================================================
# apply_seeds.sh — Apply static seed data files in order
# ============================================================================
# Runs all numbered seed files in seeds/ directory in order.
# These provide canonical system data (permissions, roles, plans) that
# should exist before the dynamic auto-seeder runs.
#
# Usage: ./manager/apply_seeds.sh [DATABASE_URL]
# ============================================================================
set -euo pipefail

DB_URL="${1:-${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/transcendence}}"
SQL_DIR="$(cd "$(dirname "$0")/.." && pwd)"
SEEDS_DIR="$SQL_DIR/seeds"

echo "════════════════════════════════════════════════════════════════"
echo "  APPLY STATIC SEED DATA"
echo "════════════════════════════════════════════════════════════════"
echo "  Target: $DB_URL"
echo "  Seeds:  $SEEDS_DIR"
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ ! -d "$SEEDS_DIR" ]; then
    echo "  No seeds directory found. Skipping."
    exit 0
fi

SEED_FILES=$(find "$SEEDS_DIR" -name '*.sql' -type f | sort)

if [ -z "$SEED_FILES" ]; then
    echo "  No seed files found. Skipping."
    exit 0
fi

FAILED=0
TOTAL=0

while IFS= read -r seed_file; do
    TOTAL=$((TOTAL + 1))
    fname=$(basename "$seed_file")
    printf "  [%d] " "$TOTAL"

    if psql "$DB_URL" -f "$seed_file" -v ON_ERROR_STOP=1 > /dev/null 2>&1; then
        echo "OK    $fname"
    else
        echo "FAIL  $fname"
        FAILED=$((FAILED + 1))
        psql "$DB_URL" -f "$seed_file" 2>&1 | tail -3 || true
    fi
done <<< "$SEED_FILES"

echo ""
if [ "$FAILED" -eq 0 ]; then
    echo "✓ All $TOTAL seed files applied successfully."
else
    echo "✗ $FAILED/$TOTAL seed files failed."
    exit 1
fi
