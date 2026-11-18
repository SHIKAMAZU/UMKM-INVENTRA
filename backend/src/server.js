import { app } from './app.js';
import { env } from './config/env.js';
import { pool } from './db/pool.js';

async function bootstrap() {
  try {
    await pool.query('SELECT 1');
    console.log('[db] Terhubung ke PostgreSQL');
  } catch (err) {
    console.error('[db] Gagal terhubung ke PostgreSQL:', err.message);
    process.exit(1);
  }

  const server = app.listen(env.port, () => {
    console.log(`[server] Berjalan di http://localhost:${env.port}`);
  });

  const shutdown = async (signal) => {
    console.log(`\n[server] Menerima ${signal}, menutup koneksi...`);
    server.close(async () => {
      await pool.end();
      process.exit(0);
    });
  };

  process.on('SIGINT', () => shutdown('SIGINT'));
  process.on('SIGTERM', () => shutdown('SIGTERM'));
}

bootstrap();
