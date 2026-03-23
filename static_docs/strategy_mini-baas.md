# mini-baas — A Self-Adapting, Database-Agnostic Backend-as-a-Service

> **Core principle:** We are not building an app. We are building an App Factory.
> Our backend must transform itself at runtime to serve any business model it has never seen before — without a single line of hardcoded schema, controller, or model.

---

## What This Actually Is

Most backends are static: a developer writes a schema, a controller, a service, and deploys. That works for one product. It breaks completely for a platform.

This BaaS is different. **The backend has zero knowledge of any user's data model at build time.** When a request arrives, the system:

1. Reads the user's metadata (their schema definition or their existing database)
2. Constructs the correct model, query, and validation on the fly
3. Executes against the right database engine (SQL or NoSQL)
4. Returns a consistent, typed JSON response to the frontend

The backend *becomes* the right backend — for each user, on every request.

---

## The Two Core Problems We Solve

### Problem 1 — We Don't Know the Schema Ahead of Time

Traditional ORMs require you to define your models before deployment. We cannot do that: every user has a different data model.

**Our solution: Metadata-Driven Architecture**

Instead of hardcoded models, users define (or we discover) their data model as JSON metadata, stored in our system database. At request time, NestJS reads this metadata and generates a Mongoose model or a Knex query builder on the fly.

```
User says: "I want a Book entity with title (string) and price (number)"
              ↓
We store:  { entity: "book", tenantId: "user_23", fields: [...] }  →  system DB
              ↓
Request arrives at GET /api/v1/books
              ↓
Backend reads metadata → generates model → executes query → returns JSON
```

There is no `BookController`. There is no `BookSchema`. There is only one `DynamicController` and one `DynamicService` that handle every entity for every user.

---

### Problem 2 — Users Have Different Database Engines

Some users have Postgres. Some have MongoDB. Some use Supabase. We cannot force everyone onto the same engine — and we do not want to.

**Our solution: The Adapter Pattern**

We define a single, universal interface that every database engine must implement:

```typescript
// src/common/interfaces/database-adapter.interface.ts
export interface IDatabaseAdapter {
  connect(connectionString: string): Promise<void>;
  findOne(collection: string, filter: Record<string, any>): Promise<any>;
  findMany(collection: string, filter: Record<string, any>): Promise<any[]>;
  create(collection: string, data: Record<string, any>): Promise<any>;
  update(collection: string, id: string, data: Record<string, any>): Promise<any>;
  delete(collection: string, id: string): Promise<boolean>;
  introspect(): Promise<SchemaMetadata>;
}
```

NestJS injects the right adapter at request time based on the user's configuration. **The rest of the codebase never knows which engine it is talking to.** A `findOne` is always a `findOne`, whether it runs as `SELECT * FROM books WHERE id = 5` or `db.books.find({ _id: 5 })`.

---

## How the Backend Transforms Itself: The Full Flow

```
Incoming request:  GET /api/v1/user_23/books/42
                              ↓
           [ TenantInterceptor ] — reads x-tenant-id header
                              ↓
           Loads tenant config from system DB:
           { dbType: "postgresql", uri: "postgres://...", schemaMap: {...} }
                              ↓
           [ DatabaseProvider Factory ] — injects PostgresAdapter or MongoAdapter
                              ↓
           [ DynamicController ] — receives entity = "books", id = "42"
                              ↓
           [ DynamicService ] — fetches metadata for "books" from schema map
                              ↓
           Calls: adapter.findOne("books", { id: "42" })
                              ↓
           PostgresAdapter translates: SELECT * FROM books WHERE id = 42
           (or MongoAdapter translates: db.books.findOne({ _id: 42 }))
                              ↓
           Transform Layer normalizes the result to consistent JSON
                              ↓
                       Response to frontend
```

No matter which engine is underneath, the frontend always receives the same shape of response. The backend adapted itself.

---

