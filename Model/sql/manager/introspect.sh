#!/usr/bin/env bash
# ============================================================================
# introspect.sh — Introspect database schema and dump column metadata
# ============================================================================
# Shows all tables, columns, types, constraints, FKs, and indexes.
# Useful for debugging seed issues or understanding the current schema state.
#
# Usage: ./manager/introspect.sh [DATABASE_URL] [table_name]
# ============================================================================
set -euo pipefail

DB_URL="${1:-${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/transcendence}}"
TARGET_TABLE="${2:-}"

echo "════════════════════════════════════════════════════════════════"
echo "  DATABASE INTROSPECTION"
echo "════════════════════════════════════════════════════════════════"
echo "  Target: $DB_URL"
if [ -n "$TARGET_TABLE" ]; then
    echo "  Table:  $TARGET_TABLE"
fi
echo "════════════════════════════════════════════════════════════════"
echo ""

if [ -n "$TARGET_TABLE" ]; then
    # ── Detailed view of one table ──
    echo "┌──────────────────────────────────────────────────────────────┐"
    echo "│  TABLE: $TARGET_TABLE"
    echo "└──────────────────────────────────────────────────────────────┘"

    psql "$DB_URL" <<SQL
-- Columns
\echo '── Columns ──'
SELECT
    ordinal_position AS "#",
    column_name,
    CASE
        WHEN character_maximum_length IS NOT NULL
            THEN data_type || '(' || character_maximum_length || ')'
        ELSE data_type
    END AS full_type,
    is_nullable AS "null?",
    COALESCE(LEFT(column_default::TEXT, 40), '') AS "default"
FROM information_schema.columns
WHERE table_schema = 'public'
  AND table_name = '$TARGET_TABLE'
ORDER BY ordinal_position;

-- Foreign keys
\echo '── Foreign Keys ──'
SELECT
    kcu.column_name AS "column",
    ccu.table_name AS "references",
    ccu.column_name AS "ref_column"
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON kcu.constraint_name = tc.constraint_name
    AND kcu.table_schema = tc.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
  AND tc.table_name = '$TARGET_TABLE';

-- CHECK constraints
\echo '── CHECK Constraints ──'
SELECT
    cc.constraint_name,
    LEFT(cc.check_clause, 100) AS check_clause
FROM information_schema.table_constraints tc
JOIN information_schema.check_constraints cc
    ON cc.constraint_name = tc.constraint_name
    AND cc.constraint_schema = tc.constraint_schema
WHERE tc.constraint_type = 'CHECK'
  AND tc.table_schema = 'public'
  AND tc.table_name = '$TARGET_TABLE';

-- Indexes
\echo '── Indexes ──'
SELECT
    indexname,
    LEFT(indexdef, 100) AS definition
FROM pg_indexes
WHERE schemaname = 'public'
  AND tablename = '$TARGET_TABLE';

-- Row count
\echo '── Row Count ──'
SELECT COUNT(*) AS total_rows FROM "$TARGET_TABLE";

-- Sample data
\echo '── Sample Data (first 5 rows) ──'
SELECT * FROM "$TARGET_TABLE" LIMIT 5;
SQL

else
    # ── Overview of all tables ──
    echo "┌──────────────────────────────────────────────────────────────┐"
    echo "│  ALL TABLES OVERVIEW                                        │"
    echo "└──────────────────────────────────────────────────────────────┘"

    psql "$DB_URL" <<'SQL'
SELECT
    t.table_name,
    (SELECT COUNT(*)
     FROM information_schema.columns c
     WHERE c.table_name = t.table_name AND c.table_schema = 'public') AS columns,
    (SELECT COUNT(*)
     FROM information_schema.table_constraints tc
     WHERE tc.table_name = t.table_name
       AND tc.table_schema = 'public'
       AND tc.constraint_type = 'FOREIGN KEY') AS fk_count,
    (SELECT COUNT(*)
     FROM information_schema.table_constraints tc
     WHERE tc.table_name = t.table_name
       AND tc.table_schema = 'public'
       AND tc.constraint_type = 'CHECK') AS check_count
FROM information_schema.tables t
WHERE t.table_schema = 'public'
  AND t.table_type = 'BASE TABLE'
ORDER BY t.table_name;
SQL

    echo ""
    echo "┌──────────────────────────────────────────────────────────────┐"
    echo "│  FK DEPENDENCY MAP                                          │"
    echo "└──────────────────────────────────────────────────────────────┘"

    psql "$DB_URL" <<'SQL'
SELECT
    tc.table_name AS "table",
    kcu.column_name AS "column",
    ccu.table_name AS "→ references",
    ccu.column_name AS "→ column"
FROM information_schema.table_constraints tc
JOIN information_schema.key_column_usage kcu
    ON kcu.constraint_name = tc.constraint_name
    AND kcu.table_schema = tc.table_schema
JOIN information_schema.constraint_column_usage ccu
    ON ccu.constraint_name = tc.constraint_name
    AND ccu.table_schema = tc.table_schema
WHERE tc.constraint_type = 'FOREIGN KEY'
  AND tc.table_schema = 'public'
ORDER BY tc.table_name, kcu.column_name;
SQL
fi

echo ""
echo "Done."
