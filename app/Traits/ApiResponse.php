<?php

namespace App\Traits;

use Illuminate\Http\JsonResponse;

trait ApiResponse
{
    protected function success(mixed $data = null, string $message = 'Berhasil', int $code = 200): JsonResponse
    {
        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $data,
        ], $code);
    }

    protected function error(string $message = 'Terjadi kesalahan', int $code = 400, mixed $errors = null): JsonResponse
    {
        return response()->json([
            'success' => false,
            'message' => $message,
            'errors' => $errors,
            'data' => null,
        ], $code);
    }

    /**
     * Response khusus login/register — token di root agar mudah di-parse Flutter.
     */
    /**
     * Response list: array langsung di `data`, meta di root (untuk tabel Flutter).
     */
    protected function listSuccess(
        mixed $items,
        array $meta = [],
        string $message = 'Data berhasil diambil',
        int $code = 200,
    ): JsonResponse {
        $resolved = $items instanceof \Illuminate\Http\Resources\Json\ResourceCollection
            ? $items->resolve()
            : $items;

        return response()->json([
            'success' => true,
            'message' => $message,
            'data' => $resolved,
            'meta' => $meta,
        ], $code);
    }

    protected function authSuccess(
        string $token,
        mixed $user,
        string $message = 'Login berhasil',
        int $code = 200,
    ): JsonResponse {
        $userData = $user instanceof \Illuminate\Http\Resources\Json\JsonResource
            ? $user->resolve()
            : $user;

        return response()->json([
            'success' => true,
            'message' => $message,
            'token' => $token,
            'access_token' => $token,
            'token_type' => 'Bearer',
            'user' => $userData,
            'data' => [
                'token' => $token,
                'access_token' => $token,
                'user' => $userData,
            ],
        ], $code);
    }
}
