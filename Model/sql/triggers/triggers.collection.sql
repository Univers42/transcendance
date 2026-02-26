-- ============================================================================
-- triggers.collection.sql — Triggers for Collections, Fields, Relations
-- ============================================================================
--
-- DOMAIN: Automates dynamic schema engine integrity and lifecycle.
--
-- TRIGGERS:
--   1. fn_enforce_single_primary_field  — One primary field per collection
--   2. fn_protect_system_collections    — Block modification of system collections
--   3. fn_protect_system_fields         — Block deletion of system fields
--   4. fn_auto_field_sort_order         — Auto-assign sort_order on new field
--   5. fn_cascade_collection_updated_at — Bubble field changes to parent collection
--
-- EXECUTION ORDER: Run AFTER triggers.utility.sql.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_enforce_single_primary_field()
-- ─────────────────────────────────────────────────────────────────────────────
-- Ensures that each collection has at most ONE primary display field
-- (is_primary = TRUE). If a new field is set as primary, the previous
-- primary field is automatically demoted.
--
-- FIRES: BEFORE INSERT OR UPDATE ON fields (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_enforce_single_primary_field()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.is_primary = TRUE THEN
        UPDATE fields
           SET is_primary = FALSE
         WHERE collection_id = NEW.collection_id
           AND is_primary = TRUE
           AND id <> NEW.id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_fields_enforce_single_primary
    BEFORE INSERT OR UPDATE OF is_primary ON fields
    FOR EACH ROW
    WHEN (NEW.is_primary = TRUE)
    EXECUTE FUNCTION fn_enforce_single_primary_field();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_protect_system_collections()
-- ─────────────────────────────────────────────────────────────────────────────
-- Prevents deletion or critical modification of system collections
-- (is_system = TRUE). System collections are platform-internal.
--
-- FIRES: BEFORE UPDATE OR DELETE ON collections (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_protect_system_collections()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF OLD.is_system = TRUE THEN
            RAISE EXCEPTION 'Cannot delete system collection: %', OLD.name;
        END IF;
        RETURN OLD;
    END IF;

    IF OLD.is_system = TRUE AND NEW.is_system IS DISTINCT FROM OLD.is_system THEN
        RAISE EXCEPTION 'Cannot change is_system flag on system collection: %', OLD.name;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_collections_protect_system
    BEFORE UPDATE OR DELETE ON collections
    FOR EACH ROW EXECUTE FUNCTION fn_protect_system_collections();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_protect_system_fields()
-- ─────────────────────────────────────────────────────────────────────────────
-- Prevents deletion or type modification of system-managed fields
-- (is_system = TRUE), such as created_at, updated_at, created_by.
--
-- FIRES: BEFORE UPDATE OR DELETE ON fields (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_protect_system_fields()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'DELETE' AND OLD.is_system = TRUE THEN
        RAISE EXCEPTION 'Cannot delete system field: %.%', OLD.collection_id, OLD.slug;
    END IF;

    IF TG_OP = 'UPDATE' AND OLD.is_system = TRUE THEN
        IF NEW.field_type IS DISTINCT FROM OLD.field_type
        OR NEW.slug       IS DISTINCT FROM OLD.slug
        OR NEW.is_system  IS DISTINCT FROM OLD.is_system THEN
            RAISE EXCEPTION 'Cannot modify type/slug/is_system on system field: %', OLD.slug;
        END IF;
    END IF;
    RETURN COALESCE(NEW, OLD);
END;
$$;

CREATE TRIGGER trg_fields_protect_system
    BEFORE UPDATE OR DELETE ON fields
    FOR EACH ROW EXECUTE FUNCTION fn_protect_system_fields();
