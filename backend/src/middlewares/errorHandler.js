import multer from 'multer';
import { AppError } from '../utils/AppError.js';

export function notFound(req, res, next) {
  next(new AppError(404, `Endpoint ${req.method} ${req.originalUrl} tidak ditemukan`));
}

export function errorHandler(err, req, res, next) {
  let status = err.status ?? 500;
  let message = err.message ?? 'Terjadi kesalahan pada server';
  const errors = err.errors ?? null;

  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      status = 413;
      message = `Ukuran file melebihi batas maksimal ${Math.round(err.limit / (1024 * 1024))} MB`;
    } else {
      status = 400;
      message = `Gagal mengunggah file: ${err.message}`;
    }
  } else if (err.code === '23505') {
    status = 409;
    message = 'Data sudah ada (duplikat)';
  } else if (err.code === '23503' || err.code === '23001') {
    status = 409;
    message = 'Data masih berhubungan dengan data lain';
  } else if (err.code === '23514') {
    status = 400;
    message = 'Data melanggar aturan validasi database';
  }

  if (status >= 500) {
    console.error('[error]', err);
  }

  res.status(status).json({ success: false, message, errors });
}
