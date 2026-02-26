-- ============================================================================
-- seeds/01_permissions.sql — System Permissions (seeded before auto-seed)
-- ============================================================================
-- These are platform-defined permissions that must exist before roles can
-- reference them. The auto-seeder handles the rest, but these are canonical.
-- ============================================================================

-- Insert permissions using resource_type:action convention
-- Idempotent: ON CONFLICT DO NOTHING
INSERT INTO permissions (name, resource_type, action, description) VALUES
    -- Dashboard permissions
    ('dashboard:create',  'dashboard',  'create',  'Create new dashboards'),
    ('dashboard:read',    'dashboard',  'read',    'View dashboards'),
    ('dashboard:update',  'dashboard',  'update',  'Edit dashboard metadata'),
    ('dashboard:delete',  'dashboard',  'delete',  'Delete dashboards'),
    ('dashboard:manage',  'dashboard',  'manage',  'Full dashboard management'),
    ('dashboard:share',   'dashboard',  'share',   'Share dashboards'),
    ('dashboard:publish', 'dashboard',  'publish', 'Publish dashboard layouts'),

    -- Collection permissions
    ('collection:create', 'collection', 'create',  'Create new collections'),
    ('collection:read',   'collection', 'read',    'View collection data'),
    ('collection:update', 'collection', 'update',  'Edit collection schema'),
    ('collection:delete', 'collection', 'delete',  'Delete collections'),
    ('collection:manage', 'collection', 'manage',  'Full collection management'),

    -- View permissions
    ('view:create',       'view',       'create',  'Create saved views'),
    ('view:read',         'view',       'read',    'Access saved views'),
    ('view:update',       'view',       'update',  'Edit view configuration'),
    ('view:delete',       'view',       'delete',  'Delete saved views'),

    -- Workspace permissions
    ('workspace:create',  'workspace',  'create',  'Create workspaces'),
    ('workspace:read',    'workspace',  'read',    'Access workspaces'),
    ('workspace:update',  'workspace',  'update',  'Edit workspace settings'),
    ('workspace:delete',  'workspace',  'delete',  'Delete workspaces'),
    ('workspace:manage',  'workspace',  'manage',  'Full workspace management'),

    -- Project permissions
    ('project:create',    'project',    'create',  'Create projects'),
    ('project:read',      'project',    'read',    'Access projects'),
    ('project:update',    'project',    'update',  'Edit project settings'),
    ('project:delete',    'project',    'delete',  'Delete projects'),
    ('project:manage',    'project',    'manage',  'Full project management'),

    -- Organization permissions
    ('organization:read',   'organization', 'read',   'View organization info'),
    ('organization:update', 'organization', 'update', 'Edit organization settings'),
    ('organization:delete', 'organization', 'delete', 'Delete organization'),
    ('organization:manage', 'organization', 'manage', 'Full organization management'),

    -- Adapter permissions
    ('adapter:create',    'adapter',    'create',  'Create adapters'),
    ('adapter:read',      'adapter',    'read',    'View adapter status'),
    ('adapter:update',    'adapter',    'update',  'Edit adapter configuration'),
    ('adapter:delete',    'adapter',    'delete',  'Delete adapters'),
    ('adapter:manage',    'adapter',    'manage',  'Full adapter management'),

    -- Resource permissions
    ('resource:create',   'resource',   'create',  'Register resources'),
    ('resource:read',     'resource',   'read',    'View resources'),
    ('resource:update',   'resource',   'update',  'Edit resource metadata'),
    ('resource:delete',   'resource',   'delete',  'Delete resources'),
    ('resource:share',    'resource',   'share',   'Share resources'),

    -- User management permissions
    ('user:read',         'user',       'read',    'View user profiles'),
    ('user:update',       'user',       'update',  'Edit user profiles'),
    ('user:delete',       'user',       'delete',  'Delete user accounts'),
    ('user:manage',       'user',       'manage',  'Full user management'),

    -- Role management permissions
    ('role:create',       'role',       'create',  'Create custom roles'),
    ('role:read',         'role',       'read',    'View roles'),
    ('role:update',       'role',       'update',  'Edit role permissions'),
    ('role:delete',       'role',       'delete',  'Delete custom roles'),
    ('role:manage',       'role',       'manage',  'Full role management'),

    -- Billing permissions
    ('billing:read',      'billing',    'read',    'View billing information'),
    ('billing:manage',    'billing',    'manage',  'Manage billing and subscriptions')
ON CONFLICT (resource_type, action) DO NOTHING;

\echo '✓ System permissions seeded.'
