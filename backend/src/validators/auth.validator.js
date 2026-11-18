import { z } from 'zod';

export const registerBodySchema = z.object({
  name: z.string().trim().min(3, 'Nama minimal 3 karakter').max(100, 'Nama maksimal 100 karakter'),
  email: z
    .string()
    .trim()
    .toLowerCase()
    .email('Format email tidak valid')
    .max(150, 'Email maksimal 150 karakter'),
  password: z
    .string()
    .min(6, 'Password minimal 6 karakter')
    .max(72, 'Password maksimal 72 karakter'),
});

export const loginBodySchema = z.object({
  email: z.string().trim().toLowerCase().email('Format email tidak valid'),
  password: z.string().min(1, 'Password wajib diisi'),
});
