/**
 * MongoDB connection for data-api.
 *
 * Reads MONGO_URL from environment (set in docker-compose.dev.yml).
 * Exports a shared MongoClient and database reference.
 */
import { MongoClient, type Db } from 'mongodb';

const MONGO_URL =
  process.env.MONGO_URL ?? 'mongodb://mongo:27017/transcendence';

const client = new MongoClient(MONGO_URL, {
  maxPoolSize: 20,
  connectTimeoutMS: 5_000,
  serverSelectionTimeoutMS: 5_000,
});

let _db: Db | null = null;

/**
 * Get the connected database instance.
 */
export function getDb(): Db {
  if (!_db) {
    throw new Error('[data-api] MongoDB not connected — call waitForMongo() first');
  }
  return _db;
}

/**
 * Get the MongoClient instance.
 */
export function getClient(): MongoClient {
  return client;
}

/**
 * Wait for MongoDB to be reachable (up to ~30 s).
 */
export async function waitForMongo(retries = 10, delayMs = 3000): Promise<void> {
  for (let i = 1; i <= retries; i++) {
    try {
      await client.connect();
      // Extract database name from connection string
      const dbName = new URL(MONGO_URL).pathname.replace('/', '') || 'transcendence';
      _db = client.db(dbName);
      await _db.command({ ping: 1 });
      console.log(`[data-api] MongoDB connected (db: ${dbName})`);
      return;
    } catch {
      console.log(`[data-api] Mongo not ready (${i}/${retries}), retrying in ${delayMs}ms…`);
      await new Promise((r) => setTimeout(r, delayMs));
    }
  }
  throw new Error('[data-api] Could not connect to MongoDB');
}
