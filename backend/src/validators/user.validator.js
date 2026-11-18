import { z } from 'zod';
import { paginationQuerySchema } from './common.validator.js';

export const userQuerySchema = paginationQuerySchema.extend({
  role: z.enum(['admin', 'staff']).optional(),
  search: z.string().trim().max(100).optional(),
});
