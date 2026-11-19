# Panduan Deployment INVENTRA

Dokumen ini menjelaskan langkah deploy INVENTRA ke layanan gratis: **Aiven for PostgreSQL**, **Vercel** untuk backend, serta **Netlify** untuk frontend Flutter Web.

> Ganti semua placeholder `[GANTI_...]` dengan nilai milik Anda. Jangan commit file `.env` atau kredensial ke repository.

## Status Deployment

| Layanan | URL | Status |
|---|---|---|
| Frontend Netlify | https://silver-cocada-e5a190.netlify.app | Aktif |
| Backend Vercel | https://inventra-stok-api.vercel.app | Aktif |
| Health check | https://inventra-stok-api.vercel.app/api/health | Database connected |
| Database | Aiven for PostgreSQL - `pg-37025a25-project-crudd.a.aivencloud.com` | Aktif |
| Repository | https://github.com/SHIKAMAZU/UMKM-INVENTRA | Aktif |

## 1. Prasyarat

- Akun GitHub, Aiven, Vercel, dan Netlify.
- Repository GitHub berisi proyek ini.
- Git terpasang di komputer.
- Flutter hanya diperlukan untuk build lokal; Netlify membangun web secara otomatis.

## 2. Siapkan Database Aiven

1. Buat service **Aiven for PostgreSQL** (paket gratis).
2. Catat **Host**, **Port**, **Database**, **User**, dan **Password** dari halaman *Connection information*.
3. Aktifkan **SSL**. Nilai yang dipakai INVENTRA:
   - `DB_SSL=true`
   - `DB_HOST=[GANTI_HOST_AIVEN]`
   - `DB_PORT=[GANTI_PORT_AIVEN]`
   - `DB_NAME=defaultdb`
   - `DB_USER=avnadmin`
   - `DB_PASSWORD=[GANTI_PASSWORD_AIVEN]`
4. Inisialisasi skema dan seed dari komputer lokal:

```powershell
cd "C:\sistem manajemen informasi stok barang toko\backend"
$env:DB_HOST="[GANTI_HOST_AIVEN]"
$env:DB_PORT="[GANTI_PORT_AIVEN]"
$env:DB_NAME="defaultdb"
$env:DB_USER="avnadmin"
$env:DB_PASSWORD="[GANTI_PASSWORD_AIVEN]"
$env:DB_SSL="true"
$env:DB_ADMIN_DB="defaultdb"
npm run db:init
```

`db:init` tidak menghapus skema jika tabel `users` sudah ada. Gunakan `DB_RESET=true` hanya jika ingin mengulang dari awal karena `schema.sql` bersifat destruktif.

## 3. Deploy Backend ke Vercel

1. Login ke Vercel dengan akun GitHub.
2. Pilih **Add New > Project**, lalu impor repository INVENTRA.
3. Pada halaman konfigurasi:
   - **Root Directory:** `backend`
   - **Framework Preset:** `Other`
   - Build Command dan Output Directory dikosongkan.
4. Buka **Environment Variables**, lalu isi:
   - `NODE_ENV` = `production`
   - `DB_HOST`, `DB_PORT`, `DB_NAME`, `DB_USER`, `DB_PASSWORD`
   - `DB_SSL` = `true`
   - `DB_ADMIN_DB` = `defaultdb`
   - `JWT_SECRET` = string acak panjang
   - `JWT_EXPIRES_IN` = `1d`
   - `UPLOAD_DIR` = `uploads`
   - `CLOUDINARY_CLOUD_NAME`, `CLOUDINARY_API_KEY`, `CLOUDINARY_API_SECRET` (disarankan)
5. Klik **Deploy** dan tunggu status **Ready**.
6. Buka `https://[NAMA-PROJECT].vercel.app/api/health`; respons harus `database: connected`.

Backend berjalan sebagai serverless function melalui `backend/api/index.js` dan `backend/vercel.json`. `JWT_SECRET` harus string acak panjang; jangan gunakan nilai contoh.

