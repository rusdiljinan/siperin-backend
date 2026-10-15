<?php

namespace App\Repositories;

use App\Models\Kategori;
use Illuminate\Database\Eloquent\Collection;

class KategoriRepository
{
    public function all(): Collection
    {
        return Kategori::orderBy('nama_kategori')->get();
    }

    public function find(int $id): ?Kategori
    {
        return Kategori::find($id);
    }

    public function create(array $data): Kategori
    {
        return Kategori::create($data);
    }

    public function update(Kategori $kategori, array $data): Kategori
    {
        $kategori->update($data);

        return $kategori->fresh();
    }

    public function delete(Kategori $kategori): void
    {
        $kategori->delete();
    }
}
