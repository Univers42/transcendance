# Business Model — Full Mindmap

> How this SaaS platform (Kibana × Notion × Airtable) was conceived,
> from vision to implementation decisions.

---

## 1 — Product Vision Mindmap

```mermaid
mindmap
  root(("🚀 SaaS Data Platform<br/>Kibana × Notion × Airtable"))
    ))Core Value Proposition((
      Any data, anywhere
        Connect your own DB
        Or we provision one for you
      Visual, no-code data modeling
        Define tables at runtime
        28 field types
        Relations between collections
      Real-time dashboards
        15 widget types
        Drag-and-drop layout
        Auto-refresh
      Collaboration-first
        Multi-tenant orgs
        Role-based access
        Comments & sharing
      Enterprise-grade security
        RBAC + ABAC layered
        Encrypted credentials
        Audit trail everything

    ))Target Users((
      Startup founders
        Need quick internal tools
        Can't afford dedicated BI team
      Product teams
        Track roadmaps & metrics
        Kanban + calendar views
      Data engineers
        Connect production DBs
        Real-time CDC sync
        Monitor data pipelines
      Business analysts
        Build dashboards
        No SQL required
        Share with stakeholders
      Enterprise IT admins
        SSO & MFA enforcement
        Organization-wide policies
        Usage monitoring & billing

    ))Competitive Edge((
      vs Airtable
        Real database connections
        Not just spreadsheets
        CDC bidirectional sync
      vs Notion
        Native data visualization
        Dashboard widgets
        Formula & rollup fields
      vs Kibana
        No YAML configs
        Visual query builder
        Multi-source support
      vs Retool
        Self-serve, no dev needed
        Built-in data modeling
        Persistent data layer
```

---

## 2 — Architecture Thinking Mindmap

```mermaid
mindmap
  root(("🏗️ Architecture<br/>Decisions"))
    ))Why Two Databases?((
      PostgreSQL for structure
        ACID transactions
        Foreign key integrity
        Schema definitions
        Permission model
        Billing & subscriptions
      MongoDB for flexibility
        Schema-free record data
        Deeply nested configs
        Frequent partial updates
        TTL-based caches
        Append-only logs
      The bridge
        SQL defines WHAT exists
        MongoDB stores HOW it looks & behaves
        UUIDs cross the boundary
        collection_id links both worlds

    ))Why NestJS + Prisma?((
      NestJS
        Module-based architecture
        Built-in DI container
        Guards & interceptors for auth
        WebSocket gateway for real-time
      Prisma
        Type-safe SQL queries
        Migration management
        Schema introspection
      Mongoose
        Decorator-based schemas
        Middleware hooks
        Population & virtuals

    ))Why Multi-Tenant?((
      organization_id on everything
        Data isolation by design
        Query-level enforcement
        Index-first access pattern
      Hierarchy reasoning
        Organization = billing boundary
        Project = logical grouping
        Workspace = data sandbox
      Membership model
        Pure fact tables
        Roles via single assignment table
        No duplicated role columns

    ))Why RBAC + ABAC?((
      RBAC alone is not enough
        "Editor can edit" — but WHICH resources?
        "Viewer can view" — but not CONFIDENTIAL ones
      ABAC fills the gap
        User attributes: department, IP range
        Resource attributes: sensitivity, owner
        Environment: time of day, location
      Layered resolution
        8-step chain
        Explicit deny always wins
        Default: DENY
```

---

## 3 — Domain Decomposition Mindmap

