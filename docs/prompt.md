# Prismatica — Full Refactoring Prompt (≈50 Commits, 7 Phases)

> **Target AI**: Claude Opus 4.6 via GitHub Copilot
> **Project**: Prismatica (ft_transcendence) — Polymorphic Data Platform
> **Team**: dlesieur · danfern3 · serjimen · rstancu · vjan-nie — Univers42, 2026
> **Date**: March 23, 2026
> **Base branch**: develop

---

## 0 — What This Project Is

A **monolithic frontend + business-data application** that will eventually attach to an external BaaS built by another team (see `docs/strategy_mini-baas.md`). **There is no backend to build.** The app ships two things:

1. **A React 19 SPA** — the product interface (landing, auth, dashboards, collections, views)
2. **A lightweight data-api service** — a thin Express server running locally in Docker that reads from PostgreSQL + MongoDB and serves REST. This is the **local stand-in** for the future BaaS. When the BaaS is ready, the frontend changes one URL in env config. Nothing else changes.

### Dual Deployment Model

The architecture supports two modes from day one:

| Mode | How it works | Who uses it |
|---|---|---|
| **Local dev** | `make dev` → Docker spins up PG + Mongo + data-api + Vite. Everything on localhost. | Daily development, offline work, demos. |
| **Hosted / BaaS** | Frontend is built (`make build`) and served as static files (Nginx, CDN, Docker image). Points `VITE_API_URL` at the BaaS endpoint. | Production, staging, when backend team delivers. |

Both modes use the same frontend code. The only difference is the value of `VITE_API_URL`.

---

## 1 — What Exists Today

### Frontend Code (draft, in `temp/`)

| Location | Contents |
|---|---|
| `temp/app/src/components/` | UI components: Navbar, HeroSection, Footer, AuthForms (Login + Register), ImageSlider, ProductDescription, plus `ui/` atoms (Button, Field, BrandLogo, SplitLayout, ThemeToggle, LanguageSelector, SocialBtn, StrengthBar, InfoPanel, Icons) |
| `temp/app/src/pages/` | `MainPage` (landing) and `AuthPage` (login/register split layout) |
| `temp/app/src/styles/` | Full SCSS: `abstracts/` (_graphical-chart, _mixins), `base/` (reset, typography), `components/` (30+ files), `layout/`, `utilities/` |
| `temp/app/src/utils/` | `password.ts` (strength calculator) |
| `apps/frontend/src/` | Skeleton welcome page — **to be replaced** |
| `apps/frontend/src-temp/` | Partial copy of temp — **to be deleted** |
| `packages/shared/src/types/` | User, Chat, Notification, API types |

### Data Layer (complete — this is the gold)

| Location | Contents |
|---|---|
| `Model/sql/schema.*.sql` (9 files) | 55 tables across 9 domains: user, organization, billing, collection, dashboard, connectivity, adapter, resource, system, ABAC |
| `Model/sql/triggers/` (11 files) | Domain-specific trigger functions |
| `Model/sql/seeds/` (7 files) | Permissions → Roles → Plans → Usage meters → Demo users → Demo orgs → ABAC rules |
| `Model/sql/views.sql` | Read-only SQL views |
| `Model/sql/optimization.sql` | Indexes (B-tree, GIN, partial) |
| `Model/sql/manager/` | `apply_schema.sh` (3-phase application), `apply_seeds.sh` (runs seed files), `reset.sh`, `verify.sh` |
| `Model/nosql/*.ts` (13 files) | Mongoose schemas: collection_records, dashboard_layouts, view_configs, user_preferences, query_cache, workflow_states, global_settings, audit_log, sync_state, connection_credentials, abac_rule_conditions, abac_user_attributes |
| `Model/nosql/seeds/seed_mongo.js` | 1673 lines, 13 collections, idempotent upserts |
| `Model/sql/manager/mongo_setup.sh` | Creates 13 MongoDB collections + 40+ indexes |
| `Model/sql/manager/mongo_seed.sh` | Seeds MongoDB via mongosh |

