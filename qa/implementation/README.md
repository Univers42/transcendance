# QA Implementation Layer

This folder contains executable guardrails and scanner configuration.

## Structure

```text
qa/implementation/
├── configs/
│   ├── gitleaks/
│   └── semgrep/
├── hooks/           # Fallback git hooks when vendor hooks are unavailable
├── playwright/      # Frontend smoke coverage for stable UI routes
└── scripts/         # Reusable local / CI guard scripts
```

## What Exists Now

- a hook activation script with vendor-first fallback behavior
- fallback `pre-commit`, `commit-msg`, and `pre-push` hooks
- a lightweight frontend sink detector for risky browser APIs
- an HTTP header / cookie checker for local preview, dev, or staging
- Playwright smoke coverage for the stable landing and auth screens
- baseline configs for Gitleaks and Semgrep

The fallback `pre-push` guard is Docker-dependent by design. It requires the
`transcendence-dev` container to be running and fails closed otherwise.

## Frontend Smoke Tests

The first P1 Playwright slice covers the two stable frontend routes that
already exist today:

- `/` landing page render and auth CTA navigation
- `/auth` smoke checks plus negative validation paths for login and register

Local usage:

```bash
pnpm install
cd apps/frontend && pnpm install && cd ../..
pnpm run frontend:smoke:install
pnpm run frontend:smoke
```

If you already have the frontend running elsewhere, skip the built-in web
server:

```bash
PLAYWRIGHT_SKIP_WEBSERVER=1 PLAYWRIGHT_BASE_URL=http://127.0.0.1:5173 pnpm run frontend:smoke
```

## Activation Order

1. Run `bash qa/implementation/scripts/activate-hooks.sh`
2. Make `QA Guardrails` a required status check in GitHub
3. Review the Gitleaks allowlist with the team before enabling CI secret scans
4. Triage Semgrep false positives before making it blocking

## Important Constraint

This layer is intentionally low-dependency. The current repo can therefore run
the first guardrails even when full scanner tooling is not installed yet.
