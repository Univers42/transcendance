-- ============================================================================
-- triggers.user.sql — Triggers for Users, Auth, RBAC & Sessions
-- ============================================================================
--
-- DOMAIN: Automates identity and access control lifecycle events.
--
-- TRIGGERS:
--   1. fn_users_set_last_login     — Set last_login_at when a session is created
--   2. fn_protect_system_roles     — Prevent DELETE/UPDATE on system roles
--   3. fn_validate_role_assignment — Ensure role.scope matches context_type
--   4. fn_expire_sessions          — Deactivate sessions past expires_at
--
-- EXECUTION ORDER: Run AFTER triggers.utility.sql.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_users_set_last_login()
-- ─────────────────────────────────────────────────────────────────────────────
-- When a new session is inserted, updates the user's last_login_at timestamp.
-- This keeps users.last_login_at always reflecting the latest login event
-- without requiring application-level coordination.
--
-- FIRES: AFTER INSERT ON user_sessions (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_users_set_last_login()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    UPDATE users
       SET last_login_at = NEW.created_at,
           last_seen_at  = NEW.created_at
     WHERE id = NEW.user_id;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sessions_update_user_last_login
    AFTER INSERT ON user_sessions
    FOR EACH ROW EXECUTE FUNCTION fn_users_set_last_login();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_protect_system_roles()
-- ─────────────────────────────────────────────────────────────────────────────
-- Prevents deletion or critical modification of system-seeded roles
-- (is_system = TRUE). System roles are immutable platform constants.
-- Allowed: updating description only.
--
-- FIRES: BEFORE UPDATE OR DELETE ON roles (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_protect_system_roles()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF TG_OP = 'DELETE' THEN
        IF OLD.is_system = TRUE THEN
            RAISE EXCEPTION 'Cannot delete system role: %', OLD.name;
        END IF;
        RETURN OLD;
    END IF;

    -- UPDATE: block changes to name, scope, is_system on system roles
    IF OLD.is_system = TRUE THEN
        IF NEW.name       IS DISTINCT FROM OLD.name
        OR NEW.scope      IS DISTINCT FROM OLD.scope
        OR NEW.is_system  IS DISTINCT FROM OLD.is_system THEN
            RAISE EXCEPTION 'Cannot modify name/scope/is_system on system role: %', OLD.name;
        END IF;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_roles_protect_system
    BEFORE UPDATE OR DELETE ON roles
    FOR EACH ROW EXECUTE FUNCTION fn_protect_system_roles();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_validate_role_assignment()
-- ─────────────────────────────────────────────────────────────────────────────
-- Ensures that the role's scope matches the assignment's context_type.
-- A workspace-scoped role cannot be assigned with context_type = 'organization'.
--
-- FIRES: BEFORE INSERT OR UPDATE ON user_role_assignments (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_validate_role_assignment()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_role_scope VARCHAR(20);
BEGIN
    SELECT scope INTO v_role_scope FROM roles WHERE id = NEW.role_id;

    IF v_role_scope IS NULL THEN
        RAISE EXCEPTION 'Role % does not exist', NEW.role_id;
    END IF;

    IF v_role_scope <> NEW.context_type THEN
        RAISE EXCEPTION 'Role scope (%) does not match context_type (%)',
            v_role_scope, NEW.context_type;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_ura_validate_scope
    BEFORE INSERT OR UPDATE ON user_role_assignments
    FOR EACH ROW EXECUTE FUNCTION fn_validate_role_assignment();
