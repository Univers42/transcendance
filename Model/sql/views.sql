-- ============================================================================
-- views.sql — SQL Views for common queries
-- ============================================================================
-- These views simplify frequent access patterns used by the backend API.
-- They are read-only projections — all writes go through the base tables.
--
-- UPDATED FOR 5NF SCHEMA:
--   • Roles are now resolved via user_role_assignments with context_type/context_id
--     instead of VARCHAR role columns on membership tables
--   • ABAC conditions include optional role_id scoping
--   • All views reflect the unified RBAC architecture
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- v_user_profile
-- ─────────────────────────────────────────────────────────────────────────────
-- User with all active roles (across all contexts) and organization memberships.
--
-- USAGE: SELECT * FROM v_user_profile WHERE id = $user_id;
--
-- JOINS:
--   users → user_role_assignments (active only) → roles
--   users → organization_members → organizations
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_user_profile AS
SELECT
    u.id,
    u.email,
    u.username,
    u.display_name,
    u.avatar_url,
    u.status,
    u.is_active,
    u.mfa_enabled,
    u.last_login_at,
    u.created_at,
    COALESCE(
        json_agg(DISTINCT jsonb_build_object(
            'role_id', r.id,
            'role_name', r.name,
            'scope', r.scope,
            'context_type', ura.context_type,
            'context_id', ura.context_id,
            'expires_at', ura.expires_at
        )) FILTER (WHERE r.id IS NOT NULL),
        '[]'::json
    ) AS roles,
    COALESCE(
        json_agg(DISTINCT jsonb_build_object(
            'org_id', o.id,
            'org_name', o.name,
            'org_slug', o.slug
        )) FILTER (WHERE o.id IS NOT NULL),
        '[]'::json
    ) AS organizations
FROM users u
LEFT JOIN user_role_assignments ura ON ura.user_id = u.id
    AND (ura.expires_at IS NULL OR ura.expires_at > now())
LEFT JOIN roles r ON r.id = ura.role_id
LEFT JOIN organization_members om ON om.user_id = u.id
LEFT JOIN organizations o ON o.id = om.organization_id AND o.is_active = TRUE
GROUP BY u.id;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_user_effective_permissions
-- ─────────────────────────────────────────────────────────────────────────────
-- Resolves all permissions a user has through roles + direct grants.
-- Does NOT evaluate ABAC conditions (those require runtime context).
--
-- USAGE: SELECT * FROM v_user_effective_permissions WHERE user_id = $user_id;
--
-- GRANT SOURCE:
--   'denied'       → explicit deny via user_permissions (highest priority)
--   'direct_grant' → explicit allow via user_permissions
--   'role_grant'   → inherited through role_permissions
--
-- JOINS:
--   users → user_role_assignments (active) → role_permissions → permissions
--   users → user_permissions → permissions
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_user_effective_permissions AS
SELECT DISTINCT
    u.id AS user_id,
    p.id AS permission_id,
    p.name AS permission_name,
    p.resource_type,
    p.action,
    CASE
        WHEN up.granted = FALSE THEN 'denied'
        WHEN up.id IS NOT NULL THEN 'direct_grant'
        ELSE 'role_grant'
    END AS grant_source,
    ura.context_type,
    ura.context_id,
    COALESCE(up.expires_at, ura.expires_at) AS expires_at
FROM users u
-- Role-based permissions
LEFT JOIN user_role_assignments ura ON ura.user_id = u.id
    AND (ura.expires_at IS NULL OR ura.expires_at > now())
LEFT JOIN role_permissions rp ON rp.role_id = ura.role_id
-- Direct user permissions
LEFT JOIN user_permissions up ON up.user_id = u.id
    AND (up.expires_at IS NULL OR up.expires_at > now())
