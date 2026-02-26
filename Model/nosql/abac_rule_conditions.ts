// ============================================================================
// abac_rule_conditions.ts — Rule Condition Trees (MongoDB / Mongoose)
// ============================================================================
// Stores the flexible, deeply-nested condition trees for ABAC rules.
//
// WHY MONGO:
//   Condition trees can nest arbitrarily deep with AND/OR/NOT logic —
//   a structure that would require recursive CTEs or JSON columns in SQL
//   but maps naturally to MongoDB's document model.
//
// LINK TO SQL:
//   Each document maps 1:1 to a row in PostgreSQL abac_rules (by rule_id).
//   SQL stores rule metadata (name, effect, priority, temporal bounds);
//   MongoDB stores the condition logic (the "if" part of the rule).
//
// CONDITION TREE STRUCTURE:
//   A tree node is either a LEAF (attribute comparison) or a BRANCH (logic):
//
//   Leaf:
//     { attribute: "user.department", operator: "eq", value: "engineering" }
//
//   Branch:
//     { logic: "and", conditions: [ ...children ] }
//
//   Example — "Engineer in Paris OR has clearance ≥ 5":
//     {
//       logic: "or",
//       conditions: [
//         {
//           logic: "and",
//           conditions: [
//             { attribute: "user.department", operator: "eq", value: "engineering" },
//             { attribute: "user.location",   operator: "eq", value: "Paris" }
//           ]
//         },
//         { attribute: "user.clearance_level", operator: "gte", value: 5 }
//       ]
//     }
//
// SUPPORTED OPERATORS:
//   Equality:    eq, neq
//   Comparison:  gt, gte, lt, lte
//   Set:         in, not_in, is_subset, is_superset
//   String:      contains, not_contains, starts_with, ends_with, matches (regex)
//   Range:       between (inclusive, expects [min, max] value)
//   Existence:   exists (boolean: attribute present or not)
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

// ── Interfaces ──────────────────────────────────────────────────────────────

/**
 * Supported comparison operators for leaf conditions.
 * Mirrors the set from abac_conditions.operator in schema.user.sql,
 * plus additional operators for richer expression.
 */
export type ConditionOperator =
  // Equality
  | 'eq'
  | 'neq'
  // Comparison
  | 'gt'
  | 'gte'
  | 'lt'
  | 'lte'
  // Set membership
  | 'in'
  | 'not_in'
  | 'is_subset'
  | 'is_superset'
  // String matching
  | 'contains'
  | 'not_contains'
  | 'starts_with'
  | 'ends_with'
  | 'matches' // regex
  // Range
  | 'between' // expects value = [min, max]
  // Existence
  | 'exists'; // expects value = true/false

/** Boolean logic for branch nodes. */
export type ConditionLogic = 'and' | 'or' | 'not';

/**
 * A leaf condition — compares a single attribute against a value.
 */
export interface LeafCondition {
  /** Dot-path attribute reference, e.g., "user.department", "resource.sensitivity" */
  attribute: string;
  /** Comparison operator */
  operator: ConditionOperator;
  /** Value(s) to compare against. Type depends on operator. */
  value: unknown;
  /**
   * Optional JSON path within the attribute for nested attribute drilling.
   * E.g., attribute="user.metadata", path="$.preferences.theme"
   */
  path?: string;
}

/**
 * A branch condition — combines child conditions with boolean logic.
 * Children can be leaves or nested branches (recursive).
 */
export interface BranchCondition {
  /** Boolean logic: all children must match (and), any (or), or negate (not) */
  logic: ConditionLogic;
  /** Child conditions (leaves and/or nested branches) */
  conditions: ConditionNode[];
}

/** A condition node is either a leaf or a branch. */
export type ConditionNode = LeafCondition | BranchCondition;

/** Type guard: is this node a branch (has logic + conditions)? */
export function isBranchCondition(
  node: ConditionNode,
): node is BranchCondition {
  return 'logic' in node && 'conditions' in node;
}

/** Type guard: is this node a leaf (has attribute + operator)? */
export function isLeafCondition(node: ConditionNode): node is LeafCondition {
  return 'attribute' in node && 'operator' in node;
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'abac_rule_conditions',
  timestamps: true, // adds createdAt, updatedAt
  versionKey: false,
})
export class AbacRuleCondition {
  // ── Identity ──────────────────────────────────────────────────────────

  /** UUID of the SQL abac_rules row this condition belongs to (1:1). */
  @Prop({ required: true, unique: true, index: true })
  rule_id: string;

  /** UUID of the owning organization. */
  @Prop({ required: true, index: true })
  organization_id: string;

  // ── Condition Tree ────────────────────────────────────────────────────

  /**
   * The full condition tree. Evaluated recursively at access-check time.
   * Must be a valid ConditionNode (leaf or branch).
   */
  @Prop({ type: Object, required: true })
  condition_tree: ConditionNode;

  // ── Metadata ──────────────────────────────────────────────────────────

  /** Human-readable description of what this condition checks. */
  @Prop()
  description?: string;

  /**
   * Schema version for forward-compatible condition format changes.
   * Future condition formats can be detected by checking this version.
   */
  @Prop({ default: 1 })
  schema_version: number;

  /**
   * SHA-256 hash of the condition_tree JSON. Must match
   * abac_rules.condition_hash in SQL for integrity verification.
   */
  @Prop()
  condition_hash?: string;

  /** UUID of the user who last modified this condition. */
  @Prop()
  updated_by?: string;
}

// ── Document type ───────────────────────────────────────────────────────────

export type AbacRuleConditionDocument = AbacRuleCondition & Document;

// ── Schema factory ──────────────────────────────────────────────────────────

export const AbacRuleConditionSchema =
  SchemaFactory.createForClass(AbacRuleCondition);

// ── Indexes ─────────────────────────────────────────────────────────────────

// Primary lookup: find condition by rule_id
AbacRuleConditionSchema.index(
  { rule_id: 1 },
  { name: 'idx_abac_rc_rule', unique: true },
);

// Org-scoped listing
AbacRuleConditionSchema.index(
  { organization_id: 1 },
  { name: 'idx_abac_rc_org' },
);

// Batch fetch: multiple rule conditions at once (policy evaluation)
AbacRuleConditionSchema.index(
  { organization_id: 1, rule_id: 1 },
  { name: 'idx_abac_rc_org_rule' },
);
