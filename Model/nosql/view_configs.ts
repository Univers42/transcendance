// ============================================================================
// view_configs.ts — View Filters, Sorts, Grouping, Field Visibility (MongoDB)
// ============================================================================
// Each View (defined in SQL) has a matching config document here that stores
// the display state: visible fields, column widths, sort order, active
// filters, grouping, color rules, and view-type-specific settings.
//
// Scope resolution (same pattern as dashboard_layouts):
//   shared    → the default config everyone sees
//   personal  → user's own filter/sort/column preferences (overrides shared)
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

// ── Interfaces ──────────────────────────────────────────────────────────────

export type ViewConfigScope = 'shared' | 'personal';
export type SortDirection = 'asc' | 'desc';
export type FilterLogic = 'and' | 'or';
export type RowHeight = 'compact' | 'default' | 'tall';

export type FilterOperator =
  | 'eq'
  | 'neq'
  | 'gt'
  | 'gte'
  | 'lt'
  | 'lte'
  | 'contains'
  | 'not_contains'
  | 'starts_with'
  | 'ends_with'
  | 'is_empty'
  | 'is_not_empty'
  | 'in'
  | 'not_in'
  | 'between'
  | 'not_between'
  | 'is_before'
  | 'is_after'
  | 'is_within';

export interface VisibleField {
  field_id: string;
  field_slug: string;
  width?: number; // column width in pixels
  is_frozen?: boolean; // pinned/frozen column
}

export interface SortRule {
  field_slug: string;
  direction: SortDirection;
}

export interface FilterCondition {
  field_slug: string;
  operator: FilterOperator;
  value?: unknown;
  nested_group?: FilterGroup; // recursive for complex logic
}

export interface FilterGroup {
  logic: FilterLogic;
  conditions: FilterCondition[];
}

export interface GroupByRule {
  field_slug: string;
  direction: SortDirection;
  collapsed_groups?: string[]; // group values collapsed by default
}

// ── View-type specific configs ──────────────────────────────────────────────

export type ChartType =
  | 'bar'
  | 'line'
  | 'area'
  | 'pie'
  | 'donut'
  | 'scatter'
  | 'bubble'
  | 'radar'
  | 'treemap'
  | 'heatmap';

export type AggregationFn = 'sum' | 'avg' | 'count' | 'min' | 'max' | 'median';

export interface ChartYAxis {
  field_slug: string;
  aggregation: AggregationFn;
  label?: string;
  color?: string;
}

export interface KanbanConfig {
  stack_field: string; // field slug used as kanban columns
  card_fields?: string[]; // field slugs shown on cards
  card_cover_field?: string; // image field for card cover
  hide_empty_stacks?: boolean;
}

export interface CalendarConfig {
  date_field: string;
  end_date_field?: string;
  title_field: string;
  color_field?: string;
  default_view?: 'month' | 'week' | 'day' | 'agenda';
}

export interface GalleryConfig {
  cover_field?: string; // image field for card cover
  title_field: string;
  subtitle_field?: string;
  card_size?: 'small' | 'medium' | 'large';
  card_fields?: string[];
}

export interface ChartConfig {
  chart_type: ChartType;
  x_axis: string;
  y_axis: ChartYAxis[];
  x_label?: string;
  y_label?: string;
  show_legend?: boolean;
  show_grid?: boolean;
  stacked?: boolean;
  colors?: string[];
}

export interface FormSection {
  title: string;
  field_slugs: string[];
}

export interface FormConfig {
  title?: string;
  description?: string;
  submit_label?: string;
  success_message?: string;
  redirect_url?: string;
  field_order?: string[];
  sections?: FormSection[];
}

export interface TimelineConfig {
  start_field: string;
  end_field?: string;
  title_field: string;
  group_field?: string;
  color_field?: string;
}

export interface ConditionalFormat {
  condition: FilterCondition;
  background_color?: string;
  text_color?: string;
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'view_configs',
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  versionKey: false,
})
export class ViewConfig {
  // ── References ──────────────────────────────────────────────────────────

  @Prop({ required: true })
  view_id: string; // UUID FK → SQL views.id

  @Prop({ required: true, index: true })
  collection_id: string; // UUID FK → SQL collections.id

  @Prop({ index: true })
  workspace_id: string;

  @Prop({ index: true })
  organization_id: string;

  @Prop({ required: true, enum: ['shared', 'personal'] })
  scope: ViewConfigScope;

  @Prop()
  owner_id?: string; // UUID (required when scope=personal)

  // ── Field Visibility & Order ────────────────────────────────────────────

  @Prop({ type: [Object], default: [] })
  visible_fields: VisibleField[];

  @Prop({ type: [String], default: [] })
  hidden_fields: string[]; // field slugs

  // ── Sorting ─────────────────────────────────────────────────────────────

  @Prop({ type: [Object], default: [] })
  sorts: SortRule[];

  // ── Filters ─────────────────────────────────────────────────────────────

  @Prop({ type: Object })
  filters?: FilterGroup;

  // ── Grouping ────────────────────────────────────────────────────────────

  @Prop({ type: [Object], default: [] })
  group_by: GroupByRule[];

  // ── View-type specific configs ──────────────────────────────────────────

  @Prop({ type: Object })
  kanban_config?: KanbanConfig;

  @Prop({ type: Object })
  calendar_config?: CalendarConfig;

  @Prop({ type: Object })
  gallery_config?: GalleryConfig;

  @Prop({ type: Object })
  chart_config?: ChartConfig;

  @Prop({ type: Object })
  form_config?: FormConfig;

  @Prop({ type: Object })
  timeline_config?: TimelineConfig;

  // ── Conditional Formatting ──────────────────────────────────────────────

  @Prop({ type: [Object], default: [] })
  row_coloring: ConditionalFormat[];

  // ── Pagination / Display ────────────────────────────────────────────────

  @Prop({ type: Number, min: 1, max: 1000 })
  page_size?: number;

  @Prop({ enum: ['compact', 'default', 'tall'] })
  row_height?: RowHeight;

  @Prop()
  wrap_cells?: boolean;

  // ── Metadata ────────────────────────────────────────────────────────────

  @Prop({ type: Number, default: 1 })
  version: number;

  // ── Timestamps (managed by Mongoose) ────────────────────────────────────
  created_at: Date;
  updated_at: Date;
}

// ── Document type ───────────────────────────────────────────────────────────

export type ViewConfigDocument = ViewConfig & Document;

// ── Schema factory ──────────────────────────────────────────────────────────

export const ViewConfigSchema = SchemaFactory.createForClass(ViewConfig);

// ── Indexes ─────────────────────────────────────────────────────────────────

// Primary lookup
ViewConfigSchema.index(
  { view_id: 1, scope: 1, owner_id: 1 },
  { name: 'idx_view_config_lookup', unique: true },
);

// All personal configs for a user
ViewConfigSchema.index(
  { owner_id: 1, scope: 1 },
  {
    name: 'idx_view_config_user',
    partialFilterExpression: { scope: 'personal' },
  },
);

// Collection-level queries
ViewConfigSchema.index(
  { collection_id: 1 },
  { name: 'idx_view_config_collection' },
);

// Workspace-level
ViewConfigSchema.index(
  { workspace_id: 1 },
  { name: 'idx_view_config_workspace' },
);
