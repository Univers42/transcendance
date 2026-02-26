-- ============================================================================
-- schema.dashboard.sql — Dashboards, Views, Templates (presentation layer)
-- ============================================================================
--
-- DOMAIN: Presentation layer — how users visualize and interact with data.
--
-- DESIGN SPLIT (SQL ↔ MongoDB):
--   SQL (this file): Structural identity, permissions, visibility, ownership.
--     → "What dashboards exist? Who can see them? Who created them?"
--   MongoDB (dashboard_layouts, view_configs):
--     → "Where are the widgets positioned? What filters are active?"
--     → Layout data is deeply nested, varies per widget, changes on every
--       drag-and-drop, and supports personal overrides — all traits that
--       favor document storage over relational.
--
-- SCOPE RESOLUTION (for dashboard_layouts in MongoDB):
--   personal  → user's own layout (highest priority)
--   shared    → published layout visible to all workspace members
--   template  → the org-level default template (lowest priority)
--   When rendering: check personal → fallback to shared → fallback to template.
--   When user drags widgets → saves to "personal" scope only.
--   When user with "dashboard:publish" permission saves → updates "shared".
--
-- EXECUTION ORDER: Run AFTER schema.collection.sql (depends on collections, workspaces).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- DASHBOARDS
-- ─────────────────────────────────────────────────────────────────────────────
-- A dashboard is a page composed of widgets (charts, tables, KPIs, etc.).
-- This table holds the identity and metadata; the actual widget layout
-- lives in MongoDB dashboard_layouts.
--
-- RELATIONSHIPS:
--   dashboards.workspace_id ──→ workspaces.id          (N:1) Parent workspace
--   dashboards.created_by   ──→ users.id               (N:1) Who created this dashboard
--   dashboards.updated_by   ──→ users.id               (N:1) Who last modified metadata
--   dashboards.id           ←── dashboard_permissions.dashboard_id (1:N) Per-dashboard access
--   dashboards.id           ──→ MongoDB dashboard_layouts.dashboard_id (1:N) Layout configs
--   dashboards.id           ──→ resources.resource_id   (1:1) Polymorphic resource entry
--
-- JOIN PATHS:
--   Workspace → Dashboards:  workspaces → dashboards
--   Dashboard → Permissions:  dashboards → dashboard_permissions
--   Dashboard → Layout:       dashboards.id = MongoDB dashboard_layouts.dashboard_id
--   Full hierarchy:           organizations → projects → workspaces → dashboards
--   Dashboard → Resource:     dashboards.id → resources (WHERE resource_type='dashboard')
--                                → resource_permissions, resource_versions, etc.
--
-- NOTES:
--   • (workspace_id, slug) is UNIQUE — slugs unique per workspace
--   • visibility controls who can discover this dashboard:
--       private      = only creator and explicit grantees
--       workspace    = all workspace members
--       project      = all project members
--       organization = all org members
--       public       = anyone with the link (used with resource_shares)
--   • is_default: if TRUE, this is the landing dashboard for the workspace
--   • is_locked: only users with "dashboard:manage" permission can edit
--   • refresh_interval: auto-refresh in seconds (NULL = manual refresh only)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE dashboards (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id UUID           NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name        VARCHAR(255)    NOT NULL,
    slug        VARCHAR(100)    NOT NULL,
    description TEXT,
    icon        VARCHAR(50),
    is_default  BOOLEAN         NOT NULL DEFAULT FALSE,
    is_locked   BOOLEAN         NOT NULL DEFAULT FALSE,
    visibility  VARCHAR(20)     NOT NULL DEFAULT 'workspace'
                                CHECK (visibility IN ('private','workspace','project','organization','public')),
    refresh_interval INT,                                       -- auto-refresh seconds, NULL = manual
    created_by  UUID            NOT NULL REFERENCES users(id),
    updated_by  UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (workspace_id, slug)
);

COMMENT ON TABLE dashboards IS
    'Dashboard identity and permissions. Layout/widgets stored in MongoDB dashboard_layouts.';

