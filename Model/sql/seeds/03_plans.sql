-- ============================================================================
-- seeds/03_plans.sql — Subscription Plans (seeded before auto-seed)
-- ============================================================================
-- Platform-defined billing plans. Must exist before organizations can
-- subscribe and before plan_features can reference them.
-- ============================================================================

INSERT INTO plans (slug, name, description, price_monthly, price_yearly, currency, trial_days, is_public, is_active, sort_order, metadata) VALUES
    ('free',       'Free',       'Free tier with basic features',             0,      0,      'USD', 0,  TRUE, TRUE, 0, '{"support_level":"community"}'),
    ('starter',    'Starter',    'For small teams getting started',           1900,   19000,  'USD', 14, TRUE, TRUE, 1, '{"support_level":"email"}'),
    ('pro',        'Pro',        'For growing teams with advanced needs',     4900,   49000,  'USD', 14, TRUE, TRUE, 2, '{"support_level":"priority"}'),
    ('enterprise', 'Enterprise', 'Custom enterprise plan with dedicated support', 14900, 149000, 'USD', 30, FALSE, TRUE, 3, '{"support_level":"dedicated","sla":"99.9%"}')
ON CONFLICT (slug) DO NOTHING;

-- Plan features for each plan
-- Free plan limits
INSERT INTO plan_features (plan_id, feature_key, limit_value, description) VALUES
    ((SELECT id FROM plans WHERE slug = 'free'), 'max_members',              5,     'Maximum org members'),
    ((SELECT id FROM plans WHERE slug = 'free'), 'max_projects',             2,     'Maximum projects per org'),
    ((SELECT id FROM plans WHERE slug = 'free'), 'max_workspaces',           3,     'Maximum workspaces per project'),
    ((SELECT id FROM plans WHERE slug = 'free'), 'max_collections',          10,    'Maximum collections per workspace'),
    ((SELECT id FROM plans WHERE slug = 'free'), 'max_records',              1000,  'Maximum records across all collections'),
    ((SELECT id FROM plans WHERE slug = 'free'), 'max_adapters',             1,     'Maximum active adapters'),
    ((SELECT id FROM plans WHERE slug = 'free'), 'max_storage_mb',           100,   'Maximum file storage in MB'),
    ((SELECT id FROM plans WHERE slug = 'free'), 'sso_enabled',              0,     'SSO authentication'),
    ((SELECT id FROM plans WHERE slug = 'free'), 'audit_log_days',           7,     'Audit log retention days'),
    ((SELECT id FROM plans WHERE slug = 'free'), 'realtime_sync',            0,     'Real-time CDC sync')
ON CONFLICT (plan_id, feature_key) DO NOTHING;

-- Starter plan limits
INSERT INTO plan_features (plan_id, feature_key, limit_value, description) VALUES
    ((SELECT id FROM plans WHERE slug = 'starter'), 'max_members',           20,    'Maximum org members'),
    ((SELECT id FROM plans WHERE slug = 'starter'), 'max_projects',          10,    'Maximum projects per org'),
    ((SELECT id FROM plans WHERE slug = 'starter'), 'max_workspaces',        10,    'Maximum workspaces per project'),
    ((SELECT id FROM plans WHERE slug = 'starter'), 'max_collections',       50,    'Maximum collections per workspace'),
    ((SELECT id FROM plans WHERE slug = 'starter'), 'max_records',           10000, 'Maximum records across all collections'),
    ((SELECT id FROM plans WHERE slug = 'starter'), 'max_adapters',          5,     'Maximum active adapters'),
    ((SELECT id FROM plans WHERE slug = 'starter'), 'max_storage_mb',        1000,  'Maximum file storage in MB'),
    ((SELECT id FROM plans WHERE slug = 'starter'), 'sso_enabled',           0,     'SSO authentication'),
    ((SELECT id FROM plans WHERE slug = 'starter'), 'audit_log_days',        30,    'Audit log retention days'),
    ((SELECT id FROM plans WHERE slug = 'starter'), 'realtime_sync',         1,     'Real-time CDC sync')
ON CONFLICT (plan_id, feature_key) DO NOTHING;

-- Pro plan limits
INSERT INTO plan_features (plan_id, feature_key, limit_value, description) VALUES
    ((SELECT id FROM plans WHERE slug = 'pro'), 'max_members',               100,   'Maximum org members'),
    ((SELECT id FROM plans WHERE slug = 'pro'), 'max_projects',              50,    'Maximum projects per org'),
    ((SELECT id FROM plans WHERE slug = 'pro'), 'max_workspaces',            50,    'Maximum workspaces per project'),
    ((SELECT id FROM plans WHERE slug = 'pro'), 'max_collections',           500,   'Maximum collections per workspace'),
    ((SELECT id FROM plans WHERE slug = 'pro'), 'max_records',               100000,'Maximum records across all collections'),
    ((SELECT id FROM plans WHERE slug = 'pro'), 'max_adapters',              20,    'Maximum active adapters'),
    ((SELECT id FROM plans WHERE slug = 'pro'), 'max_storage_mb',            10000, 'Maximum file storage in MB'),
    ((SELECT id FROM plans WHERE slug = 'pro'), 'sso_enabled',               1,     'SSO authentication'),
    ((SELECT id FROM plans WHERE slug = 'pro'), 'audit_log_days',            90,    'Audit log retention days'),
    ((SELECT id FROM plans WHERE slug = 'pro'), 'realtime_sync',             1,     'Real-time CDC sync')
ON CONFLICT (plan_id, feature_key) DO NOTHING;

-- Enterprise plan limits (NULL = unlimited)
INSERT INTO plan_features (plan_id, feature_key, limit_value, description) VALUES
    ((SELECT id FROM plans WHERE slug = 'enterprise'), 'max_members',        NULL,  'Unlimited org members'),
    ((SELECT id FROM plans WHERE slug = 'enterprise'), 'max_projects',       NULL,  'Unlimited projects'),
    ((SELECT id FROM plans WHERE slug = 'enterprise'), 'max_workspaces',     NULL,  'Unlimited workspaces'),
    ((SELECT id FROM plans WHERE slug = 'enterprise'), 'max_collections',    NULL,  'Unlimited collections'),
    ((SELECT id FROM plans WHERE slug = 'enterprise'), 'max_records',        NULL,  'Unlimited records'),
    ((SELECT id FROM plans WHERE slug = 'enterprise'), 'max_adapters',       NULL,  'Unlimited adapters'),
    ((SELECT id FROM plans WHERE slug = 'enterprise'), 'max_storage_mb',     NULL,  'Unlimited storage'),
    ((SELECT id FROM plans WHERE slug = 'enterprise'), 'sso_enabled',        1,     'SSO authentication'),
    ((SELECT id FROM plans WHERE slug = 'enterprise'), 'audit_log_days',     365,   'Audit log retention days'),
    ((SELECT id FROM plans WHERE slug = 'enterprise'), 'realtime_sync',      1,     'Real-time CDC sync')
ON CONFLICT (plan_id, feature_key) DO NOTHING;

\echo '✓ Plans and features seeded.'
