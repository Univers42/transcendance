-- ============================================================================
-- triggers.utility.sql — Shared Trigger Functions & Universal Bindings
-- ============================================================================
--
-- DOMAIN: Reusable trigger functions applied across ALL schema domains.
--
-- DESIGN PRINCIPLES:
--   • One function, many bindings — write once, attach to every table
--   • SECURITY DEFINER: runs with the privileges of the function owner
--   • STRICT immutability: system-protected rows cannot be modified
--   • All functions are idempotent (CREATE OR REPLACE)
--
-- EXECUTION ORDER: Run AFTER all schema files, BEFORE domain-specific triggers.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_set_updated_at()
-- ─────────────────────────────────────────────────────────────────────────────
-- Automatically sets the `updated_at` column to now() on every UPDATE.
-- Skips the write if no actual column values changed (prevents phantom updates).
--
-- ATTACHED TO: Every table that has an `updated_at` column.
-- FIRES: BEFORE UPDATE (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_set_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Skip if the row content is identical (no real change)
    IF NEW IS NOT DISTINCT FROM OLD THEN
        RETURN OLD;
    END IF;
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- BIND fn_set_updated_at TO ALL TABLES WITH updated_at
-- ─────────────────────────────────────────────────────────────────────────────
-- 24 tables across 9 schema files.
-- Naming: trg_{table}_set_updated_at
-- ─────────────────────────────────────────────────────────────────────────────

-- schema.user.sql
CREATE TRIGGER trg_users_set_updated_at
    BEFORE UPDATE ON users FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_roles_set_updated_at
    BEFORE UPDATE ON roles FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_contacts_set_updated_at
    BEFORE UPDATE ON contacts FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- schema.organization.sql
CREATE TRIGGER trg_organizations_set_updated_at
    BEFORE UPDATE ON organizations FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_projects_set_updated_at
    BEFORE UPDATE ON projects FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_workspaces_set_updated_at
    BEFORE UPDATE ON workspaces FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- schema.collection.sql
CREATE TRIGGER trg_collections_set_updated_at
    BEFORE UPDATE ON collections FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_fields_set_updated_at
    BEFORE UPDATE ON fields FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- schema.dashboard.sql
CREATE TRIGGER trg_dashboards_set_updated_at
    BEFORE UPDATE ON dashboards FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_views_set_updated_at
    BEFORE UPDATE ON views FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_dashboard_templates_set_updated_at
    BEFORE UPDATE ON dashboard_templates FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- schema.resource.sql
CREATE TRIGGER trg_resources_set_updated_at
    BEFORE UPDATE ON resources FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_comments_set_updated_at
    BEFORE UPDATE ON comments FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- schema.adapter.sql
CREATE TRIGGER trg_adapters_set_updated_at
    BEFORE UPDATE ON adapters FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_adapter_mappings_set_updated_at
    BEFORE UPDATE ON adapter_mappings FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- schema.system.sql
CREATE TRIGGER trg_webhooks_set_updated_at
    BEFORE UPDATE ON webhooks FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_policy_rules_set_updated_at
    BEFORE UPDATE ON policy_rules FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- schema.billing.sql
CREATE TRIGGER trg_plans_set_updated_at
    BEFORE UPDATE ON plans FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_promotions_set_updated_at
    BEFORE UPDATE ON promotions FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_subscriptions_set_updated_at
    BEFORE UPDATE ON subscriptions FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_invoices_set_updated_at
    BEFORE UPDATE ON invoices FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_payments_set_updated_at
    BEFORE UPDATE ON payments FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

-- schema.connectivity.sql
CREATE TRIGGER trg_provisioned_databases_set_updated_at
    BEFORE UPDATE ON provisioned_databases FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_database_connections_set_updated_at
    BEFORE UPDATE ON database_connections FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();

CREATE TRIGGER trg_sync_channels_set_updated_at
    BEFORE UPDATE ON sync_channels FOR EACH ROW EXECUTE FUNCTION fn_set_updated_at();
