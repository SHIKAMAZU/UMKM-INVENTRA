import bcrypt from 'bcryptjs';
import jwt from 'jsonwebtoken';
import { env } from '../config/env.js';
import { query } from '../db/pool.js';
import { AppError } from '../utils/AppError.js';
import { asyncHandler } from '../utils/asyncHandler.js';
import { sendSuccess } from '../utils/response.js';

const toPublicUser = (user) => ({
  id: user.id,
  name: user.name,
  email: user.email,
  role: user.role,
  is_active: user.is_active,
  created_at: user.created_at,
});

export const register = asyncHandler(async (req, res) => {
  const { name, email, password } = req.validated.body;
  const passwordHash = await bcrypt.hash(password, 10);

  try {
    const { rows } = await query(
      `INSERT INTO users (name, email, password_hash, role)
       VALUES ($1, $2, $3, 'staff')
       RETURNING id, name, email, role, is_active, created_at`,
      [name, email, passwordHash]
    );

    sendSuccess(res, {
      status: 201,
      message: 'Registrasi berhasil',
      data: toPublicUser(rows[0]),
    });
  } catch (err) {
    if (err.code === '23505') {
      throw new AppError(409, 'Email sudah terdaftar');
    }
    throw err;
  }
});

export const login = asyncHandler(async (req, res) => {
  const { email, password } = req.validated.body;
  const { rows } = await query('SELECT * FROM users WHERE email = $1', [email]);
  const user = rows[0];

  if (!user) {
    throw new AppError(401, 'Email atau password salah');
  }
  if (!user.is_active) {
    throw new AppError(403, 'Akun tidak aktif');
  }

  const passwordMatch = await bcrypt.compare(password, user.password_hash);
  if (!passwordMatch) {
    throw new AppError(401, 'Email atau password salah');
  }

  const signOptions =
    env.jwt.expiresIn && env.jwt.expiresIn !== 'never'
      ? { expiresIn: env.jwt.expiresIn }
      : {};

  const token = jwt.sign(
    { sub: user.id, role: user.role, name: user.name },
    env.jwt.secret,
    signOptions
  );

  sendSuccess(res, {
    message: 'Login berhasil',
    data: { token, user: toPublicUser(user) },
  });
});

export const me = asyncHandler(async (req, res) => {
  sendSuccess(res, { data: req.user });
});
