#!/usr/bin/env bash
# ============================================================================
# mongo_verify.sh — Verify MongoDB collections, indexes, and document counts
# ============================================================================
# Runs a comprehensive check on all expected MongoDB collections:
#   - Collection existence
#   - Document counts
#   - Index verification
#   - Cross-reference checks (ABAC rule_ids, user_ids, etc.)
#
# Usage: ./manager/mongo_verify.sh [MONGODB_URL] [DATABASE_NAME]
# ============================================================================
set -euo pipefail

MONGO_URL="${1:-${MONGODB_URL:-mongodb://localhost:27017}}"
MONGO_DB="${2:-${MONGODB_DB:-transcendence}}"

echo "════════════════════════════════════════════════════════════════"
echo "  MONGODB VERIFY — Integrity Check"
echo "════════════════════════════════════════════════════════════════"
echo "  Target: $MONGO_URL/$MONGO_DB"
echo "════════════════════════════════════════════════════════════════"
echo ""

mongosh "$MONGO_URL/$MONGO_DB" --quiet --eval '
const EXPECTED_COLLECTIONS = [
  "collection_records",
  "dashboard_layouts",
  "view_configs",
  "user_preferences",
  "query_cache",
  "workflow_definitions",
  "workflow_executions",
  "global_settings",
  "audit_log",
  "sync_state",
  "connection_credentials",
  "abac_rule_conditions",
  "abac_user_attributes",
];

let errors = 0;
let warnings = 0;

function pass(msg) { print("  ✓ " + msg); }
function fail(msg) { print("  ✗ " + msg); errors++; }
function warn(msg) { print("  ⚠ " + msg); warnings++; }

// ── 1. Collection existence ──
print("── Collection Existence ──");
const existing = db.getCollectionNames();
for (const name of EXPECTED_COLLECTIONS) {
  if (existing.includes(name)) {
    pass(name);
  } else {
    fail(name + " — MISSING");
  }
}

// ── 2. Document counts ──
print("");
print("── Document Counts ──");
let totalDocs = 0;
for (const name of EXPECTED_COLLECTIONS) {
  if (!existing.includes(name)) continue;
  const cnt = db[name].countDocuments();
  totalDocs += cnt;
  if (cnt > 0) {
    pass(name.padEnd(28) + cnt + " documents");
  } else {
    warn(name.padEnd(28) + "0 documents (empty)");
  }
}
print("  Total: " + totalDocs + " documents across " + EXPECTED_COLLECTIONS.length + " collections");

// ── 3. Index verification ──
print("");
print("── Index Counts ──");
let totalIdx = 0;
for (const name of EXPECTED_COLLECTIONS) {
  if (!existing.includes(name)) continue;
  const idxs = db[name].getIndexes();
  totalIdx += idxs.length;
  const customIdx = idxs.length - 1; // minus _id index
  if (customIdx > 0) {
    pass(name.padEnd(28) + customIdx + " custom indexes (+ _id)");
  } else if (customIdx === 0) {
    warn(name.padEnd(28) + "no custom indexes");
  }
}

// ── 4. Data integrity checks ──
print("");
print("── Data Integrity ──");

// Check ABAC rule conditions have matching rule_ids
if (existing.includes("abac_rule_conditions")) {
  const rcCount = db.abac_rule_conditions.countDocuments();
  const uniqueRules = db.abac_rule_conditions.distinct("rule_id").length;
  if (rcCount === uniqueRules) {
    pass("ABAC rule conditions: " + rcCount + " unique rule_ids (no dupes)");
  } else {
    fail("ABAC rule conditions: " + rcCount + " docs but " + uniqueRules + " unique rule_ids");
  }

  // Check all have condition_tree
  const noTree = db.abac_rule_conditions.countDocuments({ condition_tree: { $exists: false } });
  if (noTree === 0) {
    pass("ABAC rule conditions: all have condition_tree");
  } else {
    fail("ABAC rule conditions: " + noTree + " missing condition_tree");
  }
}

// Check ABAC user attributes unique constraint
if (existing.includes("abac_user_attributes")) {
  const uaCount = db.abac_user_attributes.countDocuments();
  const pipeline = [
    { $group: { _id: { user_id: "$user_id", organization_id: "$organization_id" }, cnt: { $sum: 1 } } },
    { $match: { cnt: { $gt: 1 } } },
  ];
  const dupes = db.abac_user_attributes.aggregate(pipeline).toArray();
  if (dupes.length === 0) {
    pass("ABAC user attributes: " + uaCount + " docs, no duplicate (user_id, org_id) pairs");
  } else {
    fail("ABAC user attributes: " + dupes.length + " duplicate (user_id, org_id) pairs");
  }
}

// Check user_preferences unique user_ids
if (existing.includes("user_preferences")) {
  const upCount = db.user_preferences.countDocuments();
  const uniqueUsers = db.user_preferences.distinct("user_id").length;
  if (upCount === uniqueUsers) {
    pass("User preferences: " + upCount + " unique user_ids");
  } else {
    fail("User preferences: " + upCount + " docs but " + uniqueUsers + " unique user_ids");
  }
}

// Check global_settings unique scopes
if (existing.includes("global_settings")) {
  const gsCount = db.global_settings.countDocuments();
  const pipeline = [
    { $group: { _id: { scope_type: "$scope_type", scope_id: "$scope_id" }, cnt: { $sum: 1 } } },
    { $match: { cnt: { $gt: 1 } } },
  ];
  const dupes = db.global_settings.aggregate(pipeline).toArray();
  if (dupes.length === 0) {
    pass("Global settings: " + gsCount + " docs, no duplicate scopes");
  } else {
    fail("Global settings: " + dupes.length + " duplicate scopes");
  }
}

// ── 5. Summary ──
print("");
print("════════════════════════════════════════════════════════════════");
if (errors === 0) {
  print("  ✓ VERIFICATION PASSED — " + totalDocs + " docs, " + totalIdx + " indexes, 0 errors");
} else {
  print("  ✗ VERIFICATION FAILED — " + errors + " errors, " + warnings + " warnings");
}
if (warnings > 0 && errors === 0) {
  print("    (" + warnings + " warnings — review above)");
}
print("════════════════════════════════════════════════════════════════");
' 2>&1

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo "✗ MongoDB verification failed (exit code $EXIT_CODE)"
    exit 1
fi
