# Security Testing Matrix

## Front Phase Matrix

| Surface | Primary risks | What should be automated now | Next step |
|---------|---------------|------------------------------|-----------|
| Auth forms (`apps/frontend/src/components/login-form`, `register-form`) | weak client validation, reflected messages, unsafe redirects, broken error handling | Playwright auth smoke, negative validation checks, static sink detection | expand to real backend-auth and degraded-session flows |
| User-facing rendering | XSS via names, bios, chat-like messages, notifications, query params | static checks for raw HTML sinks and unsafe client APIs | Semgrep rules + Playwright malicious payload fixtures |
| Route protection | broken protected views, stale auth state, bad 401/403 UX | pending once protected routes exist in the UI | Playwright multi-role flows |
| HTTP surface | missing CSP / HSTS / cookie flags / frame protection | header and cookie assertions with `check-http-surface.sh` | CI against preview / staging |
| Local git workflow | bad commit messages, merge markers, leaked env files, debug leftovers | fallback hooks in `qa/implementation/hooks` | add scanner-backed secret detection |
| Dependencies | vulnerable packages, drift, stale lockfiles | Dependabot config | scanner + nightly dependency audit |

## Near-Term Real-Time Matrix

| Surface | Primary risks | Why it matters |
|---------|---------------|----------------|
| WebSocket handshake | missing origin allowlist, cookie reuse from hostile origins | CSWSH and cross-origin abuse are common in real-time apps |
| WebSocket messages | authorization missing after connect, oversized frames, invalid JSON | "connected" must not mean "allowed to do everything" |
| Session lifecycle | logout does not close sockets, expired session stays active | real-time channels often outlive HTTP session checks |
| Matchmaking / invites | race conditions, duplicate acceptance, impossible transitions | business-logic bugs are often security bugs in games |

## Mapping Rules

- Every auth, session, or WebSocket change must add one negative test.
- Every new user-controlled string must be classified as plain text or sanitized
  rich text before shipping.
- Every new QA automation item must say whether it is local-only, PR, or nightly.
