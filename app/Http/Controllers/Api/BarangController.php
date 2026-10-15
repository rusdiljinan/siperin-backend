<?php

namespace App\Http\Controllers\Api;

use App\Exports\BarangExport;
use App\Http\Controllers\Controller;
use App\Http\Requests\Barang\StoreBarangRequest;
use App\Http\Requests\Barang\UpdateBarangRequest;
use App\Http\Resources\AktivitasResource;
use App\Http\Resources\BarangResource;
use App\Models\Barang;
use App\Models\Laporan;
use App\Repositories\BarangRepository;
use App\Services\ActivityLogService;
use App\Services\BarangClassificationService;
use App\Services\NotificationService;
use App\Services\QrCodeService;
use App\Traits\ApiResponse;
use Barryvdh\DomPDF\Facade\Pdf;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Auth;
use Maatwebsite\Excel\Facades\Excel;

class BarangController extends Controller
{
    use ApiResponse;

    public function __construct(
        protected BarangRepository $barangRepo,
        protected BarangClassificationService $classification,
        protected ActivityLogService $activityLog,
        protected NotificationService $notification,
        protected QrCodeService $qrCode,
    ) {}

    public function index(Request $request): JsonResponse
    {
        $paginated = $this->barangRepo->paginate($request->all(), (int) $request->get('per_page', 10));

        return $this->listSuccess(
            BarangResource::collection($paginated->items()),
            [
                'current_page' => $paginated->currentPage(),
                'last_page' => $paginated->lastPage(),
                'per_page' => $paginated->perPage(),
                'total' => $paginated->total(),
            ],
            'Data barang berhasil diambil'
        );
    }

    public function store(StoreBarangRequest $request): JsonResponse
    {
        try {
            $data = $request->validated();
            // keep score fields if present; remove form-only keys
            unset($data['foto'], $data['nama'], $data['kode'], $data['jumlah'], $data['kondisi'], $data['ruangan'], $data['kategori']);

            // If RBS scores are provided, evaluate and attach result
            $scoreKeys = [
                'kelengkapan_score',
                'fungsional_score',
                'fisik_score',
                'usia_score',
                'perawatan_score',
                'keamanan_score',
            ];

            $hasScores = false;
            foreach ($scoreKeys as $k) {
                if ($request->filled($k)) {
                    $hasScores = true;
                    break;
                }
            }

            if ($hasScores) {
                $scores = [];
                foreach ($scoreKeys as $k) {
                    $scores[$k] = (int) $request->input($k, 0);
                }
                $rbs = new \App\Services\InventoryRuleBasedService();
                $result = $rbs->evaluate($scores);

                // attach scores and total to data
                foreach ($scores as $k => $v) {
                    $data[$k] = $v;
                }
                $data['total_score'] = $result['total_score'];
                $data['kondisi_barang'] = $result['condition'];
            }

            $data['created_by'] = Auth::id();
            $data['updated_by'] = Auth::id();
            $data['status'] = $data['status'] ?? 'Aktif';

            if ($request->hasFile('foto')) {
                $foto = $request->file('foto');
                $data['foto_blob'] = $foto->get();
                $data['foto_mime'] = $foto->getMimeType();
            }

            $barang = $this->barangRepo->create($data);
            $this->classification->apply($barang)->save();
            $this->qrCode->generateForBarang($barang);

            if ($barang->kondisi_barang === 'Rusak') {
                $this->notification->notifyBarangRusak($barang);
            }
            $this->notification->notifyStokMenipis($barang);

            $user = Auth::user();
            $this->activityLog->log(
                $user,
                'tambah',
                "Inventaris {$barang->nama_barang} ditambahkan oleh {$user->name}",
                $barang
            );
            if ($request->hasFile('foto')) {
                $this->activityLog->log(
                    $user,
                    'upload',
                    "Foto inventaris {$barang->nama_barang} diunggah oleh {$user->name}",
                    $barang
                );
            }

            return $this->success(new BarangResource($barang->load('kategori')), 'Barang berhasil disimpan', 201);
        } catch (\Throwable $e) {
            Log::error('Gagal menyimpan inventaris baru.', ['exception' => $e]);

            return $this->error('Gagal menyimpan barang ke database. Silakan coba kembali.', 500);
        }
    }

