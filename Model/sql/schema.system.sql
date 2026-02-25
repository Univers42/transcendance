-- ============================================================================
-- schema.system.sql — Webhooks, Notifications, Policy Rules, File Uploads
-- ============================================================================
--
-- DOMAIN: Platform-level system services — outbound events, in-app
-- notifications, organization-wide ABAC policies, and file management.
--
-- POLICY RULES AND THE PERMISSION CHAIN:
--   Policy rules are step 5 in the permission resolution order
--   (see schema.user.sql header for the full chain):
--
--     1. user_permissions (explicit deny/allow)
--     2. role_permissions (via user_role_assignments)
--     3. abac_conditions (per-permission / per-role ABAC)
--     4. >>> policy_rules (THIS TABLE — org-level ABAC policies) <<<
--     5. resource_permissions (per-resource grants)
--     6. entity permissions (dashboard/view permissions)
--     7. Default: DENY
--
--   Policy rules differ from abac_conditions:
--     abac_conditions → attached to a PERMISSION, evaluated when checking that permission
--     policy_rules    → attached to an ORGANIZATION, evaluated for all resources of a type
--
--   Example policy rule:
--     "Viewers cannot access collections with sensitivity = 'confidential'"
--     → resource_type='collection', conditions={"and":[
--         {"attr":"user.role","op":"eq","val":"viewer"},
--         {"attr":"resource.sensitivity","op":"eq","val":"confidential"}
--       ]}, effect='deny'
--
-- EXECUTION ORDER: Run AFTER schema.resource.sql (depends on organizations, users).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- WEBHOOKS
-- ─────────────────────────────────────────────────────────────────────────────
-- Outbound event notifications to external services. When platform events
-- occur (record created, view changed, etc.), matching webhooks are triggered.
--
-- RELATIONSHIPS:
--   webhooks.organization_id ──→ organizations.id       (N:1) Owning organization
--   webhooks.created_by      ──→ users.id               (N:1) Who configured this webhook
--   webhooks.updated_by      ──→ users.id               (N:1) Who last modified it
--   webhooks.id              ←── webhook_deliveries.webhook_id (1:N) Delivery history
--
-- JOIN PATHS:
--   Org → Webhooks:       organizations → webhooks
--   Webhook → Deliveries: webhooks → webhook_deliveries (ORDER BY delivered_at DESC)
--
-- EVENT SYSTEM:
--   events array contains subscribed event types:
--     "record.created", "record.updated", "record.deleted",
--     "view.changed", "dashboard.updated", "member.added", etc.
--   When an event fires, backend:
--     1. Finds matching webhooks (organization_id + event type + is_active)
--     2. Serializes event payload
--     3. POSTs to webhook.url with signature in X-Webhook-Signature header
--     4. Logs result in webhook_deliveries
--     5. Retries on failure (retry_count times, retry_delay_ms apart)
--
-- NOTES:
--   • secret_hash is used to compute HMAC signatures for payload verification
--   • headers JSONB allows custom HTTP headers (auth tokens, content types)
--   • is_active allows disabling without deleting (preserves config + history)
--   • last_triggered_at / last_status provide quick health check without joining deliveries
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE webhooks (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    url             TEXT            NOT NULL,
    secret_hash     TEXT,
    headers         JSONB           NOT NULL DEFAULT '{}',
    events          VARCHAR(100)[]  NOT NULL,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    retry_count     INT             NOT NULL DEFAULT 3,
    retry_delay_ms  INT             NOT NULL DEFAULT 1000,
    last_triggered_at TIMESTAMPTZ,
    last_status     VARCHAR(20),
    created_by      UUID            NOT NULL REFERENCES users(id),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- WEBHOOK DELIVERIES (delivery log)
-- ─────────────────────────────────────────────────────────────────────────────
-- Immutable log of every webhook delivery attempt. Used for debugging
-- and retry tracking.
--
-- RELATIONSHIPS:
--   webhook_deliveries.webhook_id ──→ webhooks.id (N:1) The webhook that fired
--
-- JOIN PATHS:
--   Webhook → Deliveries: webhooks → webhook_deliveries (ORDER BY delivered_at DESC)
--   Failed deliveries:    webhook_deliveries WHERE response_status >= 400
--   Retry attempts:       webhook_deliveries WHERE webhook_id = $id AND event_type = $type
--                           ORDER BY attempt_number
--
-- NOTES:
--   • This is an IMMUTABLE event log — no updated_at/updated_by needed
--   • response_status: HTTP status code from the external server
--   • attempt_number: tracks retry attempts (1 = first try, 2+ = retries)
--   • duration_ms: round-trip time for performance monitoring
--   • payload JSONB: the full event payload that was sent
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE webhook_deliveries (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    webhook_id      UUID        NOT NULL REFERENCES webhooks(id) ON DELETE CASCADE,
    event_type      VARCHAR(100) NOT NULL,
    payload         JSONB       NOT NULL,
    response_status INT,
    response_body   TEXT,
    attempt_number  INT         NOT NULL DEFAULT 1,
    delivered_at    TIMESTAMPTZ NOT NULL DEFAULT now(),
    duration_ms     INT
);

-- ─────────────────────────────────────────────────────────────────────────────
-- NOTIFICATIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- In-app notification references. Rich notification payloads can be stored
-- in MongoDB if needed; this table provides the index for UI queries.
--
-- RELATIONSHIPS:
--   notifications.user_id ──→ users.id (N:1) The user who receives this notification
--
-- JOIN PATHS:
--   User → Notifications:   users → notifications (ORDER BY created_at DESC)
--   Unread count:            SELECT COUNT(*) FROM notifications WHERE user_id=$id AND is_read=FALSE
--   Notification → Source:   notifications.resource_type + resource_id → resources
--
-- NOTES:
--   • type categorizes the notification: mention, share, comment, sync_complete, system
--   • resource_type + resource_id provide optional deep-link context
--   • action_url: direct deep link into the app (e.g., /org/project/workspace/dashboard)
--   • Notifications are IMMUTABLE once created (no updated_at). Read state is the only
--     mutable field (is_read), which is a simple boolean flag, not an "edit"
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE notifications (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id         UUID            NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    type            VARCHAR(50)     NOT NULL,
    title           VARCHAR(255)    NOT NULL,
    message         TEXT,
    is_read         BOOLEAN         NOT NULL DEFAULT FALSE,
    resource_type   VARCHAR(50),
    resource_id     UUID,
    action_url      TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- POLICY RULES (organization-level ABAC policies)
-- ─────────────────────────────────────────────────────────────────────────────
-- Organization-wide ABAC policies evaluated at resource access time.
-- Unlike abac_conditions (which are per-permission and optionally per-role),
-- policy rules are broad organizational policies that apply across all
-- users accessing resources of a given type.
--
-- RELATIONSHIPS:
--   policy_rules.organization_id ──→ organizations.id (N:1) Owning organization
--   policy_rules.created_by      ──→ users.id         (N:1) Who created this policy
--   policy_rules.updated_by      ──→ users.id         (N:1) Who last modified it
--
-- DIFFERENCE FROM abac_conditions:
--   abac_conditions:
--     → Scoped to a PERMISSION (and optionally a ROLE)
--     → "When checking dashboard:read permission, require user.department = 'engineering'"
--     → Fine-grained, per-permission, per-role
--
--   policy_rules:
--     → Scoped to an ORGANIZATION + resource_type
--     → "In this organization, deny access to any collection where sensitivity = 'confidential'
--        for users whose role is 'viewer'"
--     → Broad organizational policies, evaluated for all access to matching resource types
--
-- JOIN PATHS:
--   Org → Policies:     organizations → policy_rules (WHERE is_active = TRUE)
--   Policy evaluation:  SELECT * FROM policy_rules
--                        WHERE organization_id = $org
--                          AND (resource_type = $type OR resource_type = '*')
--                          AND is_active = TRUE
--                        ORDER BY priority DESC
--
-- CONDITIONS FORMAT:
--   JSONB expression tree evaluated at runtime:
--   {"and": [
--     {"attr": "user.department", "op": "eq", "val": "finance"},
--     {"or": [
--       {"attr": "resource.visibility", "op": "eq", "val": "public"},
--       {"attr": "resource.created_by", "op": "eq", "val": "$user.id"}
--     ]}
--   ]}
--
-- NOTES:
--   • priority: higher = evaluated first. At same priority, deny wins over allow
--   • resource_type = '*' matches all resource types
--   • effect: 'allow' or 'deny'
--   • is_active allows disabling without deleting (useful for testing policies)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE policy_rules (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    description     TEXT,
    resource_type   VARCHAR(50)     NOT NULL,
    conditions      JSONB           NOT NULL,
    effect          VARCHAR(10)     NOT NULL
                    CHECK (effect IN ('allow','deny')),
    priority        INT             NOT NULL DEFAULT 0,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_by      UUID            NOT NULL REFERENCES users(id),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE policy_rules IS
    'Organization ABAC policies evaluated at resource access time. See header for distinction from abac_conditions.';

-- ─────────────────────────────────────────────────────────────────────────────
-- FILE UPLOADS
-- ─────────────────────────────────────────────────────────────────────────────
-- Managed file attachments linked to any resource. Files are stored on
-- external storage (S3, GCS, local) and referenced here.
--
-- RELATIONSHIPS:
--   file_uploads.organization_id ──→ organizations.id (N:1) Owning organization
--   file_uploads.uploaded_by     ──→ users.id         (N:1) Who uploaded this file
--
-- JOIN PATHS:
--   Org → Files:     organizations → file_uploads
--   User → Uploads:  users → file_uploads (via uploaded_by)
--   File → Resource: file_uploads.id → resources (WHERE resource_type='file')
--                      → resource_permissions, resource_tags, etc.
--
-- NOTES:
--   • stored_name is a UUID-based key that prevents filename collisions
--   • storage_path is the full path/key on the storage backend
--   • storage_backend: local, s3, gcs, azure
--   • uploaded_by is NOT a generic "created_by" — it specifically identifies the
--     person who performed the upload action, which is distinct from "who owns the file"
--   • Files are IMMUTABLE once uploaded (no updated_at). To "update" a file,
--     upload a new version and create a resource_version entry.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE file_uploads (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID        NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    filename        VARCHAR(500) NOT NULL,
    stored_name     VARCHAR(500) NOT NULL,
    mime_type       VARCHAR(100) NOT NULL,
    size_bytes      BIGINT      NOT NULL,
    storage_path    TEXT        NOT NULL,
    storage_backend VARCHAR(20) NOT NULL DEFAULT 'local'
                    CHECK (storage_backend IN ('local','s3','gcs','azure')),
    uploaded_by     UUID        NOT NULL REFERENCES users(id),
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);
