-- ============================================================================
-- triggers.dashboard.sql — Triggers for Dashboards, Views, Templates
-- ============================================================================
--
-- DOMAIN: Automates presentation layer defaults and integrity.
--
-- TRIGGERS:
--   1. fn_enforce_single_default_dashboard — One default per workspace
--   2. fn_enforce_single_default_view      — One default per collection
--   3. fn_validate_locked_dashboard        — Prevent edits on locked dashboards
--   4. fn_validate_locked_view             — Prevent edits on locked views
--
-- EXECUTION ORDER: Run AFTER triggers.utility.sql.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_enforce_single_default_dashboard()
-- ─────────────────────────────────────────────────────────────────────────────
-- Ensures only ONE dashboard per workspace has is_default = TRUE.
-- When a dashboard is set as default, the previous default is demoted.
--
-- FIRES: BEFORE INSERT OR UPDATE ON dashboards (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_enforce_single_default_dashboard()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.is_default = TRUE THEN
        UPDATE dashboards
           SET is_default = FALSE
         WHERE workspace_id = NEW.workspace_id
           AND is_default = TRUE
           AND id <> NEW.id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_dashboards_enforce_single_default
    BEFORE INSERT OR UPDATE OF is_default ON dashboards
    FOR EACH ROW
    WHEN (NEW.is_default = TRUE)
    EXECUTE FUNCTION fn_enforce_single_default_dashboard();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_enforce_single_default_view()
-- ─────────────────────────────────────────────────────────────────────────────
-- Ensures only ONE view per collection has is_default = TRUE.
-- When a view is set as default, the previous default is demoted.
--
-- FIRES: BEFORE INSERT OR UPDATE ON views (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_enforce_single_default_view()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.is_default = TRUE THEN
        UPDATE views
           SET is_default = FALSE
         WHERE collection_id = NEW.collection_id
           AND is_default = TRUE
           AND id <> NEW.id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_views_enforce_single_default
    BEFORE INSERT OR UPDATE OF is_default ON views
    FOR EACH ROW
    WHEN (NEW.is_default = TRUE)
    EXECUTE FUNCTION fn_enforce_single_default_view();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_validate_locked_entity()
-- ─────────────────────────────────────────────────────────────────────────────
-- Prevents content edits on locked dashboards and views. Only the
-- is_locked flag itself and updated_by/updated_at can change on a
-- locked entity (to allow unlocking).
--
-- FIRES: BEFORE UPDATE ON dashboards / views (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_validate_locked_entity()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF OLD.is_locked = TRUE AND NEW.is_locked = TRUE THEN
        -- Allow only metadata-level changes when locked
        IF NEW.name        IS DISTINCT FROM OLD.name
        OR NEW.slug        IS DISTINCT FROM OLD.slug
        OR NEW.description IS DISTINCT FROM OLD.description
        OR NEW.visibility  IS DISTINCT FROM OLD.visibility THEN
            RAISE EXCEPTION 'Cannot modify locked %: unlock first', TG_TABLE_NAME;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_dashboards_validate_locked
    BEFORE UPDATE ON dashboards
    FOR EACH ROW EXECUTE FUNCTION fn_validate_locked_entity();

CREATE TRIGGER trg_views_validate_locked
    BEFORE UPDATE ON views
    FOR EACH ROW EXECUTE FUNCTION fn_validate_locked_entity();
