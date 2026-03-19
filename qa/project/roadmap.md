# QA Roadmap

## Current Baseline

The repository already has a useful starting point:

- CI for lint, typecheck, backend tests, and E2E
- `CODEOWNERS`
- a pull request template
- Docker-based local development

Current gaps that matter for QA / pentest:

- the configured hook path depends on `vendor/scripts/hooks`, but that
  submodule is not initialized in this checkout
- no repo-owned fallback hook set exists
- no attack-oriented frontend guardrails exist yet
- no dedicated QA folder, backlog, or control matrix existed
- `CODEOWNERS` still contains placeholder usernames

## P0: Human-Error Guardrails

- Activate repo-owned fallback hooks when `vendor/scripts/hooks` is unavailable.
- Block accidental commits of `.env`, key material, and future auth-state files.
- Fail fast on merge markers, trailing whitespace issues, large staged files, and
  `debugger` statements.
- Add commit message validation aligned with Conventional Commits.
- Add a lightweight CI guard for frontend security sink patterns.
- Add Dependabot automation for root, frontend, backend, and Docker updates.

Definition of done:

- `make configure-hooks` and root `prepare` activate a valid hook path
- `pre-commit`, `commit-msg`, and `pre-push` work without the vendor submodule
- PRs get a dedicated QA guard status

## P1: Frontend Attack-Oriented Automation

Current progress:

- reusable HTTP header / cookie assertions now exist locally and via a manual
  GitHub workflow for preview or staging URLs
- Playwright smoke coverage now exists for the stable landing and auth routes,
  including negative form-validation paths

- Add Playwright smoke tests for login, guarded routes, error screens, and auth
  degradation cases.
- Add cookie / header assertions against preview or dev environments.
- Add visual baselines for login, profile, lobby, and chat once those screens are
  stable.
- Wire Semgrep custom rules into CI after the first false-positive triage pass.
- Wire Gitleaks into CI after the allowlist is reviewed with the team.

Definition of done:

- one smoke path per critical screen
- one negative path per auth-sensitive screen
- one reusable header / cookie check for preview and staging

## P2: Abuse and Real-Time Coverage

- Add WebSocket abuse tests: origin validation, post-logout behavior, oversized
  payloads, invalid JSON, unauthorized actions, flood / reconnect pressure.
- Add business-logic abuse tests: double-submit, duplicate invite acceptance,
  queue race conditions, impossible state transitions.
- Add nightly ZAP baseline scans against a preview or staging URL.
- Add Trivy repo / filesystem scans once Docker and deployment files stabilize.

Definition of done:

- nightly security run produces triageable findings, not noise
- every auth / session / websocket change has at least one negative test

## Manual GitHub Actions Still Required

These items cannot be fully enforced from files alone:

- protect `main` and `develop`
- require pull requests before merge
- require code owner review
- require the CI and QA guard checks before merge
- dismiss stale approvals on new commits
- restrict direct pushes to protected branches

## Review Cadence

- Revisit this roadmap at the end of each sprint.
- Promote a check from opt-in to required only after one false-positive review.
- Keep the attack backlog smaller than the product backlog by focusing on the
  highest-risk surfaces first.
