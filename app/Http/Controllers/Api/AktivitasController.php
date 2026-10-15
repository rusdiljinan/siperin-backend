<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\AktivitasResource;
use App\Models\HistoryAktivitas;
use App\Services\ActivityLogService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AktivitasController extends Controller
{
    use ApiResponse;

    public function __construct(protected ActivityLogService $activityLog) {}

    public function index(Request $request): JsonResponse
    {
        $aktivitas = HistoryAktivitas::with('user')
            ->latest()
            ->paginate((int) $request->get('per_page', 15));

        return $this->listSuccess(
            AktivitasResource::collection($aktivitas->items()),
            [
                'current_page' => $aktivitas->currentPage(),
                'last_page' => $aktivitas->lastPage(),
                'total' => $aktivitas->total(),
            ],
            'Riwayat aktivitas berhasil diambil'
        );
    }

    public function logPrint(Request $request): JsonResponse
    {
        $deskripsi = $request->input('deskripsi', 'Print data inventaris dari aplikasi mobile/web');

        $this->activityLog->log(
            $request->user(),
            'print',
            $deskripsi
        );

        return $this->success(null, 'Aktivitas print tercatat');
    }
}
