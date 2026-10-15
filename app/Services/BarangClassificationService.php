<?php

namespace App\Services;

use App\Enums\KondisiBarang;
use App\Models\Barang;

/**
 * Rule-based classification: barang > 5 tahun + kondisi menurun → perlu perawatan.
 */
class BarangClassificationService
{
    public function evaluate(Barang $barang): ?string
    {
        $age = now()->year - (int) $barang->tahun_pembelian;

        if ($age <= 5) {
            return null;
        }

        $needsCare = in_array($barang->kondisi_barang, [
            KondisiBarang::Baik->value,
            KondisiBarang::Rusak->value,
        ], true);

        if ($needsCare) {
            return 'Perlu Perawatan';
        }

        return null;
    }

    public function apply(Barang $barang): Barang
    {
        $barang->status_perawatan = $this->evaluate($barang);

        return $barang;
    }
}
