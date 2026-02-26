-- ============================================================================
-- seeds/07_abac_system.sql — ABAC Engine Seed Data
-- ============================================================================
-- Populates the enhanced ABAC engine with:
--   1. System attribute definitions (global)
--   2. Per-org attribute definitions (custom)
--   3. Atomic rules for demo organizations
--   4. Composable rule groups
--   5. Policies with rule group bindings
--   6. Policy assignments (users, roles, scopes)
--
-- Depends on:
--   • 02_roles.sql   (system roles)
--   • 05_users.sql   (demo users)
--   • 06_demo_org.sql (demo organizations)
--
-- UUID SCHEME:
--   Attribute defs:      aa000000-0000-0000-0000-0000000000XX
--   Rules:               ab000000-0000-0000-0000-0000000000XX
--   Rule groups:         ac000000-0000-0000-0000-0000000000XX
--   Policies:            ad000000-0000-0000-0000-0000000000XX
--   Policy assignments:  ae000000-0000-0000-0000-0000000000XX
-- ============================================================================


-- ═══════════════════════════════════════════════════════════════════════════
--  1. SYSTEM ATTRIBUTE DEFINITIONS (global — org IS NULL)
-- ═══════════════════════════════════════════════════════════════════════════
-- These are platform-managed attribute schemas available to ALL organizations.
-- Tenants can reference these in their custom rules.

INSERT INTO abac_attribute_definitions
    (id, organization_id, name, display_name, description, category, data_type, is_system, is_multivalued, default_value, created_by)
