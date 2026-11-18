# INVENTRA

INVENTRA adalah sistem manajemen informasi stok barang toko berbasis web dan mobile. Aplikasi ini membantu admin dan staff mencatat produk, kategori, supplier, pergerakan stok, transaksi penjualan, serta melihat laporan stok secara terpusat.

## Fitur

- Autentikasi JWT dengan role `admin` dan `staff`.
- Dashboard ringkasan produk, stok menipis, dan transaksi hari ini.
- CRUD kategori, supplier, dan produk.
- Upload gambar produk (lokal atau Cloudinary).
- Stok masuk, stok keluar, penyesuaian stok, dan riwayat pergerakan.
- Transaksi penjualan dengan validasi stok dan rollback otomatis.
- Pembatalan penjualan yang mengembalikan stok.
- Notifikasi stok menipis dan laporan ringkasan.
- Antarmuka Flutter responsif untuk web dan Android.

## Teknologi

| Lapisan | Teknologi |
|---|---|
| Frontend | Flutter, Dart, Material 3 |
| Backend | Node.js, Express, Zod, JWT |
| Database | PostgreSQL |
| Storage | Cloudinary / folder lokal |
| Deployment | Netlify, Vercel, Aiven |
| Version control | Git dan GitHub |

## Struktur Repository

```text
.
├── backend/          # REST API Express + PostgreSQL (serverless di Vercel)
├── flutter/          # Aplikasi Flutter (web, Android, desktop)
├── docs/             # SRS, diagram, dan panduan deployment
├── render.yaml       # Blueprint alternatif backend Render
├── netlify.toml      # Konfigurasi deploy frontend Netlify
└── README.md
```

## Menjalankan Secara Lokal

### 1. Backend

```powershell
cd backend
npm install
copy .env.example .env
npm run db:init
npm start
```

Sesuaikan `DB_*` dan `JWT_SECRET` di `backend/.env`. API berjalan di `http://localhost:3000` dan health check tersedia di `GET /api/health`.

### 2. Frontend

```powershell
cd flutter
flutter pub get
flutter run -d chrome
```

Untuk menunjuk API lain:

```powershell
flutter run -d chrome --dart-define=API_BASE_URL=http://localhost:3000
```

## Akun Pengujian

| Role | Email | Password |
|---|---|---|
| Admin | `admin@toko.test` | `admin123` |
| Staff | `user@toko.test` | `user123` |

Akun ini dibuat oleh `backend/database/seed.sql`. Ganti password dan `JWT_SECRET` sebelum digunakan di lingkungan produksi.

## Pengujian

```powershell
cd backend
npm test

cd ..\flutter
flutter analyze
flutter test
flutter build web --release
```

## Deployment

Panduan lengkap ada di [`docs/DEPLOYMENT.md`](docs/DEPLOYMENT.md). Ringkasan platform:

- Frontend: Netlify (utama) atau Vercel.
- Backend: Vercel (serverless function melalui `backend/api/index.js`).
- Database: Aiven for PostgreSQL.
- Gambar produk: Cloudinary.

Status URL produksi akan diisi setelah proses deploy selesai.

## Dokumentasi

- [`docs/SRS_INVENTRA.docx`](docs/SRS_INVENTRA.docx) — dokumen SRS lengkap.
- [`docs/SRS_INVENTRA.pdf`](docs/SRS_INVENTRA.pdf) — versi PDF.
- [`backend/api.md`](backend/api.md) — daftar endpoint API.
- [`backend/README.md`](backend/README.md) — dokumentasi backend.
- [`flutter/README.md`](flutter/README.md) — dokumentasi aplikasi Flutter.

## Lisensi

Proyek ini dibuat untuk keperluan pembelajaran di SMK Taruna Bhakti.