-- ─────────────────────────────────────────────────────────────────────────────
-- DASHBOARD PERMISSIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Fine-grained per-dashboard access beyond workspace membership.
-- Grants specific capabilities to users, roles, or teams.
--
-- RELATIONSHIPS:
--   dashboard_permissions.dashboard_id ──→ dashboards.id (N:1) The dashboard
--   dashboard_permissions.grantee_id   ──→ (polymorphic: users.id | roles.id | team_id)
--   dashboard_permissions.granted_by   ──→ users.id      (N:1) Who granted this permission
--
-- JOIN PATHS:
--   Dashboard → Permissions:  dashboards → dashboard_permissions
--   Check user access:
--     SELECT * FROM dashboard_permissions
--     WHERE dashboard_id = $dash
--       AND ((grantee_type = 'user' AND grantee_id = $user_id)
--         OR (grantee_type = 'role' AND grantee_id IN (SELECT role_id FROM user_role_assignments
--             WHERE user_id = $user_id AND ...)))
--
-- NOTES:
--   • (dashboard_id, grantee_type, grantee_id) is UNIQUE — one grant per grantee
--   • grantee_type: 'user' (direct), 'role' (via RBAC role), 'team' (future)
--   • can_publish: allows pushing personal layout → shared scope
--   • granted_by specifically identifies who granted this access — NOT redundant
--     with "created_by" because it carries accountability semantics
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE dashboard_permissions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    dashboard_id    UUID        NOT NULL REFERENCES dashboards(id) ON DELETE CASCADE,
    grantee_type    VARCHAR(20) NOT NULL CHECK (grantee_type IN ('user','role','team')),
    grantee_id      UUID        NOT NULL,
    can_view        BOOLEAN     NOT NULL DEFAULT TRUE,
    can_edit        BOOLEAN     NOT NULL DEFAULT FALSE,
    can_publish     BOOLEAN     NOT NULL DEFAULT FALSE,
    can_share       BOOLEAN     NOT NULL DEFAULT FALSE,
    granted_by      UUID        REFERENCES users(id) ON DELETE SET NULL,
    granted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (dashboard_id, grantee_type, grantee_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- VIEWS
-- ─────────────────────────────────────────────────────────────────────────────
-- A View is a saved way to look at a Collection's data.
-- Same collection can have table view, kanban view, calendar view, etc.
-- Filter/sort/group/field-visibility configs live in MongoDB (view_configs).
--
-- RELATIONSHIPS:
--   views.collection_id ──→ collections.id       (N:1) The data being viewed
--   views.workspace_id  ──→ workspaces.id        (N:1) The workspace context
--   views.created_by    ──→ users.id             (N:1) Who created this view
--   views.updated_by    ──→ users.id             (N:1) Who last modified view metadata
--   views.id            ←── view_permissions.view_id (1:N) Per-view access
--   views.id            ──→ MongoDB view_configs.view_id (1:N) Filter/sort configs
--
-- JOIN PATHS:
--   Collection → Views:     collections → views
--   View → Permissions:     views → view_permissions
--   View → Config:          views.id = MongoDB view_configs.view_id
--   Workspace → Views:      workspaces → views
--   Full chain:             workspaces → collections → views → view_permissions
--
-- NOTES:
--   • (collection_id, slug) is UNIQUE — view slugs unique per collection
--   • view_type determines the UI renderer: table, kanban, calendar, gallery, etc.
--   • is_default: if TRUE, this view is shown when opening the collection
--   • visibility works the same as dashboard visibility
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE views (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id   UUID            NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    workspace_id    UUID            NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    slug            VARCHAR(100)    NOT NULL,
    view_type       VARCHAR(50)     NOT NULL
                    CHECK (view_type IN (
                        'table','kanban','calendar','gallery','form',
                        'chart','timeline','map','list','pivot'
                    )),
    is_default      BOOLEAN         NOT NULL DEFAULT FALSE,
    is_locked       BOOLEAN         NOT NULL DEFAULT FALSE,
    visibility      VARCHAR(20)     NOT NULL DEFAULT 'workspace'
                                    CHECK (visibility IN ('private','workspace','project','organization')),
    created_by      UUID            NOT NULL REFERENCES users(id),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (collection_id, slug)
);

COMMENT ON TABLE views IS
    'View identity and type. Filters, sorts, field visibility stored in MongoDB view_configs.';

-- ─────────────────────────────────────────────────────────────────────────────
-- VIEW PERMISSIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Per-view access grants beyond workspace membership.
--
-- RELATIONSHIPS:
--   view_permissions.view_id    ──→ views.id (N:1) The view
--   view_permissions.grantee_id ──→ (polymorphic: users.id | roles.id | team_id)
--   view_permissions.granted_by ──→ users.id  (N:1) Who granted access
--
-- JOIN PATHS:
--   View → Permissions: views → view_permissions
--   Check user access:  Similar pattern to dashboard_permissions
--
-- NOTES:
--   • (view_id, grantee_type, grantee_id) is UNIQUE — one grant per grantee per view
--   • granted_by identifies the administrator who set this access grant
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE view_permissions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    view_id         UUID        NOT NULL REFERENCES views(id) ON DELETE CASCADE,
    grantee_type    VARCHAR(20) NOT NULL CHECK (grantee_type IN ('user','role','team')),
    grantee_id      UUID        NOT NULL,
    can_view        BOOLEAN     NOT NULL DEFAULT TRUE,
    can_edit        BOOLEAN     NOT NULL DEFAULT FALSE,
    granted_by      UUID        REFERENCES users(id) ON DELETE SET NULL,
    granted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (view_id, grantee_type, grantee_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- DASHBOARD TEMPLATES
-- ─────────────────────────────────────────────────────────────────────────────
-- Pre-built dashboard templates that organizations can use as starting points.
-- When a user "applies a template", the template_data is cloned into a new
-- MongoDB dashboard_layout document.
--
-- RELATIONSHIPS:
--   dashboard_templates.organization_id ──→ organizations.id (N:1) Owning org (NULL = global)
--   dashboard_templates.created_by      ──→ users.id         (N:1) Template author
--   dashboard_templates.updated_by      ──→ users.id         (N:1) Last modifier
--
-- JOIN PATHS:
--   Org → Templates:    organizations → dashboard_templates
--   Global templates:   dashboard_templates WHERE organization_id IS NULL AND is_public = TRUE
--
-- NOTES:
--   • organization_id IS NULL → global/platform template (available to all orgs)
--   • is_public: if TRUE, template is visible across all organizations
--   • template_data stores serialized layout + widget config as JSONB
--   • category enables template marketplace filtering (sales, engineering, hr, etc.)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE dashboard_templates (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            REFERENCES organizations(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    description     TEXT,
    category        VARCHAR(100),                               -- "sales", "engineering", "hr", etc.
    thumbnail_url   TEXT,
    is_public       BOOLEAN         NOT NULL DEFAULT FALSE,
    template_data   JSONB           NOT NULL DEFAULT '{}',      -- serialized layout + widget config
    created_by      UUID            NOT NULL REFERENCES users(id),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);
