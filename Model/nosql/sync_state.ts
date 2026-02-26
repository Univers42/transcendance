// ============================================================================
// sync_state.ts — CDC Sync State & Conflict Queue (MongoDB)
// ============================================================================
// Stores real-time synchronization state for CDC (Change Data Capture)
// channels. This data changes extremely frequently (every sync operation)
// and requires flexible structure — ideal for MongoDB.
//
// WHY MONGODB:
//   • CDC cursors (LSN, resume tokens) update on every change event
//   • Conflict queue items have varying shapes depending on engine type
//   • Replication lag metrics are time-series-like, frequently written
//   • Schema varies by database engine (PostgreSQL LSN vs MongoDB resume token)
//
// SQL LINK:
//   sync_state.channel_id   → sync_channels.id (SQL)
//   sync_state.connection_id → database_connections.id (SQL)
//
// LIFECYCLE:
//   Created when a sync_channel is first activated.
//   Updated continuously during sync operations.
//   conflict_queue entries are resolved manually or auto-merged.
// ============================================================================

import { Prop, Schema, SchemaFactory, raw } from '@nestjs/mongoose';
import { HydratedDocument, Types } from 'mongoose';

// ── Types ───────────────────────────────────────────────────────────────────

/** Supported CDC engine types */
export type CdcEngine =
  | 'pg_logical'
  | 'mongo_change_stream'
  | 'mysql_binlog'
  | 'polling';

/** Sync health status */
export type SyncHealth = 'healthy' | 'lagging' | 'stalled' | 'error' | 'paused';

/** Conflict resolution status */
export type ConflictStatus =
  | 'pending'
  | 'resolved_source'
  | 'resolved_platform'
  | 'resolved_merge'
  | 'resolved_manual'
  | 'discarded';

/** Direction of the change that caused the conflict */
export type ConflictDirection = 'inbound' | 'outbound';

/** CDC cursor position — varies by engine */
export interface CdcCursor {
  /** PostgreSQL: WAL Log Sequence Number (e.g., "0/16B3748") */
  lsn?: string;

  /** PostgreSQL: replication slot name */
  slot_name?: string;

  /** MongoDB: change stream resume token (BSON binary) */
  resume_token?: string;

  /** MySQL: binlog file name */
  binlog_file?: string;

  /** MySQL: binlog position offset */
  binlog_position?: number;

  /** Polling: last known updated_at timestamp */
  last_polled_at?: Date;

  /** Polling: last known max primary key value */
  last_seen_id?: string;

  /** Generic: last confirmed transaction ID */
  last_txn_id?: string;

  /** When this cursor was last updated */
  captured_at: Date;
}

/** A single field-level conflict */
export interface ConflictField {
  /** Field name / column that conflicts */
  field: string;

  /** Value from the remote source */
  source_value: any;

  /** Value from the platform */
  platform_value: any;

  /** Resolved value (set after resolution) */
  resolved_value?: any;
}

/** A conflict queue entry — one record-level conflict */
export interface ConflictEntry {
  /** Unique conflict ID */
  conflict_id: string;

  /** Remote record identifier (primary key) */
  remote_record_id: string;

  /** Local MongoDB record _id */
  local_record_id?: string;

  /** Which direction caused the conflict */
  direction: ConflictDirection;

  /** Fields in conflict */
  fields: ConflictField[];

  /** Current resolution status */
  status: ConflictStatus;

  /** Who resolved it (user_id) */
  resolved_by?: string;

  /** When the conflict was detected */
  detected_at: Date;

  /** When the conflict was resolved */
  resolved_at?: Date;

  /** Additional context (error messages, etc.) */
  metadata?: Record<string, any>;
}

/** Replication lag measurement */
export interface LagMeasurement {
  /** Measured lag in milliseconds */
  lag_ms: number;

  /** When this measurement was taken */
  measured_at: Date;