## How We Discover the Schema (Without Being Told)

We support four connection modes. In all cases, the result is the same: a **Metadata Map** that our dynamic system can read.

| Mode | How it works |
|------|-------------|
| **1. Direct DB connection** | User provides a connection string. We run `INFORMATION_SCHEMA` queries (Postgres) or collection inspection (Mongo). We read every table, column type, relation, and index. |
| **2. Supabase / cloud hosted** | User provides project URL + service role key. We connect directly to the underlying Postgres and run the same introspection. |
| **3. Manual schema upload** | User pastes or uploads a SQL dump, Prisma schema, JSON schema, or OpenAPI spec. We parse it and build the metadata map from that. |
| **4. Existing REST/GraphQL API** | User points us at an OpenAPI spec or GraphQL endpoint. We parse the spec to construct the routing and type map. |

The introspection result is always the same internal structure — a `SchemaMetadata` object the rest of the system depends on.

---

## Database Engine Support: SQL and NoSQL Together

We support both engines simultaneously. Users choose based on their needs:

- **MongoDB (NoSQL):** Maximum flexibility. Schema is validated at runtime via AJV/Zod using the stored metadata. Ideal for users who need speed and evolving data models.
- **Postgres (SQL):** Full relational integrity, foreign keys, complex joins. Ideal for users with existing structured data or strict compliance requirements.

```
User's choice        Engine injected        Query style
─────────────────    ───────────────────    ─────────────────────────────────
MongoDB (hosted)  →  MongoAdapter        →  db.collection.find({ ... })
Postgres (BYOD)   →  PostgresAdapter     →  knex(table).where({ ... })
Supabase          →  PostgresAdapter     →  (same, via Postgres connection)
```

Adding a new engine (MySQL, SQLite, CockroachDB) means writing one new Adapter class. No other code changes.

---

## Architecture Overview

```
src/
├── engines/
│   ├── sql.engine.ts          — Knex-based adapter for Postgres/MySQL
│   └── nosql.engine.ts        — MongoDB native driver adapter
│
├── database/
│   └── database.provider.ts   — Factory: injects correct adapter per request
│
├── dynamic-api/
│   ├── dynamic.controller.ts  — Single entry point: /:tenantId/:entityName
│   ├── dynamic.service.ts     — Orchestrates metadata lookup + adapter calls
│   └── dynamic.validator.ts   — Runtime validation via AJV/Zod from metadata
│
├── schema/
│   ├── introspection.service.ts — Runs DB discovery for all four connection modes
│   └── metadata.store.ts        — Reads/writes schema metadata to system DB
│
├── tenant/
│   └── tenant.interceptor.ts  — Resolves tenant config from every request
│
└── hooks/
    └── hook.runner.ts         — Executes user-defined cloud functions via isolated-vm
```

---

## The Generic Controller and Service

We write exactly one controller and one service. They handle every entity for every user.

**Controller** (`/:tenantId/:entityName`)
```typescript
@Controller(':entityName')
export class DynamicController {
  constructor(
    @Inject('DATABASE_ADAPTER') private readonly db: IDatabaseAdapter
  ) {}

  @Get(':id')
  getOne(@Param('entityName') entity: string, @Param('id') id: string) {
    // Works identically for SQL and NoSQL
    return this.db.findOne(entity, { id });
  }

  @Post()
  async create(
    @Param('entityName') entity: string,
    @Body() body: Record<string, any>
  ) {
    // Validate against runtime schema before writing
    await this.validator.validate(entity, body);
    return this.db.create(entity, body);
  }
}
```

**Service flow** (inside `DynamicService`):
1. Identify the tenant and entity from the request path
2. Fetch the metadata for that entity from the schema store
3. Run the incoming body through a dynamic validator (AJV or Zod, built from metadata)
4. Call the injected adapter (`this.db.create(...)`, `this.db.findMany(...)`, etc.)
5. Return normalized JSON