### Infrastructure

| Location | Contents |
|---|---|
| `docker-compose.dev.yml` | PostgreSQL 16, Redis 7, Mailpit, dev container (Node 22 Alpine) |
| `docker/Dockerfile.dev` | Node 22 Alpine + pnpm + TypeScript + Prisma + pg-client |
| `Makefile` (778 lines) | 40+ targets: preflight, docker, install, compile, dev, db, lint, test, clean, prod |

### Architecture References (read these — they define the rules)

| Document | What it defines |
|---|---|
| `static_docs/frontend/frontend-design.md` | **1552-line bible**: FSD + Atomic Design, 6-layer folder structure, Zustand patterns, ViewStrategy interface, data flow, SCSS system |
| `static_docs/design/DESIGN_SYSTEM.md` | Prismatica Design System: Slate + Blue palette, Inter + JetBrains Mono, WCAG 2.2 AA |
| `docs/strategy_mini-baas.md` | BaaS architecture: `IDatabaseAdapter` interface, metadata-driven dynamic controller, frontend `/discovery` endpoint |
| `docs/strategy_mini-baas-infrastructure.md` | Infrastructure: Kong, Trino, PostgREST, multi-tenancy models, Makefile-driven workflow |

---

## 2 — Architecture Target

### Directory Structure

```
apps/
├── frontend/                     ← React SPA (Vite)
│   └── src/
│       ├── app/                  ← FSD Layer 6: Global orchestration
│       │   ├── providers/        ← QueryClient, Router, Theme, DataProvider, Toast
│       │   ├── routes/           ← Route definitions (lazy-loaded)
│       │   ├── guards/           ← ProtectedRoute, RoleGuard
│       │   └── index.tsx         ← App root (compose providers + router)
│       │
│       ├── pages/                ← FSD Layer 5: Route compositions
│       │   ├── landing/          ← / — Hero, features, footer
│       │   ├── auth/             ← /auth — Login/register split
│       │   ├── dashboard/        ← /dashboard — KPIs, recent activity
│       │   ├── collections/      ← /collections, /collections/:id
│       │   ├── settings/         ← /settings — Profile, prefs, org
│       │   └── not-found/        ← 404
│       │
│       ├── widgets/              ← FSD Layer 4: Autonomous organisms
│       │   ├── navbar/           ← Top nav (responsive, hamburger)
│       │   ├── sidebar/          ← Dashboard side nav (collapsible)
│       │   ├── data-table/       ← Generic sortable/filterable table
│       │   ├── schema-builder/   ← Collection field editor
│       │   ├── dashboard-grid/   ← Widget layout grid
│       │   ├── kpi-panel/        ← KPI summary cards
│       │   └── footer/           ← Site footer
│       │
│       ├── features/             ← FSD Layer 3: User interactions
│       │   ├── auth/             ← Login, register, mock OAuth
│       │   ├── theme/            ← Dark/light toggle
│       │   ├── language/         ← i18n selector
│       │   ├── collection-crud/  ← CRUD for collections
│       │   ├── record-crud/      ← CRUD for records (dynamic fields)
│       │   ├── search/           ← Global search
│       │   ├── user-settings/    ← Profile, preferences
│       │   ├── org-management/   ← Org settings, members
│       │   └── analytics/        ← KPIs, charts (MongoDB data)
│       │
│       ├── entities/             ← FSD Layer 2: Domain models
│       │   ├── user/             ← User types, store, api, UI
│       │   ├── organization/     ← Org, Project, Workspace
│       │   ├── collection/       ← Collection, Field, FieldType
│       │   ├── record/           ← Polymorphic records
│       │   ├── dashboard/        ← Dashboard, Widget
│       │   └── notification/     ← Notification types
│       │
│       ├── shared/               ← FSD Layer 1: Agnostic UI kit
│       │   ├── ui/
│       │   │   ├── atoms/        ← Button, Input, Badge, Icon, Spinner, Avatar, Select
│       │   │   └── molecules/    ← FormField, Modal, Tooltip, KPICard, DropdownMenu
│       │   ├── lib/              ← cn(), formatters, validators, password
│       │   ├── api/              ← DataProvider interface + hook + context
│       │   ├── config/           ← env, routes, constants
│       │   └── types/            ← Re-export shared package types + domain types
│       │
│       ├── styles/               ← Global SCSS (NOT component styles)
│       │   ├── abstracts/        ← _graphical-chart.scss, _mixins.scss, _index.scss
│       │   ├── base/             ← _reset.scss, _typography.scss
│       │   ├── layout/           ← _container.scss, _header.scss, _app.scss
│       │   └── utilities/        ← _animations.scss
│       │
│       └── main.tsx              ← Entry point
│
├── data-api/                     ← Lightweight REST service (LOCAL ONLY)
│   ├── package.json              ← Express + pg + mongodb dependencies
│   ├── tsconfig.json
│   ├── Dockerfile                ← Alpine Node, connects to PG + Mongo
│   └── src/
│       ├── index.ts              ← Express server, CORS, JSON
│       ├── routes/               ← /api/users, /api/collections, /api/records, etc.
│       ├── db/
│       │   ├── postgres.ts       ← pg Pool, reads from seeded PG
│       │   └── mongo.ts          ← MongoClient, reads from seeded Mongo
│       └── seed/
│           └── init.ts           ← On startup: apply schemas + seeds if DB is empty
│
Model/                            ← Business model (single source of truth)
│   ├── sql/                      ← PostgreSQL schemas, seeds, triggers, views
│   └── nosql/                    ← MongoDB Mongoose schemas, seeds
│
packages/shared/                  ← Shared TypeScript types
docker/                           ← Dockerfiles
```

