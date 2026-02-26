-- ============================================================================
-- schema.billing.sql — Plans, Subscriptions, Billing & Promotions
-- ============================================================================
--
-- DOMAIN: Monetization layer for the platform. Manages subscription plans,
-- feature gating, usage metering, invoices, payments, and promotional offers.
--
-- HOW BILLING WORKS:
--   1. Platform defines Plans with tiers (free, starter, pro, enterprise)
--   2. Each plan has Feature Limits (max users, storage, adapters, etc.)
--   3. Organizations subscribe to a plan → creates a Subscription
--   4. Usage is tracked via Usage Meters → Usage Records
--   5. Invoices are generated per billing cycle (monthly/yearly)
--   6. Payments record each transaction against an invoice
--   7. Promotions/Coupons can discount plans for a period
--
-- REPLACES:
--   organizations.plan VARCHAR CHECK → organizations.plan_id FK → plans.id
--   This gives us rich plan metadata, feature limits, and audit trail
--   instead of a simple string.
--
-- EXECUTION ORDER: Run AFTER schema.user.sql and schema.organization.sql
--   (depends on users, organizations).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- PLANS
-- ─────────────────────────────────────────────────────────────────────────────
-- Defines the available subscription tiers. Each plan has a slug, display
-- name, pricing, and billing period.
--
-- RELATIONSHIPS:
--   plans.id ←── plan_features.plan_id          (1:N) Feature limits for this plan
--   plans.id ←── subscriptions.plan_id          (1:N) Orgs subscribed to this plan
--   plans.id ←── promotion_plans.plan_id        (N:M) Promotions applicable to this plan
--
-- JOIN PATHS:
--   Plan → Features:     plans → plan_features
--   Plan → Subscribers:  plans → subscriptions → organizations
--   Plan → Promotions:   plans → promotion_plans → promotions
--
-- NOTES:
--   • slug is unique for API/URL usage (e.g., "pro", "enterprise")
--   • price_monthly/price_yearly in smallest currency unit (cents)
--   • trial_days: number of free trial days for new subscribers (0 = no trial)
--   • is_public: FALSE for custom enterprise deals negotiated privately
--   • sort_order: display order on the pricing page
--   • metadata: extra config (e.g., custom SLA terms, support level)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE plans (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    slug            VARCHAR(50)     NOT NULL UNIQUE,
    name            VARCHAR(100)    NOT NULL,
    description     TEXT,
    price_monthly   INT             NOT NULL DEFAULT 0,         -- cents
    price_yearly    INT             NOT NULL DEFAULT 0,         -- cents
    currency        VARCHAR(3)      NOT NULL DEFAULT 'USD',
    trial_days      INT             NOT NULL DEFAULT 0,
    is_public       BOOLEAN         NOT NULL DEFAULT TRUE,
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    sort_order      INT             NOT NULL DEFAULT 0,
    metadata        JSONB           NOT NULL DEFAULT '{}',
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE plans IS 'Subscription tiers defining pricing and billing terms.';

-- ─────────────────────────────────────────────────────────────────────────────
-- PLAN FEATURES (feature limits / quotas per plan)
-- ─────────────────────────────────────────────────────────────────────────────
-- Decomposed feature flags and limits. Each row represents one quota or
-- feature toggle for a given plan.
--
-- RELATIONSHIPS:
--   plan_features.plan_id ──→ plans.id (N:1) The plan this limit belongs to
--
-- JOIN PATHS:
--   Plan → Features:  plans → plan_features
--   Feature check:    plan_features WHERE plan_id = $plan_id AND feature_key = 'max_users'
--
-- FEATURE KEYS (examples):
--   max_members           Max org members (NULL = unlimited)
--   max_projects          Max projects per org
--   max_workspaces        Max workspaces per project
--   max_collections       Max collections per workspace
--   max_records           Max records across all collections
--   max_adapters          Max active adapters
--   max_database_connections  Max external DB connections
--   max_provisioned_databases Max managed DB instances
--   max_storage_mb        Max file storage in MB
--   max_api_requests_day  Max API requests per day
--   dashboard_export      Boolean (1=yes, 0=no)
--   custom_branding       Boolean (1=yes, 0=no)
--   sso_enabled           Boolean (1=yes, 0=no)
--   audit_log_days        Number of days audit logs are retained
--   priority_support      Boolean (1=yes, 0=no)
--   realtime_sync         Boolean — can use CDC/realtime adapters
--   webhook_count         Max active webhooks
--   workflow_count        Max active workflow definitions
--
-- NOTES:
--   • feature_key + plan_id is unique (one limit per feature per plan)
--   • limit_value is INT: for booleans use 0/1, for quotas use the number
--   • NULL limit_value means unlimited / unrestricted
--   • 5NF: each row is one independent fact (plan × feature → limit)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE plan_features (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    plan_id         UUID            NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    feature_key     VARCHAR(100)    NOT NULL,
    limit_value     INT,                                        -- NULL = unlimited
    description     TEXT,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (plan_id, feature_key)
);

COMMENT ON TABLE plan_features IS 'Feature flags and quota limits per plan. One row per (plan, feature).';

-- ─────────────────────────────────────────────────────────────────────────────
-- PROMOTIONS (coupons, discounts, offers)
-- ─────────────────────────────────────────────────────────────────────────────
-- NOTE: Created BEFORE subscriptions because subscriptions.promotion_id
-- references this table.
--
-- Defines promotional offers that can be applied to subscriptions.
--
-- RELATIONSHIPS:
--   promotions.id ←── subscriptions.promotion_id    (1:N) Subscriptions using this promo
--   promotions.id ←── promotion_plans.promotion_id  (1:N) Plans this promo applies to
--   promotions.created_by ──→ users.id              (N:1) Admin who created the promo
--
-- JOIN PATHS:
--   Promo → Plans:           promotions → promotion_plans → plans
--   Promo → Subscriptions:   promotions → subscriptions → organizations
--   Active promos:           promotions WHERE is_active AND now() BETWEEN starts_at AND ends_at
--
-- DISCOUNT TYPES:
--   'percentage' → discount_value = 20 means 20% off
--   'fixed'      → discount_value = 1000 means $10.00 off (in cents)
--   'trial_extension' → discount_value = 14 means +14 extra trial days
--
-- NOTES:
--   • code: unique alphanumeric promo code (e.g., "LAUNCH2025")
--   • max_redemptions: NULL = unlimited
--   • current_redemptions: incremented when a subscription applies this promo
--   • duration_months: how many billing cycles the discount applies (NULL = forever)
--   • starts_at/ends_at: validity window (ends_at NULL = no expiry)
--   • stackable: whether multiple promos can be combined (future use)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE promotions (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    code                    VARCHAR(50)     NOT NULL UNIQUE,
    name                    VARCHAR(255)    NOT NULL,
    description             TEXT,
    discount_type           VARCHAR(20)     NOT NULL
                            CHECK (discount_type IN ('percentage','fixed','trial_extension')),
    discount_value          INT             NOT NULL,           -- percent, cents, or days
    duration_months         INT,                                -- NULL = forever
    max_redemptions         INT,                                -- NULL = unlimited
    current_redemptions     INT             NOT NULL DEFAULT 0,
    starts_at               TIMESTAMPTZ     NOT NULL DEFAULT now(),
    ends_at                 TIMESTAMPTZ,
    is_active               BOOLEAN         NOT NULL DEFAULT TRUE,
    stackable               BOOLEAN         NOT NULL DEFAULT FALSE,
    metadata                JSONB           NOT NULL DEFAULT '{}',
    created_by              UUID            NOT NULL REFERENCES users(id),
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE promotions IS 'Promotional offers, coupons, and discount codes.';

-- ─────────────────────────────────────────────────────────────────────────────
-- SUBSCRIPTIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Links an organization to a plan with billing period tracking.
-- An org has exactly ONE active subscription at a time.
--
-- RELATIONSHIPS:
--   subscriptions.organization_id ──→ organizations.id  (N:1) The subscribing org
--   subscriptions.plan_id         ──→ plans.id          (N:1) The subscribed plan
--   subscriptions.promotion_id    ──→ promotions.id     (N:1) Optional applied promo
--   subscriptions.id              ←── invoices.subscription_id (1:N) Generated invoices
--
-- JOIN PATHS:
--   Org → Subscription:  organizations → subscriptions → plans
--   Org → Features:      organizations → subscriptions → plans → plan_features
--   Org → Invoices:      organizations → subscriptions → invoices → payments
--   Promo usage:         promotions → subscriptions (WHERE promotion_id IS NOT NULL)
--
-- STATUS LIFECYCLE:
--   trialing → active → past_due → cancelled → expired
--                     → paused → active (re-activated)
--
-- NOTES:
--   • billing_period: 'monthly' or 'yearly'
--   • cancel_at_period_end: TRUE means the org will downgrade at period end
--   • external_subscription_id: maps to Stripe/Paddle/etc. subscription ID
--   • trial_ends_at: set when trialing, NULL otherwise
--   • Only ONE active subscription per org (ensured at application layer)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE subscriptions (
    id                      UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id         UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    plan_id                 UUID            NOT NULL REFERENCES plans(id) ON DELETE RESTRICT,
    promotion_id            UUID            REFERENCES promotions(id) ON DELETE SET NULL,
    status                  VARCHAR(20)     NOT NULL DEFAULT 'trialing'
                            CHECK (status IN (
                                'trialing','active','past_due','paused','cancelled','expired'
                            )),
    billing_period          VARCHAR(10)     NOT NULL DEFAULT 'monthly'
                            CHECK (billing_period IN ('monthly','yearly')),
    current_period_start    TIMESTAMPTZ     NOT NULL DEFAULT now(),
    current_period_end      TIMESTAMPTZ     NOT NULL,
    trial_ends_at           TIMESTAMPTZ,
    cancel_at_period_end    BOOLEAN         NOT NULL DEFAULT FALSE,
    cancelled_at            TIMESTAMPTZ,
    external_subscription_id VARCHAR(255),                      -- Stripe/Paddle ID
    external_customer_id    VARCHAR(255),                        -- Stripe Customer ID
    metadata                JSONB           NOT NULL DEFAULT '{}',
    created_at              TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at              TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE subscriptions IS 'Active subscription linking an organization to a billing plan.';

-- ─────────────────────────────────────────────────────────────────────────────
-- PROMOTION_PLANS (M:N — which promotions apply to which plans)
-- ─────────────────────────────────────────────────────────────────────────────
-- Controls which plans a promotion can be used with.
-- An empty set means the promotion applies to ALL plans.
--
-- RELATIONSHIPS:
--   promotion_plans.promotion_id ──→ promotions.id (N:1)
--   promotion_plans.plan_id      ──→ plans.id      (N:1)
--
-- NOTES:
--   • Pure junction table — no extra attributes (5NF-compliant)
--   • If a promo has NO rows here, it applies to every plan
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE promotion_plans (
    promotion_id    UUID    NOT NULL REFERENCES promotions(id) ON DELETE CASCADE,
    plan_id         UUID    NOT NULL REFERENCES plans(id) ON DELETE CASCADE,
    PRIMARY KEY (promotion_id, plan_id)
);

COMMENT ON TABLE promotion_plans IS 'Junction: which promotions apply to which plans.';

-- ─────────────────────────────────────────────────────────────────────────────
-- INVOICES
-- ─────────────────────────────────────────────────────────────────────────────
-- Generated for each billing cycle. Tracks amounts, discounts, and status.
--
-- RELATIONSHIPS:
--   invoices.subscription_id  ──→ subscriptions.id  (N:1) The subscription billed
--   invoices.organization_id  ──→ organizations.id  (N:1) The org being billed
--   invoices.id               ←── payments.invoice_id (1:N) Payments against this invoice
--
-- JOIN PATHS:
--   Org → Invoices:     organizations → invoices
--   Sub → Invoices:     subscriptions → invoices → payments
--   Unpaid invoices:    invoices WHERE status IN ('pending','past_due')
--   Invoice total:      invoices.subtotal_amount - discount_amount + tax_amount = total_amount
--
-- STATUS LIFECYCLE:
--   draft → pending → paid → void
--                   → past_due → paid|void
--                   → refunded (partial or full)
--
-- NOTES:
--   • invoice_number is human-readable (INV-2025-0001), unique per org
--   • All amounts in smallest currency unit (cents)
--   • period_start/period_end define the billing window
--   • external_invoice_id: maps to Stripe Invoice / Paddle Transaction
--   • line_items JSONB: detailed breakdown (plan fee, overages, credits)
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE invoices (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    subscription_id     UUID            NOT NULL REFERENCES subscriptions(id) ON DELETE CASCADE,
    organization_id     UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    invoice_number      VARCHAR(50)     NOT NULL,
    status              VARCHAR(20)     NOT NULL DEFAULT 'draft'
                        CHECK (status IN ('draft','pending','paid','past_due','void','refunded', 'rejected')),
    subtotal_amount     INT             NOT NULL DEFAULT 0,     -- cents
    discount_amount     INT             NOT NULL DEFAULT 0,     -- cents
    tax_amount          INT             NOT NULL DEFAULT 0,     -- cents
    total_amount        INT             NOT NULL DEFAULT 0,     -- cents
    currency            VARCHAR(3)      NOT NULL DEFAULT 'USD',
    period_start        TIMESTAMPTZ     NOT NULL,
    period_end          TIMESTAMPTZ     NOT NULL,
    due_date            TIMESTAMPTZ     NOT NULL,
    paid_at             TIMESTAMPTZ,
    external_invoice_id VARCHAR(255),                           -- Stripe Invoice ID
    line_items          JSONB           NOT NULL DEFAULT '[]',
    notes               TEXT,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (organization_id, invoice_number)
);

COMMENT ON TABLE invoices IS 'Billing invoices generated per subscription cycle.';

-- ─────────────────────────────────────────────────────────────────────────────
-- PAYMENTS
-- ─────────────────────────────────────────────────────────────────────────────
-- Records individual payment transactions against invoices.
--
-- RELATIONSHIPS:
--   payments.invoice_id      ──→ invoices.id        (N:1) The invoice being paid
--   payments.organization_id ──→ organizations.id   (N:1) The paying org
--
-- JOIN PATHS:
--   Invoice → Payments:  invoices → payments
--   Org → Payments:      organizations → payments (ORDER BY created_at DESC)
--   Failed payments:     payments WHERE status = 'failed'
--
-- NOTES:
--   • payment_method: 'card', 'bank_transfer', 'paypal', 'crypto', 'wire'
--   • gateway: 'stripe', 'paddle', 'manual' — the payment processor used
--   • external_payment_id: processor-specific transaction ID
--   • refund_amount: partial or full refunds (0 = no refund)
--   • failure_reason: set when status = 'failed' (e.g., "card_declined")
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE payments (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    invoice_id          UUID            NOT NULL REFERENCES invoices(id) ON DELETE CASCADE,
    organization_id     UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    amount              INT             NOT NULL,               -- cents
    currency            VARCHAR(3)      NOT NULL DEFAULT 'USD',
    status              VARCHAR(20)     NOT NULL DEFAULT 'pending'
                        CHECK (status IN ('pending','processing','succeeded','failed','refunded')),
    payment_method      VARCHAR(30)     NOT NULL
                        CHECK (payment_method IN (
                            'card','bank_transfer','paypal','crypto','wire','credits'
                        )),
    gateway             VARCHAR(30)     NOT NULL DEFAULT 'stripe'
                        CHECK (gateway IN ('stripe','paddle','manual')),
    external_payment_id VARCHAR(255),                           -- Stripe PaymentIntent ID
    refund_amount       INT             NOT NULL DEFAULT 0,     -- cents
    failure_reason      TEXT,
    metadata            JSONB           NOT NULL DEFAULT '{}',
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE payments IS 'Payment transactions against invoices.';

-- ─────────────────────────────────────────────────────────────────────────────
-- USAGE METERS (what we track)
-- ─────────────────────────────────────────────────────────────────────────────
-- Defines the dimensions of usage that are metered for billing or quota
-- enforcement. Each meter has a unit and an aggregation method.
--
-- RELATIONSHIPS:
--   usage_meters.id ←── usage_records.meter_id (1:N) Actual usage data points
--
-- JOIN PATHS:
--   Meter → Usage:  usage_meters → usage_records
--   Org usage:      usage_records WHERE organization_id = $org_id AND meter_id = $meter_id
--
-- METER EXAMPLES:
--   'storage_bytes'      — Total storage used (SUM aggregation)
--   'record_count'       — Number of records across collections (GAUGE)
--   'api_requests'       — API calls per period (SUM)
--   'adapter_syncs'      — Number of adapter sync executions (SUM)
--   'active_members'     — Current org member count (GAUGE)
--   'bandwidth_bytes'    — Data transfer (SUM)
--
-- AGGREGATION TYPES:
--   'sum'     — Cumulative total within period (resets each billing cycle)
--   'gauge'   — Point-in-time measurement (latest value wins)
--   'maximum' — Highest value in the period
--
-- NOTES:
--   • Meters are platform-defined (not per-org)
--   • reset_period: 'billing_cycle', 'daily', 'hourly', 'never'
--   • Overage charges defined via plan_features + meter linkage
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE usage_meters (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    slug            VARCHAR(100)    NOT NULL UNIQUE,
    name            VARCHAR(255)    NOT NULL,
    description     TEXT,
    unit            VARCHAR(50)     NOT NULL,                   -- 'bytes','count','requests'
    aggregation     VARCHAR(20)     NOT NULL DEFAULT 'sum'
                    CHECK (aggregation IN ('sum','gauge','maximum')),
    reset_period    VARCHAR(20)     NOT NULL DEFAULT 'billing_cycle'
                    CHECK (reset_period IN ('billing_cycle','daily','hourly','never')),
    is_active       BOOLEAN         NOT NULL DEFAULT TRUE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE usage_meters IS 'Defines measurable usage dimensions (storage, API calls, etc.).';

-- ─────────────────────────────────────────────────────────────────────────────
-- USAGE RECORDS (actual usage data points)
-- ─────────────────────────────────────────────────────────────────────────────
-- Tracks actual usage per organization per meter. Used for quota enforcement
-- and overage billing.
--
-- RELATIONSHIPS:
--   usage_records.organization_id ──→ organizations.id   (N:1) The org being metered
--   usage_records.meter_id        ──→ usage_meters.id    (N:1) Which metric
--
-- JOIN PATHS:
--   Org → Usage:     organizations → usage_records → usage_meters
--   Current usage:   usage_records WHERE organization_id = $org_id
--                    AND recorded_at BETWEEN $period_start AND $period_end
--   Quota check:     usage_records (SUM) vs plan_features (limit_value)
--                    WHERE feature_key = usage_meters.slug
--
-- NOTES:
--   • quantity: the measured value (e.g., bytes stored, API calls made)
--   • recorded_at: when the measurement was taken
--   • For 'sum' meters: backend inserts incremental records, billing sums them
--   • For 'gauge' meters: latest recorded_at value is the current usage
--   • High-volume table — consider partitioning by recorded_at in production
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE usage_records (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id UUID            NOT NULL REFERENCES organizations(id) ON DELETE CASCADE,
    meter_id        UUID            NOT NULL REFERENCES usage_meters(id) ON DELETE CASCADE,
    quantity        BIGINT          NOT NULL,
    metadata        JSONB           NOT NULL DEFAULT '{}',
    recorded_at     TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE usage_records IS 'Actual usage data points per org per meter.';

-- Optional: partition usage_records by month for performance at scale
-- CREATE TABLE usage_records PARTITION BY RANGE (recorded_at);
