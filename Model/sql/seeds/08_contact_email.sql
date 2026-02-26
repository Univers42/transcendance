-- ============================================================================
-- seeds/08_contact_email.sql — Email Templates & Sample Contact Submissions
-- ============================================================================
-- Populates:
--   1. System-wide email templates (10 templates, subject §6.9)
--   2. Organization-level template override (1 example)
--   3. Sample contact submissions (3 entries, subject §6.10)
--
-- Depends on:
--   • schema.contact.sql (contact_submissions, email_templates tables)
--   • 05_users.sql       (demo users for assigned_to / updated_by)
--   • 06_demo_org.sql    (demo organization for org-level template)
--
-- UUID SCHEME:
--   Email templates:        e1000000-0000-0000-0000-0000000000XX
--   Contact submissions:    c5000000-0000-0000-0000-0000000000XX
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- 1. SYSTEM EMAIL TEMPLATES (global — no organization_id)
-- ─────────────────────────────────────────────────────────────────────────────
-- These are the platform-wide default templates. Organizations can override
-- by creating a template with the same slug under their org.

INSERT INTO email_templates (id, organization_id, slug, name, description, subject_template, body_html, body_text, available_variables, category)
VALUES
    -- ── Auth templates ──────────────────────────────────────────────────────
    (
        'e1000000-0000-0000-0000-000000000001',
        NULL,
        'welcome_email',
        'Welcome Email',
        'Sent to new users upon registration.',
        'Welcome to {{platform_name}}, {{user.display_name}}!',
        '<h1>Welcome, {{user.display_name}}!</h1><p>Your account has been created on <strong>{{platform_name}}</strong>. Get started by exploring your dashboard.</p><p><a href="{{dashboard_url}}">Go to Dashboard</a></p>',
        'Welcome, {{user.display_name}}! Your account has been created on {{platform_name}}. Get started at {{dashboard_url}}',
        ARRAY['user.display_name', 'user.email', 'platform_name', 'dashboard_url'],
        'auth'
    ),
    (
        'e1000000-0000-0000-0000-000000000002',
        NULL,
        'password_reset',
        'Password Reset',
        'Sent when a user requests a password reset.',
        'Reset your password — {{platform_name}}',
        '<h1>Password Reset</h1><p>Hi {{user.display_name}},</p><p>Click the link below to reset your password. This link expires in {{expiry_minutes}} minutes.</p><p><a href="{{reset_link}}">Reset Password</a></p><p>If you didn''t request this, you can safely ignore this email.</p>',
        'Hi {{user.display_name}}, reset your password here: {{reset_link}} (expires in {{expiry_minutes}} minutes). If you didn''t request this, ignore this email.',
        ARRAY['user.display_name', 'user.email', 'platform_name', 'reset_link', 'expiry_minutes'],
        'auth'
    ),
    (
        'e1000000-0000-0000-0000-000000000003',
        NULL,
        'email_verification',
        'Email Verification',
        'Sent to verify a user''s email address.',
        'Verify your email — {{platform_name}}',
        '<h1>Verify Your Email</h1><p>Hi {{user.display_name}},</p><p>Please verify your email address by clicking the link below:</p><p><a href="{{verification_link}}">Verify Email</a></p>',
        'Hi {{user.display_name}}, verify your email: {{verification_link}}',
        ARRAY['user.display_name', 'user.email', 'platform_name', 'verification_link'],
        'auth'
    ),

    -- ── Notification templates ──────────────────────────────────────────────
    (
        'e1000000-0000-0000-0000-000000000004',
        NULL,
        'invite_member',
        'Member Invitation',
        'Sent when a user is invited to an organization, project, or workspace.',
        '{{inviter.display_name}} invited you to {{organization.name}}',
        '<h1>You''re Invited!</h1><p>{{inviter.display_name}} has invited you to join <strong>{{organization.name}}</strong> on {{platform_name}}.</p><p><a href="{{invite_link}}">Accept Invitation</a></p><p>This invitation expires in {{expiry_days}} days.</p>',
        '{{inviter.display_name}} invited you to {{organization.name}} on {{platform_name}}. Accept: {{invite_link}} (expires in {{expiry_days}} days)',
        ARRAY['user.display_name', 'inviter.display_name', 'organization.name', 'platform_name', 'invite_link', 'expiry_days'],
        'notification'
    ),
    (
        'e1000000-0000-0000-0000-000000000005',
        NULL,
        'adapter_error_notification',
        'Adapter Error Notification',
        'Sent when an adapter sync fails or encounters an error.',
        '[Alert] Adapter "{{adapter.name}}" failed — {{organization.name}}',
        '<h1>Adapter Error</h1><p>The adapter <strong>{{adapter.name}}</strong> in organization <strong>{{organization.name}}</strong> encountered an error:</p><pre>{{error.message}}</pre><p>Last successful sync: {{adapter.last_success}}</p><p><a href="{{adapter_url}}">View Adapter Settings</a></p>',
        'Adapter "{{adapter.name}}" in {{organization.name}} failed: {{error.message}}. Last success: {{adapter.last_success}}. View: {{adapter_url}}',
        ARRAY['adapter.name', 'adapter.last_success', 'organization.name', 'error.message', 'adapter_url'],
        'notification'
    ),
    (
        'e1000000-0000-0000-0000-000000000006',
        NULL,
        'account_deactivated',
        'Account Deactivated',
        'Sent when an admin deactivates a user account.',
        'Your account has been deactivated — {{platform_name}}',
        '<h1>Account Deactivated</h1><p>Hi {{user.display_name}},</p><p>Your account on <strong>{{platform_name}}</strong> has been deactivated by an administrator.</p><p>If you believe this is an error, please contact support at <a href="mailto:{{support_email}}">{{support_email}}</a>.</p>',
        'Hi {{user.display_name}}, your account on {{platform_name}} has been deactivated. Contact support: {{support_email}}',
        ARRAY['user.display_name', 'platform_name', 'support_email'],
        'notification'
    ),

    -- ── Billing templates ───────────────────────────────────────────────────
    (
        'e1000000-0000-0000-0000-000000000007',
        NULL,
        'subscription_renewal',
        'Subscription Renewal Reminder',
        'Sent before a subscription renews automatically.',
        'Your {{plan.name}} subscription renews soon — {{platform_name}}',
        '<h1>Subscription Renewal</h1><p>Hi {{user.display_name}},</p><p>Your <strong>{{plan.name}}</strong> subscription for <strong>{{organization.name}}</strong> will renew on <strong>{{renewal_date}}</strong> for <strong>{{renewal_amount}}</strong>.</p><p><a href="{{billing_url}}">Manage Subscription</a></p>',
        'Hi {{user.display_name}}, your {{plan.name}} subscription for {{organization.name}} renews on {{renewal_date}} for {{renewal_amount}}. Manage: {{billing_url}}',
        ARRAY['user.display_name', 'plan.name', 'organization.name', 'renewal_date', 'renewal_amount', 'billing_url'],
        'billing'
    ),
    (
        'e1000000-0000-0000-0000-000000000008',
        NULL,
        'invoice_generated',
        'Invoice Generated',
        'Sent when a new invoice is ready for download.',
        'New invoice for {{organization.name}} — {{platform_name}}',
        '<h1>Invoice Ready</h1><p>Hi {{user.display_name}},</p><p>A new invoice (<strong>{{invoice.number}}</strong>) for <strong>{{organization.name}}</strong> is ready.</p><p>Amount: <strong>{{invoice.amount}}</strong></p><p><a href="{{invoice_url}}">Download Invoice</a></p>',
        'Hi {{user.display_name}}, invoice {{invoice.number}} for {{organization.name}} is ready ({{invoice.amount}}). Download: {{invoice_url}}',
        ARRAY['user.display_name', 'organization.name', 'invoice.number', 'invoice.amount', 'invoice_url'],
        'billing'
    ),

    -- ── System templates ────────────────────────────────────────────────────
    (
        'e1000000-0000-0000-0000-000000000009',
        NULL,
        'data_export_ready',
        'Data Export Ready',
        'Sent when a GDPR data export has been generated and is ready for download.',
        'Your data export is ready — {{platform_name}}',
        '<h1>Data Export Ready</h1><p>Hi {{user.display_name}},</p><p>Your requested data export is ready for download. The download link expires in {{expiry_hours}} hours.</p><p><a href="{{export_url}}">Download Export</a></p>',
        'Hi {{user.display_name}}, your data export is ready: {{export_url}} (expires in {{expiry_hours}} hours)',
        ARRAY['user.display_name', 'platform_name', 'export_url', 'expiry_hours'],
        'system'
    ),
    (
        'e1000000-0000-0000-0000-000000000010',
        NULL,
        'contact_form_confirmation',
        'Contact Form Confirmation',
        'Auto-reply sent to visitors who submit the public contact form.',
        'We received your message — {{platform_name}}',
        '<h1>Thank You!</h1><p>Hi {{sender_name}},</p><p>We received your message regarding "<strong>{{subject}}</strong>" and will get back to you within 48 hours.</p><p>If this is urgent, please reply to this email.</p><p>— The {{platform_name}} Team</p>',
        'Hi {{sender_name}}, we received your message regarding "{{subject}}" and will get back to you within 48 hours.',
        ARRAY['sender_name', 'sender_email', 'subject', 'platform_name'],
        'system'
    )
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- 2. ORG-LEVEL TEMPLATE OVERRIDE (example for DataVault Corp)
-- ─────────────────────────────────────────────────────────────────────────────
-- Demonstrates how an organization can customize the welcome email.
-- At template lookup time, the app checks:
--   1. email_templates WHERE slug='welcome_email' AND organization_id = $org_id
--   2. Falls back to: email_templates WHERE slug='welcome_email' AND organization_id IS NULL