### Data Flow (The Key Architectural Decision)

```
┌────────────────────────────────────────────────────────────────────┐
│                        React SPA (Vite)                            │
│                                                                    │
│  pages → widgets → features → entities → shared/api/               │
│                                                  │                 │
│                                          useDataProvider()         │
│                                                  │                 │
│                                     TanStack Query + fetch         │
│                                                  │                 │
└──────────────────────────────────────────────────┼─────────────────┘
                                                   │
                                          VITE_API_URL
                                                   │
                    ┌──────────────────────────────┼────────────────┐
                    │                              │                │
              LOCAL MODE                     HOSTED MODE            │
              (make dev)                     (make build)           │
                    │                              │                │
           ┌───────▼───────┐            ┌─────────▼──────────┐     │
           │  data-api      │            │  mini-BaaS REST    │     │
           │  Express:3001  │            │  PostgREST / Kong  │     │
           │  ┌───────────┐ │            │  (another team)    │     │
           │  │ PostgreSQL│ │            └────────────────────┘     │
           │  │ MongoDB   │ │                                       │
           │  └───────────┘ │                                       │
           └───────────────┘                                        │
                    │                                                │
              Docker local                                          │
              Model/sql + Model/nosql seeds                         │
└───────────────────────────────────────────────────────────────────┘
```

**The frontend never knows which mode it's in.** It calls `fetch(VITE_API_URL + '/collections')` and gets JSON. That's it.

### DataProvider Interface (mirrors mini-BaaS IDatabaseAdapter)

```typescript
// shared/api/data-provider.ts — the contract
export interface IDataProvider {
  findMany<T>(resource: string, params?: QueryParams): Promise<PaginatedResult<T>>;
  findOne<T>(resource: string, id: string): Promise<T>;
  create<T>(resource: string, data: Partial<T>): Promise<T>;
  update<T>(resource: string, id: string, data: Partial<T>): Promise<T>;
  remove(resource: string, id: string): Promise<void>;
  count(resource: string, filter?: Record<string, unknown>): Promise<number>;
}
```

