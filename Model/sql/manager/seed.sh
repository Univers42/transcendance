#!/usr/bin/env bash
# ============================================================================
# seed.sh — Load auto_seed functions and execute seeding
# ============================================================================
# Installs the auto_seed.sql functions into the database, then runs the
# auto_seed_all() function to populate all tables with mock data.
#
# Usage: ./manager/seed.sh [DATABASE_URL] [ROWS_PER_TABLE]
# ============================================================================
set -euo pipefail

DB_URL="${1:-${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/transcendence}}"
ROWS="${2:-5}"
MANAGER_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "════════════════════════════════════════════════════════════════"
echo "  AUTO-SEED DATABASE"
echo "════════════════════════════════════════════════════════════════"
echo "  Target:         $DB_URL"
echo "  Rows per table: $ROWS"
echo "════════════════════════════════════════════════════════════════"
echo ""

# Step 1: Install seed functions
echo "── Step 1: Installing auto-seed functions ──"
if psql "$DB_URL" -f "$MANAGER_DIR/auto_seed.sql" -v ON_ERROR_STOP=1 > /dev/null 2>&1; then
    echo "  ✓ Seed functions installed."
else
    echo "  ✗ Failed to install seed functions. Error:"
    psql "$DB_URL" -f "$MANAGER_DIR/auto_seed.sql" -v ON_ERROR_STOP=1 2>&1 | tail -10
    exit 1
fi

echo ""

# Step 2: Show table insertion order
echo "── Step 2: Table dependency order ──"
psql "$DB_URL" -c "SELECT * FROM fn_show_insert_order();" 2>/dev/null || echo "(skipped)"

echo ""

# Step 3: Execute auto-seeding
echo "── Step 3: Seeding all tables ($ROWS rows each) ──"
psql "$DB_URL" <<SQL
\timing on
SELECT * FROM auto_seed_all(rows_per_table := $ROWS);
\timing off
SQL

echo ""

# Step 4: Final row counts
echo "── Step 4: Final row counts ──"
psql "$DB_URL" -c "SELECT * FROM fn_table_row_counts() ORDER BY table_name;"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  SEEDING COMPLETE"
echo "════════════════════════════════════════════════════════════════"