-- Resolve permission details
JOIN permissions p ON p.id = COALESCE(up.permission_id, rp.permission_id)
WHERE u.is_active = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_org_hierarchy
-- ─────────────────────────────────────────────────────────────────────────────
-- Organization → Projects → Workspaces with collection/dashboard counts.
--
-- USAGE: SELECT * FROM v_org_hierarchy WHERE organization_id = $org_id;
--
-- JOINS:
--   organizations → projects → workspaces
--   Subqueries for collection_count and dashboard_count
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_org_hierarchy AS
SELECT
    o.id AS organization_id,
    o.name AS organization_name,
    o.slug AS organization_slug,
    COALESCE(
        (SELECT pl.slug FROM subscriptions s
         JOIN plans pl ON pl.id = s.plan_id
         WHERE s.organization_id = o.id
           AND s.status IN ('trialing','active')
         LIMIT 1),
        'free'
    ) AS plan,
    p.id AS project_id,
    p.name AS project_name,
    p.slug AS project_slug,
    p.is_archived AS project_archived,
    w.id AS workspace_id,
    w.name AS workspace_name,
    w.slug AS workspace_slug,
    w.type AS workspace_type,
    (SELECT COUNT(*) FROM collections c WHERE c.workspace_id = w.id) AS collection_count,
    (SELECT COUNT(*) FROM dashboards d WHERE d.workspace_id = w.id) AS dashboard_count
FROM organizations o
JOIN projects p ON p.organization_id = o.id
JOIN workspaces w ON w.project_id = p.id
WHERE o.is_active = TRUE;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_collection_schema
-- ─────────────────────────────────────────────────────────────────────────────
-- Collection with all its fields aggregated as JSON array.
--
-- USAGE: SELECT * FROM v_collection_schema WHERE collection_id = $coll_id;
--
-- JOINS:
--   collections → fields (aggregated)
--   Subqueries for relation_count and view_count
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_collection_schema AS
SELECT
    c.id AS collection_id,
    c.name AS collection_name,
    c.slug AS collection_slug,
    c.workspace_id,
    c.record_count,
    c.is_system,
    COALESCE(
        json_agg(
            jsonb_build_object(
                'field_id', f.id,
                'name', f.name,
                'slug', f.slug,
                'field_type', f.field_type,
                'is_required', f.is_required,
                'is_unique', f.is_unique,
                'is_primary', f.is_primary,
                'is_hidden', f.is_hidden,
                'default_value', f.default_value,
                'validation_rules', f.validation_rules,
                'display_config', f.display_config,
                'sort_order', f.sort_order
            ) ORDER BY f.sort_order
        ) FILTER (WHERE f.id IS NOT NULL),
        '[]'::json
    ) AS fields,
    (SELECT COUNT(*) FROM collection_relations cr
     WHERE cr.source_collection_id = c.id OR cr.target_collection_id = c.id
    ) AS relation_count,
    (SELECT COUNT(*) FROM views v WHERE v.collection_id = c.id) AS view_count
FROM collections c
LEFT JOIN fields f ON f.collection_id = c.id
GROUP BY c.id;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_dashboard_overview
-- ─────────────────────────────────────────────────────────────────────────────
-- Dashboard with full workspace → project → organization context.
--
-- USAGE: SELECT * FROM v_dashboard_overview WHERE workspace_id = $ws_id;
--
-- JOINS:
--   dashboards → workspaces → projects → organizations
--   dashboards → users (created_by)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_dashboard_overview AS
SELECT
    d.id AS dashboard_id,
    d.name,
    d.slug,
    d.description,
    d.workspace_id,
    d.visibility,
    d.is_default,
    d.is_locked,
    d.refresh_interval,
    d.created_by,
    u.display_name AS created_by_name,
    d.created_at,
    d.updated_at,
    w.name AS workspace_name,
    p.name AS project_name,
    p.id AS project_id,
    o.name AS organization_name,
    o.id AS organization_id
FROM dashboards d
JOIN workspaces w ON w.id = d.workspace_id
JOIN projects p ON p.id = w.project_id
JOIN organizations o ON o.id = p.organization_id
JOIN users u ON u.id = d.created_by;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_adapter_status
-- ─────────────────────────────────────────────────────────────────────────────
-- Adapter health summary with mapping count and recent execution stats.
--
-- USAGE: SELECT * FROM v_adapter_status WHERE organization_id = $org_id;
--
-- JOINS:
--   adapters → adapter_mappings (count)
--   adapters → adapter_executions (latest + failure count)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_adapter_status AS
SELECT
    a.id AS adapter_id,
    a.name,
    a.adapter_type,
    a.health_status,
    a.is_active,
    a.organization_id,
    a.last_health_check,
    COUNT(am.id) AS mapping_count,
    MAX(ae.completed_at) AS last_execution_at,
    (SELECT ae2.status FROM adapter_executions ae2
     WHERE ae2.adapter_id = a.id ORDER BY ae2.created_at DESC LIMIT 1
    ) AS last_execution_status,
    SUM(CASE WHEN ae.status = 'failed' AND ae.created_at > now() - INTERVAL '24 hours'
        THEN 1 ELSE 0 END) AS failures_24h