```mermaid
mindmap
  root(("📐 Domain<br/>Decomposition"))
    ))1. Identity & Auth((
      Users
        Email + password
        OAuth providers: 42, Google, GitHub
        MFA with TOTP
        Status: online/offline/busy/away
      Sessions
        JWT token hashing
        IP tracking
        Activity timeout
        Multi-device support
      API Keys
        Scoped permissions
        Rate limiting
        Revocable
      Contacts
        Personal address book
        Link to platform users
        External contacts

    ))2. Organization Hierarchy((
      Organizations
        Tenant boundary
        Slug-based URL routing
        Feature flags via metadata
        Soft-delete with is_active
      Projects
        Logical grouping
        Icon + color theming
        Archivable
      Workspaces
        Data containers
        Types: default, data, analytics, admin, sandbox
        Default workspace per project
      Membership
        Pure join tables
        invited_by audit field
        No role column — uses user_role_assignments

    ))3. Permission Model((
      Roles
        4 scopes: global, org, project, workspace
        System roles are immutable
        Custom roles per org
      Permissions
        resource_type:action convention
        28+ atomic permissions
        System-defined, never edited
      ABAC Conditions
        Attached to permissions
        Optionally scoped to role
        AND/OR logic groups
      Policy Rules
        Org-wide broad policies
        Priority-based evaluation
        Allow/deny effects
      Direct Overrides
        Per-user grant/deny
        Temporal with expires_at
        Deny always wins

    ))4. Data Engine((
      Collections
        Runtime-defined tables
        28 field types
        Validation rules per field
        Display config per field
      Field Options
        Select/multi_select dropdowns
        Ordered, colored
      Collection Relations
        one_to_one, one_to_many, many_to_many
        Junction collections for M:N
        on_delete behavior
      Collection Indices
        Declarative in SQL
        Synced to MongoDB at runtime
        Unique + sparse support
      Records — MongoDB
        Schema-free data object
        Polymorphic cross-collection relations
        Soft-delete with is_deleted
        Full-text + wildcard indexes

    ))5. Presentation Layer((
      Dashboards
        Widget-based pages
        5 visibility levels
        Lock for editing control
        Auto-refresh interval
      Views
        10 view types
        Collection-bound
        Default view per collection
      Dashboard Templates
        Org-specific or global
        Category-based marketplace
        Clone to create new dash
      Layouts — MongoDB
        3-layer scope: template → shared → personal
        Grid config with responsive breakpoints
        15 widget types
        Global cross-widget filters
      View Configs — MongoDB
        Filters with nested AND/OR groups
        18 filter operators
        Kanban, calendar, gallery, chart configs
        Conditional row coloring

    ))6. Resource Registry((
      Universal registry
        Every entity registers once
        Inherit permissions, versions, shares
        9 resource types
      Versioning
        Snapshot-based
        Full state per version
        Optional diff for UI
      Sharing
        Link, email, embed modes
        Password protection
        Usage limits + counter
        Expirable
      Tagging
        Org-scoped taxonomy
        Many-to-many via junction
      Comments
        Threaded via parent_id
        Resolvable for reviews
      Cross-resource relations
        depends_on, linked_to
        embedded_in, derived_from
        parent_of

    ))7. Integration Layer((
      Adapters — generic connectors
        REST API, GraphQL
        CSV, Excel, Google Sheets
        S3 file imports
        Webhook receivers
      Adapter Mappings
        Source path → collection
        Field mapping + transforms
        Cron scheduling or realtime
        Conflict strategy
      Adapter Executions
        Immutable event log
        Metrics: processed, created, updated, failed
        Duration tracking

    ))8. Database Connectivity((
      User-owned databases
        Public endpoint
        SSH tunnel
        VPN / private link
      Managed provisioning
        Supabase PostgreSQL
        MongoDB Atlas
        PlanetScale, Neon — future
        Free → Enterprise tiers
      Database Connections
        7 engine types
        Schema introspection + caching
        Health monitoring
        Connection pooling
      CDC Sync Channels
        4 sync modes
        3 sync directions
        5 conflict strategies
        Error threshold + auto-pause
      Sync Executions
        Per-channel history
        Records in/out/conflicted
        Latency tracking
      Credentials — MongoDB
        AES-256-GCM encryption
        7 credential types
        Key rotation policies
        TTL for temporary creds
      Sync State — MongoDB
        CDC cursors per engine
        Lag monitoring + history
        Conflict queue with field-level detail

    ))9. Billing & Monetization((
      Plans
        free, starter, pro, enterprise
        Monthly + yearly pricing
        Trial periods
        Public + private plans
      Plan Features
        Decomposed limits per plan
        18+ feature keys
        NULL = unlimited
      Subscriptions
        One active per org
        6-state lifecycle
        External provider ID — Stripe/Paddle
      Promotions
        Unique codes
        percentage, fixed, trial extension
        Duration-limited
        Redemption limits
        Stackable flag — future
      Invoices
        Per billing cycle
        Line item breakdown
        6-state lifecycle
        External provider mapping
      Payments
        6 payment methods
        3 gateways
        Refund tracking
        Failure reasons
      Usage Metering
        Platform-defined meters
        3 aggregation types
        Reset per billing cycle
        Overage charging

    ))10. System Services((
      Webhooks
        Event-driven outbound
        HMAC signature verification
        Retry with backoff
        Delivery logging
      Notifications
        In-app notification index
        6 notification types
        Deep-link action URLs
        Read/unread tracking
      File Uploads
        Multi-backend storage
        S3 / GCS / Azure / local
        UUID-based stored names
        Organization-scoped
      Workflow Engine — MongoDB
        8 trigger types
        13 step types
        Error strategy per step
        Execution tracking with step results
      Query Cache — MongoDB
        Fingerprint-based dedup
        TTL auto-expiry
        Event-based invalidation
        Widget + view scoping
      Audit Log — MongoDB
        Append-only immutable
        4 actor types
        Before/after/diff snapshots
        TTL-based retention
      Global Settings — MongoDB
        3-scope inheritance
        Branding customization
        Security policies
        Feature toggles
      User Preferences — MongoDB
        Theme, locale, timezone
        Notification channels
        Sidebar layout
        Keyboard shortcuts
        Onboarding state
```

