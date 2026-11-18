import 'dotenv/config';
import fs from 'node:fs';
import path from 'node:path';
import pg from 'pg';

const { Client } = pg;

const baseConfig = {
  host: process.env.DB_HOST,
  port: Number(process.env.DB_PORT),
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  ssl: process.env.DB_SSL === 'true' ? { rejectUnauthorized: false } : false,
};

const dbName = process.env.DB_NAME;
const adminDb = process.env.DB_ADMIN_DB ?? 'postgres';

async function main() {
  const admin = new Client({ ...baseConfig, database: adminDb });
  await admin.connect();

  const exists = await admin.query('SELECT 1 FROM pg_database WHERE datname = $1', [dbName]);
  if (exists.rowCount === 0) {
    await admin.query(`CREATE DATABASE "${dbName}"`);
    console.log(`[db-init] Database "${dbName}" dibuat`);
  } else {
    console.log(`[db-init] Database "${dbName}" sudah ada`);
  }
  await admin.end();

  const client = new Client({ ...baseConfig, database: dbName });
  await client.connect();

  const hasUsersTable = await client.query("SELECT to_regclass('public.users') AS name");
  const reset = process.env.DB_RESET === 'true';

  if (reset || !hasUsersTable.rows[0].name) {
    const schema = fs.readFileSync(path.resolve('database/schema.sql'), 'utf8');
    await client.query(schema);
    console.log(reset ? '[db-init] schema.sql (reset) selesai' : '[db-init] schema.sql selesai');
  } else {
    console.log('[db-init] Tabel sudah ada, schema dilewati (set DB_RESET=true untuk reset)');
  }

  const seed = fs.readFileSync(path.resolve('database/seed.sql'), 'utf8');
  await client.query(seed);
  console.log('[db-init] seed.sql selesai');

  const counts = await client.query(`
    SELECT
      (SELECT COUNT(*)::int FROM users) AS users,
      (SELECT COUNT(*)::int FROM categories) AS categories,
      (SELECT COUNT(*)::int FROM products) AS products,
      (SELECT COUNT(*)::int FROM stock_movements) AS stock_movements,
      (SELECT COUNT(*)::int FROM sales) AS sales
  `);
  console.log('[db-init] Jumlah data:', counts.rows[0]);

  await client.end();
}

main().catch((err) => {
  console.error('[db-init] Gagal:', err.message);
  process.exit(1);
});
