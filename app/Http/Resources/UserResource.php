<?php

namespace App\Http\Resources;

use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class UserResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'id' => $this->id,
            'name' => $this->name,
            'username' => $this->username,
            'email' => $this->email,
            'role' => $this->role->value,
            'phone' => $this->phone,
            'foto' => $this->foto ? asset('storage/'.$this->foto) : null,
            'is_active' => $this->is_active,
        ];
    }
}
