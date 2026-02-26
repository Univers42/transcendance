-- ============================================================================
-- triggers.system.sql — Triggers for Webhooks, Notifications, Policies, Files
-- ============================================================================
--
-- DOMAIN: Automates platform-level system service bookkeeping.
--
-- TRIGGERS:
--   1. fn_webhook_delivery_propagate — Update webhook last_triggered/status
--   2. fn_notification_mark_read_at  — Stamp read timestamp on notifications
--   3. fn_policy_rule_validate_json  — Ensure policy conditions is valid ABAC
--   4. fn_file_upload_validate_size  — Enforce maximum file size
--
-- EXECUTION ORDER: Run AFTER triggers.utility.sql.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_webhook_delivery_propagate()
-- ─────────────────────────────────────────────────────────────────────────────
-- When a webhook_delivery is logged, propagates the delivery result back
-- to webhooks.last_triggered_at and webhooks.last_status for fast health
-- monitoring without joining the deliveries table.
--
-- FIRES: AFTER INSERT ON webhook_deliveries (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_webhook_delivery_propagate()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_status VARCHAR(20);
BEGIN
    v_status := CASE
        WHEN NEW.response_status IS NULL              THEN 'timeout'
        WHEN NEW.response_status BETWEEN 200 AND 299  THEN 'success'
        WHEN NEW.response_status BETWEEN 400 AND 499  THEN 'client_error'
        WHEN NEW.response_status >= 500                THEN 'server_error'
        ELSE 'unknown'
    END;

    UPDATE webhooks
       SET last_triggered_at = NEW.delivered_at,
           last_status       = v_status
     WHERE id = NEW.webhook_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_webhook_deliveries_propagate
    AFTER INSERT ON webhook_deliveries
    FOR EACH ROW EXECUTE FUNCTION fn_webhook_delivery_propagate();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_policy_rule_validate_json()
-- ─────────────────────────────────────────────────────────────────────────────
-- Validates that policy_rules.conditions contains a properly structured
-- ABAC expression tree. Must have at least one top-level key ('and', 'or',
-- or 'attr') to be evaluable at runtime.
--
-- FIRES: BEFORE INSERT OR UPDATE ON policy_rules (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_policy_rule_validate_json()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.conditions IS NULL OR NEW.conditions = '{}'::JSONB THEN
        RAISE EXCEPTION 'policy_rules.conditions cannot be empty';
    END IF;

    -- Must have at least one evaluable root key
    IF NOT (
        NEW.conditions ? 'and'
        OR NEW.conditions ? 'or'
        OR NEW.conditions ? 'attr'
    ) THEN
        RAISE EXCEPTION 'policy_rules.conditions must have root key: and, or, or attr';
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_policy_rules_validate_conditions
    BEFORE INSERT OR UPDATE OF conditions ON policy_rules
    FOR EACH ROW EXECUTE FUNCTION fn_policy_rule_validate_json();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_file_upload_validate_size()
-- ─────────────────────────────────────────────────────────────────────────────
-- Enforces a maximum file size guard at the database level. This is a
-- defense-in-depth measure; the primary size check happens in the API
-- layer. Maximum: 500 MB (524288000 bytes).
--
-- FIRES: BEFORE INSERT ON file_uploads (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_file_upload_validate_size()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.size_bytes <= 0 THEN
        RAISE EXCEPTION 'File size must be positive, got: %', NEW.size_bytes;
    END IF;
    IF NEW.size_bytes > 524288000 THEN -- 500 MB
        RAISE EXCEPTION 'File exceeds maximum size (500 MB): % bytes', NEW.size_bytes;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_file_uploads_validate_size
    BEFORE INSERT ON file_uploads
    FOR EACH ROW EXECUTE FUNCTION fn_file_upload_validate_size();
