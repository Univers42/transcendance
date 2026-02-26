-- ============================================================================
-- seeds/04_usage_meters.sql — Usage Meters (seeded before auto-seed)
-- ============================================================================
-- Platform-defined usage dimensions for metering and quota enforcement.
-- ============================================================================

INSERT INTO usage_meters (slug, name, description, unit, aggregation, reset_period) VALUES
    ('storage_bytes',    'Storage Usage',     'Total storage used across all files',          'bytes',    'gauge',   'never'),
    ('api_requests',     'API Requests',      'Number of API calls per billing cycle',        'requests', 'sum',     'billing_cycle'),
    ('record_count',     'Record Count',      'Total records across all collections',         'count',    'gauge',   'never'),
    ('active_members',   'Active Members',    'Current active organization member count',     'count',    'gauge',   'never'),
    ('bandwidth_bytes',  'Bandwidth',         'Total data transfer in bytes',                 'bytes',    'sum',     'billing_cycle'),
    ('adapter_syncs',    'Adapter Syncs',     'Number of adapter sync executions',            'count',    'sum',     'billing_cycle')
ON CONFLICT (slug) DO NOTHING;

\echo '✓ Usage meters seeded.'
