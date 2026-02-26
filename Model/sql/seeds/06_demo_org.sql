-- ============================================================================
-- seeds/06_demo_org.sql — Demo Organizations, Memberships & Role Assignments
-- ============================================================================
-- Creates demo organizations with full membership structures and role
-- assignments to showcase the RBAC system. Depends on:
--   • 02_roles.sql      (system roles)
--   • 03_plans.sql      (billing plans)
--   • 05_users.sql      (demo users)
-- ============================================================================

-- ═══════════════════════════════════════════════════════════════════════════
--  ORGANIZATIONS
-- ═══════════════════════════════════════════════════════════════════════════

-- Acme Corp — Starter plan (small team / startup tenant)
INSERT INTO organizations (id, name, slug, logo_url, is_active, metadata, created_by) VALUES
    ('d0000000-0000-0000-0000-000000000001',
     'Acme Corp',
     'acme-corp',
     'https://logos.example.com/org/acme-corp.svg',
     TRUE,
     '{"industry":"technology","size":"startup","feature_flags":{"beta_dashboards":true}}',
     'c0000000-0000-0000-0000-000000000001')  -- Eve Garcia (CEO)
ON CONFLICT (slug) DO NOTHING;

-- Globex Inc — Pro plan (growing enterprise tenant)
INSERT INTO organizations (id, name, slug, logo_url, is_active, metadata, created_by) VALUES
    ('d0000000-0000-0000-0000-000000000002',
     'Globex Inc',
     'globex-inc',
     'https://logos.example.com/org/globex-inc.svg',
     TRUE,
     '{"industry":"finance","size":"enterprise","feature_flags":{"sso":true,"audit_log":true}}',
     'c0000000-0000-0000-0000-000000000003')  -- Grace Davis (Enterprise Admin)
ON CONFLICT (slug) DO NOTHING;

-- Iris Freelance — Free plan (solo freelancer tenant)
INSERT INTO organizations (id, name, slug, logo_url, is_active, metadata, created_by) VALUES
    ('d0000000-0000-0000-0000-000000000003',
     'Iris Studio',
     'iris-studio',
     'https://logos.example.com/org/iris-studio.svg',
     TRUE,
     '{"industry":"design","size":"freelancer"}',
     'c0000000-0000-0000-0000-000000000005')  -- Iris Lee (Freelancer)
ON CONFLICT (slug) DO NOTHING;

\echo '  ✓ Organizations created.'

-- ═══════════════════════════════════════════════════════════════════════════
--  ORGANIZATION MEMBERS
-- ═══════════════════════════════════════════════════════════════════════════

-- Acme Corp members
INSERT INTO organization_members (organization_id, user_id, invited_by) VALUES
    ('d0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', NULL),  -- Eve (founder)
    ('d0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001')  -- Frank (invited by Eve)
ON CONFLICT (organization_id, user_id) DO NOTHING;

-- Globex Inc members
INSERT INTO organization_members (organization_id, user_id, invited_by) VALUES
    ('d0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000003', NULL),  -- Grace (founder)
    ('d0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000003')  -- Hank (invited by Grace)
ON CONFLICT (organization_id, user_id) DO NOTHING;

-- Iris Studio members
INSERT INTO organization_members (organization_id, user_id, invited_by) VALUES
    ('d0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000005', NULL)   -- Iris (solo founder)
ON CONFLICT (organization_id, user_id) DO NOTHING;

\echo '  ✓ Organization members added.'

-- ═══════════════════════════════════════════════════════════════════════════
--  ROLE ASSIGNMENTS (global + organization scoped)
-- ═══════════════════════════════════════════════════════════════════════════

-- ── Global roles ────────────────────────────────────────────────────────────
-- Platform Admin → global_admin
INSERT INTO user_role_assignments (user_id, role_id, context_type, context_id, assigned_by) VALUES
    ('a0000000-0000-0000-0000-000000000001',
     (SELECT id FROM roles WHERE name = 'global_admin' AND scope = 'global' LIMIT 1),
     'global', NULL, NULL)
ON CONFLICT DO NOTHING;

