# SIPERIN Backend

**S**istem **P**engelolaan **In**ventaris — REST API Laravel 12 + MySQL.

## Instalasi

```bash
composer install
```

Salin `.env.example` menjadi `.env` jika file `.env` belum tersedia, lalu sesuaikan konfigurasi database dengan lingkungan yang digunakan.

```bash
php artisan key:generate
```

**Catatan:** Jangan menjalankan `php artisan key:generate` pada server yang sudah digunakan tanpa memahami dampaknya terhadap sesi dan data terenkripsi. Gunakan `APP_KEY` yang sesuai untuk lingkungan deployment.

### Database MySQL (XAMPP)

1. Buat atau pilih database `siperin` melalui phpMyAdmin.
2. Sesuaikan konfigurasi database pada `.env`:

```dotenv
DB_CONNECTION=mysql
DB_DATABASE=siperin
DB_USERNAME=root
DB_PASSWORD=
```

3. Jalankan migrasi hanya setelah memastikan database yang digunakan benar dan memiliki backup yang aman:

```bash
php artisan migrate
php artisan storage:link
php artisan serve
```

API lokal: `http://127.0.0.1:8000/api`

## Struktur

```text
app/
├── Enums/
├── Exports/
├── Http/
│   ├── Controllers/Api/
│   ├── Middleware/
│   ├── Requests/
│   └── Resources/
├── Models/
├── Repositories/
├── Services/
└── Traits/
```

## Dokumentasi API

Lihat [API_DOCUMENTATION.md](API_DOCUMENTATION.md).

## Integrasi Flutter

Sesuaikan `lib/core/constants/api_constants.dart` dengan alamat backend yang digunakan.

Untuk pengembangan lokal:

```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

Untuk deployment, gunakan URL HTTPS backend yang sebenarnya.

Login menggunakan **Laravel Sanctum** dengan Bearer token. Tidak ada mode demo di aplikasi.