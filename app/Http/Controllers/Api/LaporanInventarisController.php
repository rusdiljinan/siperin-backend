<?php

namespace App\Http\Controllers\Api;

use App\Exports\LaporanInventarisExport;
use App\Http\Controllers\Controller;
use App\Http\Requests\LaporanInventarisRequest;
use App\Models\Barang;
use App\Traits\ApiResponse;
use Barryvdh\DomPDF\Facade\Pdf;
use Carbon\CarbonImmutable;
use Illuminate\Http\JsonResponse;
use Maatwebsite\Excel\Facades\Excel;

class LaporanInventarisController extends Controller
{
    use ApiResponse;

    public function index(LaporanInventarisRequest $request): JsonResponse
    {
        $report = $this->buildReport($request);

        return $this->success($report, 'Laporan inventaris berhasil dibuat');
    }

    public function export(LaporanInventarisRequest $request, string $format)
    {
        if (! in_array($format, ['pdf', 'excel'], true)) {
            return $this->error('Format laporan tidak didukung', 422);
        }

        $report = $this->buildReport($request);
        $filename = $this->filename($report, $format);

        if ($format === 'excel') {
            return Excel::download(new LaporanInventarisExport($report), $filename);
        }

        $pdf = Pdf::loadView('exports.laporan-inventaris-pdf', ['report' => $report])
            ->setPaper('a4', 'landscape');
        $pdf->getDomPDF()->getCanvas()->page_text(
            760,
            570,
            'Halaman {PAGE_NUM} dari {PAGE_COUNT}',
            null,
            8,
            [0.35, 0.35, 0.35]
        );

        return $pdf->download($filename);
    }

    private function buildReport(LaporanInventarisRequest $request): array
    {
        $period = $request->validated('period');
        [$start, $end] = $period === 'all'
            ? [null, null]
            : $this->resolveRange($request);
        $query = Barang::query()
            ->select([
                'id',
                'kategori_id',
                'nama_barang',
                'merek',
                'nomor_seri',
                'ukuran',
                'bahan',
                'tahun_pembelian',
                'kode_barang',
                'jumlah_barang',
                'harga_beli',
                'kondisi_barang',
                'lokasi_ruangan',
                'keterangan',
                'status',
                'status_perawatan',
                'created_at',
            ])
            ->with('kategori')
            ->orderBy('created_at')
            ->orderBy('id');

        if ($period !== 'all') {
            $query->whereBetween('created_at', [$start->startOfDay(), $end->endOfDay()]);
        }

        $totals = (clone $query)
            ->reorder()
            ->select([])
            ->selectRaw(
                'COUNT(*) AS total_entries, COALESCE(SUM(jumlah_barang), 0) AS total_quantity, '.
                'COALESCE(SUM(harga_beli * jumlah_barang), 0) AS total_value'
            )
            ->first();

        $conditions = (clone $query)
            ->reorder()
            ->select([])
            ->selectRaw(
                'kondisi_barang, COUNT(*) AS entries, COALESCE(SUM(jumlah_barang), 0) AS quantity'
            )
            ->groupBy('kondisi_barang')
            ->get()
            ->mapWithKeys(fn ($row) => [
                $row->kondisi_barang => [
                    'entries' => (int) $row->entries,
                    'quantity' => (int) $row->quantity,
                ],
            ])
            ->all();

        $items = $query->get()->map(fn (Barang $barang) => [
            'id' => $barang->id,
            'nama_barang' => $barang->nama_barang,
            'merek' => $barang->merek,
            'nomor_seri' => $barang->nomor_seri,
            'ukuran' => $barang->ukuran,
            'bahan' => $barang->bahan,
            'tahun_pembelian' => (int) $barang->tahun_pembelian,
            'kode_barang' => $barang->kode_barang,
            'jumlah_barang' => (int) $barang->jumlah_barang,
            'harga_beli' => (float) $barang->harga_beli,
            'kondisi_barang' => $barang->kondisi_barang,
            'lokasi_ruangan' => $barang->lokasi_ruangan,
            'kategori' => $barang->kategori?->nama_kategori,
            'keterangan' => $barang->keterangan,
            'status' => $barang->status,
            'status_perawatan' => $barang->status_perawatan,
            'created_at' => $barang->created_at?->toIso8601String(),
        ])->values()->all();

        return [
            'period' => $period,
            'date_from' => $start?->toDateString(),
            'date_to' => $end?->toDateString(),
            'generated_at' => now()->toIso8601String(),
            'summary' => [
                'total_entries' => (int) $totals->total_entries,
                'total_quantity' => (int) $totals->total_quantity,
                'total_value' => round((float) $totals->total_value, 2),
                'conditions' => (object) $conditions,
            ],
            'items' => $items,
        ];
    }

    /** @return array{0: CarbonImmutable, 1: CarbonImmutable} */
    private function resolveRange(LaporanInventarisRequest $request): array
    {
        $filters = $request->validated();

        if ($filters['period'] === 'custom') {
            return [
                CarbonImmutable::parse($filters['start_date']),
                CarbonImmutable::parse($filters['end_date']),
            ];
        }

        $reference = CarbonImmutable::parse($filters['reference_date']);

        return $filters['period'] === 'weekly'
            ? [$reference->startOfWeek(), $reference->endOfWeek()]
            : [$reference->startOfMonth(), $reference->endOfMonth()];
    }

    private function filename(array $report, string $format): string
    {
        $suffix = match ($report['period']) {
            'all' => 'semua-data',
            'monthly' => CarbonImmutable::parse($report['date_from'])->format('Y-m'),
            default => $report['date_from'].'_'.$report['date_to'],
        };

        $extension = $format === 'excel' ? 'xlsx' : 'pdf';

        return "laporan_inventaris_{$suffix}.{$extension}";
    }
}
