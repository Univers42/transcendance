-- ============================================================================
-- schema.user.sql — Users, Authentication, RBAC + ABAC, Sessions
-- ============================================================================
--
-- DOMAIN: Identity, authentication, and the full permission model.
--
-- DESIGN PHILOSOPHY:
--   We use RBAC (Role-Based Access Control) as the structural backbone, with
--   ABAC (Attribute-Based Access Control) conditions layered on top for
--   fine-grained, contextual access decisions.
--
-- PERMISSION RESOLUTION ORDER (evaluated top-to-bottom, first match wins):
--   1. user_permissions  → explicit deny (granted = FALSE) always wins
--   2. user_permissions  → explicit allow (granted = TRUE)
--   3. role_permissions  → via user_role_assignments → role_permissions
--   4. abac_conditions   → attached to permission, optionally scoped per role
--   5. policy_rules      → org-wide ABAC policies (see schema.system.sql)
--   6. resource_permissions → per-resource grants (see schema.resource.sql)
--   7. entity permissions → dashboard_permissions, view_permissions
--   8. Default: DENY
--
-- 5NF COMPLIANCE NOTES ON AUDIT COLUMNS:
--   Audit columns (created_at, updated_at, created_by, updated_by) are kept
--   on each entity table rather than extracted into a shared audit_metadata
--   table. This is NOT a 5NF violation because:
--
--     • Each column is functionally dependent on the entity's primary key
--       (i.e., "when was entity X created?" is an attribute OF entity X)
--     • Extracting them would create a mandatory 1:1 join for every query
--       with zero normalization benefit — the join dependency is implied
--       by the candidate key, which is exactly what 5NF requires
--     • Fields like invited_by, granted_by, assigned_by are semantically
--       distinct per context (they describe WHO performed THAT SPECIFIC
--       action on THAT entity), not a generic duplicate
--
--   Full event-sourced audit history is stored in MongoDB (audit_log
--   collection) for complete traceability without burdening SQL queries.
--
-- ROLE ↔ USER ↔ ABAC CONNECTIVITY:
--
--   users─┬──→ user_role_assignments ──→ roles ──→ role_permissions ──→ permissions
--         │     (context_type/context_id     │                              │
--         │      scopes role to org/          │                              │
--         │      project/workspace)           │                              │
--         │                                   │                              │
--         ├──→ user_permissions ──────────────┼─────────────────────────────→│
--         │    (direct grant/deny override)   │                              │
--         │                                   │                              │
--         └───────────────────────────────────└─── abac_conditions ─────────→┘
--                                                  (optional role_id scopes
--                                                   conditions per role)
--
-- EXECUTION ORDER: Run this file FIRST (before all other schema files).
-- ============================================================================

