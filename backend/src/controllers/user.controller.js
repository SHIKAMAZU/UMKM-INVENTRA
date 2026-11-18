import { query } from '../db/pool.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { sendSuccess } from '../utils/response.js';

export const listUsers = asyncHandler(async (req, res) => {
  const { page, limit, role, search } = req.validated.query;

  const conditions = [];
  const values = [];

  if (role) {
    values.push(role);
    conditions.push(`role = $${values.length}`);
  }
  if (search) {
    values.push(`%${search}%`);
    conditions.push(`(name ILIKE $${values.length} OR email ILIKE $${values.length})`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const countResult = await query(`SELECT COUNT(*)::int AS total FROM users ${where}`, values);
  const total = countResult.rows[0].total;

  values.push(limit, (page - 1) * limit);
  const { rows } = await query(
    `SELECT id, name, email, role, is_active, created_at, updated_at
     FROM users ${where}
     ORDER BY created_at DESC, id DESC
     LIMIT $${values.length - 1} OFFSET $${values.length}`,
    values
  );

  sendSuccess(res, {
    data: rows,
    meta: { page, limit, total, total_pages: Math.ceil(total / limit) },
  });
});
