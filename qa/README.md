# QA & Pentest Workspace

This directory keeps the QA / pentest program separate from the application
code so the team can evolve security checks, test plans, and delivery gates
without polluting `apps/`.

## Layout

```text
qa/
├── project/          # Strategy, backlog, matrices, rollout decisions
└── implementation/   # Executable guards, Playwright smoke, configs, and hooks
```

## Rules

- Keep runtime application code in `apps/`.
- Keep QA policy, attack coverage, and rollout notes in `qa/project/`.
- Keep scripts, hook wrappers, and scanner configs in `qa/implementation/`.
- Do not store secrets, auth states, or private reports in this directory.

## Quick Start

```bash
bash qa/implementation/scripts/activate-hooks.sh
bash qa/implementation/scripts/check-frontend-security.sh
bash qa/implementation/scripts/pre-commit-guard.sh
bash qa/implementation/scripts/pre-push-guard.sh   # requires transcendence-dev running
make http-surface URL=http://localhost:3000/api/health
pnpm run frontend:smoke                           # requires root + frontend deps installed
```

## Why This Exists

The repo already contains product code, Docker/dev tooling, CI, and project
documentation. This QA layer adds a dedicated place for:

- attack-oriented test planning
- human-error guardrails
- low-dependency security checks that can run locally and in CI
- future scanner configs and deeper automation for Semgrep, Gitleaks, Trivy, and ZAP
