-- ============================================================================
-- optimization.sql — Indexes for all SQL tables
-- ============================================================================
-- Run AFTER all schema files. Indexes are organized by domain.
-- Naming convention: idx_{table}_{columns}
--
-- INDEX STRATEGY:
--   • B-tree (default): equality and range queries
--   • Partial indexes (WHERE): reduce index size for common filter patterns
--   • Composite indexes: ordered by selectivity (most selective column first)
--   • Covering indexes: include all columns needed for frequent queries
--
-- NOTES:
--   • Primary keys and UNIQUE constraints already create indexes automatically
--   • These additional indexes target specific query patterns identified
--     in the views.sql and common API access patterns
-- ============================================================================

-- ── Users & Auth ────────────────────────────────────────────────────────────

CREATE INDEX idx_users_email              ON users (email);
CREATE INDEX idx_users_status             ON users (status) WHERE is_active = TRUE;
CREATE INDEX idx_users_last_seen          ON users (last_seen_at DESC NULLS LAST);

CREATE INDEX idx_oauth_accounts_user      ON oauth_accounts (user_id);
CREATE INDEX idx_oauth_accounts_provider  ON oauth_accounts (provider, provider_id);

-- user_role_assignments: critical for RBAC resolution
-- Replaces old per-membership-table role lookups with unified context queries
CREATE INDEX idx_ura_user                 ON user_role_assignments (user_id);
CREATE INDEX idx_ura_role                 ON user_role_assignments (role_id);
CREATE INDEX idx_ura_context              ON user_role_assignments (context_type, context_id)
    WHERE context_id IS NOT NULL;
CREATE INDEX IF NOT EXISTS idx_ura_user_context         ON user_role_assignments (user_id, context_type, context_id);
CREATE INDEX IF NOT EXISTS idx_ura_active               ON user_role_assignments (user_id, role_id, expires_at);

-- abac_conditions: evaluated during permission checks
CREATE INDEX idx_abac_conditions_permission ON abac_conditions (permission_id);
CREATE INDEX idx_abac_conditions_role       ON abac_conditions (role_id)
    WHERE role_id IS NOT NULL;
CREATE INDEX idx_abac_conditions_perm_role  ON abac_conditions (permission_id, role_id);

CREATE INDEX idx_user_permissions_user    ON user_permissions (user_id);
CREATE INDEX idx_user_permissions_deny    ON user_permissions (user_id, permission_id)
    WHERE granted = FALSE;

CREATE INDEX idx_user_sessions_user       ON user_sessions (user_id) WHERE is_active = TRUE;
CREATE INDEX idx_user_sessions_token      ON user_sessions (token_hash);
CREATE INDEX idx_user_sessions_expiry     ON user_sessions (expires_at) WHERE is_active = TRUE;

CREATE INDEX idx_contacts_user            ON contacts (user_id);

CREATE INDEX idx_api_keys_user            ON api_keys (user_id) WHERE is_active = TRUE;
CREATE INDEX idx_api_keys_hash            ON api_keys (key_hash);

-- ── Organizations ───────────────────────────────────────────────────────────

CREATE INDEX idx_organizations_slug       ON organizations (slug);
CREATE INDEX idx_organizations_active     ON organizations (id) WHERE is_active = TRUE;

CREATE INDEX idx_org_members_org          ON organization_members (organization_id);
CREATE INDEX idx_org_members_user         ON organization_members (user_id);

CREATE INDEX idx_projects_org             ON projects (organization_id);
CREATE INDEX idx_projects_slug            ON projects (organization_id, slug);
CREATE INDEX idx_projects_active          ON projects (organization_id) WHERE is_archived = FALSE;

CREATE INDEX idx_project_members_project  ON project_members (project_id);
CREATE INDEX idx_project_members_user     ON project_members (user_id);

CREATE INDEX idx_workspaces_project       ON workspaces (project_id);
CREATE INDEX idx_workspaces_slug          ON workspaces (project_id, slug);

CREATE INDEX idx_workspace_members_ws     ON workspace_members (workspace_id);
CREATE INDEX idx_workspace_members_user   ON workspace_members (user_id);

-- ── Collections & Fields ────────────────────────────────────────────────────

CREATE INDEX idx_collections_workspace    ON collections (workspace_id);
CREATE INDEX idx_collections_slug         ON collections (workspace_id, slug);