Catat URL backend, misalnya:

```text
https://inventra-api.vercel.app
```

### Alternatif: Render

File `render.yaml` tetap tersedia jika ingin memakai Render. Pilih **New > Blueprint**, hubungkan repository, lalu isi environment variable yang sama seperti di atas.

## 4. Deploy Frontend ke Netlify

1. Di Netlify, pilih **Add new site > Import an existing project**.
2. Hubungkan repository GitHub.
3. Netlify membaca `netlify.toml`:
   - Base directory: `flutter`
   - Build command: `bash netlify-build.sh`
   - Publish directory: `build/web`
4. Tambahkan environment variable:
   - `API_BASE_URL=https://[NAMA-PROJECT].vercel.app`
5. Deploy. Netlify akan mengunduh Flutter stable jika belum tersedia, lalu menjalankan:

```bash
flutter build web --release --dart-define=API_BASE_URL=$API_BASE_URL
```

6. Buka URL Netlify dan uji login admin/staff.

## 5. Alternatif Frontend di Vercel

Vercel tidak membaca `netlify.toml`. Buat konfigurasi berikut.

**Build Command:**

```bash
cd flutter && bash netlify-build.sh
```

**Output Directory:**

```text
flutter/build/web
```

**Environment Variable:**

```text
API_BASE_URL=https://[NAMA-PROJECT].vercel.app
```

Tambahkan rewrite semua rute ke `index.html` agar refresh halaman tidak 404. Jika menggunakan `vercel.json`:

```json
{
  "rewrites": [{ "source": "/(.*)", "destination": "/index.html" }]
}
```

## 6. Environment Variable Penting

| Variabel | Contoh | Keterangan |
|---|---|---|
| `DB_HOST` | `pg-xxx.aivencloud.com` | Host Aiven |
| `DB_PORT` | `12345` | Port Aiven |
| `DB_NAME` | `defaultdb` | Nama database |
| `DB_USER` | `avnadmin` | User database |
| `DB_PASSWORD` | `********` | Password database |
| `DB_SSL` | `true` | Wajib untuk Aiven |
| `DB_ADMIN_DB` | `defaultdb` | Database untuk membuat database baru saat init |
| `JWT_SECRET` | string acak 32+ karakter | Jangan dibagikan |
| `JWT_EXPIRES_IN` | `1d` | Masa berlaku token |
| `UPLOAD_DIR` | `uploads` | Penyimpanan lokal sementara |
| `CLOUDINARY_*` | kredensial Cloudinary | Agar gambar tidak hilang saat restart |
| `API_BASE_URL` | `https://inventra-api.vercel.app` | Hanya untuk build frontend |

## 7. Uji Setelah Deploy

```powershell
cd "C:\sistem manajemen informasi stok barang toko\backend"
$env:API_URL="https://[NAMA-PROJECT].vercel.app"
npm test
```

Uji manual:

1. Buka frontend, login `admin@toko.test / admin123`.
2. Tambah produk, ubah stok, buat penjualan.
3. Buka laporan dan notifikasi stok.
4. Login staff, pastikan tombol admin tidak muncul.
5. Upload gambar produk dan pastikan URL gambar dapat diakses.

## 8. Catatan Produksi

- Vercel free tier dapat *cold start*; permintaan pertama bisa lambat.
- Penyimpanan lokal pada serverless Vercel bersifat sementara (folder `/tmp`). Gunakan Cloudinary untuk gambar.
- `cors()` saat ini terbuka untuk memudahkan pengembangan. Untuk produksi, batasi origin ke domain frontend.
- `DB_SSL=true` memakai `rejectUnauthorized: false` agar kompatibel dengan sertifikat Aiven. Untuk keamanan lebih tinggi, gunakan CA certificate resmi.
- Jangan menjalankan `DB_RESET=true` pada database produksi.
- Simpan URL final di `docs/SRS_INVENTRA.html` Lampiran D dan `README.md`.
