-- ============================================================================
-- schema.abac.sql — Enhanced ABAC Engine (Attribute-Based Access Control)
-- ============================================================================
--
-- DOMAIN: Composable, temporal, extensible access control.
--
-- DESIGN PHILOSOPHY:
--   ABAC-first with RBAC as a convenience layer. Inspired by the Unix/Linux
--   security model: capabilities define what actions are possible, ACLs
--   compose them per-context, and a single root/super_admin bypasses all.
--
--   ┌─────────────────────────┬──────────────────────────────────────────┐
--   │  Linux Model            │  ABAC Engine                             │
--   ├─────────────────────────┼──────────────────────────────────────────┤
--   │  Capabilities           │  Permissions (resource:action atoms)     │
--   │  ACLs                   │  Rule Groups (composable AND/OR/NOT)     │
--   │  Security Profiles      │  Policies (named bundles of groups)      │
--   │  Namespaces             │  Scopes (org → project → workspace)      │
--   │  uid 0 (root)           │  super_admin (bypass all)                │
--   │  Effective / Permitted  │  Resolved at eval time via priority      │
--   │  File mode bits         │  Rule effects (allow / deny per rule)    │
--   │  /etc/security/cap.*    │  Attribute Definitions (attr schema)     │
--   └─────────────────────────┴──────────────────────────────────────────┘
--
--   Key Invariants:
--     • DENY by default — no matching rule = access denied
--     • DENY wins at equal priority — explicit deny overrides allow
--     • One super_admin — only global_admin role fully bypasses evaluation
--     • Composable — rules → rule groups → policies (nestable depth)
--     • Temporal — every rule / assignment supports time bounds
--     • Extensible — define custom attributes, combine rules freely
--     • Dual-store — SQL for identity/structure, MongoDB for condition trees
--
-- PERMISSION RESOLUTION (full algorithm):
--
--   ┌─────────────────────────────────────────────────────────────────┐
--   │  Request: (user_id, action, resource_type, resource_id, ctx)    │
--   │                                                                 │
--   │  1. super_admin? ───────────────────────────→ ALLOW             │
--   │  2. user_permissions deny? ─────────────────→ DENY              │
--   │  3. user_permissions allow? ────────────────→ ALLOW             │
--   │  4. Collect ABAC policies:                                      │
--   │     ├── User direct policy assignments                          │
--   │     ├── User role → policy assignments                          │
--   │     └── Context cascade (workspace→project→org policies)        │
--   │  5. Filter: is_active, temporal (starts_at ≤ now ≤ expires_at)  │
--   │  6. Sort by priority DESC                                       │
--   │  7. For each policy:                                            │
--   │     ├── Evaluate rule groups (conditions from MongoDB)          │
--   │     ├── Apply group logic (AND/OR/NOT)                          │
--   │     └── If match → return policy effect (allow/deny)            │
--   │  8. RBAC fallback: role_permissions → permissions               │
--   │  9. Default: ─────────────────────────────> DENY                │
--   └─────────────────────────────────────────────────────────────────┘
--
-- ARCHITECTURE (dual-store split):
--
--   ┌──────────── PostgreSQL (Structure / Identity) ──────────────┐
--   │  abac_attribute_definitions  ← what attributes exist        │
--   │  abac_rules                  ← atomic rule metadata         │
--   │  abac_rule_groups            ← composable bundles AND/OR/NOT│
--   │  abac_rule_group_members     ← rules + nested groups in grp │
--   │  abac_policies               ← named policy containers      │
--   │  abac_policy_rule_groups     ← groups inside policies       │
--   │  abac_policy_assignments     ← who/where policies apply     │
--   └─────────────────────────────────────────────────────────────┘
--                    │ links by rule_id / user_id │
--   ┌──────────── MongoDB (Flexibility / Evaluation) ─────────────┐
--   │  abac_rule_conditions    ← nested condition trees per rule  │
--   │  abac_user_attributes    ← per-user custom attribute store  │
--   └─────────────────────────────────────────────────────────────┘
--
-- COMPOSABILITY EXAMPLE:
--
--   Rule: "is_engineer"      → user.department = 'engineering'
--   Rule: "low_sensitivity"  → resource.sensitivity ≤ 3
--   Rule: "business_hours"   → env.time BETWEEN '09:00' AND '17:00'
--   Rule: "on_vpn"           → env.ip_range IN '10.0.0.0/8'
--
--   Group: "Eng Data Access" (AND)
--     ├── is_engineer
--     └── low_sensitivity
--
--   Group: "Secure Context" (OR)
--     ├── business_hours
--     └── on_vpn
--
--   Group: "Guarded Eng Access" (AND)  ← nests groups in groups
--     ├── [Eng Data Access]
--     └── [Secure Context]
--
--   Policy: "Engineering Default" → contains [Guarded Eng Access]
--     Assigned to: role=org_member, org=acme-corp
--     Effect: ALLOW, Priority: 50
--     Valid: 2024-01-01 .. 2024-12-31
--
-- CUSTOM ADMIN VARIANTS (not all admins are equal):
--
--   "billing_admin"  → manage invoices/plans only
--   "content_admin"  → manage collections/dashboards only
--   "security_admin" → manage users/roles/policies only
--   "project_lead"   → full access to ONE project, read-only everywhere else
--
--   Each is just a different policy assignment — no special role required.
--
-- BACKWARD COMPATIBILITY:
--   This schema EXTENDS (does not replace) the existing RBAC tables:
--     • permissions, roles, role_permissions — still work as before
--     • user_role_assignments, user_permissions — still work
--     • abac_conditions (schema.user.sql) — legacy, still evaluated
--     • policy_rules (schema.system.sql) — legacy, still evaluated
--   The new ABAC engine adds an evaluation layer above legacy RBAC.
--
-- EXECUTION ORDER: Run AFTER schema.system.sql.
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- ATTRIBUTE DEFINITIONS (schema registry for ABAC attributes)
-- ─────────────────────────────────────────────────────────────────────────────
-- Defines WHAT attributes can appear in rule conditions.  Acts as a schema
-- registry so that rules reference validated, typed attribute paths.
--
-- CATEGORIES (modeled after XACML attribute categories):
--   • subject     — attributes of THE USER making the request
--                    (user.department, user.clearance, user.teams)
--   • resource    — attributes of THE RESOURCE being accessed
--                    (resource.sensitivity, resource.owner, resource.type)
--   • environment — attributes of THE CONTEXT / environment
--                    (env.time, env.ip, env.geo_location, env.mfa_verified)
--   • context     — attributes of THE REQUEST itself
--                    (context.action, context.http_method, context.request_source)
--   • custom      — tenant-defined attributes for domain-specific checks
--
-- RELATIONSHIPS:
--   abac_attribute_definitions.organization_id ──→ organizations.id (N:1)
--     NULL organization_id = global/system attribute (available to all orgs)
--   abac_attribute_definitions.created_by ──→ users.id (N:1)
--
-- NOTES:
--   • is_system = TRUE  → cannot be deleted by tenants (platform-managed)
--   • allowed_values     → constrains value space (optional enum validation)
--   • validation_regex   → pattern validation for string attributes
--   • default_value      → used when attribute is absent from a subject/resource
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE abac_attribute_definitions (
    id                UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id   UUID            REFERENCES organizations(id) ON DELETE CASCADE,
    name              VARCHAR(255)    NOT NULL,      -- dot-path: "user.department"
    display_name      VARCHAR(255)    NOT NULL,
    description       TEXT,
    category          VARCHAR(20)     NOT NULL
                      CHECK (category IN (
                          'subject', 'resource', 'environment', 'context', 'custom'
                      )),
    data_type         VARCHAR(20)     NOT NULL
                      CHECK (data_type IN (
                          'string', 'number', 'boolean', 'array', 'date', 'json', 'ip', 'cidr'
                      )),
    is_system         BOOLEAN         NOT NULL DEFAULT FALSE,
    is_multivalued    BOOLEAN         NOT NULL DEFAULT FALSE,
    allowed_values    JSONB,                         -- ["val1","val2",...] enum check
    validation_regex  VARCHAR(500),                  -- regex for string attrs
    default_value     JSONB,                         -- fallback when absent
    created_by        UUID            NOT NULL REFERENCES users(id),
    created_at        TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at        TIMESTAMPTZ     NOT NULL DEFAULT now()
);

