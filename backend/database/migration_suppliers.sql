-- Migrasi: tambah tabel supplier tanpa menghapus data lama.
-- Jalankan: psql -U postgres -d sistem_stok_toko -f database/migration_suppliers.sql

BEGIN;

CREATE TABLE IF NOT EXISTS suppliers (
  id          BIGSERIAL PRIMARY KEY,
  name        VARCHAR(150) NOT NULL,
  phone       VARCHAR(30),
  email       VARCHAR(150),
  address     TEXT,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT suppliers_name_unique UNIQUE (name)
);

CREATE INDEX IF NOT EXISTS idx_suppliers_name ON suppliers (lower(name));

CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DO $$
BEGIN
  CREATE TRIGGER trg_suppliers_updated_at
    BEFORE UPDATE ON suppliers
    FOR EACH ROW EXECUTE FUNCTION set_updated_at();
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

INSERT INTO suppliers (name, phone, email, address) VALUES
  ('PT Sumber Makmur', '021-5551234', 'sales@sumbermakmur.test', 'Jl. Raya Industri No. 12, Jakarta'),
  ('CV Aneka Snack', '0812-3456-7890', 'order@anekasnack.test', 'Jl. Pasar Baru No. 8, Bandung')
ON CONFLICT (name) DO NOTHING;

COMMIT;
