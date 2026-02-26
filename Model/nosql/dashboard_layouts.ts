// ============================================================================
// dashboard_layouts.ts — Dashboard Widget Positions & Configs (MongoDB)
// ============================================================================
// Stores the visual layout of dashboard widgets: positions, sizes, and
// per-widget configuration. Implements the personal vs. shared layout system.
//
// ── SCOPE RESOLUTION (layered overrides) ──────────────────────────────────
//
//   template  → Organization-level default (the starting point)
//   shared    → Published layout visible to all workspace/project members
//   personal  → Individual user's customizations (highest priority)
//
//   Rendering: template ← shared ← personal (personal overrides everything)
//
// ── HOW IT WORKS ──────────────────────────────────────────────────────────
//
//   • User opens dashboard → backend merges: template → shared → personal
//   • User drags a widget → saves to "personal" scope only
//   • User with "dashboard:publish" permission → pushes to "shared"
//   • Admin resets dashboard → clears shared+personal, reverts to template
// ============================================================================

import { Prop, Schema, SchemaFactory, raw } from '@nestjs/mongoose';
import { Document } from 'mongoose';

// ── Interfaces ──────────────────────────────────────────────────────────────

export type LayoutScope = 'template' | 'shared' | 'personal';

export type WidgetType =
  | 'chart'
  | 'metric'
  | 'table'
  | 'kanban'
  | 'filter'
  | 'text'
  | 'image'
  | 'map'
  | 'timeline'
  | 'embed'
  | 'calendar'
  | 'form'
  | 'list'
  | 'pivot'
  | 'custom';

export type CompactType = 'vertical' | 'horizontal' | 'none';

export interface GridMargin {
  top: number;
  right: number;
  bottom: number;
  left: number;
}

export interface GridBreakpoints {
  lg?: number;
  md?: number;
  sm?: number;
  xs?: number;
}

export interface GridConfig {
  columns: number;
  row_height: number;
  gap: number;
  margin?: GridMargin;
  breakpoints?: GridBreakpoints;
  compact_type?: CompactType;
}

export interface WidgetPosition {
  x: number;
  y: number;
  w: number;
  h: number;
  min_w?: number;
  min_h?: number;
  max_w?: number;
  max_h?: number;
  is_static?: boolean;
}

export interface WidgetDataSource {
  collection_id?: string;
  view_id?: string;
  query?: Record<string, unknown>;
  aggregation?: Record<string, unknown>[];
  adapter_id?: string;
  cache_ttl?: number; // seconds
}

export interface DashboardWidget {
  widget_id: string; // UUID unique within this layout
  widget_type: WidgetType;
  position: WidgetPosition;
  responsive_positions?: Record<string, Partial<WidgetPosition>>; // { md: {...}, sm: {...} }
  config?: Record<string, unknown>; // type-dependent config
  data_source?: WidgetDataSource;
  title?: string;
  description?: string;
  is_visible?: boolean;
  style?: Record<string, unknown>; // CSS overrides
}

export type GlobalFilterType =
  | 'select'
  | 'multi_select'
  | 'date_range'
  | 'number_range'
  | 'text_search'
  | 'boolean';

export interface DashboardGlobalFilter {
  filter_id: string;
  field_slug: string;
  label: string;
  filter_type: GlobalFilterType;
  default_value?: unknown;
  affected_widgets?: string[]; // widget IDs, empty = all
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'dashboard_layouts',
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  versionKey: false,
})
export class DashboardLayout {
  // ── References ──────────────────────────────────────────────────────────

  @Prop({ required: true })
  dashboard_id: string; // UUID FK → SQL dashboards.id

  @Prop({ required: true, enum: ['template', 'shared', 'personal'] })
  scope: LayoutScope;

  @Prop()
  owner_id?: string; // UUID (required when scope=personal)

  @Prop({ index: true })
  workspace_id: string;

  @Prop({ index: true })
  organization_id: string;

  // ── Grid Configuration ──────────────────────────────────────────────────

  @Prop({ type: Object, required: true })
  grid_config: GridConfig;

  // ── Widgets ─────────────────────────────────────────────────────────────

  @Prop({ type: [Object], required: true, default: [] })
  widgets: DashboardWidget[];

  // ── Global Filters ──────────────────────────────────────────────────────
  // Filters that apply across all widgets in this dashboard

  @Prop({ type: [Object], default: [] })
  global_filters: DashboardGlobalFilter[];

  // ── Metadata ────────────────────────────────────────────────────────────

  @Prop({ type: Number, default: 1 })
  version: number;

  @Prop()
  published_at?: Date; // when this layout was last published (scope=shared)

  @Prop()
  published_by?: string; // UUID

  // ── Timestamps (managed by Mongoose) ────────────────────────────────────
  created_at: Date;
  updated_at: Date;
}

// ── Document type ───────────────────────────────────────────────────────────

export type DashboardLayoutDocument = DashboardLayout & Document;

// ── Schema factory ──────────────────────────────────────────────────────────

export const DashboardLayoutSchema =
  SchemaFactory.createForClass(DashboardLayout);

// ── Indexes ─────────────────────────────────────────────────────────────────

// Primary lookup: get layout for a dashboard + scope (+ optional user)
DashboardLayoutSchema.index(
  { dashboard_id: 1, scope: 1, owner_id: 1 },
  { name: 'idx_layout_lookup', unique: true },
);

// All personal layouts for a user
DashboardLayoutSchema.index(
  { owner_id: 1, scope: 1 },
  {
    name: 'idx_layout_user',
    partialFilterExpression: { scope: 'personal' },
  },
);

// Workspace-level queries
DashboardLayoutSchema.index(
  { workspace_id: 1, scope: 1 },
  { name: 'idx_layout_workspace' },
);

// Organization-level queries
DashboardLayoutSchema.index({ organization_id: 1 }, { name: 'idx_layout_org' });
