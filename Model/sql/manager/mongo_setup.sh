#!/usr/bin/env bash
# ============================================================================
# mongo_setup.sh — Initialize MongoDB collections, indexes, and validation
# ============================================================================
# Creates all collections with schema validation and indexes that match
# the Mongoose schemas defined in Model/nosql/*.ts.
#
# This is the MongoDB equivalent of apply_schema.sh for PostgreSQL.
#
# Usage: ./manager/mongo_setup.sh [MONGODB_URL] [DATABASE_NAME]
# ============================================================================
set -euo pipefail

MONGO_URL="${1:-${MONGODB_URL:-mongodb://localhost:27017}}"
MONGO_DB="${2:-${MONGODB_DB:-transcendence}}"
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"

echo "════════════════════════════════════════════════════════════════"
echo "  MONGODB SETUP — Collections & Indexes"
echo "════════════════════════════════════════════════════════════════"
echo "  Target: $MONGO_URL/$MONGO_DB"
echo "════════════════════════════════════════════════════════════════"
echo ""

# ── Create collections with optional schema validation ──
mongosh "$MONGO_URL/$MONGO_DB" --quiet --eval '
// ────────────────────────────────────────────────────────────────────────
//  COLLECTION CREATION (idempotent — skips if already exists)
// ────────────────────────────────────────────────────────────────────────

