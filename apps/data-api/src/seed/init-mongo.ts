/**
 * MongoDB seed runner for data-api.
 *
 * On startup, checks if the `collection_records` collection exists and has
 * documents. If empty, runs the Model/sql/manager shell scripts for
 * MongoDB setup (collections + indexes) and seeding.
 *
 * The scripts use `mongosh` which must be available in the container.
 * The Model/ directory is mounted read-only at /app/Model/.
 */
import { getDb } from '../db/mongo.js';
import { execSync } from 'node:child_process';
import { existsSync } from 'node:fs';

const MODEL_SQL_DIR = process.env.MODEL_SQL_DIR ?? '/app/Model/sql';
const MONGO_URL = process.env.MONGO_URL ?? 'mongodb://mongo:27017/transcendence';

/**
 * Extract the MONGO_HOST:PORT and DB_NAME from MONGO_URL for shell scripts.
 * Scripts expect: MONGODB_URL (without db name) and MONGODB_DB separately.
 */
function parseMongoUrl(): { baseUrl: string; dbName: string } {
  try {
    const url = new URL(MONGO_URL);
    const dbName = url.pathname.replace('/', '') || 'transcendence';
    url.pathname = '/';
    return { baseUrl: url.toString().replace(/\/$/, ''), dbName };
  } catch {
    return { baseUrl: 'mongodb://mongo:27017', dbName: 'transcendence' };
  }
}

/**
 * Check if MongoDB collections are already set up.
 */
async function isMongoSetup(): Promise<boolean> {
  try {
    const db = getDb();
    const collections = await db.listCollections({ name: 'collection_records' }).toArray();
    return collections.length > 0;
  } catch {
    return false;
  }
}

/**
 * Check if MongoDB has seed data.
 */
async function isMongoSeeded(): Promise<boolean> {
  try {
    const db = getDb();
    const count = await db.collection('collection_records').countDocuments();
    return count > 0;
  } catch {
    return false;
  }
}

/**
 * Run a MongoDB manager shell script.
 */
function runMongoScript(scriptName: string): void {
  const scriptPath = `${MODEL_SQL_DIR}/manager/${scriptName}`;
  if (!existsSync(scriptPath)) {
    console.warn(`[data-api] Script not found: ${scriptPath} — skipping`);
    return;
  }

  const { baseUrl, dbName } = parseMongoUrl();

  console.log(`[data-api] Running ${scriptName}…`);
  execSync(`bash "${scriptPath}" "${baseUrl}" "${dbName}"`, {
    cwd: MODEL_SQL_DIR,
    stdio: 'inherit',
    timeout: 120_000,
  });
  console.log(`[data-api] ${scriptName} completed`);
}

/**
 * Initialize MongoDB: create collections + indexes and seed if empty.
 */
export async function initMongo(): Promise<void> {
  console.log('[data-api] Checking MongoDB state…');

  const setupDone = await isMongoSetup();
  if (!setupDone) {
    console.log('[data-api] Collections not found — running mongo_setup.sh…');
    runMongoScript('mongo_setup.sh');
  } else {
    console.log('[data-api] MongoDB collections exist ✓');
  }

  const seeded = await isMongoSeeded();
  if (!seeded) {
    console.log('[data-api] No seed data — running mongo_seed.sh…');
    runMongoScript('mongo_seed.sh');
  } else {
    console.log('[data-api] MongoDB seed data present ✓');
  }
}
