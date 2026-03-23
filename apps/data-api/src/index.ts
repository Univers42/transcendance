import 'dotenv/config';
import express, { type Express } from 'express';
import cors from 'cors';
import { waitForPostgres } from './db/postgres.js';
import { waitForMongo } from './db/mongo.js';
import { initPostgres } from './seed/init-pg.js';
import { initMongo } from './seed/init-mongo.js';
import { apiRouter } from './routes/index.js';

const app: Express = express();
const PORT = parseInt(process.env.DATA_API_PORT ?? '3001', 10);
const CORS_ORIGIN = process.env.CORS_ORIGINS ?? 'http://localhost:5173';

// ── Middleware ───────────────────────────────────────────
app.use(cors({ origin: CORS_ORIGIN, credentials: true }));
app.use(express.json({ limit: '2mb' }));

// ── Health check ────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ status: 'ok', service: 'data-api', timestamp: new Date().toISOString() });
});

// ── API routes ──────────────────────────────────────────
app.use('/api', apiRouter);

// ── Start ───────────────────────────────────────────────
async function start(): Promise<void> {
  // Wait for databases to be reachable
  await waitForPostgres();
  await waitForMongo();

  // Auto-seed if databases are empty
  await initPostgres();
  await initMongo();

  app.listen(PORT, '0.0.0.0', () => {
    console.log(`[data-api] listening on http://0.0.0.0:${PORT}`);
    console.log(`[data-api] CORS origin: ${CORS_ORIGIN}`);
  });
}

start().catch((err) => {
  console.error('[data-api] Fatal error during startup:', err);
  process.exit(1);
});

export default app;
