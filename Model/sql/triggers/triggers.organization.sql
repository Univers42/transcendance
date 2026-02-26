-- ============================================================================
-- triggers.organization.sql — Triggers for Organizations, Projects, Workspaces
-- ============================================================================
--
-- DOMAIN: Automates multi-tenant hierarchy lifecycle events.
--
-- TRIGGERS:
--   1. fn_org_auto_add_creator_as_member — Creator becomes first member
--   2. fn_org_deactivate_cascade         — Soft-delete cascades to projects
--   3. fn_validate_slug_format           — Enforce URL-safe slug format
--
-- EXECUTION ORDER: Run AFTER triggers.utility.sql.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_org_auto_add_creator_as_member()
-- ─────────────────────────────────────────────────────────────────────────────
-- When a new organization is created, automatically inserts the creator
-- as the first organization_member. The application layer is still
-- responsible for assigning the 'org_owner' role via user_role_assignments.
--
-- This ensures membership consistency — every org always has at least
-- one member from the moment it is created.
--
-- FIRES: AFTER INSERT ON organizations (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_org_auto_add_creator_as_member()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    INSERT INTO organization_members (organization_id, user_id, invited_by, joined_at)
    VALUES (NEW.id, NEW.created_by, NEW.created_by, now())
    ON CONFLICT (organization_id, user_id) DO NOTHING;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_organizations_auto_add_creator
    AFTER INSERT ON organizations
    FOR EACH ROW EXECUTE FUNCTION fn_org_auto_add_creator_as_member();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_org_deactivate_cascade()
-- ─────────────────────────────────────────────────────────────────────────────
-- When an organization is soft-deleted (is_active set to FALSE), cascades
-- the deactivation to all child projects by archiving them.
-- This prevents orphaned active projects under a deactivated org.
--
-- FIRES: AFTER UPDATE ON organizations (row-level)
-- CONDITION: WHEN (OLD.is_active = TRUE AND NEW.is_active = FALSE)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_org_deactivate_cascade()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE projects
       SET is_archived = TRUE,
           updated_by  = NEW.updated_by
     WHERE organization_id = NEW.id
       AND is_archived = FALSE;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_organizations_deactivate_cascade
    AFTER UPDATE ON organizations
    FOR EACH ROW
    WHEN (OLD.is_active = TRUE AND NEW.is_active = FALSE)
    EXECUTE FUNCTION fn_org_deactivate_cascade();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_validate_slug_format()
-- ─────────────────────────────────────────────────────────────────────────────
-- Enforces that slug columns contain only URL-safe characters:
-- lowercase letters, digits, and hyphens. No leading/trailing hyphens.
-- Applied to organizations, projects, and workspaces.
--
-- FIRES: BEFORE INSERT OR UPDATE ON organizations/projects/workspaces (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_validate_slug_format()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.slug !~ '^[a-z0-9]([a-z0-9-]*[a-z0-9])?$' THEN
        RAISE EXCEPTION 'Invalid slug "%": must be lowercase alphanumeric with hyphens, no leading/trailing hyphens',
            NEW.slug;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_organizations_validate_slug
    BEFORE INSERT OR UPDATE OF slug ON organizations
    FOR EACH ROW EXECUTE FUNCTION fn_validate_slug_format();

CREATE TRIGGER trg_projects_validate_slug
    BEFORE INSERT OR UPDATE OF slug ON projects
    FOR EACH ROW EXECUTE FUNCTION fn_validate_slug_format();

CREATE TRIGGER trg_workspaces_validate_slug
    BEFORE INSERT OR UPDATE OF slug ON workspaces
    FOR EACH ROW EXECUTE FUNCTION fn_validate_slug_format();
