# Dokumentasi REST API - Stok Toko

Base URL lokal: `http://localhost:3000`
Untuk emulator Android: `http://10.0.2.2:3000`

## Format response

Sukses:
```json
{ "success": true, "message": "OK", "data": {}, "meta": { "page": 1, "limit": 10, "total": 25, "total_pages": 3 } }
```

Gagal:
```json
{ "success": false, "message": "Validasi gagal", "errors": { "email": "Format email tidak valid" } }
```

## Health Check

| Method | Endpoint | Akses |
|---|---|---|
| GET | `/api/health` | publik |

## Autentikasi

Header untuk endpoint privat:
```
Authorization: Bearer <token>
```

| Method | Endpoint | Akses | Body |
|---|---|---|---|
| POST | `/api/auth/register` | publik | `{ name, email, password }` (role otomatis `staff`) |
| POST | `/api/auth/login` | publik | `{ email, password }` → `{ token, user }` |
| GET | `/api/auth/me` | login | - |

Akun seed:
- `admin@toko.test` / `admin123` (admin)
- `user@toko.test` / `user123` (staff)

## Kategori

| Method | Endpoint | Akses |
|---|---|---|
| GET | `/api/categories` | login |
| GET | `/api/categories/:id` | login |
| POST | `/api/categories` | admin |
| PUT | `/api/categories/:id` | admin |
| DELETE | `/api/categories/:id` | admin |

Body POST/PUT: `{ "name": "Minuman", "description": "Minuman kemasan" }`
Response list menyertakan `product_count`.

## Produk

| Method | Endpoint | Akses |
|---|---|---|
| GET | `/api/products?search=&category_id=&low_stock=true&page=1&limit=10` | login |
| GET | `/api/products/:id` | login |
| POST | `/api/products` | admin |
| PUT | `/api/products/:id` | admin |
| DELETE | `/api/products/:id` | admin |
| POST | `/api/products/:id/image` (multipart, field `image`) | admin |
| POST | `/api/products/:id/stock` | admin, staff |

Body POST produk:
```json
{ "category_id": 1, "sku": "MNM-003", "name": "Teh Botol", "description": "Teh manis", "price": 5000, "stock": 10, "min_stock": 5 }
```
Catatan:
- `stock` saat pembuatan produk dicatat sebagai riwayat stok masuk awal; perubahan stok selanjutnya hanya lewat endpoint stok (agar riwayat tetap konsisten).
- `image_url` diisi dari endpoint upload, contoh hasil: `/uploads/1720000000-123.jpg`.
- Gambar diakses di `http://localhost:3000/uploads/<file>`.
- Upload: JPG/PNG/WEBP, ukuran maksimal 5 MB.

Body stok:
```json
{ "type": "in", "quantity": 20, "note": "Restock supplier" }
```
`type`: `in` (tambah), `out` (kurangi, gagal jika stok kurang), `adjust` (set stok menjadi `quantity`).

## Riwayat Stok

| Method | Endpoint | Akses |
|---|---|---|
| GET | `/api/stock-movements?product_id=&type=&page=1&limit=10` | admin |

## Penjualan

| Method | Endpoint | Akses |
|---|---|---|
| GET | `/api/sales?page=1&limit=10` | admin, staff |
| POST | `/api/sales` | admin, staff |
| DELETE | `/api/sales/:id` | admin |

Body POST:
```json
{ "items": [{ "product_id": 1, "quantity": 2 }, { "product_id": 4, "quantity": 1 }] }
```
Catatan:
- Satu transaksi bisa berisi banyak produk (maksimal 50 baris, produk tidak boleh duplikat).
- Harga dan subtotal dihitung server dari harga produk saat transaksi.
- Stok otomatis berkurang dan tercatat di `stock_movements` dengan tipe `out`.
- Gagal jika stok salah satu produk tidak mencukupi (transaksi dibatalkan semua).
- `DELETE /api/sales/:id` menghapus riwayat sekaligus mengembalikan stok dan mencatat movement `in` "Pembatalan penjualan".

## Supplier

| Method | Endpoint | Akses |
|---|---|---|
| GET | `/api/suppliers` | login |
| GET | `/api/suppliers/:id` | login |
| POST | `/api/suppliers` | admin |
| PUT | `/api/suppliers/:id` | admin |
| DELETE | `/api/suppliers/:id` | admin |

Body POST/PUT: `{ "name": "PT Sumber Makmur", "phone": "021-5551234", "email": "sales@sumbermakmur.test", "address": "Jl. Raya Industri No. 12, Jakarta" }`
Field `phone`, `email`, dan `address` opsional.

## Users

| Method | Endpoint | Akses |
|---|---|---|
| GET | `/api/users?role=&search=&page=1&limit=10` | admin |

## Kode status

| Kode | Arti |
|---|---|
| 200 | OK |
| 201 | Data berhasil dibuat |
| 400 | Request tidak valid |
| 401 | Belum login / token salah |
| 403 | Role tidak punya akses |
| 404 | Data/endpoint tidak ditemukan |
| 409 | Duplikat / masih berelasi |
| 413 | File terlalu besar |
| 422 | Validasi input gagal |
| 500 | Kesalahan server |