-- Global attrs: unique per name when org IS NULL
CREATE UNIQUE INDEX idx_abac_attrdef_global
    ON abac_attribute_definitions (name)
    WHERE organization_id IS NULL;

-- Org-scoped attrs: unique per (org, name)
CREATE UNIQUE INDEX idx_abac_attrdef_org
    ON abac_attribute_definitions (organization_id, name)
    WHERE organization_id IS NOT NULL;

-- Category filtering
CREATE INDEX idx_abac_attrdef_category
    ON abac_attribute_definitions (category);

COMMENT ON TABLE abac_attribute_definitions IS
    'Schema registry for ABAC attributes. Defines valid attribute paths, '
    'types, and validation constraints for rule conditions.';


-- ─────────────────────────────────────────────────────────────────────────────
-- ABAC RULES (atomic evaluatable conditions)
-- ─────────────────────────────────────────────────────────────────────────────
-- Each rule represents a single logical check with an ALLOW or DENY effect.
-- The actual condition tree is stored in MongoDB (abac_rule_conditions
-- collection, linked by rule_id) because conditions can be arbitrarily deep
-- AND/OR/NOT trees that benefit from MongoDB's flexible document model.
--
-- A rule targets:
--   • resource_type   — what kind of resource (NULL = all resources)
--   • target_actions  — which actions on that resource ({} / NULL = all)
--   • effect          — allow or deny when conditions match
--
-- TEMPORAL RULES:
--   starts_at / expires_at enable time-bound rules:
--     • Temporary contractor access (90-day window)
--     • Scheduled rollback ("this rule is active during Q4 only")
--     • Maintenance-window elevation
--
-- RELATIONSHIPS:
--   abac_rules.organization_id → organizations.id           (N:1)
--   abac_rules.created_by      → users.id                   (N:1)
--   abac_rules.updated_by      → users.id                   (N:1)
--   abac_rules.id              ← abac_rule_group_members    (1:N)
--   abac_rules.id              → MongoDB abac_rule_conditions (1:1)
--
-- JOIN PATHS:
--   Rule → Condition: abac_rules.id → MongoDB abac_rule_conditions.rule_id
--   Rule → Groups:    abac_rules ← abac_rule_group_members → abac_rule_groups
--
-- NOTES:
--   • priority: higher = evaluated first within its group (default 0)
--   • is_active: soft-disable without deleting
--   • condition_hash: SHA-256 of the MongoDB condition doc (integrity check)
--   • A rule with NO conditions in MongoDB always matches (unconditional)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE abac_rules (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    description     TEXT,
    effect          VARCHAR(10)     NOT NULL DEFAULT 'allow'
                    CHECK (effect IN ('allow', 'deny')),
    priority        INT             NOT NULL DEFAULT 0,
    resource_type   VARCHAR(100),                    -- NULL = all resources
    target_actions  VARCHAR(50)[],                   -- NULL/empty = all actions
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    starts_at       TIMESTAMPTZ,                     -- NULL = immediately active
    expires_at      TIMESTAMPTZ,                     -- NULL = never expires
    condition_hash  VARCHAR(64),                     -- SHA-256 of MongoDB doc
    created_by      UUID            NOT NULL REFERENCES users(id),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (organization_id, name)
);

