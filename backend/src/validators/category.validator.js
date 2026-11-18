import { z } from 'zod';

const name = z
  .string()
  .trim()
  .min(2, 'Nama kategori minimal 2 karakter')
  .max(100, 'Nama kategori maksimal 100 karakter');

const description = z.string().trim().max(500, 'Deskripsi maksimal 500 karakter');

export const createCategoryBodySchema = z.object({
  name,
  description: description.optional().nullable(),
});

export const updateCategoryBodySchema = z
  .object({
    name: name.optional(),
    description: description.optional().nullable(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'Minimal satu field harus diisi',
  });
