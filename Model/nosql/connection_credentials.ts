// ============================================================================
// connection_credentials.ts — Encrypted Credential Vault (MongoDB)
// ============================================================================
// Stores sensitive database credentials separately from SQL metadata.
// All credential fields are encrypted at the application layer before
// being written to MongoDB.
//
// WHY MONGODB:
//   • Credential shapes vary wildly by engine (PG password vs MongoDB URI
//     vs SSH key pair vs OAuth token)
//   • Rotation history is append-only with varying metadata
//   • Encryption metadata (IV, key version) is per-document
//   • Avoids storing secrets in PostgreSQL where they'd appear in
//     pg_dump backups and WAL logs
//
// SQL LINK:
//   database_connections.credential_ref → connection_credentials._id
//   The SQL side stores only a UUID pointer; all sensitive data lives here.
//
// SECURITY:
//   • All values in `credentials` are AES-256-GCM encrypted at app level
//   • `encryption_key_id` references the KMS key used for encryption
//   • Rotation creates a new document version; old credentials are kept
//     in rotation_history for rollback
//   • TTL index on `expires_at` auto-deletes expired temporary credentials
// ============================================================================

import { Prop, Schema, SchemaFactory } from '@nestjs/mongoose';
import { HydratedDocument } from 'mongoose';

// ── Types ───────────────────────────────────────────────────────────────────

/** Credential type determines which fields are populated */
export type CredentialType =
  | 'password' // username + password
  | 'connection_uri' // full connection string (encrypted)
  | 'ssh_key' // SSH private key for tunnel
  | 'ssl_certificate' // client SSL cert + key
  | 'api_token' // API token / bearer token
  | 'oauth2' // OAuth2 client credentials
  | 'iam_role'; // AWS IAM / GCP service account

/** Credential status */
export type CredentialStatus = 'active' | 'rotating' | 'expired' | 'revoked';

/** Encrypted credential payload — all string values are AES-256-GCM ciphertext */
export interface EncryptedCredentials {
  // ── Password auth ───────────────────────────────────────────────────────
  /** Encrypted database username */
  username?: string;

  /** Encrypted database password */
  password?: string;

  /** Encrypted full connection URI (e.g., postgresql://user:pass@host/db) */
  connection_uri?: string;

  // ── SSL / TLS ───────────────────────────────────────────────────────────
  /** Encrypted client SSL certificate (PEM) */
  ssl_cert?: string;

  /** Encrypted client SSL private key (PEM) */
  ssl_key?: string;

  /** Encrypted CA certificate for server verification (PEM) */
  ssl_ca?: string;

  // ── SSH Tunnel ──────────────────────────────────────────────────────────
  /** Encrypted SSH private key (PEM / OpenSSH format) */
  ssh_private_key?: string;

  /** SSH passphrase for the private key (encrypted) */
  ssh_passphrase?: string;

  /** SSH known hosts entry */
  ssh_known_hosts?: string;

  // ── API / OAuth ─────────────────────────────────────────────────────────
  /** Encrypted API token / bearer token */
  api_token?: string;

  /** Encrypted OAuth2 client ID */
  oauth_client_id?: string;

  /** Encrypted OAuth2 client secret */
  oauth_client_secret?: string;

  /** Encrypted OAuth2 refresh token */
  oauth_refresh_token?: string;

  /** OAuth2 token endpoint URL (not encrypted — public info) */
  oauth_token_url?: string;

  /** OAuth2 scopes (not encrypted — public info) */
  oauth_scopes?: string[];

  // ── IAM / Service Account ──────────────────────────────────────────────
  /** Encrypted service account JSON key (GCP) or role ARN (AWS) */
  service_account_key?: string;

  /** IAM role ARN for assumption (AWS) */
  iam_role_arn?: string;

  /** External ID for cross-account IAM (AWS) */
  iam_external_id?: string;
}

/** Encryption metadata for the credential document */
export interface EncryptionMeta {
  /** KMS key ID or key alias used for encryption */
  key_id: string;

  /** Key version (for key rotation) */
  key_version: number;

  /** Encryption algorithm */
  algorithm: string;

  /** Initialization vector (base64) */
  iv: string;

