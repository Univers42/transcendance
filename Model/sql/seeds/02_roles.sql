-- ============================================================================
-- seeds/02_roles.sql — System Roles (seeded before auto-seed)
-- ============================================================================
-- Platform-defined roles that are immutable (is_system = TRUE).
-- These must exist before user_role_assignments can reference them.
-- ============================================================================

-- Global roles (no organization_id)
INSERT INTO roles (name, description, scope, is_system) VALUES
    ('global_admin',       'Platform super-administrator with full access',               'global',       TRUE),
    ('global_support',     'Platform support staff with read access to all orgs',          'global',       TRUE)
ON CONFLICT (organization_id, name, scope) DO NOTHING;

-- Organization-scoped roles (organization_id will be set per-org at runtime)
-- These are template roles with NULL organization_id for system defaults
INSERT INTO roles (name, description, scope, is_system) VALUES
    ('org_owner',          'Organization owner with full administrative rights',           'organization', TRUE),
    ('org_admin',          'Organization administrator with management capabilities',     'organization', TRUE),
    ('org_member',         'Standard organization member with read/write access',         'organization', TRUE),
    ('org_viewer',         'Read-only organization member',                               'organization', TRUE),
    ('org_billing',        'Billing manager with access to invoices and subscriptions',   'organization', TRUE)
ON CONFLICT (organization_id, name, scope) DO NOTHING;

-- Project-scoped roles
INSERT INTO roles (name, description, scope, is_system) VALUES
    ('project_admin',      'Full project administration including member management',     'project',      TRUE),
    ('project_editor',     'Can create, edit, and manage project content',                'project',      TRUE),
    ('project_member',     'Standard project member with contribution access',            'project',      TRUE),
    ('project_viewer',     'Read-only access to project resources',                       'project',      TRUE)
ON CONFLICT (organization_id, name, scope) DO NOTHING;

-- Workspace-scoped roles
INSERT INTO roles (name, description, scope, is_system) VALUES
    ('workspace_admin',    'Full workspace administration and member management',         'workspace',    TRUE),
    ('workspace_editor',   'Can edit collections, views, and dashboards in workspace',   'workspace',    TRUE),
    ('workspace_member',   'Standard workspace member with contribution access',         'workspace',    TRUE),
    ('workspace_viewer',   'Read-only access to workspace content',                       'workspace',    TRUE)
ON CONFLICT (organization_id, name, scope) DO NOTHING;

\echo '✓ System roles seeded (global + organization + project + workspace).'
