# Rincian Aplikasi SIPERIN

## 1. Gambaran Umum

**SIPERIN (Sistem Pengelolaan Inventaris)** adalah aplikasi untuk mencatat,
mengelola, dan memantau barang inventaris instansi. Aplikasi terdiri dari
frontend Flutter dan backend Laravel yang menyediakan REST API. Identitas
aplikasi pada konfigurasi menyebut **Inventaris Instansi** dan **UPT Bapelkes
Riau**.

Sistem ini membantu pengguna mengelola informasi barang, seperti kode
inventaris, kategori, jumlah, harga, lokasi, kondisi, foto, dan riwayat
perubahan. Informasi tersebut dapat ditampilkan dalam dashboard dan laporan
yang dapat diekspor.

## 2. Tujuan Aplikasi

Tujuan utama aplikasi adalah:

- Memusatkan pencatatan barang inventaris instansi.
- Memudahkan pencarian dan pemantauan barang berdasarkan kategori, lokasi,
  kondisi, atau kode.
- Mendokumentasikan perubahan dan aktivitas pengguna.
- Membantu mengidentifikasi barang yang rusak atau membutuhkan perawatan.
- Menyajikan ringkasan inventaris dan menyediakan ekspor laporan.
- Membatasi tindakan pengguna sesuai peran dan hak akses.

## 3. Pengguna dan Hak Akses

Aplikasi mengenal dua peran:

| Peran | Fungsi dan akses utama |
|---|---|
| **Admin** | Mengelola akun pengguna dan mengelola inventaris serta kategori. |
| **User** | Mengakses dashboard, laporan, dan inventaris; dapat mengelola barang dan kategori serta melakukan verifikasi. |

Halaman pengelolaan pengguna dibatasi untuk admin pada frontend, sedangkan
backend juga menerapkan middleware peran untuk melindungi endpoint. Hak akses
backend yang aktif didefinisikan di `backend/routes/api.php`.

## 4. Fitur Utama

### 4.1 Autentikasi dan sesi

- Login menggunakan username dan password.
- Token autentikasi digunakan untuk permintaan API yang memerlukan login.
- Sesi dan informasi pengguna disimpan secara lokal agar status login dapat
  diperiksa kembali ketika aplikasi dibuka.
- Pengguna dapat logout.
- Backend juga menyediakan endpoint registrasi dan pemulihan/reset password.

Implementasi frontend memakai token Laravel Sanctum. Karena itu, penyebutan
JWT pada dokumentasi lama perlu disesuaikan dengan implementasi aktual.

### 4.2 Responsivitas tampilan

Frontend Flutter menggunakan breakpoint terpusat di
`lib/utils/responsive.dart`:

- Mobile: hingga 599 px, dengan skala teks lebih ringkas untuk layar sempit.
- Tablet: 600-1023 px, dengan jarak dan skala teks menengah.
- Desktop: mulai 1024 px, dengan ruang konten dan tipografi penuh.

Skala teks diterapkan melalui `MediaQuery` di root aplikasi sehingga judul,
form, tabel, dialog, notifikasi, kartu dashboard, dan navigasi mengikuti
ukuran layar tanpa mengubah logika bisnis. Daftar inventaris dan laporan tetap
menggunakan gulir horizontal pada komponen tabel ketika kolom membutuhkan
ruang tambahan, sedangkan tampilan inventaris mobile menggunakan kartu.

### 4.3 Dashboard

Dashboard menampilkan ringkasan inventaris:

- Total barang.
- Jumlah barang berkondisi baik.
- Jumlah barang rusak.
- Jumlah barang yang ditandai perlu perawatan.
- Grafik jumlah barang yang dicatat pada periode terbaru.

Dashboard mengambil datanya dari backend; halaman menampilkan status memuat,
pesan kesalahan, dan opsi untuk mencoba kembali jika permintaan gagal.

### 4.4 Daftar dan pencarian inventaris

Halaman inventaris menyediakan:

- Pencarian barang berdasarkan nama, kode, atau ruangan.
- Filter kategori dan kondisi.
- Pengurutan berdasarkan nama, kode, tahun pembelian, atau kondisi.
- Tampilan daftar yang menyesuaikan ukuran layar.
- Pembagian data ke dalam halaman.
- Pemeliharaan posisi gulir saat kembali dari halaman detail.

Pengguna dapat membuka formulir tambah barang atau memilih barang untuk melihat
detailnya.

