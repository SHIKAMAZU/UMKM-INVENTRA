import { query } from '../db/pool.js';
import { AppError } from '../utils/AppError.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { sendSuccess } from '../utils/response.js';

const SELECT_SUPPLIER = `
  SELECT id, name, phone, email, address, created_at, updated_at
  FROM suppliers
`;

export const listSuppliers = asyncHandler(async (req, res) => {
  const { rows } = await query(`${SELECT_SUPPLIER} ORDER BY name ASC`);
  sendSuccess(res, { data: rows });
});

export const getSupplier = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const { rows } = await query(`${SELECT_SUPPLIER} WHERE id = $1`, [id]);

  if (!rows[0]) {
    throw new AppError(404, 'Supplier tidak ditemukan');
  }

  sendSuccess(res, { data: rows[0] });
});

export const createSupplier = asyncHandler(async (req, res) => {
  const { name, phone, email, address } = req.validated.body;

  try {
    const { rows } = await query(
      `INSERT INTO suppliers (name, phone, email, address)
       VALUES ($1, $2, $3, $4)
       RETURNING *`,
      [name, phone ?? null, email ?? null, address ?? null]
    );
    sendSuccess(res, {
      status: 201,
      message: 'Supplier berhasil dibuat',
      data: rows[0],
    });
  } catch (err) {
    if (err.code === '23505') {
      throw new AppError(409, 'Nama supplier sudah ada');
    }
    throw err;
  }
});

export const updateSupplier = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const body = req.validated.body;

  const fields = [];
  const values = [];

  for (const key of ['name', 'phone', 'email', 'address']) {
    if (body[key] !== undefined) {
      values.push(body[key]);
      fields.push(`${key} = $${values.length}`);
    }
  }

  values.push(id);

  try {
    const { rows } = await query(
      `UPDATE suppliers SET ${fields.join(', ')} WHERE id = $${values.length} RETURNING *`,
      values
    );

    if (!rows[0]) {
      throw new AppError(404, 'Supplier tidak ditemukan');
    }

    sendSuccess(res, {
      message: 'Supplier berhasil diperbarui',
      data: rows[0],
    });
  } catch (err) {
    if (err.code === '23505') {
      throw new AppError(409, 'Nama supplier sudah ada');
    }
    throw err;
  }
});

export const deleteSupplier = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const { rows } = await query(
    'DELETE FROM suppliers WHERE id = $1 RETURNING id',
    [id]
  );

  if (!rows[0]) {
    throw new AppError(404, 'Supplier tidak ditemukan');
  }

  sendSuccess(res, {
    message: 'Supplier berhasil dihapus',
    data: { id: rows[0].id },
  });
});