---

## 4 — Data Flow Thinking Mindmap

```mermaid
mindmap
  root(("🔄 Data Flow<br/>How Data Moves"))
    ))Write Path((
      User submits form
        API validates against SQL fields
        Permission check — 8-step chain
        Write to MongoDB collection_records
        Bump SQL record_count
      Side effects — parallel
        Invalidate query_cache
        Append to audit_log
        Check workflow triggers
        Fire matching webhooks
        CDC push to external DB

    ))Read Path((
      User opens dashboard
        Load SQL dashboard metadata
        Load MongoDB dashboard_layout — scope resolution
        For each widget
          Check query_cache — hit? serve
          Cache miss? query collection_records
          Apply view_configs filters/sorts
          Compute aggregations
          Store result in query_cache
        Return assembled dashboard

    ))Sync Path — Inbound((
      External DB change detected
        CDC engine reads WAL/change stream/binlog
        Decrypt credentials from MongoDB vault
        Read sync_state cursor
        Transform via field_mappings
        Upsert into collection_records
        Update sync_state cursor + metrics
        Log sync_execution in SQL
        Invalidate affected cache entries

    ))Sync Path — Outbound((
      Platform record changes
        Detect via application hooks
        Find active outbound sync_channels
        Decrypt credentials
        Transform to remote schema
        Write to user's database
        Update outbound cursor
        Log execution

    ))Billing Path((
      Time-based cycle
        Cron checks subscriptions at period_end
        Aggregate usage_records for period
        Compare against plan_features limits
        Calculate base + overage
        Apply promotion discount
        Generate invoice
        Charge via Stripe/Paddle
        Update subscription period
```

---

## 5 — Security Thinking Mindmap

```mermaid
mindmap
  root(("🔒 Security<br/>Model"))
    ))Authentication((
      Email + password
        bcrypt hashing
        Password policies via global_settings
      OAuth 2.0
        42 School, Google, GitHub
        Token encryption at rest
      MFA
        TOTP-based
        Enforced per-org via security settings
      Sessions
        Token hash stored, never plaintext
        IP + user agent tracking
        Activity-based timeout
        Max sessions per user
      API Keys
        Scope-limited
        Hash stored, plaintext shown once
        Revocable

    ))Authorization — 8 Layers((
      Layer 1 — user_permissions DENY
        Explicit deny always wins
        Cannot be overridden
      Layer 2 — user_permissions ALLOW
        Direct grant bypass
      Layer 3 — role_permissions
        Via user_role_assignments
        Scoped to context
      Layer 4 — abac_conditions
        Attribute-based guards
        Per-permission, optionally per-role
      Layer 5 — policy_rules
        Org-wide broad policies
        Priority-ordered
      Layer 6 — resource_permissions
        Per-resource grants
        Temporal with expires_at
      Layer 7 — entity_permissions
        Dashboard + view specific
        Grantee type polymorphic
      Layer 8 — Default DENY
        No match = no access

    ))Data Protection((
      Credentials vault
        AES-256-GCM encryption
        Key rotation with history
        Never stored in SQL
        UUID pointer only
      Connection security
        SSL/TLS certificates
        SSH tunneling
        VPN / private link
        IP allowlisting
      Audit trail
        Every action logged
        Before/after snapshots
        Actor identification
        TTL-based retention

    ))Tenant Isolation((
      organization_id on every query
        Enforced at application layer
        NestJS guards + Mongoose middleware
        All compound indexes start with org_id
      No cross-tenant data leakage
        Even admin roles scoped to org
        Global roles = platform super-admin only
```

---

## 6 — Monetization Strategy Mindmap