  /** Number of pending changes in the queue */
  pending_changes: number;
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'sync_state',
  timestamps: true,
  versionKey: false,
})
export class SyncState {
  // ── Identity ────────────────────────────────────────────────────────────

  /** References sync_channels.id (SQL) */
  @Prop({ required: true, index: true, unique: true })
  channel_id!: string;

  /** References database_connections.id (SQL) — denormalized for fast lookup */
  @Prop({ required: true, index: true })
  connection_id!: string;

  /** References collections.id (SQL) — target collection */
  @Prop({ required: true, index: true })
  collection_id!: string;

  /** Organization ID — denormalized for multi-tenant queries */
  @Prop({ required: true, index: true })
  organization_id!: string;

  // ── CDC Engine & Cursor ─────────────────────────────────────────────────

  /** Which CDC engine is being used */
  @Prop({
    required: true,
    enum: ['pg_logical', 'mongo_change_stream', 'mysql_binlog', 'polling'],
  })
  cdc_engine!: CdcEngine;

  /** Current inbound cursor position (remote → platform) */
  @Prop({ type: Object, default: {} })
  inbound_cursor!: CdcCursor;

  /** Current outbound cursor position (platform → remote) */
  @Prop({ type: Object, default: {} })
  outbound_cursor!: CdcCursor;

  // ── Replication Health ──────────────────────────────────────────────────

  /** Overall sync health */
  @Prop({
    required: true,
    enum: ['healthy', 'lagging', 'stalled', 'error', 'paused'],
    default: 'healthy',
  })
  health!: SyncHealth;

  /** Current replication lag in milliseconds */
  @Prop({ default: 0 })
  current_lag_ms!: number;

  /** Rolling lag measurements (last N readings for trend analysis) */
  @Prop({ type: [Object], default: [] })
  lag_history!: LagMeasurement[];

  /** Max lag_history entries to retain (FIFO) */
  @Prop({ default: 100 })
  lag_history_limit!: number;

  /** Total records synced inbound since channel creation */
  @Prop({ default: 0 })
  total_records_in!: number;

  /** Total records synced outbound since channel creation */
  @Prop({ default: 0 })
  total_records_out!: number;

  /** Total conflicts detected since channel creation */
  @Prop({ default: 0 })
  total_conflicts!: number;

  /** Consecutive errors (resets on success) */
  @Prop({ default: 0 })
  consecutive_errors!: number;

  /** Last error message */
  @Prop()
  last_error?: string;

  /** When the last successful sync completed */
  @Prop()
  last_success_at?: Date;

  /** When the last error occurred */
  @Prop()
  last_error_at?: Date;

  // ── Conflict Queue ──────────────────────────────────────────────────────

  /** Pending and recently resolved conflicts */
  @Prop({ type: [Object], default: [] })
  conflict_queue!: ConflictEntry[];

  /** Number of currently pending (unresolved) conflicts */
  @Prop({ default: 0 })
  pending_conflicts!: number;

  // ── Watermarks ──────────────────────────────────────────────────────────

  /** High watermark — most recent change timestamp from source */
  @Prop()
  source_high_watermark?: Date;

  /** High watermark — most recent change timestamp from platform */
  @Prop()
  platform_high_watermark?: Date;

  /** Schema version hash — detects schema drift in remote DB */
  @Prop()
  remote_schema_hash?: string;

  /** Last time the remote schema was validated */
  @Prop()
  schema_validated_at?: Date;
}

export type SyncStateDocument = HydratedDocument<SyncState>;
export const SyncStateSchema = SchemaFactory.createForClass(SyncState);

// ── Indexes ──────────────────────────────────────────────────────────────────
SyncStateSchema.index({ channel_id: 1 }, { unique: true });
SyncStateSchema.index({ organization_id: 1, health: 1 });
SyncStateSchema.index({ connection_id: 1 });
SyncStateSchema.index(
  { pending_conflicts: -1 },
  { partialFilterExpression: { pending_conflicts: { $gt: 0 } } },
);