    public function show(int $id): JsonResponse
    {
        $barang = $this->barangRepo->find($id);

        if (! $barang) {
            return $this->error('Barang tidak ditemukan', 404);
        }

        return $this->success(new BarangResource($barang), 'Detail barang berhasil diambil');
    }

    public function foto(int $id)
    {
        $barang = Barang::query()
            ->select(['id', 'foto_blob', 'foto_mime', 'foto_barang'])
            ->find($id);

        if (! $barang) {
            return $this->error('Barang tidak ditemukan', 404);
        }

        if ($barang->foto_blob !== null && $barang->foto_blob !== '') {
            return response($barang->foto_blob, 200, [
                'Content-Type' => $barang->foto_mime ?: 'application/octet-stream',
                'Cache-Control' => 'private, max-age=3600',
                'X-Content-Type-Options' => 'nosniff',
            ]);
        }

        if ($barang->foto_barang && Storage::disk('public')->exists($barang->foto_barang)) {
            $contents = Storage::disk('public')->get($barang->foto_barang);
            $mime = (new \finfo(FILEINFO_MIME_TYPE))->buffer($contents);

            if (is_string($mime) && str_starts_with($mime, 'image/')) {
                return response($contents, 200, [
                    'Content-Type' => $mime,
                    'Cache-Control' => 'private, max-age=3600',
                    'X-Content-Type-Options' => 'nosniff',
                ]);
            }
        }

        return $this->error('Foto barang tidak tersedia', 404);
    }

    public function update(UpdateBarangRequest $request, int $id): JsonResponse
    {
        $barang = $this->barangRepo->find($id);

        if (! $barang) {
            return $this->error('Barang tidak ditemukan', 404);
        }

        try {
            $kondisiLama = $barang->kondisi_barang;
            $data = $request->validated();
            unset(
                $data['foto'],
                $data['remove_foto'],
                $data['nama'],
                $data['kode'],
                $data['jumlah'],
                $data['kondisi'],
                $data['ruangan'],
                $data['kategori']
            );

            // If RBS scores are provided on update, evaluate and attach
            $scoreKeys = [
                'kelengkapan_score',
                'fungsional_score',
                'fisik_score',
                'usia_score',
                'perawatan_score',
                'keamanan_score',
            ];

            $hasScores = false;
            foreach ($scoreKeys as $k) {
                if ($request->filled($k)) {
                    $hasScores = true;
                    break;
                }
            }

            if ($hasScores) {
                $scores = [];
                foreach ($scoreKeys as $k) {
                    $scores[$k] = (int) $request->input($k, 0);
                }
                $rbs = new \App\Services\InventoryRuleBasedService();
                $result = $rbs->evaluate($scores);

                foreach ($scores as $k => $v) {
                    $data[$k] = $v;
                }
                $data['total_score'] = $result['total_score'];
                $data['kondisi_barang'] = $result['condition'];
            }

            $data['updated_by'] = Auth::id();

            $oldFotoPath = $barang->foto_barang;

            if ($request->boolean('remove_foto')) {
                $data['foto_barang'] = null;
                $data['foto_blob'] = null;
                $data['foto_mime'] = null;
            } elseif ($request->hasFile('foto')) {
                $foto = $request->file('foto');
                $data['foto_barang'] = null;
                $data['foto_blob'] = $foto->get();
                $data['foto_mime'] = $foto->getMimeType();
            }

            $barang = $this->barangRepo->update($barang, $data);

            if (($request->hasFile('foto') || $request->boolean('remove_foto')) && $oldFotoPath) {
                Storage::disk('public')->delete($oldFotoPath);
            }
            $this->classification->apply($barang)->save();

            if ($barang->kondisi_barang === 'Rusak') {
                $this->notification->notifyBarangRusak($barang);
            }
            $this->notification->notifyStokMenipis($barang);

            $user = Auth::user();
            $this->activityLog->log(
                $user,
                'edit',
                "Inventaris {$barang->nama_barang} diperbarui oleh {$user->name}",
                $barang
            );
            if ($request->hasFile('foto')) {
                $this->activityLog->log(
                    $user,
                    'upload',
                    "Foto inventaris {$barang->nama_barang} diperbarui oleh {$user->name}",
                    $barang
                );
            }
            if ($kondisiLama !== $barang->kondisi_barang) {
                $this->activityLog->log(
                    $user,
                    'ubah_kondisi',
                    "Kondisi {$barang->nama_barang} diubah dari {$kondisiLama} menjadi {$barang->kondisi_barang}",
                    $barang
                );
            }

            return $this->success(new BarangResource($barang), 'Barang berhasil diperbarui');
        } catch (\Throwable $e) {
            Log::error('Gagal memperbarui inventaris.', [
                'barang_id' => $id,
                'exception' => $e,
            ]);

            return $this->error('Gagal memperbarui barang di database. Silakan coba kembali.', 500);
        }
    }