CREATE INDEX idx_fields_collection        ON fields (collection_id);
CREATE INDEX idx_fields_order             ON fields (collection_id, sort_order);
CREATE INDEX idx_fields_primary           ON fields (collection_id) WHERE is_primary = TRUE;
CREATE INDEX idx_fields_type              ON fields (collection_id, field_type);

CREATE INDEX idx_field_options_field      ON field_options (field_id, sort_order);

CREATE INDEX idx_collection_relations_source ON collection_relations (source_collection_id);
CREATE INDEX idx_collection_relations_target ON collection_relations (target_collection_id);

CREATE INDEX idx_collection_indices_coll  ON collection_indices (collection_id);

-- ── Dashboards & Views ──────────────────────────────────────────────────────

CREATE INDEX idx_dashboards_workspace     ON dashboards (workspace_id);
CREATE INDEX idx_dashboards_slug          ON dashboards (workspace_id, slug);
CREATE INDEX idx_dashboards_default       ON dashboards (workspace_id) WHERE is_default = TRUE;

CREATE INDEX idx_dashboard_perms_dash     ON dashboard_permissions (dashboard_id);
CREATE INDEX idx_dashboard_perms_grantee  ON dashboard_permissions (grantee_type, grantee_id);

CREATE INDEX idx_views_collection         ON views (collection_id);
CREATE INDEX idx_views_workspace          ON views (workspace_id);
CREATE INDEX idx_views_slug               ON views (collection_id, slug);
CREATE INDEX idx_views_default            ON views (collection_id) WHERE is_default = TRUE;

CREATE INDEX idx_view_perms_view          ON view_permissions (view_id);

CREATE INDEX idx_dashboard_templates_org  ON dashboard_templates (organization_id);
CREATE INDEX idx_dashboard_templates_public ON dashboard_templates (id) WHERE is_public = TRUE;

-- ── Resources ───────────────────────────────────────────────────────────────

CREATE INDEX idx_resources_org            ON resources (organization_id);
CREATE INDEX idx_resources_type_id        ON resources (resource_type, resource_id);
CREATE INDEX idx_resources_created_by     ON resources (created_by);

CREATE INDEX idx_resource_perms_resource  ON resource_permissions (resource_id);
CREATE INDEX idx_resource_perms_grantee   ON resource_permissions (grantee_type, grantee_id);

CREATE INDEX idx_resource_versions_res    ON resource_versions (resource_id, version_number DESC);

CREATE INDEX idx_resource_shares_token    ON resource_shares (share_token) WHERE is_active = TRUE;
CREATE INDEX idx_resource_shares_resource ON resource_shares (resource_id);

CREATE INDEX idx_resource_relations_source ON resource_relations (source_resource_id);
CREATE INDEX idx_resource_relations_target ON resource_relations (target_resource_id);

CREATE INDEX idx_tags_org                 ON tags (organization_id);

CREATE INDEX idx_comments_resource        ON comments (resource_id, created_at DESC);
CREATE INDEX idx_comments_user            ON comments (user_id);
CREATE INDEX idx_comments_thread          ON comments (parent_id) WHERE parent_id IS NOT NULL;

-- ── Adapters ────────────────────────────────────────────────────────────────

CREATE INDEX idx_adapters_org             ON adapters (organization_id);
CREATE INDEX idx_adapters_active          ON adapters (organization_id) WHERE is_active = TRUE;

CREATE INDEX idx_adapter_mappings_adapter ON adapter_mappings (adapter_id);
CREATE INDEX idx_adapter_mappings_coll    ON adapter_mappings (collection_id);

CREATE INDEX idx_adapter_executions_adapter ON adapter_executions (adapter_id, created_at DESC);
CREATE INDEX idx_adapter_executions_status  ON adapter_executions (status) WHERE status IN ('pending','running');

-- ── System ──────────────────────────────────────────────────────────────────

CREATE INDEX idx_webhooks_org             ON webhooks (organization_id) WHERE is_active = TRUE;

CREATE INDEX idx_webhook_deliveries_hook  ON webhook_deliveries (webhook_id, delivered_at DESC);

CREATE INDEX idx_notifications_user       ON notifications (user_id, is_read, created_at DESC);
CREATE INDEX idx_notifications_unread     ON notifications (user_id, created_at DESC) WHERE is_read = FALSE;

