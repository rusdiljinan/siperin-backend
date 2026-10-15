# SIPERIN Backend

**S**istem **P**engelolaan **In**ventaris — REST API Laravel 12 + MySQL.

## Instalasi

```bash
cd backend
composer install
cp .env.example .env   # jika belum ada
php artisan key:generate
```

### Database MySQL (XAMPP)

1. Buat database di phpMyAdmin: `siperin`
2. Pastikan `.env`:
```
DB_CONNECTION=mysql
DB_DATABASE=siperin
DB_USERNAME=root
DB_PASSWORD=
# Laravel Sanctum (token API mobile)
SANCTUM_STATEFUL_DOMAINS=localhost,127.0.0.1,127.0.0.1:8000
```

```bash
php artisan migrate:fresh --seed
php artisan storage:link
php artisan serve
```

API: http://127.0.0.1:8000/api

## Struktur

```
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

Lihat [API_DOCUMENTATION.md](API_DOCUMENTATION.md)

## Integrasi Flutter

Di project Flutter, set `lib/core/constants/api_constants.dart`:
```dart
static const String baseUrl = 'http://127.0.0.1:8000/api';
```

Login memakai **Laravel Sanctum** (Bearer token). Tidak ada mode demo di aplikasi.
