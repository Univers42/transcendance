# ============================================
# data-api — Lightweight REST service
# ============================================
# Multi-stage build: install deps, compile TS, run slim.

# ── Stage 1: Install + Build ────────────────
FROM node:25-alpine AS builder

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --frozen-lockfile 2>/dev/null || pnpm install

COPY tsconfig.json ./
COPY src/ ./src/

RUN pnpm run build

# ── Stage 2: Production ─────────────────────
FROM node:25-alpine AS production

RUN corepack enable && corepack prepare pnpm@latest --activate

WORKDIR /app

COPY package.json pnpm-lock.yaml* ./
RUN pnpm install --prod --frozen-lockfile 2>/dev/null || pnpm install --prod

COPY --from=builder /app/dist ./dist

ENV NODE_ENV=production
ENV DATA_API_PORT=3001

EXPOSE 3001

HEALTHCHECK --interval=10s --timeout=3s --retries=5 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:3001/health || exit 1

CMD ["node", "dist/index.js"]