const collections = [
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

const existing = db.getCollectionNames();
let created = 0;
let skipped = 0;

for (const name of collections) {
  if (existing.includes(name)) {
    print("  SKIP  " + name + " (already exists)");
    skipped++;
  } else {
    db.createCollection(name);
    print("  OK    " + name);
    created++;
  }
}

print("");
print("Collections: " + created + " created, " + skipped + " skipped");

// ────────────────────────────────────────────────────────────────────────
//  INDEXES (idempotent — createIndex is a no-op if index already exists)
// ────────────────────────────────────────────────────────────────────────

print("");
print("── Creating indexes ──");
let idxCount = 0;

function idx(col, keys, opts) {
  try {
    db[col].createIndex(keys, opts || {});
    idxCount++;
  } catch (e) {
    print("  WARN  " + col + " index " + (opts?.name || JSON.stringify(keys)) + ": " + e.message);
  }
}

// ── collection_records ──
idx("collection_records", { collection_id: 1, is_deleted: 1, created_at: -1 }, { name: "idx_collection_records_main" });
idx("collection_records", { organization_id: 1, collection_id: 1 }, { name: "idx_collection_records_org" });
idx("collection_records", { workspace_id: 1, collection_id: 1 }, { name: "idx_collection_records_workspace" });
idx("collection_records", { is_deleted: 1, deleted_at: 1 }, { name: "idx_collection_records_deleted", partialFilterExpression: { is_deleted: true } });

// ── dashboard_layouts ──
idx("dashboard_layouts", { dashboard_id: 1, scope: 1, owner_id: 1 }, { name: "idx_layout_lookup", unique: true });
idx("dashboard_layouts", { owner_id: 1, scope: 1 }, { name: "idx_layout_user", partialFilterExpression: { scope: "personal" } });
idx("dashboard_layouts", { workspace_id: 1, scope: 1 }, { name: "idx_layout_workspace" });
idx("dashboard_layouts", { organization_id: 1 }, { name: "idx_layout_org" });

// ── view_configs ──
idx("view_configs", { view_id: 1, scope: 1, owner_id: 1 }, { name: "idx_view_config_lookup", unique: true });
idx("view_configs", { owner_id: 1, scope: 1 }, { name: "idx_view_config_user", partialFilterExpression: { scope: "personal" } });
idx("view_configs", { collection_id: 1 }, { name: "idx_view_config_collection" });
idx("view_configs", { workspace_id: 1 }, { name: "idx_view_config_workspace" });

// ── user_preferences ──
idx("user_preferences", { user_id: 1 }, { name: "idx_user_preferences_user", unique: true });

// ── query_cache ──
idx("query_cache", { cache_key: 1 }, { name: "idx_query_cache_key", unique: true });
idx("query_cache", { expires_at: 1 }, { name: "idx_query_cache_ttl", expireAfterSeconds: 0 });
idx("query_cache", { collection_id: 1 }, { name: "idx_query_cache_collection" });
idx("query_cache", { workspace_id: 1 }, { name: "idx_query_cache_workspace" });
idx("query_cache", { widget_id: 1 }, { name: "idx_query_cache_widget", partialFilterExpression: { widget_id: { $exists: true } } });

// ── workflow_definitions ──
idx("workflow_definitions", { organization_id: 1, is_active: 1 }, { name: "idx_workflow_def_org" });
idx("workflow_definitions", { "trigger.type": 1, "trigger.collection_id": 1 }, { name: "idx_workflow_def_trigger" });

// ── workflow_executions ──
idx("workflow_executions", { workflow_id: 1, started_at: -1 }, { name: "idx_workflow_exec_workflow" });
idx("workflow_executions", { organization_id: 1, status: 1 }, { name: "idx_workflow_exec_status" });
idx("workflow_executions", { status: 1, started_at: 1 }, { name: "idx_workflow_exec_running", partialFilterExpression: { status: { $in: ["pending", "running"] } } });

// ── global_settings ──
idx("global_settings", { scope_type: 1, scope_id: 1 }, { name: "idx_global_settings_scope", unique: true });
idx("global_settings", { organization_id: 1, scope_type: 1 }, { name: "idx_global_settings_org" });

// ── audit_log ──
idx("audit_log", { organization_id: 1, timestamp: -1 }, { name: "idx_audit_org_time" });
idx("audit_log", { workspace_id: 1, timestamp: -1 }, { name: "idx_audit_workspace_time" });
idx("audit_log", { actor_id: 1, timestamp: -1 }, { name: "idx_audit_actor_time" });
idx("audit_log", { resource_type: 1, resource_id: 1, timestamp: -1 }, { name: "idx_audit_resource" });
idx("audit_log", { organization_id: 1, action: 1, timestamp: -1 }, { name: "idx_audit_action" });
idx("audit_log", { expires_at: 1 }, { name: "idx_audit_ttl", expireAfterSeconds: 0 });
idx("audit_log", { request_id: 1 }, { name: "idx_audit_request", partialFilterExpression: { request_id: { $exists: true } } });

// ── sync_state ──
idx("sync_state", { channel_id: 1 }, { name: "idx_sync_state_channel", unique: true });
idx("sync_state", { organization_id: 1, health: 1 }, { name: "idx_sync_state_org_health" });
idx("sync_state", { connection_id: 1 }, { name: "idx_sync_state_connection" });
idx("sync_state", { pending_conflicts: -1 }, { name: "idx_sync_state_conflicts", partialFilterExpression: { pending_conflicts: { $gt: 0 } } });

// ── connection_credentials ──
idx("connection_credentials", { connection_id: 1 }, { name: "idx_cred_connection", unique: true });
idx("connection_credentials", { organization_id: 1, status: 1 }, { name: "idx_cred_org_status" });
idx("connection_credentials", { expires_at: 1 }, { name: "idx_cred_ttl", expireAfterSeconds: 0, partialFilterExpression: { expires_at: { $exists: true } } });

// ── abac_rule_conditions ──
idx("abac_rule_conditions", { rule_id: 1 }, { name: "idx_abac_rc_rule", unique: true });
idx("abac_rule_conditions", { organization_id: 1 }, { name: "idx_abac_rc_org" });
idx("abac_rule_conditions", { organization_id: 1, rule_id: 1 }, { name: "idx_abac_rc_org_rule" });

// ── abac_user_attributes ──
idx("abac_user_attributes", { user_id: 1, organization_id: 1 }, { name: "idx_abac_ua_user_org", unique: true });
idx("abac_user_attributes", { user_id: 1 }, { name: "idx_abac_ua_user" });
idx("abac_user_attributes", { organization_id: 1 }, { name: "idx_abac_ua_org" });
idx("abac_user_attributes", { organization_id: 1, "attributes.department": 1 }, { name: "idx_abac_ua_department", partialFilterExpression: { "attributes.department": { $exists: true } } });
idx("abac_user_attributes", { organization_id: 1, "attributes.clearance_level": 1 }, { name: "idx_abac_ua_clearance", partialFilterExpression: { "attributes.clearance_level": { $exists: true } } });

print("  " + idxCount + " indexes ensured.");
print("");
print("✓ MongoDB setup complete.");
' 2>&1

EXIT_CODE=$?
if [ $EXIT_CODE -ne 0 ]; then
    echo "✗ MongoDB setup failed (exit code $EXIT_CODE)"
    exit 1
fi
