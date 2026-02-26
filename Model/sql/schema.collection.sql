-- ============================================================================
-- schema.collection.sql — Dynamic Collection Schema System
-- ============================================================================
--
-- DOMAIN: Polymorphic data engine for tenant-defined data structures.
--
-- This is the core of the platform's "Airtable-like" functionality.
-- Collections are "tables" that tenants define at runtime. The actual row
-- data lives in MongoDB (collection_records), but the STRUCTURE (columns,
-- types, validation, relations) is defined here so the backend can:
--   • Validate data on write
--   • Generate MongoDB indexes dynamically
--   • Serve correct UI controls (form fields, filters, sorts)
--   • Enforce relational integrity between tenant-defined tables
--
-- DATA FLOW:
--   1. Tenant creates a Collection (like a spreadsheet / database table)
--   2. Tenant adds Fields (columns) with types, validation rules
--   3. Backend generates MongoDB indexes from collection_indices
--   4. Frontend renders forms/tables/kanban based on field definitions
--   5. Records are stored in MongoDB → collection_records
--   6. When records are created/updated, backend validates against fields table
--
-- SQL ↔ MongoDB BOUNDARY:
--   SQL (here): Schema definition, field metadata, relation types, indexes
--   MongoDB:    Actual row data (collection_records), flexible nested values
--   This split keeps structural integrity in SQL while allowing flexible
--   per-record data in MongoDB — best of both worlds.
--
-- EXECUTION ORDER: Run AFTER schema.organization.sql (depends on workspaces).
-- ============================================================================

