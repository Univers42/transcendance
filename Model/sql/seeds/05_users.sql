-- ============================================================================
-- seeds/05_users.sql — Demo Users (admin, employees, tenants / clients)
-- ============================================================================
-- Platform demo users for development and testing. Each user has a mock
-- password hash (bcrypt placeholder — not a real secret).
--
-- User types:
--   • Platform admins — global_admin / global_support roles
--   • Employees       — internal team members (org_admin, project_admin)
--   • Tenants/Clients — external customers using the platform
--
-- All passwords are: "Password123!" (mock hash — never used in production)
-- ============================================================================

-- ── Platform Admin ──────────────────────────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('a0000000-0000-0000-0000-000000000001',
     'admin@transcendence.dev',
     'admin',
     'Platform Admin',
     'https://avatars.example.com/u/admin.png',
     '$2b$10$mockHashAdmin000000000000000000000000000000000000000',
     TRUE, TRUE, 'online')
ON CONFLICT (email) DO NOTHING;

-- ── Platform Support ────────────────────────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('a0000000-0000-0000-0000-000000000002',
     'support@transcendence.dev',
     'support',
     'Support Agent',
     'https://avatars.example.com/u/support.png',
     '$2b$10$mockHashSupport0000000000000000000000000000000000000',
     TRUE, FALSE, 'online')
ON CONFLICT (email) DO NOTHING;

-- ── Employee: Engineering Lead ──────────────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('b0000000-0000-0000-0000-000000000001',
     'alice.smith@transcendence.dev',
     'alice_smith',
     'Alice Smith',
     'https://avatars.example.com/u/alice.png',
     '$2b$10$mockHashAlice000000000000000000000000000000000000000',
     TRUE, TRUE, 'online')
ON CONFLICT (email) DO NOTHING;

-- ── Employee: Product Manager ───────────────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('b0000000-0000-0000-0000-000000000002',
     'bob.johnson@transcendence.dev',
     'bob_johnson',
     'Bob Johnson',
     'https://avatars.example.com/u/bob.png',
     '$2b$10$mockHashBob0000000000000000000000000000000000000000',
     TRUE, FALSE, 'away')
ON CONFLICT (email) DO NOTHING;

-- ── Employee: Designer ──────────────────────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('b0000000-0000-0000-0000-000000000003',
     'charlie.williams@transcendence.dev',
     'charlie_williams',
     'Charlie Williams',
     'https://avatars.example.com/u/charlie.png',
     '$2b$10$mockHashCharlie00000000000000000000000000000000000000',
     TRUE, FALSE, 'online')
ON CONFLICT (email) DO NOTHING;

-- ── Employee: DevOps ────────────────────────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('b0000000-0000-0000-0000-000000000004',
     'diana.brown@transcendence.dev',
     'diana_brown',
     'Diana Brown',
     'https://avatars.example.com/u/diana.png',
     '$2b$10$mockHashDiana000000000000000000000000000000000000000',
     TRUE, TRUE, 'busy')
ON CONFLICT (email) DO NOTHING;

-- ── Tenant/Client: Startup CEO ──────────────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('c0000000-0000-0000-0000-000000000001',
     'eve.garcia@acme-corp.com',
     'eve_garcia',
     'Eve Garcia',
     'https://avatars.example.com/u/eve.png',
     '$2b$10$mockHashEve0000000000000000000000000000000000000000',
     TRUE, FALSE, 'online')
ON CONFLICT (email) DO NOTHING;

-- ── Tenant/Client: Startup Developer ────────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('c0000000-0000-0000-0000-000000000002',
     'frank.miller@acme-corp.com',
     'frank_miller',
     'Frank Miller',
     'https://avatars.example.com/u/frank.png',
     '$2b$10$mockHashFrank000000000000000000000000000000000000000',
     TRUE, FALSE, 'offline')
ON CONFLICT (email) DO NOTHING;

-- ── Tenant/Client: Enterprise Admin ─────────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('c0000000-0000-0000-0000-000000000003',
     'grace.davis@globex-inc.com',
     'grace_davis',
     'Grace Davis',
     'https://avatars.example.com/u/grace.png',
     '$2b$10$mockHashGrace000000000000000000000000000000000000000',
     TRUE, TRUE, 'online')
ON CONFLICT (email) DO NOTHING;

-- ── Tenant/Client: Enterprise Analyst ───────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('c0000000-0000-0000-0000-000000000004',
     'hank.martinez@globex-inc.com',
     'hank_martinez',
     'Hank Martinez',
     'https://avatars.example.com/u/hank.png',
     '$2b$10$mockHashHank0000000000000000000000000000000000000000',
     TRUE, FALSE, 'online')
ON CONFLICT (email) DO NOTHING;

-- ── Tenant/Client: Freelancer ───────────────────────────────────────────────
INSERT INTO users (id, email, username, display_name, avatar_url, password_hash, is_active, mfa_enabled, status) VALUES
    ('c0000000-0000-0000-0000-000000000005',
     'iris.lee@freelance.io',
     'iris_lee',
     'Iris Lee',
     'https://avatars.example.com/u/iris.png',
     '$2b$10$mockHashIris0000000000000000000000000000000000000000',
     TRUE, FALSE, 'away')
ON CONFLICT (email) DO NOTHING;

\echo '✓ Demo users seeded (2 admins + 4 employees + 5 tenants).'
