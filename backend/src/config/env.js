import 'dotenv/config';

const required = ['DB_HOST', 'DB_PORT', 'DB_NAME', 'DB_USER', 'DB_PASSWORD', 'JWT_SECRET'];

for (const key of required) {
  if (!process.env[key]) {
    console.error(`[env] Variabel ${key} belum diisi di file .env`);
    process.exit(1);
  }
}

export const env = {
  port: Number(process.env.PORT ?? 3000),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  db: {
    host: process.env.DB_HOST,
    port: Number(process.env.DB_PORT),
    database: process.env.DB_NAME,
    user: process.env.DB_USER,
    password: process.env.DB_PASSWORD,
    ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
  },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN ?? '1d',
  },
  uploadDir: process.env.UPLOAD_DIR ?? 'uploads',
};
