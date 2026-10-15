<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class HistoryAktivitas extends Model
{
    protected $table = 'history_aktivitas';

    protected $fillable = [
        'user_id',
        'aktivitas',
        'target_type',
        'target_id',
        'deskripsi',
        'role',
        'ip_address',
    ];

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
