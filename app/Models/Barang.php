<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\SoftDeletes;

class Barang extends Model
{
    use SoftDeletes;

    protected $table = 'barang';

    protected $fillable = [
        'kategori_id',
        'nama_barang',
        'merek',
        'nomor_seri',
        'ukuran',
        'bahan',
        'tahun_pembelian',
        'kode_barang',
        'jumlah_barang',
        'harga_beli',
        'kondisi_barang',
        'kelengkapan_score',
        'fungsional_score',
        'fisik_score',
        'usia_score',
        'perawatan_score',
        'keamanan_score',
        'total_score',
        'lokasi_ruangan',
        'keterangan',
        'foto_barang',
        'foto_blob',
        'foto_mime',
        'status',
        'status_perawatan',
        'created_by',
        'updated_by',
    ];

    protected $hidden = ['foto_blob'];

    protected function casts(): array
    {
        return [
            'harga_beli' => 'decimal:2',
            'tahun_pembelian' => 'integer',
            'jumlah_barang' => 'integer',
            'kelengkapan_score' => 'integer',
            'fungsional_score' => 'integer',
            'fisik_score' => 'integer',
            'usia_score' => 'integer',
            'perawatan_score' => 'integer',
            'keamanan_score' => 'integer',
            'total_score' => 'integer',
        ];
    }

    public function kategori(): BelongsTo
    {
        return $this->belongsTo(Kategori::class, 'kategori_id');
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }

    public function updater(): BelongsTo
    {
        return $this->belongsTo(User::class, 'updated_by');
    }

    public function history(): HasMany
    {
        return $this->hasMany(HistoryAktivitas::class, 'target_id')
            ->where('target_type', 'barang')
            ->latest();
    }
}
