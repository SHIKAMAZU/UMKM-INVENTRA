# INVENTRA - Aplikasi Mobile Stok Barang Toko

Aplikasi mobile untuk UMKM toko/retail yang membantu pengelolaan kategori, produk, stok, supplier, dan transaksi penjualan. Dibangun dengan Flutter dan mengonsumsi REST API dari folder `../backend`.

## Fitur

- Login dan register dengan penyimpanan sesi (token JWT).
- Dashboard ringkasan produk, stok menipis, dan transaksi hari ini.
- Daftar serta detail produk (gambar, harga, stok, deskripsi).
- Tambah, edit, dan hapus produk dengan konfirmasi (khusus admin).
- Upload gambar produk dari galeri dan menampilkannya kembali.
- Kelola kategori dan supplier (khusus admin).
- Kelola stok masuk, keluar, dan penyesuaian.
- Transaksi penjualan multi-produk beserta riwayat dan pembatalan.
- Notifikasi stok menipis dan laporan sederhana.
- Pembatasan tampilan/aksi berdasarkan role pengguna.

## Teknologi

- Flutter 3.x / Dart 3.x
- `http` untuk komunikasi REST API
- `shared_preferences` untuk menyimpan sesi login
- `image_picker` untuk memilih gambar produk

## Prasyarat

- Flutter SDK sudah terpasang (`flutter doctor`).
- Backend sudah berjalan (lihat `../backend/README.md`).

## Menjalankan Backend

```bash
cd ../backend
npm install
npm run db:init
npm start
```

Cek backend di `http://localhost:3000/api/health`.

## Menjalankan Aplikasi

```bash
flutter pub get
flutter run
```

Base URL API diatur otomatis di `lib/config/api_config.dart`:

| Platform | Base URL |
|---|---|
| Android emulator | `http://10.0.2.2:3000` |
| Web / Windows / iOS simulator | `http://localhost:3000` |

Jika memakai perangkat fisik, ganti `baseUrl` menjadi alamat IP komputer yang menjalankan backend, misalnya `http://192.168.1.10:3000`.

## Akun Pengujian

| Role | Email | Password |
|---|---|---|
| admin | `admin@toko.test` | `admin123` |
| staff | `user@toko.test` | `user123` |

Role `admin` dapat mengelola kategori, supplier, dan produk (termasuk upload gambar). Role `staff` dapat melihat data, mengelola stok, dan membuat transaksi penjualan.

## Struktur Folder

```
lib/
├── config/
│   └── api_config.dart          # Base URL API per platform
├── models/
│   └── user.dart                # Model pengguna
├── screens/
│   ├── login_screen.dart
│   ├── register_screen.dart
│   ├── home_screen.dart
│   ├── product_screen.dart
│   ├── product_detail_screen.dart
│   ├── category_screen.dart
│   ├── supplier_screen.dart
│   ├── stock_screen.dart
│   ├── sale_screen.dart
│   ├── sales_history_screen.dart
│   ├── transaction_screen.dart
│   ├── notification_screen.dart
│   ├── report_screen.dart
│   └── profile_screen.dart
└── services/
    ├── api_client.dart          # HTTP client + upload multipart
    ├── auth_service.dart        # Login & register
    └── session.dart             # Penyimpanan token dan user
```

## Pemeriksaan Kode

```bash
flutter analyze
flutter test
```

## Catatan

- Endpoint privat memakai header `Authorization: Bearer <token>`.
- Gambar produk yang diunggah backend diakses melalui `http://<host>:3000/uploads/<nama-file>`.
- Registrasi dari aplikasi selalu membuat akun dengan role `staff`.
