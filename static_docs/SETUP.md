# 🖥️ Environment Setup Guide

Detailed setup instructions for every scenario — Docker (recommended), local, and troubleshooting.

---

## Table of Contents

- [Option A: Docker (Recommended)](#option-a-docker-recommended)
- [Option B: Local Development](#option-b-local-development)
- [Option C: VS Code Dev Container](#option-c-vs-code-dev-container)
- [Database Access](#database-access)
- [Troubleshooting](#troubleshooting)

---

## Option A: Docker (Recommended)

**Requirements**: Docker Desktop (macOS/Windows) or Docker Engine + Compose v2 (Linux)

```bash
# 1. Clone
git clone git@github.com:Univers42/ft_transcendence.git
cd ft_transcendence

# 2. Environment
cp .env.example .env
# Edit .env with your values (OAuth keys, JWT secret, etc.)

# 3. Bootstrap everything
make
```

### What Happens Behind the Scenes

```mermaid
sequenceDiagram
    participant You
    participant Make
    participant Docker
    participant Containers

    You->>Make: make
    Make->>Docker: docker compose up -d --build
    Docker->>Containers: Start PostgreSQL 16
    Docker->>Containers: Start Redis 7
    Docker->>Containers: Build dev container (Alpine + Node 22)
    Make->>Containers: pnpm install (backend)
    Make->>Containers: pnpm install (frontend)
    Make->>Containers: prisma generate
    Make->>Containers: prisma migrate deploy
    Make-->>You: ✅ Ready! Frontend :5173, Backend :3000
```

### Daily Development

```bash
# Start your day
make dev                # Start dev servers (hot reload)

# Interactive access
make shell              # Bash inside the container

# Stop when done
make docker-down        # Stop containers (data persists)
```

### Useful Commands Inside the Container

```bash
make shell              # Get inside the container, then:

# Backend
cd apps/backend
pnpm run start:dev       # Start with hot reload
pnpm exec prisma studio  # Visual database browser
pnpm exec prisma migrate dev  # Create a new migration

# Frontend
cd apps/frontend
pnpm run dev             # Start with HMR
```

---

## Option B: Local Development

**Requirements**: Node.js ≥ 22, pnpm ≥ 10, PostgreSQL 16, Redis 7

```bash
# 1. Clone
git clone git@github.com:Univers42/ft_transcendence.git
cd ft_transcendence

# 2. Environment
cp .env.example .env
# Edit DATABASE_URL to point to your local PostgreSQL
# Edit REDIS_URL to point to your local Redis

# 3. Install dependencies
cd apps/backend && pnpm install
cd ../frontend && pnpm install
cd ../../packages/shared && pnpm install

# 4. Database setup
cd apps/backend
pnpm exec prisma generate --schema=prisma/schema.prisma
pnpm exec prisma migrate deploy --schema=prisma/schema.prisma

# 5. Start servers (in separate terminals)
# Terminal 1: Backend
cd apps/backend && pnpm run start:dev

# Terminal 2: Frontend
cd apps/frontend && pnpm run dev
```

---

## Option C: VS Code Dev Container

1. Install the **Dev Containers** extension
2. Open the project folder in VS Code
3. `F1` → `Dev Containers: Reopen in Container`
4. VS Code builds the Docker image and opens the workspace inside

> The `.devcontainer/` configuration will be added in a future update.

---

## Database Access

### Prisma Studio (Visual)

```bash
make db-studio
# Open http://localhost:5555
```

### psql (Command Line)

```bash
# From inside the container
make shell
psql postgresql://transcendence:transcendence@db:5432/transcendence

# From host (if PostgreSQL is exposed)
psql postgresql://transcendence:transcendence@localhost:5432/transcendence
```

### Redis CLI

```bash
# From inside the container
make shell
redis-cli -h redis

# From host
redis-cli -h localhost -p 6379
```

---

## Troubleshooting

### "Port already in use"

```bash
# Find what's using the port
lsof -i :3000    # Backend
lsof -i :5173    # Frontend
lsof -i :5432    # PostgreSQL

# Kill it
kill -9 <PID>

# Or stop all containers and restart
make docker-down
make dev
```

### "Permission denied" on Docker volumes

```bash
# Linux: add your user to the docker group
sudo usermod -aG docker $USER
# Then log out and back in
```

### "Cannot find module" after git pull

```bash
# Rebuild node_modules inside the container
make docker-clean    # Remove volumes
make                 # Rebuild everything
```

### Prisma migration issues

```bash
# Reset the database (WARNING: deletes all data)
make db-reset

# Or manually:
make shell
cd apps/backend
pnpm exec prisma migrate reset --force --schema=prisma/schema.prisma
```

### "ECONNREFUSED" to database

Make sure containers are running:
```bash
docker ps
# You should see: transcendence-db, transcendence-redis, transcendence-dev
```

If not:
```bash
make docker-up
```

---

*If your issue isn't listed here, ask in the team Discord channel.*
