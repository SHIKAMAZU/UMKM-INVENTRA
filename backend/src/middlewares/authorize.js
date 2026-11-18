import { AppError } from '../utils/AppError.js';

export const authorize = (...roles) => (req, res, next) => {
  if (!req.user) {
    return next(new AppError(401, 'Autentikasi diperlukan'));
  }
  if (!roles.includes(req.user.role)) {
    return next(new AppError(403, 'Anda tidak memiliki hak akses untuk aksi ini'));
  }
  next();
};