FROM adapters a
LEFT JOIN adapter_mappings am ON am.adapter_id = a.id
LEFT JOIN adapter_executions ae ON ae.adapter_id = a.id
GROUP BY a.id;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_user_workspace_access
-- ─────────────────────────────────────────────────────────────────────────────
-- For a given user, lists all workspaces they can access with their
-- effective role resolved through user_role_assignments.
--
-- USAGE: SELECT * FROM v_user_workspace_access WHERE user_id = $user_id;
--
-- ROLE RESOLUTION:
--   Checks workspace-level role first, then project-level, then org-level.
--   Most specific context wins (workspace > project > organization).
--
-- ACCESS LEVEL:
--   'workspace'    → user is a direct workspace member
--   'project'      → user inherits access via project membership
--   'organization' → user inherits access via organization membership
--
-- JOINS:
--   users × workspaces → projects → organizations
--   user_role_assignments (at each context level) → roles
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_user_workspace_access AS
SELECT
    u.id AS user_id,
    w.id AS workspace_id,
    w.name AS workspace_name,
    w.slug AS workspace_slug,
    p.id AS project_id,
    p.name AS project_name,
    o.id AS organization_id,
    o.name AS organization_name,
    -- Resolve effective role: most specific context wins
    COALESCE(
        (SELECT r.name FROM user_role_assignments ura
         JOIN roles r ON r.id = ura.role_id
         WHERE ura.user_id = u.id
           AND ura.context_type = 'workspace' AND ura.context_id = w.id
           AND (ura.expires_at IS NULL OR ura.expires_at > now())
         LIMIT 1),
        (SELECT r.name FROM user_role_assignments ura
         JOIN roles r ON r.id = ura.role_id
         WHERE ura.user_id = u.id
           AND ura.context_type = 'project' AND ura.context_id = p.id
           AND (ura.expires_at IS NULL OR ura.expires_at > now())
         LIMIT 1),
        (SELECT r.name FROM user_role_assignments ura
         JOIN roles r ON r.id = ura.role_id
         WHERE ura.user_id = u.id
           AND ura.context_type = 'organization' AND ura.context_id = o.id
           AND (ura.expires_at IS NULL OR ura.expires_at > now())
         LIMIT 1),
        'none'
    ) AS effective_role,
    CASE
        WHEN wm.id IS NOT NULL THEN 'workspace'
        WHEN pm.id IS NOT NULL THEN 'project'
        WHEN om.id IS NOT NULL THEN 'organization'
        ELSE 'none'
    END AS access_level
FROM users u
CROSS JOIN workspaces w
JOIN projects p ON p.id = w.project_id
JOIN organizations o ON o.id = p.organization_id
LEFT JOIN workspace_members wm ON wm.workspace_id = w.id AND wm.user_id = u.id
LEFT JOIN project_members pm ON pm.project_id = p.id AND pm.user_id = u.id
LEFT JOIN organization_members om ON om.organization_id = o.id AND om.user_id = u.id
WHERE wm.id IS NOT NULL OR pm.id IS NOT NULL OR om.id IS NOT NULL;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_notification_feed
-- ─────────────────────────────────────────────────────────────────────────────
-- Notification feed with human-readable relative timestamps.
--
-- USAGE: SELECT * FROM v_notification_feed
--        WHERE user_id = $user_id LIMIT 50;
--
-- JOINS: notifications only (self-contained)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_notification_feed AS
SELECT
    n.id,
    n.user_id,
    n.type,
    n.title,
    n.message,
    n.is_read,
    n.resource_type,
    n.resource_id,
    n.action_url,
    n.created_at,
    CASE
        WHEN n.created_at > now() - INTERVAL '1 minute' THEN 'just now'
        WHEN n.created_at > now() - INTERVAL '1 hour' THEN
            EXTRACT(MINUTE FROM now() - n.created_at)::TEXT || 'm ago'
        WHEN n.created_at > now() - INTERVAL '1 day' THEN
            EXTRACT(HOUR FROM now() - n.created_at)::TEXT || 'h ago'
        ELSE to_char(n.created_at, 'Mon DD')
    END AS time_ago
