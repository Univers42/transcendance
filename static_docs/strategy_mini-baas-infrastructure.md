# Mini-BaaS — Platform Strategy

> **What this document is**: The canonical reference for what mini-baas is, why it is built the way it is, and how every part connects — from raw infrastructure to a working product with a frontend and a business model on top.

---

## Table of Contents

1. [What Is Mini-BaaS](#1-what-is-mini-baas)
2. [The Core Bet](#2-the-core-bet)
3. [Architecture in Plain Language](#3-architecture-in-plain-language)
4. [The Two-Layer Entry System](#4-the-two-layer-entry-system)
5. [Service Catalog](#5-service-catalog)
6. [Multi-Tenancy Models](#6-multi-tenancy-models)
7. [Infrastructure & Deployment Strategy](#7-infrastructure--deployment-strategy)
8. [The 70 / 30 Rule](#8-the-70--30-rule)
9. [Connecting a Frontend](#9-connecting-a-frontend)
10. [Connecting a Business Model](#10-connecting-a-business-model)
11. [How to Use This Repo Independently](#11-how-to-use-this-repo-independently)
12. [Workflow — From Zero to Live Product](#12-workflow--from-zero-to-live-product)
13. [Development Conventions](#13-development-conventions)
14. [Decision Log](#14-decision-log)
15. [What You Still Have to Build](#15-what-you-still-have-to-build)
16. [Next Steps](#16-next-steps)

---

## 1. What Is Mini-BaaS

Mini-BaaS is a **self-hosted, composable Backend-as-a-Service platform** built from proven open-source components.

It gives any product team — or any developer building their own SaaS — a complete, production-ready backend out of the box:

- User authentication
- Auto-generated REST APIs from any database schema
- Real-time WebSocket subscriptions
- File storage (S3-compatible)
- SQL federation across multiple database engines
- Connection pooling
- A visual admin interface

The purpose is not to reinvent these primitives. Every one of them is already solved by a battle-tested open-source project. The purpose is to **compose them correctly, containerize them cleanly, and expose them in a way that a frontend and a business model can sit on top without friction**.

---

## 2. The Core Bet

> "We assemble the 70% that is already solved. We only write the 30% that is specific to our platform."

Every serious backend needs auth, storage, a database, a REST layer, and real-time. Those are commodity. The value mini-baas adds is:

- Correct wiring between components
- Multi-tenancy at the infrastructure level (not the application level)
- Clean environment promotion (local → staging → production) out of the box
- A Makefile-driven workflow so no institutional knowledge lives in someone's head
- Ports that a frontend can talk to immediately

The 30% you write is the **control plane**: provisioning new tenants, routing requests to the right backend, managing lifecycle, and enforcing quotas. Everything else is delegated to the docker images listed in this repo.

---

## 3. Architecture in Plain Language

```
Browser / Mobile App / Third-Party Client
            │
            ▼
┌───────────────────────────────────────┐
│         Layer 1 — HTTP Gateway        │  Kong  (routing, rate limiting, JWT)
└───────────────────────────────────────┘
            │
            ▼
┌───────────────────────────────────────┐
│       Layer 2 — SQL Federation        │  Trino  (universal SQL → any DB dialect)
└───────────────────────────────────────┘
            │
     ┌──────┴───────────────────────────────────┐
     ▼                                          ▼
Auth (GoTrue)              API Translators (PostgREST / RESTHeart / NocoDB …)
     │                                          │
     └──────────────────────┬───────────────────┘
                            ▼
              Database Layer (PostgreSQL primary)
              + Redis (cache / queues)
              + MinIO (object storage)
              + Realtime (WebSocket CDC)
              + Supavisor (connection pooling)
                            │
                            ▼
                 Supabase Studio (admin UI)
```

Each layer has exactly one job. Nothing bleeds into the next.

---

## 4. The Two-Layer Entry System

### Layer 1 — Kong (HTTP)

Every HTTP request from any client hits Kong first. Kong does not know about databases. It knows about:

- Routes (which service handles which path)
- Rate limits per tenant or per API key
- JWT verification (tokens issued by GoTrue)
- Plugin middleware (transformations, logging, CORS, etc.)

Kong is configured declaratively via `deck` (declarative config sync). Adding a new tenant means registering a new route in Kong's config — no code change.

### Layer 2 — Trino (SQL Federation)

Trino is the universal SQL layer. Its job is to translate queries across different database engines so that the API layer above it never has to care whether the data lives in PostgreSQL, MySQL, MongoDB, or Elasticsearch.

Without Trino, you need a separate REST translator per database type. With Trino, you have one SQL interface that handles all of them. This is the architectural leverage that makes multi-database tenants possible without an explosion of custom code.

---

## 5. Service Catalog

### Infrastructure Services (pre-built images, no custom code)

| Service | Image | Port | Purpose |
|---|---|---|---|
| **Kong** | `kong` | 8000 / 8443 | HTTP gateway, routing, plugins |
| **Trino** | `trinodb/trino` | 8080 | SQL federation across DB engines |
| **GoTrue** | `supabase/gotrue:v2.188.1` | 9999 | Auth — JWT, OAuth, MFA, sessions |
| **PostgREST** | `postgrest/postgrest:devel` | 3000 | Auto-REST from PostgreSQL schema |
| **Realtime** | `supabase/realtime` | 4000 | WebSocket subscriptions (CDC) |
| **MinIO** | `minio/minio` | 9000 / 9001 | S3-compatible file storage |
| **Redis** | `redis:trixie` | 6379 | Cache, queues, rate counters |
| **Supavisor** | `supabase/supavisor:2.7.4` | 6543 | PostgreSQL connection pooler |
| **PostgreSQL** | `postgres:16-alpine` | 5432 | Primary relational database |
| **Studio** | `supabase/studio` | 3001 | Admin UI |

### Custom Services (this repo owns these)

| Service | Language | Port | Purpose |
|---|---|---|---|
| **api-gateway** | Node.js / Express | 3000 | Custom gateway logic, middleware |
| **auth-service** | Python / FastAPI | 8000 | Auth extensions, user management |
| **dynamic-api** | Go | 8080 | High-performance dynamic endpoints |
| **schema-service** | TypeScript / Express | 3001 | Schema introspection, API generation |

Each custom service has a multistage Dockerfile, a Kubernetes `Deployment + Service` manifest, health probes, non-root users, and an `.dockerignore`. They are scaffolds — the interfaces are defined, the business logic is yours to fill in.

---

## 6. Multi-Tenancy Models

The choice of isolation model is the single most important architectural decision for a BaaS product. It determines cost, security posture, and scalability ceiling. Three models are supported:

### Silo — One stack per tenant

```
Tenant A: [Kong route] → [own PostgREST] → [own PostgreSQL]
Tenant B: [Kong route] → [own PostgREST] → [own PostgreSQL]
```

- **Isolation**: Complete. No shared data plane.
- **Cost**: Highest. Every tenant pays for a full stack.
- **Best for**: Enterprise customers, HIPAA / FedRAMP regulated workloads, high-value accounts that require contractual data isolation.

### Bridge — Shared cluster, isolated namespaces

```
Kong (shared) → Kubernetes namespace per tenant → own DB per tenant
```

- **Isolation**: Namespace-level. Good separation, shared control plane.
- **Cost**: Medium. Share the cluster overhead, pay per DB.
- **Best for**: Mid-market SaaS customers. The **recommended starting point** for this platform.

### Pool — Everything shared, row-level isolation

```
Kong (shared) → PostgREST (shared) → PostgreSQL (shared, RLS per tenant)
```

- **Isolation**: Row-Level Security only. Application-layer separation.
- **Cost**: Lowest. Divide all resources by number of tenants.
- **Best for**: High-volume, low-cost, small-customer SaaS. Maximum density, weakest isolation.

**Rule of thumb**: Start with Bridge for your first customers. Offer Silo as a premium tier. Use Pool only if you have a clear cost model and understand the RLS complexity.

---

## 7. Infrastructure & Deployment Strategy

### Local Development

Uses Docker Compose. Two compose files exist:

- `docker-compose.yml` — the full infrastructure stack (pre-built images only, for running locally without rebuilding custom services)
- `docker-compose.build.yml` — builds custom services from source and wires everything together

```bash
# Run the full stack locally (pre-built only)
docker compose up -d

# Build and run custom services from source
docker compose -f docker-compose.build.yml up -d --build
```

### Kubernetes (staging + production)

Managed via **Kustomize overlays**. Base manifests live in `deployments/base/`. Environment-specific patches live in `deployments/overlays/`.

```
deployments/
├── base/              ← canonical K8s definitions (env-neutral)
│   ├── kustomization.yaml
│   ├── api-gateway/deployment.yaml
│   ├── auth-service/deployment.yaml
│   ├── dynamic-api/deployment.yaml
│   └── schema-service/deployment.yaml
└── overlays/
    ├── local/         ← namespace: default, tag: latest
    ├── staging/       ← namespace: mini-baas-staging, tag: staging-latest
    └── production/    ← namespace: mini-baas-production, tag: v1.0.0
```

Overlay differences are minimal: namespace, image tag, name prefix, and environment labels. This means the exact same manifest is promoted from local → staging → production by changing only the overlay.

### Makefile — The single interface to everything

The Makefile is the CLI for this entire repo. It has 31+ targets covering:

```bash
# Docker
make docker-build               # build all images
make docker-build-api-gateway   # build one image
make docker-push                # tag + push to registry

# Kubernetes
make k8s-deploy                 # build + load + deploy (local minikube)
make k8s-status                 # show pods, deployments, services
make k8s-logs SERVICE=api-gateway
make k8s-scale SERVICE=api-gateway REPLICAS=3
make k8s-rollback SERVICE=api-gateway
make k8s-port-forward SERVICE=api-gateway PORT=3000

# CI/CD
make build-and-push REGISTRY=registry.example.com IMAGE_TAG=v1.0.0
make deploy-staging
make deploy-production
```

**Convention**: always use Make targets. Never run raw `kubectl` or `docker` commands for platform operations — keep operational knowledge in the Makefile so it is reproducible.

### Environment Variables

All secrets and configuration are managed through `.env` files (see `.env.example`). **Never commit `.env` to git.** For production, inject via Kubernetes Secrets or a secret manager (Vault, AWS Secrets Manager, etc.).

---

## 8. The 70 / 30 Rule

This repo provides **70%** of what you need:

- All infrastructure containers wired together
- Kubernetes manifests with health probes and resource limits
- Three multi-tenancy models
- Automated build + deploy pipeline
- Admin UI
- Auth, storage, real-time out of the box

**You write 30%** — the control plane in NestJS (or any backend framework):

| Control Plane Piece | What It Does |
|---|---|
| **Provisioner** | Creates a new tenant: namespace, DB, credentials, Kong route |
| **Kong Configurator** | Registers routes and plugins per tenant via `deck` sync |
| **Schema Introspector** | Reads DB schema metadata to auto-generate API endpoints |
| **Lifecycle Manager** | Suspends idle tenants, enforces quotas, handles deletion |
| **Query Router** | Routes incoming requests to the right Trino catalog / DB |

These pieces connect this repo to your product. Without them, mini-baas is an infrastructure toolkit. With them, it is a platform.

---

## 9. Connecting a Frontend

A frontend talks to this platform through two surfaces:

### Surface 1 — The Public API (via Kong)

Every operation a user can do from a browser or mobile app goes through Kong on port 8000:

```
POST /auth/signup      → GoTrue   (create account)
POST /auth/signin      → GoTrue   (get JWT)
GET  /api/items        → PostgREST (query DB, JWT verified by Kong)
POST /storage/upload   → MinIO    (upload file)
WS   /realtime         → Supabase Realtime (subscribe to changes)
```

Your frontend needs only the Kong URL and the anonymous JWT key. Everything else is handled by the platform. This is identical to how Supabase's client SDK works — and you can **use the Supabase JS client directly** pointed at your GoTrue + PostgREST endpoints.

```typescript
// Frontend — works against this stack out of the box
import { createClient } from '@supabase/supabase-js'

const supabase = createClient(
  'http://localhost:9999',  // GoTrue URL (or Kong route)
  'your-anon-key'
)

// Auth
await supabase.auth.signUp({ email, password })
await supabase.auth.signInWithPassword({ email, password })

// Database (via PostgREST)
const { data } = await supabase.from('items').select('*')

// Real-time
supabase.channel('items').on('postgres_changes', { event: '*', schema: 'public', table: 'items' }, handler).subscribe()

// Storage (via MinIO)
await supabase.storage.from('bucket').upload('file.jpg', file)
```

### Surface 2 — The Admin / Control Plane API

Your control plane (the 30% you build) exposes its own endpoints that your frontend uses for platform management:

```
POST /tenants           → provision new tenant
GET  /tenants/:id/status
PUT  /tenants/:id/plan  → upgrade/downgrade isolation model
DELETE /tenants/:id
GET  /tenants/:id/usage → billing data
```

The admin frontend (Supabase Studio, or a custom dashboard) talks to these endpoints.

### Frontend Stack Recommendations

Mini-baas is frontend-agnostic. However, the following stacks integrate with zero friction:

| Stack | Why It Works Well |
|---|---|
| **Next.js + Supabase JS** | The Supabase client works directly against GoTrue + PostgREST |
| **React + TanStack Query** | Pairs well with the REST-first API surface |
| **Vue / Nuxt** | Same — use the Supabase client or plain fetch |
| **React Native / Expo** | Mobile works the same way as web |

---

## 10. Connecting a Business Model

Mini-baas maps naturally to several business model patterns. The infrastructure supports all of them without changes.

### Pattern A — Self-Serve BaaS (Supabase-style)

You offer developers a dashboard where they sign up, create a project, and get a PostgreSQL database + REST API + auth instantly.

**Infrastructure mapping**:
- Each "project" = one Pool or Bridge tenant
- Billing is based on API requests, DB rows, or storage GB
- Supabase Studio serves as the dashboard (or you build your own)
- Free tier uses Pool model; paid tiers upgrade to Bridge or Silo

**Monetization levers**: storage limits, request quotas, team seats, isolation tier, SLA.

### Pattern B — Embedded BaaS (for your own SaaS)

You are building a SaaS product (e.g. a project management tool, a CRM, an analytics platform) and you use mini-baas as the backend layer so you can focus on product instead of infrastructure.

**Infrastructure mapping**:
- Your SaaS users are tenants in the Pool model (shared DB with RLS)
- GoTrue handles all your user auth
- PostgREST gives you instant CRUD without writing route handlers
- Realtime gives you live updates without a WebSocket server

**Benefit**: You ship faster because you don't write auth, don't set up S3, don't build a REST layer from scratch.

### Pattern C — White-Label Platform (for agencies or enterprise)

You sell the entire platform to clients who want their own private BaaS instance.

**Infrastructure mapping**:
- Each client = one Silo instance (dedicated stack)
- You manage the Kubernetes cluster; they access Studio
- Billing is per instance (flat fee or resource-based)

**Benefit**: Clients get complete data isolation and can customize their schema freely.

### Billing Integration Points

Wherever you build billing, these are the metrics the platform can expose:

| Metric | Source |
|---|---|
| API request count | Kong logs / Prometheus |
| Database storage size | PostgreSQL `pg_database_size()` |
| Object storage used | MinIO bucket metrics |
| Active connections | Supavisor connection stats |
| Active users (MAU) | GoTrue `users` table |
| Real-time message volume | Supabase Realtime metrics |

Wire these into Prometheus → Grafana for internal observability, and into your billing system (Stripe, Orb, etc.) for customer invoicing.

---

## 11. How to Use This Repo Independently

This repository is intentionally **tool-agnostic and product-agnostic**. It can be used in three ways:

### Mode 1 — Full BaaS Platform

Clone the repo, configure `.env`, run `docker compose up -d`, and you have a working BaaS that a frontend can talk to immediately. Add your control plane (the 30%) to make it multi-tenant.

```bash
git clone <repo>
cp .env.example .env
# edit .env with real secrets
docker compose up -d
# → GoTrue at :9999, PostgREST at :3000, Studio at :3001
```

### Mode 2 — Kubernetes Infrastructure Baseline

Use the Kustomize manifests and Makefile as the deployment layer for any set of services. Point your own Dockerfiles at the overlay system and use the Make targets for CI/CD.

```bash
# Replace scaffold source code with your real application code
# Keep the Dockerfile patterns (multistage, non-root, health checks)
# Keep the deployment.yaml patterns (probes, resource limits, labels)
# Everything else is inherited
make docker-build
make k8s-deploy ENVIRONMENT=staging
```

### Mode 3 — Individual Component Extraction

Pick only what you need. Each service is self-contained. You can use:

- Just GoTrue for auth in an existing project
- Just PostgREST + PostgreSQL for instant REST APIs
- Just MinIO for S3-compatible storage
- Just the Kustomize overlay pattern for your own services
- Just the Makefile pattern as a CI/CD interface

The compose files and manifests are modular — comment out anything you don't need.

---

## 12. Workflow — From Zero to Live Product

### Phase 1 — Local Proof of Concept

```bash
cp .env.example .env          # configure local secrets
docker compose up -d          # start full stack
# → Studio at http://localhost:3001
# → GoTrue at http://localhost:9999
# → PostgREST at http://localhost:3000
# Connect your frontend, test auth + database
```

### Phase 2 — Build & Containerize Custom Services

```bash
# Edit scaffold source code in deployments/base/*/
# Build and validate
make docker-build
docker compose -f docker-compose.build.yml up -d
# → All custom services running alongside infrastructure
```

### Phase 3 — Kubernetes Local (Minikube)

```bash
minikube start
make k8s-deploy               # build → load images → apply manifests
make k8s-status               # verify all pods Running
SERVICE=api-gateway PORT=3000 make k8s-port-forward
```

### Phase 4 — Staging

```bash
REGISTRY=registry.example.com IMAGE_TAG=staging-v1.0.0 make build-and-push
ENVIRONMENT=staging REGISTRY=registry.example.com IMAGE_TAG=staging-v1.0.0 make deploy-staging
ENVIRONMENT=staging make k8s-status
```

### Phase 5 — Production

```bash
REGISTRY=registry.example.com IMAGE_TAG=v1.0.0 make build-and-push
ENVIRONMENT=production REGISTRY=registry.example.com IMAGE_TAG=v1.0.0 make deploy-production
# If something goes wrong:
ENVIRONMENT=production SERVICE=api-gateway make k8s-rollback
```

---

## 13. Development Conventions

### Docker

- All Dockerfiles use **multistage builds**. Builder stage installs dev tools and compiles. Runtime stage copies only the compiled output.
- All runtime images use **Alpine Linux** or distroless. Never use `debian` or `ubuntu` as a runtime base.
- All containers run as **non-root users**.
- All services expose a `/health` endpoint. All Kubernetes manifests include `livenessProbe` and `readinessProbe` pointing at it.
- Every service directory has a `.dockerignore` that excludes git history, docs, tests, dev dependencies, and environment files.

### Kubernetes

- Resource `requests` and `limits` are always set. Never deploy without them.
- Use Kustomize overlays for environment differences. Never fork a manifest per environment.
- Labels follow the pattern `app.mini-baas/managed-by: kustomize` and `app.mini-baas/version: vX`.
- Namespaces: `default` (local), `mini-baas-staging`, `mini-baas-production`.

### Secrets

- Never commit `.env` files. Use `.env.example` as the contract.
- In Kubernetes, mount secrets via `Secret` objects — never as environment variables hardcoded in manifests.
- Rotate `JWT_SECRET`, `SECRET_KEY_BASE`, and `VAULT_ENC_KEY` before going to production.

### CI/CD

- All CI/CD actions should use Makefile targets. This means a CI pipeline is just a series of `make` calls.
- Image tags should be the Git commit SHA for staging and a semver tag for production.
- Rollback is `make k8s-rollback SERVICE=<name>` — no manual kubectl commands.

---

## 14. Decision Log

| Decision | Rationale |
|---|---|
| Trino as SQL federation layer | Eliminates per-database translator code. One SQL interface to all DB engines. |
| Kustomize over Helm | Kustomize patches are simpler for overlay-only differences. Helm is available as an opt-in in `tooling/helm/`. |
| GoTrue over custom auth | Battle-tested, supports OAuth + MFA + RBAC. No auth code to maintain. |
| Alpine Linux base images | 70-90% smaller than standard images. Reduced attack surface. |
| Multistage builds for all services | Build tools never end up in production images. |
| Makefile as the single interface | Prevents institutional knowledge from living in individuals' heads. All operations are reproducible. |
| Bridge model as default starting point | Balances isolation and cost. Can upgrade to Silo or downgrade to Pool per customer. |
| PostgREST as default REST translator | Zero boilerplate. Full REST + OpenAPI from schema alone. |
| Supabase-compatible surface | Allows use of the Supabase JS client directly. Proven frontend DX. |

---

## 15. What You Still Have to Build

The following are explicitly **not in this repo** and are the product-specific 30%:

### Required for a Functioning Multi-Tenant Platform

- **Tenant Provisioner** — creates new tenants, provisions namespace / DB / credentials
- **Kong Route Registrar** — adds per-tenant routes and plugin configs via `deck`
- **Schema Introspector** — reads DB metadata to derive API surface dynamically
- **Lifecycle Manager** — suspends idle tenants, enforces quotas, handles deletion
- **Control Plane API** — the REST API your dashboard or CLI calls to manage tenants

### Required for a Business

- **Billing integration** — Stripe / Orb connected to Prometheus metrics
- **Usage metering** — per-tenant request counts, storage, MAU
- **Customer dashboard** — frontend for tenants to manage their own projects
- **Onboarding flow** — signup → provision → give credentials → first request

### Recommended for Production Readiness

- **Observability stack** — Prometheus + Grafana + Logflare + Vector for logs and metrics
- **Alerting** — PagerDuty or Slack alerts for error rate, latency, pod restarts
- **Backup strategy** — PostgreSQL WAL archiving or pg_dump CronJob
- **Network policies** — restrict inter-pod traffic to declared paths only
- **HPA (Horizontal Pod Autoscaler)** — auto-scale api-gateway and dynamic-api on CPU/RPS

---

## 16. Next Steps

In priority order:

1. **Set real secrets** in `.env` — replace every `replace-with-*` value before anything touches the internet
2. **Start the stack locally** — `docker compose up -d`, open Studio, create a table, confirm PostgREST returns data
3. **Connect a frontend** — use the Supabase JS client pointed at localhost, test auth + query + real-time
4. **Choose your isolation model** — Bridge is recommended; document the decision
5. **Build the Provisioner** — the single most important control plane piece
6. **Wire Kubernetes locally** — `make k8s-deploy`, confirm pods are Running, port-forward and test
7. **Set up a registry** — push images to a real registry (GHCR, ECR, Docker Hub)
8. **Deploy to staging** — `make deploy-staging`, run smoke tests
9. **Add observability** — Prometheus + Grafana at minimum before production
10. **Deploy to production** — `make deploy-production` with a real image tag and rollback plan

---

*This document should be updated every time a significant architectural decision is made or reversed. It is the source of truth for why things are the way they are.*