    public function destroy(int $id): JsonResponse
    {
        $barang = $this->barangRepo->find($id);

        if (! $barang) {
            return $this->error('Barang tidak ditemukan', 404);
        }

        $user = Auth::user();
        $nama = $barang->nama_barang;

        if ($barang->foto_barang) {
            Storage::disk('public')->delete($barang->foto_barang);
        }
        if ($barang->qr_code_path) {
            Storage::disk('public')->delete($barang->qr_code_path);
        }

        $this->barangRepo->delete($barang);

        $this->activityLog->log($user, 'hapus', "Inventaris {$nama} dihapus permanen oleh {$user->name}");

        return $this->success(null, 'Barang berhasil dihapus dari database');
    }

    public function history(int $id): JsonResponse
    {
        $barang = Barang::find($id);

        if (! $barang) {
            return $this->error('Barang tidak ditemukan', 404);
        }

        $history = $barang->history()->with('user')->get();

        return $this->success(AktivitasResource::collection($history), 'Riwayat barang berhasil diambil');
    }

    public function verify(int $id): JsonResponse
    {
        $barang = $this->barangRepo->find($id);

        if (! $barang) {
            return $this->error('Barang tidak ditemukan', 404);
        }

        $user = Auth::user();
        $this->activityLog->log(
            $user,
            'verifikasi',
            "Verifikasi perbaikan inventaris {$barang->nama_barang} oleh {$user->name}",
            $barang
        );

        return $this->success(new BarangResource($barang), 'Barang berhasil diverifikasi');
    }

    public function export(string $format, Request $request): mixed
    {
        $filters = $request->all();
        $barang = $this->barangRepo->query($filters)->get();
        $user = $request->user();
        $judul = 'Inventaris SIPERIN - '.now()->format('d M Y');

        if ($format === 'pdf') {
            $pdf = Pdf::loadView('exports.laporan-pdf', [
                'barang' => $barang,
                'judul' => $judul,
                'filters' => $filters,
            ]);

            $path = 'laporan/inventaris-'.time().'.pdf';
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

            $this->activityLog->log($user, 'export_pdf', "Export PDF inventaris ({$barang->count()} item) oleh {$user->name}");

            return $pdf->download('inventaris-siperin.pdf');
        }

        if ($format === 'excel') {
            $filename = 'inventaris-siperin-'.time().'.xlsx';

            Laporan::create([
                'user_id' => $user->id,
                'judul' => $judul,
                'periode_mulai' => $request->tanggal_mulai,
                'periode_akhir' => $request->tanggal_akhir,
                'filter_json' => $filters,
                'file_path' => 'laporan/'.$filename,
                'tipe' => 'excel',
            ]);

            $this->activityLog->log($user, 'export_excel', "Export Excel inventaris ({$barang->count()} item) oleh {$user->name}");

            return Excel::download(new BarangExport($barang), $filename);
        }

        return $this->error('Format export tidak didukung', 422);
    }

    public function qrCode(int $id): JsonResponse
    {
        $barang = $this->barangRepo->find($id);

        if (! $barang) {
            return $this->error('Barang tidak ditemukan', 404);
        }

        $svg = $this->qrCode->getSvgContent($barang);

        return $this->success([
            'kode_barang' => $barang->kode_barang,
            'qr_url' => $barang->qr_code_path ? asset('storage/'.$barang->qr_code_path) : null,
            'qr_svg' => $svg,
        ], 'QR Code berhasil dibuat');
    }
}
