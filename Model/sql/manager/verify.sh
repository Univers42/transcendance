#!/usr/bin/env bash
# ============================================================================
# verify.sh — Verify database integrity after seeding
# ============================================================================
# Runs a comprehensive set of checks to ensure:
#   1. All tables exist and have rows
#   2. FK constraints are satisfied
#   3. Row counts are reported
#   4. Sample data is shown for key tables
#   5. RBAC chain is intact (users → roles → permissions)
#
# Usage: ./manager/verify.sh [DATABASE_URL]
# ============================================================================
set -euo pipefail

DB_URL="${1:-${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/transcendence}}"

echo "════════════════════════════════════════════════════════════════"
echo "  DATABASE VERIFICATION"
echo "════════════════════════════════════════════════════════════════"
echo "  Target: $DB_URL"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ── 1. Table existence and row counts ──
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  1. TABLE ROW COUNTS                                        │"
echo "└──────────────────────────────────────────────────────────────┘"
psql "$DB_URL" -c "SELECT * FROM fn_table_row_counts() ORDER BY table_name;" 2>/dev/null || \
psql "$DB_URL" <<'SQL'
DO $$
DECLARE
    r RECORD;
    cnt BIGINT;
    total BIGINT := 0;
    tbl_count INT := 0;
    empty_count INT := 0;
BEGIN
    RAISE NOTICE '%-40s %s', 'TABLE', 'ROWS';
    RAISE NOTICE '%-40s %s', '────────────────────────────────────────', '──────';
    FOR r IN
        SELECT table_name::TEXT AS tname
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
        ORDER BY table_name
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I', r.tname) INTO cnt;
        RAISE NOTICE '%-40s %s', r.tname, cnt;
        total := total + cnt;
        tbl_count := tbl_count + 1;
        IF cnt = 0 THEN empty_count := empty_count + 1; END IF;
    END LOOP;
    RAISE NOTICE '';
    RAISE NOTICE 'Total tables: %  |  Total rows: %  |  Empty tables: %',
        tbl_count, total, empty_count;
END;
$$;
SQL

echo ""

# ── 2. FK integrity check ──
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  2. FOREIGN KEY INTEGRITY                                   │"
echo "└──────────────────────────────────────────────────────────────┘"
psql "$DB_URL" <<'SQL'
DO $$
DECLARE
    r RECORD;
    cnt BIGINT;
    violations INT := 0;
BEGIN
    FOR r IN
        SELECT
            tc.table_name::TEXT AS src_table,
            kcu.column_name::TEXT AS src_column,
            ccu.table_name::TEXT AS ref_table,
            ccu.column_name::TEXT AS ref_column
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON kcu.constraint_name = tc.constraint_name
            AND kcu.table_schema = tc.table_schema
        JOIN information_schema.constraint_column_usage ccu
            ON ccu.constraint_name = tc.constraint_name
            AND ccu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'FOREIGN KEY'
          AND tc.table_schema = 'public'
    LOOP
        EXECUTE format(
            'SELECT COUNT(*) FROM %I s WHERE s.%I IS NOT NULL AND NOT EXISTS (SELECT 1 FROM %I r WHERE r.%I = s.%I)',
            r.src_table, r.src_column, r.ref_table, r.ref_column, r.src_column
        ) INTO cnt;

        IF cnt > 0 THEN
            RAISE NOTICE '✗ FK violation: %.% → %.% (% orphan rows)',
                r.src_table, r.src_column, r.ref_table, r.ref_column, cnt;
            violations := violations + 1;
        END IF;
    END LOOP;

    IF violations = 0 THEN
        RAISE NOTICE '✓ All foreign key constraints satisfied.';
    ELSE
        RAISE NOTICE '';
        RAISE NOTICE '✗ Found % FK violations.', violations;
    END IF;
END;
$$;
SQL

echo ""

# ── 3. Sample data from key tables ──
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  3. SAMPLE DATA                                             │"
echo "└──────────────────────────────────────────────────────────────┘"
psql "$DB_URL" <<'SQL'
\echo '── users (first 3) ──'
SELECT id, email, username, display_name, status, is_active FROM users LIMIT 3;

\echo '── organizations (first 3) ──'
SELECT id, name, slug, is_active FROM organizations LIMIT 3;

\echo '── roles (first 5) ──'
SELECT id, name, scope, is_system FROM roles LIMIT 5;

\echo '── permissions (first 5) ──'
SELECT id, name, resource_type, action FROM permissions LIMIT 5;

\echo '── plans (all) ──'
SELECT id, slug, name, price_monthly, price_yearly, trial_days FROM plans;
SQL

echo ""

# ── 4. RBAC chain validation ──
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  4. RBAC CHAIN VALIDATION                                   │"
echo "└──────────────────────────────────────────────────────────────┘"
psql "$DB_URL" <<'SQL'
DO $$
DECLARE
    user_cnt INT;
    role_cnt INT;
    perm_cnt INT;
    ura_cnt INT;
    rp_cnt INT;
BEGIN
    SELECT COUNT(*) INTO user_cnt FROM users;
    SELECT COUNT(*) INTO role_cnt FROM roles;
    SELECT COUNT(*) INTO perm_cnt FROM permissions;
    SELECT COUNT(*) INTO ura_cnt FROM user_role_assignments;
    SELECT COUNT(*) INTO rp_cnt FROM role_permissions;

    RAISE NOTICE 'RBAC Chain Summary:';
    RAISE NOTICE '  Users:                   %', user_cnt;
    RAISE NOTICE '  Roles:                   %', role_cnt;
    RAISE NOTICE '  Permissions:             %', perm_cnt;
    RAISE NOTICE '  User → Role Assignments: %', ura_cnt;
    RAISE NOTICE '  Role → Permissions:      %', rp_cnt;

    IF user_cnt > 0 AND role_cnt > 0 AND perm_cnt > 0 AND ura_cnt > 0 AND rp_cnt > 0 THEN
        RAISE NOTICE '  Status: ✓ RBAC chain is complete.';
    ELSE
        RAISE NOTICE '  Status: ✗ RBAC chain is incomplete.';
    END IF;
END;
$$;
SQL

echo ""

# ── 5. Hierarchy validation ──
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  5. TENANT HIERARCHY                                        │"
echo "└──────────────────────────────────────────────────────────────┘"
psql "$DB_URL" <<'SQL'
\echo '── Organization → Project → Workspace → Collection hierarchy ──'
SELECT
    o.name AS organization,
    p.name AS project,
    w.name AS workspace,
    c.name AS collection
FROM organizations o
LEFT JOIN projects p ON p.organization_id = o.id
LEFT JOIN workspaces w ON w.project_id = p.id
LEFT JOIN collections c ON c.workspace_id = w.id
ORDER BY o.name, p.name, w.name, c.name
LIMIT 20;
SQL

echo ""

# ── 6. Dependency order ──
echo "┌──────────────────────────────────────────────────────────────┐"
echo "│  6. TABLE DEPENDENCY ORDER                                   │"
echo "└──────────────────────────────────────────────────────────────┘"
psql "$DB_URL" -c "SELECT * FROM fn_show_insert_order();" 2>/dev/null || \
echo "(fn_show_insert_order not available — skipped)"

echo ""
echo "════════════════════════════════════════════════════════════════"
echo "  VERIFICATION COMPLETE"
echo "════════════════════════════════════════════════════════════════"
