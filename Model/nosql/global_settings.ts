// ============================================================================
// global_settings.ts — Organization & Workspace Settings (MongoDB / Mongoose)
// ============================================================================
// Admin-managed configuration that affects all members of an org, project,
// or workspace: branding, security policies, feature flags, defaults.
//
// One document per scope (organization, project, or workspace).
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

// ── Interfaces ──────────────────────────────────────────────────────────────

export type SettingsScope = 'organization' | 'project' | 'workspace';

export interface BrandingSettings {
  logo_url?: string;
  favicon_url?: string;
  primary_color?: string;
  secondary_color?: string;
  font_family?: string;
  custom_css?: string;
  login_background_url?: string;
  app_title?: string;
}

export interface PasswordPolicy {
  min_length?: number;
  require_uppercase?: boolean;
  require_lowercase?: boolean;
  require_numbers?: boolean;
  require_special?: boolean;
  max_age_days?: number;
  prevent_reuse_count?: number;
}

export interface SSOConfig {
  enabled: boolean;
  provider?: 'saml' | 'oidc';
  metadata_url?: string;
  client_id?: string;
  certificate?: string;
}

export interface SecuritySettings {
  enforce_mfa?: boolean;
  session_timeout_minutes?: number;
  max_sessions_per_user?: number;
  password_policy?: PasswordPolicy;
  allowed_ip_ranges?: string[]; // CIDR notation
  allowed_oauth_providers?: string[]; // ["google", "42", "github"]
  sso_config?: SSOConfig;
}

export interface DashboardDefaults {
  grid_columns?: number;
  row_height?: number;
  gap?: number;
  compact_type?: 'vertical' | 'horizontal' | 'none';
  default_refresh_interval?: number; // seconds
  allow_personal_layouts?: boolean;
  allow_widget_export?: boolean;
}

export interface ViewDefaults {
  default_page_size?: number;
  default_row_height?: 'compact' | 'default' | 'tall';
  allow_personal_filters?: boolean;
  max_export_rows?: number;
}

export interface DataRetention {
  audit_log_retention_days?: number;
  query_cache_default_ttl?: number; // seconds
  soft_delete_retention_days?: number;
  version_history_limit?: number;
  backup_frequency?: 'daily' | 'weekly' | 'monthly';
}

export interface NotificationDefaults {
  email_from_name?: string;
  email_from_address?: string;
  email_footer?: string;
  slack_webhook_url?: string;
  teams_webhook_url?: string;
}

export interface ImportExportSettings {
  max_import_rows?: number;
  max_file_size_mb?: number;
  allowed_import_formats?: string[]; // ["csv", "xlsx", "json"]
  allowed_export_formats?: string[];
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'global_settings',
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  versionKey: false,
})
export class GlobalSettings {
  // ── Scope ───────────────────────────────────────────────────────────────

  @Prop({ required: true, enum: ['organization', 'project', 'workspace'] })
  scope_type: SettingsScope;

  @Prop({ required: true })
  scope_id: string; // UUID of the org, project, or workspace

  @Prop({ required: true, index: true })
  organization_id: string; // always present for tenant isolation

  // ── Settings Sections ───────────────────────────────────────────────────

  @Prop({ type: Object })
  branding?: BrandingSettings;

  @Prop({ type: Object })
  security?: SecuritySettings;

  @Prop({ type: Object, default: {} })
  features: Record<string, boolean>; // feature flags

  @Prop({ type: Object })
  dashboard_defaults?: DashboardDefaults;

  @Prop({ type: Object })
  view_defaults?: ViewDefaults;

  @Prop({ type: Object })
  data_retention?: DataRetention;

  @Prop({ type: Object })
  notification_defaults?: NotificationDefaults;

  @Prop({ type: Object })
  import_export?: ImportExportSettings;

  // ── Metadata ────────────────────────────────────────────────────────────

  @Prop()
  updated_by?: string; // UUID

  // ── Timestamps (managed by Mongoose) ────────────────────────────────────
  created_at: Date;
  updated_at: Date;
}

// ── Document type ───────────────────────────────────────────────────────────

export type GlobalSettingsDocument = GlobalSettings & Document;

// ── Schema factory ──────────────────────────────────────────────────────────

export const GlobalSettingsSchema =
  SchemaFactory.createForClass(GlobalSettings);

// ── Indexes ─────────────────────────────────────────────────────────────────

// One settings doc per scope
GlobalSettingsSchema.index(
  { scope_type: 1, scope_id: 1 },
  { name: 'idx_global_settings_scope', unique: true },
);

// Get all settings for an org
GlobalSettingsSchema.index(
  { organization_id: 1, scope_type: 1 },
  { name: 'idx_global_settings_org' },
);
