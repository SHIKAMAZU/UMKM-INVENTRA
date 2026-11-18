import { query, withTransaction } from '../db/pool.js';
import { AppError } from '../utils/AppError.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { sendSuccess } from '../utils/response.js';

export const createStockMovement = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const { type, quantity, note } = req.validated.body;

  const result = await withTransaction(async (client) => {
    const { rows } = await client.query(
      'SELECT id, name, stock FROM products WHERE id = $1 FOR UPDATE',
      [id]
    );
    const product = rows[0];

    if (!product) {
      throw new AppError(404, 'Produk tidak ditemukan');
    }

    let newStock;
    if (type === 'in') {
      newStock = product.stock + quantity;
    } else if (type === 'out') {
      newStock = product.stock - quantity;
    } else {
      newStock = quantity;
    }

    if (newStock < 0) {
      throw new AppError(
        400,
        `Stok tidak mencukupi. Stok saat ini ${product.stock}, diminta keluar ${quantity}`
      );
    }

    const updated = await client.query(
      'UPDATE products SET stock = $1 WHERE id = $2 RETURNING id, sku, name, stock',
      [newStock, id]
    );

    const movement = await client.query(
      `INSERT INTO stock_movements (product_id, user_id, type, quantity, note)
       VALUES ($1, $2, $3, $4, $5)
       RETURNING *`,
      [id, req.user.id, type, quantity, note ?? null]
    );

    return { product: updated.rows[0], movement: movement.rows[0] };
  });

  sendSuccess(res, {
    status: 201,
    message: 'Stok berhasil diperbarui',
    data: result,
  });
});

export const listStockMovements = asyncHandler(async (req, res) => {
  const { page, limit, product_id, type } = req.validated.query;

  const conditions = [];
  const values = [];

  if (product_id) {
    values.push(product_id);
    conditions.push(`sm.product_id = $${values.length}`);
  }
  if (type) {
    values.push(type);
    conditions.push(`sm.type = $${values.length}`);
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const countResult = await query(`SELECT COUNT(*)::int AS total FROM stock_movements sm ${where}`, values);
  const total = countResult.rows[0].total;

  values.push(limit, (page - 1) * limit);
  const { rows } = await query(
    `SELECT sm.id, sm.product_id, p.sku, p.name AS product_name,
            sm.user_id, u.name AS user_name, sm.type, sm.quantity, sm.note, sm.created_at
     FROM stock_movements sm
     JOIN products p ON p.id = sm.product_id
     JOIN users u ON u.id = sm.user_id
     ${where}
     ORDER BY sm.created_at DESC, sm.id DESC
     LIMIT $${values.length - 1} OFFSET $${values.length}`,
    values
  );

  sendSuccess(res, {
    data: rows,
    meta: { page, limit, total, total_pages: Math.ceil(total / limit) },
  });
});