This matches the `IDatabaseAdapter` from `docs/strategy_mini-baas.md`. When the BaaS delivers its REST surface, the frontend's `HttpDataProvider` already speaks the same language.

### SCSS Strategy: Hybrid

| What | How |
|---|---|
| **Base styles** (reset, typography, layout, animations) | Global SCSS in `src/styles/`, imported in `main.scss` |
| **Design tokens** (_graphical-chart, _mixins) | Auto-imported via Vite `additionalData` — available everywhere |
| **Component styles** | CSS Modules (`*.module.scss`) co-located with each component |

Existing global BEM classes from `temp/` are migrated into CSS Modules. Class names become scoped. The `cn()` utility (clsx wrapper) composes module classes.

---

## 3 — Git Workflow

### Branch Model: One Branch Per Phase

Each of the 7 phases gets a feature branch off `develop`. Work happens on the branch. When all commits in that phase compile and pass, merge into `develop` and delete the branch.

```
develop ──────────────────────────────────────────────────────►
    │                                                │
    └── phase/0-infra ──(8 commits)──── merge ──── delete
                                          │
                                          └── phase/1-shared ──(10 commits)──── merge ──── delete
                                                                                  │
                                                                                  └── phase/2-entities ...
```

### Branch Naming

```
phase/0-infra
phase/1-shared
phase/2-entities
phase/3-features
phase/4-widgets
phase/5-pages
phase/6-integration
```

### Commit Convention (Conventional Commits)

```
<type>(<scope>): <description>

type: feat | fix | infra | chore | test | docs | refactor
scope: shared | entities/user | features/auth | widgets/navbar | pages/dashboard | app | data-api | etc.
```

### Per-Phase Workflow

```bash
# Start phase
git checkout develop
git checkout -b phase/0-infra

# Work (multiple commits)
git add -A && git commit -m "infra: add MongoDB to docker-compose.dev.yml"
git add -A && git commit -m "infra: create data-api service skeleton"

# Verify everything compiles
make dev  # must work

# Merge and clean up
git checkout develop
git merge phase/0-infra
git branch -d phase/0-infra
```

---

## 4 — Commit Plan (≈50 Commits, 7 Phases)

### Phase 0 — Infrastructure & Data Service (8 commits)

**Branch: `phase/0-infra`**

| # | Commit | What to do |
|---|---|---|
| 1 | `infra: add MongoDB to docker-compose.dev.yml` | Add `mongo` service (mongo:7-jammy) with healthcheck, `mongo-data` volume, network. Add `MONGO_PORT=27017` and `DATA_API_PORT=3001` to `.env.example`. Mount `Model/sql/` and `Model/nosql/` as read-only volumes into the dev container. |
| 2 | `infra: create data-api service skeleton` | Create `apps/data-api/`: `package.json` (express, pg, mongodb, cors, dotenv, tsx), `tsconfig.json`, `src/index.ts` (Express on port 3001, CORS for localhost:5173, JSON body parser). Add `Dockerfile` (node:22-alpine, multistage). |
| 3 | `infra: implement data-api PostgreSQL connection and seed runner` | Create `apps/data-api/src/db/postgres.ts` (pg Pool). Create `apps/data-api/src/seed/init-pg.ts` — on startup, checks if `users` table exists; if not, runs `Model/sql/manager/apply_schema.sh` and `Model/sql/manager/apply_seeds.sh` via child_process exec against the PG container. |
| 4 | `infra: implement data-api MongoDB connection and seed runner` | Create `apps/data-api/src/db/mongo.ts` (MongoClient). Create `apps/data-api/src/seed/init-mongo.ts` — on startup, checks if `collection_records` collection exists; if not, runs `Model/sql/manager/mongo_setup.sh` and `Model/sql/manager/mongo_seed.sh` via the Mongo container. |
| 5 | `infra: implement data-api REST routes (CRUD)` | Create generic CRUD routes: `GET /api/:resource` (paginated list), `GET /api/:resource/:id`, `POST /api/:resource`, `PUT /api/:resource/:id`, `DELETE /api/:resource/:id`, `GET /api/:resource/count`. Route handler reads from PG for SQL resources (users, organizations, collections, dashboards, etc.) and from MongoDB for NoSQL resources (records, layouts, preferences, audit_log). |
| 6 | `infra: add data-api to docker-compose.dev.yml` | Add `data-api` service: builds from `apps/data-api/Dockerfile`, depends on `db` + `mongo`, ports `${DATA_API_PORT:-3001}:3001`, mounts `Model/` read-only. Environment: `DATABASE_URL`, `MONGO_URL`. |
| 7 | `chore: clean up duplicate source directories` | Delete `apps/frontend/src-temp/`. Move canonical code from `temp/app/src/` into `apps/frontend/src/` preserving the FSD structure (flat for now — reorganized in Phase 1). Keep `temp/` as archive reference. |
| 8 | `infra: update Makefile for new stack` | Add targets: `make data-api` (build + start data-api), `make db-init` (apply PG schemas + seeds + Mongo setup + seeds), `make db-reset` (drop + reinit), `make db-verify`. Update `make dev` to start PG + Mongo + data-api + Vite (no NestJS). Add `VITE_API_URL=http://localhost:3001/api` to `.env.example`. |

