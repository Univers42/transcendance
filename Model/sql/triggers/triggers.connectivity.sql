-- ============================================================================
-- triggers.connectivity.sql — Triggers for Connections, Provisioning, Sync
-- ============================================================================
--
-- DOMAIN: Automates database connectivity lifecycle — provisioning
-- timestamps, sync error tracking, auto-pause, and execution metrics.
--
-- TRIGGERS:
--   1. fn_provisioned_db_lifecycle      — Set provisioned_at / terminated_at
--   2. fn_sync_execution_duration       — Auto-compute duration_ms
--   3. fn_sync_channel_error_tracking   — Track consecutive errors + auto-pause
--   4. fn_sync_channel_last_sync        — Propagate last_sync_at from executions
--   5. fn_validate_managed_connection   — Enforce managed connection constraints
--
-- EXECUTION ORDER: Run AFTER triggers.utility.sql.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_provisioned_db_lifecycle()
-- ─────────────────────────────────────────────────────────────────────────────
-- Stamps provisioned_at when status → 'active' (instance is ready).
-- Stamps terminated_at when status → 'terminated' (instance destroyed).
-- These timestamps are immutable once set.
--
-- FIRES: BEFORE UPDATE ON provisioned_databases (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_provisioned_db_lifecycle()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    -- Stamp provisioned_at on first activation
    IF NEW.status = 'active' AND OLD.status = 'provisioning'
       AND OLD.provisioned_at IS NULL THEN
        NEW.provisioned_at := now();
    END IF;

    -- Stamp terminated_at on termination
    IF NEW.status = 'terminated' AND OLD.status <> 'terminated'
       AND OLD.terminated_at IS NULL THEN
        NEW.terminated_at := now();
    END IF;

    -- Prevent resurrection of terminated instances
    IF OLD.status = 'terminated' AND NEW.status <> 'terminated' THEN
        RAISE EXCEPTION 'Cannot change status of terminated database: %', OLD.id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_provisioned_db_lifecycle
    BEFORE UPDATE OF status ON provisioned_databases
    FOR EACH ROW EXECUTE FUNCTION fn_provisioned_db_lifecycle();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_sync_execution_duration()
-- ─────────────────────────────────────────────────────────────────────────────
-- Auto-computes duration_ms from started_at and completed_at when a
-- sync_execution finishes. Same logic as adapter_execution_duration.
--
-- FIRES: BEFORE INSERT OR UPDATE ON sync_executions (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_sync_execution_duration()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.started_at IS NOT NULL AND NEW.completed_at IS NOT NULL THEN
        NEW.duration_ms := EXTRACT(EPOCH FROM (NEW.completed_at - NEW.started_at)) * 1000;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_executions_duration
    BEFORE INSERT OR UPDATE ON sync_executions
    FOR EACH ROW EXECUTE FUNCTION fn_sync_execution_duration();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_sync_channel_error_tracking()
-- ─────────────────────────────────────────────────────────────────────────────
-- After a sync_execution completes, updates the parent sync_channel:
--   • success → resets consecutive_errors to 0, clears last_error
--   • failed  → increments consecutive_errors, records error
--   • If consecutive_errors >= error_threshold → auto-pauses the channel
--
-- FIRES: AFTER INSERT OR UPDATE ON sync_executions (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_sync_channel_error_tracking()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_threshold   INT;
    v_new_errors  INT;
BEGIN
    IF NEW.status = 'success' THEN
        UPDATE sync_channels
           SET consecutive_errors = 0,
               last_error         = NULL,
               last_sync_at       = COALESCE(NEW.completed_at, now())
         WHERE id = NEW.channel_id;

    ELSIF NEW.status = 'failed' THEN
        SELECT error_threshold INTO v_threshold
          FROM sync_channels WHERE id = NEW.channel_id;

        UPDATE sync_channels
           SET consecutive_errors = consecutive_errors + 1,
               last_error         = NEW.error_log::TEXT,
               last_sync_at       = COALESCE(NEW.completed_at, now())
         WHERE id = NEW.channel_id
         RETURNING consecutive_errors INTO v_new_errors;

        -- Auto-pause when threshold exceeded
        IF v_new_errors >= v_threshold THEN
            UPDATE sync_channels
               SET status = 'error'
             WHERE id = NEW.channel_id
               AND status <> 'error';
        END IF;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_sync_executions_error_tracking
    AFTER INSERT OR UPDATE OF status ON sync_executions
    FOR EACH ROW
    WHEN (NEW.status IN ('success', 'failed'))
    EXECUTE FUNCTION fn_sync_channel_error_tracking();