VALUES
    -- ── Subject attributes (user properties) ──
    ('aa000000-0000-0000-0000-000000000001', NULL,
     'user.department', 'Department', 'User''s primary department or business unit',
     'subject', 'string', TRUE, FALSE, NULL,
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000002', NULL,
     'user.clearance_level', 'Clearance Level', 'Numeric security clearance (0=none, 5=top)',
     'subject', 'number', TRUE, FALSE, '"0"',
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000003', NULL,
     'user.teams', 'Teams', 'Array of team slugs the user belongs to',
     'subject', 'array', TRUE, TRUE, '[]',
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000004', NULL,
     'user.location', 'Location', 'User''s primary office or city',
     'subject', 'string', TRUE, FALSE, NULL,
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000005', NULL,
     'user.is_verified', 'Email Verified', 'Whether user has verified their email',
     'subject', 'boolean', TRUE, FALSE, 'false',
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000006', NULL,
     'user.mfa_enrolled', 'MFA Enrolled', 'Whether user has enabled multi-factor auth',
     'subject', 'boolean', TRUE, FALSE, 'false',
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000007', NULL,
     'user.account_age_days', 'Account Age (days)', 'Days since user account was created',
     'subject', 'number', TRUE, FALSE, '"0"',
     'a0000000-0000-0000-0000-000000000001'),

    -- ── Resource attributes ──
    ('aa000000-0000-0000-0000-000000000010', NULL,
     'resource.sensitivity', 'Sensitivity Level', 'Numeric sensitivity rating (0=public, 5=top-secret)',
     'resource', 'number', TRUE, FALSE, '"0"',
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000011', NULL,
     'resource.owner_id', 'Resource Owner', 'UUID of the user who owns the resource',
     'resource', 'string', TRUE, FALSE, NULL,
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000012', NULL,
     'resource.visibility', 'Visibility', 'Resource visibility level',
     'resource', 'string', TRUE, FALSE, '"internal"',
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000013', NULL,
     'resource.type', 'Resource Type', 'The type identifier of the resource',
     'resource', 'string', TRUE, FALSE, NULL,
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000014', NULL,
     'resource.tags', 'Resource Tags', 'Array of tags/labels on the resource',
     'resource', 'array', TRUE, TRUE, '[]',
     'a0000000-0000-0000-0000-000000000001'),

    -- ── Environment attributes ──
    ('aa000000-0000-0000-0000-000000000020', NULL,
     'env.time_of_day', 'Time of Day', 'Current server time in HH:MM format',
     'environment', 'string', TRUE, FALSE, NULL,
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000021', NULL,
     'env.day_of_week', 'Day of Week', 'Current day: monday, tuesday, etc.',
     'environment', 'string', TRUE, FALSE, NULL,
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000022', NULL,
     'env.ip_address', 'IP Address', 'Client IP address of the request',
     'environment', 'ip', TRUE, FALSE, NULL,
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000023', NULL,
     'env.mfa_verified', 'MFA Verified', 'Whether current session used MFA',
     'environment', 'boolean', TRUE, FALSE, 'false',
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000024', NULL,
     'env.geo_country', 'Country Code', 'ISO 3166-1 alpha-2 country code from geo-IP',
     'environment', 'string', TRUE, FALSE, NULL,
     'a0000000-0000-0000-0000-000000000001'),

    -- ── Context attributes (request-level) ──
    ('aa000000-0000-0000-0000-000000000030', NULL,
     'context.action', 'Requested Action', 'The action being performed (read, write, delete, etc.)',
     'context', 'string', TRUE, FALSE, NULL,
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000031', NULL,
     'context.request_source', 'Request Source', 'Origin: web, api, mobile, webhook, internal',
     'context', 'string', TRUE, FALSE, '"web"',
     'a0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000032', NULL,
     'context.is_bulk_operation', 'Bulk Operation', 'Whether this is a batch/bulk request',
     'context', 'boolean', TRUE, FALSE, 'false',
     'a0000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════
--  2. CUSTOM ATTRIBUTE DEFINITIONS (per-org)
-- ═══════════════════════════════════════════════════════════════════════════
-- Acme Corp defines a custom "cost_center" attribute.
-- Globex Inc defines "regulatory_zone" for compliance.

INSERT INTO abac_attribute_definitions
    (id, organization_id, name, display_name, description, category, data_type, is_system, allowed_values, created_by)
VALUES
    ('aa000000-0000-0000-0000-000000000040',
     'd0000000-0000-0000-0000-000000000001',
     'user.cost_center', 'Cost Center', 'Employee cost center code at Acme',
     'custom', 'string', FALSE, '["CC-ENG","CC-SALES","CC-OPS","CC-EXEC"]',
     'c0000000-0000-0000-0000-000000000001'),

    ('aa000000-0000-0000-0000-000000000041',
     'd0000000-0000-0000-0000-000000000002',
     'user.regulatory_zone', 'Regulatory Zone', 'Compliance zone at Globex',
     'custom', 'string', FALSE, '["EU","US","APAC","GLOBAL"]',
     'c0000000-0000-0000-0000-000000000003')
ON CONFLICT DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════
--  3. ATOMIC RULES
-- ═══════════════════════════════════════════════════════════════════════════
-- Each rule is a single logical check. The actual condition tree lives in
-- MongoDB (abac_rule_conditions), but the rule identity, effect, priority,
-- and temporal bounds live here in SQL.

-- ── Acme Corp rules ──

INSERT INTO abac_rules
    (id, organization_id, name, description, effect, priority, resource_type, target_actions, is_active, created_by)
VALUES
    -- Rule: user is in engineering department
    ('ab000000-0000-0000-0000-000000000001',
     'd0000000-0000-0000-0000-000000000001',
     'is_engineer', 'User belongs to the engineering department',
     'allow', 10, NULL, NULL, TRUE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Rule: resource has low sensitivity (≤ 3)
    ('ab000000-0000-0000-0000-000000000002',
     'd0000000-0000-0000-0000-000000000001',
     'low_sensitivity', 'Resource sensitivity level is 3 or below',
     'allow', 10, NULL, NULL, TRUE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Rule: request is during business hours
    ('ab000000-0000-0000-0000-000000000003',
     'd0000000-0000-0000-0000-000000000001',
     'business_hours', 'Request occurs between 08:00 and 20:00',
     'allow', 5, NULL, NULL, TRUE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Rule: client is on corporate VPN
    ('ab000000-0000-0000-0000-000000000004',
     'd0000000-0000-0000-0000-000000000001',
     'on_vpn', 'Client IP is in the corporate VPN range 10.0.0.0/8',
     'allow', 5, NULL, NULL, TRUE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Rule: user has verified email
    ('ab000000-0000-0000-0000-000000000005',
     'd0000000-0000-0000-0000-000000000001',
     'email_verified', 'User has a verified email address',
     'allow', 20, NULL, NULL, TRUE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Rule: resource is public or internal
    ('ab000000-0000-0000-0000-000000000006',
     'd0000000-0000-0000-0000-000000000001',
     'public_or_internal', 'Resource visibility is public or internal',
     'allow', 5, NULL, '{read}', TRUE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Rule: deny all access to top-secret resources (effect = deny)
    ('ab000000-0000-0000-0000-000000000007',
     'd0000000-0000-0000-0000-000000000001',
     'deny_top_secret', 'Block access to resources with sensitivity = 5',
     'deny', 100, NULL, NULL, TRUE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Rule: billing resources only (resource_type scoped)
    ('ab000000-0000-0000-0000-000000000008',
     'd0000000-0000-0000-0000-000000000001',
     'billing_resources', 'Resource type is invoice, plan, or subscription',
     'allow', 10, NULL, NULL, TRUE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Rule: read-only actions
    ('ab000000-0000-0000-0000-000000000009',
     'd0000000-0000-0000-0000-000000000001',
     'read_only_actions', 'Action is limited to read/list/export',
     'allow', 10, NULL, '{read,list,export}', TRUE,
     'c0000000-0000-0000-0000-000000000001')
ON CONFLICT (organization_id, name) DO NOTHING;


-- ── Globex Inc rules ──

INSERT INTO abac_rules
    (id, organization_id, name, description, effect, priority, resource_type, target_actions, is_active, starts_at, expires_at, created_by)
VALUES
    -- Rule: user is in finance department
    ('ab000000-0000-0000-0000-000000000020',
     'd0000000-0000-0000-0000-000000000002',
     'is_finance', 'User belongs to the finance department',
     'allow', 10, NULL, NULL, TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000003'),

    -- Rule: MFA was used for current session
    ('ab000000-0000-0000-0000-000000000021',
     'd0000000-0000-0000-0000-000000000002',
     'mfa_verified', 'Current session was authenticated with MFA',
     'allow', 20, NULL, NULL, TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000003'),

    -- Rule: EU regulatory zone
    ('ab000000-0000-0000-0000-000000000022',
     'd0000000-0000-0000-0000-000000000002',
     'eu_zone', 'User is in the EU regulatory zone',
     'allow', 10, NULL, NULL, TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000003'),

    -- Rule: deny outside business hours for billing (TEMPORAL example)
    ('ab000000-0000-0000-0000-000000000023',
     'd0000000-0000-0000-0000-000000000002',
     'deny_billing_off_hours', 'Deny billing access outside business hours',
     'deny', 50, 'billing', NULL, TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000003'),

    -- Rule: temporary contractor access (time-bound)
    ('ab000000-0000-0000-0000-000000000024',
     'd0000000-0000-0000-0000-000000000002',
     'contractor_window', 'Temporary access window for Q2 contractors',
     'allow', 5, NULL, '{read,list}', TRUE,
     '2024-04-01T00:00:00Z', '2024-06-30T23:59:59Z',
     'c0000000-0000-0000-0000-000000000003'),

    -- Rule: user clearance at least 3
    ('ab000000-0000-0000-0000-000000000025',
     'd0000000-0000-0000-0000-000000000002',
     'clearance_3_plus', 'User clearance level is 3 or higher',
     'allow', 15, NULL, NULL, TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000003')
ON CONFLICT (organization_id, name) DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════
--  4. RULE GROUPS (composable bundles)
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Acme Corp groups ──

INSERT INTO abac_rule_groups
    (id, organization_id, name, description, combine_logic, is_system, created_by)
VALUES
    -- Group: Eng Data Access (AND) — user is engineer AND resource not highly sensitive
    ('ac000000-0000-0000-0000-000000000001',
     'd0000000-0000-0000-0000-000000000001',
     'Eng Data Access', 'Engineering team accessing non-sensitive data',
     'and', FALSE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Group: Secure Context (OR) — business hours OR on VPN
    ('ac000000-0000-0000-0000-000000000002',
     'd0000000-0000-0000-0000-000000000001',
     'Secure Context', 'Access from a trusted context: business hours or VPN',
     'or', FALSE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Group: Guarded Eng Access (AND) — nests Eng Data + Secure Context
    ('ac000000-0000-0000-0000-000000000003',
     'd0000000-0000-0000-0000-000000000001',
     'Guarded Eng Access', 'Full guarded engineering access: dept + sensitivity + context',
     'and', FALSE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Group: Basic Member Access (AND) — verified email + public/internal resources
    ('ac000000-0000-0000-0000-000000000004',
     'd0000000-0000-0000-0000-000000000001',
     'Basic Member Access', 'Minimum access for verified org members',
     'and', FALSE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Group: Top Secret Guard (single deny rule — wraps the deny)
    ('ac000000-0000-0000-0000-000000000005',
     'd0000000-0000-0000-0000-000000000001',
     'Top Secret Guard', 'Denies access to sensitivity-5 resources',
     'and', TRUE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Group: Billing Access (AND) — billing resources only
    ('ac000000-0000-0000-0000-000000000006',
     'd0000000-0000-0000-0000-000000000001',
     'Billing Access', 'Full CRUD on billing-related resources only',
     'and', FALSE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Group: Read Only Everywhere (AND) — read-only actions + email verified
    ('ac000000-0000-0000-0000-000000000007',
     'd0000000-0000-0000-0000-000000000001',
     'Read Only Everywhere', 'Read-only access across all resource types',
     'and', FALSE,
     'c0000000-0000-0000-0000-000000000001')
ON CONFLICT (organization_id, name) DO NOTHING;

-- ── Globex Inc groups ──

INSERT INTO abac_rule_groups
    (id, organization_id, name, description, combine_logic, is_system, created_by)
VALUES
    -- Group: Finance Team Access (AND)
    ('ac000000-0000-0000-0000-000000000010',
     'd0000000-0000-0000-0000-000000000002',
     'Finance Team Access', 'Finance department with clearance and MFA',
     'and', FALSE,
     'c0000000-0000-0000-0000-000000000003'),

    -- Group: MFA Required (single rule wrapper)
    ('ac000000-0000-0000-0000-000000000011',
     'd0000000-0000-0000-0000-000000000002',
     'MFA Required', 'Session must have MFA verification',
     'and', FALSE,
     'c0000000-0000-0000-0000-000000000003'),

    -- Group: EU Compliance (AND) — EU zone + MFA
    ('ac000000-0000-0000-0000-000000000012',
     'd0000000-0000-0000-0000-000000000002',
     'EU Compliance', 'EU regulatory zone access with MFA',
     'and', FALSE,
     'c0000000-0000-0000-0000-000000000003'),

    -- Group: Contractor Read Access (AND) — time-bound + read-only
    ('ac000000-0000-0000-0000-000000000013',
     'd0000000-0000-0000-0000-000000000002',
     'Contractor Read Access', 'Time-bound read-only contractor access',
     'and', FALSE,
     'c0000000-0000-0000-0000-000000000003')
ON CONFLICT (organization_id, name) DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════
--  5. RULE GROUP MEMBERS (junction: what's in each group)
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO abac_rule_group_members (group_id, rule_id, child_group_id, sort_order)
VALUES
    -- Eng Data Access (AND): is_engineer + low_sensitivity
    ('ac000000-0000-0000-0000-000000000001', 'ab000000-0000-0000-0000-000000000001', NULL, 0),
    ('ac000000-0000-0000-0000-000000000001', 'ab000000-0000-0000-0000-000000000002', NULL, 1),

    -- Secure Context (OR): business_hours + on_vpn
    ('ac000000-0000-0000-0000-000000000002', 'ab000000-0000-0000-0000-000000000003', NULL, 0),
    ('ac000000-0000-0000-0000-000000000002', 'ab000000-0000-0000-0000-000000000004', NULL, 1),

    -- Guarded Eng Access (AND): [Eng Data Access] + [Secure Context]  (nested groups!)
    ('ac000000-0000-0000-0000-000000000003', NULL, 'ac000000-0000-0000-0000-000000000001', 0),
    ('ac000000-0000-0000-0000-000000000003', NULL, 'ac000000-0000-0000-0000-000000000002', 1),

    -- Basic Member Access (AND): email_verified + public_or_internal
    ('ac000000-0000-0000-0000-000000000004', 'ab000000-0000-0000-0000-000000000005', NULL, 0),
    ('ac000000-0000-0000-0000-000000000004', 'ab000000-0000-0000-0000-000000000006', NULL, 1),

    -- Top Secret Guard: deny_top_secret (single rule)
    ('ac000000-0000-0000-0000-000000000005', 'ab000000-0000-0000-0000-000000000007', NULL, 0),

    -- Billing Access: billing_resources
    ('ac000000-0000-0000-0000-000000000006', 'ab000000-0000-0000-0000-000000000008', NULL, 0),

    -- Read Only Everywhere: email_verified + read_only_actions
    ('ac000000-0000-0000-0000-000000000007', 'ab000000-0000-0000-0000-000000000005', NULL, 0),
    ('ac000000-0000-0000-0000-000000000007', 'ab000000-0000-0000-0000-000000000009', NULL, 1),

    -- ── Globex groups ──

    -- Finance Team Access: is_finance + clearance_3_plus + mfa_verified
    ('ac000000-0000-0000-0000-000000000010', 'ab000000-0000-0000-0000-000000000020', NULL, 0),
    ('ac000000-0000-0000-0000-000000000010', 'ab000000-0000-0000-0000-000000000025', NULL, 1),
    ('ac000000-0000-0000-0000-000000000010', 'ab000000-0000-0000-0000-000000000021', NULL, 2),

    -- MFA Required: mfa_verified
    ('ac000000-0000-0000-0000-000000000011', 'ab000000-0000-0000-0000-000000000021', NULL, 0),

    -- EU Compliance: eu_zone + [MFA Required group] (nested!)
    ('ac000000-0000-0000-0000-000000000012', 'ab000000-0000-0000-0000-000000000022', NULL, 0),
    ('ac000000-0000-0000-0000-000000000012', NULL, 'ac000000-0000-0000-0000-000000000011', 1),

    -- Contractor Read Access: contractor_window (temporal rule)
    ('ac000000-0000-0000-0000-000000000013', 'ab000000-0000-0000-0000-000000000024', NULL, 0)
ON CONFLICT DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════
--  6. POLICIES
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO abac_policies
    (id, organization_id, name, description, effect, priority, is_active, is_system, created_by)
VALUES
    -- ── Acme Corp policies ──

    -- Policy: Top Secret Deny (highest priority — deny wins)
    ('ad000000-0000-0000-0000-000000000001',
     'd0000000-0000-0000-0000-000000000001',
     'Top Secret Lockdown',
     'Denies access to sensitivity-5 resources for all non-super-admins',
     'deny', 100, TRUE, TRUE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Policy: Engineering Default (allow eng access in secure contexts)
    ('ad000000-0000-0000-0000-000000000002',
     'd0000000-0000-0000-0000-000000000001',
     'Engineering Default Access',
     'Engineering team members can access non-sensitive data during business hours or on VPN',
     'allow', 50, TRUE, FALSE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Policy: Basic Member Read (allow verified members to read public resources)
    ('ad000000-0000-0000-0000-000000000003',
     'd0000000-0000-0000-0000-000000000001',
     'Basic Member Read',
     'All verified members can read public and internal resources',
     'allow', 10, TRUE, FALSE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Policy: Billing Admin (scoped admin variant — billing only)
    ('ad000000-0000-0000-0000-000000000004',
     'd0000000-0000-0000-0000-000000000001',
     'Billing Admin Access',
     'Billing administrators: full access to billing resources only',
     'allow', 60, TRUE, FALSE,
     'c0000000-0000-0000-0000-000000000001'),

    -- Policy: Read Only Viewer
    ('ad000000-0000-0000-0000-000000000005',
     'd0000000-0000-0000-0000-000000000001',
     'Read Only Viewer',
     'Viewers can only read/list/export across all resource types',
     'allow', 20, TRUE, FALSE,
     'c0000000-0000-0000-0000-000000000001'),

    -- ── Globex Inc policies ──

    -- Policy: Finance Full Access (MFA + clearance gated)
    ('ad000000-0000-0000-0000-000000000010',
     'd0000000-0000-0000-0000-000000000002',
     'Finance Full Access',
     'Finance team gets full access with clearance ≥ 3 and MFA',
     'allow', 50, TRUE, FALSE,
     'c0000000-0000-0000-0000-000000000003'),

    -- Policy: EU Data Compliance (MFA + EU zone required)
    ('ad000000-0000-0000-0000-000000000011',
     'd0000000-0000-0000-0000-000000000002',
     'EU Data Compliance',
     'EU-regulated data requires MFA and EU regulatory zone',
     'allow', 40, TRUE, TRUE,
     'c0000000-0000-0000-0000-000000000003'),

    -- Policy: Contractor Temporary Access (time-bound)
    ('ad000000-0000-0000-0000-000000000012',
     'd0000000-0000-0000-0000-000000000002',
     'Contractor Temporary',
     'Time-bound read-only access for Q2 contractors',
     'allow', 15, TRUE, FALSE,
     'c0000000-0000-0000-0000-000000000003'),

    -- Policy: Billing Off-Hours Deny
    ('ad000000-0000-0000-0000-000000000013',
     'd0000000-0000-0000-0000-000000000002',
     'Billing Off-Hours Deny',
     'Deny billing access outside business hours (defense-in-depth)',
     'deny', 80, TRUE, FALSE,
     'c0000000-0000-0000-0000-000000000003')
ON CONFLICT (organization_id, name) DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════
--  7. POLICY → RULE GROUPS (junction)
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO abac_policy_rule_groups (policy_id, rule_group_id, sort_order)
VALUES
    -- Top Secret Lockdown → Top Secret Guard
    ('ad000000-0000-0000-0000-000000000001', 'ac000000-0000-0000-0000-000000000005', 0),

    -- Engineering Default → Guarded Eng Access
    ('ad000000-0000-0000-0000-000000000002', 'ac000000-0000-0000-0000-000000000003', 0),

    -- Basic Member Read → Basic Member Access
    ('ad000000-0000-0000-0000-000000000003', 'ac000000-0000-0000-0000-000000000004', 0),

    -- Billing Admin → Billing Access
    ('ad000000-0000-0000-0000-000000000004', 'ac000000-0000-0000-0000-000000000006', 0),

    -- Read Only Viewer → Read Only Everywhere
    ('ad000000-0000-0000-0000-000000000005', 'ac000000-0000-0000-0000-000000000007', 0),

    -- Finance Full Access → Finance Team Access
    ('ad000000-0000-0000-0000-000000000010', 'ac000000-0000-0000-0000-000000000010', 0),

    -- EU Data Compliance → EU Compliance group
    ('ad000000-0000-0000-0000-000000000011', 'ac000000-0000-0000-0000-000000000012', 0),

    -- Contractor Temporary → Contractor Read Access
    ('ad000000-0000-0000-0000-000000000012', 'ac000000-0000-0000-0000-000000000013', 0),

    -- Billing Off-Hours → MFA Required (deny when match fails)
    ('ad000000-0000-0000-0000-000000000013', 'ac000000-0000-0000-0000-000000000011', 0)
ON CONFLICT DO NOTHING;


-- ═══════════════════════════════════════════════════════════════════════════
--  8. POLICY ASSIGNMENTS (who/where policies apply)
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO abac_policy_assignments
    (id, policy_id, target_type, target_id, is_active, starts_at, expires_at, assigned_by)
VALUES
    -- ── Acme Corp assignments ──

    -- Top Secret Lockdown → entire Acme org (all members)
    ('ae000000-0000-0000-0000-000000000001',
     'ad000000-0000-0000-0000-000000000001',
     'organization', 'd0000000-0000-0000-0000-000000000001',
     TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000001'),

    -- Engineering Default → org_member role (Acme engineers)
    ('ae000000-0000-0000-0000-000000000002',
     'ad000000-0000-0000-0000-000000000002',
     'role', (SELECT id FROM roles WHERE name = 'org_member' LIMIT 1),
     TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000001'),

    -- Basic Member Read → entire Acme org
    ('ae000000-0000-0000-0000-000000000003',
     'ad000000-0000-0000-0000-000000000003',
     'organization', 'd0000000-0000-0000-0000-000000000001',
     TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000001'),

    -- Billing Admin → Eve (Acme CEO, acts as billing admin)
    ('ae000000-0000-0000-0000-000000000004',
     'ad000000-0000-0000-0000-000000000004',
     'user', 'c0000000-0000-0000-0000-000000000001',
     TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000001'),

    -- Read Only Viewer → org_viewer role
    ('ae000000-0000-0000-0000-000000000005',
     'ad000000-0000-0000-0000-000000000005',
     'role', (SELECT id FROM roles WHERE name = 'org_viewer' LIMIT 1),
     TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000001'),

    -- ── Globex Inc assignments ──

    -- Finance Full Access → Grace (Globex finance lead)
    ('ae000000-0000-0000-0000-000000000010',
     'ad000000-0000-0000-0000-000000000010',
     'user', 'c0000000-0000-0000-0000-000000000003',
     TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000003'),

    -- EU Data Compliance → entire Globex org
    ('ae000000-0000-0000-0000-000000000011',
     'ad000000-0000-0000-0000-000000000011',
     'organization', 'd0000000-0000-0000-0000-000000000002',
     TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000003'),

    -- Contractor Temporary → Hank (contractor, time-bound)
    ('ae000000-0000-0000-0000-000000000012',
     'ad000000-0000-0000-0000-000000000012',
     'user', 'c0000000-0000-0000-0000-000000000004',
     TRUE, '2024-04-01T00:00:00Z', '2024-06-30T23:59:59Z',
     'c0000000-0000-0000-0000-000000000003'),

    -- Billing Off-Hours Deny → entire Globex org
    ('ae000000-0000-0000-0000-000000000013',
     'ad000000-0000-0000-0000-000000000013',
     'organization', 'd0000000-0000-0000-0000-000000000002',
     TRUE, NULL, NULL,
     'c0000000-0000-0000-0000-000000000003')
ON CONFLICT (policy_id, target_type, target_id) DO NOTHING;
