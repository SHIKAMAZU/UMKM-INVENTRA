import { z } from 'zod';
import { paginationQuerySchema } from './common.validator.js';

const categoryId = z.coerce
  .number()
  .int('Kategori tidak valid')
  .positive('Kategori wajib dipilih');

const sku = z
  .string()
  .trim()
  .toUpperCase()
  .min(2, 'SKU minimal 2 karakter')
  .max(50, 'SKU maksimal 50 karakter');

const name = z
  .string()
  .trim()
  .min(2, 'Nama produk minimal 2 karakter')
  .max(150, 'Nama produk maksimal 150 karakter');

const description = z.string().trim().max(1000, 'Deskripsi maksimal 1000 karakter');

const price = z.coerce
  .number()
  .min(0, 'Harga tidak boleh negatif')
  .max(9999999999, 'Harga terlalu besar');

const stock = z.coerce.number().int('Stok harus bilangan bulat').min(0, 'Stok tidak boleh negatif');

const minStock = z.coerce
  .number()
  .int('Stok minimal harus bilangan bulat')
  .min(0, 'Stok minimal tidak boleh negatif');

const imageUrl = z
  .string()
  .trim()
  .url('URL gambar harus berupa URL yang valid')
  .max(500, 'URL gambar maksimal 500 karakter')
  .nullable()
  .optional();

export const createProductBodySchema = z.object({
  category_id: categoryId,
  sku,
  name,
  description: description.optional().nullable(),
  price,
  stock: stock.default(0),
  min_stock: minStock.default(5),
  image_url: imageUrl,
});

export const updateProductBodySchema = z
  .object({
    category_id: categoryId.optional(),
    sku: sku.optional(),
    name: name.optional(),
    description: description.optional().nullable(),
    price: price.optional(),
    min_stock: minStock.optional(),
    image_url: imageUrl,
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'Minimal satu field harus diisi',
  });

export const productQuerySchema = paginationQuerySchema.extend({
  search: z.string().trim().max(100).optional(),
  category_id: z.coerce.number().int().positive().optional(),
  low_stock: z.enum(['true', 'false']).optional(),
});
