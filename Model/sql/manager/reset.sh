#!/usr/bin/env bash
# ============================================================================
# reset.sh — Drop all tables, functions, triggers and reset the database
# ============================================================================
# Drops everything in the public schema and recreates it clean.
# Used before re-applying schemas and re-seeding.
#
# Usage: ./manager/reset.sh [DATABASE_URL]
# ============================================================================
set -euo pipefail

DB_URL="${1:-${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/transcendence}}"

# ── Extract DB name and build a maintenance URL pointing to "postgres" DB ────
# We need to connect to the default "postgres" database to CREATE the target DB
DB_NAME=$(echo "$DB_URL" | sed -E 's|.*/([^?]+).*|\1|')
MAINTENANCE_URL=$(echo "$DB_URL" | sed -E "s|/[^/?]+(\?.*)?$|/postgres\1|")

echo "════════════════════════════════════════════════════════════════"
echo "  DATABASE RESET"
echo "════════════════════════════════════════════════════════════════"
echo "  Target: $DB_URL"
echo "  Database: $DB_NAME"
echo "  Action: CREATE database (if needed) → DROP and RECREATE public schema"
echo "════════════════════════════════════════════════════════════════"

# ── Step 1: Ensure the database exists ───────────────────────────────────────
if ! psql "$MAINTENANCE_URL" -tAc "SELECT 1 FROM pg_database WHERE datname = '$DB_NAME'" 2>/dev/null | grep -q 1; then
    echo "  Database '$DB_NAME' does not exist — creating it..."
    psql "$MAINTENANCE_URL" -c "CREATE DATABASE \"$DB_NAME\";" 2>&1
    echo "  ✓ Database '$DB_NAME' created."
else
    echo "  Database '$DB_NAME' already exists."
fi

# ── Step 2: Reset the public schema ──────────────────────────────────────────
psql "$DB_URL" <<'SQL'
-- Drop everything in public schema
DROP SCHEMA IF EXISTS public CASCADE;
CREATE SCHEMA public;

-- Restore default grants
GRANT ALL ON SCHEMA public TO PUBLIC;
GRANT ALL ON SCHEMA public TO CURRENT_USER;

-- Re-enable required extensions
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

\echo ''
\echo '✓ Database reset complete. Public schema is clean.'
\echo ''
SQL

echo "Done."
