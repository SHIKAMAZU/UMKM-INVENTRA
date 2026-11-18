import fs from 'node:fs/promises';
import path from 'node:path';
import {
  cloudinary,
  cloudinaryEnabled,
  publicIdFromUrl,
  uploadImageBuffer,
} from '../config/cloudinary.js';
import { query, withTransaction } from '../db/pool.js';
import { uploadRootDir } from '../middlewares/upload.js';
import { AppError } from '../utils/AppError.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { sendSuccess } from '../utils/response.js';

const SELECT_PRODUCT = `
  SELECT p.id, p.category_id, c.name AS category_name, p.sku, p.name,
         p.description, p.price, p.stock, p.min_stock, p.image_url,
         p.created_at, p.updated_at
  FROM products p
  JOIN categories c ON c.id = p.category_id
`;

async function findProductById(id) {
  const { rows } = await query(`${SELECT_PRODUCT} WHERE p.id = $1`, [id]);
  return rows[0] ?? null;
}

async function removeUploadedFile(filename) {
  try {
    await fs.unlink(path.join(uploadRootDir, path.basename(filename)));
  } catch {
    // file lama mungkin sudah tidak ada, abaikan
  }
}

async function removeProductImage(imageUrl) {
  if (!imageUrl) return;

  if (imageUrl.includes('res.cloudinary.com')) {
    const publicId = publicIdFromUrl(imageUrl);
    if (!publicId) return;
    try {
      await cloudinary.uploader.destroy(publicId);
    } catch {
      // abaikan kegagalan hapus di Cloudinary
    }
    return;
  }

  if (imageUrl.startsWith('/uploads/')) {
    await removeUploadedFile(imageUrl);
  }
}

async function assertCategoryExists(categoryId) {
  const { rowCount } = await query('SELECT 1 FROM categories WHERE id = $1', [categoryId]);
  if (rowCount === 0) {
    throw new AppError(422, 'Kategori tidak ditemukan', { category_id: 'Kategori tidak ditemukan' });
  }
}

export const listProducts = asyncHandler(async (req, res) => {
  const { page, limit, search, category_id, low_stock } = req.validated.query;

  const conditions = [];
  const values = [];

  if (search) {
    values.push(`%${search}%`);
    conditions.push(`(p.name ILIKE $${values.length} OR p.sku ILIKE $${values.length})`);
  }
  if (category_id) {
    values.push(category_id);
    conditions.push(`p.category_id = $${values.length}`);
  }
  if (low_stock === 'true') {
    conditions.push('p.stock <= p.min_stock');
  }

  const where = conditions.length ? `WHERE ${conditions.join(' AND ')}` : '';

  const countResult = await query(`SELECT COUNT(*)::int AS total FROM products p ${where}`, values);
  const total = countResult.rows[0].total;

  values.push(limit, (page - 1) * limit);
  const { rows } = await query(
    `${SELECT_PRODUCT} ${where}
     ORDER BY p.created_at DESC, p.id DESC
     LIMIT $${values.length - 1} OFFSET $${values.length}`,
    values
  );

  sendSuccess(res, {
    data: rows,
    meta: { page, limit, total, total_pages: Math.ceil(total / limit) },
  });
});

export const getProduct = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const product = await findProductById(id);

  if (!product) {
    throw new AppError(404, 'Produk tidak ditemukan');
  }

  sendSuccess(res, { data: product });
});

export const createProduct = asyncHandler(async (req, res) => {
  const { category_id, sku, name, description, price, stock, min_stock, image_url } =
    req.validated.body;
  await assertCategoryExists(category_id);

  try {
    const productId = await withTransaction(async (client) => {
      const { rows } = await client.query(
        `INSERT INTO products (category_id, sku, name, description, price, stock, min_stock, image_url)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8)
         RETURNING id`,
        [category_id, sku, name, description ?? null, price, stock, min_stock, image_url ?? null]
      );

      const newId = rows[0].id;

      if (stock > 0) {
        await client.query(
          `INSERT INTO stock_movements (product_id, user_id, type, quantity, note)
           VALUES ($1, $2, 'in', $3, $4)`,
          [newId, req.user.id, stock, 'Stok awal saat produk dibuat']
        );
      }

      return newId;
    });

    const product = await findProductById(productId);
    sendSuccess(res, { status: 201, message: 'Produk berhasil dibuat', data: product });
  } catch (err) {
    if (err.code === '23505') {
      throw new AppError(409, 'SKU sudah digunakan', { sku: 'SKU sudah digunakan' });
    }
    throw err;
  }
});

export const updateProduct = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const body = req.validated.body;

  const existing = await findProductById(id);
  if (!existing) {
    throw new AppError(404, 'Produk tidak ditemukan');
  }

  if (body.category_id !== undefined) {
    await assertCategoryExists(body.category_id);
  }

  const fields = [];
  const values = [];

  for (const key of ['category_id', 'sku', 'name', 'description', 'price', 'min_stock', 'image_url']) {
    if (body[key] !== undefined) {
      values.push(body[key]);
      fields.push(`${key} = $${values.length}`);
    }
  }

  values.push(id);

  try {
    await query(
      `UPDATE products SET ${fields.join(', ')} WHERE id = $${values.length}`,
      values
    );
  } catch (err) {
    if (err.code === '23505') {
      throw new AppError(409, 'SKU sudah digunakan', { sku: 'SKU sudah digunakan' });
    }
    throw err;
  }

  const product = await findProductById(id);
  sendSuccess(res, { message: 'Produk berhasil diperbarui', data: product });
});

export const deleteProduct = asyncHandler(async (req, res) => {
  const { id } = req.validated.params;
  const { rows } = await query('DELETE FROM products WHERE id = $1 RETURNING id, image_url', [id]);

  if (!rows[0]) {
    throw new AppError(404, 'Produk tidak ditemukan');
  }

  if (rows[0].image_url) {
    await removeProductImage(rows[0].image_url);
  }

  sendSuccess(res, { message: 'Produk berhasil dihapus', data: { id: rows[0].id } });
});

export const uploadProductImage = asyncHandler(async (req, res) => {
  if (!req.file) {
    throw new AppError(400, 'File gambar wajib dikirim dengan field "image"');
  }

  const { id } = req.validated.params;
  const existing = await findProductById(id);

  if (!existing) {
    if (req.file.filename) {
      await removeUploadedFile(req.file.filename);
    }
    throw new AppError(404, 'Produk tidak ditemukan');
  }

  let imageUrl;
  if (cloudinaryEnabled) {
    const result = await uploadImageBuffer(req.file.buffer);
    imageUrl = result.secure_url;
  } else {
    imageUrl = `/uploads/${req.file.filename}`;
  }

  await query('UPDATE products SET image_url = $1 WHERE id = $2', [imageUrl, id]);
  await removeProductImage(existing.image_url);

  const product = await findProductById(id);
  sendSuccess(res, { message: 'Gambar produk berhasil diunggah', data: product });
});
