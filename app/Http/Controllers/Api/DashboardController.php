<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Barang;
use App\Models\Kategori;
use App\Traits\ApiResponse;
use Carbon\Carbon;
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

        $chartYear = now()->year;
        $monthLabels = [
            'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
            'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
        ];
        $yearStart = Carbon::create($chartYear, 1, 1)->startOfDay();
        $yearEnd = Carbon::create($chartYear, 12, 31)->endOfDay();
        $monthlyQuery = Barang::query()->whereBetween('created_at', [$yearStart, $yearEnd]);
        $conditionKeys = [
            'Sangat Baik' => 'sangat_baik',
            'Baik' => 'baik',
            'Rusak' => 'rusak',
        ];

        for ($month = 1; $month <= 12; $month++) {
            $monthStart = Carbon::create($chartYear, $month, 1)->startOfDay();
            $nextMonth = $monthStart->copy()->addMonth();
            foreach ($conditionKeys as $condition => $key) {
                $alias = "month_{$month}_{$key}";
                $monthlyQuery->selectRaw(
                    "COALESCE(SUM(CASE WHEN created_at >= ? AND created_at < ? AND kondisi_barang = ? THEN jumlah_barang ELSE 0 END), 0) as {$alias}",
                    [$monthStart, $nextMonth, $condition]
                );
            }
        }
        $monthlyTotals = $monthlyQuery->first();

        $chart = [];
        for ($month = 1; $month <= 12; $month++) {
            $chart[] = [
                'label' => $monthLabels[$month - 1],
                'sangat_baik' => (int) $monthlyTotals->{"month_{$month}_sangat_baik"},
                'baik' => (int) $monthlyTotals->{"month_{$month}_baik"},
                'rusak' => (int) $monthlyTotals->{"month_{$month}_rusak"},
            ];
        }

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
            'chart_year' => $chartYear,
            'chart' => $chart,
            'statistik_kondisi' => $kondisiStats,
        ], 'Data dashboard berhasil diambil');
    }
}
