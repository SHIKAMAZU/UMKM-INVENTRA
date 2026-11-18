# Backend - Sistem Manajemen Informasi Stok Barang Toko

REST API untuk aplikasi UMKM toko/retail: pengelolaan kategori, produk, stok, upload gambar produk, serta autentikasi dan otorisasi berbasis role.

## Teknologi

- Node.js (ES Modules) + Express.js
- PostgreSQL (`pg`)
- JWT (`jsonwebtoken`) + hash password (`bcryptjs`)
- Validasi input (`zod`)
- Upload file (`multer`)

## Prasyarat

- Node.js 18+
- PostgreSQL 14+ (sudah berjalan)

## Cara Menjalankan

1. Install dependency:

   ```bash
   npm install
   ```

2. Salin konfigurasi environment lalu sesuaikan:

   ```bash
   copy .env.example .env
   ```

   Isi variabel berikut di `.env`:

   | Variabel | Keterangan |
   |---|---|
   | `PORT` | Port server (default `3000`) |
   | `DB_HOST`, `DB_PORT` | Host dan port PostgreSQL |
   | `DB_NAME` | Nama database (default `sistem_stok_toko`) |
   | `DB_USER`, `DB_PASSWORD` | Kredensial PostgreSQL |
   | `JWT_SECRET` | String acak panjang untuk menandatangani token |
   | `JWT_EXPIRES_IN` | Masa berlaku token JWT (disarankan `1d`) |
   | `UPLOAD_DIR` | Folder penyimpanan upload (default `uploads`) |

3. Buat database, tabel, dan data seed:

   ```bash
   npm run db:init
   ```

4. Jalankan server:

   ```bash
   npm start
   ```

   Mode development (auto restart):

   ```bash
   npm run dev
   ```

5. Cek kesehatan API: `http://localhost:3000/api/health`

## Script

| Perintah | Fungsi |
|---|---|
| `npm start` | Menjalankan server |
| `npm run dev` | Menjalankan server dengan auto reload |
| `npm run db:init` | Membuat database + schema + seed |
| `npm test` | Smoke test seluruh endpoint utama |

> `npm test` membutuhkan server yang sedang berjalan.

## Akun Pengujian

| Role | Email | Password |
|---|---|---|
| admin | `admin@toko.test` | `admin123` |
| staff | `user@toko.test` | `user123` |

Role `admin`: kelola kategori, produk, upload gambar, lihat riwayat stok dan daftar user.
Role `staff`: lihat data dan mencatat pergerakan stok (stok masuk/keluar/adjust).

## Ringkasan Endpoint

Dokumentasi lengkap ada di [`api.md`](./api.md).

| Method | Endpoint | Akses |
|---|---|---|
| POST | `/api/auth/register` | publik |
| POST | `/api/auth/login` | publik |
| GET | `/api/auth/me` | login |
| GET | `/api/categories` | login |
| GET | `/api/categories/:id` | login |
| POST/PUT/DELETE | `/api/categories` | admin |
| GET | `/api/products` | login |
| GET | `/api/products/:id` | login |
| POST/PUT/DELETE | `/api/products` | admin |
| POST | `/api/products/:id/image` | admin |
| POST | `/api/products/:id/stock` | admin, staff |
| GET/POST | `/api/sales` | admin, staff |
| DELETE | `/api/sales/:id` | admin |
| GET | `/api/stock-movements` | admin |
| GET | `/api/suppliers` | login |
| POST/PUT/DELETE | `/api/suppliers` | admin |
| GET | `/api/users` | admin |

## Struktur Folder

```
backend/
├── database/
│   ├── schema.sql        # Struktur tabel, relasi, index, trigger
│   ├── migration_sales.sql # Migrasi tabel penjualan tanpa reset data
│   ├── seed.sql          # Data awal + akun pengujian
│   └── ERD.html          # Diagram ERD (buka di browser)
├── scripts/
│   ├── db-init.mjs       # Membuat database, menjalankan schema & seed
│   └── smoke-test.mjs    # Pengujian endpoint
├── src/
│   ├── config/           # Konfigurasi environment
│   ├── controllers/      # Logika endpoint
│   ├── db/               # Koneksi & helper transaksi
│   ├── middlewares/      # Auth, otorisasi, validasi, upload, error handler
│   ├── routes/           # Definisi route
│   ├── utils/            # Helper (AppError, response, async handler)
│   ├── validators/       # Skema validasi Zod
│   ├── app.js            # Setup Express
│   └── server.js         # Entry point
├── uploads/              # File hasil upload (disajikan di /uploads)
├── api.md                # Dokumentasi API
└── package.json
```

## Catatan

- Password disimpan sebagai hash bcrypt, bukan teks biasa.
- Endpoint privat memakai header `Authorization: Bearer <token>`.
- Upload gambar: JPG/PNG/WEBP, maksimal 5 MB, diakses melalui `/uploads/<nama-file>`.
- Perubahan stok hanya melalui endpoint stok agar riwayat tetap konsisten.
- `database/schema.sql` bersifat reset (menghapus tabel lama) — jangan dijalankan pada data produksi.
- Jika database sudah berisi data dan hanya ingin menambah tabel penjualan, jalankan `psql -U postgres -d sistem_stok_toko -f database/migration_sales.sql` (tanpa reset).