**Verification after Phase 0:**
- `make docker-up` starts PG + Mongo + data-api
- `curl http://localhost:3001/api/users` returns seeded users as JSON
- `curl http://localhost:3001/api/collections` returns seeded collections
- Vite dev server starts at localhost:5173

### Phase 1 — Shared Layer + Design System (10 commits)

**Branch: `phase/1-shared`**

| # | Commit | What to do |
|---|---|---|
| 9 | `chore: configure Vite path aliases and tsconfig for FSD` | Add aliases: `@/` → `src/`, `@shared/` → `src/shared/`, `@entities/` → `src/entities/`, `@features/` → `src/features/`, `@widgets/` → `src/widgets/`, `@pages/` → `src/pages/`, `@app/` → `src/app/`. Update both `vite.config.ts` and `tsconfig.json`. Add `zod` to deps. |
| 10 | `feat(styles): migrate SCSS design system` | Move SCSS from `temp/app/src/styles/` into `apps/frontend/src/styles/`. Structure: `abstracts/` (_graphical-chart, _mixins, _index), `base/` (_reset, _typography), `layout/` (_container, _header, _app), `utilities/` (_animations). Create `main.scss` that imports base + layout + utilities. Verify Vite `additionalData` auto-imports abstracts. |
| 11 | `feat(shared): create UI atoms — Button, Input, Select` | Create `src/shared/ui/atoms/button/` (Button.tsx, Button.types.ts, Button.module.scss, index.ts). Migrate from temp. Polymorphic: `<button>`, `<a>`, or `<Link>`. Same for Input and Select. CSS Modules, not global BEM. |
| 12 | `feat(shared): create UI atoms — Badge, Icon, Spinner, Avatar` | Badge = colored label. Icon = Lucide wrapper with size prop. Spinner = loading indicator. Avatar = user image with fallback initials. All CSS Modules. |
| 13 | `feat(shared): create UI molecules — FormField, SplitLayout, BrandLogo, SocialBtn` | Molecules compose atoms. FormField = Label + Input + ErrorText. SplitLayout = responsive two-column (migrate from temp). BrandLogo = Icon + Text link. SocialBtn = Button + Icon. |
| 14 | `feat(shared): create UI molecules — Modal, Tooltip, DropdownMenu, KPICard` | Modal = overlay + content + close button. Tooltip = hover info. DropdownMenu = trigger + menu list. KPICard = value + label + trend arrow. |
| 15 | `feat(shared/lib): create utility functions` | Create `src/shared/lib/`: `cn.ts` (clsx wrapper), `formatters.ts` (date, number, uptime, filesize), `validators.ts` (email, URL, required, minLength), `password.ts` (migrate from temp). Barrel `index.ts`. |
| 16 | `feat(shared/api): create DataProvider layer` | Create `src/shared/api/data-provider.ts` (IDataProvider interface). Create `src/shared/api/http-provider.ts` (fetch-based, reads `VITE_API_URL`). Create `src/shared/api/provider-context.tsx` (React context + `useDataProvider()` hook). Create `src/shared/api/use-query.ts` (TanStack Query wrappers: `useResource`, `useResourceById`, `useMutateResource`). |
| 17 | `feat(shared): create config, types, and constants` | Create `src/shared/config/env.ts`, `routes.ts`. Create `src/shared/types/` — re-export from `packages/shared/` plus domain types: `Collection`, `Field`, `FieldType`, `Organization`, `Workspace`, `Project`, `Dashboard`, `DashboardWidget`, `Record`. |
| 18 | `test: verify shared layer compiles and atoms render` | Add `vitest` + `@testing-library/react`. Basic smoke tests. Add `make test-frontend` target. |

