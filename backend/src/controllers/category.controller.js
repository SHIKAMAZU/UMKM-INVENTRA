import { query } from '../db/pool.js';
import { AppError } from '../utils/AppError.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { sendSuccess } from '../utils/response.js';

const SELECT_CATEGORY = `
  SELECT c.id, c.name, c.description, c.created_at, c.updated_at,
         COUNT(p.id)::int AS product_count
  FROM categories c
  LEFT JOIN products p ON p.category_id = c.id
`;

export const listCategories = asyncHandler(async (req, res) => {
  const { rows } = await query(`${SELECT_CATEGORY} GROUP BY c.id ORDER BY c.name ASC`);
  sendSuccess(res, { data: rows });
});

export const getCategory = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const { rows } = await query(`${SELECT_CATEGORY} WHERE c.id = $1 GROUP BY c.id`, [id]);

  if (!rows[0]) {
    throw new AppError(404, 'Kategori tidak ditemukan');
  }

  sendSuccess(res, { data: rows[0] });
});

export const createCategory = asyncHandler(async (req, res) => {
  const { name, description } = req.validated.body;

  try {
    const { rows } = await query(
      'INSERT INTO categories (name, description) VALUES ($1, $2) RETURNING *',
      [name, description ?? null]
    );
    sendSuccess(res, { status: 201, message: 'Kategori berhasil dibuat', data: rows[0] });
  } catch (err) {
    if (err.code === '23505') {
      throw new AppError(409, 'Nama kategori sudah ada');
    }
    throw err;
  }
});

export const updateCategory = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const { name, description } = req.validated.body;

  const fields = [];
  const values = [];

  if (name !== undefined) {
    values.push(name);
    fields.push(`name = $${values.length}`);
  }
  if (description !== undefined) {
    values.push(description);
    fields.push(`description = $${values.length}`);
  }

  values.push(id);
  const { rows } = await query(
    `UPDATE categories SET ${fields.join(', ')} WHERE id = $${values.length} RETURNING *`,
    values
  );

  if (!rows[0]) {
    throw new AppError(404, 'Kategori tidak ditemukan');
  }

  sendSuccess(res, { message: 'Kategori berhasil diperbarui', data: rows[0] });
});

export const deleteCategory = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const { rows } = await query('DELETE FROM categories WHERE id = $1 RETURNING id', [id]);

  if (!rows[0]) {
    throw new AppError(404, 'Kategori tidak ditemukan');
  }

  sendSuccess(res, { message: 'Kategori berhasil dihapus', data: { id: rows[0].id } });
});
