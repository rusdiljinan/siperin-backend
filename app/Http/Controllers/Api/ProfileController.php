<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Resources\UserResource;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Throwable;

class ProfileController extends Controller
{
    use ApiResponse;

    public function update(Request $request): JsonResponse
    {
        $user = $request->user();

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:100'],
            'email' => ['sometimes', 'email', 'unique:users,email,'.$user->id],
            'phone' => ['nullable', 'string', 'max:20'],
            'password' => ['nullable', 'string', 'min:6', 'confirmed'],
        ]);

        try {
            if (! empty($validated['password'])) {
                $validated['password'] = Hash::make($validated['password']);
            } else {
                unset($validated['password']);
            }

            DB::transaction(fn () => $user->update($validated));
        } catch (Throwable $e) {
            Log::error('Gagal memperbarui profil pengguna.', [
                'user_id' => $user->id,
                'exception' => $e,
            ]);

            return $this->error('Profil gagal diperbarui. Silakan coba kembali.', 500);
        }

        return $this->success(new UserResource($user->fresh()), 'Profil berhasil diperbarui');
    }
}
