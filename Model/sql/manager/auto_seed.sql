-- ============================================================================
-- auto_seed.sql — Dynamic Auto-Seeder (Schema Introspection + Mock Generation)
-- ============================================================================
--
-- PURPOSE:
--   Automatically discovers all tables, columns, types, constraints, and
--   foreign key relationships in the database, then generates realistic
--   mock data by analyzing column names and types.
--
-- HOW IT WORKS:
--   1. Introspects information_schema to discover all tables and columns
--   2. Builds a topological sort of tables based on FK dependencies
--   3. For each table in dependency order:
--      a. Analyzes each column's name, type, and constraints
--      b. Generates contextually appropriate mock data
--      c. Inserts rows respecting FK references (uses already-seeded PKs)
--   4. Handles composite PKs, junction tables, and self-references
--
-- FEATURES:
--   • Fully automatic — adapts when schema changes
--   • Heuristic-based data generation (email → realistic email, etc.)
--   • Respects CHECK constraints and enum-like patterns
--   • Handles FK chains by seeding in topological order
--   • Configurable row count per table
--   • Idempotent — can be run repeatedly after reset
--
-- USAGE:
--   SELECT auto_seed_all(rows_per_table := 10);
--   SELECT auto_seed_all(rows_per_table := 5, target_schema := 'public');
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: Extract CHECK constraint allowed values
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_extract_check_values(check_clause TEXT)
RETURNS TEXT[]
LANGUAGE plpgsql
AS $$
DECLARE
    result TEXT[];
    matches TEXT;
BEGIN
    -- Extract values from patterns like: CHECK (col IN ('val1','val2','val3'))
    -- or CHECK (col = ANY(ARRAY['val1','val2']))
    SELECT array_agg(val)
    INTO result
    FROM regexp_matches(check_clause, '''([^'']+)''', 'g') AS r(m)
    CROSS JOIN LATERAL unnest(r.m) AS val;

    RETURN COALESCE(result, ARRAY[]::TEXT[]);
END;
$$;

-- ─────────────────────────────────────────────────────────────────────────────
-- Helper: Generate a realistic mock value based on column metadata
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_generate_mock_value(
    p_column_name   TEXT,
    p_data_type     TEXT,
    p_udt_name      TEXT,
    p_is_nullable   BOOLEAN,
    p_has_default    BOOLEAN,
    p_check_values  TEXT[],
    p_row_index     INT,
    p_table_name    TEXT
)
RETURNS TEXT
LANGUAGE plpgsql
AS $$
DECLARE
    v_val TEXT;
    v_idx INT := p_row_index;
    v_names TEXT[] := ARRAY[
        'Alice','Bob','Charlie','Diana','Eve','Frank','Grace','Hank',
        'Iris','Jack','Kate','Leo','Mia','Noah','Olivia','Paul',
        'Quinn','Rose','Sam','Tara','Uma','Vic','Wendy','Xander',
        'Yara','Zane','Ada','Ben','Cleo','Dan'
    ];
    v_lastnames TEXT[] := ARRAY[
        'Smith','Johnson','Williams','Brown','Jones','Garcia','Miller',
        'Davis','Rodriguez','Martinez','Anderson','Taylor','Thomas',
        'Hernandez','Moore','Martin','Jackson','Thompson','White','Lopez',
        'Lee','Gonzalez','Harris','Clark','Lewis','Robinson','Walker',
        'Perez','Hall','Young'
    ];
    v_words TEXT[] := ARRAY[
        'alpha','beta','gamma','delta','epsilon','zeta','eta','theta',
        'iota','kappa','lambda','sigma','omega','phoenix','atlas','nova',
        'pulse','orbit','nexus','zenith','apex','vertex','prism','flux',
        'core','edge','spark','wave','drift','echo'
    ];
    v_colors TEXT[] := ARRAY['#3B82F6','#EF4444','#10B981','#F59E0B','#8B5CF6','#EC4899','#06B6D4'];
    v_icons TEXT[] := ARRAY['📊','📋','🗂️','📁','📈','🔧','⚙️','💡','🎯','📌','🏷️','📝'];
    v_first TEXT;
    v_last TEXT;
    v_ci INT;
