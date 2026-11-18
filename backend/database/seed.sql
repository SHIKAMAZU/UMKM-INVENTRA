-- =============================================================
-- Seed data - Sistem Manajemen Informasi Stok Barang Toko
-- Akun pengujian:
--   admin@toko.test / admin123  (role: admin)
--   user@toko.test / user123  (role: staff)
-- Jalankan: psql -U postgres -d sistem_stok_toko -f database/seed.sql
-- =============================================================

BEGIN;

INSERT INTO users (name, email, password_hash, role) VALUES
  ('Admin Toko', 'admin@toko.test', '$2a$10$IRgL4TvZivCGs9G.24VQz.lc3D42PESaPHGYgnBcAxHqvjfE18izy', 'admin'),
  ('Staff Toko', 'user@toko.test', '$2a$10$1VcdXFV2C/Ws6ALTW.qtxeynubZgQQIa.78QFy8RPjN4xRCNmoUGm', 'staff')
ON CONFLICT (email) DO NOTHING;

INSERT INTO categories (name, description) VALUES
  ('Makanan Ringan', 'Snack dan camilan kemasan'),
  ('Minuman', 'Minuman kemasan dan sachet'),
  ('Sembako', 'Kebutuhan pokok sehari-hari'),
  ('Alat Tulis', 'Kebutuhan sekolah dan kantor')
ON CONFLICT (name) DO NOTHING;

INSERT INTO suppliers (name, phone, email, address) VALUES
  ('PT Sumber Makmur', '021-5551234', 'sales@sumbermakmur.test', 'Jl. Raya Industri No. 12, Jakarta'),
  ('CV Aneka Snack', '0812-3456-7890', 'order@anekasnack.test', 'Jl. Pasar Baru No. 8, Bandung')
ON CONFLICT (name) DO NOTHING;

INSERT INTO products (category_id, sku, name, description, price, stock, min_stock)
SELECT c.id, v.sku, v.name, v.description, v.price, v.stock, v.min_stock
FROM (VALUES
  ('Makanan Ringan', 'SNK-001', 'Keripik Kentang 68g', 'Keripik kentang rasa original', 12000.00, 40, 10),
  ('Makanan Ringan', 'SNK-002', 'Biskuit Cokelat 120g', 'Biskuit lapis cokelat', 9500.00, 25, 8),
  ('Minuman',       'MNM-001', 'Air Mineral 600ml', 'Air mineral botol', 4000.00, 60, 20),
  ('Minuman',       'MNM-002', 'Teh Kotak 250ml', 'Minuman teh dalam kotak', 5000.00, 8, 12),
  ('Sembako',       'SMK-001', 'Beras Premium 5kg', 'Beras kualitas premium', 68000.00, 15, 5),
  ('Alat Tulis',    'ATK-001', 'Pulpen Hitam', 'Pulpen tinta hitam 0.5mm', 3000.00, 50, 15)
) AS v(category_name, sku, name, description, price, stock, min_stock)
JOIN categories c ON c.name = v.category_name
ON CONFLICT (sku) DO NOTHING;

INSERT INTO stock_movements (product_id, user_id, type, quantity, note)
SELECT p.id, u.id, 'in', p.stock, 'Stok awal saat data dibuat'
FROM products p
JOIN users u ON u.email = 'admin@toko.test'
WHERE NOT EXISTS (
  SELECT 1 FROM stock_movements sm WHERE sm.product_id = p.id
);

COMMIT;
