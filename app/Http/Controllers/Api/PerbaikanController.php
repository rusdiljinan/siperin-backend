<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\BarangResource;
use App\Repositories\BarangRepository;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

/**
 * Menu Perbaikan — data inventaris dengan kondisi Rusak saja.
 */
class PerbaikanController extends Controller
{
    use ApiResponse;

    public function __construct(protected BarangRepository $barangRepo) {}

    public function index(Request $request): JsonResponse
    {
        $filters = array_merge($request->only(['search', 'ruangan', 'kategori']), [
            'kondisi' => 'Rusak',
        ]);

        $items = $this->barangRepo->query($filters)->get();

        return $this->success(
            BarangResource::collection($items),
            'Data barang rusak (perlu perbaikan) berhasil diambil'
        );
    }
}
