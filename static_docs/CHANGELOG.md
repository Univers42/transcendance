# 📋 Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [Unreleased]

### Added
- Project skeleton: monorepo structure (`apps/backend`, `apps/frontend`, `packages/shared`)
- Docker infrastructure: development containers (Alpine + Node.js 22), PostgreSQL 16, Redis 7
- Makefile: one-command bootstrap, dev servers, testing, linting, database management
- GitHub templates: PR template, issue templates (bug report, feature request)
- CI pipeline: GitHub Actions (lint + typecheck + test)
- Documentation: README, CONTRIBUTING, CODE_OF_CONDUCT, SECURITY, ARCHITECTURE
- Editor configuration: `.editorconfig`, ESLint, Prettier
- Git hooks: pre-commit (lint-staged), commit-msg (conventional commits)
- Environment template: `.env.example` with all required variables

### Changed
- Nothing yet

### Fixed
- Nothing yet

---

## [0.0.1] - 2026-02-18

### Added
- Initial repository setup
- MIT License
- `.gitignore` for Node.js/NestJS projects
- Vendor toolkit (scripts, Born2beRoot setup)

---

<!-- Release comparison links -->
[Unreleased]: https://github.com/Univers42/ft_transcendence/compare/v0.0.1...HEAD
[0.0.1]: https://github.com/Univers42/ft_transcendence/releases/tag/v0.0.1
