// ============================================================================
// user_preferences.ts — Per-User Settings & Preferences (MongoDB / Mongoose)
// ============================================================================
// Everything personal to a user that doesn't need relational integrity:
// theme, locale, notification settings, sidebar state, recent items, etc.
//
// One document per user — simple upsert pattern.
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { Document } from 'mongoose';

// ── Interfaces ──────────────────────────────────────────────────────────────

export type Theme = 'light' | 'dark' | 'system' | 'high_contrast';
export type FontSize = 'small' | 'medium' | 'large';
export type UIDensity = 'compact' | 'comfortable' | 'spacious';
export type TimeFormat = '12h' | '24h';
export type FirstDayOfWeek = 'sunday' | 'monday' | 'saturday';
export type DigestFrequency =
  | 'realtime'
  | 'hourly'
  | 'daily'
  | 'weekly'
  | 'none';
export type PinnableType = 'workspace' | 'collection' | 'dashboard' | 'view';
export type RecentType =
  | 'dashboard'
  | 'collection'
  | 'view'
  | 'workspace'
  | 'record';

export interface NumberFormat {
  decimal_separator?: string;
  thousands_separator?: string;
  currency?: string;
}

export interface QuietHours {
  enabled: boolean;
  start: string; // HH:mm
  end: string; // HH:mm
  timezone?: string;
}

export interface NotificationChannels {
  [type: string]: {
    // e.g., "mention", "comment", "share"
    email?: boolean;
    push?: boolean;
    in_app?: boolean;
  };
}

export interface NotificationPreferences {
  email_enabled?: boolean;
  push_enabled?: boolean;
  in_app_enabled?: boolean;
  digest_frequency?: DigestFrequency;
  channels?: NotificationChannels;
  quiet_hours?: QuietHours;
}

export interface SidebarPinnedItem {
  type: PinnableType;
  id: string;
  label: string;
}

export interface SidebarPreferences {
  is_collapsed?: boolean;
  width?: number;
  pinned_items?: SidebarPinnedItem[];
  collapsed_sections?: string[];
}

export interface RecentItem {
  type: RecentType;
  id: string;
  name: string;
  workspace_id?: string;
  accessed_at: Date;
}

export interface FavoriteItem {
  type: RecentType;
  id: string;
  name: string;
  added_at: Date;
}

export interface OnboardingState {
  completed?: boolean;
  completed_at?: Date;
  dismissed_tips?: string[]; // tip/tutorial IDs
  current_step?: string;
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'user_preferences',
  timestamps: { createdAt: 'created_at', updatedAt: 'updated_at' },
  versionKey: false,
})
export class UserPreferences {
  @Prop({ required: true, unique: true })
  user_id: string; // UUID FK → SQL users.id

  // ── Appearance ──────────────────────────────────────────────────────────

  @Prop({
    enum: ['light', 'dark', 'system', 'high_contrast'],
    default: 'system',
  })
  theme: Theme;

  @Prop()
  accent_color?: string; // hex color

  @Prop({ enum: ['small', 'medium', 'large'], default: 'medium' })
  font_size: FontSize;

  @Prop({
    enum: ['compact', 'comfortable', 'spacious'],
    default: 'comfortable',
  })
  density: UIDensity;

  // ── Locale ──────────────────────────────────────────────────────────────

  @Prop({ default: 'en-US' })
  locale: string; // ISO locale code

  @Prop({ default: 'UTC' })
  timezone: string; // IANA timezone

  @Prop({ default: 'YYYY-MM-DD' })
  date_format: string;

  @Prop({ enum: ['12h', '24h'], default: '24h' })
  time_format: TimeFormat;

  @Prop({ enum: ['sunday', 'monday', 'saturday'], default: 'monday' })
  first_day_of_week: FirstDayOfWeek;

  @Prop({ type: Object })
  number_format?: NumberFormat;

  // ── Notification Preferences ────────────────────────────────────────────

  @Prop({ type: Object })
  notifications?: NotificationPreferences;

  // ── Sidebar & Navigation ────────────────────────────────────────────────

  @Prop({ type: Object })
  sidebar?: SidebarPreferences;

  // ── Recently Accessed (last 50, newest first) ───────────────────────────

  @Prop({ type: [Object], default: [] })
  recent_items: RecentItem[];

  // ── Favorites / Bookmarks ───────────────────────────────────────────────

  @Prop({ type: [Object], default: [] })
  favorites: FavoriteItem[];

  // ── Default Context ─────────────────────────────────────────────────────

  @Prop()
  default_organization_id?: string;

  @Prop()
  default_project_id?: string;

  @Prop()
  default_workspace_id?: string;

  // ── Keyboard Shortcuts ──────────────────────────────────────────────────
  // Custom keybinding overrides: { "save": "Ctrl+S", "search": "Ctrl+K" }

  @Prop({ type: Object })
  keyboard_shortcuts?: Record<string, string>;

  // ── Onboarding ──────────────────────────────────────────────────────────

  @Prop({ type: Object })
  onboarding?: OnboardingState;

  // ── Timestamps (managed by Mongoose) ────────────────────────────────────
  created_at: Date;
  updated_at: Date;
}

// ── Document type ───────────────────────────────────────────────────────────

export type UserPreferencesDocument = UserPreferences & Document;

// ── Schema factory ──────────────────────────────────────────────────────────

export const UserPreferencesSchema =
  SchemaFactory.createForClass(UserPreferences);

// ── Indexes ─────────────────────────────────────────────────────────────────

// One preferences doc per user (unique index on user_id set via @Prop)
UserPreferencesSchema.index(
  { user_id: 1 },
  { name: 'idx_user_preferences_user', unique: true },
);
