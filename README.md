# SIPERIN — Sistem Pengelolaan Inventaris

Proyek hybrid inventaris barang instansi pemerintah:
- **Frontend:** Flutter (Android, iOS, Web) — folder root
- **Backend:** Laravel REST API — folder `backend/`

## Struktur Folder

```
lib/
├── core/           # theme, constants, router
├── models/         # data models
├── services/       # API, auth, storage (Dio + JWT)
├── providers/      # state management (Provider)
├── pages/          # halaman UI
├── widgets/        # komponen reusable
├── utils/          # helper (responsive, validator, format)
└── main.dart
```

## Fitur

- Login dengan validasi, loading, error message
- Dashboard statistik + grafik
- Data barang (search, filter, pagination, sort)
- Tambah / edit barang (form + image picker)
- Detail barang + QR code + riwayat
- History aktivitas (timeline)
- Laporan (filter + export PDF/Excel/print preview)
- Profile + dark mode + logout
- Responsive: desktop sidebar, mobile drawer, tablet drawer + bottom nav;
  sidebar labels remain visible in landscape orientation

## Menjalankan Backend (Laravel)

```bash
cd backend
composer install
php artisan migrate:fresh --seed
php artisan storage:link
php artisan serve
```

Buat database MySQL `siperin` di phpMyAdmin terlebih dahulu.

## Menjalankan Frontend (Flutter)

```bash
flutter pub get
flutter run -d chrome
flutter run
```

## Login (setelah backend aktif)

| Username | Password | Role |
|----------|----------|------|
| admin | password123 | Admin |
| user | password123 | User |

API base: `http://127.0.0.1:8000/api` — lihat `backend/API_DOCUMENTATION.md`

## Warna UI

- Biru tua `#0D47A1`
- Putih `#FFFFFF`
- Abu-abu muda `#F5F5F5`
