-- ============================================================================
-- schema.adapter.sql — External Data Adapters & Sync Engine
-- ============================================================================
--
-- DOMAIN: Integration layer for connecting external data sources and
-- synchronizing data into the platform's collection system.
--
-- NOTE: For bidirectional real-time database sync (CDC), see schema.connectivity.sql.
-- This file handles generic adapters for REST APIs, spreadsheets, file imports, etc.
-- The connectivity module handles database-to-database sync with CDC.
--
-- HOW ADAPTERS WORK:
--   1. Org admin creates an Adapter (configures connection to external source)
--   2. Admin creates Adapter Mappings (maps external data → local collections)
--   3. Sync engine executes on schedule or manually:
--      a. Connects to external source using adapter.connection_config
--      b. Reads data from mapping.source_path
--      c. Transforms data using mapping.transform_rules + field_mappings
--      d. Writes/updates MongoDB collection_records
--      e. Logs execution result in adapter_executions
--
-- SUPPORTED SOURCES:
--   rest_api, graphql, postgresql, mysql, mongodb, csv, excel,
--   google_sheets, s3, webhook, custom
--
-- EXECUTION ORDER: Run AFTER schema.collection.sql (depends on collections).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- ADAPTERS
-- ─────────────────────────────────────────────────────────────────────────────
-- An external data source connection. Each adapter represents one configured
-- connection to an external system.
--
-- RELATIONSHIPS:
--   adapters.organization_id ──→ organizations.id     (N:1) Owning organization
--   adapters.created_by      ──→ users.id             (N:1) Who configured this adapter
--   adapters.updated_by      ──→ users.id             (N:1) Who last modified the config
--   adapters.id              ←── adapter_mappings.adapter_id    (1:N) Data mappings
--   adapters.id              ←── adapter_executions.adapter_id  (1:N) Sync history
--
-- JOIN PATHS:
--   Org → Adapters:      organizations → adapters
--   Adapter → Mappings:  adapters → adapter_mappings → collections
--   Adapter → History:   adapters → adapter_executions
--   Adapter → Resource:  adapters.id → resources (WHERE resource_type='adapter')
--                           → resource_permissions, resource_versions, etc.
--
-- NOTES:
--   • connection_config is JSONB containing host, port, auth, headers, etc.
--     Encrypted at application level (sensitive credentials)
--   • health_status is updated by periodic health checks (cron or heartbeat)
--   • is_active allows disabling without deleting (preserves config + history)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE adapters (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name                VARCHAR(255)    NOT NULL,
    adapter_type        VARCHAR(50)     NOT NULL
                        CHECK (adapter_type IN (
                            'rest_api','graphql','postgresql','mysql','mongodb',
                            'csv','excel','google_sheets','s3','webhook',
                            'custom'
                        )),
    connection_config   JSONB           NOT NULL DEFAULT '{}',  -- encrypted at app level
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    health_status       VARCHAR(20)     NOT NULL DEFAULT 'unknown'
                        CHECK (health_status IN ('healthy','degraded','down','unknown')),
    last_health_check   TIMESTAMPTZ,
    created_by          UUID            NOT NULL REFERENCES users(id),
    updated_by          UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE adapters IS
    'External data source connections. Config is encrypted at the application layer.';

-- ─────────────────────────────────────────────────────────────────────────────
-- ADAPTER MAPPINGS
-- ─────────────────────────────────────────────────────────────────────────────
-- Maps an external data path to a local Collection and defines how fields
-- are transformed during sync.
--
-- RELATIONSHIPS:
--   adapter_mappings.adapter_id    ──→ adapters.id     (N:1) The parent adapter
--   adapter_mappings.collection_id ──→ collections.id  (N:1) Target collection for synced data
--   adapter_mappings.updated_by    ──→ users.id        (N:1) Who last modified this mapping
--
-- JOIN PATHS:
--   Adapter → Mappings:     adapters → adapter_mappings
--   Mapping → Collection:   adapter_mappings → collections → fields
--   Mapping → Executions:   adapter_mappings → adapter_executions (via mapping_id)
--   Full chain:             organizations → adapters → adapter_mappings → collections
--
-- SYNC CONFIGURATION:
--   source_path:       External data location ("/api/v1/users", "public.orders", "Sheet1")
--   field_mappings:    JSONB mapping external field names → local field slugs
--                      e.g., {"external_email": "email", "full_name": "display_name"}
--   transform_rules:   JSONB transformation applied during sync
--                      e.g., {"email": {"lowercase": true}, "amount": {"multiply": 100}}
--   sync_direction:    inbound (pull), outbound (push), bidirectional
--   sync_frequency:    Cron expression ("0 */6 * * *") or "realtime"
--   conflict_strategy: How to resolve conflicts during bidirectional sync
--
-- NOTES:
--   • One adapter can have multiple mappings (e.g., different tables from same DB)
--   • last_sync_at/status provide quick status without querying adapter_executions
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE adapter_mappings (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    adapter_id      UUID            NOT NULL REFERENCES adapters(id) ON DELETE CASCADE,
    collection_id   UUID            NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    source_path     VARCHAR(500)    NOT NULL,
    field_mappings  JSONB           NOT NULL DEFAULT '{}',
    transform_rules JSONB           NOT NULL DEFAULT '{}',
    sync_direction  VARCHAR(20)     NOT NULL DEFAULT 'inbound'
                    CHECK (sync_direction IN ('inbound','outbound','bidirectional')),
    sync_frequency  VARCHAR(100),                               -- cron or "realtime"
    conflict_strategy VARCHAR(20)   NOT NULL DEFAULT 'source_wins'
                    CHECK (conflict_strategy IN ('source_wins','target_wins','newest_wins','manual')),
    last_sync_at    TIMESTAMPTZ,
    last_sync_status VARCHAR(20),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ADAPTER EXECUTIONS (sync history / event log)
-- ─────────────────────────────────────────────────────────────────────────────
-- Immutable log of every sync execution. Used for debugging, monitoring,
-- and audit trail.
--
-- RELATIONSHIPS:
--   adapter_executions.adapter_id ──→ adapters.id          (N:1) The adapter that ran
--   adapter_executions.mapping_id ──→ adapter_mappings.id  (N:1) Optional: specific mapping
--
-- JOIN PATHS:
--   Adapter → History:  adapters → adapter_executions (ORDER BY created_at DESC)
--   Mapping → History:  adapter_mappings → adapter_executions (via mapping_id)
--   Latest execution:   adapter_executions WHERE adapter_id = $id ORDER BY created_at DESC LIMIT 1
--   Failed in 24h:      adapter_executions WHERE status='failed' AND created_at > now() - '24h'
--
-- NOTES:
--   • This is an IMMUTABLE event log — no updated_at/updated_by needed
--   • status lifecycle: pending → running → success|partial|failed|cancelled
--   • trigger_type: scheduled (cron), manual (user clicked), webhook (external trigger)
--   • records_processed/created/updated/failed provide sync metrics
--   • error_log JSONB stores per-record errors: [{record_index, error, field}]
--   • duration_ms = completed_at - started_at for performance monitoring
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE adapter_executions (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    adapter_id          UUID        NOT NULL REFERENCES adapters(id) ON DELETE CASCADE,
    mapping_id          UUID        REFERENCES adapter_mappings(id) ON DELETE SET NULL,
    status              VARCHAR(20) NOT NULL
                        CHECK (status IN ('pending','running','success','partial','failed','cancelled')),
    trigger_type        VARCHAR(20) NOT NULL DEFAULT 'scheduled'
                        CHECK (trigger_type IN ('scheduled','manual','webhook','realtime')),
    records_processed   INT         NOT NULL DEFAULT 0,
    records_created     INT         NOT NULL DEFAULT 0,
    records_updated     INT         NOT NULL DEFAULT 0,
    records_failed      INT         NOT NULL DEFAULT 0,
    error_log           JSONB,
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    duration_ms         INT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);