-- Active rules per org
CREATE INDEX idx_abac_rules_org_active
    ON abac_rules (organization_id)
    WHERE is_active = TRUE;

-- Rules by resource type (for targeted evaluation)
CREATE INDEX idx_abac_rules_resource
    ON abac_rules (organization_id, resource_type)
    WHERE is_active = TRUE;

-- Temporal rules (cleanup / expiry scanning)
CREATE INDEX idx_abac_rules_temporal
    ON abac_rules (expires_at)
    WHERE expires_at IS NOT NULL;

COMMENT ON TABLE abac_rules IS
    'Atomic ABAC rules.  Condition trees stored in MongoDB '
    'abac_rule_conditions collection, linked by rule_id.';


-- ─────────────────────────────────────────────────────────────────────────────
-- RULE GROUPS (composable rule bundles)
-- ─────────────────────────────────────────────────────────────────────────────
-- Named groups of rules combined with Boolean logic.  Rule groups can contain
-- other rule groups (nested composition), enabling arbitrary complexity.
--
-- COMBINE LOGIC (how member rules + groups are evaluated):
--   • 'and'  — ALL members must evaluate TRUE  (logical AND / intersection)
--   • 'or'   — ANY member must evaluate TRUE   (logical OR  / union)
--   • 'not'  — Result is NEGATED               (logical NOT / exclusion)
--
-- NESTING EXAMPLE:
--   Group "Complex Access" (AND):
--     ├── Rule: "is_engineer"
--     ├── Group: "Time Constraint" (OR):
--     │   ├── Rule: "business_hours"
--     │   └── Rule: "on_vpn"
--     └── Group: "Data Scope" (AND):
--         ├── Rule: "low_sensitivity"
--         └── Rule: "own_dept_data"
--
--   Evaluation:
--     is_engineer
--       AND (business_hours OR on_vpn)
--       AND (low_sensitivity AND own_dept_data)
--
-- RELATIONSHIPS:
--   abac_rule_groups.organization_id ──→ organizations.id           (N:1)
--   abac_rule_groups.created_by      ──→ users.id                   (N:1)
--   abac_rule_groups.id ←── abac_rule_group_members.group_id        (1:N)
--   abac_rule_groups.id ←── abac_rule_group_members.child_group_id  (N:N recurse)
--   abac_rule_groups.id ←── abac_policy_rule_groups.rule_group_id   (1:N)
--
-- NOTES:
--   • is_system = TRUE → platform-managed, tenants cannot delete
--   • Circular references prevented by trigger fn_abac_prevent_circular_groups
--   • Recommended nesting limit = 10 levels (enforced at application level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE abac_rule_groups (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    description     TEXT,
    combine_logic   VARCHAR(5)      NOT NULL DEFAULT 'and'
                    CHECK (combine_logic IN ('and', 'or', 'not')),
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,
    created_by      UUID            NOT NULL REFERENCES users(id),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (organization_id, name)
);

-- Listing groups per org
CREATE INDEX idx_abac_rule_groups_org
    ON abac_rule_groups (organization_id);

COMMENT ON TABLE abac_rule_groups IS
    'Named composable rule bundles with AND/OR/NOT logic.  Supports nested sub-groups.';


-- ─────────────────────────────────────────────────────────────────────────────
-- RULE GROUP MEMBERS (junction: rules & sub-groups inside a group)
-- ─────────────────────────────────────────────────────────────────────────────
-- Each row is EITHER:
--   a) An atomic rule  (rule_id IS SET,  child_group_id IS NULL)
--   b) A nested group  (child_group_id IS SET, rule_id IS NULL)
--
-- CONSTRAINTS:
--   • XOR: exactly one of (rule_id, child_group_id) is non-NULL
--   • No self-reference (group_id ≠ child_group_id)
--   • No duplicate (group_id, rule_id) or (group_id, child_group_id)
--   • Circular references prevented by trigger
--
-- RELATIONSHIPS:
--   abac_rule_group_members.group_id       ──→ abac_rule_groups.id (N:1)
--   abac_rule_group_members.rule_id        ──→ abac_rules.id       (N:1)
--   abac_rule_group_members.child_group_id ──→ abac_rule_groups.id (N:1)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE abac_rule_group_members (
    id              UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    group_id        UUID        NOT NULL REFERENCES abac_rule_groups(id) ON DELETE CASCADE,
    rule_id         UUID        REFERENCES abac_rules(id) ON DELETE CASCADE,
    child_group_id  UUID        REFERENCES abac_rule_groups(id) ON DELETE CASCADE,
    sort_order      INT         NOT NULL DEFAULT 0,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT now(),

    -- XOR: exactly one of (rule_id, child_group_id) must be set
    CONSTRAINT chk_rgm_xor CHECK (
        (rule_id IS NOT NULL AND child_group_id IS NULL) OR
        (rule_id IS NULL     AND child_group_id IS NOT NULL)
    ),
    -- No self-reference
    CONSTRAINT chk_rgm_no_self_ref CHECK (group_id != child_group_id)
);

