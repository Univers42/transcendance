/**
 * MongoDB CRUD route handlers.
 *
 * Generic handlers that operate on any MongoDB collection by name.
 * Supports pagination, sorting, search, and full CRUD.
 */
import { type Request, type Response } from 'express';
import { ObjectId, type Filter, type Document } from 'mongodb';
import { getDb } from '../db/mongo.js';

/** Safely extract a route param as string. */
function param(req: Request, name: string): string {
  const val = req.params[name];
  return Array.isArray(val) ? val[0] ?? '' : val ?? '';
}

/**
 * Parse pagination/sort/search params from query string.
 */
function parseParams(query: Record<string, unknown>): {
  page: number;
  perPage: number;
  sortBy: string;
  sortOrder: 1 | -1;
  search: string | null;
  filter: Record<string, unknown>;
} {
  const params = {
    page: Math.max(1, parseInt(String(query.page ?? '1'), 10)),
    perPage: Math.min(100, Math.max(1, parseInt(String(query.perPage ?? '20'), 10))),
    sortBy: String(query.sortBy ?? 'created_at'),
    sortOrder: (String(query.sortOrder ?? 'desc').toLowerCase() === 'asc' ? 1 : -1) as 1 | -1,
    search: query.search ? String(query.search) : null,
    filter: {} as Record<string, unknown>,
  };

  // Extract filter params (anything not a pagination param)
  const reserved = new Set(['page', 'perPage', 'sortBy', 'sortOrder', 'search']);
  for (const [key, val] of Object.entries(query)) {
    if (!reserved.has(key) && val !== undefined) {
      params.filter[key] = val;
    }
  }

  return params;
}

/**
 * Convert string ID to ObjectId if it looks like one; otherwise return as-is.
 */
function parseId(id: string): ObjectId | string {
  try {
    if (/^[0-9a-f]{24}$/i.test(id)) {
      return new ObjectId(id);
    }
  } catch {
    // Not a valid ObjectId
  }
  return id;
}

/**
 * GET /api/nosql/:resource — Paginated list
 */
export async function listNosqlResource(req: Request, res: Response): Promise<void> {
  try {
    const collection = getDb().collection(param(req, 'resource'));
    const { page, perPage, sortBy, sortOrder, search, filter } = parseParams(
      req.query as Record<string, unknown>,
    );

    const mongoFilter: Filter<Document> = { ...filter };

    // Text search across common string fields
    if (search) {
      mongoFilter.$or = [
        { name: { $regex: search, $options: 'i' } },
        { title: { $regex: search, $options: 'i' } },
        { description: { $regex: search, $options: 'i' } },
        { slug: { $regex: search, $options: 'i' } },
      ];
    }

    const skip = (page - 1) * perPage;

    const [total, data] = await Promise.all([
      collection.countDocuments(mongoFilter),
      collection
        .find(mongoFilter)
        .sort({ [sortBy]: sortOrder })
        .skip(skip)
        .limit(perPage)
        .toArray(),
    ]);

    res.json({
      data,
      meta: {
        total,
        page,
        perPage,
        totalPages: Math.ceil(total / perPage),
      },
    });
  } catch (err) {
    console.error('[data-api] listNosqlResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}

/**
 * GET /api/nosql/:resource/:id — Single document
 */
export async function getNosqlResource(req: Request, res: Response): Promise<void> {
  try {
    const collection = getDb().collection(param(req, 'resource'));
    const id = parseId(param(req, 'id'));

    const doc = await collection.findOne({ _id: id as never });

    if (!doc) {
      res.status(404).json({ error: 'Not found' });
      return;
    }

    res.json(doc);
  } catch (err) {
    console.error('[data-api] getNosqlResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}

/**
 * POST /api/nosql/:resource — Create document
 */
export async function createNosqlResource(req: Request, res: Response): Promise<void> {
  try {
    const collection = getDb().collection(param(req, 'resource'));
    const data = req.body as Record<string, unknown>;

    if (!data || Object.keys(data).length === 0) {
      res.status(400).json({ error: 'Request body is required' });
      return;
    }

    const now = new Date().toISOString();
    const doc = {
      ...data,
      created_at: data.created_at ?? now,
      updated_at: data.updated_at ?? now,
    };

    const result = await collection.insertOne(doc);
    res.status(201).json({ ...doc, _id: result.insertedId });
  } catch (err) {
    console.error('[data-api] createNosqlResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}

/**
 * PUT /api/nosql/:resource/:id — Update document
 */
export async function updateNosqlResource(req: Request, res: Response): Promise<void> {
  try {
    const collection = getDb().collection(param(req, 'resource'));
    const id = parseId(param(req, 'id'));
    const data = req.body as Record<string, unknown>;

    if (!data || Object.keys(data).length === 0) {
      res.status(400).json({ error: 'Request body is required' });
      return;
    }

    const result = await collection.findOneAndUpdate(
      { _id: id as never },
      {
        $set: {
          ...data,
          updated_at: new Date().toISOString(),
        },
      },
      { returnDocument: 'after' },
    );

    if (!result) {
      res.status(404).json({ error: 'Not found' });
      return;
    }

    res.json(result);
  } catch (err) {
    console.error('[data-api] updateNosqlResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}

/**
 * DELETE /api/nosql/:resource/:id — Delete document
 */
export async function deleteNosqlResource(req: Request, res: Response): Promise<void> {
  try {
    const collection = getDb().collection(param(req, 'resource'));
    const id = parseId(param(req, 'id'));

    const result = await collection.deleteOne({ _id: id as never });

    if (result.deletedCount === 0) {
      res.status(404).json({ error: 'Not found' });
      return;
    }

    res.status(204).send();
  } catch (err) {
    console.error('[data-api] deleteNosqlResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}

/**
 * GET /api/nosql/:resource/count — Count documents
 */
export async function countNosqlResource(req: Request, res: Response): Promise<void> {
  try {
    const collection = getDb().collection(param(req, 'resource'));
    const count = await collection.countDocuments();
    res.json({ count });
  } catch (err) {
    console.error('[data-api] countNosqlResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}
