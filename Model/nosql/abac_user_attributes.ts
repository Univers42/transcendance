// ============================================================================
// abac_user_attributes.ts — Per-User ABAC Attribute Store (MongoDB / Mongoose)
// ============================================================================
// Stores flexible, schema-free attributes for each user that ABAC rules
// evaluate against at access-check time.
//
// WHY MONGO:
//   User attributes vary wildly per tenant — one org might care about
//   "department" and "clearance_level", another about "team_tags" and
//   "cost_center".  A rigid SQL table would need ALTER TABLE for every
//   new attribute.  MongoDB lets each document carry whatever attributes
//   the tenant defines, validated at the application layer against
//   abac_attribute_definitions in SQL.
//
// SCOPING:
//   Each document is scoped to (user_id, organization_id):
//     • A user can have DIFFERENT attributes in different orgs
//     • Global attributes (org-independent) use organization_id = null
//
// ATTRIBUTE RESOLUTION ORDER (for ABAC evaluation):
//   1. User's org-scoped attributes (this collection, where org matches)
//   2. User's global attributes     (this collection, where org IS null)
//   3. Attribute default_value      (from SQL abac_attribute_definitions)
//   4. Attribute not found           → condition evaluates as "attribute missing"
//
// EXAMPLE DOCUMENTS:
//
//   // Alice's attributes at Acme Corp
//   {
//     user_id: "b000...01",
//     organization_id: "d000...01",
//     attributes: {
//       department: "engineering",
//       clearance_level: 4,
//       teams: ["backend", "infrastructure"],
//       location: "Paris",
//       cost_center: "CC-ENG-001",
//       certifications: ["aws-sa", "k8s-admin"]
//     }
//   }
//
//   // Alice's global attributes (org-independent)
//   {
//     user_id: "b000...01",
//     organization_id: null,
//     attributes: {
//       timezone: "Europe/Paris",
//       preferred_language: "fr",
//       mfa_enrolled: true,
//       account_tier: "professional"
//     }
//   }
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

// ── Interfaces ──────────────────────────────────────────────────────────────

/**
 * Flexible attribute map.  Keys match abac_attribute_definitions.name
 * (without the "user." prefix — the prefix is implicit since this is
 * a user attribute store).
 *
 * Values can be any JSON-serializable type:
 *   string, number, boolean, string[], number[], nested objects
 */
export type UserAttributes = Record<string, unknown>;

/**
 * History entry for attribute change tracking.
 * Stored as an array on the document for lightweight auditing.
 * Full audit trail lives in the audit_log MongoDB collection.
 */
export interface AttributeChangeEntry {
  /** Which attribute key was changed */
  key: string;
  /** Previous value (undefined if newly added) */
  old_value?: unknown;
  /** New value (undefined if removed) */
  new_value?: unknown;
  /** UUID of the user or system that made the change */
  changed_by: string;
  /** When the change was made */
  changed_at: Date;
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'abac_user_attributes',
  timestamps: true, // adds createdAt, updatedAt
  versionKey: false,
})
export class AbacUserAttribute {
  // ── Identity ──────────────────────────────────────────────────────────

  /**
   * UUID of the user whose attributes are stored.
   * References SQL users.id.
   */
  @Prop({ required: true, index: true })
  user_id: string;

  /**
   * UUID of the organization scope for these attributes.
   * NULL = global/org-independent attributes.
   * References SQL organizations.id.
   */
  @Prop({ index: true, default: null })
  organization_id: string | null;

  // ── Attribute Data ────────────────────────────────────────────────────

  /**
   * The actual attributes map.
   * Keys should match abac_attribute_definitions.name (minus "user." prefix).
   * Values are validated at the application layer, not by MongoDB.
   *
   * Example: { department: "engineering", clearance_level: 4, teams: ["be"] }
   */
  @Prop({ type: Object, required: true, default: {} })
  attributes: UserAttributes;

  // ── Computed / Derived Attributes ─────────────────────────────────────

  /**
   * Attributes that are computed at evaluation time rather than stored.
   * Each key maps to a computation rule (resolved by the ABAC engine).
   *
   * Example: { "active_project_count": { source: "sql", query: "project_members" } }
   *
   * This field is optional; most attributes are directly stored above.
   */
  @Prop({ type: Object, default: {} })
  computed_attributes?: Record<
    string,
    { source: string; query?: string; params?: Record<string, unknown> }
  >;

  // ── Metadata ──────────────────────────────────────────────────────────

  /** UUID of the user or system process that last updated attributes. */
  @Prop()
  updated_by?: string;

  /**
   * Recent attribute changes (lightweight inline audit).
   * Limited to last N entries; full history in audit_log collection.
   */
  @Prop({ type: [Object], default: [] })
  recent_changes?: AttributeChangeEntry[];
}

// ── Document type ───────────────────────────────────────────────────────────

export type AbacUserAttributeDocument = AbacUserAttribute & Document;

// ── Schema factory ──────────────────────────────────────────────────────────

export const AbacUserAttributeSchema =
  SchemaFactory.createForClass(AbacUserAttribute);

// ── Indexes ─────────────────────────────────────────────────────────────────

// Primary lookup: one document per (user, org) pair
AbacUserAttributeSchema.index(
  { user_id: 1, organization_id: 1 },
  { name: 'idx_abac_ua_user_org', unique: true },
);

// Find all attribute sets for a user (across orgs)
AbacUserAttributeSchema.index({ user_id: 1 }, { name: 'idx_abac_ua_user' });

// Org-scoped listing (admin: "show me all user attributes in this org")
AbacUserAttributeSchema.index(
  { organization_id: 1 },
  { name: 'idx_abac_ua_org' },
);

// Attribute value search (e.g., "find all users where department=engineering")
// Uses a wildcard text index on the attributes sub-document.
// For production, consider specific field indexes based on query patterns.
AbacUserAttributeSchema.index(
  { organization_id: 1, 'attributes.department': 1 },
  {
    name: 'idx_abac_ua_department',
    partialFilterExpression: { 'attributes.department': { $exists: true } },
  },
);

AbacUserAttributeSchema.index(
  { organization_id: 1, 'attributes.clearance_level': 1 },
  {
    name: 'idx_abac_ua_clearance',
    partialFilterExpression: {
      'attributes.clearance_level': { $exists: true },
    },
  },
);
