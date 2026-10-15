<?php

namespace App\Http\Requests\Barang;

use App\Enums\KondisiBarang;
use App\Models\Kategori;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateBarangRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        $barangId = $this->route('barang') ?? $this->route('id');

        return [
            'kategori_id' => ['sometimes', 'exists:kategori,id'],
            'nama_barang' => ['sometimes', 'string', 'max:150'],
            'nama' => ['sometimes', 'string', 'max:150'],
            'merek' => ['nullable', 'string', 'max:100'],
            'nomor_seri' => ['nullable', 'string', 'max:100'],
            'ukuran' => ['nullable', 'string', 'max:100'],
            'bahan' => ['nullable', 'string', 'max:100'],
            'tahun_pembelian' => ['sometimes', 'integer', 'min:1900', 'max:'.(date('Y') + 1)],
            'kode_barang' => ['sometimes', 'string', 'max:50', Rule::unique('barang', 'kode_barang')->ignore($barangId)],
            'kode' => ['sometimes', 'string', 'max:50', Rule::unique('barang', 'kode_barang')->ignore($barangId)],
            'jumlah_barang' => ['sometimes', 'integer', 'min:1'],
            'jumlah' => ['sometimes', 'integer', 'min:1'],
            'harga_beli' => ['sometimes', 'numeric', 'min:0'],
            'kondisi_barang' => ['sometimes', Rule::in(KondisiBarang::values())],
            'kondisi' => ['sometimes', Rule::in(KondisiBarang::values())],
            // Scores for RBS (1..3)
            'kelengkapan_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'fungsional_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'fisik_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'usia_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'perawatan_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'keamanan_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'total_score' => ['sometimes', 'integer', 'min:6', 'max:18'],
            'lokasi_ruangan' => ['sometimes', 'string', 'max:100'],
            'ruangan' => ['sometimes', 'string', 'max:100'],
            'keterangan' => ['nullable', 'string'],
            'foto' => ['nullable', 'image', 'mimes:jpeg,jpg,png,webp', 'max:5120'],
            'remove_foto' => ['nullable', 'boolean'],
            'status' => ['nullable', 'in:Aktif,Nonaktif'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $merge = [];
        if ($this->has('nama')) {
            $merge['nama_barang'] = $this->nama;
        }
        if ($this->has('kode')) {
            $merge['kode_barang'] = $this->kode;
        }
        if ($this->has('jumlah')) {
            $merge['jumlah_barang'] = $this->jumlah;
        }
        if ($this->has('kondisi')) {
            $merge['kondisi_barang'] = $this->kondisi;
        }
        if ($this->has('ruangan')) {
            $merge['lokasi_ruangan'] = $this->ruangan;
        }
        if (! ($merge['kategori_id'] ?? $this->kategori_id) && $this->filled('kategori')) {
            $merge['kategori_id'] = Kategori::where('nama_kategori', $this->kategori)->value('id');
        }
        $this->merge($merge);
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            if ($this->boolean('remove_foto') && $this->hasFile('foto')) {
                $validator->errors()->add(
                    'remove_foto',
                    'Pilih untuk mengganti atau menghapus foto, jangan keduanya.'
                );
            }
        });
    }
}
