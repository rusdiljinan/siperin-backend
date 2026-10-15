<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class AktivitasResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'deskripsi' => $this->deskripsi,
            'aktivitas' => $this->aktivitas,
            'tipe' => $this->aktivitas,
            'aksi' => $this->aktivitas,
            'user' => $this->user?->name,
            'user_name' => $this->user?->name,
            'role' => $this->role ?? $this->user?->role?->value,
            'target_type' => $this->target_type,
            'target_id' => $this->target_id,
            'created_at' => $this->created_at?->toIso8601String(),
        ];
    }
}