-- Support Agent → global_support
INSERT INTO user_role_assignments (user_id, role_id, context_type, context_id, assigned_by) VALUES
    ('a0000000-0000-0000-0000-000000000002',
     (SELECT id FROM roles WHERE name = 'global_support' AND scope = 'global' LIMIT 1),
     'global', NULL, 'a0000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

-- ── Acme Corp org roles ─────────────────────────────────────────────────────
-- Eve → org_owner
INSERT INTO user_role_assignments (user_id, role_id, context_type, context_id, assigned_by) VALUES
    ('c0000000-0000-0000-0000-000000000001',
     (SELECT id FROM roles WHERE name = 'org_owner' AND scope = 'organization' LIMIT 1),
     'organization', 'd0000000-0000-0000-0000-000000000001', NULL)
ON CONFLICT DO NOTHING;

-- Frank → org_member
INSERT INTO user_role_assignments (user_id, role_id, context_type, context_id, assigned_by) VALUES
    ('c0000000-0000-0000-0000-000000000002',
     (SELECT id FROM roles WHERE name = 'org_member' AND scope = 'organization' LIMIT 1),
     'organization', 'd0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001')
ON CONFLICT DO NOTHING;

-- ── Globex Inc org roles ────────────────────────────────────────────────────
-- Grace → org_owner
INSERT INTO user_role_assignments (user_id, role_id, context_type, context_id, assigned_by) VALUES
    ('c0000000-0000-0000-0000-000000000003',
     (SELECT id FROM roles WHERE name = 'org_owner' AND scope = 'organization' LIMIT 1),
     'organization', 'd0000000-0000-0000-0000-000000000002', NULL)
ON CONFLICT DO NOTHING;

-- Hank → org_member
INSERT INTO user_role_assignments (user_id, role_id, context_type, context_id, assigned_by) VALUES
    ('c0000000-0000-0000-0000-000000000004',
     (SELECT id FROM roles WHERE name = 'org_member' AND scope = 'organization' LIMIT 1),
     'organization', 'd0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000003')
ON CONFLICT DO NOTHING;

-- ── Iris Studio org roles ───────────────────────────────────────────────────
-- Iris → org_owner
INSERT INTO user_role_assignments (user_id, role_id, context_type, context_id, assigned_by) VALUES
    ('c0000000-0000-0000-0000-000000000005',
     (SELECT id FROM roles WHERE name = 'org_owner' AND scope = 'organization' LIMIT 1),
     'organization', 'd0000000-0000-0000-0000-000000000003', NULL)
ON CONFLICT DO NOTHING;

\echo '  ✓ Role assignments created.'

-- ═══════════════════════════════════════════════════════════════════════════
--  ROLE → PERMISSION MAPPINGS (system roles get their permissions)
-- ═══════════════════════════════════════════════════════════════════════════

-- org_owner gets ALL permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT
    (SELECT id FROM roles WHERE name = 'org_owner' AND scope = 'organization' LIMIT 1),
    p.id
FROM permissions p
ON CONFLICT DO NOTHING;

-- org_admin gets all except delete/manage organization
INSERT INTO role_permissions (role_id, permission_id)
SELECT
    (SELECT id FROM roles WHERE name = 'org_admin' AND scope = 'organization' LIMIT 1),
    p.id
FROM permissions p
WHERE NOT (p.resource_type = 'organization' AND p.action IN ('delete', 'manage'))
ON CONFLICT DO NOTHING;

-- org_member gets create/read/update on most resources, no delete/manage org-level
INSERT INTO role_permissions (role_id, permission_id)
SELECT
    (SELECT id FROM roles WHERE name = 'org_member' AND scope = 'organization' LIMIT 1),
    p.id
FROM permissions p
WHERE p.action IN ('create', 'read', 'update')
  AND p.resource_type NOT IN ('organization', 'role', 'billing', 'user')
ON CONFLICT DO NOTHING;

-- org_viewer gets read-only on everything
INSERT INTO role_permissions (role_id, permission_id)
SELECT
    (SELECT id FROM roles WHERE name = 'org_viewer' AND scope = 'organization' LIMIT 1),
    p.id
FROM permissions p
WHERE p.action = 'read'
ON CONFLICT DO NOTHING;

-- org_billing gets billing:read + billing:manage
INSERT INTO role_permissions (role_id, permission_id)
SELECT
    (SELECT id FROM roles WHERE name = 'org_billing' AND scope = 'organization' LIMIT 1),
    p.id
FROM permissions p
WHERE p.resource_type = 'billing'
ON CONFLICT DO NOTHING;

-- global_admin gets ALL permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT
    (SELECT id FROM roles WHERE name = 'global_admin' AND scope = 'global' LIMIT 1),
    p.id
FROM permissions p
ON CONFLICT DO NOTHING;

-- global_support gets all read permissions
INSERT INTO role_permissions (role_id, permission_id)
SELECT
    (SELECT id FROM roles WHERE name = 'global_support' AND scope = 'global' LIMIT 1),
    p.id
FROM permissions p
WHERE p.action = 'read'
ON CONFLICT DO NOTHING;

\echo '  ✓ Role-permission mappings created.'

-- ═══════════════════════════════════════════════════════════════════════════
--  PROJECTS (one per org for demo)
-- ═══════════════════════════════════════════════════════════════════════════

-- Acme Corp: CRM project
INSERT INTO projects (id, organization_id, name, slug, description, icon, color, created_by) VALUES
    ('e0000000-0000-0000-0000-000000000001',
     'd0000000-0000-0000-0000-000000000001',
     'CRM System',
     'crm-system',
     'Customer relationship management project for Acme Corp.',
     '📋', '#3B82F6',
     'c0000000-0000-0000-0000-000000000001')
ON CONFLICT (organization_id, slug) DO NOTHING;

-- Globex Inc: Analytics project
INSERT INTO projects (id, organization_id, name, slug, description, icon, color, created_by) VALUES
    ('e0000000-0000-0000-0000-000000000002',
     'd0000000-0000-0000-0000-000000000002',
     'Financial Analytics',
     'financial-analytics',
     'Financial data analytics and reporting project for Globex Inc.',
     '📊', '#10B981',
     'c0000000-0000-0000-0000-000000000003')
ON CONFLICT (organization_id, slug) DO NOTHING;

-- Iris Studio: Portfolio project
INSERT INTO projects (id, organization_id, name, slug, description, icon, color, created_by) VALUES
    ('e0000000-0000-0000-0000-000000000003',
     'd0000000-0000-0000-0000-000000000003',
     'Client Portfolio',
     'client-portfolio',
     'Design portfolio management for Iris Studio.',
     '🎨', '#8B5CF6',
     'c0000000-0000-0000-0000-000000000005')
ON CONFLICT (organization_id, slug) DO NOTHING;

\echo '  ✓ Projects created.'

-- ═══════════════════════════════════════════════════════════════════════════
--  PROJECT MEMBERS
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO project_members (project_id, user_id, invited_by) VALUES
    ('e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', NULL),
    ('e0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001'),
    ('e0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000003', NULL),
    ('e0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000003'),
    ('e0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000005', NULL)
ON CONFLICT (project_id, user_id) DO NOTHING;

\echo '  ✓ Project members added.'

-- ═══════════════════════════════════════════════════════════════════════════
--  WORKSPACES (one default per project)
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO workspaces (id, project_id, name, slug, description, type, is_default, sort_order, created_by) VALUES
    ('f0000000-0000-0000-0000-000000000001',
     'e0000000-0000-0000-0000-000000000001',
     'Sales Pipeline',
     'sales-pipeline',
     'Main workspace for tracking sales leads and opportunities.',
     'default', TRUE, 0,
     'c0000000-0000-0000-0000-000000000001'),
    ('f0000000-0000-0000-0000-000000000002',
     'e0000000-0000-0000-0000-000000000002',
     'Quarterly Reports',
     'quarterly-reports',
     'Financial reports and dashboards workspace.',
     'analytics', TRUE, 0,
     'c0000000-0000-0000-0000-000000000003'),
    ('f0000000-0000-0000-0000-000000000003',
     'e0000000-0000-0000-0000-000000000003',
     'Design Projects',
     'design-projects',
     'Client design projects and deliverables.',
     'default', TRUE, 0,
     'c0000000-0000-0000-0000-000000000005')
ON CONFLICT (project_id, slug) DO NOTHING;

\echo '  ✓ Workspaces created.'

-- ═══════════════════════════════════════════════════════════════════════════
--  WORKSPACE MEMBERS
-- ═══════════════════════════════════════════════════════════════════════════

INSERT INTO workspace_members (workspace_id, user_id, invited_by) VALUES
    ('f0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000001', NULL),
    ('f0000000-0000-0000-0000-000000000001', 'c0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000001'),
    ('f0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000003', NULL),
    ('f0000000-0000-0000-0000-000000000002', 'c0000000-0000-0000-0000-000000000004', 'c0000000-0000-0000-0000-000000000003'),
    ('f0000000-0000-0000-0000-000000000003', 'c0000000-0000-0000-0000-000000000005', NULL)
ON CONFLICT (workspace_id, user_id) DO NOTHING;

\echo '  ✓ Workspace members added.'
\echo '✓ Demo organizations fully seeded (3 orgs, projects, workspaces, members, roles).'