### 4.5 Tambah dan ubah barang

Data barang yang dapat dicatat meliputi:

- Nama dan kode barang.
- Kategori, merek, nomor seri, ukuran, dan bahan.
- Tahun pembelian, jumlah unit, dan harga beli.
- Kondisi barang, ruangan, dan keterangan.
- Foto barang.

Formulir melakukan validasi sebelum mengirim data. Foto dapat dipilih dan
diunggah ke backend. Pada perubahan data, foto lama juga dapat dipertahankan
atau dihapus.

### 4.6 Detail barang, foto, QR code, dan riwayat

Halaman detail menyajikan data utama barang, kondisi, foto, kode, dan riwayat
perubahan. Antarmuka membuat QR code dari kode inventaris dengan isi
`BARANG:<kode>`. Backend juga memiliki endpoint untuk mengambil QR code.

Pengguna yang memiliki izin dapat mengubah atau menghapus data dari halaman
detail.

### 4.7 Penilaian kondisi dan perbaikan

Penilaian kondisi menggunakan enam aspek:

1. Kelengkapan.
2. Fungsional.
3. Fisik.
4. Usia.
5. Perawatan.
6. Keamanan.

Skor aspek dijumlahkan untuk menentukan kondisi:

| Total skor | Kondisi |
|---:|---|
| 15 atau lebih | Sangat Baik |
| 10 sampai 14 | Baik |
| Di bawah 10 | Rusak |

Aturan backend juga menandai barang yang berusia **lebih dari lima tahun**
dengan kondisi Baik atau Rusak sebagai **Perlu Perawatan**. Menu Perbaikan
menampilkan barang dengan kondisi Rusak dan menyediakan pencarian serta filter
ruangan.

### 4.8 Laporan inventaris

Laporan dapat dibuat untuk:

- Semua data.
- Periode mingguan.
- Periode bulanan.
- Rentang tanggal khusus.

Ringkasan laporan mencakup jumlah entri, total kuantitas unit, nilai
inventaris, dan rekap berdasarkan kondisi. Laporan dapat diekspor ke PDF atau
Excel. Untuk periode tertentu, backend menggunakan tanggal pencatatan barang
(`created_at`), bukan tahun pembelian.

### 4.9 Riwayat aktivitas dan notifikasi

Frontend menampilkan riwayat aktivitas dalam bentuk timeline. Backend
menyediakan endpoint untuk membaca aktivitas serta mencatat aktivitas tertentu,
seperti pencetakan laporan. Backend juga menyediakan endpoint untuk membaca
notifikasi dan menandainya sebagai telah dibaca.

### 4.10 Pengelolaan pengguna

Admin dapat melihat daftar pengguna, melakukan pencarian dan filter peran,
menambah akun, mengubah data/peran, mengubah status aktif, serta menghapus
akun. Backend juga menyediakan mekanisme pengiriman ulang undangan akun.

### 4.11 Profil dan tema

Halaman profil menampilkan informasi akun dan peran, menyediakan pilihan mode
terang/gelap, serta tombol logout. Preferensi tema disimpan secara lokal.

## 5. Alur Kerja Umum

1. Pengguna membuka aplikasi dan masuk menggunakan akun yang terdaftar.
2. Frontend memeriksa sesi dan mengambil data pengguna dari backend.
3. Setelah berhasil masuk, pengguna diarahkan ke dashboard.
4. Pengguna membuka daftar inventaris untuk mencari, memfilter, atau memilih
   barang.
5. Pengguna yang memiliki izin dapat menambah atau mengubah barang, termasuk
   mengisi data dan mengunggah foto.
6. Backend memvalidasi serta menyimpan data, memperbarui klasifikasi kondisi,
   membuat QR code, dan mencatat aktivitas yang terkait.
7. Pengguna melihat kondisi dan riwayat melalui halaman detail, atau
   menggunakan menu Perbaikan untuk meninjau barang rusak.
8. Pengguna membuka laporan, menentukan periode, melihat ringkasan, lalu
   mengunduh PDF atau Excel.
9. Pengguna mengakhiri sesi dengan logout.

## 6. Arsitektur dan Teknologi

### Frontend

- **Flutter / Dart** untuk aplikasi lintas platform.
- **Provider** untuk state management.
- **Dio** untuk komunikasi HTTP dengan REST API.
- **GoRouter** untuk navigasi dan perlindungan rute berbasis status login/peran.
- **fl_chart** untuk grafik.
- **image_picker** untuk pemilihan foto.
- **qr_flutter** untuk menampilkan QR code.
- **file_saver** untuk menyimpan hasil ekspor.
- **Shared Preferences** untuk penyimpanan sesi/pengaturan lokal.

