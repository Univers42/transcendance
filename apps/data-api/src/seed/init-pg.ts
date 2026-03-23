/**
 * PostgreSQL seed runner for data-api.
 *
 * On startup, checks if the database is already seeded (by looking for
 * the `users` table). If not found, executes the Model/sql/manager
 * shell scripts to apply schemas and seeds.
 *
 * The Model/ directory is mounted read-only into the container at /app/Model/.
 */
import { pool } from '../db/postgres.js';
import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';

const MODEL_SQL_DIR = process.env.MODEL_SQL_DIR ?? '/app/Model/sql';

/**
 * Check if PostgreSQL schemas are already applied.
 */
async function isSchemaApplied(): Promise<boolean> {
  try {
    const result = await pool.query(`
      SELECT EXISTS (
        SELECT FROM information_schema.tables
        WHERE table_schema = 'public'
        AND table_name = 'users'
      ) AS "exists"
    `);
    return result.rows[0]?.exists === true;
  } catch {
    return false;
  }
}

/**
 * Check if seed data exists (at least one role present).
 */
async function isSeedDataPresent(): Promise<boolean> {
  try {
    const result = await pool.query(`SELECT count(*) AS c FROM roles`);
    return parseInt(result.rows[0]?.c, 10) > 0;
  } catch {
    return false;
  }
}

/**
 * Run a shell script from Model/sql/manager/, passing DATABASE_URL.
 */
function runScript(scriptName: string): void {
  const scriptPath = `${MODEL_SQL_DIR}/manager/${scriptName}`;
  if (!existsSync(scriptPath)) {
    console.warn(`[data-api] Script not found: ${scriptPath} — skipping`);
    return;
  }

  const dbUrl =
    process.env.DATABASE_URL ??
    'postgresql://transcendence:transcendence@db:5432/transcendence';

  console.log(`[data-api] Running ${scriptName}…`);
  execSync(`bash "${scriptPath}" "${dbUrl}"`, {
    cwd: MODEL_SQL_DIR,
    stdio: 'inherit',
    timeout: 120_000,
  });
  console.log(`[data-api] ${scriptName} completed`);
}

/**
 * Initialize PostgreSQL: apply schemas + seeds if the database is empty.
 */
export async function initPostgres(): Promise<void> {
  console.log('[data-api] Checking PostgreSQL state…');

  const schemaReady = await isSchemaApplied();
  if (!schemaReady) {
    console.log('[data-api] No schema found — applying schemas…');
    runScript('apply_schema.sh');
  } else {
    console.log('[data-api] Schema already applied ✓');
  }

  const seedsReady = await isSeedDataPresent();
  if (!seedsReady) {
    console.log('[data-api] No seed data found — running seeds…');
    runScript('apply_seeds.sh');
  } else {
    console.log('[data-api] Seed data present ✓');
  }
}
