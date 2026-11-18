-- =============================================================
-- Sistem Manajemen Informasi Stok Barang Toko
-- Skema Database - PostgreSQL 18
-- PERINGATAN: script ini menghapus tabel lama lalu membuat ulang.
-- Jalankan: psql -U postgres -d sistem_stok_toko -f database/schema.sql
-- =============================================================

BEGIN;

-- ---------- ENUM ----------
DO $$
BEGIN
  CREATE TYPE user_role AS ENUM ('admin', 'staff');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

DO $$
BEGIN
  CREATE TYPE movement_type AS ENUM ('in', 'out', 'adjust');
EXCEPTION
  WHEN duplicate_object THEN NULL;
END $$;

-- ---------- RESET ----------
DROP TABLE IF EXISTS sale_items CASCADE;
DROP TABLE IF EXISTS sales CASCADE;
DROP TABLE IF EXISTS stock_movements CASCADE;
DROP TABLE IF EXISTS products CASCADE;
DROP TABLE IF EXISTS categories CASCADE;
DROP TABLE IF EXISTS suppliers CASCADE;
DROP TABLE IF EXISTS users CASCADE;

-- ---------- USERS ----------
CREATE TABLE users (
  id            BIGSERIAL PRIMARY KEY,
  name          VARCHAR(100) NOT NULL,
  email         VARCHAR(150) NOT NULL,
  password_hash TEXT         NOT NULL,
  role          user_role    NOT NULL DEFAULT 'staff',
  is_active     BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at    TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT users_email_unique UNIQUE (email),
  CONSTRAINT users_email_format CHECK (email ~* '^[^@[:space:]]+@[^@[:space:]]+\.[^@[:space:]]+$')
);

-- ---------- CATEGORIES ----------
CREATE TABLE categories (
  id          BIGSERIAL PRIMARY KEY,
  name        VARCHAR(100) NOT NULL,
  description TEXT,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT categories_name_unique UNIQUE (name)
);

-- ---------- SUPPLIERS ----------
CREATE TABLE suppliers (
  id          BIGSERIAL PRIMARY KEY,
  name        VARCHAR(150) NOT NULL,
  phone       VARCHAR(30),
  email       VARCHAR(150),
  address     TEXT,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT suppliers_name_unique UNIQUE (name)
);

-- ---------- PRODUCTS ----------
CREATE TABLE products (
  id          BIGSERIAL PRIMARY KEY,
  category_id BIGINT       NOT NULL,
  sku         VARCHAR(50)  NOT NULL,
  name        VARCHAR(150) NOT NULL,
  description TEXT,
  price       NUMERIC(12,2) NOT NULL DEFAULT 0,
  stock       INTEGER      NOT NULL DEFAULT 0,
  min_stock   INTEGER      NOT NULL DEFAULT 5,
  image_url   TEXT,
  created_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  updated_at  TIMESTAMPTZ  NOT NULL DEFAULT now(),
  CONSTRAINT products_sku_unique UNIQUE (sku),
  CONSTRAINT products_price_nonnegative CHECK (price >= 0),
  CONSTRAINT products_stock_nonnegative CHECK (stock >= 0),
  CONSTRAINT products_min_stock_nonnegative CHECK (min_stock >= 0),
  CONSTRAINT products_category_fk FOREIGN KEY (category_id)
    REFERENCES categories (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ---------- STOCK MOVEMENTS ----------
CREATE TABLE stock_movements (
  id         BIGSERIAL PRIMARY KEY,
  product_id BIGINT        NOT NULL,
  user_id    BIGINT        NOT NULL,
  type       movement_type NOT NULL,
  quantity   INTEGER       NOT NULL,
  note       TEXT,
  created_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
  CONSTRAINT stock_movements_quantity_positive CHECK (quantity > 0),
  CONSTRAINT stock_movements_product_fk FOREIGN KEY (product_id)
    REFERENCES products (id) ON UPDATE CASCADE ON DELETE CASCADE,
  CONSTRAINT stock_movements_user_fk FOREIGN KEY (user_id)
    REFERENCES users (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

-- ---------- SALES ----------
CREATE TABLE sales (
  id         BIGSERIAL PRIMARY KEY,
  user_id    BIGINT        NOT NULL,
  total      NUMERIC(14,2) NOT NULL DEFAULT 0,
  created_at TIMESTAMPTZ   NOT NULL DEFAULT now(),
  CONSTRAINT sales_total_nonnegative CHECK (total >= 0),
  CONSTRAINT sales_user_fk FOREIGN KEY (user_id)
    REFERENCES users (id) ON UPDATE CASCADE ON DELETE RESTRICT
);

CREATE TABLE sale_items (
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

-- ---------- INDEX ----------
CREATE INDEX idx_users_role ON users (role);
CREATE INDEX idx_suppliers_name ON suppliers (lower(name));
CREATE INDEX idx_products_category_id ON products (category_id);
CREATE INDEX idx_products_name ON products (lower(name));
CREATE INDEX idx_stock_movements_product_id ON stock_movements (product_id);
CREATE INDEX idx_stock_movements_created_at ON stock_movements (created_at DESC);
CREATE INDEX idx_sales_created_at ON sales (created_at DESC);
CREATE INDEX idx_sale_items_sale_id ON sale_items (sale_id);
CREATE INDEX idx_sale_items_product_id ON sale_items (product_id);

-- ---------- TRIGGER updated_at ----------
CREATE OR REPLACE FUNCTION set_updated_at() RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trg_users_updated_at
  BEFORE UPDATE ON users
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_categories_updated_at
  BEFORE UPDATE ON categories
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_suppliers_updated_at
  BEFORE UPDATE ON suppliers
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

CREATE TRIGGER trg_products_updated_at
  BEFORE UPDATE ON products
  FOR EACH ROW EXECUTE FUNCTION set_updated_at();

COMMIT;
