<?php

namespace App\Repositories;

use App\Models\Barang;
use Illuminate\Contracts\Pagination\LengthAwarePaginator;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Facades\Schema;

class BarangRepository
{
    public function query(array $filters = []): Builder
    {
        $query = Barang::query()
            ->select($this->inventoryColumns())
            ->with('kategori')
            ->latest();

        if (! empty($filters['search'])) {
            $search = $filters['search'];
            $query->where(function (Builder $q) use ($search) {
                $q->where('nama_barang', 'like', "%{$search}%")
                    ->orWhere('kode_barang', 'like', "%{$search}%")
                    ->orWhere('lokasi_ruangan', 'like', "%{$search}%");
            });
        }

        if (! empty($filters['kategori'])) {
            $query->whereHas('kategori', fn (Builder $q) => $q->where('nama_kategori', $filters['kategori']));
        }

        if (! empty($filters['kategori_id'])) {
            $query->where('kategori_id', $filters['kategori_id']);
        }

        if (! empty($filters['kondisi'])) {
            $query->where('kondisi_barang', $filters['kondisi']);
        }

        if (! empty($filters['ruangan'])) {
            $query->where('lokasi_ruangan', $filters['ruangan']);
        }

        if (! empty($filters['tanggal_mulai'])) {
            $query->whereDate('created_at', '>=', $filters['tanggal_mulai']);
        }

        if (! empty($filters['tanggal_akhir'])) {
            $query->whereDate('created_at', '<=', $filters['tanggal_akhir']);
        }

        $sortBy = $filters['sort_by'] ?? 'nama_barang';
        $sortDir = $filters['sort_dir'] ?? 'asc';
        $allowed = ['nama_barang', 'kode_barang', 'tahun_pembelian', 'kondisi_barang', 'created_at'];

        if (in_array($sortBy, $allowed, true)) {
            $query->orderBy($sortBy, $sortDir === 'desc' ? 'desc' : 'asc');
        }

        return $query;
    }

    public function paginate(array $filters = [], int $perPage = 10): LengthAwarePaginator
    {
        $query = $this->query($filters)->reorder();

        if (! empty($filters['kondisi'])) {
            $query->where('barang.kondisi_barang', $filters['kondisi']);
        }

        $sortBy = $filters['sort_by'] ?? 'nama_barang';
        $sortDir = ($filters['sort_dir'] ?? 'asc') === 'desc' ? 'desc' : 'asc';
        $allowedSorts = ['nama_barang', 'kode_barang', 'tahun_pembelian', 'kondisi_barang', 'created_at'];

        if (in_array($sortBy, $allowedSorts, true)) {
            $query->orderBy("barang.{$sortBy}", $sortDir);
        } else {
            $query->orderByDesc('barang.created_at');
            $sortDir = 'desc';
        }

        return $query
            ->orderBy('barang.id', $sortDir)
            ->paginate($perPage);
    }

    public function find(int $id): ?Barang
    {
        return Barang::query()
            ->select($this->inventoryColumns())
            ->with(['kategori', 'creator', 'updater'])
            ->find($id);
    }

    public function create(array $data): Barang
    {
        return Barang::create($data);
    }

    public function update(Barang $barang, array $data): Barang
    {
        $barang->update($data);

        return $barang->fresh(['kategori']);
    }

    public function delete(Barang $barang): void
    {
        $barang->forceDelete();
    }

    private function inventoryColumns(): array
    {
        return array_map(
            static fn (string $column): string => "barang.{$column}",
            array_values(array_diff(Schema::getColumnListing('barang'), ['foto_blob']))
        );
    }
}