CREATE INDEX idx_policy_rules_org         ON policy_rules (organization_id) WHERE is_active = TRUE;
CREATE INDEX idx_policy_rules_resource    ON policy_rules (organization_id, resource_type, priority DESC);

CREATE INDEX idx_file_uploads_org         ON file_uploads (organization_id);
CREATE INDEX idx_file_uploads_user        ON file_uploads (uploaded_by);

-- ── Billing ─────────────────────────────────────────────────────────────────

CREATE INDEX idx_plans_slug               ON plans (slug);
CREATE INDEX idx_plans_active_public      ON plans (sort_order)
    WHERE is_active = TRUE AND is_public = TRUE;

CREATE INDEX idx_plan_features_plan       ON plan_features (plan_id);
CREATE INDEX idx_plan_features_key        ON plan_features (feature_key, plan_id);

CREATE INDEX idx_promotions_code          ON promotions (code);
CREATE INDEX IF NOT EXISTS idx_promotions_active        ON promotions (id)
    WHERE is_active = TRUE;

CREATE INDEX idx_subscriptions_org        ON subscriptions (organization_id);
CREATE INDEX idx_subscriptions_plan       ON subscriptions (plan_id);
CREATE INDEX idx_subscriptions_active     ON subscriptions (organization_id)
    WHERE status IN ('trialing','active');
CREATE INDEX idx_subscriptions_promo      ON subscriptions (promotion_id)
    WHERE promotion_id IS NOT NULL;

CREATE INDEX idx_invoices_org             ON invoices (organization_id, created_at DESC);
CREATE INDEX idx_invoices_sub             ON invoices (subscription_id);
CREATE INDEX idx_invoices_unpaid          ON invoices (organization_id)
    WHERE status IN ('pending','past_due');
CREATE INDEX idx_invoices_number          ON invoices (organization_id, invoice_number);

CREATE INDEX idx_payments_invoice         ON payments (invoice_id);
CREATE INDEX idx_payments_org             ON payments (organization_id, created_at DESC);
CREATE INDEX idx_payments_failed          ON payments (organization_id)
    WHERE status = 'failed';

CREATE INDEX idx_usage_meters_slug        ON usage_meters (slug);

CREATE INDEX idx_usage_records_org_meter  ON usage_records (organization_id, meter_id, recorded_at DESC);
CREATE INDEX idx_usage_records_recorded   ON usage_records (recorded_at DESC);
CREATE INDEX idx_usage_records_meter      ON usage_records (meter_id, recorded_at DESC);

-- ── Connectivity ────────────────────────────────────────────────────────────

CREATE INDEX idx_provisioned_dbs_org      ON provisioned_databases (organization_id);
CREATE INDEX idx_provisioned_dbs_active   ON provisioned_databases (organization_id)
    WHERE status = 'active';
CREATE INDEX idx_provisioned_dbs_provider ON provisioned_databases (provider, status);

CREATE INDEX idx_db_connections_org       ON database_connections (organization_id);
CREATE INDEX idx_db_connections_active    ON database_connections (organization_id)
    WHERE is_active = TRUE;
CREATE INDEX idx_db_connections_slug      ON database_connections (organization_id, slug);
CREATE INDEX idx_db_connections_type      ON database_connections (connection_type, engine);
CREATE INDEX idx_db_connections_health    ON database_connections (organization_id, health_status)
    WHERE is_active = TRUE;
CREATE INDEX idx_db_connections_provisioned ON database_connections (provisioned_db_id)
    WHERE provisioned_db_id IS NOT NULL;

CREATE INDEX idx_sync_channels_conn      ON sync_channels (connection_id);
CREATE INDEX idx_sync_channels_coll      ON sync_channels (collection_id);
CREATE INDEX idx_sync_channels_active    ON sync_channels (connection_id)
    WHERE status = 'active' AND is_active = TRUE;
CREATE INDEX idx_sync_channels_status    ON sync_channels (status)
    WHERE status IN ('active','error','initializing');

CREATE INDEX idx_sync_executions_channel ON sync_executions (channel_id, created_at DESC);
CREATE INDEX idx_sync_executions_status  ON sync_executions (status)
    WHERE status IN ('pending','running');