-- No duplicate rule in same group
CREATE UNIQUE INDEX idx_rgm_unique_rule
    ON abac_rule_group_members (group_id, rule_id)
    WHERE rule_id IS NOT NULL;

-- No duplicate child group in same group
CREATE UNIQUE INDEX idx_rgm_unique_child
    ON abac_rule_group_members (group_id, child_group_id)
    WHERE child_group_id IS NOT NULL;

-- Evaluation ordering
CREATE INDEX idx_rgm_group_order
    ON abac_rule_group_members (group_id, sort_order);

-- Reverse lookup: "which groups contain this rule?"
CREATE INDEX idx_rgm_rule_lookup
    ON abac_rule_group_members (rule_id)
    WHERE rule_id IS NOT NULL;

-- Reverse lookup: "which groups contain this child group?"
CREATE INDEX idx_rgm_child_lookup
    ON abac_rule_group_members (child_group_id)
    WHERE child_group_id IS NOT NULL;

COMMENT ON TABLE abac_rule_group_members IS
    'Junction table linking atomic rules and nested sub-groups into a parent rule group.';


-- ─────────────────────────────────────────────────────────────────────────────
-- ABAC POLICIES (named policy containers — the unit of assignment)
-- ─────────────────────────────────────────────────────────────────────────────
-- A policy is the top-level object that gets assigned to users, roles, or
-- scopes.  Each policy contains one or more rule groups and has an overall
-- effect (allow / deny).
--
-- EVALUATION:
--   1. Evaluate all contained rule groups (via abac_policy_rule_groups)
--   2. If ALL rule groups match → apply the policy effect (allow / deny)
--   3. No match → skip this policy, try next by priority
--
-- CUSTOM ADMIN EXAMPLE:
--   Policy "Billing Admin" (effect=allow):
--     Rule Group "Billing Full Access" (AND):
--       ├── Rule: resource_type IN ('invoice','plan','subscription')
--       └── Rule: action IN ('read','create','update','delete')
--     Assigned to: role=billing_admin, org=acme-corp
--
--   Policy "Security Admin" (effect=allow):
--     Rule Group "Security Full Access" (AND):
--       ├── Rule: resource_type IN ('user','role','permission','policy')
--       └── Rule: action IN ('read','create','update','delete')
--     Assigned to: role=security_admin, org=acme-corp
--
--   Result: billing_admin CANNOT manage users.
--           security_admin CANNOT manage billing.
--           Both are "admins" with completely disjoint capabilities.
--
-- RELATIONSHIPS:
--   abac_policies.organization_id ──→ organizations.id                (N:1)
--   abac_policies.created_by      ──→ users.id                       (N:1)
--   abac_policies.id ←── abac_policy_rule_groups.policy_id            (1:N)
--   abac_policies.id ←── abac_policy_assignments.policy_id            (1:N)
--
-- NOTES:
--   • priority: higher = evaluated first (among policies for same subject)
--   • At equal priority, deny-effect policies win over allow-effect ones
--   • is_system: platform-managed, tenants cannot delete
--   • version: incremented on update — enables optimistic concurrency
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE abac_policies (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    description     TEXT,
    effect          VARCHAR(10)     NOT NULL DEFAULT 'allow'
                    CHECK (effect IN ('allow', 'deny')),
    priority        INT             NOT NULL DEFAULT 0,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,
    version         INT             NOT NULL DEFAULT 1,
    created_by      UUID            NOT NULL REFERENCES users(id),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (organization_id, name)
);

