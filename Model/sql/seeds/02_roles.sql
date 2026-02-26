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

\echo '✓ System roles seeded.'
