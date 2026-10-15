<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Barang;
use App\Models\Kategori;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\DB;

class DashboardController extends Controller
{
    use ApiResponse;

    public function index(): JsonResponse
    {
        $totalBarang = Barang::count();
        $barangBaik = Barang::whereIn('kondisi_barang', ['Sangat Baik', 'Baik'])->count();
        $barangRusak = Barang::where('kondisi_barang', 'Rusak')->count();
        $barangPerbaikan = Barang::where('status_perawatan', 'Perlu Perawatan')->count();

        $chart = Barang::select(
            DB::raw('MONTH(created_at) as bulan'),
            DB::raw('COUNT(*) as total')
        )
            ->where('created_at', '>=', now()->subMonths(6))
            ->groupBy('bulan')
            ->orderBy('bulan')
            ->get()
            ->map(fn ($row) => [
                'label' => date('M', mktime(0, 0, 0, (int) $row->bulan, 1)),
                'value' => (int) $row->total,
            ]);

        $kondisiStats = Barang::select('kondisi_barang', DB::raw('COUNT(*) as total'))
            ->groupBy('kondisi_barang')
            ->get();

        return $this->success([
            'total_barang' => $totalBarang,
            'total' => $totalBarang,
            'total_kategori' => Kategori::count(),
            'barang_baik' => $barangBaik,
            'barang_rusak' => $barangRusak,
            'barang_perbaikan' => $barangPerbaikan,
            'chart' => $chart,
            'statistik_kondisi' => $kondisiStats,
        ], 'Data dashboard berhasil diambil');
    }
}
