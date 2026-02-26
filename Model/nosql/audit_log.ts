// ============================================================================
// audit_log.ts — Change Tracking & Activity Feed (MongoDB / Mongoose)
// ============================================================================
// Append-only log of all significant actions in the platform.
//
// Uses:
//   • Security auditing (who changed what, when)
//   • Activity feeds (recent changes in a workspace)
//   • Undo/redo (replaying or reverting events)
//   • Compliance (immutable audit trail)
//
// This collection is write-heavy, append-only, and benefits from TTL indexes
// for automatic cleanup based on retention policies.
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

// ── Interfaces ──────────────────────────────────────────────────────────────

export type ActorType = 'user' | 'system' | 'api_key' | 'workflow';

export interface AuditChanges {
  before?: Record<string, unknown>; // previous state (changed fields only)
  after?: Record<string, unknown>; // new state (changed fields only)
  diff?: string[]; // changed field paths: ["data.status", "data.assignee"]
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'audit_log',
  timestamps: false, // we use our own `timestamp` field
  versionKey: false,
})
export class AuditLog {
  // ── Who ─────────────────────────────────────────────────────────────────

  @Prop({ required: true, index: true })
  organization_id: string;

  @Prop({ required: true, index: true })
  actor_id: string; // UUID of the user performing the action

  @Prop({ enum: ['user', 'system', 'api_key', 'workflow'], default: 'user' })
  actor_type: ActorType;

  @Prop()
  actor_ip?: string;

  @Prop()
  actor_user_agent?: string;

  // ── What ────────────────────────────────────────────────────────────────

  @Prop({ required: true })
  action: string; // "created", "updated", "deleted", "viewed", "published", "shared", "login", etc.

  @Prop({ required: true })
  resource_type: string; // "dashboard", "collection", "record", "view", "user", etc.

  @Prop()
  resource_id?: string; // UUID of the affected resource

  @Prop()
  resource_name?: string; // human-readable name at time of action

  // ── Where ───────────────────────────────────────────────────────────────

  @Prop({ index: true })
  workspace_id?: string;

  @Prop()
  project_id?: string;

  // ── Details ─────────────────────────────────────────────────────────────

  @Prop({ type: Object })
  changes?: AuditChanges;

  @Prop({ type: Object })
  metadata?: Record<string, unknown>; // action-specific: { import_source: "csv", row_count: 150 }

  // ── Context ─────────────────────────────────────────────────────────────

  @Prop()
  session_id?: string;

  @Prop()
  request_id?: string; // correlation ID for distributed tracing

  // ── Timing ──────────────────────────────────────────────────────────────

  @Prop({ required: true, default: () => new Date() })
  timestamp: Date;

  @Prop()
  expires_at?: Date; // TTL auto-cleanup based on retention policy
}

// ── Document type ───────────────────────────────────────────────────────────

export type AuditLogDocument = AuditLog & Document;

// ── Schema factory ──────────────────────────────────────────────────────────

export const AuditLogSchema = SchemaFactory.createForClass(AuditLog);

// ── Indexes ─────────────────────────────────────────────────────────────────

// Recent actions in an organization
AuditLogSchema.index(
  { organization_id: 1, timestamp: -1 },
  { name: 'idx_audit_org_time' },
);

// Activity feed for a workspace
AuditLogSchema.index(
  { workspace_id: 1, timestamp: -1 },
  { name: 'idx_audit_workspace_time' },
);

// User activity history
AuditLogSchema.index(
  { actor_id: 1, timestamp: -1 },
  { name: 'idx_audit_actor_time' },
);

// Resource history (all changes to a specific resource)
AuditLogSchema.index(
  { resource_type: 1, resource_id: 1, timestamp: -1 },
  { name: 'idx_audit_resource' },
);

// Action type filtering
AuditLogSchema.index(
  { organization_id: 1, action: 1, timestamp: -1 },
  { name: 'idx_audit_action' },
);

// TTL auto-cleanup (retention policy)
AuditLogSchema.index(
  { expires_at: 1 },
  { name: 'idx_audit_ttl', expireAfterSeconds: 0 },
);

// Request tracing
AuditLogSchema.index(
  { request_id: 1 },
  {
    name: 'idx_audit_request',
    partialFilterExpression: { request_id: { $exists: true } },
  },
);
