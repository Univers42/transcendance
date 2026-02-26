-- ============================================================================
-- schema.resource.sql — Universal Resource Registry, Permissions, Versioning
-- ============================================================================
--
-- DOMAIN: Polymorphic resource layer providing unified operations across
-- all platform entities (dashboards, collections, views, workspaces, files).
--
-- WHY A RESOURCE REGISTRY?
--   Without this, every entity type would need its own:
--     • Permission table (dashboard_permissions, collection_permissions, ...)
--     • Version history table
--     • Sharing mechanism
--     • Tagging system
--     • Comment system
--   The resource registry provides ALL of these once, for any entity type.
--   Entities register themselves here and inherit the full feature set.
--
-- HOW IT WORKS:
--   1. When a dashboard/collection/view/etc. is created:
--      → A row is inserted into resources with resource_type + resource_id
--   2. Resource-level permissions, versions, shares, tags, comments all
--      reference resources.id (not the entity directly)
--   3. Queries join: entity table ←→ resources ←→ resource_permissions/etc.
--
-- EXECUTION ORDER: Run AFTER schema.dashboard.sql (depends on organizations, users).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- RESOURCES (universal registry)
-- ─────────────────────────────────────────────────────────────────────────────
-- Polymorphic registry for all platform entities. Each significant entity
-- (dashboard, collection, view, etc.) gets a row here to inherit unified
-- permissions, versioning, sharing, tagging, and commenting.
--
-- RELATIONSHIPS:
--   resources.organization_id ──→ organizations.id    (N:1) Owning organization
--   resources.created_by      ──→ users.id            (N:1) Who registered this resource
--   resources.updated_by      ──→ users.id            (N:1) Who last modified resource metadata
--   resources.resource_id     ──→ (polymorphic: dashboards.id | collections.id | views.id | ...)
--   resources.id              ←── resource_permissions.resource_id  (1:N) Access grants
--   resources.id              ←── resource_versions.resource_id     (1:N) Version history
--   resources.id              ←── resource_shares.resource_id       (1:N) Shareable links
--   resources.id              ←── resource_relations.source_resource_id (1:N) Outgoing relations
--   resources.id              ←── resource_relations.target_resource_id (1:N) Incoming relations
--   resources.id              ←── resource_tags.resource_id         (1:N) Tags
--   resources.id              ←── comments.resource_id              (1:N) Comments
--
-- JOIN PATHS:
--   Entity → Resource:     dashboards.id → resources (WHERE resource_type='dashboard' AND resource_id=dashboards.id)
--   Resource → Permissions: resources → resource_permissions
--   Resource → Versions:    resources → resource_versions
--   Resource → Shares:      resources → resource_shares
--   Resource → Tags:        resources → resource_tags → tags
--   Resource → Comments:    resources → comments → users
--
-- NOTES:
--   • (resource_type, resource_id) is UNIQUE — one registry entry per entity
--   • resource_id FK is not enforced at DB level (polymorphic pattern)
--     Application layer ensures referential integrity
--   • resource_type enum covers all registerable entity types
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE resources (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    resource_type   VARCHAR(50)     NOT NULL
                    CHECK (resource_type IN (
                        'dashboard','collection','view','workspace','project',
                        'file','adapter','template','report'
                    )),
    resource_id     UUID            NOT NULL,                   -- FK to actual entity (polymorphic, not enforced)
    name            VARCHAR(255)    NOT NULL,
    created_by      UUID            NOT NULL REFERENCES users(id),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (resource_type, resource_id)
);

COMMENT ON TABLE resources IS
    'Polymorphic resource registry for unified permissions, versioning, sharing, and comments.';