-- Active policies per org (sorted by priority for evaluation)
CREATE INDEX idx_abac_policies_org_active
    ON abac_policies (organization_id, priority DESC)
    WHERE is_active = TRUE;

COMMENT ON TABLE abac_policies IS
    'Named access policies containing rule groups.  '
    'Top-level assignment unit for the ABAC engine.';


-- ─────────────────────────────────────────────────────────────────────────────
-- POLICY RULE GROUPS (junction: policies → rule groups)
-- ─────────────────────────────────────────────────────────────────────────────
-- Links rule groups into a policy.  When the policy is evaluated, all linked
-- rule groups must match for the policy's effect to apply (implicit AND
-- across groups within a single policy).
--
-- RELATIONSHIPS:
--   abac_policy_rule_groups.policy_id     ──→ abac_policies.id     (N:1)
--   abac_policy_rule_groups.rule_group_id ──→ abac_rule_groups.id  (N:1)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE abac_policy_rule_groups (
    policy_id       UUID    NOT NULL REFERENCES abac_policies(id) ON DELETE CASCADE,
    rule_group_id   UUID    NOT NULL REFERENCES abac_rule_groups(id) ON DELETE CASCADE,
    sort_order      INT     NOT NULL DEFAULT 0,

    PRIMARY KEY (policy_id, rule_group_id)
);