INSERT INTO email_templates (id, organization_id, slug, name, description, subject_template, body_html, body_text, available_variables, category, updated_by)
VALUES (
    'e1000000-0000-0000-0000-000000000011',
    'd0000000-0000-0000-0000-000000000001', -- Acme Corp
    'welcome_email',
    'Welcome Email (Acme Custom)',
    'Custom welcome for Acme Corp members.',
    'Welcome to Acme, {{user.display_name}}! 🚀',
    '<div style="background:#1a1a2e;color:#e0e0e0;padding:40px;font-family:sans-serif;"><h1 style="color:#00d9ff;">Welcome to Acme!</h1><p>Hi {{user.display_name}},</p><p>Your Acme account is ready. Start by creating your first workspace and connecting your data sources.</p><p><a href="{{dashboard_url}}" style="background:#00d9ff;color:#1a1a2e;padding:12px 24px;border-radius:6px;text-decoration:none;">Enter Acme</a></p></div>',
    'Welcome to Acme, {{user.display_name}}! Start at {{dashboard_url}}',
    ARRAY['user.display_name', 'user.email', 'platform_name', 'dashboard_url'],
    'auth',
    'b0000000-0000-0000-0000-000000000001' -- Alice Smith (employee admin)
)
ON CONFLICT DO NOTHING;


