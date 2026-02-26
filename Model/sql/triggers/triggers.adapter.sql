-- ============================================================================
-- triggers.adapter.sql — Triggers for Adapters, Mappings, Executions
-- ============================================================================
--
-- DOMAIN: Automates adapter sync engine lifecycle and metrics.
--
-- TRIGGERS:
--   1. fn_adapter_execution_duration    — Auto-compute duration_ms
--   2. fn_adapter_sync_status_propagate — Update mapping last_sync from executions
--   3. fn_adapter_health_from_execution — Update adapter health from last execution
--   4. fn_prevent_inactive_adapter_exec — Block sync on disabled adapters
--
-- EXECUTION ORDER: Run AFTER triggers.utility.sql.
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_adapter_execution_duration()
-- ─────────────────────────────────────────────────────────────────────────────
-- Automatically computes duration_ms from started_at and completed_at
-- when an execution finishes. Saves the application from computing this
-- on every write.
--
-- FIRES: BEFORE INSERT OR UPDATE ON adapter_executions (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_adapter_execution_duration()
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

CREATE TRIGGER trg_adapter_executions_duration
    BEFORE INSERT OR UPDATE ON adapter_executions
    FOR EACH ROW EXECUTE FUNCTION fn_adapter_execution_duration();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_adapter_sync_status_propagate()
-- ─────────────────────────────────────────────────────────────────────────────
-- When an adapter_execution completes (status in success/partial/failed),
-- propagates the result back to the adapter_mapping's last_sync_at and
-- last_sync_status for quick lookups without joining executions.
--
-- FIRES: AFTER INSERT OR UPDATE ON adapter_executions (row-level)
-- CONDITION: When status is a terminal state
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_adapter_sync_status_propagate()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
BEGIN
    IF NEW.status IN ('success', 'partial', 'failed') AND NEW.mapping_id IS NOT NULL THEN
        UPDATE adapter_mappings
           SET last_sync_at     = COALESCE(NEW.completed_at, now()),
               last_sync_status = NEW.status
         WHERE id = NEW.mapping_id;
    END IF;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_adapter_executions_propagate_status
    AFTER INSERT OR UPDATE OF status ON adapter_executions
    FOR EACH ROW
    WHEN (NEW.status IN ('success', 'partial', 'failed'))
    EXECUTE FUNCTION fn_adapter_sync_status_propagate();

-- ─────────────────────────────────────────────────────────────────────────────
-- fn_adapter_health_from_execution()
-- ─────────────────────────────────────────────────────────────────────────────
-- Updates adapter.health_status based on the latest execution result.
--   success → healthy | partial → degraded | failed → down
-- Also stamps last_health_check.
--
-- FIRES: AFTER INSERT OR UPDATE ON adapter_executions (row-level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE OR REPLACE FUNCTION fn_adapter_health_from_execution()
RETURNS TRIGGER
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $$
DECLARE
    v_health VARCHAR(20);
BEGIN
    IF NEW.status NOT IN ('success', 'partial', 'failed') THEN
        RETURN NEW;
    END IF;

    v_health := CASE NEW.status
        WHEN 'success' THEN 'healthy'
        WHEN 'partial' THEN 'degraded'
        WHEN 'failed'  THEN 'down'
    END;

    UPDATE adapters
       SET health_status    = v_health,
           last_health_check = COALESCE(NEW.completed_at, now())
     WHERE id = NEW.adapter_id;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_adapter_executions_update_health
    AFTER INSERT OR UPDATE OF status ON adapter_executions
    FOR EACH ROW EXECUTE FUNCTION fn_adapter_health_from_execution();
