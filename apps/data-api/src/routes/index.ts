/**
 * API Router — mounts SQL and NoSQL CRUD handlers.
 *
 * Routes:
 *   /api/:resource          — SQL (PostgreSQL) tables
 *   /api/nosql/:resource    — NoSQL (MongoDB) collections
 *
 * Both support: GET (list), GET /:id, POST, PUT /:id, DELETE /:id, GET /count
 */
import { Router, type Request, type Response, type NextFunction } from 'express';
import { SQL_RESOURCES, NOSQL_RESOURCES } from './resources.js';

/** Safely extract a route param as string. */
function param(req: Request, name: string): string {
  const val = req.params[name];
  return Array.isArray(val) ? val[0] ?? '' : val ?? '';
}

import {
  listResource,
  getResource,
  createResource,
  updateResource,
  deleteResource,
  countResource,
} from './sql-handlers.js';
import {
  listNosqlResource,
  getNosqlResource,
  createNosqlResource,
  updateNosqlResource,
  deleteNosqlResource,
  countNosqlResource,
} from './nosql-handlers.js';

export const apiRouter: Router = Router();

// ── Resource validation middleware ──────────────────────

function validateSqlResource(req: Request, res: Response, next: NextFunction): void {
  const resource = param(req, 'resource');
  if (!SQL_RESOURCES.has(resource)) {
    res.status(404).json({
      error: 'Unknown SQL resource',
      resource,
      hint: 'Use GET /api to list available resources',
    });
    return;
  }
  next();
}

function validateNosqlResource(req: Request, res: Response, next: NextFunction): void {
  const resource = param(req, 'resource');
  if (!NOSQL_RESOURCES.has(resource)) {
    res.status(404).json({
      error: 'Unknown NoSQL resource',
      resource,
      hint: 'Use GET /api to list available resources',
    });
    return;
  }
  next();
}

// ── Discovery endpoint ──────────────────────────────────

apiRouter.get('/', (_req: Request, res: Response) => {
  res.json({
    service: 'Prismatica data-api',
    version: '0.1.0',
    sql_resources: [...SQL_RESOURCES].sort(),
    nosql_resources: [...NOSQL_RESOURCES].sort(),
    routes: {
      sql: {
        list: 'GET /api/:resource?page=1&perPage=20&sortBy=created_at&sortOrder=desc&search=foo',
        get: 'GET /api/:resource/:id',
        create: 'POST /api/:resource',
        update: 'PUT /api/:resource/:id',
        delete: 'DELETE /api/:resource/:id',
        count: 'GET /api/:resource/count',
      },
      nosql: {
        list: 'GET /api/nosql/:resource?page=1&perPage=20&sortBy=created_at&sortOrder=desc&search=foo',
        get: 'GET /api/nosql/:resource/:id',
        create: 'POST /api/nosql/:resource',
        update: 'PUT /api/nosql/:resource/:id',
        delete: 'DELETE /api/nosql/:resource/:id',
        count: 'GET /api/nosql/:resource/count',
      },
    },
  });
});

// ── NoSQL routes (must come before SQL to avoid /nosql/:resource clash) ─

apiRouter.get('/nosql/:resource/count', validateNosqlResource, countNosqlResource);
apiRouter.get('/nosql/:resource/:id', validateNosqlResource, getNosqlResource);
apiRouter.get('/nosql/:resource', validateNosqlResource, listNosqlResource);
apiRouter.post('/nosql/:resource', validateNosqlResource, createNosqlResource);
apiRouter.put('/nosql/:resource/:id', validateNosqlResource, updateNosqlResource);
apiRouter.delete('/nosql/:resource/:id', validateNosqlResource, deleteNosqlResource);

// ── SQL routes ──────────────────────────────────────────

apiRouter.get('/:resource/count', validateSqlResource, countResource);
apiRouter.get('/:resource/:id', validateSqlResource, getResource);
apiRouter.get('/:resource', validateSqlResource, listResource);
apiRouter.post('/:resource', validateSqlResource, createResource);
apiRouter.put('/:resource/:id', validateSqlResource, updateResource);
apiRouter.delete('/:resource/:id', validateSqlResource, deleteResource);