  /** Authentication tag (base64) — for GCM mode */
  auth_tag?: string;
}

/** Rotation history entry */
export interface RotationEntry {
  /** When the rotation occurred */
  rotated_at: Date;

  /** Who triggered the rotation (user_id or 'system') */
  rotated_by: string;

  /** Reason for rotation */
  reason: string;

  /** Previous encryption_meta (for rollback decryption) */
  previous_encryption_meta: EncryptionMeta;

  /** Previous credentials snapshot (encrypted with previous key) */
  previous_credentials: EncryptedCredentials;
}

/** Auto-rotation policy */
export interface RotationPolicy {
  /** Whether auto-rotation is enabled */
  enabled: boolean;

  /** Rotation interval in days */
  interval_days: number;

  /** Last auto-rotation timestamp */
  last_rotation_at?: Date;

  /** Next scheduled rotation */
  next_rotation_at?: Date;

  /** Strategy: 'generate' (platform creates new password) or 'notify' (alert user) */
  strategy: 'generate' | 'notify';
}

// ── Schema ──────────────────────────────────────────────────────────────────

@Schema({
  collection: 'connection_credentials',
  timestamps: true,
  versionKey: false,
})
export class ConnectionCredentials {
  // ── Identity ────────────────────────────────────────────────────────────

  /** References database_connections.credential_ref (SQL) */
  @Prop({ required: true, index: true })
  connection_id!: string;

  /** Organization ID — for multi-tenant isolation */
  @Prop({ required: true, index: true })
  organization_id!: string;

  /** Human-readable label (e.g., "Production PG Credentials") */
  @Prop({ required: true })
  label!: string;

  // ── Credential Data ─────────────────────────────────────────────────────

  /** Type of credential stored */
  @Prop({
    required: true,
    enum: [
      'password',
      'connection_uri',
      'ssh_key',
      'ssl_certificate',
      'api_token',
      'oauth2',
      'iam_role',
    ],
  })
  credential_type!: CredentialType;

  /** Encrypted credential payload — ALL values are ciphertext */
  @Prop({ type: Object, required: true })
  credentials!: EncryptedCredentials;

  /** Encryption metadata (key ID, IV, algorithm) */
  @Prop({ type: Object, required: true })
  encryption_meta!: EncryptionMeta;

  // ── Lifecycle ───────────────────────────────────────────────────────────

  /** Current credential status */
  @Prop({
    required: true,
    enum: ['active', 'rotating', 'expired', 'revoked'],
    default: 'active',
  })
  status!: CredentialStatus;

  /** When these credentials expire (null = no expiry) */
  @Prop()
  expires_at?: Date;

  /** Auto-rotation configuration */
  @Prop({
    type: Object,
    default: { enabled: false, interval_days: 90, strategy: 'notify' },
  })
  rotation_policy!: RotationPolicy;

  /** History of credential rotations (keep last N entries) */
  @Prop({ type: [Object], default: [] })
  rotation_history!: RotationEntry[];

  // ── Audit ───────────────────────────────────────────────────────────────

  /** Who created these credentials (user_id) */
  @Prop({ required: true })
  created_by!: string;

  /** Who last modified these credentials (user_id) */
  @Prop()
  updated_by?: string;

  /** Last time these credentials were used for a connection */
  @Prop()
  last_used_at?: Date;

  /** Number of times these credentials have been used */
  @Prop({ default: 0 })
  usage_count!: number;

  /** Last connection test result */
  @Prop()
  last_test_result?: string;

  /** Last connection test timestamp */
  @Prop()
  last_tested_at?: Date;
}

export type ConnectionCredentialsDocument =
  HydratedDocument<ConnectionCredentials>;
export const ConnectionCredentialsSchema = SchemaFactory.createForClass(
  ConnectionCredentials,
);

// ── Indexes ──────────────────────────────────────────────────────────────────
ConnectionCredentialsSchema.index({ connection_id: 1 }, { unique: true });
ConnectionCredentialsSchema.index({ organization_id: 1, status: 1 });
ConnectionCredentialsSchema.index(
  { expires_at: 1 },
  {
    expireAfterSeconds: 0,
    partialFilterExpression: { expires_at: { $exists: true } },
  },
);
