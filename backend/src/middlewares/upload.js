import fs from 'node:fs';
import path from 'node:path';
import multer from 'multer';
import { env } from '../config/env.js';
import { cloudinaryEnabled } from '../config/cloudinary.js';
import { AppError } from '../utils/AppError.js';

export const uploadRootDir = path.resolve(process.cwd(), env.uploadDir);
fs.mkdirSync(uploadRootDir, { recursive: true });

const allowedMimeTypes = new Map([
  ['image/jpeg', '.jpg'],
  ['image/png', '.png'],
  ['image/webp', '.webp'],
]);

const diskStorage = multer.diskStorage({
  destination: (req, file, cb) => cb(null, uploadRootDir),
  filename: (req, file, cb) => {
    const ext = allowedMimeTypes.get(file.mimetype) ?? path.extname(file.originalname).toLowerCase();
    const unique = `${Date.now()}-${Math.round(Math.random() * 1e9)}`;
    cb(null, `${unique}${ext}`);
  },
});

const storage = cloudinaryEnabled ? multer.memoryStorage() : diskStorage;

const MAX_FILE_SIZE = 5 * 1024 * 1024;

export const uploadProductImage = multer({
  storage,
  limits: { fileSize: MAX_FILE_SIZE },
  fileFilter: (req, file, cb) => {
    if (!allowedMimeTypes.has(file.mimetype)) {
      return cb(new AppError(422, 'Format file tidak didukung. Gunakan JPG, PNG, atau WEBP'));
    }
    cb(null, true);
  },
}).single('image');