### Phase 2 — Entities Layer (6 commits)

**Branch: `phase/2-entities`**

| # | Commit | What to do |
|---|---|---|
| 19 | `feat(entities/user): create User entity slice` | `model/types.ts`, `model/store.ts` (Zustand), `api/user.api.ts` (TanStack Query + DataProvider), `ui/UserAvatar.tsx`, `ui/UserBadge.tsx`, `index.ts`. |
| 20 | `feat(entities/organization): create Organization entity` | types (Organization, Project, Workspace, Membership), store, api, ui (OrgSelector, OrgBadge). |
| 21 | `feat(entities/collection): create Collection entity` | types (Collection, Field, FieldType enum — 15+ types from schema.collection.sql), store, api. **Core business entity.** |
| 22 | `feat(entities/record): create Record entity` | types (CollectionRecord — polymorphic `data: Record<string, unknown>`), store, api. Data from MongoDB via data-api. |
| 23 | `feat(entities/dashboard): create Dashboard entity` | types (Dashboard, Widget, WidgetPosition, WidgetType — 15 types), store, api. |
| 24 | `feat(entities/notification): create Notification entity` | types, store, api, ui (NotificationBadge, NotificationItem). |

### Phase 3 — Features Layer (9 commits)

**Branch: `phase/3-features`**

| # | Commit | What to do |
|---|---|---|
| 25 | `feat(features/auth): create authentication feature` | LoginForm, RegisterForm, AuthForms (migrate from temp — CSS Modules), useAuthStore, auth.api.ts. |
| 26 | `feat(features/theme): create theme toggle feature` | ThemeToggle (migrate), useThemeStore (Zustand persist). |
| 27 | `feat(features/language): create language selector feature` | LanguageSelector (migrate), useLanguageStore (Zustand persist). |
| 28 | `feat(features/collection-crud): create collection CRUD` | CreateCollectionDialog, CollectionListItem, useCollectionActions. |
| 29 | `feat(features/record-crud): create record CRUD` | RecordForm (**dynamic** — renders per FieldType), RecordRow, useRecordActions. |
| 30 | `feat(features/search): create global search` | SearchBar (debounced), SearchResults, useSearchStore. |
| 31 | `feat(features/user-settings): create user settings` | ProfileForm, PreferencesForm, useSettingsStore. |
| 32 | `feat(features/org-management): create org management` | OrgSettingsForm, MemberList, InviteMemberDialog. |
| 33 | `feat(features/analytics): create analytics feature` | KPICard, AnalyticsChart (canvas/SVG), useAnalyticsStore. |

### Phase 4 — Widgets Layer (6 commits)

**Branch: `phase/4-widgets`**

