<?php

namespace App\Http\Requests\Barang;

use App\Enums\KondisiBarang;
use App\Models\Kategori;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class StoreBarangRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'kategori_id' => ['nullable', 'exists:kategori,id'],
            'kategori' => ['nullable', 'string', 'max:100'],
            'nama_barang' => ['required', 'string', 'max:150'],
            'nama' => ['sometimes', 'string', 'max:150'],
            'merek' => ['nullable', 'string', 'max:100'],
            'nomor_seri' => ['nullable', 'string', 'max:100'],
            'ukuran' => ['nullable', 'string', 'max:100'],
            'bahan' => ['nullable', 'string', 'max:100'],
            'tahun_pembelian' => ['required', 'integer', 'min:1900', 'max:'.(date('Y') + 1)],
            'kode_barang' => ['required', 'string', 'max:50', 'unique:barang,kode_barang'],
            'kode' => ['sometimes', 'string', 'max:50', 'unique:barang,kode_barang'],
            'jumlah_barang' => ['required', 'integer', 'min:1'],
            'jumlah' => ['sometimes', 'integer', 'min:1'],
            'harga_beli' => ['required', 'numeric', 'min:0'],
            // Kondisi sekarang dapat di-set otomatis oleh RBS. Tetap terima nilai manual jika disediakan.
            'kondisi_barang' => ['sometimes', 'nullable', Rule::in(KondisiBarang::values())],
            'kondisi' => ['sometimes', Rule::in(KondisiBarang::values())],
            // Scores for RBS (1..3)
            'kelengkapan_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'fungsional_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'fisik_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'usia_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'perawatan_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'keamanan_score' => ['sometimes', 'integer', 'min:1', 'max:3'],
            'total_score' => ['sometimes', 'integer', 'min:6', 'max:18'],
            'lokasi_ruangan' => ['required', 'string', 'max:100'],
            'ruangan' => ['sometimes', 'string', 'max:100'],
            'keterangan' => ['nullable', 'string'],
            'foto' => ['nullable', 'image', 'mimes:jpeg,jpg,png,webp', 'max:5120'],
            'status' => ['nullable', 'in:Aktif,Nonaktif'],
        ];
    }

    protected function prepareForValidation(): void
    {
        $kategoriId = $this->kategori_id;
        if (! $kategoriId && $this->filled('kategori')) {
            $allowedCategories = ['Elektronik', 'Furniture', 'Kendaraan', 'Alat Tulis', 'Lainnya'];
            $kategoriName = trim((string) $this->kategori);

            if (in_array($kategoriName, $allowedCategories, true)) {
                $kategoriId = Kategori::firstOrCreate([
                    'nama_kategori' => $kategoriName,
                ])->id;
            }
        }

        $this->merge([
            'nama_barang' => $this->nama_barang ?? $this->nama,
            'kode_barang' => $this->kode_barang ?? $this->kode,
            'jumlah_barang' => $this->jumlah_barang ?? $this->jumlah,
            'kondisi_barang' => $this->kondisi_barang ?? $this->kondisi,
            'lokasi_ruangan' => $this->lokasi_ruangan ?? $this->ruangan,
            'kategori_id' => $kategoriId,
        ]);
    }

    public function withValidator($validator): void
    {
        $validator->after(function ($validator) {
            if (! $this->kategori_id) {
                $message = $this->filled('kategori')
                    ? 'Kategori yang dipilih tidak tersedia. Silakan muat ulang daftar kategori.'
                    : 'Silakan pilih kategori barang.';
                $validator->errors()->add('kategori', $message);
            }
        });
    }
}