---

## The Database Provider Factory (The "Switch")

This is where NestJS decides which engine to use — once per request, based on tenant config:

```typescript
// src/database/database.provider.ts
export const DatabaseProvider = {
  provide: 'DATABASE_ADAPTER',
  scope: Scope.REQUEST,  // Critical: resolved fresh on every request
  useFactory: async (configService: ConfigService, request: Request): Promise<IDatabaseAdapter> => {
    const tenantConfig = await configService.getTenantConfig(
      request.headers['x-tenant-id']
    );

    if (tenantConfig.dbType === 'postgresql') {
      const adapter = new PostgresAdapter();
      await adapter.connect(tenantConfig.uri);
      return adapter;
    }

    const adapter = new MongoAdapter();
    await adapter.connect(tenantConfig.uri);
    return adapter;
  },
  inject: [ConfigService, REQUEST],
};
```

`Scope.REQUEST` is the key: NestJS rebuilds this provider for every incoming request, so every user always gets their own isolated adapter instance pointing at their own database.

---

## Frontend Discovery: How the Client Knows What to Do

The frontend never hardcodes entity names, field types, or API routes. Instead:

- **`/discovery` endpoint:** On load, the frontend calls this and receives the full schema map for that tenant — all entities, all fields, all types, all permissions.
- **Universal Client SDK:** Instead of `axios.post('/books')`, the user's frontend uses `baas.collection('books').create({ title: 'My Book' })`. The SDK reads the discovery map and handles routing internally.

This means: **when a user adds a new entity to their schema, the frontend automatically supports it — with zero frontend code changes.**

---

## Custom Business Logic: The Hook System

When a user needs logic like "when a book is created, send a confirmation email," we cannot hardcode that. We use a sandboxed hook runner:

- Users define hooks (small JS functions) per entity + event (`onCreate`, `onUpdate`, etc.)
- We execute them inside `isolated-vm` — a secure V8 isolate — so user code cannot access our server environment
- Hooks receive the entity data as input and can trigger outbound calls (webhooks, emails via Resend, etc.)

---

## Full Technology Stack

| Layer | Technology | Why |
|-------|-----------|-----|
| Framework | NestJS + TypeScript | Modular DI system is essential for the Adapter pattern |
| System DB | MongoDB | Stores schema metadata, tenant configs, hook definitions |
| SQL Engine | Knex.js | Dynamic query builder — no static models required |
| NoSQL Engine | MongoDB Native Driver | Direct, schema-free collection access |
| Validation | AJV / Zod | Build validators at runtime from metadata |
| Auth | Passport.js + JWT + CASL | Per-tenant ABAC permissions |
| Background Jobs | BullMQ + Redis | Async tasks: email, webhooks, schema introspection jobs |
| Real-time | Socket.io | Push data updates to clients (Firebase-style) |
| Storage | MinIO / AWS S3 | S3-compatible, self-hostable file storage |
| Cache | Redis | Metadata and query result caching |
| Sandbox | isolated-vm | Safe execution of user-defined hook functions |
| Containers | Docker + Kubernetes | Multi-tenant isolation at the infrastructure level |
| Monitoring | Prometheus + Grafana + Sentry | Infra metrics and error tracking |
| API Docs | Swagger (auto-generated by NestJS) | |

---

## What Makes This Different From a Normal Backend

| Normal backend | This BaaS |
|----------------|-----------|
| Schema defined at build time | Schema discovered or defined at runtime |
| One controller per resource | One controller for all resources |
| Tied to one DB engine | Engine-agnostic via Adapter pattern |
| Frontend knows the API shape | Frontend discovers the API shape at load time |
| New entity = new code deploy | New entity = metadata entry, zero redeploy |

The goal is simple: **a developer should be able to point our platform at their existing database and have a fully functional REST API — with validation, auth, real-time, and file storage — within minutes, without writing a single line of backend code.**