BEGIN
    -- Ensure index stays within array bounds
    v_ci := (v_idx % 30) + 1;
    v_first := v_names[v_ci];
    v_last := v_lastnames[v_ci];

    -- ── If CHECK constraint has allowed values, pick one ──
    IF array_length(p_check_values, 1) > 0 THEN
        RETURN '''' || p_check_values[1 + (v_idx % array_length(p_check_values, 1))] || '''';
    END IF;

    -- ── UUID columns ──
    IF p_udt_name = 'uuid' THEN
        -- Polymorphic grantee_id / context_id: resolve to a real user UUID
        -- (the seeding loop handles this more precisely, but fallback here)
        IF p_column_name IN ('grantee_id', 'context_id') THEN
            IF p_is_nullable THEN
                RETURN 'NULL';
            END IF;
            -- Fallback: generate a random UUID
            RETURN '''' || gen_random_uuid()::TEXT || '''';
        END IF;
        -- resource_id on the resources table is NOT the PK — it's a ref UUID
        IF p_column_name = 'resource_id' AND p_table_name = 'resources' THEN
            RETURN '''' || gen_random_uuid()::TEXT || '''';
        END IF;
        -- updated_by / assigned_by etc. that aren't FKs
        IF p_column_name LIKE '%_by' THEN
            IF p_is_nullable THEN
                RETURN 'NULL';
            END IF;
            RETURN '''' || gen_random_uuid()::TEXT || '''';
        END IF;
        RETURN NULL; -- handled by DEFAULT or FK resolver
    END IF;

    -- ── BOOLEAN columns ──
    IF p_udt_name = 'bool' THEN
        -- Contextual defaults based on column name
        IF p_column_name IN ('is_active', 'is_public', 'can_view', 'granted') THEN
            RETURN 'TRUE';
        ELSIF p_column_name IN ('is_locked', 'is_resolved', 'is_read', 'mfa_enabled',
                                 'stackable', 'cancel_at_period_end', 'is_hidden',
                                 'is_readonly', 'is_archived') THEN
            RETURN CASE WHEN v_idx % 5 = 0 THEN 'TRUE' ELSE 'FALSE' END;
        ELSIF p_column_name = 'is_system' THEN
            RETURN 'FALSE';
        ELSIF p_column_name = 'is_default' THEN
            RETURN CASE WHEN v_idx = 0 THEN 'TRUE' ELSE 'FALSE' END;
        ELSIF p_column_name = 'is_primary' THEN
            RETURN CASE WHEN v_idx = 0 THEN 'TRUE' ELSE 'FALSE' END;
        ELSIF p_column_name IN ('is_required', 'is_unique', 'is_sparse') THEN
            RETURN CASE WHEN v_idx % 3 = 0 THEN 'TRUE' ELSE 'FALSE' END;
        END IF;
        RETURN CASE WHEN v_idx % 2 = 0 THEN 'TRUE' ELSE 'FALSE' END;
    END IF;

    -- ── TIMESTAMPTZ / TIMESTAMP columns ──
    IF p_udt_name IN ('timestamptz', 'timestamp') THEN
        IF p_column_name IN ('created_at', 'assigned_at', 'granted_at', 'joined_at', 'recorded_at', 'delivered_at') THEN
            RETURN NULL; -- use DEFAULT now()
        END IF;
        IF p_column_name = 'updated_at' THEN
            RETURN NULL; -- use DEFAULT now()
        END IF;
        IF p_column_name IN ('expires_at', 'terminated_at', 'cancelled_at', 'paid_at',
                              'token_expires_at', 'trial_ends_at', 'ends_at') THEN
            RETURN '''' || (now() + (interval '1 day' * (30 + v_idx * 7)))::TEXT || '''';
        END IF;
        IF p_column_name IN ('last_login_at', 'last_seen_at', 'last_used_at',
                              'last_health_check', 'last_triggered_at', 'last_sync_at',
                              'last_activity_at', 'schema_cached_at') THEN
            RETURN '''' || (now() - (interval '1 hour' * v_idx))::TEXT || '''';
        END IF;
        IF p_column_name = 'provisioned_at' THEN
            RETURN '''' || (now() - (interval '1 day' * v_idx))::TEXT || '''';
        END IF;
        IF p_column_name IN ('current_period_start', 'period_start', 'starts_at') THEN
            RETURN '''' || (now() - interval '15 days')::TEXT || '''';
        END IF;
        IF p_column_name IN ('current_period_end', 'period_end', 'due_date') THEN
            RETURN '''' || (now() + interval '15 days')::TEXT || '''';
        END IF;
        IF p_column_name IN ('started_at') THEN
            RETURN '''' || (now() - (interval '1 minute' * (v_idx * 5 + 10)))::TEXT || '''';
        END IF;
        IF p_column_name IN ('completed_at') THEN
            RETURN '''' || (now() - (interval '1 minute' * v_idx))::TEXT || '''';
        END IF;
        -- Generic timestamp
        RETURN '''' || (now() - (interval '1 day' * v_idx))::TEXT || '''';
    END IF;

    -- ── INTEGER / BIGINT columns ──
    IF p_udt_name IN ('int4', 'int8', 'int2') THEN
        IF p_column_name IN ('sort_order') THEN RETURN v_idx::TEXT; END IF;
        IF p_column_name IN ('record_count') THEN RETURN (v_idx * 42 + 10)::TEXT; END IF;
        IF p_column_name IN ('price_monthly') THEN RETURN (ARRAY[0, 1900, 4900, 14900])[1 + (v_idx % 4)]::TEXT; END IF;
        IF p_column_name IN ('price_yearly') THEN RETURN (ARRAY[0, 19000, 49000, 149000])[1 + (v_idx % 4)]::TEXT; END IF;
        IF p_column_name = 'trial_days' THEN RETURN (ARRAY[0, 7, 14, 30])[1 + (v_idx % 4)]::TEXT; END IF;
        IF p_column_name IN ('discount_value') THEN RETURN (ARRAY[10, 20, 25, 50])[1 + (v_idx % 4)]::TEXT; END IF;
        IF p_column_name = 'duration_months' THEN
            RETURN (v_idx % 12 + 1)::TEXT;
        END IF;
        IF p_column_name IN ('max_redemptions') THEN RETURN (100 + v_idx * 50)::TEXT; END IF;
        IF p_column_name = 'current_redemptions' THEN RETURN (v_idx * 3)::TEXT; END IF;
        IF p_column_name IN ('subtotal_amount', 'amount') THEN RETURN (4900 + v_idx * 1000)::TEXT; END IF;
        IF p_column_name = 'discount_amount' THEN RETURN (v_idx * 100)::TEXT; END IF;
        IF p_column_name = 'tax_amount' THEN RETURN (v_idx * 50 + 200)::TEXT; END IF;
        IF p_column_name = 'total_amount' THEN RETURN (4900 + v_idx * 950)::TEXT; END IF;
        IF p_column_name = 'refund_amount' THEN RETURN '0'; END IF;
        IF p_column_name = 'response_status' THEN RETURN (ARRAY[200, 200, 200, 201, 400, 500])[1 + (v_idx % 6)]::TEXT; END IF;
        IF p_column_name = 'attempt_number' THEN RETURN '1'; END IF;
        IF p_column_name IN ('duration_ms', 'latency_ms') THEN RETURN (150 + v_idx * 37)::TEXT; END IF;
        IF p_column_name = 'version_number' THEN RETURN (v_idx + 1)::TEXT; END IF;
        IF p_column_name = 'use_count' THEN RETURN (v_idx * 2)::TEXT; END IF;
        IF p_column_name = 'max_uses' THEN RETURN (50 + v_idx * 10)::TEXT; END IF;
        IF p_column_name = 'priority' THEN RETURN (v_idx * 10)::TEXT; END IF;
        IF p_column_name = 'limit_value' THEN RETURN (ARRAY[5, 10, 50, 100, 500])[1 + (v_idx % 5)]::TEXT; END IF;
        IF p_column_name = 'retry_count' THEN RETURN '3'; END IF;
        IF p_column_name = 'retry_delay_ms' THEN RETURN '1000'; END IF;
        IF p_column_name = 'refresh_interval' THEN RETURN '60'; END IF;
        IF p_column_name IN ('pool_min') THEN RETURN '2'; END IF;
        IF p_column_name IN ('pool_max') THEN RETURN '10'; END IF;
        IF p_column_name = 'connection_timeout' THEN RETURN '30000'; END IF;
        IF p_column_name = 'polling_interval_ms' THEN RETURN '60000'; END IF;
        IF p_column_name IN ('error_threshold') THEN RETURN '10'; END IF;
        IF p_column_name IN ('retry_backoff_ms') THEN RETURN '1000'; END IF;
        IF p_column_name IN ('max_retry_attempts') THEN RETURN '5'; END IF;
        IF p_column_name = 'consecutive_errors' THEN RETURN '0'; END IF;
        IF p_column_name IN ('records_processed', 'records_created', 'records_updated',
                              'records_failed', 'records_in', 'records_out', 'records_conflicted') THEN
            RETURN (v_idx * 10 + 5)::TEXT;
        END IF;
        IF p_column_name = 'size_bytes' THEN RETURN (1024 * (v_idx + 1) * 100)::TEXT; END IF;
        -- quantity for usage_records
        IF p_column_name = 'quantity' THEN RETURN (v_idx * 1000 + 500)::TEXT; END IF;
        -- Generic int
        RETURN v_idx::TEXT;
    END IF;

    -- ── VARCHAR / TEXT columns ──
    IF p_udt_name IN ('varchar', 'text', 'bpchar') THEN
        -- Name columns
        IF p_column_name = 'email' AND p_table_name = 'users' THEN
            RETURN '''' || lower(v_first) || '.' || lower(v_last) || v_idx::TEXT || '@example.com''';
        END IF;
        IF p_column_name = 'email' AND p_table_name != 'users' THEN
            RETURN '''' || 'contact' || v_idx::TEXT || '@example.com''';
        END IF;
        IF p_column_name = 'username' THEN
            RETURN '''' || lower(v_first) || '_' || lower(v_last) || v_idx::TEXT || '''';
        END IF;
        IF p_column_name = 'display_name' THEN
            RETURN '''' || v_first || ' ' || v_last || '''';
        END IF;
        IF p_column_name = 'first_name' THEN RETURN '''' || v_first || ''''; END IF;
        IF p_column_name = 'last_name' THEN RETURN '''' || v_last || ''''; END IF;
        IF p_column_name = 'name' THEN
            IF p_table_name = 'organizations' THEN
                RETURN '''' || v_words[(v_ci % 30) + 1] || ' Corp ' || v_idx::TEXT || '''';
            ELSIF p_table_name = 'projects' THEN
                RETURN '''' || 'Project ' || v_words[(v_ci % 30) + 1] || ' ' || v_idx::TEXT || '''';
            ELSIF p_table_name = 'workspaces' THEN
                RETURN '''' || 'Workspace ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'collections' THEN
                RETURN '''' || 'Collection ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'fields' THEN
                RETURN '''' || 'Field ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'plans' THEN
                RETURN '''' || (ARRAY['Free','Starter','Pro','Enterprise'])[1 + (v_idx % 4)] || '''';
            ELSIF p_table_name = 'roles' THEN
                RETURN '''' || 'role_' || v_words[(v_ci % 30) + 1] || '_' || v_idx || '''';
            ELSIF p_table_name = 'permissions' THEN
                RETURN '''' || (ARRAY['dashboard','collection','view','workspace','project','adapter','resource','user','role','billing'])[1 + (v_idx % 10)]
                    || ':' || (ARRAY['create','read','update','delete','manage','share','publish'])[1 + (v_idx % 7)] || '''';
            ELSIF p_table_name = 'dashboards' THEN
                RETURN '''' || 'Dashboard ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'views' THEN
                RETURN '''' || 'View ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'tags' THEN
                RETURN '''' || (ARRAY['important','urgent','reviewed','draft','archived','featured','deprecated','experimental'])[1 + (v_idx % 8)] || '''';
            ELSIF p_table_name = 'webhooks' THEN
                RETURN '''' || 'Webhook ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'adapters' THEN
                RETURN '''' || 'Adapter ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'api_keys' THEN
                RETURN '''' || 'API Key ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'usage_meters' THEN
                RETURN '''' || (ARRAY['Storage Usage','API Requests','Record Count','Active Members','Bandwidth','Adapter Syncs'])[1 + (v_idx % 6)] || '''';
            ELSIF p_table_name = 'promotions' THEN
                RETURN '''' || 'Promo ' || upper(v_words[(v_ci % 30) + 1]) || '''';
            ELSIF p_table_name = 'database_connections' THEN
                RETURN '''' || 'Connection ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'provisioned_databases' THEN
                RETURN '''' || 'ManagedDB ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'dashboard_templates' THEN
                RETURN '''' || 'Template ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'policy_rules' THEN
                RETURN '''' || 'Policy ' || v_words[(v_ci % 30) + 1] || '''';
            ELSIF p_table_name = 'resources' THEN
                RETURN '''' || 'Resource ' || v_words[(v_ci % 30) + 1] || ' ' || v_idx || '''';
            END IF;
            RETURN '''' || p_table_name || '_' || v_words[(v_ci % 30) + 1] || '_' || v_idx || '''';
        END IF;

        -- Slug columns
        IF p_column_name = 'slug' THEN
            IF p_table_name = 'organizations' THEN
                RETURN '''' || v_words[(v_ci % 30) + 1] || '-corp-' || v_idx || '''';
            ELSIF p_table_name = 'plans' THEN
                RETURN '''' || (ARRAY['free','starter','pro','enterprise'])[1 + (v_idx % 4)] || '''';
            ELSIF p_table_name = 'usage_meters' THEN
                RETURN '''' || (ARRAY['storage_bytes','api_requests','record_count','active_members','bandwidth_bytes','adapter_syncs'])[1 + (v_idx % 6)] || '''';
            ELSIF p_table_name = 'tags' THEN
                RETURN '''' || (ARRAY['important','urgent','reviewed','draft','archived','featured','deprecated','experimental'])[1 + (v_idx % 8)] || '''';
            END IF;
            RETURN '''' || lower(p_table_name) || '-' || v_words[(v_ci % 30) + 1] || '-' || v_idx || '''';
        END IF;

        -- Description/text — always fill with meaningful content
        IF p_column_name = 'description' THEN
            RETURN '''' || 'Description for ' || p_table_name || ' #' || v_idx || '. Auto-generated mock data.''';
        END IF;

        -- URL columns
        IF p_column_name LIKE '%_url' OR p_column_name = 'url' THEN
            IF p_column_name = 'avatar_url' THEN
                RETURN '''' || 'https://avatars.example.com/u/' || v_idx || '.png''';
            ELSIF p_column_name = 'logo_url' THEN
                RETURN '''' || 'https://logos.example.com/org/' || v_idx || '.svg''';
            ELSIF p_column_name = 'thumbnail_url' THEN
                RETURN '''' || 'https://thumbs.example.com/t/' || v_idx || '.jpg''';
            ELSIF p_column_name = 'action_url' THEN
                RETURN '''' || '/org/project/workspace/' || v_idx || '''';
            ELSIF p_column_name = 'url' THEN
                RETURN '''' || 'https://hooks.example.com/webhook/' || v_idx || '''';
            END IF;
            RETURN '''' || 'https://example.com/' || p_column_name || '/' || v_idx || '''';
        END IF;

        -- Hash columns (never real secrets) — always fill
        IF p_column_name LIKE '%_hash' OR p_column_name = 'password_hash' THEN
            RETURN '''' || '$2b$10$mock_hash_' || md5(p_table_name || v_idx::TEXT) || '''';
        END IF;

        -- Token columns — always fill
        IF p_column_name LIKE '%token%' THEN
            IF p_column_name = 'share_token' THEN
                RETURN '''' || 'share_' || md5(v_idx::TEXT || p_table_name)::TEXT || '''';
            END IF;
            RETURN '''' || 'tok_' || md5(v_idx::TEXT || p_table_name)::TEXT || '''';
        END IF;

        -- Secret/encrypted columns — fill with mock encrypted values
        IF p_column_name LIKE '%secret%' OR p_column_name LIKE '%access_token%'
           OR p_column_name LIKE '%refresh_token%' THEN
            RETURN '''' || 'enc_mock_' || md5(p_column_name || v_idx::TEXT) || '''';
        END IF;

        -- Phone
        IF p_column_name = 'phone' THEN
            RETURN '''' || '+1-555-' || lpad((v_idx * 111 + 1000)::TEXT, 4, '0') || '''';
        END IF;

        -- Color
        IF p_column_name = 'color' THEN
            RETURN '''' || v_colors[1 + (v_idx % array_length(v_colors, 1))] || '''';
        END IF;

        -- Icon
        IF p_column_name = 'icon' THEN
            RETURN '''' || v_icons[1 + (v_idx % array_length(v_icons, 1))] || '''';
        END IF;

        -- Category
        IF p_column_name = 'category' THEN
            RETURN '''' || (ARRAY['sales','engineering','hr','marketing','finance','operations','support'])[1 + (v_idx % 7)] || '''';
        END IF;

        -- Currency
        IF p_column_name = 'currency' THEN RETURN '''USD'''; END IF;

        -- Provider columns
        IF p_column_name = 'provider' AND p_table_name = 'oauth_accounts' THEN
            RETURN '''' || (ARRAY['42','google','github'])[1 + (v_idx % 3)] || '''';
        END IF;
        IF p_column_name = 'provider_id' THEN
            RETURN '''' || 'provider_' || v_idx || '_' || md5(v_idx::TEXT) || '''';
        END IF;

        -- External IDs — always fill
        IF p_column_name LIKE 'external_%' THEN
            RETURN '''' || 'ext_' || p_column_name || '_' || v_idx || '''';
        END IF;

        -- Invoice number
        IF p_column_name = 'invoice_number' THEN
            RETURN '''' || 'INV-2025-' || lpad(v_idx::TEXT, 4, '0') || '''';
        END IF;

        -- Promotion code
        IF p_column_name = 'code' THEN
            RETURN '''' || 'PROMO' || upper(v_words[(v_ci % 30) + 1]) || v_idx || '''';
        END IF;

        -- Event type
        IF p_column_name = 'event_type' THEN
            RETURN '''' || (ARRAY['record.created','record.updated','record.deleted','view.changed','dashboard.updated','member.added'])[1 + (v_idx % 6)] || '''';
        END IF;

        -- Title
        IF p_column_name = 'title' THEN
            RETURN '''' || 'Notification: ' || v_words[(v_ci % 30) + 1] || ' event #' || v_idx || '''';
        END IF;

        -- Message / content / notes — always fill for quality data
        IF p_column_name IN ('message', 'content', 'notes', 'change_summary') THEN
            RETURN '''' || 'Auto-generated ' || p_column_name || ' for ' || p_table_name || ' row ' || v_idx || '.''';
        END IF;

        -- Response body
        IF p_column_name = 'response_body' THEN
            RETURN '''' || '{"status":"ok","mock":true}''';
        END IF;

        -- Label / value for field_options
        IF p_column_name = 'label' THEN
            RETURN '''' || 'Option ' || v_words[(v_ci % 30) + 1] || '''';
        END IF;
        IF p_column_name = 'value' AND p_table_name = 'field_options' THEN
            RETURN '''' || v_words[(v_ci % 30) + 1] || '_' || v_idx || '''';
        END IF;

        -- User agent
        IF p_column_name = 'user_agent' THEN
            RETURN '''' || 'Mozilla/5.0 (MockSeed/' || v_idx || ')''';
        END IF;

        -- Source path
        IF p_column_name = 'source_path' THEN
            RETURN '''' || (ARRAY['public.orders','public.customers','users','products','transactions','inventory'])[1 + (v_idx % 6)] || '''';
        END IF;
        IF p_column_name = 'source_schema' THEN
            RETURN '''public''';
        END IF;

        -- Filename / stored_name / storage_path / mime_type
        IF p_column_name = 'filename' THEN
            RETURN '''' || 'file_' || v_idx || '.' || (ARRAY['pdf','png','csv','xlsx','json'])[1 + (v_idx % 5)] || '''';
        END IF;
        IF p_column_name = 'stored_name' THEN
            RETURN '''' || md5(v_idx::TEXT || 'stored') || '.' || (ARRAY['pdf','png','csv','xlsx','json'])[1 + (v_idx % 5)] || '''';
        END IF;
        IF p_column_name = 'storage_path' THEN
            RETURN '''' || 'uploads/org/' || v_idx || '/' || md5(v_idx::TEXT) || '''';
        END IF;
        IF p_column_name = 'mime_type' THEN
            RETURN '''' || (ARRAY['application/pdf','image/png','text/csv','application/vnd.openxmlformats-officedocument.spreadsheetml.sheet','application/json'])[1 + (v_idx % 5)] || '''';
        END IF;

        -- Attribute key (ABAC)
        IF p_column_name = 'attribute_key' THEN
            RETURN '''' || (ARRAY['user.department','resource.sensitivity','env.ip_range','user.role','resource.visibility','env.time_of_day'])[1 + (v_idx % 6)] || '''';
        END IF;

        -- Failure reason — always fill
        IF p_column_name = 'failure_reason' OR p_column_name = 'last_error' THEN
            RETURN '''' || 'Mock error: simulated failure for row ' || v_idx || '''';
        END IF;

        -- Last status — always fill
        IF p_column_name = 'last_status' THEN
            RETURN '''healthy''';
        END IF;

        -- Feature key
        IF p_column_name = 'feature_key' THEN
            RETURN '''' || (ARRAY['max_members','max_projects','max_workspaces','max_collections','max_records',
                                   'max_adapters','max_storage_mb','max_api_requests_day','sso_enabled','audit_log_days'])[1 + (v_idx % 10)] || '''';
        END IF;

        -- Unit
        IF p_column_name = 'unit' THEN
            RETURN '''' || (ARRAY['bytes','count','requests','members','megabytes','syncs'])[1 + (v_idx % 6)] || '''';
        END IF;

        -- Resource type for permissions
        IF p_column_name = 'resource_type' AND p_table_name = 'permissions' THEN
            RETURN '''' || (ARRAY['dashboard','collection','view','workspace','project','adapter','resource','user','role','billing'])[1 + (v_idx % 10)] || '''';
        END IF;
        IF p_column_name = 'action' AND p_table_name = 'permissions' THEN
            RETURN '''' || (ARRAY['create','read','update','delete','manage','share','publish'])[1 + (v_idx % 7)] || '''';
        END IF;

        -- Type column
        IF p_column_name = 'type' AND p_table_name = 'notifications' THEN
            RETURN '''' || (ARRAY['mention','share','comment','sync_complete','system','invite'])[1 + (v_idx % 6)] || '''';
        END IF;

        -- Sync / connection status columns (VARCHAR(20) safe)
        IF p_column_name IN ('last_sync_status', 'last_status', 'health_status', 'sync_status', 'connection_status') THEN
            RETURN '''' || (ARRAY['success','failed','running','idle','pending','error'])[1 + (v_idx % 6)] || '''';
        END IF;

        -- Generic nullable text — always fill with data for quality seeds
        IF p_is_nullable AND p_column_name NOT IN ('name', 'slug', 'email', 'username') THEN
            RETURN '''' || left(p_column_name, 12) || '_' || v_idx || '''';
        END IF;

        -- Fallback text (truncated for short VARCHAR columns)
        RETURN '''' || left(p_column_name, 12) || '_' || v_idx || '''';
    END IF;

    -- ── JSONB columns ──
    IF p_udt_name = 'jsonb' THEN
        IF p_column_name = 'metadata' THEN RETURN '''{}''::JSONB'; END IF;
        IF p_column_name = 'line_items' THEN RETURN '''[]''::JSONB'; END IF;
        IF p_column_name = 'validation_rules' THEN RETURN '''{}''::JSONB'; END IF;
        IF p_column_name = 'display_config' THEN RETURN '''{}''::JSONB'; END IF;
        IF p_column_name = 'default_value' THEN RETURN '''null''::JSONB'; END IF;
        IF p_column_name = 'template_data' THEN RETURN '''{"widgets":[],"layout":"grid"}''::JSONB'; END IF;
        IF p_column_name = 'conditions' THEN
            RETURN '''{"and":[{"attr":"user.role","op":"eq","val":"member"}]}''::JSONB';
        END IF;
        IF p_column_name = 'attribute_value' THEN
            RETURN '''"engineering"''::JSONB';
        END IF;
        IF p_column_name = 'snapshot' THEN
            RETURN '''{"version":' || (v_idx + 1) || ',"data":"mock_snapshot"}''::JSONB';
        END IF;
        IF p_column_name = 'change_diff' THEN RETURN '''{"mock":"diff_data"}''::JSONB'; END IF;
        IF p_column_name = 'payload' THEN
            RETURN '''{"event":"mock","index":' || v_idx || '}''::JSONB';
        END IF;
        IF p_column_name = 'error_log' THEN RETURN '''[]''::JSONB'; END IF;
        IF p_column_name = 'headers' THEN RETURN '''{}''::JSONB'; END IF;
        IF p_column_name IN ('connection_config', 'network_config', 'schema_cache') THEN
            RETURN '''{}''::JSONB';
        END IF;
        IF p_column_name IN ('provider_config', 'provider_metadata', 'resource_limits', 'backup_config') THEN
            RETURN '''{}''::JSONB';
        END IF;
        IF p_column_name IN ('field_mappings', 'transform_rules', 'filter_conditions') THEN
            RETURN '''{}''::JSONB';
        END IF;
        RETURN '''{}''::JSONB';
    END IF;

    -- ── INET columns ──
    IF p_udt_name = 'inet' THEN
        RETURN '''' || '192.168.1.' || (v_idx % 254 + 1) || '''::INET';
    END IF;

    -- ── ARRAY columns ──
    IF p_data_type = 'ARRAY' THEN
        IF p_column_name = 'scopes' THEN
            RETURN 'ARRAY[''collection:read'',''dashboard:read'']::VARCHAR[]';
        END IF;
        IF p_column_name = 'events' THEN
            RETURN 'ARRAY[''record.created'',''record.updated'']::VARCHAR[]';
        END IF;
        IF p_column_name = 'actions' THEN
            RETURN 'ARRAY[''read'']::VARCHAR[]';
        END IF;
        IF p_column_name = 'permissions' AND p_table_name = 'resource_shares' THEN
            RETURN 'ARRAY[''read'']::VARCHAR[]';
        END IF;
        IF p_column_name = 'field_slugs' THEN
            RETURN 'ARRAY[''field_' || v_idx || ''',''status'']::TEXT[]';
        END IF;
        RETURN 'ARRAY[]::TEXT[]';
    END IF;

    -- ── Fallback ──
    RETURN 'NULL';
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- Core: Build topological order of tables respecting FK dependencies
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_get_table_insert_order()
RETURNS TABLE(table_name TEXT, table_order INT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_changed BOOLEAN := TRUE;
    v_iter INT := 0;
BEGIN
    -- Temp table for ordering
    CREATE TEMP TABLE IF NOT EXISTS _topo_order (
        tname TEXT PRIMARY KEY,
        torder INT NOT NULL DEFAULT 0
    );
    TRUNCATE _topo_order;

    -- All public tables
    INSERT INTO _topo_order (tname)
    SELECT t.table_name::TEXT
    FROM information_schema.tables t
    WHERE t.table_schema = 'public'
      AND t.table_type = 'BASE TABLE';

    -- Iteratively increase order based on FK references
    WHILE v_changed AND v_iter < 20 LOOP
        v_changed := FALSE;
        v_iter := v_iter + 1;

        UPDATE _topo_order AS target
        SET torder = sub.new_order
        FROM (
            SELECT
                tc.table_name::TEXT AS tname,
                MAX(ref.torder) + 1 AS new_order
            FROM information_schema.table_constraints tc
            JOIN information_schema.constraint_column_usage ccu
                ON ccu.constraint_name = tc.constraint_name
                AND ccu.table_schema = tc.table_schema
            JOIN _topo_order ref ON ref.tname = ccu.table_name::TEXT
            WHERE tc.constraint_type = 'FOREIGN KEY'
              AND tc.table_schema = 'public'
              AND ccu.table_name::TEXT != tc.table_name::TEXT  -- skip self-refs
            GROUP BY tc.table_name::TEXT
        ) sub
        WHERE target.tname = sub.tname
          AND sub.new_order > target.torder;

        IF FOUND THEN
            v_changed := TRUE;
        END IF;
    END LOOP;

    RETURN QUERY
    SELECT _topo_order.tname, _topo_order.torder
    FROM _topo_order
    ORDER BY _topo_order.torder, _topo_order.tname;

    DROP TABLE _topo_order;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- Core: Get FK references for a table (which columns reference which tables)
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_get_fk_map(p_table TEXT)
RETURNS TABLE(
    column_name TEXT,
    referenced_table TEXT,
    referenced_column TEXT,
    is_self_ref BOOLEAN
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        kcu.column_name::TEXT,
        ccu.table_name::TEXT AS referenced_table,
        ccu.column_name::TEXT AS referenced_column,
        (kcu.table_name::TEXT = ccu.table_name::TEXT) AS is_self_ref
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON kcu.constraint_name = tc.constraint_name
        AND kcu.table_schema = tc.table_schema
    JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public'
      AND tc.table_name::TEXT = p_table;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- Core: Get CHECK constraint values for columns in a table
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_get_check_constraints(p_table TEXT)
RETURNS TABLE(column_name TEXT, allowed_values TEXT[])
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        ccu.column_name::TEXT,
        fn_extract_check_values(cc.check_clause::TEXT) AS allowed_values
    FROM information_schema.table_constraints tc
    JOIN information_schema.check_constraints cc
        ON cc.constraint_name = tc.constraint_name
        AND cc.constraint_schema = tc.constraint_schema
    JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'CHECK'
      AND tc.table_schema = 'public'
      AND tc.table_name::TEXT = p_table
      AND array_length(fn_extract_check_values(cc.check_clause::TEXT), 1) > 0;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- Main: Auto-seed all tables
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION auto_seed_all(
    rows_per_table INT DEFAULT 5,
    target_schema TEXT DEFAULT 'public'
)
RETURNS TABLE(seeded_table TEXT, rows_inserted INT, status TEXT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_table RECORD;
    v_col RECORD;
    v_fk RECORD;
    v_check RECORD;
    v_sql TEXT;
    v_columns TEXT;
    v_values TEXT;
    v_row INT;
    v_fk_value TEXT;
    v_check_values TEXT[];
    v_col_list TEXT[];
    v_val_list TEXT[];
    v_inserted INT;
    v_has_composite_pk BOOLEAN;
    v_pk_cols TEXT[];
    v_is_junction BOOLEAN;
    v_fk_map RECORD;
    v_skip_table BOOLEAN;
    v_error TEXT;
    v_actual_rows INT;
    v_ref_count INT;
    -- Polymorphic resolution variables
    v_type_col TEXT;
    v_type_val TEXT;
    v_poly_table TEXT;
    v_poly_uuid TEXT;
    v_poly_count INT;
    i INT;
BEGIN
    -- ── Create temp table for FK reference cache ──
    CREATE TEMP TABLE IF NOT EXISTS _fk_cache (
        src_table TEXT,
        src_column TEXT,
        ref_table TEXT,
        ref_column TEXT,
        is_self BOOLEAN
    );
    TRUNCATE _fk_cache;

    CREATE TEMP TABLE IF NOT EXISTS _check_cache (
        src_table TEXT,
        col_name TEXT,
        vals TEXT[]
    );
    TRUNCATE _check_cache;

    CREATE TEMP TABLE IF NOT EXISTS _seed_results (
        tbl TEXT,
        cnt INT,
        stat TEXT
    );
    TRUNCATE _seed_results;

    -- ── Pre-cache all FK relationships ──
    INSERT INTO _fk_cache (src_table, src_column, ref_table, ref_column, is_self)
    SELECT
        kcu.table_name::TEXT,
        kcu.column_name::TEXT,
        ccu.table_name::TEXT,
        ccu.column_name::TEXT,
        (kcu.table_name::TEXT = ccu.table_name::TEXT)
    FROM information_schema.table_constraints tc
    JOIN information_schema.key_column_usage kcu
        ON kcu.constraint_name = tc.constraint_name
        AND kcu.table_schema = tc.table_schema
    JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'FOREIGN KEY'
      AND tc.table_schema = 'public';

    -- ── Pre-cache CHECK constraints ──
    INSERT INTO _check_cache (src_table, col_name, vals)
    SELECT
        tc.table_name::TEXT,
        ccu.column_name::TEXT,
        fn_extract_check_values(cc.check_clause::TEXT)
    FROM information_schema.table_constraints tc
    JOIN information_schema.check_constraints cc
        ON cc.constraint_name = tc.constraint_name
        AND cc.constraint_schema = tc.constraint_schema
    JOIN information_schema.constraint_column_usage ccu
        ON ccu.constraint_name = tc.constraint_name
        AND ccu.table_schema = tc.table_schema
    WHERE tc.constraint_type = 'CHECK'
      AND tc.table_schema = 'public'
      AND array_length(fn_extract_check_values(cc.check_clause::TEXT), 1) > 0;

    -- ── Iterate tables in topological (FK-dependency) order ──
    FOR v_table IN
        SELECT t.table_name AS tname, t.table_order AS torder
        FROM fn_get_table_insert_order() t
    LOOP
        v_skip_table := FALSE;

        -- ── Skip tables already populated by static seeds ──
        EXECUTE format('SELECT COUNT(*)::INT FROM %I', v_table.tname) INTO v_ref_count;
        IF v_ref_count >= rows_per_table THEN
            INSERT INTO _seed_results VALUES (v_table.tname, v_ref_count, 'ALREADY SEEDED');
            CONTINUE;
        END IF;

        -- Determine how many rows to insert (fewer for junction tables)
        -- Check if table has a composite PK (junction table indicator)
        SELECT array_agg(kcu.column_name::TEXT ORDER BY kcu.ordinal_position)
        INTO v_pk_cols
        FROM information_schema.table_constraints tc
        JOIN information_schema.key_column_usage kcu
            ON kcu.constraint_name = tc.constraint_name
            AND kcu.table_schema = tc.table_schema
        WHERE tc.constraint_type = 'PRIMARY KEY'
          AND tc.table_schema = 'public'
          AND tc.table_name::TEXT = v_table.tname;

        v_is_junction := (array_length(v_pk_cols, 1) > 1);

        -- For junction tables, use fewer rows but ensure we have referenced data
        v_actual_rows := CASE WHEN v_is_junction THEN LEAST(rows_per_table, 3) ELSE rows_per_table END;

        -- ── Generate and insert rows ──
        FOR v_row IN 0..(v_actual_rows - 1) LOOP
            v_col_list := ARRAY[]::TEXT[];
            v_val_list := ARRAY[]::TEXT[];

            FOR v_col IN
                SELECT
                    c.column_name::TEXT AS cname,
                    c.data_type::TEXT AS dtype,
                    c.udt_name::TEXT AS uname,
                    (c.is_nullable = 'YES') AS nullable,
                    (c.column_default IS NOT NULL) AS has_default,
                    c.column_default::TEXT AS col_default
                FROM information_schema.columns c
                WHERE c.table_schema = 'public'
                  AND c.table_name::TEXT = v_table.tname
                ORDER BY c.ordinal_position
            LOOP
                -- Skip auto-generated columns
                IF v_col.col_default LIKE '%gen_random_uuid()%'
                   OR v_col.col_default LIKE '%uuid_generate%' THEN
                    -- It's a PK with auto UUID — skip unless it's a composite PK column
                    IF v_col.cname = ANY(v_pk_cols) AND NOT v_is_junction THEN
                        CONTINUE;
                    END IF;
                END IF;

                -- Check if it's a FK column
                SELECT fc.ref_table, fc.ref_column, fc.is_self
                INTO v_fk_map
                FROM _fk_cache fc
                WHERE fc.src_table = v_table.tname
                  AND fc.src_column = v_col.cname
                LIMIT 1;

                IF FOUND THEN
                    -- It's a FK column — resolve reference
                    IF v_fk_map.is_self THEN
                        -- Self-reference: NULL for first rows, then reference earlier rows
                        IF v_row = 0 OR v_col.nullable THEN
                            v_fk_value := 'NULL';
                        ELSE
                            EXECUTE format(
                                'SELECT %I::TEXT FROM %I ORDER BY ctid LIMIT 1',
                                v_fk_map.ref_column, v_fk_map.ref_table
                            ) INTO v_fk_value;
                            IF v_fk_value IS NULL THEN
                                v_fk_value := 'NULL';
                            ELSE
                                v_fk_value := '''' || v_fk_value || '''';
                            END IF;
                        END IF;
                    ELSE
                        -- Reference to another table — pick a random existing row
                        -- Check if referenced table has data
                        EXECUTE format(
                            'SELECT COUNT(*)::INT FROM %I',
                            v_fk_map.ref_table
                        ) INTO v_ref_count;

                        IF v_ref_count = 0 THEN
                            -- Referenced table is empty
                            IF v_col.nullable THEN
                                v_fk_value := 'NULL';
                            ELSE
                                -- Can't satisfy FK — skip the whole table for now
                                v_skip_table := TRUE;
                                EXIT;
                            END IF;
                        ELSE
                            -- Pick a row (cycle through available rows)
                            -- For resource_relations.target, shift offset to avoid self-ref
                            IF v_table.tname = 'resource_relations' AND v_col.cname = 'target_resource_id' AND v_ref_count > 1 THEN
                                EXECUTE format(
                                    'SELECT %I::TEXT FROM %I ORDER BY ctid OFFSET %s LIMIT 1',
                                    v_fk_map.ref_column, v_fk_map.ref_table,
                                    (v_row + 1) % v_ref_count
                                ) INTO v_fk_value;
                            ELSE
                                EXECUTE format(
                                    'SELECT %I::TEXT FROM %I ORDER BY ctid OFFSET %s LIMIT 1',
                                    v_fk_map.ref_column, v_fk_map.ref_table,
                                    v_row % v_ref_count
                                ) INTO v_fk_value;
                            END IF;
                            v_fk_value := '''' || v_fk_value || '''';
                        END IF;
                    END IF;

                    v_col_list := array_append(v_col_list, v_col.cname);
                    v_val_list := array_append(v_val_list, v_fk_value);
                    CONTINUE;
                END IF;

                -- ── Polymorphic UUID resolution ──
                -- These columns are UUID-typed but have no FK constraint because
                -- they can point to different tables depending on a sibling *_type column.
                IF v_col.uname = 'uuid' AND v_col.cname IN ('grantee_id', 'context_id') THEN
                    -- Resolve polymorphic UUID based on sibling *_type column
                    v_type_col := NULL;
                    v_type_val := NULL;
                    v_poly_table := NULL;

                    IF v_col.cname = 'grantee_id' THEN
                        v_type_col := 'grantee_type';
                    ELSIF v_col.cname = 'context_id' THEN
                        v_type_col := 'context_type';
                    END IF;

                    -- Find sibling type value in the already-built val list
                    IF v_type_col IS NOT NULL AND array_length(v_col_list, 1) > 0 THEN
                        FOR i IN 1..array_length(v_col_list, 1) LOOP
                            IF v_col_list[i] = v_type_col THEN
                                v_type_val := trim(both '''' from v_val_list[i]);
                                EXIT;
                            END IF;
                        END LOOP;
                    END IF;

                    -- Map type to source table
                    IF v_type_val IS NOT NULL AND v_type_val != 'NULL' THEN
                        v_poly_table := CASE v_type_val
                            WHEN 'user' THEN 'users'
                            WHEN 'role' THEN 'roles'
                            WHEN 'team' THEN 'organizations'
                            WHEN 'global' THEN NULL
                            WHEN 'organization' THEN 'organizations'
                            WHEN 'project' THEN 'projects'
                            WHEN 'workspace' THEN 'workspaces'
                            ELSE NULL
                        END;
                    END IF;

                    IF v_poly_table IS NOT NULL THEN
                        EXECUTE format('SELECT COUNT(*)::INT FROM %I', v_poly_table) INTO v_poly_count;
                        IF v_poly_count > 0 THEN
                            EXECUTE format(
                                'SELECT id::TEXT FROM %I ORDER BY ctid OFFSET %s LIMIT 1',
                                v_poly_table, v_row % v_poly_count
                            ) INTO v_poly_uuid;
                            v_col_list := array_append(v_col_list, v_col.cname);
                            v_val_list := array_append(v_val_list, '''' || v_poly_uuid || '''');
                            CONTINUE;
                        END IF;
                    END IF;

                    -- Fallback
                    IF v_col.nullable THEN
                        v_col_list := array_append(v_col_list, v_col.cname);
                        v_val_list := array_append(v_val_list, 'NULL');
                        CONTINUE;
                    ELSE
                        v_col_list := array_append(v_col_list, v_col.cname);
                        v_val_list := array_append(v_val_list, '''' || gen_random_uuid()::TEXT || '''');
                        CONTINUE;
                    END IF;
                END IF;

                -- Skip columns that have a DEFAULT and are auto-managed
                IF v_col.has_default AND v_col.cname IN ('created_at', 'updated_at', 'assigned_at',
                    'granted_at', 'joined_at', 'recorded_at', 'delivered_at') THEN
                    CONTINUE;
                END IF;

                -- Get CHECK constraint values
                SELECT cc.vals INTO v_check_values
                FROM _check_cache cc
                WHERE cc.src_table = v_table.tname
                  AND cc.col_name = v_col.cname
                LIMIT 1;
                IF NOT FOUND THEN
                    v_check_values := ARRAY[]::TEXT[];
                END IF;

                -- Generate mock value
                v_fk_value := fn_generate_mock_value(
                    v_col.cname,
                    v_col.dtype,
                    v_col.uname,
                    v_col.nullable,
                    v_col.has_default,
                    v_check_values,
                    v_row,
                    v_table.tname
                );

                -- If NULL and column has a default, skip it entirely
                IF v_fk_value IS NULL OR v_fk_value = 'NULL' THEN
                    IF v_col.has_default THEN
                        CONTINUE;
                    ELSIF v_col.nullable THEN
                        v_col_list := array_append(v_col_list, v_col.cname);
                        v_val_list := array_append(v_val_list, 'NULL');
                        CONTINUE;
                    ELSE
                        -- Non-nullable, no default, no FK — use generic fallback
                        IF v_col.uname = 'uuid' THEN
                            v_col_list := array_append(v_col_list, v_col.cname);
                            v_val_list := array_append(v_val_list, '''' || gen_random_uuid()::TEXT || '''');
                        ELSE
                            v_col_list := array_append(v_col_list, v_col.cname);
                            v_val_list := array_append(v_val_list, '''' || v_col.cname || '_' || v_row || '''');
                        END IF;
                        CONTINUE;
                    END IF;
                END IF;

                v_col_list := array_append(v_col_list, v_col.cname);
                v_val_list := array_append(v_val_list, v_fk_value);
            END LOOP;

            IF v_skip_table THEN
                EXIT; -- Break out of row loop
            END IF;

            -- ── Post-processing: user_role_assignments scope matching ──
            -- The trigger requires role.scope == context_type and context_id
            -- to reference a real entity matching that scope.
            IF v_table.tname = 'user_role_assignments' AND array_length(v_col_list, 1) > 0 THEN
                -- Find role_id value in the built val_list
                v_type_val := NULL;  -- reuse: role_id value
                v_type_col := NULL;  -- reuse: role scope
                FOR i IN 1..array_length(v_col_list, 1) LOOP
                    IF v_col_list[i] = 'role_id' THEN
                        v_type_val := trim(both '''' from v_val_list[i]);
                        EXIT;
                    END IF;
                END LOOP;

                -- Look up this role's scope
                IF v_type_val IS NOT NULL THEN
                    EXECUTE format(
                        'SELECT scope FROM roles WHERE id = %L',
                        v_type_val
                    ) INTO v_type_col;
                END IF;

                IF v_type_col IS NOT NULL THEN
                    -- Override context_type to match role scope
                    FOR i IN 1..array_length(v_col_list, 1) LOOP
                        IF v_col_list[i] = 'context_type' THEN
                            v_val_list[i] := '''' || v_type_col || '''';
                            EXIT;
                        END IF;
                    END LOOP;

                    -- Determine context table and resolve context_id
                    v_poly_table := CASE v_type_col
                        WHEN 'organization' THEN 'organizations'
                        WHEN 'project' THEN 'projects'
                        WHEN 'workspace' THEN 'workspaces'
                        WHEN 'global' THEN NULL
                        ELSE NULL
                    END;

                    IF v_poly_table IS NOT NULL THEN
                        EXECUTE format('SELECT COUNT(*)::INT FROM %I', v_poly_table) INTO v_poly_count;
                        IF v_poly_count > 0 THEN
                            EXECUTE format(
                                'SELECT id::TEXT FROM %I ORDER BY ctid OFFSET %s LIMIT 1',
                                v_poly_table, v_row % v_poly_count
                            ) INTO v_poly_uuid;
                            FOR i IN 1..array_length(v_col_list, 1) LOOP
                                IF v_col_list[i] = 'context_id' THEN
                                    v_val_list[i] := '''' || v_poly_uuid || '''';
                                    EXIT;
                                END IF;
                            END LOOP;
                        END IF;
                    ELSE
                        -- global scope: set context_id to NULL
                        FOR i IN 1..array_length(v_col_list, 1) LOOP
                            IF v_col_list[i] = 'context_id' THEN
                                v_val_list[i] := 'NULL';
                                EXIT;
                            END IF;
                        END LOOP;
                    END IF;
                END IF;
            END IF;

            -- Build and execute INSERT with ON CONFLICT DO NOTHING
            IF array_length(v_col_list, 1) > 0 THEN
                v_sql := format(
                    'INSERT INTO %I (%s) VALUES (%s) ON CONFLICT DO NOTHING',
                    v_table.tname,
                    array_to_string(v_col_list, ', '),
                    array_to_string(v_val_list, ', ')
                );

                BEGIN
                    EXECUTE v_sql;
                    GET DIAGNOSTICS v_inserted = ROW_COUNT;
                EXCEPTION WHEN OTHERS THEN
                    GET STACKED DIAGNOSTICS v_error = MESSAGE_TEXT;
                    -- Log the error but continue with other rows
                    RAISE NOTICE 'SEED WARN [%.row%]: % | SQL: %',
                        v_table.tname, v_row, v_error, left(v_sql, 200);
                END;
            END IF;
        END LOOP;

        IF v_skip_table THEN
            INSERT INTO _seed_results VALUES (v_table.tname, 0, 'SKIPPED (missing FK data)');
        ELSE
            -- Count actual rows
            EXECUTE format('SELECT COUNT(*)::INT FROM %I', v_table.tname) INTO v_inserted;
            INSERT INTO _seed_results VALUES (v_table.tname, v_inserted, 'OK');
        END IF;

        v_inserted := 0;
    END LOOP;

    -- Return results
    RETURN QUERY SELECT r.tbl, r.cnt, r.stat FROM _seed_results r ORDER BY r.tbl;

    -- Cleanup
    DROP TABLE IF EXISTS _fk_cache;
    DROP TABLE IF EXISTS _check_cache;
    DROP TABLE IF EXISTS _seed_results;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- Utility: Show table row counts
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_table_row_counts()
RETURNS TABLE(table_name TEXT, row_count BIGINT)
LANGUAGE plpgsql
AS $$
DECLARE
    v_tbl TEXT;
    v_cnt BIGINT;
BEGIN
    FOR v_tbl IN
        SELECT t.table_name::TEXT
        FROM information_schema.tables t
        WHERE t.table_schema = 'public'
          AND t.table_type = 'BASE TABLE'
        ORDER BY t.table_name
    LOOP
        EXECUTE format('SELECT COUNT(*) FROM %I', v_tbl) INTO v_cnt;
        table_name := v_tbl;
        row_count := v_cnt;
        RETURN NEXT;
    END LOOP;
END;
$$;


-- ─────────────────────────────────────────────────────────────────────────────
-- Utility: Display table topological order
-- ─────────────────────────────────────────────────────────────────────────────
CREATE OR REPLACE FUNCTION fn_show_insert_order()
RETURNS TABLE(table_name TEXT, dependency_level INT, fk_references TEXT)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT
        t.table_name,
        t.table_order,
        COALESCE(
            string_agg(DISTINCT fk.ref_table || '.' || fk.ref_column, ', '),
            '(none)'
        ) AS fk_references
    FROM fn_get_table_insert_order() t
    LEFT JOIN LATERAL (
        SELECT fc.column_name AS src_col, fc.referenced_table AS ref_table, fc.referenced_column AS ref_column
        FROM fn_get_fk_map(t.table_name) fc
        WHERE NOT fc.is_self_ref
    ) fk ON TRUE
    GROUP BY t.table_name, t.table_order
    ORDER BY t.table_order, t.table_name;
END;
$$;
