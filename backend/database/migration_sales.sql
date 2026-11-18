-- Migrasi: tambah tabel penjualan tanpa menghapus data lama.
-- Jalankan: psql -U postgres -d sistem_stok_toko -f database/migration_sales.sql

BEGIN;

CREATE TABLE IF NOT EXISTS sales (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT        NOT NULL,
  total      NUMERIC(14,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
  CONSTRAINT sales_total_nonnegative CHECK (total >= 0),
  CONSTRAINT sales_user_fk FOREIGN KEY (user_id)
    REFERENCES users (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE IF NOT EXISTS sale_items (
  id           BIGSERIAL PRIMARY KEY,
  sale_id      BIGINT        NOT NULL,
  product_id   BIGINT        NOT NULL,
  product_name VARCHAR(150)  NOT NULL,
  price        NUMERIC(12,2) NOT NULL,
  quantity     INTEGER       NOT NULL,
  subtotal     NUMERIC(14,2) NOT NULL,
  CONSTRAINT sale_items_quantity_positive CHECK (quantity > 0),
  CONSTRAINT sale_items_price_nonnegative CHECK (price >= 0),
  CONSTRAINT sale_items_subtotal_nonnegative CHECK (subtotal >= 0),
  CONSTRAINT sale_items_sale_fk FOREIGN KEY (sale_id)
    REFERENCES sales (id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT sale_items_product_fk FOREIGN KEY (product_id)
    REFERENCES products (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE INDEX IF NOT EXISTS idx_sales_created_at ON sales (created_at DESC);
CREATE INDEX IF NOT EXISTS idx_sale_items_sale_id ON sale_items (sale_id);
CREATE INDEX IF NOT EXISTS idx_sale_items_product_id ON sale_items (product_id);

COMMIT;