| # | Commit | What to do |
|---|---|---|
| 34 | `feat(widgets/navbar): create Navbar widget` | Migrate from temp. BrandLogo + NavLinks + ThemeToggle + LanguageSelector + CTA. Responsive hamburger. |
| 35 | `feat(widgets/sidebar): create Sidebar widget` | OrgSelector + collection tree + dashboard list + settings link. Collapsible. |
| 36 | `feat(widgets/data-table): create DataTable widget` | Generic dynamic table. Columns from field definitions, rows from records. Sortable, filterable, paginated. |
| 37 | `feat(widgets/schema-builder): create SchemaBuilder widget` | Visual field editor. Add/remove/reorder fields. FieldType selector, name, slug, required, default. |
| 38 | `feat(widgets/dashboard-grid): create DashboardGrid widget` | Widget layout grid from dashboard entity. Renders KPICards, Charts, DataTables. Static grid layout. |
| 39 | `feat(widgets/footer): create Footer widget` | Migrate from temp. Four-column links + social + copyright. |

### Phase 5 — Pages Layer (6 commits)

**Branch: `phase/5-pages`**

| # | Commit | What to do |
|---|---|---|
| 40 | `feat(pages/landing): create Landing page` | Navbar + HeroSection + ProductDescription + Footer. Public route `/`. |
| 41 | `feat(pages/auth): create Auth page` | Navbar + SplitLayout(InfoPanel + AuthForms). Route `/auth`. |
| 42 | `feat(pages/dashboard): create Dashboard page` | Protected route. Navbar + Sidebar + DashboardGrid. KPIs + recent collections. |
| 43 | `feat(pages/collections): create Collections page` | Protected route. `/collections` → list, `/:id` → DataTable, `/:id/schema` → SchemaBuilder. |
| 44 | `feat(pages/settings): create Settings page` | Protected route. Tabbed: Profile, Preferences, Organization. |
| 45 | `feat(pages/not-found): create 404 page` | Illustration + "Page not found" + back button. |

### Phase 6 — App Shell & Final Integration (5 commits)

**Branch: `phase/6-integration`**

| # | Commit | What to do |
|---|---|---|
| 46 | `feat(app): create App shell with providers and lazy routing` | Providers: QueryClient, BrowserRouter, DataProvider (HttpDataProvider + VITE_API_URL), Toaster. Routes: React.lazy() + ProtectedRoute. main.tsx entry. |
| 47 | `refactor(styles): finalize SCSS integration` | Verify main.scss is base/layout/utilities only. All component styles are CSS Modules. Theme toggle end-to-end. |
| 48 | `infra: finalize Makefile for complete workflow` | `make` = docker-up + db-init + install + dev. `make build` = vite build. `make prod` = build + nginx. `make test` = vitest. `make typecheck` = tsc --noEmit. |
| 49 | `test: add integration tests for key flows` | Landing renders, auth tabs, login flow, dashboard KPIs, collections list, records DataTable. |
| 50 | `docs: update README, CONTRIBUTING, and CHANGELOG` | Architecture diagram, quick start, dual deployment, FSD rules, commit convention. |

---

## 5 — Critical Rules

### FSD Import Direction (enforced in every file)

```
app/     → pages, widgets, features, entities, shared
pages/   → widgets, features, entities, shared
widgets/ → features, entities, shared
features/→ entities, shared
entities/→ shared
shared/  → NOTHING (only npm packages)
```

### Slice Structure (every entity, feature, widget)

```
slice-name/
├── ui/           ← TSX components (+ co-located *.module.scss)
├── model/        ← types.ts + store.ts (Zustand)
├── api/          ← TanStack Query hooks using DataProvider
├── lib/          ← Slice-specific utilities (optional)
└── index.ts      ← PUBLIC API — the only export surface
```

**Never import from `slice/model/store.ts` directly. Import from `slice/index.ts`.**

### TypeScript Rules

- `strict: true` with all strict flags enabled
- Every component: explicit return type `JSX.Element`
- Props in `.types.ts` file — always an interface, never inline
- `unknown` over `any` — polymorphic record data is `Record<string, unknown>`