COMMENT ON TABLE abac_policy_rule_groups IS
    'Junction linking rule groups into policies.  '
    'All groups in a policy must match for the policy effect to apply.';


-- ─────────────────────────────────────────────────────────────────────────────
-- POLICY ASSIGNMENTS (who / where a policy applies + temporal bounds)
-- ─────────────────────────────────────────────────────────────────────────────
-- Assigns a policy to a target entity.  Supports temporal assignments via
-- starts_at / expires_at for temporary or scheduled access.
--
-- TARGET TYPES:
--   • 'user'         — Policy applies to one specific user
--   • 'role'         — Policy applies to everyone holding that role
--   • 'organization' — Policy applies to ALL members of the org
--   • 'project'      — Policy scoped to a project
--   • 'workspace'    — Policy scoped to a workspace
--   • 'team'         — Policy applies to a team (org sub-group)
--
-- TEMPORAL ASSIGNMENTS (Linux-inspired temporary access):
--
--   Contractor access:
--     starts_at: 2024-03-01,  expires_at: 2024-05-31
--     → Access automatically stops after contract period
--
--   Maintenance window:
--     starts_at: 2024-03-15T02:00Z,  expires_at: 2024-03-15T06:00Z
--     → Elevated access for a single 4-hour window
--
--   Scheduled feature rollout:
--     starts_at: 2024-06-01,  expires_at: NULL
--     → Turns on at a future date, never expires
--
-- INHERITANCE:
--   Policies cascade down the scope hierarchy:
--     organization → project → workspace
--   A policy assigned to an org applies to all projects/workspaces in that
--   org unless overridden by a higher-priority policy at a narrower scope.
--
-- RELATIONSHIPS:
--   abac_policy_assignments.policy_id   ──→ abac_policies.id  (N:1)
--   abac_policy_assignments.assigned_by ──→ users.id          (N:1)
--   target_id is polymorphic: users.id, roles.id, organizations.id, etc.
--
-- NOTES:
--   • (policy_id, target_type, target_id) is UNIQUE — no duplicate assign
--   • expires_at enables automatic revocation without manual intervention
--   • assigned_by is the admin who created the assignment (audit trail)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE abac_policy_assignments (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    policy_id       UUID            NOT NULL REFERENCES abac_policies(id) ON DELETE CASCADE,
    target_type     VARCHAR(20)     NOT NULL
                    CHECK (target_type IN (
                        'user', 'role', 'organization', 'project', 'workspace', 'team'
                    )),
    target_id       UUID            NOT NULL,        -- polymorphic FK
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    starts_at       TIMESTAMPTZ,                     -- NULL = immediately active
    expires_at      TIMESTAMPTZ,                     -- NULL = never expires
    assigned_by     UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (policy_id, target_type, target_id)
);

-- "What policies apply to this target?" (primary evaluation query)
CREATE INDEX idx_abac_pa_target
    ON abac_policy_assignments (target_type, target_id)
    WHERE is_active = TRUE;

-- "Who is assigned to this policy?" (admin listing)
CREATE INDEX idx_abac_pa_policy
    ON abac_policy_assignments (policy_id)
    WHERE is_active = TRUE;

-- Expiry scanner (for cleanup / revocation jobs)
CREATE INDEX idx_abac_pa_temporal
    ON abac_policy_assignments (expires_at)
    WHERE expires_at IS NOT NULL;

COMMENT ON TABLE abac_policy_assignments IS
    'Assigns policies to users, roles, or scopes with optional temporal '
    'bounds for automatic access revocation.';
