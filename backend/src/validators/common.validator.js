import { z } from 'zod';

export const idParamSchema = z.object({
  id: z.coerce.number().int('ID harus berupa angka').positive('ID harus lebih dari 0'),
});

export const paginationQuerySchema = z.object({
  page: z.coerce.number().int('Page harus berupa angka').min(1, 'Page minimal 1').default(1),
  limit: z.coerce
    .number()
    .int('Limit harus berupa angka')
    .min(1, 'Limit minimal 1')
    .max(100, 'Limit maksimal 100')
    .default(10),
});
