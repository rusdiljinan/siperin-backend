<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class BarangResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        $hasFoto = filled($this->foto_mime)
            || filled($this->foto_barang)
            || filled($this->foto_blob);
        $fotoUrl = $hasFoto ? url("/api/barang/{$this->id}/foto") : null;

        return [
            'id' => $this->id,
            'nama' => $this->nama_barang,
            'nama_barang' => $this->nama_barang,
            'merek' => $this->merek,
            'nomor_seri' => $this->nomor_seri,
            'ukuran' => $this->ukuran,
            'bahan' => $this->bahan,
            'tahun_pembelian' => (int) $this->tahun_pembelian,
            'kode' => $this->kode_barang,
            'kode_barang' => $this->kode_barang,
            'jumlah' => (int) $this->jumlah_barang,
            'jumlah_barang' => (int) $this->jumlah_barang,
            'harga_beli' => (float) $this->harga_beli,
            'kondisi' => $this->kondisi_barang,
            'kondisi_barang' => $this->kondisi_barang,
            'ruangan' => $this->lokasi_ruangan,
            'lokasi_ruangan' => $this->lokasi_ruangan,
            'kelengkapan_score' => $this->kelengkapan_score,
            'fungsional_score' => $this->fungsional_score,
            'fisik_score' => $this->fisik_score,
            'usia_score' => $this->usia_score,
            'perawatan_score' => $this->perawatan_score,
            'keamanan_score' => $this->keamanan_score,
            'total_score' => $this->total_score,
            'keterangan' => $this->keterangan,
            'foto' => $fotoUrl,
            'foto_url' => $fotoUrl,
            'foto_barang' => $fotoUrl,
            'has_foto' => $hasFoto,
            'qr_code_path' => $this->qr_code_path ? asset('storage/'.$this->qr_code_path) : null,
            'status' => $this->status,
            'status_perawatan' => $this->status_perawatan,
            'kategori' => $this->whenLoaded('kategori', fn () => $this->kategori->nama_kategori),
            'kategori_id' => $this->kategori_id,
            'created_at' => $this->created_at?->toIso8601String(),
            'updated_at' => $this->updated_at?->toIso8601String(),
        ];
    }
}
