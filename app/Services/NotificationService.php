<?php

namespace App\Services;

use App\Models\Barang;
use App\Models\Notifikasi;
use App\Models\User;

class NotificationService
{
    public function notifyBarangRusak(Barang $barang): void
    {
        $this->broadcast(
            tipe: 'barang_rusak',
            judul: 'Barang Rusak Terdeteksi',
            pesan: "Barang {$barang->nama_barang} ({$barang->kode_barang}) dalam kondisi rusak.",
            barangId: $barang->id,
        );
    }

    public function notifyStokMenipis(Barang $barang, int $threshold = 3): void
    {
        if ($barang->jumlah_barang > $threshold) {
            return;
        }

        $this->broadcast(
            tipe: 'stok_menipis',
            judul: 'Stok Barang Menipis',
            pesan: "Stok {$barang->nama_barang} tersisa {$barang->jumlah_barang} unit.",
            barangId: $barang->id,
        );
    }

    protected function broadcast(string $tipe, string $judul, string $pesan, ?int $barangId = null): void
    {
        $admins = User::whereIn('role', ['admin', 'user'])->where('is_active', true)->get();

        foreach ($admins as $user) {
            Notifikasi::create([
                'user_id' => $user->id,
                'barang_id' => $barangId,
                'tipe' => $tipe,
                'judul' => $judul,
                'pesan' => $pesan,
            ]);
        }
    }
}