Platform yang dituju mencakup Android, iOS, web, serta target desktop Flutter
yang didukung proyek.

### Backend

- **PHP 8.2 atau lebih baru**.
- **Laravel 12** sebagai REST API.
- **Laravel Sanctum** untuk token API.
- **MySQL** sebagai database pada konfigurasi proyek yang didokumentasikan.
- **Dompdf** untuk keluaran PDF.
- **Laravel Excel / Maatwebsite Excel** untuk keluaran Excel.
- **QR code service** untuk pembuatan QR code barang.

### Pembagian lapisan frontend

| Direktori | Tanggung jawab |
|---|---|
| `lib/pages/` | Halaman login, dashboard, inventaris, laporan, aktivitas, perbaikan, profil, dan pengguna. |
| `lib/widgets/` | Komponen UI yang dapat digunakan kembali, seperti sidebar, kartu statistik, grafik, badge kondisi, dan tampilan foto. |
| `lib/providers/` | State serta aksi untuk autentikasi, inventaris, dashboard, aktivitas, perbaikan, dan tema. |
| `lib/services/` | Komunikasi dengan endpoint API dan pemrosesan respons. |
| `lib/models/` | Model data yang digunakan frontend. |
| `lib/core/` | Konfigurasi API, tema, konstanta, dan router. |
| `lib/utils/` | Utilitas validasi, format, respons API, gambar, dan responsivitas. |

### Pembagian lapisan backend

Backend mengelompokkan route API, controller, request validation, resource,
model, repository, service, dan export. Controller menangani permintaan,
validasi memeriksa masukan, model/repository mengakses data, dan service
menangani logika seperti klasifikasi kondisi, pencatatan aktivitas, notifikasi,
serta QR code.

## 7. Ringkasan Data dan Relasi

Entitas utama database meliputi:

| Entitas | Kegunaan |
|---|---|
| `users` | Akun, kredensial, peran, dan status pengguna. |
| `kategori` | Data kategori inventaris. |
| `barang` | Informasi barang, nilai, lokasi, kondisi, skor, dan referensi foto. |
| `history_aktivitas` | Catatan aktivitas pengguna dan target aktivitas. |
| `laporan` | Metadata laporan yang terkait dengan pengguna. |
| `notifikasi` | Notifikasi pengguna dan/atau barang. |

Relasi penting:

- Satu kategori dapat memiliki banyak barang.
- Barang dapat menyimpan referensi pengguna pembuat dan pengguna pengubah.
- Aktivitas dan laporan dikaitkan dengan pengguna.
- Notifikasi dapat dikaitkan dengan pengguna dan barang.
- Riwayat barang menggunakan `target_type` dan `target_id`; pasangan ini
  merupakan referensi logis aplikasi, bukan foreign key langsung ke tabel
  barang.
- Tabel barang menggunakan soft delete, sehingga penghapusan normal menandai
  data terhapus tanpa langsung menghapus record fisiknya.

Rincian kolom dan relasi tersedia di
[`DOKUMENTASI_DATABASE_SIPERIN.md`](./DOKUMENTASI_DATABASE_SIPERIN.md).

## 8. Endpoint API Utama

Semua endpoint berikut berada di bawah prefix `/api`. Endpoint selain yang
secara eksplisit bersifat publik memerlukan autentikasi.

| Kelompok | Endpoint utama | Fungsi |
|---|---|---|
| Pemeriksaan layanan | `GET /health` | Memeriksa status API dan koneksi database. |
| Autentikasi | `POST /login`, `POST /logout`, `GET /me` | Login, logout, dan identitas sesi. Backend juga menyediakan endpoint registrasi dan pemulihan/reset password. |
| Profil | `PUT /profile` | Memperbarui profil pengguna. |
| Pengguna | `/users` dan `/users/{id}` | Pengelolaan pengguna oleh admin. |
| Dashboard | `GET /dashboard` | Statistik inventaris. |
| Inventaris | `/barang` dan `/barang/{id}` | Daftar, detail, tambah, ubah, dan hapus barang. |
| Foto/riwayat/QR | `/barang/{id}/foto`, `/barang/{id}/history`, `/barang/{id}/qr` | Mengambil foto, riwayat, dan QR barang. |
| Kategori | `/kategori` dan `/kategori/{id}` | Membaca dan mengelola kategori. |
| Perbaikan | `GET /perbaikan` | Mengambil daftar barang berkondisi Rusak. |
| Aktivitas | `GET /aktivitas` | Membaca riwayat aktivitas. |
| Notifikasi | `/notifikasi` | Membaca notifikasi dan menandainya telah dibaca. |
| Laporan | `/laporan-inventaris` | Membaca ringkasan laporan berdasarkan periode. |
| Ekspor | `/laporan-inventaris/export/{format}` | Mengunduh laporan PDF atau Excel. |