```mermaid
mindmap
  root(("💰 Monetization<br/>Strategy"))
    ))Pricing Tiers((
      Free
        Up to 3 members
        1 project, 1 workspace
        1,000 records
        Community support
      Starter — $19/mo
        10 members
        5 projects
        10,000 records
        5 adapters
        Email support
      Pro — $49/mo
        50 members
        Unlimited projects
        100,000 records
        Unlimited adapters
        CDC real-time sync
        Custom branding
        Priority support
      Enterprise — custom
        Unlimited everything
        Managed DB provisioning
        SSO + SAML
        Dedicated infrastructure
        SLA guarantee
        Dedicated CSM

    ))Revenue Streams((
      Subscription revenue
        Monthly or annual billing
        Annual = 2 months free
      Usage-based overages
        Storage beyond limit
        API requests beyond quota
        Record count beyond tier
      Managed DB fees
        Supabase/Atlas hosting markup
        Tiered: free → enterprise
      Marketplace — future
        Dashboard templates
        Adapter plugins
        Custom widgets

    ))Growth Levers((
      Viral — resource sharing
        Public links
        Embed in other apps
        Password-protected shares
      Product-led growth
        Free tier with generous limits
        Self-serve upgrade
        In-app upgrade prompts
      Promotions
        Launch codes
        Partner discounts
        Trial extensions
      Retention
        Data gravity — hard to leave
        Workflow automations
        Team collaboration
        Historical audit trail
```

---

## 7 — Technology Stack Mindmap

```mermaid
mindmap
  root(("⚡ Technology<br/>Stack"))
    ))Backend((
      NestJS v11
        TypeScript ~5.7
        Module-based architecture
        Guards for auth
        Interceptors for logging
        WebSocket gateway
      Prisma ^7
        PostgreSQL driver
        Type-safe queries
        Migration management
      Mongoose
        MongoDB ODM
        @nestjs/mongoose decorators
        Schema + SchemaFactory
      PostgreSQL
        uuid-ossp extension
        pgcrypto extension
        5NF normalized
        55+ tables
      MongoDB
        10 collections
        TTL indexes
        Wildcard text search
        Change streams for CDC

    ))Frontend((
      Vite
        Fast HMR
        TypeScript
      Component library
        Dashboard grid system
        Widget renderer
        View type renderers
        Form builder
      State management
        Real-time via WebSocket
        Optimistic updates
        Cache invalidation

    ))Infrastructure((
      Docker
        Separate Dockerfiles
        Backend + frontend
        docker-compose for orchestration
      Nginx
        Reverse proxy
        Static file serving
        WebSocket upgrade
      External services
        Stripe — payments
        Supabase — managed PostgreSQL
        MongoDB Atlas — managed MongoDB
        S3/GCS/Azure — file storage

    ))Shared Package((
      packages/shared
        TypeScript types
        Validation schemas
        Constants
        Utility functions
```

---

## 8 — Feature Prioritization Mindmap (Build Order)

```mermaid
mindmap
  root(("📅 Build Order<br/>What to Ship When"))
    ))Phase 1 — Foundation((
      Users + Auth
        Registration, login, OAuth
        Sessions + JWT
      Organizations
        Create org, invite members
        Projects + workspaces
      Basic RBAC
        Roles: admin, member, viewer
        Role assignment

    ))Phase 2 — Data Engine((
      Collections + Fields
        Create tables, define columns
        28 field types
        Validation rules
      Records (MongoDB)
        CRUD operations
        Schema validation
        Basic filtering + sorting
      Views
        Table view first
        Column visibility + ordering

    ))Phase 3 — Visualization((
      Dashboards
        Widget grid system
        Chart, metric, table widgets
      Dashboard Layouts
        Scope system — shared/personal
        Responsive breakpoints
      Additional views
        Kanban, calendar, gallery
        Chart views

    ))Phase 4 — Collaboration((
      Resource registry
        Unified permissions
        Versioning
      Sharing
        Public links
        Email invites
        Embed mode
      Comments + tags
      Notifications
      Webhooks

    ))Phase 5 — Integration((
      Adapters
        REST API connector
        CSV/Excel import
        Google Sheets sync
      Adapter mappings + scheduling
      Execution logging

    ))Phase 6 — Connectivity((
      Database connections
        Public endpoint
        SSH tunnel
      CDC sync channels
        PostgreSQL logical replication
        MongoDB change streams
      Conflict resolution
      Sync state + credentials vault

    ))Phase 7 — Enterprise((
      ABAC conditions
        Attribute-based guards
        Policy rules
      Managed provisioning
        Supabase integration
        MongoDB Atlas integration
      Billing
        Plans + features
        Subscriptions
        Invoices + payments
      Promotions
      Usage metering

    ))Phase 8 — Polish((
      Workflow engine
        Trigger automation
        Multi-step pipelines
      Advanced security
        MFA enforcement
        IP allowlisting
        SSO — future
      Global settings
        Custom branding
        Data retention policies
      Query cache optimization
      Full audit trail
```
