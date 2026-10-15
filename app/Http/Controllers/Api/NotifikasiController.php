<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\NotifikasiResource;
use App\Models\Notifikasi;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class NotifikasiController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $items = Notifikasi::where('user_id', $request->user()->id)
            ->latest()
            ->paginate(20);

        return $this->success([
            'data' => NotifikasiResource::collection($items->items()),
            'unread_count' => Notifikasi::where('user_id', $request->user()->id)->where('is_read', false)->count(),
        ], 'Notifikasi berhasil diambil');
    }

    public function markRead(int $id, Request $request): JsonResponse
    {
        $notif = Notifikasi::where('user_id', $request->user()->id)->find($id);

        if (! $notif) {
            return $this->error('Notifikasi tidak ditemukan', 404);
        }

        $notif->update(['is_read' => true]);

        return $this->success(new NotifikasiResource($notif), 'Notifikasi ditandai sudah dibaca');
    }
}