Route lengkap dan middleware akses dapat diperiksa di
[`backend/routes/api.php`](./backend/routes/api.php).

## 9. Tampilan dan Pengalaman Pengguna

- Layout menyesuaikan layar ponsel, tablet, dan desktop.
- Navigasi menggunakan drawer atau sidebar sesuai ukuran layar.
- Daftar inventaris memakai kartu pada layar kecil dan dapat memakai tabel pada
  layar yang lebih lebar.
- Halaman menggunakan indikator memuat, kondisi data kosong, serta pesan error
  dan tindakan muat ulang pada sejumlah alur.
- Warna utama antarmuka menggunakan biru tua, putih, dan abu-abu muda.
- Tema terang dan gelap tersedia.

## 10. Konfigurasi dan Menjalankan Aplikasi

### Backend Laravel

1. Siapkan PHP, Composer, dan MySQL.
2. Buat database yang akan digunakan.
3. Siapkan konfigurasi `.env` lokal dan sesuaikan koneksi database.
4. Dari folder `backend`, pasang dependency dengan `composer install`.
5. Jalankan migration setelah memastikan konfigurasi database benar.
6. Jalankan `php artisan serve` untuk menyediakan API lokal.

### Frontend Flutter

1. Pastikan Flutter SDK tersedia.
2. Dari folder proyek, jalankan `flutter pub get`.
3. Sesuaikan alamat API di `lib/core/constants/api_constants.dart`.
4. Jalankan aplikasi pada perangkat atau target yang diinginkan, misalnya
   browser atau emulator.

Alamat API untuk web, emulator, simulator, dan perangkat fisik dapat berbeda.
Untuk deployment, gunakan alamat server yang benar dan HTTPS. Jangan
mengandalkan alamat IP lokal yang hanya berlaku di jaringan pengembangan.

## 11. Catatan Akurasi dan Batasan

- Dokumentasi lama `backend/API_DOCUMENTATION.md` mencantumkan beberapa nama
  endpoint laporan yang berbeda. Route yang saat ini terdaftar di
  `backend/routes/api.php` menggunakan `/laporan-inventaris` dan
  `/laporan-inventaris/export/{format}`.
- README menyebut JWT, sedangkan implementasi autentikasi frontend/backend
  menggunakan token Laravel Sanctum.
- Pilihan kategori dan ruangan pada beberapa form Flutter berasal dari daftar
  statis. Meskipun backend menyediakan endpoint kategori, form perlu
  dihubungkan secara dinamis apabila kategori harus dapat dikelola tanpa
  memperbarui aplikasi.
- Backend menyediakan endpoint notifikasi, tetapi keberadaan endpoint saja
  tidak berarti seluruh alur notifikasi telah tersedia sebagai halaman khusus
  di frontend.
- File dokumentasi perbaikan seperti `README_FIXES.md` berisi catatan perubahan
  dan klaim status. Klaim tersebut tidak dengan sendirinya membuktikan hasil
  pengujian pada semua perangkat atau kesiapan produksi.
- Akun demo yang disebut dokumentasi hanya berlaku bila seeder terkait telah
  dijalankan pada database lokal. Jangan memakai kredensial demo untuk
  deployment.

## 12. Kesimpulan

SIPERIN merupakan sistem inventaris dengan frontend Flutter dan backend Laravel.
Fungsi utamanya mencakup pencatatan barang, pencarian dan pemantauan kondisi,
penilaian berbasis skor, pemantauan barang rusak/perlu perawatan, pencatatan
aktivitas, pengelolaan akun berbasis peran, serta laporan PDF dan Excel.
Dokumen dan konfigurasi deployment sebaiknya tetap disesuaikan dengan route API,
alamat server, database, serta hak akses yang benar-benar digunakan pada
lingkungan operasional.