### SCSS Rules (Hybrid)

- **Global** (`src/styles/`): reset, typography, layout, animations, CSS variables for theming
- **Tokens** (`abstracts/_graphical-chart.scss`): auto-imported in every SCSS file via Vite
- **Components**: CSS Modules (`.module.scss`), class names composed via `cn()` from `shared/lib`
- **Theming**: `:root` = light, `[data-theme='dark']` = dark. All colors use CSS custom properties.

### Zustand Rules

- One store per slice — never monolithic
- `persist` for: theme, language, auth token
- `devtools` in dev mode
- Async data in TanStack Query, not in stores. Stores hold UI state only.

### data-api Rules

- **Resource mapping**: SQL tables → `/api/<table_name>`. MongoDB collections → `/api/nosql/<collection_name>`.
- **Pagination**: `?page=1&perPage=20&sortBy=created_at&sortOrder=desc&search=foo`
- **Response shape**: `{ data: T[], meta: { total, page, perPage, totalPages } }` for lists. Raw `T` for single items.
- **Startup**: Auto-seeds databases if empty using `Model/sql/manager/*.sh` and `Model/nosql/seeds/seed_mongo.js`.

---

## 6 — Docker Compose (Target State)

```yaml
services:
  db:        # PostgreSQL 16-alpine (existing)
  redis:     # Redis 7-alpine (existing)
  mongo:     # MongoDB 7 (NEW)
  data-api:  # Express REST service (NEW) — reads from db + mongo
  dev:       # Node 22 dev container — runs Vite only (simplified)
```

### .env.example (updated)

```env
FRONTEND_PORT=5173
DATA_API_PORT=3001
DB_PORT=5432
REDIS_PORT=6379
MONGO_PORT=27017
POSTGRES_USER=transcendence
POSTGRES_PASSWORD=transcendence
POSTGRES_DB=transcendence
MONGO_URL=mongodb://mongo:27017/transcendence
VITE_API_URL=http://localhost:3001/api
```

---

## 7 — Execution Instructions

1. **Read before coding.** Before each phase, read reference files in `temp/`, `Model/sql/`, `Model/nosql/`, `static_docs/frontend/frontend-design.md`.
2. **Migrate, don't rewrite.** Move existing components from `temp/` into FSD structure, convert BEM to CSS Modules, add TypeScript strictness.
3. **Every commit compiles.** `pnpm exec tsc --noEmit` + `pnpm exec vite build` + `make dev` must work.
4. **Branch discipline.** Start each phase on its own branch. Merge into develop only when verified. Delete branch after merge.
5. **Follow code style.** JSDoc headers, named exports, barrel exports via `index.ts`, Prettier (semi, singleQuote, trailingComma all).
6. **The Makefile is the CLI.** Every operation gets a `make` target.
7. **Dual deployment.** Never hardcode `localhost`. Always read `VITE_API_URL` from env.

---

## 8 — Success Criteria

- [ ] `make` from clean clone → Docker up + DB seeded + Vite running
- [ ] `curl localhost:3001/api/users` → seeded users JSON
- [ ] `curl localhost:3001/api/collections` → seeded collections JSON
- [ ] Landing page: Navbar + Hero + Product + Footer
- [ ] `/auth`: login/register with form validation
- [ ] `/dashboard`: KPIs from data-api, widget grid
- [ ] `/collections`: list, click → DataTable with records
- [ ] `/collections/:id/schema`: SchemaBuilder
- [ ] Theme toggle: dark/light persisted
- [ ] `make typecheck` → 0 errors
- [ ] `make test-frontend` → all tests pass
- [ ] FSD import rules: no upward imports
- [ ] All data flows through DataProvider → data-api → Docker PG/Mongo
- [ ] `VITE_API_URL=https://baas.example.com/api make build` → works against remote BaaS

---

*This prompt is the canonical execution plan. Follow it phase by phase, commit by commit. When in doubt, read the referenced source files.*
