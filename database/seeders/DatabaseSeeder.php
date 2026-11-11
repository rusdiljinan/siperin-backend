<?php

namespace Database\Seeders;

use App\Enums\KondisiBarang;
use App\Enums\UserRole;
use App\Models\Barang;
use App\Models\HistoryAktivitas;
use App\Models\Kategori;
use App\Models\User;
use App\Services\BarangClassificationService;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    public function run(): void
    {
        $admin = User::create([
            'name' => 'Administrator SIPERIN',
            'username' => 'admin',
            'email' => 'admin@siperin.go.id',
            'password' => Hash::make('password123'),
            'role' => UserRole::Admin,
            'phone' => '081234567890',
            'is_active' => true,
        ]);

        $user = User::create([
            'name' => 'User Inventaris',
            'username' => 'user',
            'email' => 'user@siperin.go.id',
            'password' => Hash::make('password123'),
            'role' => UserRole::User,
            'is_active' => true,
        ]);

        $kategoris = [
            ['nama_kategori' => 'Elektronik', 'deskripsi' => 'Perangkat elektronik kantor'],
            ['nama_kategori' => 'Furniture', 'deskripsi' => 'Meja, kursi, lemari'],
            ['nama_kategori' => 'Kendaraan', 'deskripsi' => 'Kendaraan dinas'],
            ['nama_kategori' => 'Alat Tulis', 'deskripsi' => 'ATK dan perlengkapan'],
            ['nama_kategori' => 'Lainnya', 'deskripsi' => 'Kategori lainnya'],
        ];

        foreach ($kategoris as $k) {
            Kategori::create($k);
        }

        $classification = app(BarangClassificationService::class);

        $items = [
            [
                'kategori_id' => 1,
                'nama_barang' => 'Laptop Asus Vivobook',
                'merek' => 'Asus',
                'nomor_seri' => 'SN-88291',
                'ukuran' => '14 inch',
                'bahan' => 'Aluminium',
                'tahun_pembelian' => 2023,
                'kode_barang' => 'INV-2024-001',
                'jumlah_barang' => 5,
                'harga_beli' => 8500000,
                'kondisi_barang' => KondisiBarang::Baik->value,
                'lokasi_ruangan' => 'Ruang IT',
                'keterangan' => 'Untuk administrasi',
                'status' => 'Aktif',
                'created_by' => $admin->id,
            ],
            [
                'kategori_id' => 2,
                'nama_barang' => 'Kursi Pelatihan',
                'merek' => 'Chitose',
                'tahun_pembelian' => 2018,
                'kode_barang' => 'INV-2024-002',
                'jumlah_barang' => 20,
                'harga_beli' => 450000,
                'kondisi_barang' => KondisiBarang::Baik->value,
                'lokasi_ruangan' => 'Ruang Rapat',
                'status' => 'Aktif',
                'created_by' => $user->id,
            ],
            [
                'kategori_id' => 1,
                'nama_barang' => 'Proyektor Epson',
                'merek' => 'Epson',
                'tahun_pembelian' => 2019,
                'kode_barang' => 'INV-2024-003',
                'jumlah_barang' => 2,
                'harga_beli' => 5200000,
                'kondisi_barang' => KondisiBarang::Rusak->value,
                'lokasi_ruangan' => 'Ruang Rapat',
                'status' => 'Nonaktif',
                'created_by' => $admin->id,
            ],
            [
                'kategori_id' => 2,
                'nama_barang' => 'Meja Kerja',
                'tahun_pembelian' => 2022,
                'kode_barang' => 'INV-2024-004',
                'jumlah_barang' => 10,
                'harga_beli' => 1200000,
                'kondisi_barang' => KondisiBarang::SangatBaik->value,
                'lokasi_ruangan' => 'Ruang Sekretariat',
                'status' => 'Aktif',
                'created_by' => $user->id,
            ],
            [
                'kategori_id' => 1,
                'nama_barang' => 'Printer Canon',
                'merek' => 'Canon',
                'tahun_pembelian' => 2024,
                'kode_barang' => 'INV-2024-005',
                'jumlah_barang' => 2,
                'harga_beli' => 2800000,
                'kondisi_barang' => KondisiBarang::Baik->value,
                'lokasi_ruangan' => 'Ruang Arsip',
                'status' => 'Aktif',
                'created_by' => $user->id,
            ],
        ];

        foreach ($items as $item) {
            $barang = Barang::create($item);
            $classification->apply($barang)->save();
        }

        HistoryAktivitas::create([
            'user_id' => $admin->id,
            'aktivitas' => 'tambah',
            'target_type' => 'barang',
            'target_id' => 1,
            'deskripsi' => 'Barang Laptop Asus ditambahkan oleh Admin',
        ]);

        HistoryAktivitas::create([
            'user_id' => $user->id,
            'aktivitas' => 'edit',
            'target_type' => 'barang',
            'target_id' => 2,
            'deskripsi' => 'Kursi Pelatihan diperbaharui oleh User',
        ]);

        HistoryAktivitas::create([
            'user_id' => $admin->id,
            'aktivitas' => 'login',
            'deskripsi' => 'User Administrator SIPERIN berhasil login',
        ]);

        $this->command->info('SIPERIN seeder selesai!');
        $this->command->info('Login: admin / user — password: password123');
    }
}
