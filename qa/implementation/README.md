# QA Implementation Layer

This folder contains executable guardrails and scanner configuration.

## Structure

```text
qa/implementation/
├── configs/
│   ├── gitleaks/
│   └── semgrep/
├── hooks/           # Fallback git hooks when vendor hooks are unavailable
└── scripts/         # Reusable local / CI guard scripts
```

## What Exists Now

- a hook activation script with vendor-first fallback behavior
- fallback `pre-commit`, `commit-msg`, and `pre-push` hooks
- a lightweight frontend sink detector for risky browser APIs
- an HTTP header / cookie checker for local preview, dev, or staging
- baseline configs for Gitleaks and Semgrep

The fallback `pre-push` guard is Docker-dependent by design. It requires the
`transcendence-dev` container to be running and fails closed otherwise.

## Activation Order

1. Run `bash qa/implementation/scripts/activate-hooks.sh`
2. Make `QA Guardrails` a required status check in GitHub
3. Review the Gitleaks allowlist with the team before enabling CI secret scans
4. Triage Semgrep false positives before making it blocking

## Important Constraint

This layer is intentionally low-dependency. The current repo can therefore run
the first guardrails even when full scanner tooling is not installed yet.
