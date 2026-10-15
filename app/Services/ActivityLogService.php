<?php

namespace App\Services;

use App\Models\HistoryAktivitas;
use App\Models\User;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Request;

class ActivityLogService
{
    public function log(
        User $user,
        string $aktivitas,
        string $deskripsi,
        ?Model $target = null,
    ): HistoryAktivitas {
        return HistoryAktivitas::create([
            'user_id' => $user->id,
            'aktivitas' => $aktivitas,
            'target_type' => $target ? class_basename($target) : null,
            'target_id' => $target?->getKey(),
            'deskripsi' => $deskripsi,
            'role' => $user->role?->value ?? (string) $user->role,
            'ip_address' => Request::ip(),
        ]);
    }
}
