import { z } from 'zod';
import { paginationQuerySchema } from './common.validator.js';

export const createStockMovementBodySchema = z.object({
  type: z.enum(['in', 'out', 'adjust'], {
    errorMap: () => ({ message: "Tipe harus 'in', 'out', atau 'adjust'" }),
  }),
  quantity: z.coerce
    .number()
    .int('Jumlah harus bilangan bulat')
    .positive('Jumlah harus lebih dari 0'),
  note: z.string().trim().max(255, 'Catatan maksimal 255 karakter').optional().nullable(),
});

export const stockMovementQuerySchema = paginationQuerySchema.extend({
  product_id: z.coerce.number().int().positive().optional(),
  type: z.enum(['in', 'out', 'adjust']).optional(),
});
