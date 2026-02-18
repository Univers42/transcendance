# 🔒 Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability in this project, please report it responsibly.

### How to Report

1. **Do NOT open a public issue** — security issues must be reported privately
2. Contact the Tech Lead or Project Manager directly via Discord DM
3. Include:
   - Description of the vulnerability
   - Steps to reproduce
   - Potential impact
   - Suggested fix (if you have one)

### Response Timeline

| Step | Timeframe |
|------|-----------|
| Acknowledgment | Within 24 hours |
| Initial assessment | Within 48 hours |
| Fix deployed | Within 1 week (critical) / 2 weeks (medium) |

---

## Security Practices

### Authentication & Authorization

- **JWT** with short-lived access tokens and refresh token rotation
- **OAuth 2.0** for third-party authentication (42 API / Google)
- **bcrypt** for password hashing (minimum 12 salt rounds)
- **Role-Based Access Control (RBAC)** — routes are guarded by role
- **Session invalidation** on password change or suspicious activity

### Data Protection

- **HTTPS only** — all traffic encrypted in transit (TLS 1.3)
- **Environment variables** for secrets — never hardcoded, never committed
- **Database** — parameterized queries via Prisma (SQL injection prevention)
- **Input validation** — all inputs validated with `class-validator` DTOs
- **Output sanitization** — prevent XSS via React's default escaping + CSP headers

### Infrastructure

- **Docker containers** — isolated runtime environments
- **Non-root users** in production containers
- **Helmet.js** — secure HTTP headers (CSP, HSTS, X-Frame-Options, etc.)
- **Rate limiting** — per-IP and per-route rate limits
- **CORS** — strict origin whitelist

### Dependencies

- **Regular updates** — `npm audit` run in CI pipeline
- **Lock files committed** — `package-lock.json` ensures reproducible builds
- **No wildcard versions** — all dependencies pinned to exact or minor range

---

## Security Checklist for PRs

Before merging any PR, verify:

- [ ] No secrets or credentials in the code
- [ ] No `console.log` with sensitive data
- [ ] Input validation on all new endpoints
- [ ] Authorization guards on protected routes
- [ ] SQL injection prevention (using Prisma, no raw queries without parameterization)
- [ ] XSS prevention (no `dangerouslySetInnerHTML` without sanitization)
- [ ] Rate limiting considered for new public endpoints
- [ ] Error messages don't leak internal details

---

## Known Security Boundaries

This is a **student project** for 42's Common Core. While we implement security best practices, the following are out of scope:

- Penetration testing / formal security audit
- SOC 2 / ISO 27001 compliance
- Bug bounty program
- 24/7 incident response team

We take security seriously as a learning exercise and implement industry best practices within the scope of an educational project.

---

*This policy is reviewed and updated with each major release.*