FROM notifications n
ORDER BY n.created_at DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_org_subscription
-- ─────────────────────────────────────────────────────────────────────────────
-- Organization's current subscription with plan details and feature limits.
--
-- USAGE: SELECT * FROM v_org_subscription WHERE organization_id = $org_id;
--
-- JOINS:
--   organizations → subscriptions (active) → plans → plan_features
--   subscriptions → promotions (optional)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_org_subscription AS
SELECT
    o.id AS organization_id,
    o.name AS organization_name,
    s.id AS subscription_id,
    s.status AS subscription_status,
    s.billing_period,
    s.current_period_start,
    s.current_period_end,
    s.trial_ends_at,
    s.cancel_at_period_end,
    p.id AS plan_id,
    p.slug AS plan_slug,
    p.name AS plan_name,
    p.price_monthly,
    p.price_yearly,
    p.currency,
    pr.code AS promo_code,
    pr.discount_type AS promo_discount_type,
    pr.discount_value AS promo_discount_value,
    COALESCE(
        json_agg(DISTINCT jsonb_build_object(
            'feature_key', pf.feature_key,
            'limit_value', pf.limit_value,
            'description', pf.description
        )) FILTER (WHERE pf.id IS NOT NULL),
        '[]'::json
    ) AS features
FROM organizations o
LEFT JOIN subscriptions s ON s.organization_id = o.id
    AND s.status IN ('trialing','active','past_due')
LEFT JOIN plans p ON p.id = s.plan_id
LEFT JOIN plan_features pf ON pf.plan_id = p.id
LEFT JOIN promotions pr ON pr.id = s.promotion_id
GROUP BY o.id, s.id, p.id, pr.code, pr.discount_type, pr.discount_value;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_org_usage_summary
-- ─────────────────────────────────────────────────────────────────────────────
-- Organization usage vs plan limits for quota enforcement.
--
-- USAGE: SELECT * FROM v_org_usage_summary WHERE organization_id = $org_id;
--
-- JOINS:
--   organizations → usage_records → usage_meters
--   organizations → subscriptions → plans → plan_features (for limits)
--
-- NOTES:
--   Compares current usage (SUM this billing period) against plan limits.
--   Returns NULL plan_limit when unlimited.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_org_usage_summary AS
SELECT
    ur_agg.organization_id,
    um.slug AS meter_slug,
    um.name AS meter_name,
    um.unit,
    um.aggregation,
    ur_agg.current_usage,
    pf.limit_value AS plan_limit,
    CASE
        WHEN pf.limit_value IS NULL THEN 'unlimited'
        WHEN ur_agg.current_usage >= pf.limit_value THEN 'exceeded'
        WHEN ur_agg.current_usage >= pf.limit_value * 0.8 THEN 'warning'
        ELSE 'ok'
    END AS quota_status
FROM (
    SELECT
        ur.organization_id,
        ur.meter_id,
        CASE
            WHEN um2.aggregation = 'gauge' THEN (
                SELECT ur2.quantity FROM usage_records ur2
                WHERE ur2.organization_id = ur.organization_id
                  AND ur2.meter_id = ur.meter_id
                ORDER BY ur2.recorded_at DESC LIMIT 1
            )
            WHEN um2.aggregation = 'maximum' THEN MAX(ur.quantity)
            ELSE SUM(ur.quantity)
        END AS current_usage
    FROM usage_records ur
    JOIN usage_meters um2 ON um2.id = ur.meter_id
    JOIN subscriptions s ON s.organization_id = ur.organization_id
        AND s.status IN ('trialing','active')
    WHERE ur.recorded_at >= s.current_period_start
    GROUP BY ur.organization_id, ur.meter_id, um2.aggregation
) ur_agg
JOIN usage_meters um ON um.id = ur_agg.meter_id
LEFT JOIN subscriptions s ON s.organization_id = ur_agg.organization_id
    AND s.status IN ('trialing','active')
