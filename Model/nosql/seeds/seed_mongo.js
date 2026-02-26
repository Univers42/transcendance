// ============================================================================
// seed_mongo.js — MongoDB Seed Data for Transcendence
// ============================================================================
// Seeds all 13 MongoDB collections with demo data that aligns with the
// PostgreSQL seeds (users, organizations, ABAC rules).
//
// Usage: mongosh mongodb://localhost:27017/transcendence seed_mongo.js
//        — OR —
//        mongosh --file seed_mongo.js
//
// Idempotent: uses updateOne + upsert for all inserts.
// ============================================================================

const DB_NAME = 'transcendence';
const db = db.getSiblingDB(DB_NAME); // eslint-disable-line no-undef

print('');
print('════════════════════════════════════════════════════════════════');
print('  MONGODB SEED — Transcendence Demo Data');
print('════════════════════════════════════════════════════════════════');
print('');

const now = new Date();
const iso = (d) => new Date(d);

// ── Helper: bulk upsert by a key field ──────────────────────────────────────

function upsertMany(collName, docs, keyFields) {
  const coll = db[collName];
  let inserted = 0;
  let updated = 0;
  for (const doc of docs) {
    const filter = {};
    for (const k of keyFields) {
      filter[k] = doc[k];
    }
    const result = coll.updateOne(filter, { $set: doc }, { upsert: true });
    if (result.upsertedCount > 0) inserted++;
    else if (result.modifiedCount > 0) updated++;
  }
  print(
    '  ' +
      collName.padEnd(28) +
      inserted +
      ' inserted, ' +
      updated +
      ' updated  (total: ' +
      docs.length +
      ')',
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  1. USER PREFERENCES (one per user — 11 demo users)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'user_preferences',
  [
    // ── Platform admins ──
    {
      user_id: 'a0000000-0000-0000-0000-000000000001',
      theme: 'dark',
      accent_color: '#6366f1',
      font_size: 'medium',
      density: 'comfortable',
      locale: 'en-US',
      timezone: 'America/New_York',
      date_format: 'YYYY-MM-DD',
      time_format: '24h',
      first_day_of_week: 'monday',
      notifications: {
        email_enabled: true,
        push_enabled: true,
        digest_frequency: 'daily',
      },
      sidebar: { is_collapsed: false, width: 260, pinned_items: [] },
      recent_items: [],
      favorites: [],
      onboarding: {
        completed: true,
        completed_at: iso('2024-01-15T10:00:00Z'),
      },
      created_at: now,
      updated_at: now,
    },
    {
      user_id: 'a0000000-0000-0000-0000-000000000002',
      theme: 'light',
      font_size: 'medium',
      density: 'comfortable',
      locale: 'en-US',
      timezone: 'America/Chicago',
      date_format: 'MM/DD/YYYY',
      time_format: '12h',
      first_day_of_week: 'sunday',
      notifications: {
        email_enabled: true,
        push_enabled: false,
        digest_frequency: 'weekly',
      },
      sidebar: { is_collapsed: true, width: 240 },
      recent_items: [],
      favorites: [],
      onboarding: { completed: true },
      created_at: now,
      updated_at: now,
    },

    // ── Employees ──
    {
      user_id: 'b0000000-0000-0000-0000-000000000001',
      theme: 'dark',
      accent_color: '#10b981',
      font_size: 'small',
      density: 'compact',
      locale: 'en-US',
      timezone: 'America/Los_Angeles',
      date_format: 'YYYY-MM-DD',
      time_format: '24h',
      first_day_of_week: 'monday',
      notifications: {
        email_enabled: true,
        push_enabled: true,
        digest_frequency: 'instant',
      },
      sidebar: { is_collapsed: false, width: 280 },
      recent_items: [],
      favorites: [],
      onboarding: { completed: true },
      created_at: now,
      updated_at: now,
    },
    {
      user_id: 'b0000000-0000-0000-0000-000000000002',
      theme: 'system',
      font_size: 'medium',
      density: 'comfortable',
      locale: 'en-US',
      timezone: 'America/New_York',
      date_format: 'DD/MM/YYYY',
      time_format: '24h',
      first_day_of_week: 'monday',
      notifications: {
        email_enabled: true,
        push_enabled: true,
        digest_frequency: 'daily',
      },
      sidebar: { is_collapsed: false, width: 260 },
      recent_items: [],
      favorites: [],
      onboarding: { completed: true },
      created_at: now,
      updated_at: now,
    },
    {
      user_id: 'b0000000-0000-0000-0000-000000000003',
      theme: 'light',
      accent_color: '#f59e0b',
      font_size: 'large',
      density: 'spacious',
      locale: 'en-US',
      timezone: 'Europe/London',
      date_format: 'DD/MM/YYYY',
      time_format: '24h',
      first_day_of_week: 'monday',
      notifications: {
        email_enabled: false,
        push_enabled: true,
        digest_frequency: 'weekly',
      },
      sidebar: { is_collapsed: false, width: 300 },
      recent_items: [],
      favorites: [],
      onboarding: { completed: true },
      created_at: now,
      updated_at: now,
    },
    {
      user_id: 'b0000000-0000-0000-0000-000000000004',
      theme: 'dark',
      accent_color: '#ef4444',
      font_size: 'small',
      density: 'compact',
      locale: 'en-US',
      timezone: 'America/Denver',
      date_format: 'YYYY-MM-DD',
      time_format: '24h',
      first_day_of_week: 'monday',
      notifications: {
        email_enabled: true,
        push_enabled: true,
        digest_frequency: 'instant',
        channels: { slack: true, email: true },
      },
      sidebar: { is_collapsed: true, width: 220 },
      recent_items: [],
      favorites: [],
      onboarding: { completed: true },
      created_at: now,
      updated_at: now,
    },

    // ── Tenants / Clients ──
    {
      user_id: 'c0000000-0000-0000-0000-000000000001',
      theme: 'light',
      accent_color: '#3b82f6',
      font_size: 'medium',
      density: 'comfortable',
      locale: 'en-US',
      timezone: 'America/Los_Angeles',
      date_format: 'MM/DD/YYYY',
      time_format: '12h',
      first_day_of_week: 'sunday',
      default_organization_id: 'd0000000-0000-0000-0000-000000000001',
      notifications: {
        email_enabled: true,
        push_enabled: true,
        digest_frequency: 'daily',
      },
      sidebar: { is_collapsed: false, width: 260 },
      recent_items: [],
      favorites: [],
      onboarding: {
        completed: true,
        completed_at: iso('2024-02-01T14:00:00Z'),
      },
      created_at: now,
      updated_at: now,
    },
    {
      user_id: 'c0000000-0000-0000-0000-000000000002',
      theme: 'dark',
      font_size: 'small',
      density: 'compact',
      locale: 'en-US',
      timezone: 'America/Los_Angeles',
      date_format: 'YYYY-MM-DD',
      time_format: '24h',
      first_day_of_week: 'monday',
      default_organization_id: 'd0000000-0000-0000-0000-000000000001',
      notifications: {
        email_enabled: false,
        push_enabled: false,
        digest_frequency: 'never',
      },
      sidebar: { is_collapsed: true, width: 200 },
      recent_items: [],
      favorites: [],
      onboarding: { completed: false, current_step: 3 },
      created_at: now,
      updated_at: now,
    },
    {
      user_id: 'c0000000-0000-0000-0000-000000000003',
      theme: 'system',
      accent_color: '#8b5cf6',
      font_size: 'medium',
      density: 'comfortable',
      locale: 'en-GB',
      timezone: 'Europe/London',
      date_format: 'DD/MM/YYYY',
      time_format: '24h',
      first_day_of_week: 'monday',
      default_organization_id: 'd0000000-0000-0000-0000-000000000002',
      notifications: {
        email_enabled: true,
        push_enabled: true,
        digest_frequency: 'daily',
      },
      sidebar: { is_collapsed: false, width: 260 },
      recent_items: [],
      favorites: [],
      onboarding: { completed: true },
      created_at: now,
      updated_at: now,
    },
    {
      user_id: 'c0000000-0000-0000-0000-000000000004',
      theme: 'light',
      font_size: 'medium',
      density: 'comfortable',
      locale: 'en-US',
      timezone: 'America/New_York',
      date_format: 'YYYY-MM-DD',
      time_format: '24h',
      first_day_of_week: 'monday',
      default_organization_id: 'd0000000-0000-0000-0000-000000000002',
      notifications: {
        email_enabled: true,
        push_enabled: false,
        digest_frequency: 'weekly',
      },
      sidebar: { is_collapsed: false, width: 260 },
      recent_items: [],
      favorites: [],
      onboarding: { completed: true },
      created_at: now,
      updated_at: now,
    },
    {
      user_id: 'c0000000-0000-0000-0000-000000000005',
      theme: 'dark',
      accent_color: '#ec4899',
      font_size: 'medium',
      density: 'comfortable',
      locale: 'fr-FR',
      timezone: 'Europe/Paris',
      date_format: 'DD/MM/YYYY',
      time_format: '24h',
      first_day_of_week: 'monday',
      default_organization_id: 'd0000000-0000-0000-0000-000000000003',
      notifications: {
        email_enabled: true,
        push_enabled: true,
        digest_frequency: 'daily',
      },
      sidebar: { is_collapsed: false, width: 260 },
      recent_items: [],
      favorites: [],
      onboarding: { completed: true },
      created_at: now,
      updated_at: now,
    },
  ],
  ['user_id'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  2. GLOBAL SETTINGS (per-org configuration)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'global_settings',
  [
    // Acme Corp — organization settings
    {
      scope_type: 'organization',
      scope_id: 'd0000000-0000-0000-0000-000000000001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      branding: {
        logo_url: 'https://logos.example.com/org/acme-corp.svg',
        primary_color: '#3b82f6',
        app_title: 'Acme Workspace',
      },
      security: {
        enforce_mfa: false,
        session_timeout_minutes: 480,
        password_policy: {
          min_length: 8,
          require_uppercase: true,
          require_number: true,
        },
      },
      features: {
        beta_dashboards: true,
        workflows: true,
        api_access: true,
        sso: false,
        audit_log: false,
      },
      dashboard_defaults: {
        grid_columns: 12,
        row_height: 60,
        gap: 16,
        default_refresh_interval: 300,
      },
      view_defaults: {
        default_page_size: 25,
        default_row_height: 'default',
        max_export_rows: 10000,
      },
      data_retention: {
        audit_log_retention_days: 90,
        query_cache_default_ttl: 300,
      },
      updated_by: 'c0000000-0000-0000-0000-000000000001',
      created_at: now,
      updated_at: now,
    },

    // Globex Inc — organization settings
    {
      scope_type: 'organization',
      scope_id: 'd0000000-0000-0000-0000-000000000002',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      branding: {
        logo_url: 'https://logos.example.com/org/globex-inc.svg',
        primary_color: '#8b5cf6',
        app_title: 'Globex Platform',
      },
      security: {
        enforce_mfa: true,
        session_timeout_minutes: 240,
        password_policy: {
          min_length: 12,
          require_uppercase: true,
          require_number: true,
          require_special: true,
        },
        sso_config: {
          provider: 'okta',
          enabled: true,
          domain: 'globex.okta.com',
        },
      },
      features: {
        beta_dashboards: true,
        workflows: true,
        api_access: true,
        sso: true,
        audit_log: true,
        advanced_analytics: true,
      },
      dashboard_defaults: {
        grid_columns: 12,
        row_height: 80,
        gap: 12,
        default_refresh_interval: 60,
      },
      view_defaults: {
        default_page_size: 50,
        default_row_height: 'default',
        max_export_rows: 100000,
      },
      data_retention: {
        audit_log_retention_days: 365,
        query_cache_default_ttl: 60,
      },
      updated_by: 'c0000000-0000-0000-0000-000000000003',
      created_at: now,
      updated_at: now,
    },

    // Iris Studio — organization settings
    {
      scope_type: 'organization',
      scope_id: 'd0000000-0000-0000-0000-000000000003',
      organization_id: 'd0000000-0000-0000-0000-000000000003',
      branding: {
        logo_url: 'https://logos.example.com/org/iris-studio.svg',
        primary_color: '#ec4899',
        app_title: 'Iris Studio',
      },
      security: {
        enforce_mfa: false,
        session_timeout_minutes: 720,
        password_policy: { min_length: 8 },
      },
      features: {
        beta_dashboards: false,
        workflows: false,
        api_access: false,
        sso: false,
        audit_log: false,
      },
      dashboard_defaults: {
        grid_columns: 12,
        row_height: 60,
        gap: 16,
      },
      view_defaults: {
        default_page_size: 25,
        default_row_height: 'default',
        max_export_rows: 1000,
      },
      data_retention: {
        audit_log_retention_days: 30,
        query_cache_default_ttl: 600,
      },
      updated_by: 'c0000000-0000-0000-0000-000000000005',
      created_at: now,
      updated_at: now,
    },
  ],
  ['scope_type', 'scope_id'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  3. ABAC RULE CONDITIONS (condition trees matching SQL abac_rules)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'abac_rule_conditions',
  [
    // ── Acme Corp rule conditions ──

    // is_engineer: user.department == "engineering"
    {
      rule_id: 'ab000000-0000-0000-0000-000000000001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      condition_tree: {
        attribute: 'user.department',
        operator: 'equals',
        value: 'engineering',
      },
      description: 'User department is engineering',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000001',
    },

    // low_sensitivity: resource.sensitivity <= 3
    {
      rule_id: 'ab000000-0000-0000-0000-000000000002',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      condition_tree: {
        attribute: 'resource.sensitivity',
        operator: 'lte',
        value: 3,
      },
      description: 'Resource sensitivity is 3 or below',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000001',
    },

    // business_hours: env.time_of_day between 08:00 and 20:00
    {
      rule_id: 'ab000000-0000-0000-0000-000000000003',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      condition_tree: {
        logic: 'and',
        conditions: [
          { attribute: 'env.time_of_day', operator: 'gte', value: '08:00' },
          { attribute: 'env.time_of_day', operator: 'lte', value: '20:00' },
        ],
      },
      description: 'Request occurs between 08:00 and 20:00',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000001',
    },

    // on_vpn: env.ip_address in_cidr 10.0.0.0/8
    {
      rule_id: 'ab000000-0000-0000-0000-000000000004',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      condition_tree: {
        attribute: 'env.ip_address',
        operator: 'in_cidr',
        value: '10.0.0.0/8',
      },
      description: 'Client IP is in the corporate VPN range',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000001',
    },

    // email_verified: user.is_verified == true
    {
      rule_id: 'ab000000-0000-0000-0000-000000000005',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      condition_tree: {
        attribute: 'user.is_verified',
        operator: 'equals',
        value: true,
      },
      description: 'User has a verified email address',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000001',
    },

    // public_or_internal: resource.visibility in [public, internal]
    {
      rule_id: 'ab000000-0000-0000-0000-000000000006',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      condition_tree: {
        attribute: 'resource.visibility',
        operator: 'in',
        value: ['public', 'internal'],
      },
      description: 'Resource visibility is public or internal',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000001',
    },

    // deny_top_secret: resource.sensitivity == 5
    {
      rule_id: 'ab000000-0000-0000-0000-000000000007',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      condition_tree: {
        attribute: 'resource.sensitivity',
        operator: 'equals',
        value: 5,
      },
      description: 'Resource sensitivity is top secret (5)',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000001',
    },

    // billing_resources: resource.type in [invoice, plan, subscription]
    {
      rule_id: 'ab000000-0000-0000-0000-000000000008',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      condition_tree: {
        attribute: 'resource.type',
        operator: 'in',
        value: ['invoice', 'plan', 'subscription'],
      },
      description: 'Resource type is a billing entity',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000001',
    },

    // read_only_actions: context.action in [read, list, export]
    {
      rule_id: 'ab000000-0000-0000-0000-000000000009',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      condition_tree: {
        attribute: 'context.action',
        operator: 'in',
        value: ['read', 'list', 'export'],
      },
      description: 'Action is limited to read/list/export',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000001',
    },

    // ── Globex Inc rule conditions ──

    // is_finance: user.department == "finance"
    {
      rule_id: 'ab000000-0000-0000-0000-000000000020',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      condition_tree: {
        attribute: 'user.department',
        operator: 'equals',
        value: 'finance',
      },
      description: 'User belongs to the finance department',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000003',
    },

    // mfa_verified: env.mfa_verified == true
    {
      rule_id: 'ab000000-0000-0000-0000-000000000021',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      condition_tree: {
        attribute: 'env.mfa_verified',
        operator: 'equals',
        value: true,
      },
      description: 'Current session was authenticated with MFA',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000003',
    },

    // eu_zone: user.regulatory_zone == "EU"
    {
      rule_id: 'ab000000-0000-0000-0000-000000000022',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      condition_tree: {
        attribute: 'user.regulatory_zone',
        operator: 'equals',
        value: 'EU',
      },
      description: 'User is in the EU regulatory zone',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000003',
    },

    // deny_billing_off_hours: NOT business hours (outside 08:00-18:00)
    {
      rule_id: 'ab000000-0000-0000-0000-000000000023',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      condition_tree: {
        logic: 'not',
        conditions: [
          {
            logic: 'and',
            conditions: [
              {
                attribute: 'env.time_of_day',
                operator: 'gte',
                value: '08:00',
              },
              {
                attribute: 'env.time_of_day',
                operator: 'lte',
                value: '18:00',
              },
            ],
          },
        ],
      },
      description:
        'Evaluates true when OUTSIDE business hours (deny trigger)',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000003',
    },

    // contractor_window: (already time-bounded in SQL — condition is just a pass-through)
    {
      rule_id: 'ab000000-0000-0000-0000-000000000024',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      condition_tree: {
        logic: 'and',
        conditions: [
          {
            attribute: 'user.is_verified',
            operator: 'equals',
            value: true,
          },
          {
            attribute: 'context.action',
            operator: 'in',
            value: ['read', 'list'],
          },
        ],
      },
      description:
        'Contractor must be verified and limited to read/list actions',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000003',
    },

    // clearance_3_plus: user.clearance_level >= 3
    {
      rule_id: 'ab000000-0000-0000-0000-000000000025',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      condition_tree: {
        attribute: 'user.clearance_level',
        operator: 'gte',
        value: 3,
      },
      description: 'User clearance level is 3 or higher',
      schema_version: 1,
      updated_by: 'c0000000-0000-0000-0000-000000000003',
    },
  ],
  ['rule_id'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  4. ABAC USER ATTRIBUTES (per-user per-org attribute store)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'abac_user_attributes',
  [
    // ── Platform admins (global — null org) ──
    {
      user_id: 'a0000000-0000-0000-0000-000000000001',
      organization_id: null,
      attributes: {
        department: 'platform',
        clearance_level: 5,
        teams: ['platform-core', 'security'],
        location: 'New York',
        is_verified: true,
        mfa_enrolled: true,
        account_age_days: 365,
      },
      computed_attributes: {
        account_age_days: {
          source: 'derived',
          query: 'DATEDIFF(NOW(), users.created_at)',
        },
      },
      updated_by: 'a0000000-0000-0000-0000-000000000001',
      recent_changes: [],
    },
    {
      user_id: 'a0000000-0000-0000-0000-000000000002',
      organization_id: null,
      attributes: {
        department: 'support',
        clearance_level: 3,
        teams: ['customer-success'],
        location: 'Chicago',
        is_verified: true,
        mfa_enrolled: false,
        account_age_days: 300,
      },
      updated_by: 'a0000000-0000-0000-0000-000000000001',
      recent_changes: [],
    },

    // ── Acme Corp members ──
    {
      user_id: 'c0000000-0000-0000-0000-000000000001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      attributes: {
        department: 'executive',
        clearance_level: 4,
        teams: ['leadership', 'product'],
        location: 'San Francisco',
        is_verified: true,
        mfa_enrolled: false,
        cost_center: 'CC-EXEC',
        account_age_days: 180,
      },
      updated_by: 'c0000000-0000-0000-0000-000000000001',
      recent_changes: [
        {
          key: 'cost_center',
          old_value: null,
          new_value: 'CC-EXEC',
          changed_by: 'c0000000-0000-0000-0000-000000000001',
          changed_at: iso('2024-03-01T10:00:00Z'),
        },
      ],
    },
    {
      user_id: 'c0000000-0000-0000-0000-000000000002',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      attributes: {
        department: 'engineering',
        clearance_level: 2,
        teams: ['backend', 'devops'],
        location: 'San Francisco',
        is_verified: true,
        mfa_enrolled: false,
        cost_center: 'CC-ENG',
        account_age_days: 90,
      },
      updated_by: 'c0000000-0000-0000-0000-000000000001',
      recent_changes: [],
    },

    // ── Globex Inc members ──
    {
      user_id: 'c0000000-0000-0000-0000-000000000003',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      attributes: {
        department: 'finance',
        clearance_level: 4,
        teams: ['finance-leadership', 'compliance'],
        location: 'London',
        is_verified: true,
        mfa_enrolled: true,
        regulatory_zone: 'EU',
        account_age_days: 250,
      },
      computed_attributes: {
        account_age_days: {
          source: 'derived',
          query: 'DATEDIFF(NOW(), users.created_at)',
        },
      },
      updated_by: 'c0000000-0000-0000-0000-000000000003',
      recent_changes: [
        {
          key: 'regulatory_zone',
          old_value: 'GLOBAL',
          new_value: 'EU',
          changed_by: 'c0000000-0000-0000-0000-000000000003',
          changed_at: iso('2024-02-15T09:30:00Z'),
        },
      ],
    },
    {
      user_id: 'c0000000-0000-0000-0000-000000000004',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      attributes: {
        department: 'analytics',
        clearance_level: 2,
        teams: ['data-science'],
        location: 'New York',
        is_verified: true,
        mfa_enrolled: false,
        regulatory_zone: 'US',
        account_age_days: 120,
      },
      updated_by: 'c0000000-0000-0000-0000-000000000003',
      recent_changes: [],
    },

    // ── Iris Studio (solo freelancer) ──
    {
      user_id: 'c0000000-0000-0000-0000-000000000005',
      organization_id: 'd0000000-0000-0000-0000-000000000003',
      attributes: {
        department: 'design',
        clearance_level: 1,
        teams: ['creative'],
        location: 'Paris',
        is_verified: true,
        mfa_enrolled: false,
        account_age_days: 60,
      },
      updated_by: 'c0000000-0000-0000-0000-000000000005',
      recent_changes: [],
    },
  ],
  ['user_id', 'organization_id'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  5. AUDIT LOG (sample entries)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'audit_log',
  [
    {
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      actor_id: 'c0000000-0000-0000-0000-000000000001',
      actor_type: 'user',
      actor_ip: '192.168.1.100',
      action: 'organization.created',
      resource_type: 'organization',
      resource_id: 'd0000000-0000-0000-0000-000000000001',
      resource_name: 'Acme Corp',
      timestamp: iso('2024-01-10T09:00:00Z'),
      metadata: { plan: 'starter' },
      request_id: 'req-00000000-0001',
    },
    {
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      actor_id: 'c0000000-0000-0000-0000-000000000001',
      actor_type: 'user',
      actor_ip: '192.168.1.100',
      action: 'member.invited',
      resource_type: 'organization_member',
      resource_id: 'c0000000-0000-0000-0000-000000000002',
      resource_name: 'Frank Miller',
      workspace_id: null,
      timestamp: iso('2024-01-12T14:30:00Z'),
      metadata: { invited_email: 'frank.miller@acme-corp.com' },
      request_id: 'req-00000000-0002',
    },
    {
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      actor_id: 'c0000000-0000-0000-0000-000000000003',
      actor_type: 'user',
      actor_ip: '10.20.30.40',
      action: 'organization.created',
      resource_type: 'organization',
      resource_id: 'd0000000-0000-0000-0000-000000000002',
      resource_name: 'Globex Inc',
      timestamp: iso('2024-01-05T11:00:00Z'),
      metadata: { plan: 'pro' },
      request_id: 'req-00000000-0003',
    },
    {
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      actor_id: 'c0000000-0000-0000-0000-000000000003',
      actor_type: 'user',
      actor_ip: '10.20.30.40',
      action: 'settings.updated',
      resource_type: 'global_settings',
      resource_id: 'd0000000-0000-0000-0000-000000000002',
      resource_name: 'Globex Inc Settings',
      timestamp: iso('2024-02-20T16:45:00Z'),
      changes: {
        before: { enforce_mfa: false },
        after: { enforce_mfa: true },
        diff: ['security.enforce_mfa'],
      },
      metadata: { reason: 'Compliance requirement' },
      request_id: 'req-00000000-0004',
    },
    {
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      actor_id: 'a0000000-0000-0000-0000-000000000001',
      actor_type: 'system',
      action: 'abac.policy_assigned',
      resource_type: 'abac_policy',
      resource_id: 'ad000000-0000-0000-0000-000000000010',
      resource_name: 'Finance Full Access',
      timestamp: iso('2024-03-01T08:00:00Z'),
      metadata: {
        target_type: 'user',
        target_id: 'c0000000-0000-0000-0000-000000000003',
      },
      request_id: 'req-00000000-0005',
    },
    {
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      actor_id: 'c0000000-0000-0000-0000-000000000002',
      actor_type: 'user',
      actor_ip: '10.0.1.50',
      action: 'record.created',
      resource_type: 'collection_record',
      resource_id: 'rec-00000000-0001',
      resource_name: 'New Task: Setup CI/CD',
      timestamp: iso('2024-03-15T10:20:00Z'),
      metadata: { collection: 'tasks' },
      request_id: 'req-00000000-0006',
    },
    {
      organization_id: 'd0000000-0000-0000-0000-000000000003',
      actor_id: 'c0000000-0000-0000-0000-000000000005',
      actor_type: 'user',
      actor_ip: '82.65.42.100',
      action: 'organization.created',
      resource_type: 'organization',
      resource_id: 'd0000000-0000-0000-0000-000000000003',
      resource_name: 'Iris Studio',
      timestamp: iso('2024-02-01T13:00:00Z'),
      metadata: { plan: 'free' },
      request_id: 'req-00000000-0007',
    },
    {
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      actor_id: 'a0000000-0000-0000-0000-000000000001',
      actor_type: 'system',
      action: 'abac.rule_created',
      resource_type: 'abac_rule',
      resource_id: 'ab000000-0000-0000-0000-000000000001',
      resource_name: 'is_engineer',
      timestamp: iso('2024-03-01T07:30:00Z'),
      metadata: { org_name: 'Acme Corp', effect: 'allow' },
      request_id: 'req-00000000-0008',
    },
  ],
  ['request_id'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  6. WORKFLOW DEFINITIONS (sample automation workflows)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'workflow_definitions',
  [
    {
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      name: 'Auto-notify on task create',
      description:
        'Sends a Slack notification when a new task record is created',
      is_active: true,
      trigger: {
        type: 'record_created',
        collection_id: 'col-tasks-acme-001',
      },
      steps: [
        {
          step_id: 'step-1',
          type: 'send_notification',
          config: {
            channel: 'slack',
            template: 'New task created: {{record.name}}',
            target: '#eng-tasks',
          },
          on_error: 'skip',
        },
      ],
      created_by: 'c0000000-0000-0000-0000-000000000001',
      execution_count: 12,
      last_triggered_at: iso('2024-03-20T15:30:00Z'),
      created_at: iso('2024-02-01T10:00:00Z'),
      updated_at: iso('2024-03-20T15:30:00Z'),
    },
    {
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      name: 'Compliance audit on sensitive update',
      description:
        'Logs an audit entry when a high-sensitivity record is updated',
      is_active: true,
      trigger: {
        type: 'record_updated',
        collection_id: 'col-finance-globex-001',
        conditions: { 'record.sensitivity': { $gte: 3 } },
      },
      steps: [
        {
          step_id: 'step-1',
          type: 'create_audit_entry',
          config: {
            action: 'compliance.sensitive_update',
            include_changes: true,
          },
        },
        {
          step_id: 'step-2',
          type: 'send_notification',
          config: {
            channel: 'email',
            template: 'Sensitive record updated: {{record.name}}',
            target: 'compliance@globex-inc.com',
          },
          on_error: 'continue',
        },
      ],
      created_by: 'c0000000-0000-0000-0000-000000000003',
      execution_count: 5,
      last_triggered_at: iso('2024-03-18T11:00:00Z'),
      created_at: iso('2024-01-15T09:00:00Z'),
      updated_at: iso('2024-03-18T11:00:00Z'),
    },
  ],
  ['organization_id', 'name'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  7. WORKFLOW EXECUTIONS (sample runs)
// ═══════════════════════════════════════════════════════════════════════════

// Get workflow definition ObjectIds for linking
const wfNotify = db.workflow_definitions.findOne({
  name: 'Auto-notify on task create',
});
const wfAudit = db.workflow_definitions.findOne({
  name: 'Compliance audit on sensitive update',
});

if (wfNotify) {
  upsertMany(
    'workflow_executions',
    [
      {
        workflow_id: wfNotify._id,
        organization_id: 'd0000000-0000-0000-0000-000000000001',
        status: 'completed',
        trigger_data: {
          record_id: 'rec-00000000-0001',
          collection_id: 'col-tasks-acme-001',
          triggered_by: 'c0000000-0000-0000-0000-000000000002',
        },
        step_results: [
          {
            step_id: 'step-1',
            status: 'completed',
            started_at: iso('2024-03-20T15:30:01Z'),
            completed_at: iso('2024-03-20T15:30:02Z'),
            duration_ms: 850,
            output: { message_sent: true, channel: '#eng-tasks' },
          },
        ],
        started_at: iso('2024-03-20T15:30:00Z'),
        completed_at: iso('2024-03-20T15:30:02Z'),
        duration_ms: 2100,
        _seed_key: 'wf-exec-acme-001',
      },
    ],
    ['_seed_key'],
  );
}

if (wfAudit) {
  upsertMany(
    'workflow_executions',
    [
      {
        workflow_id: wfAudit._id,
        organization_id: 'd0000000-0000-0000-0000-000000000002',
        status: 'completed',
        trigger_data: {
          record_id: 'rec-globex-fin-001',
          collection_id: 'col-finance-globex-001',
          triggered_by: 'c0000000-0000-0000-0000-000000000003',
          changed_fields: ['amount', 'status'],
        },
        step_results: [
          {
            step_id: 'step-1',
            status: 'completed',
            started_at: iso('2024-03-18T11:00:01Z'),
            completed_at: iso('2024-03-18T11:00:01Z'),
            duration_ms: 120,
            output: { audit_entry_created: true },
          },
          {
            step_id: 'step-2',
            status: 'completed',
            started_at: iso('2024-03-18T11:00:02Z'),
            completed_at: iso('2024-03-18T11:00:03Z'),
            duration_ms: 1200,
            output: { email_sent: true },
          },
        ],
        started_at: iso('2024-03-18T11:00:00Z'),
        completed_at: iso('2024-03-18T11:00:03Z'),
        duration_ms: 3400,
        _seed_key: 'wf-exec-globex-001',
      },
    ],
    ['_seed_key'],
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  8. DASHBOARD LAYOUTS (sample layouts)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'dashboard_layouts',
  [
    {
      dashboard_id: 'dash-acme-overview-001',
      scope: 'shared',
      workspace_id: 'ws-acme-main-001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      grid_config: {
        columns: 12,
        row_height: 60,
        gap: 16,
        compact_type: 'vertical',
      },
      widgets: [
        {
          widget_id: 'w-1',
          widget_type: 'metric_card',
          position: { x: 0, y: 0, w: 3, h: 2 },
          title: 'Total Tasks',
          data_source: {
            collection_id: 'col-tasks-acme-001',
            aggregation: 'count',
          },
        },
        {
          widget_id: 'w-2',
          widget_type: 'chart',
          position: { x: 3, y: 0, w: 6, h: 4 },
          title: 'Tasks by Status',
          config: { chart_type: 'bar' },
          data_source: {
            collection_id: 'col-tasks-acme-001',
            aggregation: 'group_by',
            group_field: 'status',
          },
        },
        {
          widget_id: 'w-3',
          widget_type: 'table',
          position: { x: 0, y: 4, w: 12, h: 6 },
          title: 'Recent Activity',
          data_source: {
            collection_id: 'col-tasks-acme-001',
            sort: { created_at: -1 },
            limit: 10,
          },
        },
      ],
      global_filters: [
        {
          filter_id: 'gf-1',
          field_slug: 'assignee',
          label: 'Assignee',
          filter_type: 'select',
          affected_widgets: ['w-1', 'w-2', 'w-3'],
        },
      ],
      version: 1,
      published_at: iso('2024-02-10T12:00:00Z'),
      published_by: 'c0000000-0000-0000-0000-000000000001',
      created_at: iso('2024-02-10T11:00:00Z'),
      updated_at: iso('2024-02-10T12:00:00Z'),
    },
    {
      dashboard_id: 'dash-globex-finance-001',
      scope: 'shared',
      workspace_id: 'ws-globex-finance-001',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      grid_config: {
        columns: 12,
        row_height: 80,
        gap: 12,
        compact_type: 'horizontal',
      },
      widgets: [
        {
          widget_id: 'w-1',
          widget_type: 'metric_card',
          position: { x: 0, y: 0, w: 4, h: 2 },
          title: 'Revenue MTD',
          data_source: {
            collection_id: 'col-finance-globex-001',
            aggregation: 'sum',
            field: 'amount',
          },
        },
        {
          widget_id: 'w-2',
          widget_type: 'chart',
          position: { x: 4, y: 0, w: 8, h: 4 },
          title: 'Revenue Trend',
          config: { chart_type: 'line' },
          data_source: {
            collection_id: 'col-finance-globex-001',
            aggregation: 'time_series',
            date_field: 'created_at',
          },
        },
      ],
      global_filters: [],
      version: 2,
      published_at: iso('2024-03-01T10:00:00Z'),
      published_by: 'c0000000-0000-0000-0000-000000000003',
      created_at: iso('2024-01-20T09:00:00Z'),
      updated_at: iso('2024-03-01T10:00:00Z'),
    },
  ],
  ['dashboard_id', 'scope', 'owner_id'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  9. VIEW CONFIGS (sample views)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'view_configs',
  [
    {
      view_id: 'view-acme-tasks-grid-001',
      collection_id: 'col-tasks-acme-001',
      workspace_id: 'ws-acme-main-001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      scope: 'shared',
      visible_fields: [
        { field_id: 'f-name', field_slug: 'name', width: 250, is_frozen: true },
        { field_id: 'f-status', field_slug: 'status', width: 120 },
        { field_id: 'f-priority', field_slug: 'priority', width: 100 },
        { field_id: 'f-assignee', field_slug: 'assignee', width: 150 },
        { field_id: 'f-due_date', field_slug: 'due_date', width: 120 },
      ],
      hidden_fields: ['internal_notes', 'legacy_id'],
      sorts: [
        { field_slug: 'priority', direction: 'desc' },
        { field_slug: 'due_date', direction: 'asc' },
      ],
      filters: {
        logic: 'and',
        conditions: [
          { field_slug: 'is_archived', operator: 'equals', value: false },
        ],
      },
      group_by: [],
      page_size: 25,
      row_height: 'default',
      wrap_cells: false,
      version: 1,
      created_at: iso('2024-02-05T08:00:00Z'),
      updated_at: iso('2024-02-05T08:00:00Z'),
    },
    {
      view_id: 'view-acme-tasks-kanban-001',
      collection_id: 'col-tasks-acme-001',
      workspace_id: 'ws-acme-main-001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      scope: 'shared',
      visible_fields: [
        { field_id: 'f-name', field_slug: 'name' },
        { field_id: 'f-priority', field_slug: 'priority' },
        { field_id: 'f-assignee', field_slug: 'assignee' },
      ],
      hidden_fields: [],
      sorts: [{ field_slug: 'priority', direction: 'desc' }],
      kanban_config: {
        stack_field: 'status',
        card_fields: ['name', 'priority', 'assignee'],
        hide_empty_stacks: false,
      },
      version: 1,
      created_at: iso('2024-02-05T08:30:00Z'),
      updated_at: iso('2024-02-05T08:30:00Z'),
    },
    {
      view_id: 'view-globex-finance-grid-001',
      collection_id: 'col-finance-globex-001',
      workspace_id: 'ws-globex-finance-001',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      scope: 'shared',
      visible_fields: [
        { field_id: 'f-tx-id', field_slug: 'transaction_id', width: 180 },
        { field_id: 'f-amount', field_slug: 'amount', width: 120 },
        { field_id: 'f-currency', field_slug: 'currency', width: 80 },
        { field_id: 'f-status', field_slug: 'status', width: 100 },
        { field_id: 'f-date', field_slug: 'date', width: 120 },
      ],
      hidden_fields: ['internal_ref'],
      sorts: [{ field_slug: 'date', direction: 'desc' }],
      group_by: [{ field_slug: 'currency', direction: 'asc' }],
      page_size: 50,
      row_height: 'compact',
      version: 1,
      created_at: iso('2024-01-25T10:00:00Z'),
      updated_at: iso('2024-01-25T10:00:00Z'),
    },
  ],
  ['view_id', 'scope', 'owner_id'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  10. COLLECTION RECORDS (sample data records)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'collection_records',
  [
    {
      collection_id: 'col-tasks-acme-001',
      workspace_id: 'ws-acme-main-001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      data: {
        name: 'Setup CI/CD pipeline',
        status: 'in_progress',
        priority: 'high',
        assignee: 'c0000000-0000-0000-0000-000000000002',
        due_date: '2024-04-01',
        description: 'Configure GitHub Actions for backend and frontend',
      },
      _relations: {},
      created_by: 'c0000000-0000-0000-0000-000000000001',
      updated_by: 'c0000000-0000-0000-0000-000000000002',
      version: 2,
      is_deleted: false,
      created_at: iso('2024-03-15T10:00:00Z'),
      updated_at: iso('2024-03-16T09:00:00Z'),
      _seed_key: 'rec-acme-task-001',
    },
    {
      collection_id: 'col-tasks-acme-001',
      workspace_id: 'ws-acme-main-001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      data: {
        name: 'Design landing page',
        status: 'todo',
        priority: 'medium',
        assignee: 'c0000000-0000-0000-0000-000000000001',
        due_date: '2024-04-15',
        description: 'Create responsive landing page mockups',
      },
      _relations: {},
      created_by: 'c0000000-0000-0000-0000-000000000001',
      version: 1,
      is_deleted: false,
      created_at: iso('2024-03-16T14:00:00Z'),
      updated_at: iso('2024-03-16T14:00:00Z'),
      _seed_key: 'rec-acme-task-002',
    },
    {
      collection_id: 'col-tasks-acme-001',
      workspace_id: 'ws-acme-main-001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      data: {
        name: 'Database schema review',
        status: 'done',
        priority: 'high',
        assignee: 'c0000000-0000-0000-0000-000000000002',
        due_date: '2024-03-10',
        description: 'Review and optimize SQL schema for production',
      },
      _relations: {},
      created_by: 'c0000000-0000-0000-0000-000000000002',
      version: 3,
      is_deleted: false,
      created_at: iso('2024-03-01T08:00:00Z'),
      updated_at: iso('2024-03-10T17:00:00Z'),
      _seed_key: 'rec-acme-task-003',
    },
    {
      collection_id: 'col-finance-globex-001',
      workspace_id: 'ws-globex-finance-001',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      data: {
        transaction_id: 'TXN-2024-001',
        amount: 125000.0,
        currency: 'GBP',
        status: 'completed',
        date: '2024-03-15',
        counterparty: 'Vendor Alpha Ltd',
      },
      _relations: {},
      created_by: 'c0000000-0000-0000-0000-000000000003',
      version: 1,
      is_deleted: false,
      created_at: iso('2024-03-15T09:00:00Z'),
      updated_at: iso('2024-03-15T09:00:00Z'),
      _seed_key: 'rec-globex-fin-001',
    },
    {
      collection_id: 'col-finance-globex-001',
      workspace_id: 'ws-globex-finance-001',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      data: {
        transaction_id: 'TXN-2024-002',
        amount: 45600.5,
        currency: 'EUR',
        status: 'pending',
        date: '2024-03-18',
        counterparty: 'Vendor Beta GmbH',
      },
      _relations: {},
      created_by: 'c0000000-0000-0000-0000-000000000004',
      version: 1,
      is_deleted: false,
      created_at: iso('2024-03-18T11:00:00Z'),
      updated_at: iso('2024-03-18T11:00:00Z'),
      _seed_key: 'rec-globex-fin-002',
    },
  ],
  ['_seed_key'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  11. QUERY CACHE (sample cached queries — short TTL)
// ═══════════════════════════════════════════════════════════════════════════

const cacheExpiry = new Date(Date.now() + 5 * 60 * 1000); // 5 min from now

upsertMany(
  'query_cache',
  [
    {
      cache_key: 'acme:tasks:count:all',
      collection_id: 'col-tasks-acme-001',
      workspace_id: 'ws-acme-main-001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      query_fingerprint: { aggregation: 'count', filters: {} },
      result: { count: 3 },
      result_count: 1,
      computation_time_ms: 12,
      ttl_seconds: 300,
      created_at: now,
      expires_at: cacheExpiry,
    },
    {
      cache_key: 'acme:tasks:group_by:status',
      collection_id: 'col-tasks-acme-001',
      workspace_id: 'ws-acme-main-001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      widget_id: 'w-2',
      query_fingerprint: {
        aggregation: 'group_by',
        group_field: 'status',
        filters: {},
      },
      result: [
        { _id: 'todo', count: 1 },
        { _id: 'in_progress', count: 1 },
        { _id: 'done', count: 1 },
      ],
      result_count: 3,
      computation_time_ms: 25,
      ttl_seconds: 300,
      created_at: now,
      expires_at: cacheExpiry,
    },
  ],
  ['cache_key'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  12. SYNC STATE (sample sync channel — Acme tasks sync)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'sync_state',
  [
    {
      channel_id: 'sync-acme-tasks-pg-001',
      connection_id: 'conn-acme-pg-001',
      collection_id: 'col-tasks-acme-001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      cdc_engine: 'pg_logical',
      inbound_cursor: {
        lsn: '0/1A2B3C4',
        slot_name: 'acme_tasks_slot',
        captured_at: iso('2024-03-20T15:00:00Z'),
      },
      outbound_cursor: {
        lsn: '0/1A2B3C0',
        captured_at: iso('2024-03-20T14:58:00Z'),
      },
      health: 'healthy',
      current_lag_ms: 120,
      lag_history: [
        {
          lag_ms: 100,
          measured_at: iso('2024-03-20T14:55:00Z'),
          pending_changes: 0,
        },
        {
          lag_ms: 120,
          measured_at: iso('2024-03-20T15:00:00Z'),
          pending_changes: 2,
        },
      ],
      lag_history_limit: 100,
      total_records_in: 156,
      total_records_out: 154,
      total_conflicts: 1,
      consecutive_errors: 0,
      last_success_at: iso('2024-03-20T15:00:00Z'),
      conflict_queue: [],
      pending_conflicts: 0,
      source_high_watermark: iso('2024-03-20T15:00:00Z'),
      platform_high_watermark: iso('2024-03-20T14:58:00Z'),
    },
  ],
  ['channel_id'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  13. CONNECTION CREDENTIALS (sample encrypted creds — mock values)
// ═══════════════════════════════════════════════════════════════════════════

upsertMany(
  'connection_credentials',
  [
    {
      connection_id: 'conn-acme-pg-001',
      organization_id: 'd0000000-0000-0000-0000-000000000001',
      label: 'Acme PostgreSQL Primary',
      credential_type: 'password',
      credentials: {
        username: 'ENC:AES256:bW9ja19lbmNyeXB0ZWRfdXNlcm5hbWU=',
        password: 'ENC:AES256:bW9ja19lbmNyeXB0ZWRfcGFzc3dvcmQ=',
      },
      encryption_meta: {
        key_id: 'kms-key-001',
        key_version: 1,
        algorithm: 'AES-256-GCM',
        iv: 'bW9ja19pdjEyMzQ1Ng==',
        auth_tag: 'bW9ja19hdXRoX3RhZw==',
      },
      status: 'active',
      rotation_policy: {
        enabled: true,
        interval_days: 90,
        last_rotation_at: iso('2024-01-15T00:00:00Z'),
        next_rotation_at: iso('2024-04-15T00:00:00Z'),
        strategy: 'dual_password',
      },
      rotation_history: [],
      created_by: 'c0000000-0000-0000-0000-000000000001',
      last_used_at: iso('2024-03-20T15:00:00Z'),
      usage_count: 1560,
      last_test_result: 'success',
      last_tested_at: iso('2024-03-20T12:00:00Z'),
    },
    {
      connection_id: 'conn-globex-api-001',
      organization_id: 'd0000000-0000-0000-0000-000000000002',
      label: 'Globex External API',
      credential_type: 'api_token',
      credentials: {
        api_token:
          'ENC:AES256:bW9ja19hcGlfdG9rZW5fZ2xvYmV4X2V4dGVybmFs',
      },
      encryption_meta: {
        key_id: 'kms-key-002',
        key_version: 1,
        algorithm: 'AES-256-GCM',
        iv: 'bW9ja19pdjc4OTAxMg==',
        auth_tag: 'bW9ja19hdXRoX3RhZzI=',
      },
      status: 'active',
      expires_at: iso('2025-01-01T00:00:00Z'),
      rotation_policy: {
        enabled: false,
        interval_days: 365,
        strategy: 'replace',
      },
      rotation_history: [],
      created_by: 'c0000000-0000-0000-0000-000000000003',
      last_used_at: iso('2024-03-19T16:00:00Z'),
      usage_count: 420,
      last_test_result: 'success',
      last_tested_at: iso('2024-03-15T08:00:00Z'),
    },
  ],
  ['connection_id'],
);

// ═══════════════════════════════════════════════════════════════════════════
//  SUMMARY
// ═══════════════════════════════════════════════════════════════════════════

print('');
print('── Collection summary ──');
const allColls = db.getCollectionNames().sort();
for (const c of allColls) {
  const cnt = db[c].countDocuments();
  print('  ' + c.padEnd(28) + cnt + ' documents');
}
print('');
print('════════════════════════════════════════════════════════════════');
print('  ✓ MongoDB seed complete. ' + allColls.length + ' collections seeded.');
print('════════════════════════════════════════════════════════════════');
