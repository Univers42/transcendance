-- ============================================================================
-- schema.organization.sql — Organizations, Projects, Workspaces (multi-tenant)
-- ============================================================================
--
-- HIERARCHY:  Organization → Project → Workspace
--
--   Organization = the tenant (company, team). Billing, roles, global settings,
--                  adapters, and policies are all scoped at this level.
--   Project      = a logical grouping inside an org (e.g., "CRM", "Analytics").
--   Workspace    = a container for collections, views, and dashboards.
--                  Think of it as a "tab" or "section" inside a project.
--
-- MEMBERSHIP MODEL (5NF-COMPLIANT):
--   Membership tables track ONLY the fact of membership: "user X belongs to
--   entity Y". They store WHO invited the member and WHEN they joined, because
--   those are intrinsic facts of the membership event itself.
--
--   The user's ROLE within that context is managed through user_role_assignments
--   (see schema.user.sql) with context_type/context_id, NOT through a
--   redundant VARCHAR role column on each membership table.
--
--   OLD (violated 3NF — same concept in multiple places):
--     organization_members.role VARCHAR CHECK ('owner','admin','member','viewer','billing')
--     project_members.role      VARCHAR CHECK ('admin','editor','member','viewer')
--     workspace_members.role    VARCHAR CHECK ('admin','editor','member','viewer')
--
--   NEW (5NF — single source of truth):
--     user_role_assignments: (user_id, role_id, context_type='organization', context_id=org.id)
--                            → references roles table with proper FK
--
--   To get a user's role in an organization:
--     SELECT r.name FROM user_role_assignments ura
--     JOIN roles r ON r.id = ura.role_id
--     WHERE ura.user_id = $user_id
--       AND ura.context_type = 'organization'
--       AND ura.context_id = $organization_id
--       AND (ura.expires_at IS NULL OR ura.expires_at > now());
--
-- EXECUTION ORDER: Run AFTER schema.user.sql (depends on users, roles tables).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- ORGANIZATIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Top-level tenant entity. Every resource on the platform is ultimately
-- scoped under an organization.
--
-- RELATIONSHIPS:
--   organizations.id         ←── roles.organization_id            (1:N) Roles defined for this org
--   organizations.id         ←── organization_members.organization_id (1:N) Members
--   organizations.id         ←── projects.organization_id         (1:N) Projects under this org
--   organizations.id         ←── resources.organization_id        (1:N) Polymorphic resource registry
--   organizations.id         ←── adapters.organization_id         (1:N) External data connectors
--   organizations.id         ←── database_connections.organization_id (1:N) DB connections
--   organizations.id         ←── provisioned_databases.organization_id (1:N) Managed DBs
--   organizations.id         ←── subscriptions.organization_id    (1:N) Billing subscriptions
--   organizations.id         ←── invoices.organization_id         (1:N) Billing invoices
--   organizations.id         ←── usage_records.organization_id    (1:N) Usage metering
--   organizations.id         ←── tags.organization_id             (1:N) Tagging taxonomy
--   organizations.id         ←── webhooks.organization_id         (1:N) Outbound event hooks
--   organizations.id         ←── policy_rules.organization_id     (1:N) Org-wide ABAC policies
--   organizations.id         ←── file_uploads.organization_id     (1:N) Uploaded files
--   organizations.id         ←── dashboard_templates.organization_id (1:N) Dashboard templates
--   organizations.created_by ──→ users.id                         (N:1) Founding user
--   organizations.updated_by ──→ users.id                         (N:1) Last modifier
--
-- JOIN PATHS:
--   Org → Members:       organizations → organization_members → users
--   Org → Projects:      organizations → projects → workspaces
--   Org → Full tree:     organizations → projects → workspaces → collections
--   Org → Roles:         organizations → roles → role_permissions → permissions
--   Org → Adapters:      organizations → adapters → adapter_mappings → collections
--   Org → DB Connections: organizations → database_connections → sync_channels → collections
--   Org → Provisioned:   organizations → provisioned_databases → database_connections
--   Org → Subscription:  organizations → subscriptions → plans → plan_features
--   Org → Invoices:      organizations → invoices → payments
--   Org → Usage:         organizations → usage_records → usage_meters
--   Org → Policies:      organizations → policy_rules
--
-- NOTES:
--   • slug is globally unique for URL routing (/orgs/{slug}/...)
--   • plan_id references the plans table (see schema.billing.sql)
--     OLD design used VARCHAR CHECK — now a proper FK for rich plan metadata
--   • metadata stores feature flags, custom limits, extras (JSONB for flexibility)
--   • is_active allows soft-deletion (preserves data for billing/audit)
--   • created_by identifies the founding user; updated_by tracks last admin edit
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE organizations (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name        VARCHAR(255)    NOT NULL,
    slug        VARCHAR(100)    NOT NULL UNIQUE,
    logo_url    TEXT,
    is_active   BOOLEAN         NOT NULL DEFAULT TRUE,
    metadata    JSONB           NOT NULL DEFAULT '{}',          -- feature flags, custom limits
    created_by  UUID            NOT NULL REFERENCES users(id),
    updated_by  UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE organizations IS 'Top-level tenant. All resources are scoped under an organization.';

-- Deferred FK from schema.user.sql: roles.organization_id → organizations.id
-- This could not be set inline because schema.user.sql runs first and
-- organizations did not yet exist when the roles table was created.
ALTER TABLE roles
    ADD CONSTRAINT fk_roles_organization
    FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

-- ─────────────────────────────────────────────────────────────────────────────
-- ORGANIZATION MEMBERS
-- ─────────────────────────────────────────────────────────────────────────────
-- Pure membership fact: "user X belongs to organization Y".
-- Role assignment is handled by user_role_assignments (see schema.user.sql).
--
-- RELATIONSHIPS:
--   organization_members.organization_id ──→ organizations.id (N:1) The organization
--   organization_members.user_id         ──→ users.id         (N:1) The member
--   organization_members.invited_by      ──→ users.id         (N:1) Who sent the invitation
--
-- HOW TO GET THE USER'S ROLE IN THIS ORG:
--   This table does NOT store roles. Instead, query:
--     user_role_assignments WHERE context_type = 'organization'
--                            AND context_id = organization_members.organization_id
--                            AND user_id = organization_members.user_id
--   Then join → roles → role_permissions → permissions for full RBAC resolution.
--
-- JOIN PATHS:
--   Org → Members:      organizations → organization_members → users
--   Member → Org Role:  organization_members.user_id + organization_id
--                          → user_role_assignments (context_type='organization')
--                          → roles → role_permissions → permissions
--   Member → Inviter:   organization_members → users (via invited_by)
--
-- NOTES:
--   • (organization_id, user_id) is UNIQUE — a user can be a member only once
--   • invited_by is NOT generic "created_by" — it specifically identifies the
--     person who sent the invitation, an important audit fact for org governance
--   • joined_at records when the user accepted the invite and became a member
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE organization_members (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invited_by      UUID        REFERENCES users(id) ON DELETE SET NULL,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (organization_id, user_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- PROJECTS
-- ─────────────────────────────────────────────────────────────────────────────
-- A logical grouping inside an organization. Projects contain workspaces,
-- which contain collections, views, and dashboards.
--
-- RELATIONSHIPS:
--   projects.organization_id ──→ organizations.id      (N:1) Parent organization
--   projects.created_by      ──→ users.id              (N:1) Who created this project
--   projects.updated_by      ──→ users.id              (N:1) Who last modified it
--   projects.id              ←── project_members.project_id  (1:N) Project members
--   projects.id              ←── workspaces.project_id       (1:N) Workspaces in this project
--
-- JOIN PATHS:
--   Org → Projects:         organizations → projects
--   Project → Workspaces:   projects → workspaces → collections
--   Project → Members:      projects → project_members → users
--   Project → Member Roles: project_members.user_id + project_id
--                             → user_role_assignments (context_type='project')
--                             → roles → role_permissions → permissions
--
-- NOTES:
--   • (organization_id, slug) is UNIQUE — slugs are unique within an org
--   • is_archived allows soft-hiding (data preserved, not visible in UI by default)
--   • icon supports emoji or icon-set identifiers; color is hex for UI theming
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE projects (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    slug            VARCHAR(100)    NOT NULL,
    description     TEXT,
    icon            VARCHAR(50),                                -- emoji or icon identifier
    color           VARCHAR(7),                                 -- hex color #RRGGBB
    is_archived     BOOLEAN         NOT NULL DEFAULT FALSE,
    created_by      UUID            NOT NULL REFERENCES users(id),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (organization_id, slug)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- PROJECT MEMBERS
-- ─────────────────────────────────────────────────────────────────────────────
-- Pure membership fact: "user X participates in project Y".
-- Role assignment is handled by user_role_assignments (see schema.user.sql).
--
-- RELATIONSHIPS:
--   project_members.project_id ──→ projects.id (N:1) The project
--   project_members.user_id    ──→ users.id    (N:1) The member
--   project_members.invited_by ──→ users.id    (N:1) Who added this member
--
-- HOW TO GET THE USER'S ROLE IN THIS PROJECT:
--   Query user_role_assignments WHERE context_type = 'project'
--                                AND context_id = project_members.project_id
--                                AND user_id = project_members.user_id
--   Then join → roles → role_permissions → permissions for RBAC resolution.
--
-- JOIN PATHS:
--   Project → Members:       projects → project_members → users
--   Member → Project Role:   project_members.user_id + project_id
--                               → user_role_assignments (context_type='project')
--                               → roles
--
-- NOTES:
--   • (project_id, user_id) is UNIQUE — a user can be a member only once
--   • invited_by tracks who added this member (project admin or org admin)
--   • joined_at records when the membership became effective
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE project_members (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID        NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invited_by  UUID        REFERENCES users(id) ON DELETE SET NULL,
    joined_at   TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (project_id, user_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- WORKSPACES
-- ─────────────────────────────────────────────────────────────────────────────
-- A workspace contains collections, views, and dashboards.
-- Each project has at least one default workspace.
-- Think of it as a "tab" or "section" inside a project.
--
-- RELATIONSHIPS:
--   workspaces.project_id  ──→ projects.id           (N:1) Parent project
--   workspaces.created_by  ──→ users.id              (N:1) Who created this workspace
--   workspaces.updated_by  ──→ users.id              (N:1) Who last modified it
--   workspaces.id          ←── workspace_members.workspace_id (1:N) Workspace members
--   workspaces.id          ←── collections.workspace_id       (1:N) Data collections
--   workspaces.id          ←── dashboards.workspace_id        (1:N) Dashboards
--   workspaces.id          ←── views.workspace_id             (1:N) Data views
--
-- JOIN PATHS:
--   Project → Workspaces:    projects → workspaces
--   Workspace → Collections: workspaces → collections → fields
--   Workspace → Dashboards:  workspaces → dashboards
--   Workspace → Members:     workspaces → workspace_members → users
--   Full hierarchy:          organizations → projects → workspaces → collections
--   Workspace → Member Roles: workspace_members.user_id + workspace_id
--                               → user_role_assignments (context_type='workspace')
--                               → roles → role_permissions → permissions
--
-- NOTES:
--   • (project_id, slug) is UNIQUE — slugs are unique within a project
--   • type categorizes workspace purpose: default, data, analytics, admin, sandbox
--   • is_default: if TRUE, this workspace is the landing workspace for the project
--   • sort_order controls display order in the sidebar/nav
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE workspaces (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    project_id  UUID            NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    name        VARCHAR(255)    NOT NULL,
    slug        VARCHAR(100)    NOT NULL,
    description TEXT,
    type        VARCHAR(50)     NOT NULL DEFAULT 'default'
                                CHECK (type IN ('default','data','analytics','admin','sandbox')),
    is_default  BOOLEAN         NOT NULL DEFAULT FALSE,
    sort_order  INT             NOT NULL DEFAULT 0,
    created_by  UUID            NOT NULL REFERENCES users(id),
    updated_by  UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (project_id, slug)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- WORKSPACE MEMBERS
-- ─────────────────────────────────────────────────────────────────────────────
-- Pure membership fact: "user X has access to workspace Y".
-- Role assignment is handled by user_role_assignments (see schema.user.sql).
--
-- RELATIONSHIPS:
--   workspace_members.workspace_id ──→ workspaces.id (N:1) The workspace
--   workspace_members.user_id      ──→ users.id      (N:1) The member
--   workspace_members.invited_by   ──→ users.id      (N:1) Who granted access
--
-- HOW TO GET THE USER'S ROLE IN THIS WORKSPACE:
--   Query user_role_assignments WHERE context_type = 'workspace'
--                                AND context_id = workspace_members.workspace_id
--                                AND user_id = workspace_members.user_id
--   Then join → roles → role_permissions → permissions for RBAC resolution.
--
-- JOIN PATHS:
--   Workspace → Members:      workspaces → workspace_members → users
--   Member → Workspace Role:  workspace_members.user_id + workspace_id
--                                → user_role_assignments (context_type='workspace')
--                                → roles
--
-- NOTES:
--   • (workspace_id, user_id) is UNIQUE — a user can be a member only once
--   • Access can also cascade: org member → org projects → project workspaces
--     (application logic determines if project/org membership implies workspace access)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE workspace_members (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id    UUID        NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    invited_by      UUID        REFERENCES users(id) ON DELETE SET NULL,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (workspace_id, user_id)
);
