<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Requests\Auth\ForgotPasswordRequest;
use App\Http\Requests\Auth\LoginRequest;
use App\Http\Requests\Auth\RegisterRequest;
use App\Http\Requests\Auth\ResetPasswordRequest;
use App\Http\Resources\UserResource;
use App\Models\User;
use App\Services\ActivityLogService;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

class AuthController extends Controller
{
    use ApiResponse;

    public function __construct(
        protected ActivityLogService $activityLog,
    ) {}

    public function login(LoginRequest $request): JsonResponse
    {
        try {
            $user = User::where('username', $request->username)
                ->where('is_active', true)
                ->first();

            if (! $user || ! Hash::check($request->password, $user->password)) {
                return $this->error('Username atau password salah', 401);
            }

            // Satu token aktif per perangkat (mobile)
            $user->tokens()->where('name', 'mobile')->delete();

            $plainToken = $user->createToken('mobile')->plainTextToken;

            $this->activityLog->log($user, 'login', "User {$user->name} berhasil login");

            return $this->authSuccess(
                $plainToken,
                new UserResource($user),
                'Login berhasil'
            );
        } catch (Throwable $e) {
            Log::error('Login gagal', [
                'username' => $request->username,
                'error' => $e->getMessage(),
            ]);

            return $this->error('Terjadi kesalahan saat login. Hubungi administrator.', 500);
        }
    }

    public function register(RegisterRequest $request): JsonResponse
    {
        try {
            $user = User::create([
                'name' => $request->name,
                'username' => $request->username,
                'email' => $request->email,
                'password' => $request->password,
                'role' => $request->role ?? UserRole::Staff->value,
                'phone' => $request->phone,
                'is_active' => true,
            ]);

            $plainToken = $user->createToken('mobile')->plainTextToken;

            return $this->authSuccess(
                $plainToken,
                new UserResource($user),
                'Registrasi berhasil',
                201
            );
        } catch (Throwable $e) {
            Log::error('Register gagal', ['error' => $e->getMessage()]);

            return $this->error('Registrasi gagal: '.$e->getMessage(), 500);
        }
    }

    public function logout(Request $request): JsonResponse
    {
        try {
            $user = $request->user();

            if ($user) {
                $token = $user->currentAccessToken();
                if ($token) {
                    $token->delete();
                }
                $this->activityLog->log($user, 'logout', "User {$user->name} logout");
            }

            return $this->success(null, 'Logout berhasil');
        } catch (Throwable $e) {
            Log::error('Logout error', ['error' => $e->getMessage()]);

            return $this->error('Logout gagal', 500);
        }
    }

    public function me(Request $request): JsonResponse
    {
        return $this->success(new UserResource($request->user()), 'Profil berhasil diambil');
    }

    public function forgotPassword(ForgotPasswordRequest $request): JsonResponse
    {
        try {
            $token = Str::random(64);

            DB::table('password_reset_tokens')->updateOrInsert(
                ['email' => $request->email],
                ['token' => Hash::make($token), 'created_at' => now()]
            );

            return $this->success([
                'reset_token' => $token,
            ], 'Permintaan reset password berhasil');
        } catch (Throwable $e) {
            Log::error('Forgot password error', ['error' => $e->getMessage()]);

            return $this->error('Gagal memproses reset password', 500);
        }
    }

    public function resetPassword(ResetPasswordRequest $request): JsonResponse
    {
        try {
            $record = DB::table('password_reset_tokens')->where('email', $request->email)->first();

            if (! $record || ! Hash::check($request->token, $record->token)) {
                return $this->error('Token reset tidak valid', 422);
            }

            User::where('email', $request->email)->update([
                'password' => $request->password,
            ]);

            DB::table('password_reset_tokens')->where('email', $request->email)->delete();

            return $this->success(null, 'Password berhasil direset');
        } catch (Throwable $e) {
            Log::error('Reset password error', ['error' => $e->getMessage()]);

            return $this->error('Gagal reset password', 500);
        }
    }
}
