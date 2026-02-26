# Database Shell Cheatsheet — PostgreSQL & MongoDB

A hands-on guide for the team to connect, explore, query, and manage both
databases from their shells. Every example uses our local Transcendence
dev setup so you can paste and run immediately.

---

## Table of Contents

1. [Connecting to the Shells](#1-connecting-to-the-shells)
2. [Orientation — Where Am I?](#2-orientation--where-am-i)
3. [Listing & Describing Structure](#3-listing--describing-structure)
4. [Reading Data (SELECT / find)](#4-reading-data)
5. [Filtering & Sorting](#5-filtering--sorting)
6. [Inserting Data](#6-inserting-data)
7. [Updating Data](#7-updating-data)
8. [Deleting Data](#8-deleting-data)
9. [Aggregations & Counting](#9-aggregations--counting)
10. [Joins & Lookups](#10-joins--lookups)
11. [Indexes](#11-indexes)
12. [Users & Permissions](#12-users--permissions)
13. [Import / Export](#13-import--export)
14. [Transactions](#14-transactions)
15. [Useful One-Liners](#15-useful-one-liners)
16. [Quick Reference Card](#16-quick-reference-card)

---

## 1. Connecting to the Shells

### PostgreSQL — `psql`

```bash
# Default local connection (our dev database)
psql postgresql://postgres:postgres@localhost:5432/transcendence

# Shorter form (same thing)
psql -U postgres -d transcendence

# Connect to a remote host
psql -h 192.168.1.50 -p 5432 -U myuser -d mydb

# One-shot command (no interactive shell)
psql -U postgres -d transcendence -c "SELECT count(*) FROM users;"

# One-shot from a file
psql -U postgres -d transcendence -f seeds/05_users.sql
```

### MongoDB — `mongosh`

```bash
# Default local connection (our dev database)
mongosh mongodb://localhost:27017/transcendence

# Shorter form
mongosh --host localhost --port 27017 transcendence

# With authentication
mongosh -u admin -p secret --authenticationDatabase admin transcendence

# One-shot command
mongosh transcendence --eval 'db.users.countDocuments()'

# One-shot from a file
mongosh transcendence --file seeds/seed_mongo.js
```

> **Tip**: Add `--quiet` to `mongosh` to suppress the banner and logo.

---

## 2. Orientation — Where Am I?

### psql

```sql
-- Which database am I connected to?
SELECT current_database();

-- Which user am I?
SELECT current_user;

-- Which server version?
SELECT version();

-- Connection info
\conninfo

-- Switch to another database
\c other_database

-- Quit
\q
```

### mongosh

```javascript
// Which database am I using?
db.getName()         // → "transcendence"

// Which server version?
db.version()

// Server status (uptime, connections, etc.)
db.serverStatus().uptime

// Switch to another database
use other_database

// Show current connection
db.getMongo()

// Quit
.exit
// or Ctrl+C twice
```

---

## 3. Listing & Describing Structure

### psql — Tables, Columns, Schemas

```sql
-- List all tables (public schema)
\dt

-- List all tables with sizes
\dt+

-- List tables matching a pattern
\dt *user*

-- Describe a table (columns, types, nullable)
\d users

-- Describe with indexes, constraints, triggers
\d+ users

-- List all schemas
\dn

-- List all views
\dv

-- List all indexes
\di

-- List all functions
\df

-- List all enums/types
\dT+

-- List foreign keys for a table
\d+ organization_members

-- Raw query: list all tables + row count
SELECT schemaname, tablename
FROM pg_tables
WHERE schemaname = 'public'
ORDER BY tablename;
```

### mongosh — Collections, Fields, Indexes

```javascript
// List all databases
show dbs

// List all collections in current db
show collections
// or
db.getCollectionNames()

// Show a sample document to see the "schema"
db.user_preferences.findOne()

// Pretty-print it
db.user_preferences.findOne({}, { _id: 0 })

// Get all field names from a collection (sample-based)
Object.keys(db.user_preferences.findOne())

// Show indexes
db.user_preferences.getIndexes()

// Collection stats (document count, size, index size)
db.user_preferences.stats()

// Database stats
db.stats()

// List all collections with document counts
db.getCollectionNames().forEach(c => {
  print(c.padEnd(30) + db[c].countDocuments())
})
```

---

## 4. Reading Data

### psql — `SELECT`

```sql
-- Get everything
SELECT * FROM users;

-- Get specific columns
SELECT id, email, display_name, status FROM users;

-- Limit results
SELECT * FROM users LIMIT 5;

-- Offset + Limit (pagination)
SELECT * FROM users ORDER BY created_at DESC LIMIT 10 OFFSET 20;

-- Get one row by primary key
SELECT * FROM users WHERE id = 'a0000000-0000-0000-0000-000000000001';

-- Alias columns
SELECT display_name AS name, email AS "Email Address" FROM users;

-- Distinct values
SELECT DISTINCT status FROM users;

-- Count rows
SELECT count(*) FROM users;

-- Check if a row exists
SELECT EXISTS(SELECT 1 FROM users WHERE email = 'admin@transcendence.dev');

-- NULL checks
SELECT * FROM users WHERE avatar_url IS NOT NULL;
```

### mongosh — `find()`

```javascript
// Get everything
db.user_preferences.find()

// Pretty-print
db.user_preferences.find().pretty()

// Get specific fields (projection: 1 = include, 0 = exclude)
db.user_preferences.find({}, { user_id: 1, theme: 1, locale: 1, _id: 0 })

// Limit results
db.user_preferences.find().limit(5)

// Skip + Limit (pagination)
db.user_preferences.find().skip(20).limit(10)

// Get one document
db.user_preferences.findOne({ user_id: 'a0000000-0000-0000-0000-000000000001' })

// Count documents
db.user_preferences.countDocuments()

// Count with a filter
db.user_preferences.countDocuments({ theme: 'dark' })

// Distinct values
db.user_preferences.distinct('theme')

// Check if a document exists
db.user_preferences.countDocuments({ user_id: 'a0000000-0000-0000-0000-000000000001' }) > 0
```

---

## 5. Filtering & Sorting

### psql — `WHERE` / `ORDER BY`

```sql
-- Equality
SELECT * FROM users WHERE status = 'online';

-- Not equal
SELECT * FROM users WHERE status != 'offline';
SELECT * FROM users WHERE status <> 'offline';   -- same thing

-- Comparison
SELECT * FROM abac_rules WHERE priority >= 50;

-- Pattern matching (LIKE / ILIKE for case-insensitive)
SELECT * FROM users WHERE email LIKE '%@acme-corp.com';
SELECT * FROM users WHERE display_name ILIKE '%alice%';

-- Regex
SELECT * FROM users WHERE email ~ '^admin';

-- IN list
SELECT * FROM users WHERE status IN ('online', 'away');

-- BETWEEN
SELECT * FROM abac_rules WHERE priority BETWEEN 10 AND 50;

-- AND / OR
SELECT * FROM users WHERE is_active = TRUE AND mfa_enabled = TRUE;
SELECT * FROM users WHERE status = 'online' OR status = 'busy';

-- NOT
SELECT * FROM users WHERE NOT is_active;

-- NULL handling
SELECT * FROM users WHERE avatar_url IS NULL;
SELECT * FROM users WHERE avatar_url IS NOT NULL;

-- Sorting (ASC default)
SELECT * FROM users ORDER BY created_at DESC;

-- Multi-column sort
SELECT * FROM abac_rules ORDER BY priority DESC, name ASC;

-- JSON field access (our metadata column)
SELECT name, metadata->>'industry' AS industry
FROM organizations
WHERE metadata->>'size' = 'enterprise';

-- JSON containment
SELECT * FROM organizations
WHERE metadata @> '{"feature_flags":{"sso":true}}';

-- Array containment (for PostgreSQL arrays)
SELECT * FROM abac_rules
WHERE target_actions @> '{read}';
```

### mongosh — Query Operators

```javascript
// Equality
db.user_preferences.find({ theme: 'dark' })

// Not equal
db.user_preferences.find({ theme: { $ne: 'dark' } })

// Comparison: $gt, $gte, $lt, $lte
db.abac_rule_conditions.find({ schema_version: { $gte: 1 } })

// Regex
db.audit_log.find({ action: /^organization/ })
db.audit_log.find({ action: { $regex: 'created', $options: 'i' } })

// IN list
db.user_preferences.find({ theme: { $in: ['dark', 'system'] } })

// NOT IN
db.user_preferences.find({ theme: { $nin: ['light'] } })

// AND (implicit — just add fields)
db.user_preferences.find({ theme: 'dark', density: 'compact' })

// AND (explicit — for multiple conditions on same field)
db.user_preferences.find({
  $and: [
    { font_size: { $ne: 'large' } },
    { font_size: { $ne: 'small' } }
  ]
})

// OR
db.user_preferences.find({
  $or: [{ theme: 'dark' }, { theme: 'system' }]
})

// NOT
db.user_preferences.find({ theme: { $not: { $eq: 'light' } } })

// EXISTS (field presence)
db.user_preferences.find({ accent_color: { $exists: true } })

// Nested field access (dot notation)
db.global_settings.find({ 'security.enforce_mfa': true })

// Array contains a value
db.abac_user_attributes.find({ 'attributes.teams': 'compliance' })

// Array size
db.abac_user_attributes.find({ 'attributes.teams': { $size: 2 } })

// Sorting: 1 = ascending, -1 = descending
db.audit_log.find().sort({ timestamp: -1 })

// Multi-field sort
db.audit_log.find().sort({ organization_id: 1, timestamp: -1 })

// Combine everything
db.audit_log
  .find({ action: /created/, organization_id: 'd0000000-0000-0000-0000-000000000001' })
  .sort({ timestamp: -1 })
  .limit(5)
  .pretty()
```

---

## 6. Inserting Data

### psql — `INSERT`

```sql
-- Insert one row
INSERT INTO users (id, email, username, display_name, password_hash, is_active, status)
VALUES (
  gen_random_uuid(),
  'newuser@example.com',
  'newuser',
  'New User',
  '$2b$10$placeholder',
  TRUE,
  'offline'
);

-- Insert multiple rows
INSERT INTO users (id, email, username, display_name, password_hash, is_active, status)
VALUES
  (gen_random_uuid(), 'one@example.com', 'user_one', 'User One', '$2b$10$x', TRUE, 'offline'),
  (gen_random_uuid(), 'two@example.com', 'user_two', 'User Two', '$2b$10$x', TRUE, 'offline');

-- Insert and return the new row
INSERT INTO users (id, email, username, display_name, password_hash, is_active, status)
VALUES (gen_random_uuid(), 'ret@example.com', 'ret_user', 'Ret User', '$2b$10$x', TRUE, 'online')
RETURNING id, email, created_at;

-- Insert with conflict handling (upsert)
INSERT INTO users (id, email, username, display_name, password_hash, is_active, status)
VALUES (gen_random_uuid(), 'admin@transcendence.dev', 'admin2', 'Admin2', '$2b$10$x', TRUE, 'online')
ON CONFLICT (email) DO NOTHING;                     -- skip if exists

-- Upsert: update on conflict
INSERT INTO users (id, email, username, display_name, password_hash, is_active, status)
VALUES (gen_random_uuid(), 'admin@transcendence.dev', 'admin2', 'Admin2', '$2b$10$x', TRUE, 'online')
ON CONFLICT (email) DO UPDATE SET display_name = EXCLUDED.display_name;
```

### mongosh — `insertOne()` / `insertMany()`

```javascript
// Insert one document
db.user_preferences.insertOne({
  user_id: 'test-0001',
  theme: 'dark',
  font_size: 'medium',
  density: 'comfortable',
  locale: 'en-US',
  timezone: 'UTC',
  created_at: new Date(),
  updated_at: new Date()
})

// Insert many documents
db.user_preferences.insertMany([
  { user_id: 'test-0002', theme: 'light', locale: 'fr-FR' },
  { user_id: 'test-0003', theme: 'system', locale: 'de-DE' }
])

// Upsert (insert if not exists, update if exists)
db.user_preferences.updateOne(
  { user_id: 'test-0001' },              // filter
  { $set: { theme: 'light' } },          // update
  { upsert: true }                        // create if missing
)
```

---

## 7. Updating Data

### psql — `UPDATE`

```sql
-- Update one column
UPDATE users SET status = 'away' WHERE email = 'admin@transcendence.dev';

-- Update multiple columns
UPDATE users
SET status = 'offline', is_active = FALSE
WHERE id = 'a0000000-0000-0000-0000-000000000001';

-- Update with a computed value
UPDATE users SET updated_at = NOW() WHERE id = 'a0000000-0000-0000-0000-000000000001';

-- Update + return old and new values
UPDATE users SET status = 'busy'
WHERE email = 'admin@transcendence.dev'
RETURNING id, email, status;

-- Conditional update (CASE)
UPDATE users SET status = CASE
  WHEN mfa_enabled THEN 'online'
  ELSE 'away'
END;

-- Update JSON field
UPDATE organizations
SET metadata = jsonb_set(metadata, '{feature_flags,beta_dashboards}', 'true')
WHERE slug = 'acme-corp';

-- ⚠️ ALWAYS use WHERE — without it, ALL rows are updated!
```

### mongosh — `updateOne()` / `updateMany()`

```javascript
// Update one field
db.user_preferences.updateOne(
  { user_id: 'a0000000-0000-0000-0000-000000000001' },
  { $set: { theme: 'light' } }
)

// Update multiple fields
db.user_preferences.updateOne(
  { user_id: 'a0000000-0000-0000-0000-000000000001' },
  { $set: { theme: 'system', density: 'spacious', updated_at: new Date() } }
)

// Update many documents at once
db.user_preferences.updateMany(
  { theme: 'dark' },
  { $set: { 'notifications.push_enabled': true } }
)

// Increment a number
db.connection_credentials.updateOne(
  { connection_id: 'conn-acme-pg-001' },
  { $inc: { usage_count: 1 } }
)

// Add to an array
db.abac_user_attributes.updateOne(
  { user_id: 'c0000000-0000-0000-0000-000000000002' },
  { $push: { 'attributes.teams': 'frontend' } }
)

// Remove from an array
db.abac_user_attributes.updateOne(
  { user_id: 'c0000000-0000-0000-0000-000000000002' },
  { $pull: { 'attributes.teams': 'frontend' } }
)

// Rename a field
db.user_preferences.updateMany(
  {},
  { $rename: { 'font_size': 'fontSize' } }
)

// Unset (remove) a field
db.user_preferences.updateOne(
  { user_id: 'test-0001' },
  { $unset: { accent_color: '' } }
)

// Replace entire document (keep _id)
db.user_preferences.replaceOne(
  { user_id: 'test-0001' },
  { user_id: 'test-0001', theme: 'dark', locale: 'en-US' }
)
```

---

## 8. Deleting Data

### psql — `DELETE` / `TRUNCATE`

```sql
-- Delete specific rows
DELETE FROM users WHERE email = 'newuser@example.com';

-- Delete with RETURNING (see what was deleted)
DELETE FROM users WHERE email = 'test@example.com' RETURNING id, email;

-- Delete all rows (keeps table structure)
DELETE FROM users;

-- Truncate (faster, resets sequences)
TRUNCATE TABLE query_cache;

-- Truncate with cascading FK cleanup
TRUNCATE TABLE organizations CASCADE;

-- Drop entire table
DROP TABLE IF EXISTS temp_data;

-- ⚠️ ALWAYS use WHERE with DELETE unless you mean to delete everything!
```

### mongosh — `deleteOne()` / `deleteMany()`

```javascript
// Delete one document
db.user_preferences.deleteOne({ user_id: 'test-0001' })

// Delete many matching documents
db.user_preferences.deleteMany({ user_id: /^test-/ })

// Delete ALL documents (empty filter = match all)
db.query_cache.deleteMany({})

// Drop entire collection (removes indexes too)
db.query_cache.drop()

// Drop entire database
db.dropDatabase()
```

---

## 9. Aggregations & Counting

### psql — `GROUP BY` / Aggregate Functions

```sql
-- Count rows per group
SELECT status, count(*) FROM users GROUP BY status;

-- Count, sum, avg, min, max
SELECT
  count(*) AS total_rules,
  avg(priority) AS avg_priority,
  max(priority) AS max_priority,
  min(priority) AS min_priority
FROM abac_rules;

-- Group by with HAVING (filter groups)
SELECT status, count(*) AS cnt
FROM users
GROUP BY status
HAVING count(*) > 1;

-- Count per organization
SELECT o.name, count(om.user_id) AS member_count
FROM organizations o
LEFT JOIN organization_members om ON o.id = om.organization_id
GROUP BY o.name
ORDER BY member_count DESC;

-- String aggregation
SELECT organization_id, string_agg(name, ', ') AS rule_names
FROM abac_rules
GROUP BY organization_id;

-- Window function: rank users by creation date
SELECT email, created_at,
       ROW_NUMBER() OVER (ORDER BY created_at) AS signup_order
FROM users;

-- Running total
SELECT email, created_at,
       count(*) OVER (ORDER BY created_at) AS cumulative_signups
FROM users;
```

### mongosh — Aggregation Pipeline

```javascript
// Count per group (equivalent of GROUP BY)
db.user_preferences.aggregate([
  { $group: { _id: '$theme', count: { $sum: 1 } } }
])

// Count, avg, min, max
db.abac_rule_conditions.aggregate([
  { $group: {
    _id: '$organization_id',
    total: { $sum: 1 },
    avg_version: { $avg: '$schema_version' }
  }}
])

// Filter before grouping ($match = WHERE)
db.audit_log.aggregate([
  { $match: { action: /created/ } },
  { $group: { _id: '$organization_id', total: { $sum: 1 } } },
  { $sort: { total: -1 } }
])

// Top N per group
db.audit_log.aggregate([
  { $sort: { timestamp: -1 } },
  { $group: {
    _id: '$organization_id',
    latest_action: { $first: '$action' },
    latest_time: { $first: '$timestamp' },
    total: { $sum: 1 }
  }}
])

// Distinct count
db.user_preferences.aggregate([
  { $group: { _id: '$theme' } },
  { $count: 'distinct_themes' }
])

// Unwind arrays (explode array into separate docs)
db.abac_user_attributes.aggregate([
  { $unwind: '$attributes.teams' },
  { $group: { _id: '$attributes.teams', user_count: { $sum: 1 } } },
  { $sort: { user_count: -1 } }
])

// Project (reshape output)
db.user_preferences.aggregate([
  { $project: {
    _id: 0,
    user_id: 1,
    theme: 1,
    locale: 1,
    has_accent: { $cond: [{ $ifNull: ['$accent_color', false] }, true, false] }
  }}
])

// Bucket (histogram-style grouping)
db.abac_user_attributes.aggregate([
  { $bucket: {
    groupBy: '$attributes.clearance_level',
    boundaries: [0, 2, 4, 6],
    default: 'unknown',
    output: { count: { $sum: 1 }, users: { $push: '$user_id' } }
  }}
])
```

---

## 10. Joins & Lookups

### psql — `JOIN`

```sql
-- INNER JOIN: users with their org memberships
SELECT u.display_name, o.name AS org_name
FROM users u
JOIN organization_members om ON u.id = om.user_id
JOIN organizations o ON om.organization_id = o.id;

-- LEFT JOIN: all users, even those without orgs
SELECT u.display_name, o.name AS org_name
FROM users u
LEFT JOIN organization_members om ON u.id = om.user_id
LEFT JOIN organizations o ON om.organization_id = o.id;

-- Multi-table join: full RBAC chain
SELECT
  u.display_name,
  r.name AS role,
  ura.context_type,
  o.name AS org_name
FROM users u
JOIN user_role_assignments ura ON u.id = ura.user_id
JOIN roles r ON ura.role_id = r.id
LEFT JOIN organizations o ON ura.context_id = o.id AND ura.context_type = 'organization';

-- Self-join: find users in the same org
SELECT u1.display_name AS user1, u2.display_name AS user2, o.name
FROM organization_members om1
JOIN organization_members om2 ON om1.organization_id = om2.organization_id
                              AND om1.user_id < om2.user_id
JOIN users u1 ON om1.user_id = u1.id
JOIN users u2 ON om2.user_id = u2.id
JOIN organizations o ON om1.organization_id = o.id;

-- Subquery: users who have at least one role
SELECT display_name, email
FROM users
WHERE id IN (SELECT DISTINCT user_id FROM user_role_assignments);

-- CTE (Common Table Expression) — readable subqueries
WITH org_members AS (
  SELECT organization_id, count(*) AS member_count
  FROM organization_members
  GROUP BY organization_id
)
SELECT o.name, om.member_count
FROM organizations o
JOIN org_members om ON o.id = om.organization_id
ORDER BY om.member_count DESC;
```

### mongosh — `$lookup`

```javascript
// $lookup: join audit_log with user_preferences
db.audit_log.aggregate([
  { $lookup: {
    from: 'user_preferences',
    localField: 'actor_id',
    foreignField: 'user_id',
    as: 'actor_prefs'
  }},
  { $project: {
    action: 1,
    actor_id: 1,
    resource_name: 1,
    actor_theme: { $arrayElemAt: ['$actor_prefs.theme', 0] }
  }},
  { $limit: 5 }
])

// $lookup: ABAC rules with their condition trees
db.abac_rule_conditions.aggregate([
  { $lookup: {
    from: 'abac_user_attributes',
    localField: 'organization_id',
    foreignField: 'organization_id',
    as: 'org_users'
  }},
  { $project: {
    rule_id: 1,
    description: 1,
    user_count: { $size: '$org_users' }
  }}
])

// Multiple stages: filter → lookup → reshape
db.global_settings.aggregate([
  { $match: { 'security.enforce_mfa': true } },
  { $lookup: {
    from: 'abac_user_attributes',
    localField: 'organization_id',
    foreignField: 'organization_id',
    as: 'org_users'
  }},
  { $project: {
    scope_id: 1,
    'branding.app_title': 1,
    mfa_enforced: '$security.enforce_mfa',
    user_count: { $size: '$org_users' }
  }}
])
```

> **Key difference**: SQL does Joins natively and efficiently. MongoDB is
> document-oriented — try to embed related data in documents when possible.
> Use `$lookup` sparingly (it's analogous to a LEFT JOIN).

---

## 11. Indexes

### psql

```sql
-- List all indexes on a table
\di+ users

-- Create an index
CREATE INDEX idx_users_email ON users (email);

-- Create a unique index
CREATE UNIQUE INDEX idx_users_email_unique ON users (email);

-- Create a partial index (only active users)
CREATE INDEX idx_users_active ON users (status) WHERE is_active = TRUE;

-- Create a composite index
CREATE INDEX idx_members_org_user ON organization_members (organization_id, user_id);

-- Create a GIN index on JSONB (for @> containment queries)
CREATE INDEX idx_orgs_metadata ON organizations USING gin (metadata);

-- Drop an index
DROP INDEX IF EXISTS idx_users_email;

-- Check index usage statistics
SELECT indexrelname, idx_scan, idx_tup_read, idx_tup_fetch
FROM pg_stat_user_indexes
WHERE schemaname = 'public'
ORDER BY idx_scan DESC;

-- Find unused indexes
SELECT indexrelname, idx_scan
FROM pg_stat_user_indexes
WHERE idx_scan = 0 AND schemaname = 'public';

-- Explain a query (see if indexes are used)
EXPLAIN ANALYZE SELECT * FROM users WHERE email = 'admin@transcendence.dev';
```

### mongosh

```javascript
// List all indexes on a collection
db.user_preferences.getIndexes()

// Create a single-field index
db.user_preferences.createIndex({ user_id: 1 })

// Create a unique index
db.user_preferences.createIndex({ user_id: 1 }, { unique: true })

// Create a compound index
db.audit_log.createIndex({ organization_id: 1, timestamp: -1 })

// Create a partial index
db.audit_log.createIndex(
  { request_id: 1 },
  { partialFilterExpression: { request_id: { $exists: true } } }
)

// Create a TTL index (auto-delete after expiry)
db.query_cache.createIndex({ expires_at: 1 }, { expireAfterSeconds: 0 })

// Create a text index (full-text search)
db.audit_log.createIndex({ action: 'text', resource_name: 'text' })

// Search with text index
db.audit_log.find({ $text: { $search: 'created organization' } })

// Drop an index
db.user_preferences.dropIndex('user_id_1')

// Drop all indexes except _id
db.user_preferences.dropIndexes()

// Explain a query (see if indexes are used)
db.user_preferences.find({ user_id: 'a0000000-0000-0000-0000-000000000001' }).explain('executionStats')

// Check index sizes
db.user_preferences.stats().indexSizes
```

---

## 12. Users & Permissions

### psql

```sql
-- List all database users/roles
\du

-- Create a new user
CREATE USER app_readonly WITH PASSWORD 'secret123';

-- Grant read-only on all tables
GRANT SELECT ON ALL TABLES IN SCHEMA public TO app_readonly;

-- Grant full access
GRANT ALL PRIVILEGES ON DATABASE transcendence TO app_readonly;

-- Revoke
REVOKE DELETE ON ALL TABLES IN SCHEMA public FROM app_readonly;

-- Change password
ALTER USER app_readonly WITH PASSWORD 'newsecret';

-- Drop a user
DROP USER IF EXISTS app_readonly;

-- See current grants
SELECT grantee, table_name, privilege_type
FROM information_schema.table_privileges
WHERE table_schema = 'public'
ORDER BY grantee, table_name;
```

### mongosh

```javascript
// List all users in current database
db.getUsers()

// Create a read-only user
db.createUser({
  user: 'app_readonly',
  pwd: 'secret123',
  roles: [{ role: 'read', db: 'transcendence' }]
})

// Create a read-write user
db.createUser({
  user: 'app_readwrite',
  pwd: 'secret456',
  roles: [{ role: 'readWrite', db: 'transcendence' }]
})

// Grant additional roles
db.grantRolesToUser('app_readonly', [{ role: 'readWrite', db: 'transcendence' }])

// Revoke roles
db.revokeRolesFromUser('app_readwrite', [{ role: 'readWrite', db: 'transcendence' }])

// Change password
db.changeUserPassword('app_readonly', 'newsecret')

// Drop a user
db.dropUser('app_readonly')

// Built-in roles: read, readWrite, dbAdmin, dbOwner, userAdmin, clusterAdmin, root
```

---

## 13. Import / Export

### psql

```bash
# Export a table to CSV
psql -U postgres -d transcendence \
  -c "\copy users TO '/tmp/users.csv' CSV HEADER"

# Import from CSV
psql -U postgres -d transcendence \
  -c "\copy users FROM '/tmp/users.csv' CSV HEADER"

# Dump entire database (backup)
pg_dump -U postgres transcendence > backup.sql

# Dump specific tables only
pg_dump -U postgres -t users -t organizations transcendence > partial.sql

# Dump data only (no schema)
pg_dump -U postgres --data-only transcendence > data_only.sql

# Dump schema only (no data)
pg_dump -U postgres --schema-only transcendence > schema_only.sql

# Restore from dump
psql -U postgres -d transcendence < backup.sql

# Custom format (compressed, parallel restore)
pg_dump -U postgres -Fc transcendence > backup.dump
pg_restore -U postgres -d transcendence backup.dump
```

### mongosh / mongotools

```bash
# Export a collection to JSON
mongoexport --db transcendence --collection user_preferences --out prefs.json

# Export to CSV
mongoexport --db transcendence --collection user_preferences \
  --type=csv --fields user_id,theme,locale --out prefs.csv

# Import from JSON
mongoimport --db transcendence --collection user_preferences --file prefs.json

# Import from CSV
mongoimport --db transcendence --collection user_preferences \
  --type=csv --headerline --file prefs.csv

# Dump entire database (binary — BSON)
mongodump --db transcendence --out /tmp/mongodump/

# Dump a single collection
mongodump --db transcendence --collection audit_log --out /tmp/mongodump/

# Restore from dump
mongorestore --db transcendence /tmp/mongodump/transcendence/

# Restore a single collection
mongorestore --db transcendence --collection audit_log \
  /tmp/mongodump/transcendence/audit_log.bson
```

---

## 14. Transactions

### psql

```sql
-- Start a transaction
BEGIN;

-- Do work
INSERT INTO users (id, email, username, display_name, password_hash, is_active, status)
VALUES (gen_random_uuid(), 'tx@test.com', 'tx_user', 'TX User', '$2b$10$x', TRUE, 'online');

UPDATE organizations SET name = 'Updated Name' WHERE slug = 'acme-corp';

-- Check your work before committing
SELECT * FROM users WHERE email = 'tx@test.com';

-- Happy? Commit.
COMMIT;

-- Not happy? Rollback instead.
-- ROLLBACK;

-- Savepoints (partial rollback)
BEGIN;
  INSERT INTO users (id, email, username, display_name, password_hash, is_active, status)
  VALUES (gen_random_uuid(), 'save@test.com', 'save_user', 'Save User', '$2b$10$x', TRUE, 'online');

  SAVEPOINT my_savepoint;

  DELETE FROM organizations WHERE slug = 'acme-corp';  -- oops

  ROLLBACK TO my_savepoint;  -- undo the delete, keep the insert

COMMIT;
```

### mongosh

```javascript
// Start a session + transaction
const session = db.getMongo().startSession()
session.startTransaction()

try {
  // Do work within the session
  db.user_preferences.insertOne(
    { user_id: 'tx-001', theme: 'dark' },
    { session }
  )

  db.audit_log.insertOne(
    { actor_id: 'tx-001', action: 'test.created', timestamp: new Date() },
    { session }
  )

  // Happy? Commit.
  session.commitTransaction()
  print('Transaction committed.')
} catch (e) {
  // Error? Abort.
  session.abortTransaction()
  print('Transaction aborted: ' + e.message)
} finally {
  session.endSession()
}

// ⚠️ MongoDB transactions require a replica set.
// Standalone mongod does NOT support multi-document transactions.
// For local dev, start mongod with: mongod --replSet rs0
// Then initialize: rs.initiate()
```

---

## 15. Useful One-Liners

### psql Power Moves

```sql
-- Table sizes
SELECT relname AS table, pg_size_pretty(pg_total_relation_size(relid)) AS size
FROM pg_catalog.pg_statio_user_tables
ORDER BY pg_total_relation_size(relid) DESC;

-- Row counts for all tables
SELECT schemaname, relname, n_live_tup AS row_count
FROM pg_stat_user_tables
ORDER BY n_live_tup DESC;

-- Currently running queries
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state = 'active';

-- Kill a stuck query
SELECT pg_cancel_backend(pid);    -- graceful
SELECT pg_terminate_backend(pid); -- force

-- Find duplicate values
SELECT email, count(*) FROM users GROUP BY email HAVING count(*) > 1;

-- Generate a UUID
SELECT gen_random_uuid();

-- Current time
SELECT NOW();

-- Formatted output modes in psql
\x           -- Toggle expanded (vertical) display
\x auto      -- Auto-expand for wide tables
\timing      -- Toggle query timing
\pset format wrapped    -- Wrap long lines
\pset null '(null)'     -- Show nulls explicitly

-- Save query output to a file
\o /tmp/output.txt
SELECT * FROM users;
\o                  -- stop saving

-- Execute a shell command from psql
\! ls -la

-- Edit a query in your $EDITOR
\e

-- History
\s
```

### mongosh Power Moves

```javascript
// Collection sizes
db.getCollectionNames().forEach(c => {
  const s = db[c].stats()
  print(c.padEnd(30) + (s.size / 1024).toFixed(1) + ' KB  (' + s.count + ' docs)')
})

// Find documents modified in the last hour
db.audit_log.find({ timestamp: { $gte: new Date(Date.now() - 3600000) } })

// Get all unique values for a field
db.audit_log.distinct('action')

// Pretty-print one doc as JSON
printjson(db.abac_rule_conditions.findOne())

// Convert dates for display
db.audit_log.find().forEach(doc => {
  print(doc.timestamp.toISOString() + ' | ' + doc.action + ' | ' + doc.resource_name)
})

// Performance profiling — enable slow query log
db.setProfilingLevel(1, { slowms: 100 })  // log queries > 100ms
db.system.profile.find().sort({ ts: -1 }).limit(5)
db.setProfilingLevel(0) // disable

// Server metrics
db.serverStatus().opcounters   // insert/query/update/delete counts
db.serverStatus().connections  // active connections

// Show current operations
db.currentOp()

// Kill an operation
db.killOp(opId)

// Generate an ObjectId
new ObjectId()

// Current time
new Date()

// Command history
// Press ↑/↓ arrows, or Ctrl+R to search

// Run a .js file
load('/path/to/script.js')

// Multi-line editing: just press Enter, mongosh auto-detects incomplete expressions
```

---

## 16. Quick Reference Card

| Task | PostgreSQL (`psql`) | MongoDB (`mongosh`) |
|------|-------------------|-------------------|
| **Connect** | `psql -U postgres -d transcendence` | `mongosh transcendence` |
| **List databases** | `\l` | `show dbs` |
| **List tables/collections** | `\dt` | `show collections` |
| **Describe table** | `\d users` | `db.users.findOne()` |
| **Select all** | `SELECT * FROM users;` | `db.users.find()` |
| **Select with filter** | `WHERE status = 'online'` | `.find({ status: 'online' })` |
| **Select fields** | `SELECT id, email FROM …` | `.find({}, { id: 1, email: 1 })` |
| **Sort** | `ORDER BY created_at DESC` | `.sort({ created_at: -1 })` |
| **Limit** | `LIMIT 10` | `.limit(10)` |
| **Count** | `SELECT count(*) FROM users` | `db.users.countDocuments()` |
| **Distinct** | `SELECT DISTINCT status…` | `db.users.distinct('status')` |
| **Insert** | `INSERT INTO … VALUES …` | `db.users.insertOne({…})` |
| **Update** | `UPDATE users SET … WHERE …` | `db.users.updateOne({…}, {$set:{…}})` |
| **Delete** | `DELETE FROM users WHERE …` | `db.users.deleteOne({…})` |
| **Drop table** | `DROP TABLE users;` | `db.users.drop()` |
| **Join** | `JOIN … ON …` | `$lookup` in aggregation |
| **Group by** | `GROUP BY status` | `$group: { _id: '$status' }` |
| **Index create** | `CREATE INDEX idx ON …` | `db.coll.createIndex({…})` |
| **Index list** | `\di` | `db.coll.getIndexes()` |
| **Explain** | `EXPLAIN ANALYZE …` | `.explain('executionStats')` |
| **Transaction** | `BEGIN; … COMMIT;` | `session.startTransaction()` |
| **Export** | `\copy … TO CSV` | `mongoexport --out …` |
| **Backup** | `pg_dump` | `mongodump` |
| **Quit** | `\q` | `.exit` |

---

## Transcendence-Specific Queries

### Explore our RBAC system (psql)

```sql
-- Who has what role?
SELECT u.display_name, r.name AS role, ura.context_type, o.name AS org
FROM user_role_assignments ura
JOIN users u ON ura.user_id = u.id
JOIN roles r ON ura.role_id = r.id
LEFT JOIN organizations o ON ura.context_id = o.id
ORDER BY u.display_name;

-- What permissions does a role have?
SELECT r.name, p.resource_type, p.action
FROM roles r
JOIN role_permissions rp ON r.id = rp.role_id
JOIN permissions p ON rp.permission_id = p.id
WHERE r.name = 'org_owner'
ORDER BY p.resource_type, p.action;

-- ABAC policies for an organization
SELECT ap.name, ap.effect, ap.priority, ap.is_active
FROM abac_policies ap
WHERE ap.organization_id = 'd0000000-0000-0000-0000-000000000001'
ORDER BY ap.priority DESC;
```

### Explore our ABAC conditions (mongosh)

```javascript
// All ABAC rule conditions for Acme Corp
db.abac_rule_conditions.find(
  { organization_id: 'd0000000-0000-0000-0000-000000000001' },
  { rule_id: 1, description: 1, 'condition_tree.operator': 1, _id: 0 }
)

// User attributes for Globex Inc members
db.abac_user_attributes.find(
  { organization_id: 'd0000000-0000-0000-0000-000000000002' },
  { user_id: 1, 'attributes.department': 1, 'attributes.clearance_level': 1, _id: 0 }
)

// Recent audit log across all orgs
db.audit_log.find({}, { action: 1, resource_name: 1, timestamp: 1, _id: 0 })
  .sort({ timestamp: -1 })
  .limit(10)
  .pretty()

// Settings for orgs with MFA enforced
db.global_settings.find(
  { 'security.enforce_mfa': true },
  { 'branding.app_title': 1, 'security.session_timeout_minutes': 1, _id: 0 }
)
```

---

## Keyboard Shortcuts

### psql

| Shortcut | Action |
|----------|--------|
| `Ctrl+L` | Clear screen |
| `Ctrl+R` | Reverse search history |
| `↑ / ↓` | Navigate history |
| `Ctrl+C` | Cancel current query |
| `Ctrl+D` | Quit (same as `\q`) |
| `\e` | Open query in `$EDITOR` |
| `\i file.sql` | Execute a SQL file |
| `\?` | Help for backslash commands |
| `\h SELECT` | Help for SQL commands |

### mongosh

| Shortcut | Action |
|----------|--------|
| `Ctrl+L` | Clear screen |
| `Ctrl+R` | Reverse search history |
| `↑ / ↓` | Navigate history |
| `Ctrl+C` | Cancel / clear line |
| `Ctrl+D` | Quit |
| `Tab` | Autocomplete |
| `.help` | Built-in help |
| `.editor` | Multi-line editor mode |
| `load('f.js')` | Execute a JS file |

---

> **Remember**: Our Makefile has shortcuts too!
> ```bash
> cd Model/sql
> make help              # see all targets
> make query Q=users     # quick user list
> make query Q=rbac      # RBAC assignments
> make query Q=hierarchy # full org tree
> make mongo-verify      # check MongoDB health
> ```
