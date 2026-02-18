# Security Policy

---

## Reporting a Vulnerability

Do not open a public GitHub issue for security vulnerabilities.

Report privately by contacting the Tech Lead or Project Manager via Discord DM. Include:

- What the vulnerability is and where it is in the codebase
- Steps to reproduce
- What an attacker could do with it
- A suggested fix if you have one

| Step | Deadline |
|------|----------|
| Acknowledgment | 24 hours |
| Initial assessment | 48 hours |
| Fix — critical severity | 1 week |
| Fix — medium severity | 2 weeks |

---

## Security Model

### Authentication

- JWT access tokens with short expiry and refresh token rotation on each use
- 42 OAuth 2.0 via the [official 42 API](https://api.intra.42.fr/apidoc) — authorization code flow
- bcrypt for password hashing, minimum 12 salt rounds
- Session invalidation on password change and on any detected anomaly

Token lifecycle:

```mermaid
sequenceDiagram
    participant C as Client
    participant API as NestJS API
    participant DB as PostgreSQL

    C->>API: POST /auth/login
    API->>DB: Verify credentials
    DB-->>API: User record
    API-->>C: access_token (15 min) + refresh_token (7 d, httpOnly cookie)

    Note over C,API: access_token expires

    C->>API: POST /auth/refresh  (cookie sent automatically)
    API->>DB: Validate refresh token hash
    DB-->>API: Valid
    API->>DB: Rotate — invalidate old, store new hash
    API-->>C: New access_token + new refresh_token cookie
```

### Authorization

- Route-level guards on every protected endpoint — no endpoint is public by default
- Role-Based Access Control (RBAC) — roles checked at the guard layer, never in the controller
- No authorization logic in DTOs or validators

### Data Protection

- All inputs validated via `class-validator` DTOs — no raw user data reaches the service layer
- Parameterized queries only — Prisma never interpolates user input into SQL
- No `dangerouslySetInnerHTML` in React — default escaping plus strict Content-Security-Policy headers via Helmet.js
- Secrets in environment variables — the `pre-commit` hook blocks `.env` files from being staged
- HTTPS in production — TLS 1.3, HSTS enforced, HTTP redirected

### Infrastructure

```mermaid
graph LR
    Internet --> Nginx["nginx (TLS termination)"]
    Nginx --> Backend["NestJS API"]
    Nginx --> Frontend["React SPA"]

    subgraph Container["Each container"]
        nonroot["Non-root user"]
        ro["Read-only filesystem where possible"]
    end

    Backend --> Container

    style Internet fill:#fecaca,stroke:#dc2626,color:#7f1d1d
    style Nginx fill:#fef3c7,stroke:#d97706,color:#78350f
    style Backend fill:#ede9fe,stroke:#7c3aed,color:#3b1f6e
    style Frontend fill:#dbeafe,stroke:#3b82f6,color:#1e3a5f
    style Container fill:#dcfce7,stroke:#22c55e,color:#14532d
```

- Non-root user in all production containers
- Helmet.js: CSP, X-Frame-Options, X-Content-Type-Options, Referrer-Policy, HSTS
- Per-IP and per-route rate limiting on all public endpoints
- CORS restricted to known origins only

### Dependencies

- `pnpm audit` runs in the CI pipeline on every PR
- Lock files committed — reproducible installs, no silent version drift
- No wildcard version ranges — all dependencies pinned to exact or `~minor`

---

## Scope

This is a 42 school project. The following are explicitly out of scope:

- Formal penetration testing or security audit
- SOC 2, ISO 27001, or any compliance framework
- Bug bounty program
- 24/7 incident response

Security is taken seriously as a technical discipline, not as compliance theater. The practices above reflect what a production service at this scale actually needs.
