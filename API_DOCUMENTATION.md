# SIPERIN API Documentation

**Sistem Pengelolaan Inventaris** — REST API Laravel untuk Flutter / Web / Mobile.

Base URL: `http://127.0.0.1:8000/api`

## Format Response

```json
{
  "success": true,
  "message": "Pesan response",
  "data": {}
}
```

Error:
```json
{
  "success": false,
  "message": "Pesan error",
  "errors": {},
  "data": null
}
```

Header autentikasi: `Authorization: Bearer {token}`

---

## Authentication

| Method | Endpoint | Auth | Deskripsi |
|--------|----------|------|-----------|
| POST | `/login` | - | Login username & password |
| POST | `/register` | - | Registrasi user baru |
| POST | `/forgot-password` | - | Minta token reset password |
| POST | `/reset-password` | - | Reset password dengan token |
| POST | `/logout` | Sanctum | Logout (revoke token) |
| GET | `/me` | Sanctum | Profil user login |
| PUT | `/profile` | Sanctum | Update profil |

### Login Request
```json
{ "username": "admin", "password": "password123" }
```

### Login Response
```json
{
  "success": true,
  "message": "Login berhasil",
  "token": "eyJhbGciOiJIUzI1NiIs...",
  "access_token": "eyJhbGciOiJIUzI1NiIs...",
  "token_type": "Bearer",
  "expires_in": 86400,
  "user": {
    "id": 1,
    "name": "Administrator SIPERIN",
    "username": "admin",
    "role": "admin"
  },
  "data": {
    "token": "...",
    "access_token": "...",
    "user": { }
  }
}
```

> Flutter membaca `token` di root **atau** di dalam `data` (backward compatible).

---

## Role-Based Access

| Role | Akses |
|------|-------|
| `admin` | Full CRUD + kategori + verifikasi |
| `staff` | CRUD barang & kategori |
| `pimpinan` | Read-only (dashboard, laporan, barang) |

---

## Dashboard

| GET | `/dashboard` | Statistik inventaris + grafik |

---

## Barang

| Method | Endpoint | Role |
|--------|----------|------|
| GET | `/barang?search=&kategori=&page=&sort_by=&sort_dir=` | All |
| GET | `/barang/{id}` | All |
| GET | `/barang/{id}/history` | All |
| GET | `/barang/{id}/qr` | All |
| POST | `/barang` | admin, staff |
| PUT | `/barang/{id}` | admin, staff |
| DELETE | `/barang/{id}` | admin, staff |
| POST | `/barang/{id}/verify` | admin, staff |

Upload foto: `multipart/form-data` field `foto`

---

## Kategori

| GET | `/kategori` |
| POST | `/kategori` | admin, staff |
| PUT | `/kategori/{id}` | admin, staff |
| DELETE | `/kategori/{id}` | admin, staff |

---

## Aktivitas & Notifikasi

| GET | `/aktivitas` |
| GET | `/notifikasi` |
| PATCH | `/notifikasi/{id}/read` |

---

## Laporan

| GET | `/laporan?tanggal_mulai=&tanggal_akhir=&ruangan=&kondisi=` |
| GET | `/laporan/export/pdf` |
| GET | `/laporan/export/excel` |

---

## Kondisi Barang

- Sangat Baik
- Baik
- Rusak

**Rule:** Barang > 5 tahun + kondisi Baik/Rusak → `status_perawatan: Perlu Perawatan`

---

## Akun Demo (Seeder)

| Username | Password | Role |
|----------|----------|------|
| admin | password123 | admin |
| staff | password123 | staff |
| pimpinan | password123 | pimpinan |
