// ============================================================================
// platform_analytics.ts — Admin Analytics Events (MongoDB / Mongoose)
// ============================================================================
// Stores analytics events for the admin dashboard (subject §6.9).
//
// SUBJECT REQUIREMENT:
//   "All analytics data must be stored in and queried from a non-relational
//    database (MongoDB)."
//
// WHY MONGODB (not PostgreSQL):
//   • Analytics events are write-heavy, read-infrequently (time-series pattern)
//   • Event shapes vary by type (page_view has path; api_call has endpoint + status)
//   • Aggregation pipelines are ideal for bucketed time-series queries
//   • TTL indexes auto-expire old analytics without manual cleanup
//   • No transactional integrity needed — approximate counts are acceptable
//
// ADMIN DASHBOARD WIDGETS POWERED BY THIS DATA:
//   • Active users (DAU/WAU/MAU)
//   • API call volume + error rates
//   • Page views / feature usage heatmaps
//   • Collection growth (records created/deleted over time)
//   • Adapter sync success/failure rates
//   • Storage consumption trends
//   • Login frequency and auth method distribution
//
// AGGREGATION PATTERNS:
//   • Bucket by hour/day:  $group + $dateToString on timestamp
//   • Top pages:           $match event_type='page_view' → $group by metadata.path
//   • Error rate:          $match event_type='api_call' → $group by metadata.status_code
//   • DAU:                 $match event_type='page_view' → $group by $dateToString + actor_id
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

// ── Types ───────────────────────────────────────────────────────────────────

export type AnalyticsEventType =
  | 'page_view'
  | 'api_call'
  | 'record_created'
  | 'record_updated'
  | 'record_deleted'
  | 'collection_created'
  | 'adapter_sync'
  | 'login'
  | 'signup'
  | 'export'
  | 'import'
  | 'search'
  | 'dashboard_view'
  | 'file_upload'
  | 'invitation_sent'
  | 'error';

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'platform_analytics',
  timestamps: false, // we manage timestamp explicitly for time-series
  versionKey: false,
})
export class PlatformAnalytics {
  // ── Event identity ────────────────────────────────────────────────────

  @Prop({
    required: true,
    enum: [
      'page_view',
      'api_call',
      'record_created',
      'record_updated',
      'record_deleted',
      'collection_created',
      'adapter_sync',
      'login',
      'signup',
      'export',
      'import',
      'search',
      'dashboard_view',
      'file_upload',
      'invitation_sent',
      'error',
    ],
  })
  event_type: AnalyticsEventType;

  // ── Scope ─────────────────────────────────────────────────────────────

  @Prop({ index: true })
  organization_id?: string; // NULL for platform-wide events (e.g., landing page views)

  @Prop()
  workspace_id?: string;

  @Prop({ index: true })
  actor_id?: string; // NULL for anonymous events (public page views)

  // ── Event metadata (shape varies by event_type) ───────────────────────
  // Examples:
  //   page_view:      { path: '/dashboard', referrer: 'https://google.com' }
  //   api_call:       { method: 'POST', endpoint: '/api/v1/records', status_code: 201, duration_ms: 45 }
  //   adapter_sync:   { adapter_id: '...', direction: 'pull', records_synced: 150, success: true }
  //   record_created: { collection_id: '...', record_id: '...' }
  //   login:          { method: 'password', ip: '1.2.3.4', success: true }
  //   error:          { error_code: 'RATE_LIMIT', message: 'Too many requests', endpoint: '/api/v1/...' }

  @Prop({ type: Object, default: {} })
  metadata: Record<string, unknown>;

  // ── Client context ────────────────────────────────────────────────────

  @Prop()
  ip?: string;

  @Prop()
  user_agent?: string;

  @Prop()
  session_id?: string;

  // ── Timing ────────────────────────────────────────────────────────────

  @Prop({ required: true, default: () => new Date() })
  timestamp: Date;

  @Prop()
  duration_ms?: number; // for timed events (api_call, adapter_sync)

  // ── TTL ───────────────────────────────────────────────────────────────
  // Analytics data auto-expires based on retention policy.
  // Default: 90 days for raw events; aggregated summaries live separately.

  @Prop()
  expires_at?: Date;
}

// ── Document type ───────────────────────────────────────────────────────────

export type PlatformAnalyticsDocument = PlatformAnalytics & Document;

// ── Schema factory ──────────────────────────────────────────────────────────

export const PlatformAnalyticsSchema =
  SchemaFactory.createForClass(PlatformAnalytics);

// ── Indexes ─────────────────────────────────────────────────────────────────
// Designed for admin dashboard aggregate queries (time-bucketed reads).

// Primary query path: event type over time (powers most dashboard widgets)
PlatformAnalyticsSchema.index(
  { event_type: 1, timestamp: -1 },
  { name: 'idx_analytics_type_time' },
);

// Organization-scoped analytics (per-org admin dashboard)
PlatformAnalyticsSchema.index(
  { organization_id: 1, event_type: 1, timestamp: -1 },
  { name: 'idx_analytics_org_type_time' },
);

// User activity tracking (for DAU/WAU/MAU calculations)
PlatformAnalyticsSchema.index(
  { actor_id: 1, timestamp: -1 },
  {
    name: 'idx_analytics_actor_time',
    partialFilterExpression: { actor_id: { $exists: true } },
  },
);

// Workspace-scoped analytics
PlatformAnalyticsSchema.index(
  { workspace_id: 1, event_type: 1, timestamp: -1 },
  {
    name: 'idx_analytics_workspace_type_time',
    partialFilterExpression: { workspace_id: { $exists: true } },
  },
);

// TTL auto-cleanup (retention policy — default 90 days)
PlatformAnalyticsSchema.index(
  { expires_at: 1 },
  { name: 'idx_analytics_ttl', expireAfterSeconds: 0 },
);

// Time-based range scans (for date-range filtering without event_type)
PlatformAnalyticsSchema.index(
  { timestamp: -1 },
  { name: 'idx_analytics_timestamp' },
);
