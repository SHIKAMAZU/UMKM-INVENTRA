import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { query } from '../db/pool.js';
import { AppError } from '../utils/AppError.js';
import { asyncHandler } from '../utils/asyncHandler.js';

export const authenticate = asyncHandler(async (req, res, next) => {
  const [scheme, token] = (req.headers.authorization ?? '').split(' ');

  if (scheme !== 'Bearer' || !token) {
    throw new AppError(401, 'Token autentikasi tidak ditemukan');
  }

  let payload;
  try {
    payload = jwt.verify(token, env.jwt.secret);
  } catch {
    throw new AppError(401, 'Token tidak valid atau sudah kedaluwarsa');
  }

  const { rows } = await query(
    'SELECT id, name, email, role, is_active, created_at FROM users WHERE id = $1',
    [payload.sub]
  );
  const user = rows[0];

  if (!user || !user.is_active) {
    throw new AppError(401, 'Akun tidak ditemukan atau tidak aktif');
  }

  req.user = user;
  next();
});
