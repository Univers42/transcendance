# ⚡ Transcendence

*Full-Stack Platform — Team Univers42, 2026*

> A modern full-stack web application built with TypeScript, containerized and production-ready. The thematic is entirely up to your team — build whatever inspires you.

[![TypeScript](https://img.shields.io/badge/TypeScript-strict-blue?logo=typescript&logoColor=white)]()
[![NestJS](https://img.shields.io/badge/NestJS-11-e0234e?logo=nestjs&logoColor=white)]()
[![React](https://img.shields.io/badge/React-19-61dafb?logo=react&logoColor=white)]()
[![Docker](https://img.shields.io/badge/Docker-ready-2496ed?logo=docker&logoColor=white)]()
[![License](https://img.shields.io/badge/license-MIT-green)](LICENSE)

---

## 📋 Table of Contents

- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Make Commands](#-make-commands)
- [Environment Variables](#-environment-variables)
- [Documentation](#-documentation)
- [License](#-license)

---

## 🚀 Quick Start

### Prerequisites

- **Docker** (Docker Desktop or Docker Engine + Compose v2)

That's it. No Node.js, no PostgreSQL, no Redis on your host. Everything runs in containers.

### Setup

```bash
git clone git@github.com:Univers42/ft_transcendence.git
cd ft_transcendence
cp .env.example .env   # then edit .env with your values
make                   # builds containers, installs deps, runs migrations
```

### Local URLs

| Service | URL |
|---------|-----|
| Frontend (Vite) | http://localhost:5173 |
| Backend (NestJS) | http://localhost:3000 |
| API Docs (Swagger) | http://localhost:3000/api/docs |
| Prisma Studio | http://localhost:5555 |
| PostgreSQL | localhost:5432 |
| Redis | localhost:6379 |
| Mailpit (dev email) | http://localhost:8025 |

---

## 📂 Project Structure

```
transcendence/
├── apps/
│   ├── backend/          # NestJS API + WebSockets
│   │   ├── src/          # Application source
│   │   ├── prisma/       # Database schema & migrations
│   │   └── test/         # E2E tests
│   └── frontend/         # React + Vite SPA
│       └── src/          # Components, pages, hooks, stores
├── packages/
│   └── shared/           # Shared TypeScript types & DTOs
├── docker/               # Dockerfiles + nginx config
├── docs/                 # Architecture, setup, API docs
├── scripts/              # Utility scripts (doctor, etc.)
├── docker-compose.yml    # Production stack
├── docker-compose.dev.yml # Development stack
├── Makefile              # All project commands
└── .env.example          # Environment template
```

---

## ⌨️ Make Commands

### Daily Workflow

```bash
make                # Full bootstrap (default — Docker only)
make dev            # Start all dev servers (hot reload)
make turn-on        # Start servers + open browser
make turn-off       # Stop everything + free ports
make shell          # Interactive shell in dev container
```

### Quality

```bash
make lint           # Run ESLint on all workspaces
make format         # Run Prettier --write on all workspaces
make prettier       # Check formatting (add FIX=1 to auto-fix)
make typecheck      # TypeScript type checking (no emit)
make audit          # Full audit: ESLint strict + Prettier + pnpm security
make audit PATH=apps/frontend          # Audit a specific workspace
make audit PATH=apps/backend VERBOSE=1 # Full verbose output
```

### Database

```bash
make db-migrate     # Run Prisma migrations
make db-seed        # Seed with sample data
make db-studio      # Open Prisma Studio
make db-reset       # Reset database (drop + migrate + seed)
```

### Testing

```bash
make test           # Run all tests
make test-unit      # Unit tests only
make test-e2e       # E2E tests only
make test-watch     # Tests in watch mode
```

### Docker

```bash
make docker-up      # Start all containers
make docker-down    # Stop all containers
make docker-logs    # Tail all container logs
make docker-clean   # Remove containers + volumes (full reset)
```

### Build & Deploy

```bash
make build          # Production build (all workspaces)
make prod           # Build & start production stack
make clean          # Remove build artifacts
make fclean         # Full clean (artifacts + modules + volumes)
make re             # Full rebuild from scratch
```

### Diagnostics

```bash
make doctor         # Full environment diagnostic
make info           # Show detected environment
make help           # Show all available commands
```

---

## 🔐 Environment Variables

Copy `.env.example` to `.env` and edit:

```env
# Ports
BACKEND_PORT=3000
FRONTEND_PORT=5173
DB_PORT=5432
REDIS_PORT=6379

# Database
POSTGRES_USER=transcendence
POSTGRES_PASSWORD=transcendence
POSTGRES_DB=transcendence

# Auth
JWT_SECRET=change-me-to-a-random-64-char-string
JWT_EXPIRATION=7d

# OAuth 2.0
OAUTH_42_CLIENT_ID=
OAUTH_42_CLIENT_SECRET=
OAUTH_42_CALLBACK_URL=http://localhost:3000/api/auth/42/callback

# App
NODE_ENV=development
CORS_ORIGINS=http://localhost:5173
```

> ⚠️ **Never commit `.env`** — it's in `.gitignore`.

---

## 📚 Documentation

Detailed docs live in separate files to keep this README focused:

| Document | What it covers |
|----------|---------------|
| [CONTRIBUTING.md](CONTRIBUTING.md) | Git flow, branch naming, commit convention, PR process, code standards |
| [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) | Architecture decisions (ADRs), tech stack rationale |
| [docs/SETUP.md](docs/SETUP.md) | Detailed setup guide (Docker, local, Dev Container) |
| [docs/API.md](docs/API.md) | REST API conventions, authentication, endpoints |
| [CODE_OF_CONDUCT.md](CODE_OF_CONDUCT.md) | Team behavior expectations |
| [SECURITY.md](SECURITY.md) | Security policy & vulnerability reporting |
| [CHANGELOG.md](CHANGELOG.md) | Version history & release notes |

---

## 📄 License

[MIT](LICENSE)

---

*Built with ☕ and teamwork by Team Univers42 — 2026.*
