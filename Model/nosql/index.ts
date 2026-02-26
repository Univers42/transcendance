// ============================================================================
// index.ts — Barrel Export for all MongoDB Mongoose Schemas
// ============================================================================
// Import this file to register all schemas with NestJS MongooseModule:
//
//   import {
//     CollectionRecord, CollectionRecordSchema,
//     DashboardLayout, DashboardLayoutSchema,
//     ...
//   } from '@model/nosql';
//
//   @Module({
//     imports: [
//       MongooseModule.forFeature([
//         { name: CollectionRecord.name, schema: CollectionRecordSchema },
//         { name: DashboardLayout.name,  schema: DashboardLayoutSchema },
//         { name: ViewConfig.name,       schema: ViewConfigSchema },
//         { name: UserPreferences.name,  schema: UserPreferencesSchema },
//         { name: QueryCache.name,       schema: QueryCacheSchema },
//         { name: WorkflowDefinition.name, schema: WorkflowDefinitionSchema },
//         { name: WorkflowExecution.name,  schema: WorkflowExecutionSchema },
//         { name: GlobalSettings.name,   schema: GlobalSettingsSchema },
//         { name: AuditLog.name,         schema: AuditLogSchema },
//         { name: SyncState.name,        schema: SyncStateSchema },
//         { name: ConnectionCredentials.name, schema: ConnectionCredentialsSchema },
//         { name: AbacRuleCondition.name,    schema: AbacRuleConditionSchema },
//         { name: AbacUserAttribute.name,    schema: AbacUserAttributeSchema },
//       ]),
//     ],
//   })
// ============================================================================

// ── Collection Records (polymorphic business data) ─────────────────────────
export {
  CollectionRecord,
  CollectionRecordDocument,
  CollectionRecordSchema,
  type CollectionRecordRelations,
} from './collection_records';

// ── Dashboard Layouts (widget positions, personal/shared/template) ─────────
export {
  DashboardLayout,
  DashboardLayoutDocument,
  DashboardLayoutSchema,
  type LayoutScope,
  type WidgetType,
  type CompactType,
  type GridConfig,
  type GridMargin,
  type GridBreakpoints,
  type WidgetPosition,
  type WidgetDataSource,
  type DashboardWidget,
  type GlobalFilterType,
  type DashboardGlobalFilter,
} from './dashboard_layouts';

// ── View Configs (filters, sorts, field visibility, chart config) ──────────
export {
  ViewConfig,
  ViewConfigDocument,
  ViewConfigSchema,
  type ViewConfigScope,
  type SortDirection,
  type FilterLogic,
  type RowHeight,
  type FilterOperator,
  type VisibleField,
  type SortRule,
  type FilterCondition,
  type FilterGroup,
  type GroupByRule,
  type ChartType,
  type AggregationFn,
  type ChartYAxis,
  type KanbanConfig,
  type CalendarConfig,
  type GalleryConfig,
  type ChartConfig,
  type FormSection,
  type FormConfig,
  type TimelineConfig,
  type ConditionalFormat,
} from './view_configs';

// ── User Preferences (theme, locale, sidebar, favorites) ───────────────────
export {
  UserPreferences,
  UserPreferencesDocument,
  UserPreferencesSchema,
  type Theme,
  type FontSize,
  type UIDensity,
  type TimeFormat,
  type FirstDayOfWeek,
  type DigestFrequency,
  type NumberFormat,
  type QuietHours,
  type NotificationChannels,
  type NotificationPreferences,
  type SidebarPreferences,
  type SidebarPinnedItem,
  type RecentItem,
  type FavoriteItem,
  type OnboardingState,
} from './user_preferences';

// ── Query Cache (TTL-based aggregation cache) ──────────────────────────────
export {
  QueryCache,
  QueryCacheDocument,
  QueryCacheSchema,
  type QueryFingerprint,
} from './query_cache';

// ── Workflow States (definitions + execution runtime) ──────────────────────
export {
  WorkflowDefinition,
  WorkflowDefinitionDocument,
  WorkflowDefinitionSchema,
  WorkflowExecution,
  WorkflowExecutionDocument,
  WorkflowExecutionSchema,
  type TriggerType,
  type StepType,
  type ErrorStrategy,
  type WorkflowStatus,
  type StepStatus,
  type WorkflowTrigger,
  type WorkflowStep,
  type StepResult,
  type TriggerData,
} from './workflow_states';

// ── Global Settings (branding, security, feature flags) ────────────────────
export {
  GlobalSettings,
  GlobalSettingsDocument,
  GlobalSettingsSchema,
  type SettingsScope,
  type BrandingSettings,
  type PasswordPolicy,
  type SSOConfig,
  type SecuritySettings,
  type DashboardDefaults,
  type ViewDefaults,
  type DataRetention,
  type NotificationDefaults,
  type ImportExportSettings,
} from './global_settings';

// ── Audit Log (append-only change tracking) ────────────────────────────────
export {
  AuditLog,
  AuditLogDocument,
  AuditLogSchema,
  type ActorType,
  type AuditChanges,
} from './audit_log';

// ── Sync State (CDC cursors, replication lag, conflict queue) ───────────────
export {
  SyncState,
  SyncStateDocument,
  SyncStateSchema,
  type CdcEngine,
  type SyncHealth,
  type ConflictStatus,
  type ConflictDirection,
  type CdcCursor,
  type ConflictField,
  type ConflictEntry,
  type LagMeasurement,
} from './sync_state';

// ── Connection Credentials (encrypted credential vault) ────────────────────
export {
  ConnectionCredentials,
  ConnectionCredentialsDocument,
  ConnectionCredentialsSchema,
  type CredentialType,
  type CredentialStatus,
  type EncryptedCredentials,
  type EncryptionMeta,
  type RotationEntry,
  type RotationPolicy,
} from './connection_credentials';

// ── ABAC Rule Conditions (nested condition trees for rules) ────────────────
export {
  AbacRuleCondition,
  AbacRuleConditionDocument,
  AbacRuleConditionSchema,
  type ConditionOperator,
  type ConditionLogic,
  type LeafCondition,
  type BranchCondition,
  type ConditionNode,
  isBranchCondition,
  isLeafCondition,
} from './abac_rule_conditions';

// ── ABAC User Attributes (per-user flexible attribute store) ───────────────
export {
  AbacUserAttribute,
  AbacUserAttributeDocument,
  AbacUserAttributeSchema,
  type UserAttributes,
  type AttributeChangeEntry,
} from './abac_user_attributes';
