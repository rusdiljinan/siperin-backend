<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Laporan extends Model
{
    protected $table = 'laporan';

    protected $fillable = [
        'user_id',
        'judul',
        'periode_mulai',
        'periode_akhir',
        'filter_json',
        'file_path',
        'tipe',
    ];

    protected function casts(): array
    {
        return [
            'filter_json' => 'array',
            'periode_mulai' => 'date',
            'periode_akhir' => 'date',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
