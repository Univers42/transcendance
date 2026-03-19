# Human-Error Guardrails

## Local Gates

Use local hooks for fast failures that do not need network or a full app boot:

- `pre-commit`
  - staged diff integrity via `git diff --cached --check`
  - blocks `.env`, key material, and future auth-state files
  - blocks large staged files over 500 KB
  - blocks `debugger` statements in staged JS / TS files
  - runs the lightweight frontend security sink check
- `commit-msg`
  - validates Conventional Commit subject format
- `pre-push`
  - re-runs static security checks
  - validates outgoing commit subjects
  - runs `eslint` and `tsc` through the `transcendence-dev` Docker container
  - blocks the push if Docker is down or the dev container is not running

## Pull Request Gates

Make these required checks on `develop` and `main`:

- `CI / 🔍 Lint`
- `CI / 🏗️ Type Check`
- `CI / 🧪 Tests`
- `QA Guardrails / Frontend Security Guard`

Also require:

- at least one approval
- required code owner review
- stale approval dismissal on new commits
- conversation resolution before merge

## Branch Protection Checklist

Apply to both `develop` and `main`:

1. Require a pull request before merging.
2. Require status checks before merging.
3. Require review from code owners.
4. Dismiss stale pull request approvals when new commits are pushed.
5. Restrict who can push directly.
6. Disable force pushes.
7. Disable branch deletion.

## Repo-Specific Notes

- Replace placeholder usernames in [`.github/CODEOWNERS`](../../.github/CODEOWNERS)
  before relying on required code owner review.
- The vendor hook path is not always present locally, so the repo-owned fallback
  hook set in `qa/implementation/hooks/` should stay available.
- Promote heavy scanners only after one false-positive triage pass.
