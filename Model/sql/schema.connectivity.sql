-- ============================================================================
-- schema.connectivity.sql — Database Connections, Provisioning & Sync Channels
-- ============================================================================
--
-- DOMAIN: Manages user-owned database connections (private/public endpoints)
-- and platform-provisioned databases (Supabase PostgreSQL, MongoDB Atlas).
-- This is the bridge between the user's real data infrastructure and
-- the platform's collection/dashboard layer.
--
-- HOW CONNECTIVITY WORKS:
--
--   === USER-OWNED DATABASES ===
--   1. User provides their database endpoint (public URL or private network)
--   2. Platform establishes connection via public endpoint, SSH tunnel, or VPN
--   3. Schema introspection reads tables/collections → creates local Collections
--   4. Bidirectional real-time sync via CDC (Change Data Capture):
--      • User changes value in their DB → platform updates collection_records
--      • User changes value on platform → platform pushes to user's DB
--   5. Conflict resolution strategy per sync channel
--
--   === MANAGED / PROVISIONED DATABASES ===
--   1. User without their own DB requests a managed instance
--   2. Platform provisions a Supabase PostgreSQL or MongoDB Atlas cluster
--   3. User builds their model using the schema builder (SQL or NoSQL or both)
--   4. Platform manages backups, scaling, and lifecycle
--
-- SECURITY:
--   • Credentials stored in MongoDB (connection_credentials collection)
--   • SQL stores only credential_ref (UUID pointer to MongoDB document)
--   • SSL/TLS certificates, SSH keys, and API tokens are encrypted at rest
--   • Connection testing happens in isolated containers
--
-- EXECUTION ORDER: Run AFTER schema.organization.sql and schema.collection.sql
--   (depends on organizations, collections).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- PROVISIONED DATABASES (managed instances)
-- ─────────────────────────────────────────────────────────────────────────────
-- NOTE: This table is created BEFORE database_connections because
-- database_connections.provisioned_db_id references this table.
--
-- Platform-provisioned database instances for users who don't have their own
-- infrastructure. Currently supports Supabase PostgreSQL and MongoDB Atlas.
--
-- RELATIONSHIPS:
--   provisioned_databases.organization_id ──→ organizations.id     (N:1) Owning org
--   provisioned_databases.created_by      ──→ users.id             (N:1) Who requested provisioning
--   provisioned_databases.id              ←── database_connections.provisioned_db_id (1:1)
--
-- JOIN PATHS:
--   Org → Provisioned:        organizations → provisioned_databases
--   Provisioned → Connection: provisioned_databases → database_connections
--   Active instances:         provisioned_databases WHERE status = 'active'
--
-- PROVIDERS:
--   'supabase'      — Supabase PostgreSQL (auto-provisioned via Supabase Management API)
--   'mongodb_atlas'  — MongoDB Atlas (auto-provisioned via Atlas Admin API)
--   'planetscale'   — PlanetScale MySQL (future)
--   'neon'          — Neon serverless PostgreSQL (future)
--
-- TIER:
--   'free'       — Free tier (limited resources, shared infrastructure)
--   'starter'    — Small dedicated instance
--   'pro'        — Production-grade with backups and HA
--   'enterprise' — Custom resources, dedicated infrastructure
--
-- STATUS LIFECYCLE:
--   provisioning → active → suspended → terminated
--                         → scaling (during vertical/horizontal scale)
--                         → maintenance (during provider maintenance)
--
-- NOTES:
--   • provider_config: API keys, project IDs, cluster names (encrypted)
--   • provider_metadata: response from provisioning API (instance ID, endpoints)
--   • resource_limits: CPU, memory, storage, IOPS limits for the instance
--   • backup_config: backup schedule, retention policy
--   • Platform handles the entire lifecycle: provisioning, scaling, backups,
--     and termination when the org downgrades or cancels
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE provisioned_databases (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name                VARCHAR(255)    NOT NULL,
    provider            VARCHAR(30)     NOT NULL
                        CHECK (provider IN ('supabase','mongodb_atlas','planetscale','neon')),
    engine              VARCHAR(30)     NOT NULL
                        CHECK (engine IN ('postgresql','mongodb','mysql')),
    tier                VARCHAR(20)     NOT NULL DEFAULT 'free'
                        CHECK (tier IN ('free','starter','pro','enterprise')),
    region              VARCHAR(50)     NOT NULL DEFAULT 'us-east-1',

    -- Provider-specific configuration (encrypted at app level)
    provider_config     JSONB           NOT NULL DEFAULT '{}',

    -- Response from provisioning API (instance ID, connection endpoint, etc.)
    provider_metadata   JSONB           NOT NULL DEFAULT '{}',

    -- Resource limits
    resource_limits     JSONB           NOT NULL DEFAULT '{}'::JSONB,
    -- e.g. {"cpu_cores": 2, "memory_mb": 4096, "storage_gb": 50, "iops": 3000}

    -- Backup configuration
    backup_config       JSONB           NOT NULL DEFAULT '{}'::JSONB,
    -- e.g. {"enabled": true, "frequency": "daily", "retention_days": 30}

    -- Status
    status              VARCHAR(20)     NOT NULL DEFAULT 'provisioning'
                        CHECK (status IN (
                            'provisioning','active','suspended','scaling',
                            'maintenance','terminated'
                        )),
    provisioned_at      TIMESTAMPTZ,
    terminated_at       TIMESTAMPTZ,

    -- Audit
    created_by          UUID            NOT NULL REFERENCES users(id),
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE provisioned_databases IS
    'Platform-managed database instances (Supabase PG, MongoDB Atlas) for users without their own DB.';

-- ─────────────────────────────────────────────────────────────────────────────
-- DATABASE CONNECTIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- A connection to a user-owned external database. Supports PostgreSQL, MySQL,
-- MongoDB, and other engines via public endpoints, SSH tunnels, or VPNs.
--
-- RELATIONSHIPS:
--   database_connections.organization_id   ──→ organizations.id     (N:1) Owning org
--   database_connections.project_id        ──→ projects.id          (N:1) Optional project scope
--   database_connections.provisioned_db_id ──→ provisioned_databases.id (N:1) Managed DB link
--   database_connections.created_by        ──→ users.id             (N:1) Who set up the connection
--   database_connections.updated_by        ──→ users.id             (N:1) Last modifier
--   database_connections.id                ←── sync_channels.connection_id (1:N) Sync configs
--
-- JOIN PATHS:
--   Org → Connections:         organizations → database_connections
--   Connection → Sync:         database_connections → sync_channels → collections
--   Connection → Credentials:  database_connections.credential_ref → MongoDB connection_credentials
--   Connection → Provisioned:  database_connections.provisioned_db_id → provisioned_databases
--
-- CONNECTION TYPES:
--   'user_public'    — User's DB is accessible via public internet (direct TCP)
--   'user_ssh'       — Connection tunneled through SSH bastion host
--   'user_vpn'       — Connection over VPN / VPC peering / private link
--   'managed'        — Platform-provisioned database (Supabase / Atlas)
--
-- ENGINE TYPES:
--   'postgresql'  — PostgreSQL (user-owned or Supabase-managed)
--   'mysql'       — MySQL / MariaDB
--   'mongodb'     — MongoDB (user-owned or Atlas-managed)
--   'redis'       — Redis (for cache/queue connections)
--   'mssql'       — Microsoft SQL Server
--   'cockroachdb' — CockroachDB
--   'sqlite'      — SQLite (file-based, for prototyping)
--
-- NOTES:
--   • credential_ref is a UUID pointing to a MongoDB document in
--     connection_credentials collection (encrypted vault)
--   • connection_config stores non-sensitive config: host, port, database name,
--     SSL mode, pool size, timeouts (no passwords/keys)
--   • network_config stores SSH/VPN settings: bastion host, tunnel port,
--     VPC ID, private link endpoint
--   • schema_cache stores the introspected schema (tables, columns, types)
--     refreshed on connect and periodically
--   • is_readonly: TRUE if the platform should never write to this DB
--   • For managed connections, provisioned_db_id links to the provisioned instance
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE database_connections (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    project_id          UUID            REFERENCES projects(id) ON DELETE SET NULL,
    name                VARCHAR(255)    NOT NULL,
    slug                VARCHAR(100)    NOT NULL,
    description         TEXT,

    -- Connection classification
    connection_type     VARCHAR(20)     NOT NULL
                        CHECK (connection_type IN (
                            'user_public','user_ssh','user_vpn','managed'
                        )),
    engine              VARCHAR(30)     NOT NULL
                        CHECK (engine IN (
                            'postgresql','mysql','mongodb','redis',
                            'mssql','cockroachdb','sqlite'
                        )),

    -- Non-sensitive connection config (host, port, db name, SSL mode, pool)
    connection_config   JSONB           NOT NULL DEFAULT '{}',

    -- Network access config (SSH bastion, VPN, private link)
    network_config      JSONB           NOT NULL DEFAULT '{}',

    -- UUID reference to MongoDB connection_credentials document
    credential_ref      UUID,

    -- For managed databases — links to provisioned instance
    provisioned_db_id   UUID            REFERENCES provisioned_databases(id) ON DELETE SET NULL,

    -- Introspected schema from the remote database (cached)
    schema_cache        JSONB           NOT NULL DEFAULT '{}',
    schema_cached_at    TIMESTAMPTZ,

    -- Connection health
    health_status       VARCHAR(20)     NOT NULL DEFAULT 'unknown'
                        CHECK (health_status IN ('healthy','degraded','down','unknown')),
    last_health_check   TIMESTAMPTZ,

    -- Pool config
    pool_min            INT             NOT NULL DEFAULT 2,
    pool_max            INT             NOT NULL DEFAULT 10,
    connection_timeout  INT             NOT NULL DEFAULT 30000, -- ms

    -- Access mode
    is_readonly         BOOLEAN         NOT NULL DEFAULT FALSE,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,

    -- Audit
    created_by          UUID            NOT NULL REFERENCES users(id),
    updated_by          UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (organization_id, slug)
);

COMMENT ON TABLE database_connections IS
    'User-owned or managed database connections with network and credential references.';

-- ─────────────────────────────────────────────────────────────────────────────
-- SYNC CHANNELS (real-time bidirectional sync via CDC)
-- ─────────────────────────────────────────────────────────────────────────────
-- Defines a bidirectional sync channel between a remote database table/collection
-- and a local platform Collection. Uses Change Data Capture (CDC) for real-time
-- synchronization.
--
-- RELATIONSHIPS:
--   sync_channels.connection_id ──→ database_connections.id (N:1) The DB connection
--   sync_channels.collection_id ──→ collections.id         (N:1) Local collection target
--   sync_channels.created_by    ──→ users.id               (N:1) Who configured the sync
--   sync_channels.updated_by    ──→ users.id               (N:1) Last modifier
--
-- JOIN PATHS:
--   Connection → Channels:  database_connections → sync_channels → collections
--   Org → Full sync map:    organizations → database_connections → sync_channels → collections
--   Active syncs:           sync_channels WHERE status = 'active' AND is_active = TRUE
--
-- SYNC MODES:
--   'cdc_realtime'    — Change Data Capture with real-time streaming (PostgreSQL logical
--                       replication, MongoDB change streams, MySQL binlog)
--   'polling'         — Periodic polling with change detection (based on updated_at)
--   'webhook_push'    — External system pushes changes to our webhook endpoint
--   'manual'          — User manually triggers sync
--
-- SYNC DIRECTIONS:
--   'inbound'       — Remote DB → Platform only (read-only mirror)
--   'outbound'      — Platform → Remote DB only (write-back)
--   'bidirectional'  — Both directions with conflict resolution
--
-- CONFLICT STRATEGIES:
--   'source_wins'   — Remote DB value always wins
--   'platform_wins' — Platform value always wins
--   'newest_wins'   — Most recent timestamp wins
--   'manual'        — Queue conflicts for manual resolution
--   'merge'         — Field-level merge (non-conflicting fields auto-resolve)
--
-- CDC IMPLEMENTATION:
--   PostgreSQL: Logical replication slots + pgoutput plugin
--   MongoDB:    Change Streams (resume token stored in sync_state MongoDB collection)
--   MySQL:      Binlog streaming via Debezium-compatible connector
--
-- NOTES:
--   • source_path: remote table/collection name (e.g., "public.orders", "users")
--   • field_mappings: maps remote columns → local fields
--   • transform_rules: data transformations during sync
--   • filter_conditions: only sync records matching this filter
--   • sync_state is stored in MongoDB `sync_state` collection for CDC cursors,
--     replication slot info, and conflict queue
--   • error_threshold: number of consecutive errors before auto-pausing
--   • last_sync_lsn/last_sync_cursor: stored in MongoDB for durability
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE sync_channels (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    connection_id       UUID            NOT NULL REFERENCES database_connections(id) ON DELETE CASCADE,
    collection_id       UUID            NOT NULL REFERENCES collections(id) ON DELETE CASCADE,

    -- What to sync from remote
    source_schema       VARCHAR(255),                           -- e.g., "public" (PostgreSQL)
    source_path         VARCHAR(500)    NOT NULL,               -- e.g., "orders", "users"

    -- Field mapping & transforms
    field_mappings      JSONB           NOT NULL DEFAULT '{}',
    transform_rules     JSONB           NOT NULL DEFAULT '{}',
    filter_conditions   JSONB           NOT NULL DEFAULT '{}',

    -- Sync configuration
    sync_mode           VARCHAR(20)     NOT NULL DEFAULT 'cdc_realtime'
                        CHECK (sync_mode IN ('cdc_realtime','polling','webhook_push','manual')),
    sync_direction      VARCHAR(20)     NOT NULL DEFAULT 'bidirectional'
                        CHECK (sync_direction IN ('inbound','outbound','bidirectional')),
    conflict_strategy   VARCHAR(20)     NOT NULL DEFAULT 'newest_wins'
                        CHECK (conflict_strategy IN (
                            'source_wins','platform_wins','newest_wins','manual','merge'
                        )),

    -- Polling interval (only used when sync_mode = 'polling')
    polling_interval_ms INT             NOT NULL DEFAULT 60000, -- 60 seconds

    -- Error handling
    error_threshold     INT             NOT NULL DEFAULT 10,    -- auto-pause after N consecutive errors
    retry_backoff_ms    INT             NOT NULL DEFAULT 1000,  -- initial retry delay
    max_retry_attempts  INT             NOT NULL DEFAULT 5,

    -- Status
    status              VARCHAR(20)     NOT NULL DEFAULT 'initializing'
                        CHECK (status IN (
                            'initializing','active','paused','error','disabled'
                        )),
    last_sync_at        TIMESTAMPTZ,
    last_error          TEXT,
    consecutive_errors  INT             NOT NULL DEFAULT 0,

    -- Flags
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,

    -- Audit
    created_by          UUID            NOT NULL REFERENCES users(id),
    updated_by          UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE sync_channels IS
    'Real-time CDC sync channels between user databases and platform collections.';

-- ─────────────────────────────────────────────────────────────────────────────
-- SYNC EXECUTIONS (sync history log for channels)
-- ─────────────────────────────────────────────────────────────────────────────
-- Immutable log of sync operations on a channel. Similar to adapter_executions
-- but specifically for the connectivity sync engine.
--
-- RELATIONSHIPS:
--   sync_executions.channel_id ──→ sync_channels.id (N:1)
--
-- JOIN PATHS:
--   Channel → History:  sync_channels → sync_executions (ORDER BY created_at DESC)
--   Failed in 24h:      sync_executions WHERE status='failed' AND created_at > now() - '24h'
--
-- NOTES:
--   • Immutable event log — no updated_at needed
--   • For CDC: each execution may represent a batch of changes
--   • records_in/out track the number of changes in each direction
--   • latency_ms: time from change detection to sync completion
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE sync_executions (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    channel_id          UUID        NOT NULL REFERENCES sync_channels(id) ON DELETE CASCADE,
    status              VARCHAR(20) NOT NULL
                        CHECK (status IN ('pending','running','success','partial','failed','cancelled')),
    trigger_type        VARCHAR(20) NOT NULL DEFAULT 'cdc'
                        CHECK (trigger_type IN ('cdc','poll','webhook','manual')),
    direction           VARCHAR(20) NOT NULL
                        CHECK (direction IN ('inbound','outbound','bidirectional')),

    -- Metrics
    records_processed   INT         NOT NULL DEFAULT 0,
    records_in          INT         NOT NULL DEFAULT 0,         -- remote → platform
    records_out         INT         NOT NULL DEFAULT 0,         -- platform → remote
    records_conflicted  INT         NOT NULL DEFAULT 0,
    records_failed      INT         NOT NULL DEFAULT 0,
    latency_ms          INT,

    -- Error details
    error_log           JSONB,

    -- Timing
    started_at          TIMESTAMPTZ,
    completed_at        TIMESTAMPTZ,
    duration_ms         INT,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now()
);

COMMENT ON TABLE sync_executions IS
    'Immutable log of sync operations on CDC channels.';
