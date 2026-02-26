-- ============================================================================
-- triggers.abac.sql — Triggers for the Enhanced ABAC Engine
-- ============================================================================
--
-- DOMAIN: Enforcement, validation, and bookkeeping for ABAC tables.
--
-- TRIGGERS:
--   1. fn_abac_prevent_circular_groups — Block circular group nesting
--   2. fn_abac_validate_temporal       — Ensure starts_at < expires_at
--   3. fn_abac_rules_updated_at        — Stamp updated_at on rule change
--   4. fn_abac_groups_updated_at       — Stamp updated_at on group change
--   5. fn_abac_policies_updated_at     — Stamp updated_at on policy change
--   6. fn_abac_policy_version_bump     — Increment version on policy update
--   7. fn_abac_protect_system_records  — Prevent deletion of is_system rows
--   8. fn_abac_attrdef_updated_at      — Stamp updated_at on attr def change
--
-- EXECUTION ORDER: Run AFTER triggers.system.sql.
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- fn_abac_prevent_circular_groups()
-- ─────────────────────────────────────────────────────────────────────────────
-- Prevents circular references when nesting rule groups.
-- Uses a recursive CTE to walk the descendant tree of the proposed child
-- group and checks whether any descendant leads back to the parent group.
--
-- Example:
--   Group A → Group B → Group C
--   INSERT (group_id=C, child_group_id=A) ← would create A→B→C→A cycle
--   This trigger detects and blocks it.
--
-- FIRES: BEFORE INSERT OR UPDATE ON abac_rule_group_members (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_abac_prevent_circular_groups()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Only relevant when inserting/updating a child-group reference
    IF NEW.child_group_id IS NULL THEN
        RETURN NEW;
    END IF;

    -- Direct self-reference is already blocked by CHECK constraint,
    -- but double-check for safety
    IF NEW.group_id = NEW.child_group_id THEN
        RAISE EXCEPTION 'A rule group cannot contain itself (group_id = %)', NEW.group_id;
    END IF;

    -- Recursive descent: starting from child_group_id, walk all descendants.
    -- If we ever reach group_id, there's a cycle.
    IF EXISTS (
        WITH RECURSIVE descendants AS (
            -- Seed: direct children of the proposed child group
            SELECT child_group_id AS descendant_id
              FROM abac_rule_group_members
             WHERE group_id = NEW.child_group_id
               AND child_group_id IS NOT NULL

            UNION ALL

            -- Recurse: children of children
            SELECT rgm.child_group_id
              FROM abac_rule_group_members rgm
              JOIN descendants d ON d.descendant_id = rgm.group_id
             WHERE rgm.child_group_id IS NOT NULL
        )
        SELECT 1
          FROM descendants
         WHERE descendant_id = NEW.group_id
    ) THEN
        RAISE EXCEPTION
            'Circular group reference detected: group % is already a '
            'descendant of group %, adding it as a child would create a cycle',
            NEW.group_id, NEW.child_group_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_abac_rgm_prevent_circular
    BEFORE INSERT OR UPDATE ON abac_rule_group_members
    FOR EACH ROW EXECUTE FUNCTION fn_abac_prevent_circular_groups();


-- ─────────────────────────────────────────────────────────────────────────────
-- fn_abac_validate_temporal()
-- ─────────────────────────────────────────────────────────────────────────────
-- Ensures starts_at < expires_at whenever both are set, on any table that
-- has these temporal columns (abac_rules, abac_policy_assignments).
--
-- FIRES: BEFORE INSERT OR UPDATE ON abac_rules, abac_policy_assignments
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_abac_validate_temporal()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.starts_at IS NOT NULL
       AND NEW.expires_at IS NOT NULL
       AND NEW.starts_at >= NEW.expires_at
    THEN
        RAISE EXCEPTION
            'starts_at (%) must be strictly before expires_at (%)',
            NEW.starts_at, NEW.expires_at;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_abac_rules_validate_temporal
    BEFORE INSERT OR UPDATE ON abac_rules
    FOR EACH ROW EXECUTE FUNCTION fn_abac_validate_temporal();

CREATE TRIGGER trg_abac_pa_validate_temporal
    BEFORE INSERT OR UPDATE ON abac_policy_assignments
    FOR EACH ROW EXECUTE FUNCTION fn_abac_validate_temporal();


-- ─────────────────────────────────────────────────────────────────────────────
-- fn_abac_rules_updated_at()
-- ─────────────────────────────────────────────────────────────────────────────
-- Stamps updated_at = now() on every UPDATE to abac_rules.
--
-- FIRES: BEFORE UPDATE ON abac_rules (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_abac_rules_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_abac_rules_updated_at
    BEFORE UPDATE ON abac_rules
    FOR EACH ROW EXECUTE FUNCTION fn_abac_rules_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- fn_abac_groups_updated_at()
-- ─────────────────────────────────────────────────────────────────────────────
-- Stamps updated_at = now() on every UPDATE to abac_rule_groups.
--
-- FIRES: BEFORE UPDATE ON abac_rule_groups (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_abac_groups_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_abac_rule_groups_updated_at
    BEFORE UPDATE ON abac_rule_groups
    FOR EACH ROW EXECUTE FUNCTION fn_abac_groups_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- fn_abac_policies_updated_at()
-- ─────────────────────────────────────────────────────────────────────────────
-- Stamps updated_at = now() on every UPDATE to abac_policies.
--
-- FIRES: BEFORE UPDATE ON abac_policies (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_abac_policies_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_abac_policies_updated_at
    BEFORE UPDATE ON abac_policies
    FOR EACH ROW EXECUTE FUNCTION fn_abac_policies_updated_at();


-- ─────────────────────────────────────────────────────────────────────────────
-- fn_abac_policy_version_bump()
-- ─────────────────────────────────────────────────────────────────────────────
-- Auto-increments abac_policies.version on every UPDATE, enabling optimistic
-- concurrency control in the application layer.
--
-- FIRES: BEFORE UPDATE ON abac_policies (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_abac_policy_version_bump()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.version := OLD.version + 1;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_abac_policies_version_bump
    BEFORE UPDATE ON abac_policies
    FOR EACH ROW EXECUTE FUNCTION fn_abac_policy_version_bump();


-- ─────────────────────────────────────────────────────────────────────────────
-- fn_abac_protect_system_records()
-- ─────────────────────────────────────────────────────────────────────────────
-- Prevents deletion of rows where is_system = TRUE on:
--   • abac_attribute_definitions
--   • abac_rule_groups
--   • abac_policies
--
-- System records are platform-managed and must not be removed by tenants.
--
-- FIRES: BEFORE DELETE ON abac_attribute_definitions,
--                        abac_rule_groups,
--                        abac_policies   (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_abac_protect_system_records()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF OLD.is_system = TRUE THEN
        RAISE EXCEPTION
            'Cannot delete system-managed % record: % (%)',
            TG_TABLE_NAME, OLD.name, OLD.id;
    END IF;
    RETURN OLD;
END;
$$;

CREATE TRIGGER trg_abac_attrdef_protect_system
    BEFORE DELETE ON abac_attribute_definitions
    FOR EACH ROW EXECUTE FUNCTION fn_abac_protect_system_records();

CREATE TRIGGER trg_abac_rule_groups_protect_system
    BEFORE DELETE ON abac_rule_groups
    FOR EACH ROW EXECUTE FUNCTION fn_abac_protect_system_records();

CREATE TRIGGER trg_abac_policies_protect_system
    BEFORE DELETE ON abac_policies
    FOR EACH ROW EXECUTE FUNCTION fn_abac_protect_system_records();


-- ─────────────────────────────────────────────────────────────────────────────
-- fn_abac_attrdef_updated_at()
-- ─────────────────────────────────────────────────────────────────────────────
-- Stamps updated_at = now() on every UPDATE to abac_attribute_definitions.
--
-- FIRES: BEFORE UPDATE ON abac_attribute_definitions (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_abac_attrdef_updated_at()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    NEW.updated_at := now();
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_abac_attrdef_updated_at
    BEFORE UPDATE ON abac_attribute_definitions
    FOR EACH ROW EXECUTE FUNCTION fn_abac_attrdef_updated_at();
