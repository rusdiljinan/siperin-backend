<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Kategori\StoreKategoriRequest;
use App\Http\Requests\Kategori\UpdateKategoriRequest;
use App\Http\Resources\KategoriResource;
use App\Models\Kategori;
use App\Repositories\KategoriRepository;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;

class KategoriController extends Controller
{
    use ApiResponse;

    public function __construct(protected KategoriRepository $kategoriRepo) {}

    public function index(): JsonResponse
    {
        $defaultCategories = [
            ['nama_kategori' => 'Elektronik', 'deskripsi' => 'Perangkat elektronik kantor'],
            ['nama_kategori' => 'Furniture', 'deskripsi' => 'Meja, kursi, lemari'],
            ['nama_kategori' => 'Kendaraan', 'deskripsi' => 'Kendaraan dinas'],
            ['nama_kategori' => 'Alat Tulis', 'deskripsi' => 'ATK dan perlengkapan'],
            ['nama_kategori' => 'Lainnya', 'deskripsi' => 'Kategori lainnya'],
        ];

        foreach ($defaultCategories as $category) {
            Kategori::firstOrCreate(
                ['nama_kategori' => $category['nama_kategori']],
                ['deskripsi' => $category['deskripsi']]
            );
        }

        $kategori = $this->kategoriRepo->all()->loadCount('barang');

        return $this->success(KategoriResource::collection($kategori), 'Data kategori berhasil diambil');
    }

    public function store(StoreKategoriRequest $request): JsonResponse
    {
        $kategori = $this->kategoriRepo->create($request->validated());

        return $this->success(new KategoriResource($kategori), 'Kategori berhasil ditambahkan', 201);
    }

    public function show(int $id): JsonResponse
    {
        $kategori = $this->kategoriRepo->find($id);

        if (! $kategori) {
            return $this->error('Kategori tidak ditemukan', 404);
        }

        $kategori->loadCount('barang');

        return $this->success(new KategoriResource($kategori), 'Detail kategori berhasil diambil');
    }

    public function update(UpdateKategoriRequest $request, int $id): JsonResponse
    {
        $kategori = $this->kategoriRepo->find($id);

        if (! $kategori) {
            return $this->error('Kategori tidak ditemukan', 404);
        }

        $kategori = $this->kategoriRepo->update($kategori, $request->validated());

        return $this->success(new KategoriResource($kategori), 'Kategori berhasil diperbarui');
    }

    public function destroy(int $id): JsonResponse
    {
        $kategori = $this->kategoriRepo->find($id);

        if (! $kategori) {
            return $this->error('Kategori tidak ditemukan', 404);
        }

        if ($kategori->barang()->count() > 0) {
            return $this->error('Kategori masih memiliki barang terkait', 422);
        }

        $this->kategoriRepo->delete($kategori);

        return $this->success(null, 'Kategori berhasil dihapus');
    }
}