-- ─────────────────────────────────────────────────────────────────────────────
-- RESOURCE PERMISSIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Resource-level access grants. These complement (not replace) the RBAC
-- permission system. They answer: "who can do what with THIS SPECIFIC resource?"
--
-- RELATIONSHIPS:
--   resource_permissions.resource_id ──→ resources.id (N:1) The resource
--   resource_permissions.grantee_id  ──→ (polymorphic: users.id | roles.id | organizations.id)
--   resource_permissions.granted_by  ──→ users.id     (N:1) Who granted this
--
-- PERMISSION RESOLUTION INTERACTION:
--   This is step 6 in the permission resolution chain (see schema.user.sql header):
--     1-3. RBAC check (user_permissions, role_permissions)
--     4.   ABAC conditions
--     5.   Policy rules
--     6.   >>> resource_permissions (this table) <<<
--     7.   Entity permissions (dashboard_permissions, view_permissions)
--     8.   Default: DENY
--
-- JOIN PATHS:
--   Resource → Permissions: resources → resource_permissions
--   Check user access:
--     SELECT * FROM resource_permissions
--     WHERE resource_id = $res_id
--       AND ((grantee_type='user' AND grantee_id=$user)
--         OR (grantee_type='role' AND grantee_id IN (...))
--         OR grantee_type='public')
--       AND (expires_at IS NULL OR expires_at > now())
--
-- NOTES:
--   • grantee_type 'public' uses grantee_id = NULL (anyone can access)
--   • actions array lists allowed operations: {"read","write","delete","share","manage"}
--   • granted_by tracks the administrator who set this grant
--   • expires_at enables temporary resource sharing
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE resource_permissions (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id     UUID            NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    grantee_type    VARCHAR(20)     NOT NULL
                    CHECK (grantee_type IN ('user','role','organization','team','public')),
    grantee_id      UUID,                                       -- NULL when grantee_type = 'public'
    actions         VARCHAR(50)[]   NOT NULL DEFAULT '{"read"}',
    granted_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    granted_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    expires_at      TIMESTAMPTZ
);

