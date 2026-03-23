/**
 * PostgreSQL connection pool for data-api.
 *
 * Reads DATABASE_URL from environment (set in docker-compose.dev.yml).
 * Exports a shared pg.Pool used by all route handlers.
 */
import pg from 'pg';

const DATABASE_URL =
  process.env.DATABASE_URL ??
  'postgresql://transcendence:transcendence@db:5432/transcendence';

export const pool = new pg.Pool({
  connectionString: DATABASE_URL,
  max: 20,
  idleTimeoutMillis: 30_000,
  connectionTimeoutMillis: 5_000,
});

pool.on('error', (err) => {
  console.error('[data-api] PostgreSQL pool error:', err.message);
});

/**
 * Wait for PG to be reachable (up to ~30 s).
 * Docker healthcheck usually handles this, but just in case.
 */
export async function waitForPostgres(retries = 10, delayMs = 3000): Promise<void> {
  for (let i = 1; i <= retries; i++) {
    try {
      const client = await pool.connect();
      client.release();
      console.log('[data-api] PostgreSQL connected');
      return;
    } catch {
      console.log(`[data-api] PG not ready (${i}/${retries}), retrying in ${delayMs}ms…`);
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
  throw new Error('[data-api] Could not connect to PostgreSQL');
}
