-- ============================================================================
-- schema.contact.sql — Contact Submissions & Email Templates
-- ============================================================================
--
-- DOMAIN: Public-facing contact form and admin-managed email templates.
--
-- SUBJECT REQUIREMENTS:
--   §6.10 — Contact Page: "Any visitor can submit a contact form"
--     → contact_submissions table stores form data with spam protection
--   §6.9  — Admin Space: "View and manage the platform's email templates
--            (welcome, password reset, adapter error notification)"
--     → email_templates table for admin CRUD on transactional emails
--
-- EXECUTION ORDER: Run AFTER schema.system.sql (depends on organizations, users).
-- ============================================================================


-- ─────────────────────────────────────────────────────────────────────────────
-- CONTACT SUBMISSIONS (public-facing contact form)
-- ─────────────────────────────────────────────────────────────────────────────
-- Stores submissions from the public contact page (Section 6.10).
-- Unauthenticated visitors can submit subject + message + email.
-- Anti-spam protection fields (honeypot + CAPTCHA) are included.
--
-- RELATIONSHIPS:
--   contact_submissions.assigned_to ──→ users.id (N:1) Support person handling this
--
-- JOIN PATHS:
--   All submissions:  contact_submissions ORDER BY created_at DESC
--   Open tickets:     contact_submissions WHERE status IN ('new','in_progress')
--   Assigned to agent: contact_submissions WHERE assigned_to = $agent_id
--
-- ANTI-SPAM:
--   • honeypot_filled: TRUE if the bot-trap field was filled (reject at app layer)
--   • captcha_token: CAPTCHA response token for server-side verification
--   • submitted_ip: rate-limit by IP (5 submissions / 10 minutes per IP)
--
-- NOTES:
--   • No organization_id: these come from the public landing page
--   • On submit, message is forwarded by email to the support team (app layer)
--   • No updated_at: submissions are append-only (status changes are DML)
--     Actually, status changes warrant updated_at — included.
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE contact_submissions (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_email        VARCHAR(255)    NOT NULL,
    sender_name         VARCHAR(255),
    subject             VARCHAR(500)    NOT NULL,
    message             TEXT            NOT NULL,

    -- Anti-spam
    honeypot_filled     BOOLEAN         NOT NULL DEFAULT FALSE,
    captcha_token       TEXT,
    submitted_ip        INET,
    user_agent          TEXT,

    -- Handling
    status              VARCHAR(20)     NOT NULL DEFAULT 'new'
                        CHECK (status IN ('new','in_progress','resolved','spam','archived')),
    assigned_to         UUID            REFERENCES users(id) ON DELETE SET NULL,
    internal_notes      TEXT,

    -- Timestamps
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE contact_submissions IS
    'Public contact form submissions (subject §6.10). Rate-limited and spam-protected at app layer.';

-- Index for status filtering (support queue)
CREATE INDEX idx_contact_sub_status ON contact_submissions (status, created_at DESC);

-- Index for assigned agent
CREATE INDEX idx_contact_sub_assigned ON contact_submissions (assigned_to)
    WHERE assigned_to IS NOT NULL;

-- Index for rate limiting by IP
CREATE INDEX idx_contact_sub_ip ON contact_submissions (submitted_ip, created_at DESC)
    WHERE submitted_ip IS NOT NULL;


-- ─────────────────────────────────────────────────────────────────────────────
-- EMAIL TEMPLATES (admin-managed transactional emails)
-- ─────────────────────────────────────────────────────────────────────────────
-- Stores configurable email templates for all platform transactional emails.
-- Admins can edit subject, body, and variables from the admin panel.
--
-- RELATIONSHIPS:
--   email_templates.organization_id ──→ organizations.id (N:1) Owning org (NULL = global/system)
--   email_templates.updated_by      ──→ users.id         (N:1) Who last modified this template
--
-- JOIN PATHS:
--   Global templates:  email_templates WHERE organization_id IS NULL
--   Org templates:     email_templates WHERE organization_id = $org_id
--   Template lookup:   email_templates WHERE slug = 'welcome_email' AND
--                        (organization_id = $org_id OR organization_id IS NULL)
--                        ORDER BY organization_id NULLS LAST LIMIT 1
--
-- TEMPLATE VARIABLES:
--   Templates use Handlebars-style placeholders: {{user.display_name}},
--   {{organization.name}}, {{reset_link}}, etc.
--   The available_variables column documents what variables each template supports.
--
-- BUILT-IN TEMPLATES (seeded):
--   welcome_email              — sent on user registration
--   password_reset             — sent on forgot-password request
--   email_verification         — verify email address
--   invite_member              — org/project/workspace invitation
--   adapter_error_notification — sent when an adapter fails
--   subscription_renewal       — upcoming subscription renewal
--   invoice_generated          — new invoice available
--   account_deactivated        — account disabled by admin
--   data_export_ready          — GDPR data export is ready for download
--   contact_form_confirmation  — auto-reply to contact form submitter
--
-- NOTES:
--   • (organization_id, slug) is UNIQUE with COALESCE for NULL org
--   • Organization-level templates override global ones (same slug)
--   • body_html and body_text support both rich HTML and plain-text fallback
--   • is_active: disabled templates use the global fallback
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE email_templates (
    id                  UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    organization_id     UUID            REFERENCES organizations(id) ON DELETE CASCADE,
    slug                VARCHAR(100)    NOT NULL,
    name                VARCHAR(255)    NOT NULL,
    description         TEXT,

    -- Email content
    subject_template    TEXT            NOT NULL,               -- "Welcome to {{organization.name}}, {{user.display_name}}!"
    body_html           TEXT            NOT NULL,               -- Rich HTML template
    body_text           TEXT,                                   -- Plain-text fallback
    from_name           VARCHAR(255),                           -- Override sender name
    from_email          VARCHAR(255),                           -- Override sender email
    reply_to            VARCHAR(255),                           -- Reply-to address

    -- Template metadata
    available_variables TEXT[]          NOT NULL DEFAULT '{}',  -- {"user.display_name","organization.name","reset_link",...}
    category            VARCHAR(50)     NOT NULL DEFAULT 'system'
                        CHECK (category IN ('system','auth','billing','notification','marketing','custom')),
    is_active           BOOLEAN         NOT NULL DEFAULT TRUE,

    -- Audit
    updated_by          UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at          TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at          TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE email_templates IS
    'Admin-managed email templates for transactional emails (subject §6.9). Org templates override global.';

-- Global templates: unique per slug when org IS NULL
CREATE UNIQUE INDEX idx_email_templates_global
    ON email_templates (slug)
    WHERE organization_id IS NULL;

-- Org templates: unique per (org, slug)
CREATE UNIQUE INDEX idx_email_templates_org
    ON email_templates (organization_id, slug)
    WHERE organization_id IS NOT NULL;

-- Category filtering
CREATE INDEX idx_email_templates_category
    ON email_templates (category);
