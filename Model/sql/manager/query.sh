#!/usr/bin/env bash
# ============================================================================
# query.sh — Quick query helper for common operations
# ============================================================================
# Provides named shortcuts for frequently used queries to validate
# seed data, inspect relationships, and test access patterns.
#
# Usage: ./manager/query.sh [DATABASE_URL] <command>
#
# Commands:
#   users           — List all users
#   orgs            — List all organizations with member count
#   hierarchy       — Show full org → project → workspace → collection tree
#   rbac <user_id>  — Show user's roles and permissions
#   billing         — Show subscription status per org
#   adapters        — List adapters with health status
#   connections     — List database connections
#   stats           — Overall database statistics
#   custom <sql>    — Run custom SQL
# ============================================================================
set -euo pipefail

DB_URL="${1:-${DATABASE_URL:-postgresql://postgres:postgres@localhost:5432/transcendence}}"
COMMAND="${2:-stats}"
ARG3="${3:-}"

case "$COMMAND" in
    users)
        psql "$DB_URL" -c "
            SELECT u.id, u.email, u.username, u.display_name, u.status, u.is_active,
                   u.last_login_at, u.created_at
            FROM users u ORDER BY u.created_at;"
        ;;

    orgs)
        psql "$DB_URL" -c "
            SELECT o.id, o.name, o.slug, o.is_active,
                   COUNT(om.id) AS members,
                   (SELECT COUNT(*) FROM projects p WHERE p.organization_id = o.id) AS projects
            FROM organizations o
            LEFT JOIN organization_members om ON om.organization_id = o.id
            GROUP BY o.id ORDER BY o.name;"
        ;;

    hierarchy)
        psql "$DB_URL" -c "
            SELECT
                o.name AS organization,
                p.name AS project,
                w.name AS workspace,
                w.type AS ws_type,
                c.name AS collection,
                (SELECT COUNT(*) FROM fields f WHERE f.collection_id = c.id) AS fields
            FROM organizations o
            LEFT JOIN projects p ON p.organization_id = o.id
            LEFT JOIN workspaces w ON w.project_id = p.id
            LEFT JOIN collections c ON c.workspace_id = w.id
            ORDER BY o.name, p.name, w.name, c.name;"
        ;;

    rbac)
        if [ -z "$ARG3" ]; then
            # Show all users with their roles
            psql "$DB_URL" -c "
                SELECT u.username, r.name AS role, r.scope,
                       ura.context_type, ura.context_id,
                       ura.assigned_at, ura.expires_at
                FROM user_role_assignments ura
                JOIN users u ON u.id = ura.user_id
                JOIN roles r ON r.id = ura.role_id
                ORDER BY u.username, r.scope;"
        else
            # Show specific user's RBAC
            psql "$DB_URL" -c "
                SELECT r.name AS role, r.scope, ura.context_type,
                       ura.context_id, ura.expires_at
                FROM user_role_assignments ura
                JOIN roles r ON r.id = ura.role_id
                WHERE ura.user_id = '$ARG3'
                ORDER BY r.scope;"
            psql "$DB_URL" -c "
                SELECT DISTINCT p.name AS permission, p.resource_type, p.action
                FROM user_role_assignments ura
                JOIN role_permissions rp ON rp.role_id = ura.role_id
                JOIN permissions p ON p.id = rp.permission_id
                WHERE ura.user_id = '$ARG3'
                  AND (ura.expires_at IS NULL OR ura.expires_at > now())
                ORDER BY p.resource_type, p.action;"
        fi
        ;;

    billing)
        psql "$DB_URL" -c "
            SELECT o.name AS organization,
                   pl.name AS plan,
                   s.status AS sub_status,
                   s.billing_period,
                   s.current_period_start,
                   s.current_period_end,
                   (SELECT COUNT(*) FROM invoices i WHERE i.organization_id = o.id) AS invoices
            FROM organizations o
            LEFT JOIN subscriptions s ON s.organization_id = o.id
            LEFT JOIN plans pl ON pl.id = s.plan_id
            ORDER BY o.name;"
        ;;

    adapters)
        psql "$DB_URL" -c "
            SELECT a.name, a.adapter_type, a.health_status, a.is_active,
                   o.name AS organization,
                   (SELECT COUNT(*) FROM adapter_mappings am WHERE am.adapter_id = a.id) AS mappings,
                   (SELECT COUNT(*) FROM adapter_executions ae WHERE ae.adapter_id = a.id) AS executions
            FROM adapters a
            JOIN organizations o ON o.id = a.organization_id
            ORDER BY a.name;"
        ;;

    connections)
        psql "$DB_URL" -c "
            SELECT dc.name, dc.engine, dc.connection_type, dc.health_status,
                   dc.is_active, o.name AS organization,
                   (SELECT COUNT(*) FROM sync_channels sc WHERE sc.connection_id = dc.id) AS sync_channels
            FROM database_connections dc
            JOIN organizations o ON o.id = dc.organization_id
            ORDER BY dc.name;"
        ;;

    stats)
        psql "$DB_URL" <<'SQL'
DO $$
DECLARE
    r RECORD;
    cnt BIGINT;
    total BIGINT := 0;
    tbl_count INT := 0;
BEGIN
    RAISE NOTICE '════════════════════════════════════════════════';
    RAISE NOTICE '  DATABASE STATISTICS';
    RAISE NOTICE '════════════════════════════════════════════════';

    FOR r IN
        SELECT table_name::TEXT AS tname
        FROM information_schema.tables
        WHERE table_schema = 'public' AND table_type = 'BASE TABLE'
        ORDER BY table_name
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I', r.tname) INTO cnt;
        total := total + cnt;
        tbl_count := tbl_count + 1;
    END LOOP;

    RAISE NOTICE '  Tables:     %', tbl_count;
    RAISE NOTICE '  Total rows: %', total;
    RAISE NOTICE '  Avg rows:   %', CASE WHEN tbl_count > 0 THEN total / tbl_count ELSE 0 END;

    SELECT COUNT(*) INTO cnt FROM information_schema.table_constraints
    WHERE table_schema = 'public' AND constraint_type = 'FOREIGN KEY';
    RAISE NOTICE '  FK constraints: %', cnt;

    SELECT COUNT(*) INTO cnt FROM pg_indexes WHERE schemaname = 'public';
    RAISE NOTICE '  Indexes:    %', cnt;

    SELECT COUNT(*) INTO cnt FROM pg_trigger t
    JOIN pg_class c ON c.oid = t.tgrelid
    JOIN pg_namespace n ON n.oid = c.relnamespace
    WHERE n.nspname = 'public' AND NOT t.tgisinternal;
    RAISE NOTICE '  Triggers:   %', cnt;

    SELECT COUNT(*) INTO cnt FROM information_schema.views WHERE table_schema = 'public';
    RAISE NOTICE '  Views:      %', cnt;
END;
$$;
SQL
        ;;

    custom)
        if [ -z "$ARG3" ]; then
            echo "Usage: query.sh [DB_URL] custom \"SELECT ...\""
            exit 1
        fi
        psql "$DB_URL" -c "$ARG3"
        ;;

    *)
        echo "Unknown command: $COMMAND"
        echo "Available: users, orgs, hierarchy, rbac, billing, adapters, connections, stats, custom"
        exit 1
        ;;
esac
