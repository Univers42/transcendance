// ============================================================================
// query_cache.ts — Cached Aggregation Results (MongoDB / Mongoose)
// ============================================================================
// Dashboard widgets and views often run expensive aggregations on
// collection_records. This cache stores pre-computed results with TTL.
//
// Cache invalidation strategies:
//   • TTL-based: each entry has a configurable TTL (MongoDB TTL index)
//   • Event-based: when a collection_record is CUD'd, invalidate the
//     collection's cache entries
//   • Manual: user can force-refresh a widget
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

// ── Interfaces ──────────────────────────────────────────────────────────────

export interface QueryFingerprint {
  query?: Record<string, unknown>;
  aggregation?: Record<string, unknown>[];
  filters?: Record<string, unknown>;
  sort?: Record<string, unknown>;
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'query_cache',
  timestamps: false, // we manage created_at manually
  versionKey: false,
})
export class QueryCache {
  // ── Cache Key ───────────────────────────────────────────────────────────
  // Deterministic hash of: collection_id + query + aggregation + filters

  @Prop({ required: true, unique: true })
  cache_key: string;

  // ── Context ─────────────────────────────────────────────────────────────

  @Prop({ index: true })
  collection_id?: string; // UUID

  @Prop({ index: true })
  workspace_id?: string;

  @Prop()
  organization_id?: string;

  @Prop()
  widget_id?: string; // dashboard widget that triggered this

  @Prop()
  view_id?: string; // view that triggered this

  // ── Query Fingerprint ───────────────────────────────────────────────────
  // Original query for debugging and recomputation

  @Prop({ type: Object })
  query_fingerprint?: QueryFingerprint;

  // ── Result ──────────────────────────────────────────────────────────────

  @Prop({ type: Object, required: true })
  result: unknown; // cached aggregation output

  @Prop({ type: Number })
  result_count?: number;

  @Prop({ type: Number })
  computation_time_ms?: number;

  // ── TTL ─────────────────────────────────────────────────────────────────

  @Prop({ type: Number })
  ttl_seconds?: number;

  @Prop({ required: true, default: () => new Date() })
  created_at: Date;

  @Prop({ required: true })
  expires_at: Date; // MongoDB TTL index auto-deletes at this time
}

// ── Document type ───────────────────────────────────────────────────────────

export type QueryCacheDocument = QueryCache & Document;

// ── Schema factory ──────────────────────────────────────────────────────────

export const QueryCacheSchema = SchemaFactory.createForClass(QueryCache);

// ── Indexes ─────────────────────────────────────────────────────────────────

// Cache key lookup
QueryCacheSchema.index(
  { cache_key: 1 },
  { name: 'idx_query_cache_key', unique: true },
);

// Auto-expiration via MongoDB TTL index
QueryCacheSchema.index(
  { expires_at: 1 },
  { name: 'idx_query_cache_ttl', expireAfterSeconds: 0 },
);

// Invalidation by collection
QueryCacheSchema.index(
  { collection_id: 1 },
  { name: 'idx_query_cache_collection' },
);

// Invalidation by workspace
QueryCacheSchema.index(
  { workspace_id: 1 },
  { name: 'idx_query_cache_workspace' },
);

// Widget-specific cache lookup
QueryCacheSchema.index(
  { widget_id: 1 },
  {
    name: 'idx_query_cache_widget',
    partialFilterExpression: { widget_id: { $exists: true } },
  },
);