LEFT JOIN plan_features pf ON pf.plan_id = s.plan_id
    AND pf.feature_key = um.slug;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_billing_overview
-- ─────────────────────────────────────────────────────────────────────────────
-- Recent invoices and payment status for an organization.
--
-- USAGE: SELECT * FROM v_billing_overview WHERE organization_id = $org_id;
--
-- JOINS:
--   invoices → payments (latest status)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_billing_overview AS
SELECT
    i.organization_id,
    i.id AS invoice_id,
    i.invoice_number,
    i.status AS invoice_status,
    i.subtotal_amount,
    i.discount_amount,
    i.tax_amount,
    i.total_amount,
    i.currency,
    i.period_start,
    i.period_end,
    i.due_date,
    i.paid_at,
    (SELECT p.status FROM payments p
     WHERE p.invoice_id = i.id ORDER BY p.created_at DESC LIMIT 1
    ) AS last_payment_status,
    (SELECT COUNT(*) FROM payments p WHERE p.invoice_id = i.id) AS payment_attempts
FROM invoices i
ORDER BY i.created_at DESC;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_database_connection_status
-- ─────────────────────────────────────────────────────────────────────────────
-- Database connection health summary with sync channel counts.
--
-- USAGE: SELECT * FROM v_database_connection_status WHERE organization_id = $org_id;
--
-- JOINS:
--   database_connections → sync_channels (count + active count)
--   database_connections → provisioned_databases (optional)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_database_connection_status AS
SELECT
    dc.id AS connection_id,
    dc.name,
    dc.slug,
    dc.connection_type,
    dc.engine,
    dc.health_status,
    dc.is_active,
    dc.is_readonly,
    dc.organization_id,
    dc.project_id,
    dc.last_health_check,
    dc.schema_cached_at,
    pd.provider AS managed_provider,
    pd.tier AS managed_tier,
    pd.status AS managed_status,
    pd.region AS managed_region,
    COUNT(sc.id) AS sync_channel_count,
    COUNT(sc.id) FILTER (WHERE sc.status = 'active' AND sc.is_active = TRUE) AS active_sync_channels,
    COUNT(sc.id) FILTER (WHERE sc.status = 'error') AS error_sync_channels
FROM database_connections dc
LEFT JOIN provisioned_databases pd ON pd.id = dc.provisioned_db_id
LEFT JOIN sync_channels sc ON sc.connection_id = dc.id
GROUP BY dc.id, pd.provider, pd.tier, pd.status, pd.region;

-- ─────────────────────────────────────────────────────────────────────────────
-- v_sync_channel_overview
-- ─────────────────────────────────────────────────────────────────────────────
-- Sync channel status with connection and collection context.
--
-- USAGE: SELECT * FROM v_sync_channel_overview WHERE connection_id = $conn_id;
--
-- JOINS:
--   sync_channels → database_connections → organizations
--   sync_channels → collections
--   sync_channels → sync_executions (latest)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE VIEW v_sync_channel_overview AS
SELECT
    sc.id AS channel_id,
    sc.source_schema,
    sc.source_path,
    sc.sync_mode,
    sc.sync_direction,
    sc.conflict_strategy,
    sc.status,
    sc.is_active,
    sc.last_sync_at,
    sc.consecutive_errors,
    sc.last_error,
    dc.id AS connection_id,
    dc.name AS connection_name,
    dc.engine,
    dc.connection_type,
    dc.organization_id,
    c.id AS collection_id,
    c.name AS collection_name,
    c.slug AS collection_slug,
    (SELECT se.status FROM sync_executions se
     WHERE se.channel_id = sc.id ORDER BY se.created_at DESC LIMIT 1
    ) AS last_execution_status,
    (SELECT se.completed_at FROM sync_executions se
     WHERE se.channel_id = sc.id ORDER BY se.created_at DESC LIMIT 1
    ) AS last_execution_at,
    (SELECT SUM(se.records_conflicted) FROM sync_executions se
     WHERE se.channel_id = sc.id
       AND se.created_at > now() - INTERVAL '24 hours'
    ) AS conflicts_24h
FROM sync_channels sc
JOIN database_connections dc ON dc.id = sc.connection_id
JOIN collections c ON c.id = sc.collection_id;
