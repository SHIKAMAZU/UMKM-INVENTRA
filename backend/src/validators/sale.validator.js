import { z } from 'zod';

export const createSaleBodySchema = z.object({
  items: z
    .array(
      z.object({
        product_id: z.coerce
          .number()
          .int('Produk tidak valid')
          .positive('Produk tidak valid'),
        quantity: z.coerce
          .number()
          .int('Jumlah harus bilangan bulat')
          .positive('Jumlah harus lebih dari 0'),
      })
    )
    .min(1, 'Minimal satu barang')
    .max(50, 'Maksimal 50 barang')
    .refine(
      (items) =>
        new Set(items.map((item) => item.product_id)).size === items.length,
      { message: 'Produk tidak boleh duplikat' }
    ),
});
