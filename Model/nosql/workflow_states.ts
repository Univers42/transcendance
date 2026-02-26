// ============================================================================
// workflow_states.ts — Workflow Definitions & Execution Runtime (MongoDB)
// ============================================================================
// Two collections:
//   • WorkflowDefinition — the blueprint: trigger + step pipeline
//   • WorkflowExecution  — a single run + per-step results
//
// Examples:
//   • When record status → "approved" → send webhook + email
//   • When new record in "Orders" → assign to team member
//   • Every Monday → generate weekly report (cron schedule)
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document, Types } from 'mongoose';

// ── Interfaces ──────────────────────────────────────────────────────────────

export type TriggerType =
  | 'record_created'
  | 'record_updated'
  | 'record_deleted'
  | 'field_changed'
  | 'schedule'
  | 'webhook_received'
  | 'form_submitted'
  | 'manual';

export type StepType =
  | 'filter'
  | 'transform'
  | 'create_record'
  | 'update_record'
  | 'delete_record'
  | 'send_email'
  | 'send_webhook'
  | 'send_notification'
  | 'delay'
  | 'condition'
  | 'loop'
  | 'assign'
  | 'custom_function';

export type ErrorStrategy = 'stop' | 'skip' | 'retry';

export type WorkflowStatus =
  | 'pending'
  | 'running'
  | 'completed'
  | 'failed'
  | 'cancelled'
  | 'paused';

export type StepStatus =
  | 'pending'
  | 'running'
  | 'completed'
  | 'failed'
  | 'skipped';

export interface WorkflowTrigger {
  type: TriggerType;
  collection_id?: string;
  field_slug?: string; // for field_changed triggers
  schedule?: string; // cron expression
  conditions?: Record<string, unknown>; // same format as view filters
}

export interface WorkflowStep {
  step_id: string; // UUID
  type: StepType;
  config: Record<string, unknown>; // step-specific configuration
  on_error?: ErrorStrategy;
  retry_count?: number;
  timeout_ms?: number;
}

export interface StepResult {
  step_id: string;
  status: StepStatus;
  started_at?: Date;
  completed_at?: Date;
  duration_ms?: number;
  input?: Record<string, unknown>;
  output?: Record<string, unknown>;
  error?: string;
  retry_attempt?: number;
}

export interface TriggerData {
  record_id?: string;
  collection_id?: string;
  changed_fields?: Record<string, unknown>;
  previous_values?: Record<string, unknown>;
  triggered_by?: string; // UUID of user or "system"
}

// ── WorkflowDefinition Schema ───────────────────────────────────────────────

@Schema({
  collection: 'workflow_definitions',
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  versionKey: false,
})
export class WorkflowDefinition {
  @Prop({ required: true, index: true })
  organization_id: string;

  @Prop({ index: true })
  workspace_id?: string;

  @Prop({ required: true })
  name: string;

  @Prop()
  description?: string;

  @Prop({ default: true })
  is_active: boolean;

  // ── Trigger ─────────────────────────────────────────────────────────────

  @Prop({ type: Object, required: true })
  trigger: WorkflowTrigger;

  // ── Steps (pipeline) ────────────────────────────────────────────────────

  @Prop({ type: [Object], required: true, default: [] })
  steps: WorkflowStep[];

  // ── Metadata ────────────────────────────────────────────────────────────

  @Prop()
  created_by: string; // UUID

  @Prop()
  last_triggered_at?: Date;

  @Prop({ type: Number, default: 0 })
  execution_count: number;

  // ── Timestamps (managed by Mongoose) ────────────────────────────────────
  created_at: Date;
  updated_at: Date;
}

export type WorkflowDefinitionDocument = WorkflowDefinition & Document;
export const WorkflowDefinitionSchema =
  SchemaFactory.createForClass(WorkflowDefinition);

// ── WorkflowExecution Schema ────────────────────────────────────────────────

@Schema({
  collection: 'workflow_executions',
  timestamps: false,
  versionKey: false,
})
export class WorkflowExecution {
  @Prop({ type: Types.ObjectId, ref: WorkflowDefinition.name, required: true })
  workflow_id: Types.ObjectId;

  @Prop({ required: true, index: true })
  organization_id: string;

  @Prop({
    required: true,
    enum: ['pending', 'running', 'completed', 'failed', 'cancelled', 'paused'],
  })
  status: WorkflowStatus;

  // ── Trigger Context ─────────────────────────────────────────────────────

  @Prop({ type: Object })
  trigger_data?: TriggerData;

  // ── Step Results ────────────────────────────────────────────────────────

  @Prop({ type: [Object], default: [] })
  step_results: StepResult[];

  // ── Timing ──────────────────────────────────────────────────────────────

  @Prop({ required: true, default: () => new Date() })
  started_at: Date;

  @Prop()
  completed_at?: Date;

  @Prop({ type: Number })
  duration_ms?: number;

  @Prop()
  error?: string;
}

export type WorkflowExecutionDocument = WorkflowExecution & Document;
export const WorkflowExecutionSchema =
  SchemaFactory.createForClass(WorkflowExecution);

// ── Indexes: WorkflowDefinition ─────────────────────────────────────────────

WorkflowDefinitionSchema.index(
  { organization_id: 1, is_active: 1 },
  { name: 'idx_workflow_def_org' },
);

WorkflowDefinitionSchema.index(
  { 'trigger.type': 1, 'trigger.collection_id': 1 },
  { name: 'idx_workflow_def_trigger' },
);

// ── Indexes: WorkflowExecution ──────────────────────────────────────────────

WorkflowExecutionSchema.index(
  { workflow_id: 1, started_at: -1 },
  { name: 'idx_workflow_exec_workflow' },
);

WorkflowExecutionSchema.index(
  { organization_id: 1, status: 1 },
  { name: 'idx_workflow_exec_status' },
);

WorkflowExecutionSchema.index(
  { status: 1, started_at: 1 },
  {
    name: 'idx_workflow_exec_running',
    partialFilterExpression: { status: { $in: ['pending', 'running'] } },
  },
);
