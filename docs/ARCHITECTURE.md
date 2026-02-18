# 🏗️ Architecture Decisions

This document records the key architectural decisions made for ft_transcendence, along with the rationale behind each choice.

---

## Table of Contents

- [ADR-001: Monorepo Structure](#adr-001-monorepo-structure)
- [ADR-002: TypeScript Everywhere (Strict Mode)](#adr-002-typescript-everywhere-strict-mode)
- [ADR-003: NestJS for Backend](#adr-003-nestjs-for-backend)
- [ADR-004: React + Vite for Frontend](#adr-004-react--vite-for-frontend)
- [ADR-005: PostgreSQL as Primary Database](#adr-005-postgresql-as-primary-database)
- [ADR-006: Prisma as ORM](#adr-006-prisma-as-orm)
- [ADR-007: Redis for Cache & Real-Time](#adr-007-redis-for-cache--real-time)
- [ADR-008: Docker-First Development](#adr-008-docker-first-development)
- [ADR-009: JWT Authentication + OAuth 2.0](#adr-009-jwt-authentication--oauth-20)
- [ADR-010: Git Flow Branching Strategy](#adr-010-git-flow-branching-strategy)

---

## ADR-001: Monorepo Structure

**Status**: Accepted  
**Date**: 2026-02-18

### Context

We need to organize code for a backend (NestJS), frontend (React), and shared types/utilities in a way that supports 4-5 developers working in parallel.

### Decision

Use a **monorepo** structure with `apps/` for applications and `packages/` for shared code:

```
apps/backend/      # NestJS
apps/frontend/     # React + Vite
packages/shared/   # Shared types, DTOs, utilities
```

### Rationale

- **Shared types**: DTOs and interfaces defined once, used in both frontend and backend — eliminates type drift
- **Atomic PRs**: A feature touching both frontend and backend lives in one PR
- **Simpler CI**: One repo, one pipeline, one source of truth
- **No publishing overhead**: Unlike a multi-repo setup, no need for private npm packages

### Alternatives Considered

- **Separate repos** (backend + frontend): rejected — too much overhead for a 4-person team, type sharing becomes painful
- **Nx/Turborepo**: rejected — adds complexity we don't need for this project size

---

## ADR-002: TypeScript Everywhere (Strict Mode)

**Status**: Accepted  
**Date**: 2026-02-18

### Context

The project involves multiple developers with varying experience levels working on both frontend and backend.

### Decision

Use **TypeScript in strict mode** (`strict: true`) for all code — backend, frontend, and shared packages.

### Rationale

- **Catches bugs at compile time** — before they reach runtime or production
- **Self-documenting code** — types serve as inline documentation
- **Refactoring confidence** — rename a field and the compiler shows every place that needs updating
- **Shared language** — everyone writes the same language, reducing context switching
- **Industry standard** — TypeScript is used by most modern web projects; learning it is an investment

### Configuration

```json
{
  "compilerOptions": {
    "strict": true,
    "noUncheckedIndexedAccess": true,
    "noImplicitReturns": true,
    "noFallthroughCasesInSwitch": true,
    "forceConsistentCasingInFileNames": true,
    "esModuleInterop": true,
    "skipLibCheck": true
  }
}
```

---

## ADR-003: NestJS for Backend

**Status**: Accepted  
**Date**: 2026-02-18

### Context

We need a backend framework that supports:
- REST API endpoints
- WebSocket connections (real-time features)
- Authentication (JWT + OAuth)
- Database integration (Prisma)
- Modular architecture (multiple developers working in parallel)

### Decision

Use **NestJS 11** as the backend framework.

### Rationale

- **Opinionated architecture** — modules, controllers, services, guards, pipes, interceptors. Everyone follows the same patterns.
- **Built-in WebSocket support** — `@nestjs/websockets` + Socket.IO or native WS
- **Passport.js integration** — `@nestjs/passport` for JWT and OAuth strategies
- **Prisma integration** — first-class recipe in NestJS docs
- **Swagger generation** — automatic API documentation with `@nestjs/swagger`
- **Dependency injection** — makes testing easier (mock services, swap implementations)
- **TypeScript native** — built in TypeScript, for TypeScript

### Alternatives Considered

- **Express.js**: rejected — too unopinionated for a team project; everyone would structure code differently
- **Fastify**: rejected — excellent performance but smaller ecosystem for auth/websockets
- **Django/Flask**: rejected — team wants full-stack TypeScript

---

## ADR-004: React + Vite for Frontend

**Status**: Accepted  
**Date**: 2026-02-18

### Context

We need a frontend framework for a single-page application with real-time updates and a component-based architecture.

### Decision

Use **React 19** with **Vite 7** as the build tool, **Tailwind CSS v4** for styling, and **shadcn/ui** for accessible components.

### Rationale

- **React 19**: largest ecosystem, most learning resources, hooks + concurrent features
- **Vite 7**: instant HMR, fast builds, native ESM — dramatically faster than Webpack
- **Tailwind CSS v4**: utility-first, no CSS files to organize, consistent design system
- **shadcn/ui**: accessible, customizable components (not a dependency — code is copied into your project)

### Alternatives Considered

- **Next.js**: rejected — SSR adds complexity we don't need for this SPA
- **Angular**: rejected — steeper learning curve, heavier framework
- **Vue.js**: rejected — team has more React experience

---

## ADR-005: PostgreSQL as Primary Database

**Status**: Accepted  
**Date**: 2026-02-18

### Context

We need a relational database for user accounts, game history, chat messages, and other structured data.

### Decision

Use **PostgreSQL 16** as the primary (and only) database.

### Rationale

- **ACID compliance** — data integrity for user accounts, scores, transactions
- **Rich feature set** — JSONB, arrays, enums, full-text search, triggers, views
- **Row-Level Security** — built-in RLS for fine-grained access control
- **Prisma support** — first-class integration, excellent migration tooling
- **Industry standard** — most deployed open-source relational database

---

## ADR-006: Prisma as ORM

**Status**: Accepted  
**Date**: 2026-02-18

### Decision

Use **Prisma 7** as the database ORM.

### Rationale

- **Type-safe queries** — generated client provides full TypeScript autocompletion
- **Declarative schema** — `schema.prisma` is readable and serves as documentation
- **Migrations** — `prisma migrate` handles schema evolution safely
- **Prisma Studio** — visual database browser for debugging (port 5555)
- **NestJS recipe** — official integration guide in NestJS docs

---

## ADR-007: Redis for Cache & Real-Time

**Status**: Accepted  
**Date**: 2026-02-18

### Decision

Use **Redis 7** for caching, session storage, and real-time pub/sub.

### Rationale

- **Pub/Sub** — enables WebSocket message broadcasting across multiple server instances
- **Caching** — reduces database load for frequently accessed data
- **Session store** — faster than database-backed sessions
- **Rate limiting** — backend for `express-rate-limit` or custom implementation
- **Simple** — single dependency, Alpine image, no configuration needed

---

## ADR-008: Docker-First Development

**Status**: Accepted  
**Date**: 2026-02-18

### Decision

Use **Docker Compose** as the default development environment. Every team member runs `make` and gets an identical setup.

### Rationale

- **Zero local dependencies** — only Docker needed on the host
- **Identical environments** — eliminates "works on my machine" issues
- **Database included** — PostgreSQL + Redis start automatically
- **Named volumes** — `node_modules` in Docker volumes (fast, isolated)
- **Production parity** — dev environment mirrors production topology

---

## ADR-009: JWT Authentication + OAuth 2.0

**Status**: Accepted  
**Date**: 2026-02-18

### Decision

Use **JWT tokens** (access + refresh) for API authentication, with **OAuth 2.0** for third-party login (42 API / Google).

### Rationale

- **Stateless** — JWT tokens don't require server-side session storage
- **Refresh rotation** — short-lived access tokens + rotating refresh tokens for security
- **OAuth 2.0** — industry standard for third-party authentication
- **Passport.js** — battle-tested middleware with strategies for JWT and OAuth

---

## ADR-010: Git Flow Branching Strategy

**Status**: Accepted  
**Date**: 2026-02-18

### Decision

Use **Git Flow** with `main` (stable) and `develop` (integration) as protected branches. All work goes through feature branches and pull requests.

### Rationale

- **Protected main** — `main` always reflects production-ready code
- **Integration branch** — `develop` is where features meet and get tested together
- **Code reviews** — PRs enforce review before merge, catching bugs and sharing knowledge
- **Traceability** — every change is linked to an issue and a PR

See [CONTRIBUTING.md](../CONTRIBUTING.md) for the full workflow.

---

*This document is a living record. New ADRs are added as architectural decisions are made.*
