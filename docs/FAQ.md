# ❓ FAQ — Frequently Asked Questions

Comprehensive troubleshooting guide for **ft_transcendence**.
Every question uses a collapsible toggle — click to expand the answer.

> **Tip**: Run `make doctor` at any time for an automated diagnostic of your environment.

---

## 📋 Table of Contents

### 🐳 Docker & Containers
- [Docker daemon is not running](#docker-daemon-is-not-running)
- [docker-compose vs docker compose — which one?](#docker-compose-vs-docker-compose--which-one)
- ["permission denied" when stopping containers (AppArmor)](#permission-denied-when-stopping-containers-apparmor)
- [Container stuck in "Restarting" loop](#container-stuck-in-restarting-loop)
- [Volumes not updating after code change](#volumes-not-updating-after-code-change)
- [How to do a complete clean rebuild?](#how-to-do-a-complete-clean-rebuild)

### 🔌 Ports & Network
- ["Port already in use"](#port-already-in-use)
- [Port conflict with another project](#port-conflict-with-another-project)
- ["ECONNREFUSED" when connecting to database or Redis](#econnrefused-when-connecting-to-database-or-redis)

### 📦 Dependencies (pnpm)
- [Why pnpm instead of npm?](#why-pnpm-instead-of-npm)
- ["Ignored build scripts" warning from pnpm](#ignored-build-scripts-warning-from-pnpm)
- [Peer dependency conflict](#peer-dependency-conflict)
- ["Cannot find module" after git pull](#cannot-find-module-after-git-pull)
- [How to add a new dependency?](#how-to-add-a-new-dependency)
- [pnpm-lock.yaml conflict after merge](#pnpm-lockyaml-conflict-after-merge)

### 🗄️ Database (Prisma / PostgreSQL)
- [Prisma migration fails or is out of sync](#prisma-migration-fails-or-is-out-of-sync)
- [How to reset the database completely?](#how-to-reset-the-database-completely)
- [Prisma Client not generated / types missing](#prisma-client-not-generated--types-missing)
- [Prisma Studio won't open on port 5555](#prisma-studio-wont-open-on-port-5555)

### 🔐 Authentication & Environment
- [OAuth 42 callback not working](#oauth-42-callback-not-working)
- [JWT / session errors after restart](#jwt--session-errors-after-restart)
- [Missing .env variables](#missing-env-variables)

### 🛠️ Development
- [TypeScript compilation errors after update](#typescript-compilation-errors-after-update)
- [Hot reload not working (backend or frontend)](#hot-reload-not-working-backend-or-frontend)
- [How to access the container shell?](#how-to-access-the-container-shell)
- [Makefile target fails silently](#makefile-target-fails-silently)

### 📝 Testing
- [Tests fail with database connection error](#tests-fail-with-database-connection-error)
- [How to run only one test file?](#how-to-run-only-one-test-file)

---

## 🐳 Docker & Containers

<a id="docker-daemon-is-not-running"></a>
<details>
<summary><strong>🔹 Docker daemon is not running</strong></summary>

**Symptom**: `Cannot connect to the Docker daemon` or `Is the docker daemon running?`

**Fix**:

```bash
# Linux (systemd)
sudo systemctl start docker
sudo systemctl enable docker   # auto-start on boot

# Verify
docker info
```

If your user is not in the `docker` group:

```bash
sudo usermod -aG docker $USER
# Log out and back in (or reboot)
```

**42 School machines**: Docker Desktop may need to be launched from the applications menu first.

</details>

---

<a id="docker-compose-vs-docker-compose--which-one"></a>
<details>
<summary><strong>🔹 docker-compose vs docker compose — which one?</strong></summary>

**Short answer**: The Makefile auto-detects whichever you have. No action needed.

**Context**: Docker Compose exists in two forms:

| Version | Command | Install |
|---------|---------|---------|
| v1 (standalone) | `docker-compose` | Separate Python binary |
| v2 (plugin) | `docker compose` | Built into Docker CLI |

Our Makefile tries in this order:
1. `docker compose` (v2 plugin — preferred)
2. `docker-compose` (v1 standalone — works fine)
3. `podman-compose` (Podman alternative)

If none are found, `make doctor` will tell you what to install.

> **42 School**: Most machines have `docker-compose` v1.29.2. This is fully supported.

</details>

---

<a id="permission-denied-when-stopping-containers-apparmor"></a>
<details>
<summary><strong>🔹 "permission denied" when stopping containers (AppArmor)</strong></summary>

**Symptom**: `docker stop` or `docker rm` fails with:

```
Error response from daemon: cannot stop container: permission denied
```

**Cause**: Linux AppArmor security module has stale profiles that block Docker operations.

**Fix**:

```bash
# Remove stale AppArmor profiles
sudo aa-remove-unknown

# Now stop the containers
docker rm -f $(docker ps -aq --filter "name=transcendence")

# Restart Docker (optional but thorough)
sudo systemctl restart docker
```

**Prevention**: The Makefile automatically retries on AppArmor failures — but if it persists, run the fix above.

</details>

---

<a id="container-stuck-in-restarting-loop"></a>
<details>
<summary><strong>🔹 Container stuck in "Restarting" loop</strong></summary>

**Symptom**: `docker ps` shows a container with status `Restarting (1) X seconds ago`.

**Diagnose**:

```bash
# Check why it's crashing
docker logs transcendence-dev --tail 50

# Common reasons:
# - Missing .env variable
# - Port already in use inside the container
# - Database not ready yet
```

**Fix**:

```bash
# Stop everything and rebuild
make docker-down
make docker-clean   # Remove volumes
make                # Full rebuild
```

</details>

---

<a id="volumes-not-updating-after-code-change"></a>
<details>
<summary><strong>🔹 Volumes not updating after code change</strong></summary>

**Symptom**: You edited a file on the host, but the container still runs old code.

**Check**: The `docker-compose.dev.yml` bind-mounts source directories. Changes should appear instantly.

**If not**:

```bash
# 1. Make sure you're editing in the right directory
ls apps/backend/src/   # Verify your file is here

# 2. The dev server may need a manual restart
make docker-restart

# 3. Nuclear option: rebuild
make docker-down && make
```

> `node_modules/` directories are Docker **volumes**, not bind-mounts — they persist independently. If you need to refresh deps, use `make install-backend` or `make install-frontend`.

</details>

---

<a id="how-to-do-a-complete-clean-rebuild"></a>
<details>
<summary><strong>🔹 How to do a complete clean rebuild?</strong></summary>

```bash
# Stop everything, remove volumes and images
make docker-clean

# Rebuild from scratch
make
```

This will:
1. Stop all containers
2. Remove all project volumes (node_modules, pnpm-store, database data)
3. Rebuild the Docker image
4. Install all dependencies fresh
5. Run Prisma generate + migrate

> ⚠️ **Warning**: `docker-clean` deletes the database. Export any data you need first.

</details>

---

## 🔌 Ports & Network

<a id="port-already-in-use"></a>
<details>
<summary><strong>🔹 "Port already in use"</strong></summary>

**Symptom**: `Bind for 0.0.0.0:3000 failed: port is already allocated`

**Fix**:

```bash
# Option 1: Use the Makefile helper
make kill-ports

# Option 2: Manual
lsof -i :3000    # Find the PID
kill -9 <PID>    # Kill it

# Option 3: Change the port in .env
# Edit: BACKEND_PORT=3000 → BACKEND_PORT=3100
```

**Our port scheme** (standard ports):

| Service | Port |
|---------|------|
| Backend API | 3000 |
| Frontend | 5173 |
| Prisma Studio | 5555 |
| PostgreSQL | 5432 |
| Redis | 6379 |
| Mailpit | 8025 |

</details>

---

<a id="port-conflict-with-another-project"></a>
<details>
<summary><strong>🔹 Port conflict with another project</strong></summary>

**Symptom**: Another project running on your machine already uses port 3000, 5173, or 5432.

**We use standard ports** (3000 for the backend, 5173 for the frontend, 5432 for PostgreSQL, etc.). If another project occupies the same port, override it in `.env`:

```env
BACKEND_PORT=3100
FRONTEND_PORT=5174
DB_PORT=5433
REDIS_PORT=6380
```

Then restart:

```bash
make docker-down && make docker-up
```

</details>

---

<a id="econnrefused-when-connecting-to-database-or-redis"></a>
<details>
<summary><strong>🔹 "ECONNREFUSED" when connecting to database or Redis</strong></summary>

**Symptom**: Backend crashes with `ECONNREFUSED 127.0.0.1:5432` or `ECONNREFUSED 127.0.0.1:6379`.

**Cause**: The backend is trying to connect to `localhost` but the database runs in a different container.

**Fix**: Inside Docker, services use container names, not `localhost`:

```env
# ✅ Correct (inside Docker)
DATABASE_URL=postgresql://transcendence:transcendence@db:5432/transcendence
REDIS_URL=redis://redis:6379

# ❌ Wrong (these are for host-machine access)
DATABASE_URL=postgresql://transcendence:transcendence@localhost:5432/transcendence
REDIS_URL=redis://localhost:6379
```

**Also check** that containers are running:

```bash
docker ps --filter "name=transcendence"
# You should see: transcendence-db, transcendence-redis, transcendence-dev
```

</details>

---

## 📦 Dependencies (pnpm)

<a id="why-pnpm-instead-of-npm"></a>
<details>
<summary><strong>🔹 Why pnpm instead of npm?</strong></summary>

We migrated from npm to **pnpm** for these reasons:

| Problem with npm | pnpm solution |
|---|---|
| **Phantom dependencies** — code can `require()` packages it never declared | Strict `node_modules` structure prevents undeclared imports |
| **`--legacy-peer-deps` workaround** — hides real incompatibilities | `strict-peer-dependencies=true` catches conflicts at install time |
| **Disk space** — npm duplicates packages across projects | Content-addressable store shares packages globally |
| **Speed** — npm resolves and downloads serially | pnpm resolves, downloads, and links in parallel |
| **"Invalid Version" arborist bug** — npm 10.9+ crashes on certain lockfiles | pnpm has no such bug |

**pnpm is pre-installed** inside the Docker container via Node.js corepack. You don't need to install it manually.

If you need it locally:

```bash
corepack enable
corepack prepare pnpm@latest --activate
```

</details>

---

<a id="ignored-build-scripts-warning-from-pnpm"></a>
<details>
<summary><strong>🔹 "Ignored build scripts" warning from pnpm</strong></summary>

**Symptom**:

```
Ignored build scripts: @nestjs/core@11.1.14, @scarf/scarf@1.4.0.
Run "pnpm approve-builds" to pick which dependencies should be allowed to run scripts.
```

**Explanation**: pnpm 10 blocks postinstall scripts by default (security feature). We've already approved all necessary ones in each `package.json`:

```json
"pnpm": {
  "onlyBuiltDependencies": [
    "bcrypt", "sharp", "@prisma/client", "@prisma/engines",
    "prisma", "@nestjs/core", "@scarf/scarf"
  ]
}
```

All critical native packages (bcrypt, sharp, prisma, esbuild) are approved. If you still see warnings, a new package with a postinstall script was added — add it to `pnpm.onlyBuiltDependencies` in the relevant `package.json`.

</details>

---

<a id="peer-dependency-conflict"></a>
<details>
<summary><strong>🔹 Peer dependency conflict</strong></summary>

**Symptom**: `pnpm install` fails with:

```
ERR_PNPM_PEER_DEP_ISSUES  Unmet peer dependencies
```

**Why this happens**: Our `.npmrc` enforces `strict-peer-dependencies=true`. This is intentional — we don't want hidden incompatibilities.

**Fix**:

1. **Read the error** — it tells you exactly which package expects which version
2. **Align versions** — bump or pin the conflicting package in `package.json`
3. **Never use `--force`** or `--legacy-peer-deps`** — these hide real bugs

**Example**: If `@nestjs/swagger` expects `@nestjs/common@^11` but you have `@nestjs/common@^10`:

```bash
# Fix: align the version
cd apps/backend
pnpm add @nestjs/common@^11
```

**Check for issues**:

```bash
make doctor   # Section 7: Dependency Health
```

</details>

---

<a id="cannot-find-module-after-git-pull"></a>
<details>
<summary><strong>🔹 "Cannot find module" after git pull</strong></summary>

**Symptom**: TypeScript or runtime error: `Cannot find module '@nestjs/something'`.

**Cause**: A teammate added or updated dependencies, but your `node_modules` volume is stale.

**Fix**:

```bash
# Reinstall inside the container
make install-backend
make install-frontend

# If that doesn't work, clean rebuild
make docker-clean && make
```

> Remember: `node_modules/` is a Docker volume — it persists even when code on disk changes.

</details>

---

<a id="how-to-add-a-new-dependency"></a>
<details>
<summary><strong>🔹 How to add a new dependency?</strong></summary>

```bash
# Get a shell inside the container
make shell

# Backend dependency
cd apps/backend
pnpm add <package-name>          # runtime dependency
pnpm add -D <package-name>       # dev dependency

# Frontend dependency
cd apps/frontend
pnpm add <package-name>

# Shared types package
cd packages/shared
pnpm add -D <package-name>
```

**After adding**, commit both `package.json` AND `pnpm-lock.yaml`:

```bash
git add apps/backend/package.json apps/backend/pnpm-lock.yaml
git commit -m "feat(backend): add <package-name>"
```

</details>

---

<a id="pnpm-lockyaml-conflict-after-merge"></a>
<details>
<summary><strong>🔹 pnpm-lock.yaml conflict after merge</strong></summary>

**Symptom**: Git merge conflict in `pnpm-lock.yaml` with thousands of conflicting lines.

**Fix** — never try to manually resolve a lockfile:

```bash
# Accept either version (doesn't matter which)
git checkout --theirs apps/backend/pnpm-lock.yaml
# Or: git checkout --ours apps/backend/pnpm-lock.yaml

# Then regenerate it cleanly
make shell
cd apps/backend
pnpm install

# Commit the resolved lockfile
git add apps/backend/pnpm-lock.yaml
git commit -m "fix: resolve lockfile conflict"
```

</details>

---

## 🗄️ Database (Prisma / PostgreSQL)

<a id="prisma-migration-fails-or-is-out-of-sync"></a>
<details>
<summary><strong>🔹 Prisma migration fails or is out of sync</strong></summary>

**Symptom**: `prisma migrate deploy` errors with "Migration failed" or "drift detected".

**Fix (safe)**:

```bash
make shell
cd apps/backend

# Check migration status
pnpm exec prisma migrate status

# If drift is detected, create a new migration to fix it
pnpm exec prisma migrate dev --name fix_drift
```

**Fix (nuclear — resets all data)**:

```bash
make db-reset
```

</details>

---

<a id="how-to-reset-the-database-completely"></a>
<details>
<summary><strong>🔹 How to reset the database completely?</strong></summary>

```bash
# Option 1: Prisma reset (drops & recreates tables, runs migrations + seed)
make db-reset

# Option 2: Delete the entire volume (removes PostgreSQL data files)
make docker-down
docker volume rm transcendance_db-data
make docker-up
make db-migrate
```

> ⚠️ Both options **delete all data permanently**.

</details>

---

<a id="prisma-client-not-generated--types-missing"></a>
<details>
<summary><strong>🔹 Prisma Client not generated / types missing</strong></summary>

**Symptom**: TypeScript errors like `Cannot find module '.prisma/client'` or `PrismaClient is not a constructor`.

**Fix**:

```bash
# Inside the container
make shell
cd apps/backend
pnpm exec prisma generate

# Or from the host
make compile
```

> Prisma Client is auto-generated during `make` (bootstrap) and `pnpm install` (via the `@prisma/client` postinstall hook).

</details>

---

<a id="prisma-studio-wont-open-on-port-5555"></a>
<details>
<summary><strong>🔹 Prisma Studio won't open on port 5555</strong></summary>

**Fix**:

```bash
# Make sure the port is free
lsof -i :5555

# Start Prisma Studio
make db-studio
# Opens http://localhost:5555
```

If port 5555 is busy, change `PRISMA_STUDIO_PORT` in `.env`.

</details>

---

## 🔐 Authentication & Environment

<a id="oauth-42-callback-not-working"></a>
<details>
<summary><strong>🔹 OAuth 42 callback not working</strong></summary>

**Symptom**: 42 login redirects to an error page or returns "invalid_grant".

**Checklist**:

1. **42 API app settings** → Redirect URI must match exactly:
   ```
   http://localhost:3000/api/auth/42/callback
   ```
2. **`.env` variables** — must match your 42 API app:
   ```env
   FORTYTWO_CLIENT_ID=u-s4t2...
   FORTYTWO_CLIENT_SECRET=s-s4t2...
   FORTYTWO_CALLBACK_URL=http://localhost:3000/api/auth/42/callback
   ```
3. **Backend is running** — the callback URL points to port 3000 (backend)

</details>

---

<a id="jwt--session-errors-after-restart"></a>
<details>
<summary><strong>🔹 JWT / session errors after restart</strong></summary>

**Symptom**: `JsonWebTokenError: invalid signature` or all users are logged out.

**Cause**: The `JWT_SECRET` in `.env` changed, or the container was rebuilt with a different secret.

**Fix**: Make sure `JWT_SECRET` in `.env` is a stable, random string:

```bash
# Generate a strong secret (run once, save permanently)
openssl rand -base64 48
```

> Never commit your real JWT_SECRET. The `.env.example` has a placeholder.

</details>

---

<a id="missing-env-variables"></a>
<details>
<summary><strong>🔹 Missing .env variables</strong></summary>

**Symptom**: `make` fails with `✗ .env file not found` or backend crashes with `undefined` config values.

**Fix**:

```bash
# Create from template
cp .env.example .env

# Edit with your values
nano .env    # or vim, code, etc.
```

**Required variables**:

| Variable | Description |
|---|---|
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |
| `JWT_SECRET` | Secret for JWT signing |
| `FORTYTWO_CLIENT_ID` | 42 OAuth app ID |
| `FORTYTWO_CLIENT_SECRET` | 42 OAuth app secret |

Run `make doctor` to verify your `.env` is complete.

</details>

---

## 🛠️ Development

<a id="typescript-compilation-errors-after-update"></a>
<details>
<summary><strong>🔹 TypeScript compilation errors after update</strong></summary>

**Symptom**: `pnpm exec tsc --noEmit` shows errors after pulling new code.

**Fix order**:

```bash
# 1. Reinstall deps (lockfile may have changed)
make install-backend
make install-frontend

# 2. Regenerate Prisma types
make shell
cd apps/backend && pnpm exec prisma generate

# 3. Recompile
make compile
```

If errors persist, check that `typescript` versions match across packages:
- Backend: `~5.7.0`
- Frontend: `~5.7.0`
- Shared: `~5.7.0`

</details>

---

<a id="hot-reload-not-working-backend-or-frontend"></a>
<details>
<summary><strong>🔹 Hot reload not working (backend or frontend)</strong></summary>

**Symptom**: You save a file but the dev server doesn't recompile.

**Backend (NestJS)**: Uses `nest start --watch` via `make dev-backend`.

**Frontend (Vite)**: Uses Vite HMR via `make dev-frontend`.

**Common fixes**:

```bash
# 1. Check the dev server is running
docker logs transcendence-dev --tail 20

# 2. File system notifications may be limited
# Inside the container:
cat /proc/sys/fs/inotify/max_user_watches
# If < 65536, increase on the HOST:
echo 65536 | sudo tee /proc/sys/fs/inotify/max_user_watches

# 3. Restart the dev servers
make dev
```

</details>

---

<a id="how-to-access-the-container-shell"></a>
<details>
<summary><strong>🔹 How to access the container shell?</strong></summary>

```bash
# Interactive bash shell inside the dev container
make shell

# You're now inside /app with all tools available:
pnpm --version       # Package manager
node --version       # Runtime
prisma --version     # ORM CLI
psql --version       # PostgreSQL client
redis-cli --version  # Redis client
```

</details>

---

<a id="makefile-target-fails-silently"></a>
<details>
<summary><strong>🔹 Makefile target fails silently</strong></summary>

**Symptom**: Running a `make` command shows no output or a cryptic error.

**Debug**:

```bash
# Run with verbose output
make <target> --trace

# Check make version (we need GNU Make ≥ 4)
make --version

# Common issue: tabs vs spaces
# Makefile rules MUST use tabs (not spaces) for indentation
```

**If a Docker command fails inside Make**:

```bash
# Try running the Docker command directly
docker-compose -f docker-compose.dev.yml exec -T dev sh -c 'your command here'
```

</details>

---

## 📝 Testing

<a id="tests-fail-with-database-connection-error"></a>
<details>
<summary><strong>🔹 Tests fail with database connection error</strong></summary>

**Symptom**: Jest crashes with `Can't reach database server at db:5432`.

**Fix**: Tests run inside the Docker container, so the database container must be up:

```bash
# Make sure everything is running
make docker-up

# Then run tests
make test-unit     # Unit tests
make test-e2e      # End-to-end tests
```

**For isolated test databases**, set `DATABASE_URL` to a test-specific database in your test config.

</details>

---

<a id="how-to-run-only-one-test-file"></a>
<details>
<summary><strong>🔹 How to run only one test file?</strong></summary>

```bash
make shell
cd apps/backend

# Run a specific test file
pnpm exec jest --testPathPattern="user.service.spec"

# Run tests matching a name pattern
pnpm exec jest -t "should create a user"

# Run in watch mode (re-runs on file change)
pnpm run test:watch
```

</details>

---

## 🆘 Still Stuck?

1. Run `make doctor` — it checks Docker, Compose, ports, environment, dependencies, and more
2. Check container logs: `docker logs transcendence-dev --tail 100`
3. Search existing docs: `docs/ARCHITECTURE.md`, `docs/SETUP.md`, `docs/API.md`
4. Ask in the team Discord channel

---

*Last updated: July 2025*
