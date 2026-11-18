import { query, withTransaction } from '../db/pool.js';
import { AppError } from '../utils/AppError.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { sendSuccess } from '../utils/response.js';

export const createSale = asyncHandler(async (req, res) => {
  const { items } = req.validated.body;
  const ordered = [...items].sort((a, b) => a.product_id - b.product_id);

  const sale = await withTransaction(async (client) => {
    let total = 0;
    const prepared = [];

    for (const item of ordered) {
      const { rows } = await client.query(
        'SELECT id, name, price, stock FROM products WHERE id = $1 FOR UPDATE',
        [item.product_id]
      );
      const product = rows[0];

      if (!product) {
        throw new AppError(404, `Produk ${item.product_id} tidak ditemukan`);
      }
      if (product.stock < item.quantity) {
        throw new AppError(
          400,
          `Stok ${product.name} tidak cukup. Tersisa ${product.stock}`
        );
      }

      const subtotal = Number(product.price) * item.quantity;
      total += subtotal;
      prepared.push({ ...product, quantity: item.quantity, subtotal });
    }

    const saleResult = await client.query(
      `INSERT INTO sales (user_id, total) VALUES ($1, $2)
       RETURNING id, user_id, total, created_at`,
      [req.user.id, total]
    );
    const newSale = saleResult.rows[0];

    for (const item of prepared) {
      await client.query(
        `INSERT INTO sale_items
           (sale_id, product_id, product_name, price, quantity, subtotal)
         VALUES ($1, $2, $3, $4, $5, $6)`,
        [
          newSale.id,
          item.id,
          item.name,
          item.price,
          item.quantity,
          item.subtotal,
        ]
      );

      await client.query(
        'UPDATE products SET stock = stock - $1 WHERE id = $2',
        [item.quantity, item.id]
      );

      await client.query(
        `INSERT INTO stock_movements (product_id, user_id, type, quantity, note)
         VALUES ($1, $2, 'out', $3, $4)`,
        [item.id, req.user.id, item.quantity, `Penjualan #${newSale.id}`]
      );
    }

    const saleItems = await client.query(
      `SELECT id, product_id, product_name, price, quantity, subtotal
       FROM sale_items WHERE sale_id = $1 ORDER BY id`,
      [newSale.id]
    );

    return { ...newSale, items: saleItems.rows };
  });

  sendSuccess(res, {
    status: 201,
    message: 'Transaksi penjualan berhasil',
    data: sale,
  });
});

export const deleteSale = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;

  await withTransaction(async (client) => {
    const saleResult = await client.query(
      'SELECT id FROM sales WHERE id = $1 FOR UPDATE',
      [id]
    );

    if (!saleResult.rows[0]) {
      throw new AppError(404, 'Riwayat penjualan tidak ditemukan');
    }

    const items = await client.query(
      'SELECT product_id, quantity FROM sale_items WHERE sale_id = $1',
      [id]
    );

    for (const item of items.rows) {
      await client.query(
        'UPDATE products SET stock = stock + $1 WHERE id = $2',
        [item.quantity, item.product_id]
      );

      await client.query(
        `INSERT INTO stock_movements (product_id, user_id, type, quantity, note)
         VALUES ($1, $2, 'in', $3, $4)`,
        [
          item.product_id,
          req.user.id,
          item.quantity,
          `Pembatalan penjualan #${id}`,
        ]
      );
    }

    await client.query('DELETE FROM sales WHERE id = $1', [id]);
  });

  sendSuccess(res, {
    message: 'Riwayat penjualan dihapus dan stok dikembalikan',
    data: { id },
  });
});

export const listSales = asyncHandler(async (req, res) => {
  const { page, limit } = req.validated.query;

  const countResult = await query('SELECT COUNT(*)::int AS total FROM sales');
  const total = countResult.rows[0].total;

  const { rows } = await query(
    `SELECT s.id, s.user_id, u.name AS user_name, s.total, s.created_at,
            COUNT(si.id)::int AS item_count,
            COALESCE(SUM(si.quantity), 0)::int AS total_quantity
     FROM sales s
     JOIN users u ON u.id = s.user_id
     LEFT JOIN sale_items si ON si.sale_id = s.id
     GROUP BY s.id, u.name
     ORDER BY s.created_at DESC, s.id DESC
     LIMIT $1 OFFSET $2`,
    [limit, (page - 1) * limit]
  );

  sendSuccess(res, {
    data: rows,
    meta: { page, limit, total, total_pages: Math.ceil(total / limit) },
  });
});
