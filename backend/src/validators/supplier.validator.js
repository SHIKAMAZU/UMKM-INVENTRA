import { z } from 'zod';

const name = z
  .string()
  .trim()
  .min(2, 'Nama supplier minimal 2 karakter')
  .max(150, 'Nama supplier maksimal 150 karakter');

const phone = z
  .string()
  .trim()
  .regex(/^[0-9+\-\s()]{6,30}$/, 'Nomor telepon tidak valid')
  .max(30, 'Nomor telepon maksimal 30 karakter');

const email = z
  .string()
  .trim()
  .toLowerCase()
  .email('Format email tidak valid')
  .max(150, 'Email maksimal 150 karakter');

const address = z.string().trim().max(500, 'Alamat maksimal 500 karakter');

export const createSupplierBodySchema = z.object({
  name,
  phone: phone.optional().nullable(),
  email: email.optional().nullable(),
  address: address.optional().nullable(),
});

export const updateSupplierBodySchema = z
  .object({
    name: name.optional(),
    phone: phone.optional().nullable(),
    email: email.optional().nullable(),
    address: address.optional().nullable(),
  })
  .refine((data) => Object.keys(data).length > 0, {
    message: 'Minimal satu field harus diisi',
  });
