/**
 * PostgreSQL CRUD route handlers.
 *
 * Generic handlers that operate on any SQL table by name.
 * Supports pagination, sorting, search, and full CRUD.
 */
import { type Request, type Response } from 'express';
import { pool } from '../db/postgres.js';

/** Safely extract a route param as string. */
function param(req: Request, name: string): string {
  const val = req.params[name];
  return Array.isArray(val) ? val[0] ?? '' : val ?? '';
}

/** Standard paginated response shape. */
interface PaginatedMeta {
  total: number;
  page: number;
  perPage: number;
  totalPages: number;
}

/**
 * Parse pagination/sort/search params from query string.
 */
function parseParams(query: Record<string, unknown>): {
  page: number;
  perPage: number;
  sortBy: string;
  sortOrder: 'ASC' | 'DESC';
  search: string | null;
} {
  return {
    page: Math.max(1, parseInt(String(query.page ?? '1'), 10)),
    perPage: Math.min(100, Math.max(1, parseInt(String(query.perPage ?? '20'), 10))),
    sortBy: String(query.sortBy ?? 'created_at'),
    sortOrder: String(query.sortOrder ?? 'desc').toUpperCase() === 'ASC' ? 'ASC' : 'DESC',
    search: query.search ? String(query.search) : null,
  };
}

/**
 * Sanitize table/column names — only allow alphanumeric + underscores.
 */
function safeName(name: string): string {
  if (!/^[a-z_][a-z0-9_]*$/i.test(name)) {
    throw new Error(`Invalid identifier: ${name}`);
  }
  return name;
}

/**
 * GET /api/:resource — Paginated list
 */
export async function listResource(req: Request, res: Response): Promise<void> {
  try {
    const table = safeName(param(req, 'resource'));
    const { page, perPage, sortBy, sortOrder, search } = parseParams(
      req.query as Record<string, unknown>,
    );

    // Check if sort column exists (fallback to created_at, then id)
    let orderCol = 'id';
    try {
      const colCheck = await pool.query(
        `SELECT column_name FROM information_schema.columns WHERE table_name = $1 AND column_name = $2`,
        [table, sortBy],
      );
      if (colCheck.rows.length > 0) {
        orderCol = sortBy;
      } else {
        // Try created_at
        const createdCheck = await pool.query(
          `SELECT column_name FROM information_schema.columns WHERE table_name = $1 AND column_name = 'created_at'`,
          [table],
        );
        if (createdCheck.rows.length > 0) orderCol = 'created_at';
      }
    } catch {
      // Fallback to id
    }

    const offset = (page - 1) * perPage;

    // Build WHERE clause for search (searches all text columns)
    let whereClause = '';
    const params: unknown[] = [];

    if (search) {
      // Get text columns for this table
      const textCols = await pool.query(
        `SELECT column_name FROM information_schema.columns 
         WHERE table_name = $1 AND data_type IN ('text', 'character varying')
         LIMIT 5`,
        [table],
      );

      if (textCols.rows.length > 0) {
        const conditions = textCols.rows.map(
          (r: { column_name: string }, i: number) =>
            `"${safeName(r.column_name)}" ILIKE $${i + 1}`,
        );
        whereClause = `WHERE (${conditions.join(' OR ')})`;
        params.push(...textCols.rows.map(() => `%${search}%`));
      }
    }

    // Count
    const countResult = await pool.query(
      `SELECT count(*) AS total FROM "${safeName(table)}" ${whereClause}`,
      params,
    );
    const total = parseInt(countResult.rows[0]?.total, 10);

    // Data
    const dataResult = await pool.query(
      `SELECT * FROM "${safeName(table)}" ${whereClause} 
       ORDER BY "${safeName(orderCol)}" ${sortOrder} 
       LIMIT $${params.length + 1} OFFSET $${params.length + 2}`,
      [...params, perPage, offset],
    );

    const meta: PaginatedMeta = {
      total,
      page,
      perPage,
      totalPages: Math.ceil(total / perPage),
    };

    res.json({ data: dataResult.rows, meta });
  } catch (err) {
    console.error('[data-api] listResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}

/**
 * GET /api/:resource/:id — Single item
 */
export async function getResource(req: Request, res: Response): Promise<void> {
  try {
    const table = safeName(param(req, 'resource'));
    const id = param(req, 'id');

    const result = await pool.query(`SELECT * FROM "${table}" WHERE id = $1`, [id]);

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('[data-api] getResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}

/**
 * POST /api/:resource — Create
 */
export async function createResource(req: Request, res: Response): Promise<void> {
  try {
    const table = safeName(param(req, 'resource'));
    const data = req.body as Record<string, unknown>;

    if (!data || Object.keys(data).length === 0) {
      res.status(400).json({ error: 'Request body is required' });
      return;
    }

    const columns = Object.keys(data).map(safeName);
    const values = Object.values(data);
    const placeholders = values.map((_, i) => `$${i + 1}`);

    const result = await pool.query(
      `INSERT INTO "${table}" (${columns.map((c) => `"${c}"`).join(', ')})
       VALUES (${placeholders.join(', ')})
       RETURNING *`,
      values,
    );

    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error('[data-api] createResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}

/**
 * PUT /api/:resource/:id — Update
 */
export async function updateResource(req: Request, res: Response): Promise<void> {
  try {
    const table = safeName(param(req, 'resource'));
    const id = param(req, 'id');
    const data = req.body as Record<string, unknown>;

    if (!data || Object.keys(data).length === 0) {
      res.status(400).json({ error: 'Request body is required' });
      return;
    }

    const entries = Object.entries(data);
    const setClauses = entries.map(([key], i) => `"${safeName(key)}" = $${i + 1}`);
    const values = entries.map(([, val]) => val);

    const result = await pool.query(
      `UPDATE "${table}" SET ${setClauses.join(', ')} WHERE id = $${values.length + 1} RETURNING *`,
      [...values, id],
    );

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Not found' });
      return;
    }

    res.json(result.rows[0]);
  } catch (err) {
    console.error('[data-api] updateResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}

/**
 * DELETE /api/:resource/:id — Delete
 */
export async function deleteResource(req: Request, res: Response): Promise<void> {
  try {
    const table = safeName(param(req, 'resource'));
    const id = param(req, 'id');

    const result = await pool.query(`DELETE FROM "${table}" WHERE id = $1 RETURNING id`, [id]);

    if (result.rows.length === 0) {
      res.status(404).json({ error: 'Not found' });
      return;
    }

    res.status(204).send();
  } catch (err) {
    console.error('[data-api] deleteResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}

/**
 * GET /api/:resource/count — Count
 */
export async function countResource(req: Request, res: Response): Promise<void> {
  try {
    const table = safeName(param(req, 'resource'));
    const result = await pool.query(`SELECT count(*) AS total FROM "${table}"`);
    res.json({ count: parseInt(result.rows[0]?.total, 10) });
  } catch (err) {
    console.error('[data-api] countResource error:', err);
    res.status(500).json({ error: 'Internal server error', details: String(err) });
  }
}
