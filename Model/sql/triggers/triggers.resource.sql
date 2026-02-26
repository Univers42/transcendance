-- ============================================================================
-- triggers.resource.sql — Triggers for Resource Registry, Versions, Shares
-- ============================================================================
--
-- DOMAIN: Automates polymorphic resource lifecycle — versioning, share
-- counters, and self-referential relation safeguards.
--
-- TRIGGERS:
--   1. fn_auto_version_number       — Auto-increment version_number per resource
--   2. fn_increment_share_use_count — Track share link usage
--   3. fn_prevent_self_relation     — Block resource self-references
--   4. fn_validate_share_limits     — Enforce max_uses on resource_shares
--
-- EXECUTION ORDER: Run AFTER triggers.utility.sql.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_auto_version_number()
-- ─────────────────────────────────────────────────────────────────────────────
-- Automatically assigns the next version_number for a resource when a new
-- version row is inserted. This avoids race conditions where two concurrent
-- inserts might pick the same version_number at the application level.
--
-- Uses an advisory lock keyed on the resource UUID to serialize versioning.
--
-- FIRES: BEFORE INSERT ON resource_versions (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_auto_version_number()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_max INT;
    v_lock_key BIGINT;
BEGIN
    -- Advisory lock keyed on resource UUID hash for concurrency safety
    v_lock_key := ('x' || left(replace(NEW.resource_id::text, '-', ''), 15))::bit(60)::bigint;
    PERFORM pg_advisory_xact_lock(v_lock_key);

    SELECT COALESCE(MAX(version_number), 0)
      INTO v_max
      FROM resource_versions
     WHERE resource_id = NEW.resource_id;

    NEW.version_number := v_max + 1;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_resource_versions_auto_number
    BEFORE INSERT ON resource_versions
    FOR EACH ROW EXECUTE FUNCTION fn_auto_version_number();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_prevent_self_relation()
-- ─────────────────────────────────────────────────────────────────────────────
-- Blocks a resource from relating to itself. Self-references create
-- infinite loops in dependency resolution and UI rendering.
--
-- FIRES: BEFORE INSERT OR UPDATE ON resource_relations (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_prevent_self_relation()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.source_resource_id = NEW.target_resource_id THEN
        RAISE EXCEPTION 'Resource cannot relate to itself: %', NEW.source_resource_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_resource_relations_no_self
    BEFORE INSERT OR UPDATE ON resource_relations
    FOR EACH ROW EXECUTE FUNCTION fn_prevent_self_relation();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_validate_share_limits()
-- ─────────────────────────────────────────────────────────────────────────────
-- When use_count is incremented on a resource_share, checks whether the
-- share has exceeded max_uses. If so, automatically deactivates the share.
-- Also prevents incrementing use_count on inactive shares.
--
-- FIRES: BEFORE UPDATE ON resource_shares (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_validate_share_limits()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Block usage on deactivated or expired shares
    IF OLD.is_active = FALSE THEN
        RAISE EXCEPTION 'Share link % is deactivated', OLD.id;
    END IF;
    IF OLD.expires_at IS NOT NULL AND OLD.expires_at < now() THEN
        NEW.is_active := FALSE;
        RETURN NEW;
    END IF;

    -- Auto-deactivate when max_uses reached
    IF NEW.use_count IS DISTINCT FROM OLD.use_count
       AND OLD.max_uses IS NOT NULL
       AND NEW.use_count >= OLD.max_uses THEN
        NEW.is_active := FALSE;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_resource_shares_validate_limits
    BEFORE UPDATE ON resource_shares
    FOR EACH ROW EXECUTE FUNCTION fn_validate_share_limits();
