<?php

namespace App\Http\Controllers\Api;

use App\Exports\BarangExport;
use App\Http\Controllers\Controller;
use App\Http\Resources\BarangResource;
use App\Models\Laporan;
use App\Repositories\BarangRepository;
use App\Traits\ApiResponse;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Maatwebsite\Excel\Facades\Excel;

class LaporanController extends Controller
{
    use ApiResponse;

    public function __construct(protected BarangRepository $barangRepo) {}

    public function index(Request $request): JsonResponse
    {
        $filters = $request->only(['tanggal_mulai', 'tanggal_akhir', 'ruangan', 'kondisi', 'kategori']);
        if ($request->ruangan) {
            $filters['ruangan'] = $request->ruangan;
        }
        if ($request->kondisi) {
            $filters['kondisi'] = $request->kondisi;
        }

        $items = $this->barangRepo->query($filters)->get();

        return $this->success(BarangResource::collection($items), 'Data laporan berhasil diambil');
    }

    public function export(string $format, Request $request): mixed
    {
        $filters = $request->all();
        $barang = $this->barangRepo->query($filters)->get();

        $user = $request->user();
        $judul = 'Laporan Inventaris SIPERIN - '.now()->format('d M Y');

        if ($format === 'pdf') {
            $pdf = Pdf::loadView('exports.laporan-pdf', [
                'barang' => $barang,
                'judul' => $judul,
                'filters' => $filters,
            ]);

            $path = 'laporan/laporan-'.time().'.pdf';
            $pdf->save(storage_path('app/public/'.$path));

            Laporan::create([
                'user_id' => $user->id,
                'judul' => $judul,
                'periode_mulai' => $request->tanggal_mulai,
                'periode_akhir' => $request->tanggal_akhir,
                'filter_json' => $filters,
                'file_path' => $path,
                'tipe' => 'pdf',
            ]);

            return $pdf->download('laporan-inventaris.pdf');
        }

        if ($format === 'excel') {
            $filename = 'laporan-inventaris-'.time().'.xlsx';

            Laporan::create([
                'user_id' => $user->id,
                'judul' => $judul,
                'periode_mulai' => $request->tanggal_mulai,
                'periode_akhir' => $request->tanggal_akhir,
                'filter_json' => $filters,
                'file_path' => 'laporan/'.$filename,
                'tipe' => 'excel',
            ]);

            return Excel::download(new BarangExport($barang), $filename);
        }

        return $this->error('Format export tidak didukung', 422);
    }
}