-- ─────────────────────────────────────────────────────────────────────────────
-- 3. SAMPLE CONTACT SUBMISSIONS
-- ─────────────────────────────────────────────────────────────────────────────

INSERT INTO contact_submissions (id, sender_email, sender_name, subject, message, submitted_ip, user_agent, status)
VALUES
    (
        'c5000000-0000-0000-0000-000000000001',
        'curious@example.com',
        'Curious Visitor',
        'Pricing for enterprise plan',
        'Hi, I''m interested in your enterprise plan. Can you share pricing details and whether you offer custom integrations?',
        '203.0.113.10',
        'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)',
        'new'
    ),
    (
        'c5000000-0000-0000-0000-000000000002',
        'dev@techstartup.io',
        'Jordan Lee',
        'API rate limits question',
        'We''re evaluating your API for our startup. What are the rate limits on the free tier? Also, is there a sandbox environment for testing?',
        '198.51.100.42',
        'Mozilla/5.0 (X11; Linux x86_64)',
        'in_progress'
    ),
    (
        'c5000000-0000-0000-0000-000000000003',
        'spam@bot.fake',
        'Buy Cheap Watches',
        'Amazing Deal!!!',
        'Buy watches at www.definitely-not-spam.example',
        '192.0.2.99',
        'SpamBot/1.0',
        'spam'
    )
ON CONFLICT DO NOTHING;
