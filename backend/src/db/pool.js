import pg from 'pg';
import { env } from '../config/env.js';

const { Pool, types } = pg;

types.setTypeParser(types.builtins.NUMERIC, (value) => Number(value));
types.setTypeParser(types.builtins.INT8, (value) => Number(value));

export const pool = new Pool({
  host: env.db.host,
  port: env.db.port,
  database: env.db.database,
  user: env.db.user,
  password: env.db.password,
  ssl: env.db.ssl,
  max: 10,
});

pool.on('error', (err) => {
  console.error('[db] Kesalahan pada koneksi idle:', err.message);
});

export const query = (text, params) => pool.query(text, params);

export async function withTransaction(handler) {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');
    const result = await handler(client);
    await client.query('COMMIT');
    return result;
  } catch (err) {
    await client.query('ROLLBACK');
    throw err;
  } finally {
    client.release();
  }
}
