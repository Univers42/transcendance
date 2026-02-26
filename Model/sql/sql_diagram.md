# PostgreSQL Schema — Complete SQL Architecture

> 55 tables across 9 schema files.
> Strict **5NF** normalization. UUID primary keys via `gen_random_uuid()`.
> Multi-tenant isolation via `organization_id` on every business table.
> RBAC + ABAC layered permission model.

---

## Table of Contents

1. [CMR — Class Model Relationship (Entity-Relationship)](#1--cmr--class-model-relationship)
2. [UMM — UML Model Map (Domain Map)](#2--umm--uml-model-map)
3. [UML — Class Diagrams per Domain](#3--uml--class-diagrams-per-domain)
4. [Use Case Diagrams](#4--use-case-diagrams)
5. [Sequence Diagrams](#5--sequence-diagrams)
6. [Flowcharts](#6--flowcharts)

---

## 1 — CMR — Class Model Relationship

### 1.1 — Master ER Diagram (All Domains)

```mermaid
---
title: Full Entity-Relationship Diagram — 55 Tables
---
erDiagram
    %% ═══════════════════════════════════════════
    %% IDENTITY & AUTH (schema.user.sql)
    %% ═══════════════════════════════════════════

    users {
        UUID id PK
        VARCHAR email UK
        VARCHAR username UK
        VARCHAR display_name
        TEXT password_hash
        BOOLEAN is_active
        BOOLEAN mfa_enabled
        VARCHAR status
    }

    oauth_accounts {
        UUID id PK
        UUID user_id FK
        VARCHAR provider
        VARCHAR provider_id
        TEXT access_token
    }

    roles {
        UUID id PK
        UUID organization_id FK
        VARCHAR name
        VARCHAR scope
        BOOLEAN is_system
    }

    permissions {
        UUID id PK
        VARCHAR name UK
        VARCHAR resource_type
        VARCHAR action
    }

    role_permissions {
        UUID role_id PK_FK
        UUID permission_id PK_FK
    }

    user_role_assignments {
        UUID id PK
        UUID user_id FK
        UUID role_id FK
        VARCHAR context_type
        UUID context_id
        TIMESTAMPTZ expires_at
    }

    abac_conditions {
        UUID id PK
        UUID permission_id FK
        UUID role_id FK
        VARCHAR attribute_key
        VARCHAR operator
        JSONB attribute_value
    }

    user_permissions {
        UUID id PK
        UUID user_id FK
        UUID permission_id FK
        BOOLEAN granted
        TIMESTAMPTZ expires_at
    }

    user_sessions {
        UUID id PK
        UUID user_id FK
        VARCHAR token_hash
        INET ip_address
        BOOLEAN is_active
    }

    contacts {
        UUID id PK
        UUID user_id FK
        UUID contact_user_id FK
        VARCHAR first_name
        VARCHAR last_name
    }

    api_keys {
        UUID id PK
        UUID user_id FK
        VARCHAR name
        VARCHAR key_hash UK
        BOOLEAN is_active
    }

    %% ═══════════════════════════════════════════
    %% ORGANIZATION HIERARCHY (schema.organization.sql)
    %% ═══════════════════════════════════════════

    organizations {
        UUID id PK
        VARCHAR name
        VARCHAR slug UK
        UUID created_by FK
        BOOLEAN is_active
    }

    organization_members {
        UUID id PK
        UUID organization_id FK
        UUID user_id FK
        UUID invited_by FK
    }

    projects {
        UUID id PK
        UUID organization_id FK
        VARCHAR name
        VARCHAR slug
        UUID created_by FK
    }

    project_members {
        UUID id PK
        UUID project_id FK
        UUID user_id FK
        UUID invited_by FK
    }

    workspaces {
        UUID id PK
        UUID project_id FK
        VARCHAR name
        VARCHAR slug
        VARCHAR type
        UUID created_by FK
    }

    workspace_members {
        UUID id PK
        UUID workspace_id FK
        UUID user_id FK
        UUID invited_by FK
    }

    %% ═══════════════════════════════════════════
    %% COLLECTIONS (schema.collection.sql)
    %% ═══════════════════════════════════════════

    collections {
        UUID id PK
        UUID workspace_id FK
        VARCHAR name
        VARCHAR slug
        VARCHAR field_type
        INT record_count
        UUID created_by FK
    }

    fields {
        UUID id PK
        UUID collection_id FK
        VARCHAR name
        VARCHAR slug
        VARCHAR field_type
        BOOLEAN is_required
        JSONB validation_rules
    }

    field_options {
        UUID id PK
        UUID field_id FK
        VARCHAR label
        VARCHAR value
    }

    collection_relations {
        UUID id PK
        UUID source_collection_id FK
        UUID target_collection_id FK
        UUID source_field_id FK
        VARCHAR relation_type
    }

    collection_indices {
        UUID id PK
        UUID collection_id FK
        VARCHAR name
        TEXT_ARRAY field_slugs
    }

    %% ═══════════════════════════════════════════
    %% DASHBOARDS & VIEWS (schema.dashboard.sql)
    %% ═══════════════════════════════════════════

    dashboards {
        UUID id PK
        UUID workspace_id FK
        VARCHAR name
        VARCHAR slug
        VARCHAR visibility
        UUID created_by FK
    }

    dashboard_permissions {
        UUID id PK
        UUID dashboard_id FK
        VARCHAR grantee_type
        UUID grantee_id
        BOOLEAN can_view
        BOOLEAN can_edit
    }

    views {
        UUID id PK
        UUID collection_id FK
        UUID workspace_id FK
        VARCHAR name
        VARCHAR view_type
        VARCHAR visibility
        UUID created_by FK
    }

    view_permissions {
        UUID id PK
        UUID view_id FK
        VARCHAR grantee_type
        UUID grantee_id
    }

    dashboard_templates {
        UUID id PK
        UUID organization_id FK
        VARCHAR name
        VARCHAR category
        JSONB template_data
    }

    %% ═══════════════════════════════════════════
    %% RESOURCES (schema.resource.sql)
    %% ═══════════════════════════════════════════

    resources {
        UUID id PK
        UUID organization_id FK
        VARCHAR resource_type
        UUID resource_id
        VARCHAR name
    }

    resource_permissions {
        UUID id PK
        UUID resource_id FK
        VARCHAR grantee_type
        UUID grantee_id
        VARCHAR_ARRAY actions
    }

    resource_versions {
        UUID id PK
        UUID resource_id FK
        INT version_number
        JSONB snapshot
    }

    resource_shares {
        UUID id PK
        UUID resource_id FK
        VARCHAR share_type
        VARCHAR share_token UK
        BOOLEAN is_active
    }

    resource_relations {
        UUID id PK
        UUID source_resource_id FK
        UUID target_resource_id FK
        VARCHAR relation_type
    }

    tags {
        UUID id PK
        UUID organization_id FK
        VARCHAR name
        VARCHAR slug
    }

    resource_tags {
        UUID resource_id PK_FK
        UUID tag_id PK_FK
    }

    comments {
        UUID id PK
        UUID resource_id FK
        UUID user_id FK
        UUID parent_id FK
        TEXT content
        BOOLEAN is_resolved
    }

    %% ═══════════════════════════════════════════
    %% ADAPTERS (schema.adapter.sql)
    %% ═══════════════════════════════════════════

    adapters {
        UUID id PK
        UUID organization_id FK
        VARCHAR name
        VARCHAR adapter_type
        JSONB connection_config
        VARCHAR health_status
    }

    adapter_mappings {
        UUID id PK
        UUID adapter_id FK
        UUID collection_id FK
        VARCHAR source_path
        JSONB field_mappings
        VARCHAR sync_direction
    }

    adapter_executions {
        UUID id PK
        UUID adapter_id FK
        UUID mapping_id FK
        VARCHAR status
        INT records_processed
    }

    %% ═══════════════════════════════════════════
    %% SYSTEM (schema.system.sql)
    %% ═══════════════════════════════════════════

    webhooks {
        UUID id PK
        UUID organization_id FK
        VARCHAR name
        TEXT url
        VARCHAR_ARRAY events
        BOOLEAN is_active
    }

    webhook_deliveries {
        UUID id PK
        UUID webhook_id FK
        VARCHAR event_type
        INT response_status
    }

    notifications {
        UUID id PK
        UUID user_id FK
        VARCHAR type
        VARCHAR title
        BOOLEAN is_read
    }

    policy_rules {
        UUID id PK
        UUID organization_id FK
        VARCHAR name
        VARCHAR resource_type
        JSONB conditions
        VARCHAR effect
    }

    file_uploads {
        UUID id PK
        UUID organization_id FK
        VARCHAR filename
        BIGINT size_bytes
        VARCHAR storage_backend
    }

    %% ═══════════════════════════════════════════
    %% BILLING (schema.billing.sql)
    %% ═══════════════════════════════════════════

    plans {
        UUID id PK
        VARCHAR slug UK
        VARCHAR name
        INT price_monthly
        INT price_yearly
    }

    plan_features {
        UUID id PK
        UUID plan_id FK
        VARCHAR feature_key
        INT limit_value
    }

    promotions {
        UUID id PK
        VARCHAR code UK
        VARCHAR name
        VARCHAR discount_type
        INT discount_value
    }

    subscriptions {
        UUID id PK
        UUID organization_id FK
        UUID plan_id FK
        UUID promotion_id FK
        VARCHAR status
        VARCHAR billing_period
    }

    promotion_plans {
        UUID promotion_id PK_FK
        UUID plan_id PK_FK
    }

    invoices {
        UUID id PK
        UUID subscription_id FK
        UUID organization_id FK
        VARCHAR invoice_number
        VARCHAR status
        INT total_amount
    }

    payments {
        UUID id PK
        UUID invoice_id FK
        UUID organization_id FK
        INT amount
        VARCHAR status
        VARCHAR payment_method
    }

    usage_meters {
        UUID id PK
        VARCHAR slug UK
        VARCHAR name
        VARCHAR unit
        VARCHAR aggregation
    }

    usage_records {
        UUID id PK
        UUID organization_id FK
        UUID meter_id FK
        BIGINT quantity
    }

    %% ═══════════════════════════════════════════
    %% CONNECTIVITY (schema.connectivity.sql)
    %% ═══════════════════════════════════════════

    provisioned_databases {
        UUID id PK
        UUID organization_id FK
        VARCHAR name
        VARCHAR provider
        VARCHAR engine
        VARCHAR tier
        VARCHAR status
    }

    database_connections {
        UUID id PK
        UUID organization_id FK
        UUID project_id FK
        VARCHAR name
        VARCHAR connection_type
        VARCHAR engine
        UUID credential_ref
        UUID provisioned_db_id FK
    }

    sync_channels {
        UUID id PK
        UUID connection_id FK
        UUID collection_id FK
        VARCHAR source_path
        VARCHAR sync_mode
        VARCHAR sync_direction
        VARCHAR status
    }

    sync_executions {
        UUID id PK
        UUID channel_id FK
        VARCHAR status
        VARCHAR direction
        INT records_processed
    }

    %% ═══════════════════════════════════════════
    %% RELATIONSHIPS
    %% ═══════════════════════════════════════════

    users ||--o{ oauth_accounts : "has"
    users ||--o{ user_role_assignments : "assigned"
    users ||--o{ user_permissions : "granted"
    users ||--o{ user_sessions : "logs in"
    users ||--o{ contacts : "owns"
    users ||--o{ api_keys : "generates"
    users ||--o{ notifications : "receives"

    roles ||--o{ role_permissions : "includes"
    permissions ||--o{ role_permissions : "granted via"
    roles ||--o{ user_role_assignments : "assigned to"
    roles ||--o{ abac_conditions : "scoped by"
    permissions ||--o{ abac_conditions : "constrained by"
    permissions ||--o{ user_permissions : "overridden"

    organizations ||--o{ roles : "defines"
    organizations ||--o{ organization_members : "has"
    organizations ||--o{ projects : "contains"
    organizations ||--o{ resources : "owns"
    organizations ||--o{ adapters : "configures"
    organizations ||--o{ webhooks : "registers"
    organizations ||--o{ policy_rules : "enforces"
    organizations ||--o{ file_uploads : "stores"
    organizations ||--o{ tags : "creates"
    organizations ||--o{ subscriptions : "subscribes"
    organizations ||--o{ invoices : "billed"
    organizations ||--o{ payments : "pays"
    organizations ||--o{ usage_records : "metered"
    organizations ||--o{ database_connections : "connects"
    organizations ||--o{ provisioned_databases : "provisions"
    organizations ||--o{ dashboard_templates : "offers"

    organization_members }o--|| users : "is"
    project_members }o--|| users : "is"
    workspace_members }o--|| users : "is"

    projects ||--o{ project_members : "has"
    projects ||--o{ workspaces : "contains"

    workspaces ||--o{ workspace_members : "has"
    workspaces ||--o{ collections : "contains"
    workspaces ||--o{ dashboards : "displays"
    workspaces ||--o{ views : "shows"

    collections ||--o{ fields : "defines"
    collections ||--o{ collection_indices : "indexed by"
    collections ||--o{ views : "viewed as"
    fields ||--o{ field_options : "has"
    collections ||--o{ collection_relations : "source"
    collections ||--o{ collection_relations : "target"

    dashboards ||--o{ dashboard_permissions : "grants"
    views ||--o{ view_permissions : "grants"

    resources ||--o{ resource_permissions : "grants"
    resources ||--o{ resource_versions : "versioned"
    resources ||--o{ resource_shares : "shared via"
    resources ||--o{ resource_relations : "relates"
    resources ||--o{ resource_tags : "tagged"
    resources ||--o{ comments : "commented"
    tags ||--o{ resource_tags : "applied"
    comments ||--o{ comments : "replies"

    adapters ||--o{ adapter_mappings : "maps"
    adapters ||--o{ adapter_executions : "runs"
    adapter_mappings }o--|| collections : "targets"

    webhooks ||--o{ webhook_deliveries : "delivers"

    plans ||--o{ plan_features : "includes"
    plans ||--o{ subscriptions : "subscribed"
    plans ||--o{ promotion_plans : "eligible"
    promotions ||--o{ promotion_plans : "applies to"
    promotions ||--o{ subscriptions : "discounts"
    subscriptions ||--o{ invoices : "generates"
    invoices ||--o{ payments : "paid by"
    usage_meters ||--o{ usage_records : "tracks"

    provisioned_databases ||--o| database_connections : "linked"
    database_connections ||--o{ sync_channels : "syncs via"
    sync_channels }o--|| collections : "syncs to"
    sync_channels ||--o{ sync_executions : "logs"
```

### 1.2 — Identity & Access Control ERD (Focused)

```mermaid
---
title: RBAC + ABAC Permission Model — Detailed
---
erDiagram
    users ||--o{ user_role_assignments : "holds roles"
    users ||--o{ user_permissions : "has overrides"
    users ||--o{ oauth_accounts : "authenticates via"
    users ||--o{ user_sessions : "sessions"
    users ||--o{ api_keys : "api access"

    roles ||--o{ user_role_assignments : "assigned to users"
    roles ||--o{ role_permissions : "grants"
    roles ||--o{ abac_conditions : "scoped conditions"

    permissions ||--o{ role_permissions : "included in roles"
    permissions ||--o{ user_permissions : "directly granted"
    permissions ||--o{ abac_conditions : "constrained by"

    organizations ||--o{ roles : "defines custom"
    organizations ||--o{ policy_rules : "org-wide ABAC"

    user_role_assignments {
        UUID user_id FK
        UUID role_id FK
        VARCHAR context_type "global|org|project|workspace"
        UUID context_id "polymorphic FK"
        TIMESTAMPTZ expires_at "temporal access"
    }

    abac_conditions {
        UUID permission_id FK
        UUID role_id FK "NULL = all roles"
        VARCHAR attribute_key "user.dept|resource.x"
        VARCHAR operator "eq|neq|in|gt|..."
        JSONB attribute_value
        VARCHAR logic_group "AND|OR"
    }

    user_permissions {
        UUID user_id FK
        UUID permission_id FK
        BOOLEAN granted "FALSE = explicit DENY"
        TIMESTAMPTZ expires_at
    }

    policy_rules {
        UUID organization_id FK
        VARCHAR resource_type
        JSONB conditions "expression tree"
        VARCHAR effect "allow|deny"
        INT priority "higher = first"
    }
```

### 1.3 — Billing & Monetization ERD (Focused)

```mermaid
---
title: Billing Domain — Plans, Subscriptions, Invoicing
---
erDiagram
    plans ||--o{ plan_features : "feature limits"
    plans ||--o{ subscriptions : "subscribers"
    plans ||--o{ promotion_plans : "promo eligible"

    promotions ||--o{ promotion_plans : "applicable plans"
    promotions ||--o{ subscriptions : "applied to"

    organizations ||--o{ subscriptions : "subscribes"
    organizations ||--o{ invoices : "billed"
    organizations ||--o{ usage_records : "metered"

    subscriptions ||--o{ invoices : "generates"
    invoices ||--o{ payments : "paid via"
    usage_meters ||--o{ usage_records : "tracks"

    plans {
        VARCHAR slug UK "free|starter|pro|enterprise"
        INT price_monthly "cents"
        INT price_yearly "cents"
        INT trial_days
    }

    plan_features {
        VARCHAR feature_key "max_members|storage_mb|..."
        INT limit_value "NULL = unlimited"
    }

    subscriptions {
        VARCHAR status "trialing|active|past_due|..."
        VARCHAR billing_period "monthly|yearly"
        TIMESTAMPTZ current_period_end
    }

    invoices {
        VARCHAR invoice_number UK "INV-2025-0001"
        INT subtotal_amount "cents"
        INT discount_amount "cents"
        INT total_amount "cents"
        VARCHAR status "draft|pending|paid|void"
    }

    payments {
        INT amount "cents"
        VARCHAR payment_method "card|bank|paypal"
        VARCHAR gateway "stripe|paddle|manual"
        VARCHAR status "pending|succeeded|failed"
    }

    promotions {
        VARCHAR code UK "LAUNCH2025"
        VARCHAR discount_type "percentage|fixed|trial_ext"
        INT discount_value
        INT duration_months "NULL = forever"
    }
```

### 1.4 — Connectivity & Sync ERD (Focused)

```mermaid
---
title: Database Connectivity & CDC Sync
---
erDiagram
    organizations ||--o{ provisioned_databases : "requests managed"
    organizations ||--o{ database_connections : "connects to"

    provisioned_databases ||--o| database_connections : "auto-linked"
    database_connections ||--o{ sync_channels : "has channels"
    sync_channels }o--|| collections : "syncs into"
    sync_channels ||--o{ sync_executions : "execution log"

    provisioned_databases {
        VARCHAR provider "supabase|mongodb_atlas|..."
        VARCHAR engine "postgresql|mongodb|mysql"
        VARCHAR tier "free|starter|pro|enterprise"
        VARCHAR status "provisioning|active|terminated"
        JSONB resource_limits "cpu|memory|storage"
    }

    database_connections {
        VARCHAR connection_type "user_public|ssh|vpn|managed"
        VARCHAR engine "postgresql|mysql|mongodb|..."
        UUID credential_ref "→ MongoDB vault"
        JSONB connection_config "host|port|db|ssl"
        JSONB network_config "bastion|vpn|private_link"
        VARCHAR health_status
    }

    sync_channels {
        VARCHAR source_path "public.orders"
        VARCHAR sync_mode "cdc_realtime|polling|webhook"
        VARCHAR sync_direction "inbound|outbound|bidirectional"
        VARCHAR conflict_strategy "newest_wins|manual|merge"
        VARCHAR status "active|paused|error"
    }

    sync_executions {
        VARCHAR trigger_type "cdc|poll|webhook|manual"
        INT records_in "remote → platform"
        INT records_out "platform → remote"
        INT records_conflicted
        INT latency_ms
    }
```

---

## 2 — UMM — UML Model Map

### 2.1 — Domain Dependency Map

```mermaid
---
title: Domain Dependencies — Execution Order
---
graph LR
    classDef core fill:#2563eb,stroke:#1d4ed8,color:#fff
    classDef mid fill:#7c3aed,stroke:#6d28d9,color:#fff
    classDef high fill:#059669,stroke:#047857,color:#fff
    classDef top fill:#d97706,stroke:#b45309,color:#fff

    USER["🔑 schema.user.sql\n───────────────\nusers, oauth, roles,\npermissions, RBAC,\nABAC, sessions,\ncontacts, api_keys\n(11 tables)"]:::core

    ORG["🏢 schema.organization.sql\n─────────────────────\norganizations, projects,\nworkspaces + members\n(6 tables)"]:::core

    COLL["📊 schema.collection.sql\n─────────────────────\ncollections, fields,\noptions, relations,\nindices\n(5 tables)"]:::mid

    DASH["📈 schema.dashboard.sql\n─────────────────────\ndashboards, views,\npermissions, templates\n(5 tables)"]:::mid

    RES["📦 schema.resource.sql\n────────────────────\nresources, permissions,\nversions, shares,\ntags, comments\n(8 tables)"]:::high

    ADAPT["🔌 schema.adapter.sql\n───────────────────\nadapters, mappings,\nexecutions\n(3 tables)"]:::high

    SYS["⚙️ schema.system.sql\n──────────────────\nwebhooks, notifications,\npolicies, file_uploads\n(5 tables)"]:::top

    BILL["💳 schema.billing.sql\n──────────────────\nplans, subscriptions,\ninvoices, payments,\nusage, promotions\n(9 tables)"]:::top

    CONN["🔄 schema.connectivity.sql\n────────────────────────\nprovisioned_dbs, connections,\nsync_channels, executions\n(4 tables)"]:::top

    USER --> ORG
    ORG --> COLL
    COLL --> DASH
    DASH --> RES
    COLL --> ADAPT
    RES --> SYS
    USER --> BILL
    ORG --> BILL
    ORG --> CONN
    COLL --> CONN
```

### 2.2 — Multi-Tenant Hierarchy

```mermaid
---
title: Organizational Hierarchy — Containment Model
---
graph TB
    classDef tenant fill:#ef4444,stroke:#dc2626,color:#fff
    classDef level1 fill:#f97316,stroke:#ea580c,color:#fff
    classDef level2 fill:#eab308,stroke:#ca8a04,color:#000
    classDef level3 fill:#22c55e,stroke:#16a34a,color:#fff
    classDef leaf fill:#3b82f6,stroke:#2563eb,color:#fff

    ORG["🏢 Organization\n(tenant boundary)"]:::tenant

    ORG --> P1["📁 Project A"]:::level1
    ORG --> P2["📁 Project B"]:::level1

    P1 --> W1["📂 Workspace 1"]:::level2
    P1 --> W2["📂 Workspace 2"]:::level2
    P2 --> W3["📂 Workspace 3"]:::level2

    W1 --> C1["📊 Collections"]:::level3
    W1 --> D1["📈 Dashboards"]:::level3
    W1 --> V1["👁️ Views"]:::level3

    C1 --> F1["🏷️ Fields"]:::leaf
    C1 --> R1["🔗 Relations"]:::leaf
    C1 --> I1["📇 Indices"]:::leaf

    D1 --> DP["🔒 Dashboard Perms"]:::leaf
    V1 --> VP["🔒 View Perms"]:::leaf

    ORG --> ROLES["🎭 Roles"]:::leaf
    ORG --> ADAPT["🔌 Adapters"]:::leaf
    ORG --> TAGS["🏷️ Tags"]:::leaf
    ORG --> HOOKS["🪝 Webhooks"]:::leaf
    ORG --> POLICY["📜 Policies"]:::leaf
    ORG --> SUB["💳 Subscription"]:::leaf
    ORG --> DBCONN["🔄 DB Connections"]:::leaf
```

### 2.3 — Schema File Table Count

```mermaid
---
title: Tables per Schema File
---
pie title 55 Tables Across 9 Schema Files
    "schema.user.sql (11)" : 11
    "schema.organization.sql (6)" : 6
    "schema.collection.sql (5)" : 5
    "schema.dashboard.sql (5)" : 5
    "schema.resource.sql (8)" : 8
    "schema.adapter.sql (3)" : 3
    "schema.system.sql (5)" : 5
    "schema.billing.sql (9)" : 9
    "schema.connectivity.sql (4)" : 4
```

---

## 3 — UML — Class Diagrams per Domain

### 3.1 — Identity & Auth

```mermaid
---
title: schema.user.sql — Identity, Auth & RBAC/ABAC
---
classDiagram
    class users {
        +UUID id
        +VARCHAR email
        +VARCHAR username
        +VARCHAR display_name
        +TEXT password_hash
        +BOOLEAN is_active
        +BOOLEAN mfa_enabled
        +TEXT mfa_secret
        +VARCHAR status
        +TIMESTAMPTZ last_login_at
        +TIMESTAMPTZ last_seen_at
    }

    class oauth_accounts {
        +UUID id
        +UUID user_id
        +VARCHAR provider
        +VARCHAR provider_id
        +TEXT access_token
        +TEXT refresh_token
        +TIMESTAMPTZ token_expires_at
    }

    class roles {
        +UUID id
        +UUID organization_id
        +VARCHAR name
        +TEXT description
        +VARCHAR scope
        +BOOLEAN is_system
    }

    class permissions {
        +UUID id
        +VARCHAR name
        +TEXT description
        +VARCHAR resource_type
        +VARCHAR action
    }

    class role_permissions {
        +UUID role_id
        +UUID permission_id
    }

    class user_role_assignments {
        +UUID id
        +UUID user_id
        +UUID role_id
        +VARCHAR context_type
        +UUID context_id
        +UUID assigned_by
        +TIMESTAMPTZ expires_at
    }

    class abac_conditions {
        +UUID id
        +UUID permission_id
        +UUID role_id
        +VARCHAR attribute_key
        +VARCHAR operator
        +JSONB attribute_value
        +VARCHAR logic_group
    }

    class user_permissions {
        +UUID id
        +UUID user_id
        +UUID permission_id
        +BOOLEAN granted
        +UUID granted_by
        +TIMESTAMPTZ expires_at
    }

    class user_sessions {
        +UUID id
        +UUID user_id
        +VARCHAR token_hash
        +INET ip_address
        +TEXT user_agent
        +BOOLEAN is_active
        +TIMESTAMPTZ expires_at
    }

    class contacts {
        +UUID id
        +UUID user_id
        +UUID contact_user_id
        +VARCHAR first_name
        +VARCHAR last_name
        +VARCHAR email
        +VARCHAR phone
        +JSONB metadata
    }

    class api_keys {
        +UUID id
        +UUID user_id
        +VARCHAR name
        +VARCHAR key_hash
        +VARCHAR[] scopes
        +BOOLEAN is_active
        +TIMESTAMPTZ expires_at
    }

    users "1" --> "*" oauth_accounts
    users "1" --> "*" user_role_assignments
    users "1" --> "*" user_permissions
    users "1" --> "*" user_sessions
    users "1" --> "*" contacts
    users "1" --> "*" api_keys
    roles "1" --> "*" role_permissions
    permissions "1" --> "*" role_permissions
    roles "1" --> "*" user_role_assignments
    permissions "1" --> "*" abac_conditions
    roles "0..1" --> "*" abac_conditions : "optional scope"
    permissions "1" --> "*" user_permissions

    note for roles "scope: global | organization |\nproject | workspace\n\nis_system = TRUE → immutable"
    note for user_role_assignments "context_type + context_id =\npolymorphic scope target\n\nexpires_at = temporal access"
    note for abac_conditions "role_id NULL → applies to ALL roles\nrole_id SET → only that role"
```

### 3.2 — Organization Hierarchy

```mermaid
---
title: schema.organization.sql — Multi-Tenant Hierarchy
---
classDiagram
    class organizations {
        +UUID id
        +VARCHAR name
        +VARCHAR slug
        +TEXT logo_url
        +BOOLEAN is_active
        +JSONB metadata
        +UUID created_by
    }

    class organization_members {
        +UUID id
        +UUID organization_id
        +UUID user_id
        +UUID invited_by
        +TIMESTAMPTZ joined_at
    }

    class projects {
        +UUID id
        +UUID organization_id
        +VARCHAR name
        +VARCHAR slug
        +TEXT description
        +VARCHAR icon
        +VARCHAR color
        +BOOLEAN is_archived
        +UUID created_by
    }

    class project_members {
        +UUID id
        +UUID project_id
        +UUID user_id
        +UUID invited_by
        +TIMESTAMPTZ joined_at
    }

    class workspaces {
        +UUID id
        +UUID project_id
        +VARCHAR name
        +VARCHAR slug
        +TEXT description
        +VARCHAR type
        +BOOLEAN is_default
        +INT sort_order
        +UUID created_by
    }

    class workspace_members {
        +UUID id
        +UUID workspace_id
        +UUID user_id
        +UUID invited_by
        +TIMESTAMPTZ joined_at
    }

    organizations "1" --> "*" projects : contains
    organizations "1" --> "*" organization_members : has
    projects "1" --> "*" workspaces : contains
    projects "1" --> "*" project_members : has
    workspaces "1" --> "*" workspace_members : has

    note for organizations "Top-level tenant boundary\nAll resources scoped here\nslug used in URL routing"
    note for workspaces "type: default | data |\nanalytics | admin | sandbox"
```

### 3.3 — Collection Schema Engine

```mermaid
---
title: schema.collection.sql — Dynamic Schema Engine
---
classDiagram
    class collections {
        +UUID id
        +UUID workspace_id
        +VARCHAR name
        +VARCHAR slug
        +TEXT description
        +BOOLEAN is_system
        +INT record_count
    }

    class fields {
        +UUID id
        +UUID collection_id
        +VARCHAR name
        +VARCHAR slug
        +VARCHAR field_type
        +BOOLEAN is_required
        +BOOLEAN is_unique
        +BOOLEAN is_primary
        +BOOLEAN is_system
        +JSONB default_value
        +JSONB validation_rules
        +JSONB display_config
        +INT sort_order
    }

    class field_options {
        +UUID id
        +UUID field_id
        +VARCHAR label
        +VARCHAR value
        +VARCHAR color
        +INT sort_order
    }

    class collection_relations {
        +UUID id
        +UUID source_collection_id
        +UUID target_collection_id
        +UUID source_field_id
        +UUID target_field_id
        +VARCHAR relation_type
        +UUID junction_collection_id
        +VARCHAR on_delete_action
    }

    class collection_indices {
        +UUID id
        +UUID collection_id
        +VARCHAR name
        +TEXT[] field_slugs
        +BOOLEAN is_unique
        +BOOLEAN is_sparse
    }

    collections "1" --> "*" fields : defines
    fields "1" --> "*" field_options : "for select/multi_select"
    collections "1" --> "*" collection_relations : "source"
    collections "1" --> "*" collection_relations : "target"
    collections "1" --> "*" collection_indices : indexed by
    fields "1" --> "*" collection_relations : "field ref"

    note for fields "28 field types:\ntext, number, date, select,\nrelation, lookup, rollup,\nformula, file, currency, ..."
    note for collection_relations "relation_type:\none_to_one | one_to_many |\nmany_to_many\n\nEnforced at app level in MongoDB"
```

### 3.4 — Presentation Layer

```mermaid
---
title: schema.dashboard.sql — Dashboards & Views
---
classDiagram
    class dashboards {
        +UUID id
        +UUID workspace_id
        +VARCHAR name
        +VARCHAR slug
        +TEXT description
        +BOOLEAN is_default
        +BOOLEAN is_locked
        +VARCHAR visibility
        +INT refresh_interval
    }

    class dashboard_permissions {
        +UUID id
        +UUID dashboard_id
        +VARCHAR grantee_type
        +UUID grantee_id
        +BOOLEAN can_view
        +BOOLEAN can_edit
        +BOOLEAN can_publish
        +BOOLEAN can_share
    }

    class views {
        +UUID id
        +UUID collection_id
        +UUID workspace_id
        +VARCHAR name
        +VARCHAR slug
        +VARCHAR view_type
        +BOOLEAN is_default
        +BOOLEAN is_locked
        +VARCHAR visibility
    }

    class view_permissions {
        +UUID id
        +UUID view_id
        +VARCHAR grantee_type
        +UUID grantee_id
        +BOOLEAN can_view
        +BOOLEAN can_edit
    }

    class dashboard_templates {
        +UUID id
        +UUID organization_id
        +VARCHAR name
        +TEXT description
        +VARCHAR category
        +BOOLEAN is_public
        +JSONB template_data
    }

    dashboards "1" --> "*" dashboard_permissions : grants
    views "1" --> "*" view_permissions : grants

    note for dashboards "visibility: private | workspace |\nproject | organization | public\n\nLayout in MongoDB dashboard_layouts"
    note for views "view_type: table | kanban |\ncalendar | gallery | form |\nchart | timeline | map |\nlist | pivot\n\nConfig in MongoDB view_configs"
    note for dashboard_templates "org_id NULL → global template\nis_public → all orgs can use\ntemplate_data → serialized layout"
```

### 3.5 — Resource Registry

```mermaid
---
title: schema.resource.sql — Polymorphic Resource Layer
---
classDiagram
    class resources {
        +UUID id
        +UUID organization_id
        +VARCHAR resource_type
        +UUID resource_id
        +VARCHAR name
    }

    class resource_permissions {
        +UUID id
        +UUID resource_id
        +VARCHAR grantee_type
        +UUID grantee_id
        +VARCHAR[] actions
        +TIMESTAMPTZ expires_at
    }

    class resource_versions {
        +UUID id
        +UUID resource_id
        +INT version_number
        +JSONB snapshot
        +TEXT change_summary
        +JSONB change_diff
    }

    class resource_shares {
        +UUID id
        +UUID resource_id
        +VARCHAR share_type
        +VARCHAR share_token
        +VARCHAR[] permissions
        +TEXT password_hash
        +INT max_uses
        +INT use_count
        +BOOLEAN is_active
    }

    class resource_relations {
        +UUID id
        +UUID source_resource_id
        +UUID target_resource_id
        +VARCHAR relation_type
        +JSONB metadata
    }

    class tags {
        +UUID id
        +UUID organization_id
        +VARCHAR name
        +VARCHAR slug
        +VARCHAR color
    }

    class resource_tags {
        +UUID resource_id
        +UUID tag_id
    }

    class comments {
        +UUID id
        +UUID resource_id
        +UUID user_id
        +UUID parent_id
        +TEXT content
        +BOOLEAN is_resolved
    }

    resources "1" --> "*" resource_permissions : grants
    resources "1" --> "*" resource_versions : versioned
    resources "1" --> "*" resource_shares : shared via
    resources "1" --> "*" resource_relations : relates
    resources "1" --> "*" resource_tags : tagged
    resources "1" --> "*" comments : discussed
    tags "1" --> "*" resource_tags : applied
    comments "0..1" --> "*" comments : "threaded replies"

    note for resources "resource_type: dashboard |\ncollection | view | workspace |\nproject | file | adapter |\ntemplate | report\n\nPolymorphic: resource_id is NOT FK"
    note for resource_relations "relation_type:\ndepends_on | linked_to |\nembedded_in | derived_from |\nparent_of"
```

---

## 4 — Use Case Diagrams

### 4.1 — Platform Actors & Use Cases

```mermaid
---
title: Platform Use Cases — All Actors
---
flowchart LR
    classDef actor fill:#3b82f6,stroke:#2563eb,color:#fff
    classDef usecase fill:#f8fafc,stroke:#94a3b8,color:#0f172a
    classDef system fill:#f59e0b,stroke:#d97706,color:#000

    GUEST["👤 Guest"]:::actor
    USER["👤 Authenticated\nUser"]:::actor
    ADMIN["👤 Org Admin"]:::actor
    BILLING["👤 Billing\nAdmin"]:::actor
    PLATFORM["👤 Platform\nSuper Admin"]:::actor
    SYSTEM["⚙️ System\n(Cron/CDC)"]:::system

    subgraph AUTH["Authentication"]
        UC1["Register / Login"]:::usecase
        UC2["OAuth Login\n(42/Google/GitHub)"]:::usecase
        UC3["Enable MFA"]:::usecase
        UC4["Manage API Keys"]:::usecase
    end

    subgraph DATA["Data Management"]
        UC5["Create Collection"]:::usecase
        UC6["Define Fields\n& Relations"]:::usecase
        UC7["CRUD Records\n(→ MongoDB)"]:::usecase
        UC8["Create Views\n(table/kanban/chart)"]:::usecase
        UC9["Build Dashboards\n& Widgets"]:::usecase
    end

    subgraph COLLAB["Collaboration"]
        UC10["Invite Members"]:::usecase
        UC11["Assign Roles"]:::usecase
        UC12["Share Resources\n(link/email/embed)"]:::usecase
        UC13["Comment &\nThread"]:::usecase
        UC14["Tag Resources"]:::usecase
    end

    subgraph INTEGRATION["Integration & Sync"]
        UC15["Configure Adapter\n(REST/CSV/Sheets)"]:::usecase
        UC16["Connect External DB"]:::usecase
        UC17["Setup CDC\nSync Channel"]:::usecase
        UC18["Provision Managed\nDB (Supabase/Atlas)"]:::usecase
    end

    subgraph BILLING_UC["Billing & Usage"]
        UC19["Subscribe to Plan"]:::usecase
        UC20["Apply Promo Code"]:::usecase
        UC21["View Invoices\n& Pay"]:::usecase
        UC22["Monitor Usage\nQuotas"]:::usecase
    end

    subgraph ADMIN_UC["Administration"]
        UC23["Define ABAC\nConditions"]:::usecase
        UC24["Create Policy\nRules"]:::usecase
        UC25["Configure Webhooks"]:::usecase
        UC26["Manage File\nUploads"]:::usecase
        UC27["Set Org Branding\n& Security"]:::usecase
    end

    subgraph SYSTEM_UC["System Processes"]
        UC28["Execute Adapter\nSync"]:::usecase
        UC29["CDC Change\nPropagation"]:::usecase
        UC30["Webhook\nDelivery"]:::usecase
        UC31["Usage Metering"]:::usecase
        UC32["Session Cleanup"]:::usecase
    end

    GUEST --> UC1
    GUEST --> UC2

    USER --> UC3
    USER --> UC4
    USER --> UC5
    USER --> UC6
    USER --> UC7
    USER --> UC8
    USER --> UC9
    USER --> UC13
    USER --> UC14

    ADMIN --> UC10
    ADMIN --> UC11
    ADMIN --> UC12
    ADMIN --> UC15
    ADMIN --> UC16
    ADMIN --> UC17
    ADMIN --> UC23
    ADMIN --> UC24
    ADMIN --> UC25
    ADMIN --> UC26
    ADMIN --> UC27

    BILLING --> UC19
    BILLING --> UC20
    BILLING --> UC21
    BILLING --> UC22

    PLATFORM --> UC18
    PLATFORM --> UC24

    SYSTEM --> UC28
    SYSTEM --> UC29
    SYSTEM --> UC30
    SYSTEM --> UC31
    SYSTEM --> UC32
```

### 4.2 — Data Management Use Cases (Detailed)

```mermaid
---
title: Data Management — Actor Interactions
---
flowchart TB
    classDef actor fill:#3b82f6,stroke:#2563eb,color:#fff
    classDef uc fill:#fefce8,stroke:#ca8a04,color:#000
    classDef include fill:#dcfce7,stroke:#16a34a,color:#000
    classDef extend fill:#fce7f3,stroke:#db2777,color:#000

    USER["👤 User"]:::actor

    USER --> CREATE_COLL["Create Collection"]:::uc
    USER --> ADD_FIELD["Add Field to Collection"]:::uc
    USER --> CRUD["CRUD Records"]:::uc
    USER --> CREATE_VIEW["Create View"]:::uc
    USER --> BUILD_DASH["Build Dashboard"]:::uc
    USER --> SHARE["Share Resource"]:::uc

    CREATE_COLL --> |"«includes»"| REGISTER_RES["Register in\nResource Registry"]:::include
    ADD_FIELD --> |"«includes»"| SYNC_INDEX["Sync MongoDB\nIndexes"]:::include
    CRUD --> |"«includes»"| VALIDATE["Validate Against\nField Schema"]:::include
    CRUD --> |"«includes»"| AUDIT["Log in\nAudit Trail"]:::include
    BUILD_DASH --> |"«includes»"| PERM_CHECK["Check Dashboard\nPermissions"]:::include
    SHARE --> |"«includes»"| GEN_TOKEN["Generate\nShare Token"]:::include

    CRUD --> |"«extends»"| TRIGGER_WF["Trigger\nWorkflow"]:::extend
    CRUD --> |"«extends»"| INVALIDATE["Invalidate\nQuery Cache"]:::extend
    CRUD --> |"«extends»"| FIRE_WEBHOOK["Fire\nWebhook"]:::extend
    CRUD --> |"«extends»"| CDC_PUSH["CDC Push to\nExternal DB"]:::extend
```

---

## 5 — Sequence Diagrams

### 5.1 — Permission Resolution Chain

```mermaid
---
title: Permission Check — Full RBAC + ABAC Resolution
---
sequenceDiagram
    actor User
    participant API as NestJS API
    participant UP as user_permissions
    participant URA as user_role_assignments
    participant RP as role_permissions
    participant ABAC as abac_conditions
    participant PR as policy_rules
    participant ResP as resource_permissions
    participant EP as entity_permissions

    User ->> API: Request (e.g., GET /dashboard/123)
    API ->> API: Extract user_id + resource_type + action

    Note over API,EP: Step 1-2: Check DIRECT user overrides

    API ->> UP: SELECT granted FROM user_permissions<br/>WHERE user_id=$user AND permission_id=$perm
    alt Explicit DENY found
        UP -->> API: granted = FALSE
        API -->> User: 403 Forbidden (explicit deny)
    else Explicit ALLOW found
        UP -->> API: granted = TRUE
        Note over API: Continue (allow, but still run ABAC)
    else No direct override
        UP -->> API: No rows
    end

    Note over API,EP: Step 3: Check ROLE-based permissions

    API ->> URA: SELECT role_id FROM user_role_assignments<br/>WHERE user_id=$user AND context matches
    URA -->> API: role_ids[]
    API ->> RP: SELECT permission_id FROM role_permissions<br/>WHERE role_id IN (role_ids)
    alt Permission NOT in any role
        RP -->> API: No match
    else Permission granted by role
        RP -->> API: Match found
    end

    Note over API,EP: Step 4: Evaluate ABAC conditions

    API ->> ABAC: SELECT * FROM abac_conditions<br/>WHERE permission_id=$perm<br/>AND (role_id IS NULL OR role_id=$current_role)
    ABAC -->> API: conditions[]
    API ->> API: Evaluate attribute expressions<br/>against user/resource/env context
    alt ABAC condition fails
        API -->> User: 403 Forbidden (ABAC denied)
    end

    Note over API,EP: Step 5: Evaluate org-level policies

    API ->> PR: SELECT * FROM policy_rules<br/>WHERE org_id=$org AND resource_type=$type<br/>AND is_active=TRUE ORDER BY priority DESC
    PR -->> API: policies[]
    API ->> API: Evaluate policy conditions
    alt Policy denies
        API -->> User: 403 Forbidden (policy denied)
    end

    Note over API,EP: Step 6-7: Check resource & entity permissions

    API ->> ResP: SELECT actions FROM resource_permissions<br/>WHERE resource_id=$res AND grantee matches
    API ->> EP: SELECT * FROM dashboard_permissions<br/>WHERE dashboard_id=$id AND grantee matches

    alt ALL checks pass
        API -->> User: 200 OK (access granted)
    else Default DENY
        API -->> User: 403 Forbidden
    end
```

### 5.2 — Record CRUD with Validation

```mermaid
---
title: Create Record — SQL Validation + MongoDB Storage
---
sequenceDiagram
    actor User
    participant API as NestJS API
    participant PG as PostgreSQL
    participant Mongo as MongoDB
    participant Cache as query_cache
    participant Audit as audit_log
    participant WF as workflow_engine

    User ->> API: POST /collections/{id}/records {data}

    Note over API,PG: 1. Schema validation (SQL-driven)

    API ->> PG: SELECT * FROM fields<br/>WHERE collection_id = $id
    PG -->> API: field definitions[]
    API ->> API: Validate data against field types,<br/>required, unique, validation_rules

    alt Validation fails
        API -->> User: 400 Bad Request {errors}
    end

    Note over API,PG: 2. Permission check

    API ->> PG: Check user_permissions → role_permissions<br/>→ abac_conditions → policy_rules
    alt Not authorized
        API -->> User: 403 Forbidden
    end

    Note over API,Mongo: 3. Write to MongoDB

    API ->> Mongo: collection_records.insertOne({<br/>  collection_id, workspace_id, org_id,<br/>  data, version: 1<br/>})
    Mongo -->> API: created record

    Note over API,PG: 4. Update counters

    API ->> PG: UPDATE collections SET<br/>record_count = record_count + 1<br/>WHERE id = $collection_id

    Note over API,Audit: 5. Post-write side effects

    par Cache invalidation
        API ->> Cache: Delete entries WHERE<br/>collection_id = $id
    and Audit trail
        API ->> Audit: audit_log.insertOne({<br/>  action: 'record.created',<br/>  changes: {after: data}<br/>})
    and Workflow trigger
        API ->> WF: Check workflow_definitions<br/>WHERE trigger.type = 'record_created'<br/>AND trigger.collection_id = $id
    end

    API -->> User: 201 Created {record}
```

### 5.3 — Subscription & Billing Flow

```mermaid
---
title: Subscribe to Plan — Full Billing Flow
---
sequenceDiagram
    actor Admin as Org Admin
    participant API as NestJS API
    participant PG as PostgreSQL
    participant Stripe as Stripe API
    participant Audit as audit_log

    Admin ->> API: POST /billing/subscribe {plan_slug, promo_code?}

    API ->> PG: SELECT * FROM plans WHERE slug=$slug AND is_active
    PG -->> API: plan

    opt Promo code provided
        API ->> PG: SELECT * FROM promotions<br/>WHERE code=$code AND is_active<br/>AND now() BETWEEN starts_at AND ends_at
        PG -->> API: promotion
        API ->> PG: SELECT * FROM promotion_plans<br/>WHERE promotion_id=$promo AND plan_id=$plan
        alt Promo not valid for this plan
            API -->> Admin: 400 Bad Request
        end
    end

    API ->> PG: SELECT * FROM plan_features<br/>WHERE plan_id = $plan_id
    PG -->> API: feature limits[]

    API ->> Stripe: Create Subscription<br/>{customer_id, price_id, coupon?}
    Stripe -->> API: subscription object

    API ->> PG: INSERT INTO subscriptions<br/>(org_id, plan_id, promotion_id,<br/>status, billing_period, period_end,<br/>external_subscription_id)
    API ->> PG: INSERT INTO invoices<br/>(subscription_id, org_id, amounts,<br/>period_start, period_end, due_date)

    opt Promo applied
        API ->> PG: UPDATE promotions SET<br/>current_redemptions = current_redemptions + 1
    end

    API ->> Audit: Log subscription.created event

    API -->> Admin: 200 OK {subscription, invoice}
```

### 5.4 — CDC Real-Time Sync

```mermaid
---
title: CDC Sync — User DB Change → Platform Update
---
sequenceDiagram
    participant UserDB as User's Database
    participant CDC as CDC Engine
    participant PG as PostgreSQL
    participant Mongo as MongoDB
    participant Vault as connection_credentials
    participant State as sync_state
    participant Cache as query_cache

    Note over UserDB,Cache: Inbound Change: User's DB → Platform

    UserDB ->> CDC: WAL event / Change Stream /<br/>Binlog event detected

    CDC ->> PG: SELECT * FROM sync_channels<br/>WHERE connection_id=$conn<br/>AND source_path=$table<br/>AND is_active=TRUE
    PG -->> CDC: sync channel config

    CDC ->> Vault: Decrypt credentials<br/>(connection_credentials.find({connection_id}))
    Vault -->> CDC: Decrypted creds

    CDC ->> State: Read inbound_cursor<br/>(sync_state.find({channel_id}))
    State -->> CDC: last LSN / resume token

    CDC ->> CDC: Transform data via<br/>field_mappings + transform_rules

    CDC ->> Mongo: collection_records.upsert({<br/>  filter: {collection_id, source_record_id},<br/>  update: {data, version++}<br/>})

    CDC ->> State: Update inbound_cursor,<br/>total_records_in++,<br/>current_lag_ms

    CDC ->> PG: INSERT INTO sync_executions<br/>{channel_id, status, records_in}

    CDC ->> Cache: Invalidate cache entries<br/>WHERE collection_id = $id

    Note over UserDB,Cache: Conflict Detection

    alt Same record changed on both sides
        CDC ->> State: Add to conflict_queue[]
        alt conflict_strategy = newest_wins
            CDC ->> CDC: Compare timestamps, auto-resolve
        else conflict_strategy = manual
            CDC ->> State: pending_conflicts++
            Note over State: User resolves in UI
        end
    end
```

### 5.5 — Adapter Sync Execution

```mermaid
---
title: Adapter Sync — External Source → Platform
---
sequenceDiagram
    participant Cron as Scheduler
    participant API as Sync Engine
    participant PG as PostgreSQL
    participant Ext as External Source<br/>(REST/CSV/Sheets)
    participant Mongo as MongoDB

    Cron ->> API: Trigger sync (scheduled / manual)

    API ->> PG: SELECT a.*, am.* FROM adapters a<br/>JOIN adapter_mappings am ON am.adapter_id = a.id<br/>WHERE a.id = $adapter_id AND a.is_active
    PG -->> API: adapter + mappings[]

    API ->> PG: INSERT INTO adapter_executions<br/>(adapter_id, mapping_id, status='running')
    PG -->> API: execution_id

    loop For each mapping
        API ->> Ext: Fetch data from source_path<br/>(GET /api/v1/users, read CSV, etc.)
        Ext -->> API: raw data[]

        API ->> API: Apply field_mappings<br/>Transform via transform_rules

        API ->> PG: SELECT * FROM fields<br/>WHERE collection_id = $mapping.collection_id
        PG -->> API: field schema

        API ->> API: Validate against field types

        API ->> Mongo: Bulk upsert into<br/>collection_records
        Mongo -->> API: write results

        API ->> PG: UPDATE adapter_mappings SET<br/>last_sync_at=now(), last_sync_status=$status
    end

    API ->> PG: UPDATE adapter_executions SET<br/>status=$result, records_processed=$n,<br/>completed_at=now(), duration_ms=$ms
    API ->> PG: UPDATE adapters SET<br/>health_status = CASE status ...

    API -->> Cron: Execution complete
```

---

## 6 — Flowcharts

### 6.1 — Permission Resolution Flowchart

```mermaid
---
title: Permission Resolution — Decision Flow
---
flowchart TD
    START([User requests action]) --> CHECK_UP{Check<br/>user_permissions}

    CHECK_UP -->|"granted = FALSE\n(explicit deny)"| DENY([❌ 403 DENY])
    CHECK_UP -->|"granted = TRUE\n(explicit allow)"| PASS_UP[Direct allow]
    CHECK_UP -->|"No override"| CHECK_ROLES{Check roles via<br/>user_role_assignments}

    PASS_UP --> CHECK_ABAC

    CHECK_ROLES -->|"Role has permission"| CHECK_ABAC{Evaluate<br/>abac_conditions}
    CHECK_ROLES -->|"No matching role<br/>permission"| CHECK_POLICY

    CHECK_ABAC -->|"Conditions pass"| CHECK_POLICY{Evaluate<br/>policy_rules}
    CHECK_ABAC -->|"Conditions fail"| DENY

    CHECK_POLICY -->|"effect = deny"| DENY
    CHECK_POLICY -->|"No deny / allow"| CHECK_RES{Check<br/>resource_permissions}

    CHECK_RES -->|"Actions include<br/>requested action"| CHECK_ENTITY{Check entity<br/>permissions}
    CHECK_RES -->|"No resource<br/>grant"| CHECK_ENTITY

    CHECK_ENTITY -->|"Has entity permission"| ALLOW([✅ 200 ALLOW])
    CHECK_ENTITY -->|"No entity permission"| FINAL{Any prior<br/>layer allowed?}

    FINAL -->|"Yes"| ALLOW
    FINAL -->|"No"| DENY

    style DENY fill:#ef4444,stroke:#dc2626,color:#fff
    style ALLOW fill:#22c55e,stroke:#16a34a,color:#fff
    style START fill:#3b82f6,stroke:#2563eb,color:#fff
```

### 6.2 — Record Lifecycle Flowchart

```mermaid
---
title: Record Lifecycle — From Creation to Deletion
---
flowchart TD
    classDef sql fill:#f59e0b,stroke:#d97706,color:#000
    classDef mongo fill:#3b82f6,stroke:#2563eb,color:#fff
    classDef action fill:#22c55e,stroke:#16a34a,color:#fff
    classDef check fill:#f8fafc,stroke:#94a3b8,color:#0f172a

    START([User submits data]) --> VALIDATE{Validate against<br/>SQL fields table}:::sql

    VALIDATE -->|"Invalid"| ERROR([400 Bad Request])
    VALIDATE -->|"Valid"| PERM{Permission<br/>check (RBAC+ABAC)}:::sql

    PERM -->|"Denied"| FORBIDDEN([403 Forbidden])
    PERM -->|"Allowed"| WRITE[Write to MongoDB<br/>collection_records]:::mongo

    WRITE --> PAR1[/Parallel side effects/]

    PAR1 --> COUNT[Update SQL<br/>record_count]:::sql
    PAR1 --> AUDIT[Insert MongoDB<br/>audit_log]:::mongo
    PAR1 --> CACHE[Invalidate<br/>query_cache]:::mongo
    PAR1 --> WFCHECK{Matching<br/>workflow?}:::check

    WFCHECK -->|"Yes"| WF_EXEC[Create workflow<br/>execution]:::mongo
    WFCHECK -->|"No"| SKIP1[Skip]

    PAR1 --> HOOKCHECK{Matching<br/>webhook?}:::check
    HOOKCHECK -->|"Yes"| HOOK_FIRE[Fire webhook<br/>+ log delivery]:::sql
    HOOKCHECK -->|"No"| SKIP2[Skip]

    PAR1 --> CDCCHECK{Active CDC<br/>sync channel?}:::check
    CDCCHECK -->|"Yes"| CDC_PUSH[Push to user's<br/>external DB]:::action
    CDCCHECK -->|"No"| SKIP3[Skip]

    COUNT --> DONE([201 Created])
    AUDIT --> DONE
    CACHE --> DONE

    style ERROR fill:#ef4444,stroke:#dc2626,color:#fff
    style FORBIDDEN fill:#ef4444,stroke:#dc2626,color:#fff
    style DONE fill:#22c55e,stroke:#16a34a,color:#fff
```

### 6.3 — Subscription Lifecycle Flowchart

```mermaid
---
title: Subscription Status Lifecycle
---
stateDiagram-v2
    [*] --> trialing : Org creates subscription\n(plan has trial_days > 0)
    [*] --> active : Org subscribes\n(no trial)

    trialing --> active : Trial ends +\npayment succeeds
    trialing --> cancelled : Trial ends +\nno payment method

    active --> past_due : Payment fails
    active --> paused : Admin pauses
    active --> cancelled : Admin cancels\n(cancel_at_period_end)

    past_due --> active : Retry payment succeeds
    past_due --> cancelled : Max retries exceeded

    paused --> active : Admin reactivates

    cancelled --> expired : Period ends
    expired --> [*]

    note right of active
        Normal operating state.
        Invoices generated per cycle.
        Usage metered continuously.
    end note

    note right of past_due
        Grace period.
        Stripe retries payment.
        Features may be limited.
    end note
```

### 6.4 — Database Connection Setup Flow

```mermaid
---
title: External DB Connection — Setup Flow
---
flowchart TD
    START([Admin initiates\nDB connection]) --> TYPE{Connection\ntype?}

    TYPE -->|"User-owned DB"| CREDS[Collect credentials\n(host, port, user, pass)]
    TYPE -->|"Managed / Provisioned"| PROVIDER{Select\nprovider}

    PROVIDER -->|"Supabase"| PROV_SB[Provision via\nSupabase Management API]
    PROVIDER -->|"MongoDB Atlas"| PROV_ATLAS[Provision via\nAtlas Admin API]

    PROV_SB --> AUTO_CONN[Auto-create\ndatabase_connection]
    PROV_ATLAS --> AUTO_CONN

    CREDS --> ENCRYPT[Encrypt credentials\nAES-256-GCM]
    ENCRYPT --> STORE[Store in MongoDB\nconnection_credentials]
    STORE --> CREATE_CONN[Create SQL\ndatabase_connections row\n(credential_ref → MongoDB)]

    AUTO_CONN --> TEST_CONN
    CREATE_CONN --> TEST_CONN{Test\nconnection}

    TEST_CONN -->|"Failed"| FAIL([Connection failed\nUpdate health_status])
    TEST_CONN -->|"Success"| INTROSPECT[Introspect remote\nschema]

    INTROSPECT --> CACHE_SCHEMA[Cache schema in\nschema_cache JSONB]
    CACHE_SCHEMA --> SETUP_SYNC{Setup sync\nchannel?}

    SETUP_SYNC -->|"Yes"| MAP_FIELDS[Map remote fields\n→ local fields]
    SETUP_SYNC -->|"No"| DONE([Connection ready\nhealth_status = healthy])

    MAP_FIELDS --> CREATE_COLL[Create/link\nSQL collection + fields]
    CREATE_COLL --> CREATE_CHAN[Create SQL\nsync_channel]
    CREATE_CHAN --> INIT_STATE[Initialize MongoDB\nsync_state document]
    INIT_STATE --> START_CDC{Sync mode?}

    START_CDC -->|"CDC Realtime"| SLOT[Create replication\nslot / change stream]
    START_CDC -->|"Polling"| POLL[Start polling\ntimer]
    START_CDC -->|"Webhook"| WEBHOOK_EP[Register webhook\nendpoint]

    SLOT --> ACTIVE([Sync active ✅])
    POLL --> ACTIVE
    WEBHOOK_EP --> ACTIVE

    style FAIL fill:#ef4444,stroke:#dc2626,color:#fff
    style DONE fill:#22c55e,stroke:#16a34a,color:#fff
    style ACTIVE fill:#22c55e,stroke:#16a34a,color:#fff
```

### 6.5 — Webhook Delivery Flow

```mermaid
---
title: Webhook Delivery — Event to Delivery
---
flowchart TD
    EVENT([Platform event fires\ne.g., record.created]) --> MATCH{Find matching\nwebhooks}

    MATCH --> QUERY[SELECT * FROM webhooks\nWHERE org_id=$org\nAND $event = ANY events\nAND is_active = TRUE]

    QUERY --> FOUND{Webhooks\nfound?}

    FOUND -->|"None"| DONE_NO([No delivery needed])
    FOUND -->|"1+ found"| LOOP[/For each webhook/]

    LOOP --> SIGN[Compute HMAC signature\nusing secret_hash]
    SIGN --> POST[POST to webhook.url\nwith payload + signature\n+ custom headers]

    POST --> RESP{Response\nstatus?}

    RESP -->|"2xx"| LOG_OK[Log delivery:\nstatus=success,\nresponse_status, duration_ms]
    RESP -->|"4xx/5xx\nor timeout"| RETRY{Attempt <\nretry_count?}

    RETRY -->|"Yes"| DELAY[Wait retry_delay_ms\n× attempt_number]
    DELAY --> POST
    RETRY -->|"No, max retries"| LOG_FAIL[Log delivery:\nstatus=failed,\nerror details]

    LOG_OK --> UPDATE[UPDATE webhooks SET\nlast_triggered_at, last_status]
    LOG_FAIL --> UPDATE

    UPDATE --> NEXT{More\nwebhooks?}
    NEXT -->|"Yes"| LOOP
    NEXT -->|"No"| DONE([All deliveries complete])

    style DONE_NO fill:#94a3b8,stroke:#64748b,color:#fff
    style DONE fill:#22c55e,stroke:#16a34a,color:#fff
    style LOG_FAIL fill:#ef4444,stroke:#dc2626,color:#fff
```

### 6.6 — Invoice Generation Flow

```mermaid
---
title: Invoice Generation — Billing Cycle
---
flowchart TD
    TRIGGER([Billing cycle ends\nor cron triggers]) --> FETCH[SELECT * FROM subscriptions\nWHERE status = 'active'\nAND current_period_end <= now]

    FETCH --> LOOP[/For each subscription/]

    LOOP --> PLAN[Fetch plan pricing\nplans.price_monthly/yearly]
    PLAN --> USAGE[Aggregate usage_records\nfor billing period]
    USAGE --> OVERAGE{Usage exceeds\nplan limits?}

    OVERAGE -->|"Yes"| CALC_OVER[Calculate overage\ncharges]
    OVERAGE -->|"No"| BASE[Base plan amount only]

    CALC_OVER --> PROMO
    BASE --> PROMO{Active\npromotion?}

    PROMO -->|"Yes"| DISCOUNT[Apply discount:\npercentage or fixed]
    PROMO -->|"No"| TAX

    DISCOUNT --> TAX[Calculate tax]
    TAX --> CREATE_INV[INSERT INTO invoices\nsubtotal, discount, tax, total]

    CREATE_INV --> CHARGE{Auto-charge\nenabled?}

    CHARGE -->|"Yes"| STRIPE[Charge via Stripe\n(external_customer_id)]
    CHARGE -->|"No"| PENDING([Invoice status: pending\nAwait manual payment])

    STRIPE --> SUCCESS{Payment\nsucceeded?}

    SUCCESS -->|"Yes"| PAID[UPDATE invoice status='paid'\nINSERT INTO payments status='succeeded'\nAdvance subscription period]
    SUCCESS -->|"No"| PAST_DUE[UPDATE invoice status='past_due'\nUPDATE subscription status='past_due'\nINSERT INTO payments status='failed']

    PAID --> NEXT{More\nsubscriptions?}
    PAST_DUE --> NEXT
    PENDING --> NEXT

    NEXT -->|"Yes"| LOOP
    NEXT -->|"No"| DONE([Billing cycle complete])

    style DONE fill:#22c55e,stroke:#16a34a,color:#fff
    style PAST_DUE fill:#ef4444,stroke:#dc2626,color:#fff
    style PENDING fill:#f59e0b,stroke:#d97706,color:#000
```

---

## Appendix — Table Reference

| # | Schema File | Table | Purpose |
|---|---|---|---|
| 1 | user | `users` | Core identity |
| 2 | user | `oauth_accounts` | OAuth provider links |
| 3 | user | `roles` | RBAC role definitions |
| 4 | user | `permissions` | Atomic permission atoms |
| 5 | user | `role_permissions` | Role ↔ Permission junction |
| 6 | user | `user_role_assignments` | User ↔ Role scoped binding |
| 7 | user | `abac_conditions` | Attribute conditions on permissions |
| 8 | user | `user_permissions` | Direct user permission overrides |
| 9 | user | `user_sessions` | Active login sessions |
| 10 | user | `contacts` | Personal address book |
| 11 | user | `api_keys` | Programmatic API tokens |
| 12 | organization | `organizations` | Top-level tenant |
| 13 | organization | `organization_members` | Org membership |
| 14 | organization | `projects` | Logical project groupings |
| 15 | organization | `project_members` | Project membership |
| 16 | organization | `workspaces` | Data containers |
| 17 | organization | `workspace_members` | Workspace membership |
| 18 | collection | `collections` | Tenant-defined data tables |
| 19 | collection | `fields` | Column definitions (28 types) |
| 20 | collection | `field_options` | Select/multi-select options |
| 21 | collection | `collection_relations` | Inter-collection relations |
| 22 | collection | `collection_indices` | Custom MongoDB indexes |
| 23 | dashboard | `dashboards` | Dashboard identity |
| 24 | dashboard | `dashboard_permissions` | Per-dashboard access |
| 25 | dashboard | `views` | View identity (10 types) |
| 26 | dashboard | `view_permissions` | Per-view access |
| 27 | dashboard | `dashboard_templates` | Reusable layout templates |
| 28 | resource | `resources` | Polymorphic resource registry |
| 29 | resource | `resource_permissions` | Resource-level access |
| 30 | resource | `resource_versions` | Snapshot versioning |
| 31 | resource | `resource_shares` | Shareable links |
| 32 | resource | `resource_relations` | Cross-resource relations |
| 33 | resource | `tags` | Org-scoped taxonomy |
| 34 | resource | `resource_tags` | Resource ↔ Tag junction |
| 35 | resource | `comments` | Threaded comments |
| 36 | adapter | `adapters` | External source connections |
| 37 | adapter | `adapter_mappings` | Source → Collection mappings |
| 38 | adapter | `adapter_executions` | Sync execution log |
| 39 | system | `webhooks` | Outbound event hooks |
| 40 | system | `webhook_deliveries` | Delivery attempt log |
| 41 | system | `notifications` | In-app notifications |
| 42 | system | `policy_rules` | Org-level ABAC policies |
| 43 | system | `file_uploads` | Managed file attachments |
| 44 | billing | `plans` | Subscription tiers |
| 45 | billing | `plan_features` | Feature limits per plan |
| 46 | billing | `promotions` | Discount codes / coupons |
| 47 | billing | `subscriptions` | Org ↔ Plan binding |
| 48 | billing | `promotion_plans` | Promo ↔ Plan junction |
| 49 | billing | `invoices` | Billing invoices |
| 50 | billing | `payments` | Payment transactions |
| 51 | billing | `usage_meters` | Metering definitions |
| 52 | billing | `usage_records` | Actual usage data points |
| 53 | connectivity | `provisioned_databases` | Managed DB instances |
| 54 | connectivity | `database_connections` | External DB connections |
| 55 | connectivity | `sync_channels` | CDC sync channel config |
| 56 | connectivity | `sync_executions` | Sync operation log |