-- ─────────────────────────────────────────────────────────────────────────────
-- COLLECTIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- A tenant-defined data table. Analogous to a spreadsheet or database table
-- but defined at runtime, not at database design time.
--
-- RELATIONSHIPS:
--   collections.workspace_id ──→ workspaces.id        (N:1) Parent workspace
--   collections.created_by   ──→ users.id             (N:1) Who created this collection
--   collections.updated_by   ──→ users.id             (N:1) Who last modified the schema
--   collections.id           ←── fields.collection_id (1:N) Column definitions
--   collections.id           ←── collection_relations.source_collection_id (1:N) Outgoing relations
--   collections.id           ←── collection_relations.target_collection_id (1:N) Incoming relations
--   collections.id           ←── collection_indices.collection_id          (1:N) Custom indexes
--   collections.id           ←── views.collection_id  (1:N) Saved views of this data
--   collections.id           ←── adapter_mappings.collection_id            (1:N) External data maps
--
-- JOIN PATHS:
--   Workspace → Collections:  workspaces → collections
--   Collection → Fields:      collections → fields → field_options
--   Collection → Views:       collections → views
--   Collection → Relations:   collections → collection_relations → collections (self-join)
--   Collection → MongoDB:     collections.id = collection_records.collection_id (in MongoDB)
--   Full hierarchy:           organizations → projects → workspaces → collections → fields
--
-- NOTES:
--   • (workspace_id, slug) is UNIQUE — collection names unique per workspace
--   • is_system: protected collections that the platform uses internally
--   • record_count is DENORMALIZED for performance (count from MongoDB is expensive).
--     Updated by application triggers. This is a conscious 5NF trade-off documented here.
--     The canonical count is always: db.collection_records.countDocuments({collection_id: X})
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE collections (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    workspace_id    UUID            NOT NULL REFERENCES workspaces(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    slug            VARCHAR(100)    NOT NULL,
    description     TEXT,
    icon            VARCHAR(50),
    color           VARCHAR(7),
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,     -- system collections are protected
    record_count    INT             NOT NULL DEFAULT 0,         -- denormalized; see NOTES above
    created_by      UUID            NOT NULL REFERENCES users(id),
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (workspace_id, slug)
);

COMMENT ON TABLE collections IS
    'Schema definitions for tenant-created data tables. Actual records are in MongoDB collection_records.';

-- ─────────────────────────────────────────────────────────────────────────────
-- FIELDS (Column Definitions)
-- ─────────────────────────────────────────────────────────────────────────────
-- Each field describes a column in a collection. The field_type determines
-- which UI control is rendered and how data is validated on write.
--
-- RELATIONSHIPS:
--   fields.collection_id ──→ collections.id         (N:1) Parent collection
--   fields.id            ←── field_options.field_id  (1:N) Dropdown options (for select types)
--   fields.id            ←── collection_relations.source_field_id (1:N) Relation source
--   fields.id            ←── collection_relations.target_field_id (1:N) Relation target
--
-- JOIN PATHS:
--   Collection → Fields:  collections → fields
--   Field → Options:      fields → field_options (WHERE field_type IN ('select','multi_select'))
--   Field → Relations:    fields → collection_relations → collections
--   Full schema:          workspaces → collections → fields → field_options
--
-- FIELD TYPES AND THEIR MEANING:
--   'text','long_text'    → String fields (short / multi-line)
--   'number','decimal'    → Numeric (integer / float)
--   'date','datetime'     → Temporal values
--   'select','multi_select' → Dropdown with options from field_options table
--   'relation'            → FK-like link to another collection (via collection_relations)
--   'lookup','rollup'     → Computed fields pulling data across relations
--   'formula'             → Client-side calculated field
--   'file','image'        → Attachment fields (stored via file_uploads)
--   'auto_number'         → Auto-incrementing counter per collection
--   'created_at','updated_at','created_by','updated_by' → system-managed audit fields
--
-- NOTES:
--   • (collection_id, slug) is UNIQUE — field slugs unique per collection
--   • is_primary marks the "display name" field (like a table's title column)
--   • is_system marks auto-managed fields (created_at, updated_by, etc.)
--   • validation_rules JSONB: {min, max, pattern, min_length, max_length, etc.}
--   • display_config JSONB: {width, align, format, prefix, suffix, etc.}
--   • sort_order controls column display order in table/form views
--   • updated_by tracks who last modified this field definition
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE fields (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id   UUID            NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    slug            VARCHAR(100)    NOT NULL,
    field_type      VARCHAR(50)     NOT NULL
                    CHECK (field_type IN (
                        'text','long_text','number','decimal','boolean',
                        'date','datetime','email','url','phone',
                        'select','multi_select','checkbox',
                        'relation','lookup','rollup','formula',
                        'file','image','attachment',
                        'json','rich_text','markdown',
                        'currency','percent','rating','duration',
                        'auto_number','created_at','updated_at','created_by','updated_by'
                    )),
    is_required     BOOLEAN         NOT NULL DEFAULT FALSE,
    is_unique       BOOLEAN         NOT NULL DEFAULT FALSE,
    is_primary      BOOLEAN         NOT NULL DEFAULT FALSE,     -- primary display field
    is_system       BOOLEAN         NOT NULL DEFAULT FALSE,     -- auto-managed fields
    is_hidden       BOOLEAN         NOT NULL DEFAULT FALSE,
    default_value   JSONB,                                      -- type-dependent default
    validation_rules JSONB          NOT NULL DEFAULT '{}',      -- { min, max, pattern, etc. }
    display_config  JSONB           NOT NULL DEFAULT '{}',      -- { width, align, format, etc. }
    sort_order      INT             NOT NULL DEFAULT 0,
    updated_by      UUID            REFERENCES users(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),
    updated_at      TIMESTAMPTZ     NOT NULL DEFAULT now(),

    UNIQUE (collection_id, slug)
);

COMMENT ON TABLE fields IS
    'Column definitions for collections. Controls validation, UI rendering, and data types.';

-- ─────────────────────────────────────────────────────────────────────────────
-- FIELD OPTIONS (for select/multi_select fields)
-- ─────────────────────────────────────────────────────────────────────────────
-- Enumeration values for dropdown-type fields.
--
-- RELATIONSHIPS:
--   field_options.field_id ──→ fields.id (N:1) The select/multi_select field
--
-- JOIN PATHS:
--   Field → Options: fields → field_options (ORDER BY sort_order)
--   Full chain:      collections → fields → field_options
--
-- NOTES:
--   • (field_id, value) is UNIQUE — no duplicate option values per field
--   • label is the display text; value is the stored/programmatic identifier
--   • color supports UI chip/tag coloring
--   • sort_order controls dropdown display order
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE field_options (
    id          UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    field_id    UUID            NOT NULL REFERENCES fields(id) ON DELETE CASCADE,
    label       VARCHAR(255)    NOT NULL,
    value       VARCHAR(255)    NOT NULL,
    color       VARCHAR(7),
    sort_order  INT             NOT NULL DEFAULT 0,

    UNIQUE (field_id, value)
);

-- ─────────────────────────────────────────────────────────────────────────────
-- COLLECTION RELATIONS
-- ─────────────────────────────────────────────────────────────────────────────
-- Explicit relationships between tenant-defined collections, analogous
-- to foreign keys between tables.
--
-- RELATIONSHIPS:
--   collection_relations.source_collection_id ──→ collections.id (N:1) Source ("from") collection
--   collection_relations.target_collection_id ──→ collections.id (N:1) Target ("to") collection
--   collection_relations.source_field_id      ──→ fields.id      (N:1) The relation field on source
--   collection_relations.target_field_id      ──→ fields.id      (N:1) Optional: back-reference field
--   collection_relations.junction_collection_id ──→ collections.id (N:1) For many_to_many: the junction
--
-- JOIN PATHS:
--   Collection → Outgoing relations: collections → collection_relations (source_collection_id)
--   Collection → Incoming relations: collections → collection_relations (target_collection_id)
--   Relation → Fields: collection_relations → fields (source_field_id, target_field_id)
--
-- NOTES:
--   • relation_type: one_to_one, one_to_many, many_to_many
--   • junction_collection_id: only used for many_to_many (the intermediate table)
--   • on_delete_action: how MongoDB records handle deletion (cascade, set_null, restrict)
--   • These relations are enforced at application level in MongoDB, not by SQL constraints
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE collection_relations (
    id                      UUID        PRIMARY KEY DEFAULT gen_random_uuid(),
    source_collection_id    UUID        NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    target_collection_id    UUID        NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    source_field_id         UUID        NOT NULL REFERENCES fields(id) ON DELETE CASCADE,
    target_field_id         UUID        REFERENCES fields(id) ON DELETE SET NULL,
    relation_type           VARCHAR(20) NOT NULL
                            CHECK (relation_type IN ('one_to_one','one_to_many','many_to_many')),
    junction_collection_id  UUID        REFERENCES collections(id) ON DELETE SET NULL,
    on_delete_action        VARCHAR(20) NOT NULL DEFAULT 'set_null'
                            CHECK (on_delete_action IN ('cascade','set_null','restrict','no_action')),
    created_at              TIMESTAMPTZ NOT NULL DEFAULT now()
);

-- ─────────────────────────────────────────────────────────────────────────────
-- COLLECTION INDICES
-- ─────────────────────────────────────────────────────────────────────────────
-- Tenant-defined indexes that are synced into MongoDB as compound indexes
-- on collection_records documents.
--
-- RELATIONSHIPS:
--   collection_indices.collection_id ──→ collections.id (N:1) The collection being indexed
--
-- JOIN PATHS:
--   Collection → Indexes: collections → collection_indices
--
-- BACKEND SYNC FLOW:
--   1. Tenant creates index via UI → row inserted here
--   2. Backend reads field_slugs and builds MongoDB index spec
--   3. Backend calls db.collection_records.createIndex() with the compound key
--   4. On deletion, backend drops the corresponding MongoDB index
--
-- NOTES:
--   • field_slugs is an ordered array of field slug names (maps to MongoDB doc keys)
--   • is_unique: creates a unique constraint in MongoDB
--   • is_sparse: skips documents where indexed fields are null/missing
-- ─────────────────────────────────────────────────────────────────────────────

CREATE TABLE collection_indices (
    id              UUID            PRIMARY KEY DEFAULT gen_random_uuid(),
    collection_id   UUID            NOT NULL REFERENCES collections(id) ON DELETE CASCADE,
    name            VARCHAR(255)    NOT NULL,
    field_slugs     TEXT[]          NOT NULL,                    -- ordered: {"email","status"}
    is_unique       BOOLEAN         NOT NULL DEFAULT FALSE,
    is_sparse       BOOLEAN         NOT NULL DEFAULT FALSE,
    created_at      TIMESTAMPTZ     NOT NULL DEFAULT now()
);

COMMENT ON TABLE collection_indices IS
    'Declarative indexes that the backend syncs into MongoDB for collection_records.';