-- Required extensions (idempotent)
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- ─────────────────────────────────────────────────────────────────────────────
-- USERS
-- ─────────────────────────────────────────────────────────────────────────────
-- Core identity table. Every person on the platform has exactly one row here.
--
-- RELATIONSHIPS (this entity is referenced by almost every other table):
--   users.id ←── oauth_accounts.user_id          (1:N) Linked OAuth providers
--   users.id ←── user_role_assignments.user_id    (1:N) Roles assigned to user
--   users.id ←── user_permissions.user_id         (1:N) Direct permission overrides
--   users.id ←── user_sessions.user_id            (1:N) Active login sessions
--   users.id ←── contacts.user_id                 (1:N) User's personal address book
--   users.id ←── api_keys.user_id                 (1:N) Programmatic API tokens
--   users.id ←── organization_members.user_id     (1:N) Org memberships
--   users.id ←── project_members.user_id          (1:N) Project participations
--   users.id ←── workspace_members.user_id        (1:N) Workspace access
--   users.id ←── notifications.user_id            (1:N) In-app notifications
--   users.id ←── organizations.created_by         (1:N) Orgs founded by user
--   users.id ←── projects.created_by              (1:N) Projects created by user
--   users.id ←── workspaces.created_by            (1:N) Workspaces created by user
--   users.id ←── dashboards.created_by            (1:N) Dashboards created by user
--   users.id ←── collections.created_by           (1:N) Collections created by user
--   users.id ←── resources.created_by             (1:N) Resources registered by user
--
-- JOIN PATHS:
--   User → Roles:       users → user_role_assignments → roles
--   User → Permissions: users → user_role_assignments → roles → role_permissions → permissions
--                   OR: users → user_permissions → permissions (direct override)
--   User → Orgs:        users → organization_members → organizations
--   User → Workspaces:  users → workspace_members → workspaces → projects → organizations
--
-- NOTES:
--   • password_hash is NULL for OAuth-only users (login exclusively via provider)
--   • mfa_secret is encrypted at application level, not by PostgreSQL
--   • Profile preferences, themes, notification settings live in MongoDB (user_preferences)
--   • updated_by tracks which user (self or admin) last modified this profile
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE users (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    email           VARCHAR(255)    NOT NULL UNIQUE,
    username        VARCHAR(100)    NOT NULL UNIQUE,
    display_name    VARCHAR(255),
    avatar_url      TEXT,
    password_hash   TEXT,                           -- NULL for OAuth-only users
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    mfa_enabled     BOOLEAN         NOT NULL DEFAULT FALSE,
    mfa_secret      TEXT,                           -- encrypted at application level
    status          VARCHAR(20)     NOT NULL DEFAULT 'offline'
                                    CHECK (status IN ('online','offline','busy','away')),
    last_login_at   TIMESTAMPTZ,
    last_seen_at    TIMESTAMPTZ,
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE users IS 'Core user accounts. Profile metadata lives in MongoDB user_preferences.';

-- ─────────────────────────────────────────────────────────────────────────────
-- OAUTH ACCOUNTS
-- ─────────────────────────────────────────────────────────────────────────────
-- Links one or more OAuth providers to a single user account.
-- A user can log in via multiple providers (42, Google, GitHub, etc.).
--
-- RELATIONSHIPS:
--   oauth_accounts.user_id ──→ users.id  (N:1) The user who owns this OAuth link
--
-- JOIN PATHS:
--   OAuth → User: oauth_accounts → users
--   Find all providers for a user: users → oauth_accounts
--
-- NOTES:
--   • (provider, provider_id) is UNIQUE — each external account maps to exactly one user
--   • access_token and refresh_token are encrypted at application level
--   • No updated_at because token refresh is handled at app level, not tracked in schema
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE oauth_accounts (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    provider            VARCHAR(50) NOT NULL,                   -- "42", "google", "github", etc.
    provider_id         VARCHAR(255) NOT NULL,
    access_token        TEXT,                                   -- encrypted
    refresh_token       TEXT,                                   -- encrypted
    token_expires_at    TIMESTAMPTZ,
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (provider, provider_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ROLES
-- ─────────────────────────────────────────────────────────────────────────────
-- RBAC roles scoped by organization and hierarchy level (scope column).
-- System roles (is_system = TRUE) are seeded at bootstrap and immutable.
--
-- RELATIONSHIPS:
--   roles.organization_id ──→ organizations.id             (N:1) Owning organization
--   roles.id              ←── role_permissions.role_id      (1:N) Permissions this role grants
--   roles.id              ←── user_role_assignments.role_id (1:N) Users holding this role
--   roles.id              ←── abac_conditions.role_id       (1:N) ABAC conditions scoped to role
--
-- JOIN PATHS:
--   Role → Permissions: roles → role_permissions → permissions
--   Role → Users:       roles → user_role_assignments → users
--   Role → ABAC:        roles → abac_conditions (optional scoping)
--   Role → Org:         roles → organizations
--
-- SCOPE COLUMN (5NF-compliant hierarchy):
--   Defines at which hierarchy level this role operates:
--     'global'       → platform-wide (e.g., super_admin). organization_id IS NULL.
--     'organization' → org-wide (e.g., org_admin, org_billing).
--     'project'      → project-level (e.g., project_editor).
--     'workspace'    → workspace-level (e.g., workspace_viewer).
--
--   The application MUST enforce that when assigning via user_role_assignments,
--   the assignment's context_type matches the role's scope.
--
-- NOTES:
--   • FK to organizations.id is deferred: added via ALTER TABLE in schema.organization.sql
--     because organizations depends on users, which depends on this file running first
--   • (organization_id, name, scope) is UNIQUE — role names are unique per org per scope level
--   • System roles are pre-seeded: global_admin, org_owner, org_admin, org_member,
--     org_viewer, org_billing, project_admin, project_editor, project_member,
--     project_viewer, workspace_admin, workspace_editor, workspace_member,
--     workspace_viewer
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE roles (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID,                                       -- FK added after organizations table
    name            VARCHAR(100)    NOT NULL,
    description     TEXT,
    scope           VARCHAR(20)     NOT NULL DEFAULT 'organization'
                                    CHECK (scope IN ('global','organization','project','workspace')),
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (organization_id, name, scope)
);

COMMENT ON TABLE roles IS 'RBAC roles scoped per organization and hierarchy level. System roles apply globally.';

-- ─────────────────────────────────────────────────────────────────────────────
-- PERMISSIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Atomic permission definitions using resource_type:action naming convention.
-- Permissions are system-defined (platform-wide) and do not belong to any org.
-- e.g., "dashboard:create", "collection:read", "workspace:delete"
--
-- RELATIONSHIPS:
--   permissions.id ←── role_permissions.permission_id  (1:N) Roles that include this permission
--   permissions.id ←── user_permissions.permission_id  (1:N) Users directly granted/denied
--   permissions.id ←── abac_conditions.permission_id   (1:N) ABAC conditions on this permission
--
-- JOIN PATHS:
--   Permission → Roles: permissions → role_permissions → roles
--   Permission → Users (direct): permissions → user_permissions → users
--   Permission → Users (via roles): permissions → role_permissions → roles
--                                     → user_role_assignments → users
--   Permission → ABAC: permissions → abac_conditions
--
-- NOTES:
--   • (resource_type, action) is UNIQUE — one permission per resource+action pair
--   • name column follows the convention "{resource_type}:{action}" for readability
--   • No updated_at: permissions are immutable system definitions, never edited
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE permissions (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(255)    NOT NULL UNIQUE,            -- "dashboard:create"
    description     TEXT,
    resource_type   VARCHAR(100)    NOT NULL,                   -- "dashboard", "collection", etc.
    action          VARCHAR(50)     NOT NULL,                   -- "create","read","update","delete","publish","share","manage"
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (resource_type, action)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- ROLE ↔ PERMISSION (many-to-many junction)
-- ─────────────────────────────────────────────────────────────────────────────
-- Maps which permissions each role grants. This is the core of RBAC.
--
-- RELATIONSHIPS:
--   role_permissions.role_id       ──→ roles.id       (N:1) The role
--   role_permissions.permission_id ──→ permissions.id  (N:1) The permission
--
-- JOIN PATHS:
--   Full RBAC chain: users → user_role_assignments → roles
--                      → role_permissions → permissions
--
-- NOTES:
--   • Composite PK (role_id, permission_id) ensures no duplicate grants
--   • CASCADE on both FKs: deleting a role or permission cleans up this junction
--   • No timestamps: structural mapping fact, audit trail in MongoDB audit_log
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE role_permissions (
    role_id         UUID    NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    permission_id   UUID    NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    PRIMARY KEY (role_id, permission_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- USER ↔ ROLE ASSIGNMENT (scoped, temporal)
-- ─────────────────────────────────────────────────────────────────────────────
-- Assigns roles to users within a specific context (org, project, workspace,
-- or globally). Supports temporal roles with expires_at.
--
-- RELATIONSHIPS:
--   user_role_assignments.user_id     ──→ users.id  (N:1) The user receiving the role
--   user_role_assignments.role_id     ──→ roles.id  (N:1) The role being assigned
--   user_role_assignments.assigned_by ──→ users.id  (N:1) The admin who granted the role
--   user_role_assignments.context_id  ──→ (polymorphic: organizations.id | projects.id | workspaces.id)
--
-- CONTEXT SYSTEM (5NF-COMPLIANT ROLE SCOPING):
--   Instead of duplicating role VARCHAR columns across organization_members,
--   project_members, and workspace_members tables (which violates 3NF by
--   representing the same concept in multiple places with CHECK constraints
--   instead of FK references), ALL role assignments flow through this single
--   table with context_type/context_id:
--
--     context_type = 'global'       → context_id IS NULL (platform-wide)
--     context_type = 'organization' → context_id = organizations.id
--     context_type = 'project'      → context_id = projects.id
--     context_type = 'workspace'    → context_id = workspaces.id
--
-- JOIN PATHS:
--   User's org roles:
--     SELECT r.name FROM user_role_assignments ura
--     JOIN roles r ON r.id = ura.role_id
--     WHERE ura.user_id = $user AND ura.context_type = 'organization'
--           AND ura.context_id = $org_id
--           AND (ura.expires_at IS NULL OR ura.expires_at > now());
--
--   User's workspace permissions:
--     users → user_role_assignments (WHERE context_type='workspace' AND context_id=$ws_id)
--           → roles → role_permissions → permissions
--
-- NOTES:
--   • context_id FK is polymorphic and cannot be enforced at DB level.
--     Application layer validates referential integrity.
--   • Application MUST enforce that role.scope matches context_type at assignment time
--   • expires_at enables temporary elevated access (e.g., "admin for 24h during incident")
--   • assigned_by is NOT a redundant "created_by" — it specifically records the
--     administrator who performed this role grant action
--   • CHECK constraint ensures global roles have NULL context_id and scoped roles have non-NULL
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE user_role_assignments (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    role_id         UUID        NOT NULL REFERENCES roles(id) ON DELETE CASCADE,
    context_type    VARCHAR(20) NOT NULL DEFAULT 'global'
                                CHECK (context_type IN ('global','organization','project','workspace')),
    context_id      UUID,                                       -- NULL for global, entity ID for scoped
    assigned_by     UUID        REFERENCES users(id) ON DELETE SET NULL,
    assigned_at     TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ,                                -- NULL = permanent

    CHECK (
        (context_type = 'global' AND context_id IS NULL) OR
        (context_type IN ('organization','project','workspace') AND context_id IS NOT NULL)
    )
);

-- Unique constraint: a user can hold each role only once per context.
-- COALESCE handles NULL context_id for global roles since PostgreSQL
-- treats NULL as distinct in UNIQUE constraints.
CREATE UNIQUE INDEX idx_ura_unique_assignment
    ON user_role_assignments (
        user_id, role_id, context_type,
        COALESCE(context_id, '00000000-0000-0000-0000-000000000000'::UUID)
    );

-- ─────────────────────────────────────────────────────────────────────────────
-- ABAC CONDITIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Fine-grained attribute conditions attached to permissions, optionally
-- scoped to a specific role. Evaluated at runtime against user, resource,
-- and environment attributes.
--
-- RELATIONSHIPS:
--   abac_conditions.permission_id ──→ permissions.id (N:1) The permission being constrained
--   abac_conditions.role_id       ──→ roles.id       (N:1) Optional: scopes condition to one role
--
-- ROLE-SCOPED ABAC (the role_id column — this is the ABAC↔RBAC bridge):
--   When role_id IS NULL:
--     → Condition applies to ALL roles that hold this permission
--   When role_id IS NOT NULL:
--     → Condition ONLY applies when the permission is accessed through that specific role
--
--   EXAMPLE — "dashboard:read" permission with mixed ABAC scoping:
--     Condition 1: role_id=NULL, attr="resource.visibility", op="neq", val="deleted"
--       → ALL roles: cannot read deleted dashboards (global guard)
--     Condition 2: role_id=<member_role_id>, attr="user.department", op="eq", val="engineering"
--       → MEMBERS only: can only read dashboards if user is in engineering department
--     No condition for admin role:
--       → ADMINS: can read ALL dashboards (no ABAC restriction imposed)
--
-- JOIN PATHS:
--   ABAC evaluation query:
--     SELECT * FROM abac_conditions
--     WHERE permission_id = $perm_id
--       AND (role_id IS NULL OR role_id = $user_current_role_id)
--     ORDER BY logic_group;
--
--   Full ABAC chain:
--     users → user_role_assignments → roles ──┐
--                                              ├──→ abac_conditions
--     permissions ─────────────────────────────┘
--
-- NOTES:
--   • Multiple conditions for same permission+role are grouped via logic_group (AND/OR)
--   • attribute_key uses dot-path: "user.department", "resource.sensitivity", "env.ip_range"
--   • attribute_value is JSONB to support scalar, array, range comparisons
--   • operator covers: eq, neq, in, not_in, gt, gte, lt, lte, contains, starts_with, between
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE abac_conditions (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    permission_id   UUID            NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    role_id         UUID            REFERENCES roles(id) ON DELETE CASCADE,  -- NULL = all roles
    attribute_key   VARCHAR(255)    NOT NULL,    -- dot-path: "user.department", "resource.sensitivity"
    operator        VARCHAR(50)     NOT NULL
                                    CHECK (operator IN ('eq','neq','in','not_in','gt','gte','lt','lte','contains','starts_with','between')),
    attribute_value JSONB           NOT NULL,    -- value(s) to compare against
    logic_group     VARCHAR(50)     NOT NULL DEFAULT 'AND'
                                    CHECK (logic_group IN ('AND', 'OR')),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE abac_conditions IS
    'Attribute-Based Access Control conditions layered on RBAC permissions, optionally scoped per role via role_id.';

-- ─────────────────────────────────────────────────────────────────────────────
-- DIRECT USER PERMISSIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Per-user permission overrides that bypass the role system entirely.
-- `granted = FALSE` creates an explicit deny that ALWAYS takes priority
-- over any role-based grant (see permission resolution order in header).
--
-- RELATIONSHIPS:
--   user_permissions.user_id       ──→ users.id       (N:1) The user receiving the override
--   user_permissions.permission_id ──→ permissions.id  (N:1) The permission being granted/denied
--   user_permissions.granted_by    ──→ users.id        (N:1) The admin who set this override
--
-- JOIN PATHS:
--   Direct permissions check:
--     SELECT * FROM user_permissions
--     WHERE user_id = $user AND permission_id = $perm
--       AND (expires_at IS NULL OR expires_at > now())
--
--   All direct grants: users → user_permissions → permissions
--
-- NOTES:
--   • (user_id, permission_id) is UNIQUE — one override per user per permission
--   • granted = FALSE = EXPLICIT DENY, overrides ALL role-based grants
--   • granted_by is NOT a redundant "created_by" — it specifically identifies
--     the administrator who set this permission override, which is critical
--     for permission audit trails and accountability
--   • Supports temporal overrides via expires_at (e.g., temp elevated access)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE user_permissions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    permission_id   UUID        NOT NULL REFERENCES permissions(id) ON DELETE CASCADE,
    granted         BOOLEAN     NOT NULL DEFAULT TRUE,          -- FALSE = explicit deny
    granted_by      UUID        REFERENCES users(id) ON DELETE SET NULL,
    granted_at      TIMESTAMPTZ NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ,

    UNIQUE (user_id, permission_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- USER SESSIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Tracks active authenticated sessions for token management and security audit.
--
-- RELATIONSHIPS:
--   user_sessions.user_id ──→ users.id (N:1) The authenticated user
--
-- JOIN PATHS:
--   Active sessions: users → user_sessions (WHERE is_active = TRUE)
--   Session validation: lookup by token_hash → check is_active + expires_at → resolve user
--
-- NOTES:
--   • token_hash stores a hashed JWT/session token (never plaintext)
--   • ip_address uses INET type for native PostgreSQL IP operations
--   • last_activity_at is updated on each request for session timeout detection
--   • is_active is set FALSE on logout; expired sessions cleaned by cron job
--   • No updated_by: sessions are system-managed, not user-edited
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE user_sessions (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id             UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    token_hash          VARCHAR(512)    NOT NULL,
    ip_address          INET,
    user_agent          TEXT,
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,
    expires_at          TIMESTAMPTZ     NOT NULL,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    last_activity_at    TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- CONTACTS (User address book)
-- ─────────────────────────────────────────────────────────────────────────────
-- A personal contact list per user. Contacts may or may not correspond to
-- existing platform users.
--
-- RELATIONSHIPS:
--   contacts.user_id         ──→ users.id (N:1) The user who owns this contact
--   contacts.contact_user_id ──→ users.id (N:1) Optional: the platform user this refers to
--   contacts.updated_by      ──→ users.id (N:1) Who last modified this contact
--
-- JOIN PATHS:
--   User's contacts: users → contacts
--   Contact → Platform user: contacts → users (via contact_user_id)
--
-- NOTES:
--   • contact_user_id is optional — contacts can be "external" (no platform account)
--   • metadata stores flexible key-value pairs (company, notes, custom fields)
--   • updated_by tracks which user (owner or admin) last edited the contact
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE contacts (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    contact_user_id UUID            REFERENCES users(id) ON DELETE SET NULL,
    first_name      VARCHAR(100),
    last_name       VARCHAR(100),
    email           VARCHAR(255),
    phone           VARCHAR(50),
    metadata        JSONB           NOT NULL DEFAULT '{}',
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- API KEYS
-- ─────────────────────────────────────────────────────────────────────────────
-- Long-lived tokens for programmatic API access. Each key has scopes that
-- limit which permissions it can exercise (subset of user's permissions).
--
-- RELATIONSHIPS:
--   api_keys.user_id ──→ users.id (N:1) The user who owns this API key
--
-- JOIN PATHS:
--   User's keys: users → api_keys
--   Key validation: lookup by key_hash → verify is_active + not expired → resolve user
--   Key permission check: api_keys.scopes ∩ user's effective permissions
--
-- NOTES:
--   • key_hash stores a hashed version (plaintext key shown once at creation, never stored)
--   • scopes array limits which permissions this key can exercise
--   • is_active allows revocation without deletion (preserves audit trail)
--   • last_used_at updated on each API call for monitoring
--   • No updated_at: keys are created then optionally revoked, not edited
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE api_keys (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id     UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    name        VARCHAR(255)    NOT NULL,
    key_hash    VARCHAR(512)    NOT NULL UNIQUE,
    scopes      VARCHAR(100)[]  NOT NULL DEFAULT '{}',          -- e.g., {"collection:read","dashboard:read"}
    is_active   BOOLEAN         NOT NULL DEFAULT TRUE,
    last_used_at TIMESTAMPTZ,
    expires_at  TIMESTAMPTZ,
    created_at  TIMESTAMPTZ     NOT NULL DEFAULT now()
);