-- ─────────────────────────────────────────────────────────────────────────────
-- RESOURCE VERSIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Snapshot-based versioning for any resource. Each version stores the full
-- serialized state at that point in time.
--
-- RELATIONSHIPS:
--   resource_versions.resource_id ──→ resources.id (N:1) The versioned resource
--   resource_versions.created_by  ──→ users.id     (N:1) Who created this version
--
-- JOIN PATHS:
--   Resource → Versions: resources → resource_versions (ORDER BY version_number DESC)
--   Latest version:      resources → resource_versions WHERE version_number = (SELECT MAX(...))
--   Diff between versions: compare change_diff or snapshot JSONB between version_numbers
--
-- NOTES:
--   • (resource_id, version_number) is UNIQUE — monotonically increasing per resource
--   • snapshot stores FULL state (not delta) for reliable point-in-time recovery
--   • change_diff stores optional delta from previous version for UI diff display
--   • Versions are IMMUTABLE — no updated_at/updated_by needed
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE resource_versions (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id     UUID        NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    version_number  INT         NOT NULL,
    snapshot        JSONB       NOT NULL,                       -- full state at this version
    change_summary  TEXT,
    change_diff     JSONB,                                     -- optional delta from previous
    created_by      UUID        NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (resource_id, version_number)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- RESOURCE SHARES (public/private links)
-- ─────────────────────────────────────────────────────────────────────────────
-- Shareable links for resources. Supports link-based, email, and embed sharing
-- with optional password protection and usage limits.
--
-- RELATIONSHIPS:
--   resource_shares.resource_id ──→ resources.id (N:1) The shared resource
--   resource_shares.created_by  ──→ users.id     (N:1) Who created this share link
--
-- JOIN PATHS:
--   Resource → Shares:   resources → resource_shares
--   Share validation:     lookup by share_token → check is_active + not expired
--                          + use_count < max_uses → resolve resource → check permissions
--
-- NOTES:
--   • share_token is UNIQUE — used in URLs (/share/{token})
--   • share_type: 'link' (URL), 'email' (sent to specific email), 'embed' (iframe)
--   • password_hash: optional password protection (hashed)
--   • max_uses: limits how many times the link can be used (NULL = unlimited)
--   • use_count: incremented on each access
--   • Shares are IMMUTABLE once created (no updated_at) — revoke by setting is_active=FALSE
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE resource_shares (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id     UUID            NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    share_type      VARCHAR(20)     NOT NULL
                    CHECK (share_type IN ('link','email','embed')),
    share_token     VARCHAR(255)    UNIQUE,
    permissions     VARCHAR(50)[]   NOT NULL DEFAULT '{"read"}',
    password_hash   TEXT,
    expires_at      TIMESTAMPTZ,
    max_uses        INT,
    use_count       INT             NOT NULL DEFAULT 0,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_by      UUID            NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- RESOURCE RELATIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Cross-resource relationships. Allows linking any resource to any other
-- resource with typed relationships.
--
-- RELATIONSHIPS:
--   resource_relations.source_resource_id ──→ resources.id (N:1) Source resource
--   resource_relations.target_resource_id ──→ resources.id (N:1) Target resource
--
-- JOIN PATHS:
--   Outgoing: resources → resource_relations (source_resource_id) → resources
--   Incoming: resources → resource_relations (target_resource_id) → resources
--
-- NOTES:
--   • (source, target, relation_type) is UNIQUE — one relation type per pair
--   • relation_type examples:
--       depends_on:   dashboard depends_on collection (breaks if collection deleted)
--       linked_to:    two resources are cross-referenced
--       embedded_in:  view is embedded in a dashboard widget
--       derived_from: report is derived from an adapter's data
--       parent_of:    hierarchical grouping
--   • Relations are IMMUTABLE facts — no updated_at needed
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE resource_relations (
    id                  UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    source_resource_id  UUID        NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    target_resource_id  UUID        NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    relation_type       VARCHAR(50) NOT NULL
                        CHECK (relation_type IN ('depends_on','linked_to','embedded_in','derived_from','parent_of')),
    metadata            JSONB       NOT NULL DEFAULT '{}',
    created_at          TIMESTAMPTZ NOT NULL DEFAULT now(),

    UNIQUE (source_resource_id, target_resource_id, relation_type)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- TAGS
-- ─────────────────────────────────────────────────────────────────────────────
-- Organization-scoped taxonomy for labeling and filtering resources.
--
-- RELATIONSHIPS:
--   tags.organization_id ──→ organizations.id     (N:1) Owning organization
--   tags.id              ←── resource_tags.tag_id  (1:N) Tagged resources
--
-- JOIN PATHS:
--   Org → Tags:          organizations → tags
--   Tag → Resources:     tags → resource_tags → resources
--   Resource → Tags:     resources → resource_tags → tags
--
-- NOTES:
--   • (organization_id, slug) is UNIQUE — tag slugs unique per org
--   • Tags are simple labels — no updated_at needed (rename = new slug)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE tags (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name            VARCHAR(100)    NOT NULL,
    slug            VARCHAR(100)    NOT NULL,
    color           VARCHAR(7),
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (organization_id, slug)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- RESOURCE ↔ TAG (many-to-many junction)
-- ─────────────────────────────────────────────────────────────────────────────
-- Associates tags with resources. Pure junction table.
--
-- RELATIONSHIPS:
--   resource_tags.resource_id ──→ resources.id (N:1) The tagged resource
--   resource_tags.tag_id      ──→ tags.id      (N:1) The applied tag
--
-- JOIN PATHS:
--   Resource → Tags: resources → resource_tags → tags
--   Tag → Resources: tags → resource_tags → resources
--
-- NOTES:
--   • Composite PK ensures no duplicate tag assignments
--   • CASCADE on both FKs: resource or tag deletion cleans up
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE resource_tags (
    resource_id UUID NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    tag_id      UUID NOT NULL REFERENCES tags(id) ON DELETE CASCADE,
    PRIMARY KEY (resource_id, tag_id)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- COMMENTS
-- ─────────────────────────────────────────────────────────────────────────────
-- Threaded comments on any resource. Supports nested replies via parent_id
-- and resolved state for review workflows.
--
-- RELATIONSHIPS:
--   comments.resource_id ──→ resources.id (N:1) The resource being commented on
--   comments.user_id     ──→ users.id     (N:1) The comment author
--   comments.parent_id   ──→ comments.id  (N:1) Optional: parent comment for threads
--   comments.updated_by  ──→ users.id     (N:1) Who last edited this comment
--
-- JOIN PATHS:
--   Resource → Comments:    resources → comments (ORDER BY created_at)
--   Comment → Replies:      comments → comments (WHERE parent_id = comment.id)
--   Comment → Author:       comments → users (via user_id)
--   Full thread:            comments WHERE resource_id = $res AND parent_id IS NULL
--                             → comments WHERE parent_id IN (...) (recursive)
--
-- NOTES:
--   • parent_id enables threaded conversations (NULL = top-level comment)
--   • is_resolved: used in review workflows to mark comments as "addressed"
--   • updated_by tracks who last edited the comment (could be author or moderator)
--   • CASCADE on parent_id: deleting a parent deletes the entire thread
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE comments (
    id          UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    resource_id UUID        NOT NULL REFERENCES resources(id) ON DELETE CASCADE,
    user_id     UUID        NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    parent_id   UUID        REFERENCES comments(id) ON DELETE CASCADE,
    content     TEXT        NOT NULL,
    is_resolved BOOLEAN     NOT NULL DEFAULT FALSE,
    updated_by  UUID        REFERENCES users(id) ON DELETE SET NULL,
    created_at  TIMESTAMPTZ NOT NULL DEFAULT now(),
    updated_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);
