// ============================================================================
// collection_records.ts — Polymorphic Business Data (MongoDB / Mongoose)
// ============================================================================
// Each document represents one "row" in a tenant-defined Collection.
// The schema of `data` is not known at compile time — it's defined by
// the `fields` table in PostgreSQL.
//
// Flow:
//   1. Tenant creates a Collection (SQL) → defines the "table"
//   2. Tenant adds Fields (SQL) → defines columns with types & validation
//   3. Backend syncs indexes from `collection_indices` (SQL) → MongoDB
//   4. Records are stored here → schema-free `data` object
//   5. Frontend reads field definitions → renders the correct UI controls
//   6. Backend validates records at write time against SQL field rules
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

// ── Interfaces ──────────────────────────────────────────────────────────────

export interface CollectionRecordRelations {
  [fieldSlug: string]: string[]; // field_slug → array of referenced record IDs
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'collection_records',
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  versionKey: false,
})
export class CollectionRecord {
  // ── Identity ────────────────────────────────────────────────────────────

  @Prop({ required: true, index: true })
  collection_id: string; // UUID FK → SQL collections.id

  @Prop({ required: true, index: true })
  workspace_id: string; // UUID denormalized

  @Prop({ required: true, index: true })
  organization_id: string; // UUID tenant isolation

  // ── Polymorphic data ────────────────────────────────────────────────────
  // Keys are field slugs, values are field values.
  // Example for a "Customers" collection:
  // {
  //   name: "Acme Corp",
  //   email: "contact@acme.com",
  //   revenue: 1500000,
  //   status: "active",
  //   tags: ["enterprise", "priority"],
  //   address: { city: "Paris", country: "FR" }
  // }
  @Prop({ type: Object, required: true, default: {} })
  data: Record<string, unknown>;

  // ── Relations ───────────────────────────────────────────────────────────
  // For relation fields: { field_slug: [referenced_record_id, ...] }
  @Prop({ type: Object, default: {} })
  _relations: CollectionRecordRelations;

  // ── Metadata ────────────────────────────────────────────────────────────

  @Prop({ required: true })
  created_by: string; // UUID

  @Prop()
  updated_by?: string; // UUID

  @Prop({ type: Number, default: 1, min: 1 })
  version: number; // Optimistic concurrency

  // ── Soft delete ─────────────────────────────────────────────────────────

  @Prop({ default: false })
  is_deleted: boolean;

  @Prop()
  deleted_at?: Date;

  @Prop()
  deleted_by?: string; // UUID

  // ── Timestamps (managed by Mongoose timestamps option) ──────────────────
  created_at: Date;
  updated_at: Date;
}

// ── Document type ───────────────────────────────────────────────────────────

export type CollectionRecordDocument = CollectionRecord & Document;

// ── Schema factory ──────────────────────────────────────────────────────────

export const CollectionRecordSchema =
  SchemaFactory.createForClass(CollectionRecord);

// ── Indexes ─────────────────────────────────────────────────────────────────

// Primary: all records in a collection, excluding soft-deleted, newest first
CollectionRecordSchema.index(
  { collection_id: 1, is_deleted: 1, created_at: -1 },
  { name: 'idx_collection_records_main' },
);

// Tenant isolation
CollectionRecordSchema.index(
  { organization_id: 1, collection_id: 1 },
  { name: 'idx_collection_records_org' },
);

// Workspace-scoped queries
CollectionRecordSchema.index(
  { workspace_id: 1, collection_id: 1 },
  { name: 'idx_collection_records_workspace' },
);

// Soft-delete cleanup
CollectionRecordSchema.index(
  { is_deleted: 1, deleted_at: 1 },
  {
    name: 'idx_collection_records_deleted',
    partialFilterExpression: { is_deleted: true },
  },
);

// Full-text search across data values
CollectionRecordSchema.index(
  { 'data.$**': 'text' },
  { name: 'idx_collection_records_text', default_language: 'english' },
);

// Wildcard index for flexible querying on any data field
CollectionRecordSchema.index(
  { 'data.$**': 1 },
  { name: 'idx_collection_records_data_wildcard' },
);
