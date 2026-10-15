<?php

namespace App\Http\Controllers\Api;

use App\Enums\UserRole;
use App\Http\Controllers\Controller;
use App\Http\Resources\ManagedUserResource;
use App\Models\User;
use Illuminate\Database\Eloquent\ModelNotFoundException;
use App\Traits\ApiResponse;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\Rules\Password;
use Throwable;

class UserManagementController extends Controller
{
    use ApiResponse;

    public function index(Request $request): JsonResponse
    {
        $filters = $request->validate([
            'search' => ['nullable', 'string', 'max:100'],
            'role' => ['nullable', Rule::in(array_column(UserRole::cases(), 'value'))],
        ]);

        $users = User::query()
            ->when($filters['search'] ?? null, fn ($query, $search) => $query->where('name', 'like', "%{$search}%"))
            ->when($filters['role'] ?? null, fn ($query, $role) => $query->where('role', $role))
            ->orderBy('name')
            ->paginate(20);

        $items = $users->getCollection()
            ->map(fn (User $user) => (new ManagedUserResource($user))->toArray($request))
            ->all();

        return $this->listSuccess($items, [
            'current_page' => $users->currentPage(),
            'last_page' => $users->lastPage(),
            'per_page' => $users->perPage(),
            'total' => $users->total(),
        ], 'Daftar pengguna berhasil diambil');
    }

    public function show(Request $request, int $id): JsonResponse
    {
        $user = User::findOrFail($id);

        return $this->success(
            (new ManagedUserResource($user))->toArray($request),
            'Detail pengguna berhasil diambil'
        );
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'role' => ['required', Rule::in(array_column(UserRole::cases(), 'value'))],
            'password' => ['required', 'string', 'max:72', Password::min(8)->letters()->numbers()],
        ]);

        try {
            [$user, $loginUsername] = DB::transaction(function () use ($validated): array {
                [$username, $email] = $this->generateLoginIdentity($validated['name']);
                $user = User::create([
                    'name' => trim($validated['name']),
                    'username' => $username,
                    'email' => $email,
                    'role' => $validated['role'],
                    'password' => Hash::make($validated['password']),
                    'is_active' => true,
                ]);

                return [$user, $username];
            });

            return $this->success([
                'user' => (new ManagedUserResource($user))->toArray($request),
                'login_username' => $loginUsername,
            ], 'Pengguna berhasil ditambahkan', 201);
        } catch (Throwable $e) {
            Log::error('Gagal membuat pengguna', ['error' => $e->getMessage()]);

            return $this->error('Pengguna gagal disimpan', 500);
        }
    }

    public function update(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'role' => ['required', Rule::in(array_column(UserRole::cases(), 'value'))],
            'password' => ['sometimes', 'nullable', 'string', 'max:72', Password::min(8)->letters()->numbers()],
        ]);

        try {
            $user = DB::transaction(function () use ($id, $validated): User {
                $user = User::query()->whereKey($id)->lockForUpdate()->firstOrFail();
                $newRole = $validated['role'];

                if ($user->is_active && $user->role === UserRole::Admin && $newRole !== UserRole::Admin->value
                    && ! $this->hasOtherActiveAdmin($user)) {
                    throw new \DomainException('Minimal harus ada satu Admin aktif.');
                }

                $user->name = trim($validated['name']);
                $user->role = $newRole;
                if (! empty($validated['password'])) {
                    $user->password = Hash::make($validated['password']);
                }
                $user->save();

                return $user;
            });

            return $this->success(
                (new ManagedUserResource($user))->toArray($request),
                'Pengguna berhasil diperbarui'
            );
        } catch (\DomainException $e) {
            return $this->error($e->getMessage(), 422);
        } catch (ModelNotFoundException) {
            return $this->error('Pengguna tidak ditemukan', 404);
        } catch (Throwable $e) {
            Log::error('Gagal memperbarui pengguna', ['user_id' => $id, 'error' => $e->getMessage()]);

            return $this->error('Pengguna gagal diperbarui', 500);
        }
    }

    public function updateStatus(Request $request, int $id): JsonResponse
    {
        $validated = $request->validate([
            'is_active' => ['required', 'boolean'],
        ]);

        try {
            $user = DB::transaction(function () use ($id, $validated, $request): User {
                $user = User::query()->whereKey($id)->lockForUpdate()->firstOrFail();
                $active = (bool) $validated['is_active'];

                if (! $active && (int) $request->user()->id === (int) $user->id) {
                    throw new \DomainException('Anda tidak dapat menonaktifkan akun sendiri.');
                }

                if (! $active && $user->is_active && $user->role === UserRole::Admin
                    && ! $this->hasOtherActiveAdmin($user)) {
                    throw new \DomainException('Minimal harus ada satu Admin aktif.');
                }

                $user->is_active = $active;
                $user->save();
                if (! $active) {
                    $user->tokens()->delete();
                }

                return $user;
            });

            return $this->success(
                (new ManagedUserResource($user))->toArray($request),
                $user->is_active ? 'Pengguna berhasil diaktifkan' : 'Pengguna berhasil dinonaktifkan'
            );
        } catch (\DomainException $e) {
            return $this->error($e->getMessage(), 422);
        } catch (ModelNotFoundException) {
            return $this->error('Pengguna tidak ditemukan', 404);
        } catch (Throwable $e) {
            Log::error('Gagal mengubah status pengguna', ['user_id' => $id, 'error' => $e->getMessage()]);

            return $this->error('Status pengguna gagal diperbarui', 500);
        }
    }

    public function destroy(Request $request, int $id): JsonResponse
    {
        try {
            DB::transaction(function () use ($request, $id): void {
                $user = User::query()->whereKey($id)->lockForUpdate()->firstOrFail();

                if ((int) $request->user()->id === (int) $user->id) {
                    throw new \DomainException('Anda tidak dapat menghapus akun sendiri.');
                }

                if ($user->is_active && $user->role === UserRole::Admin
                    && ! $this->hasOtherActiveAdmin($user)) {
                    throw new \DomainException('Minimal harus ada satu Admin aktif.');
                }

                $user->tokens()->delete();
                $user->delete();
            });

            return $this->success(null, 'Pengguna berhasil dihapus');
        } catch (\DomainException $e) {
            return $this->error($e->getMessage(), 422);
        } catch (ModelNotFoundException) {
            return $this->error('Pengguna tidak ditemukan', 404);
        } catch (Throwable $e) {
            Log::error('Gagal menghapus pengguna', ['user_id' => $id, 'error' => $e->getMessage()]);

            return $this->error('Pengguna gagal dihapus', 500);
        }
    }

    private function generateLoginIdentity(string $name): array
    {
        $base = Str::slug($name, '.');
        if ($base === '') {
            $base = 'pengguna';
        }

        for ($suffix = 1; ; $suffix++) {
            $tail = $suffix === 1 ? '' : (string) $suffix;
            $username = substr($base, 0, 50 - strlen($tail)).$tail;
            $email = $username.'@users.siperin.local';

            if (! User::where('username', $username)->orWhere('email', $email)->exists()) {
                return [$username, $email];
            }
        }
    }

    private function hasOtherActiveAdmin(User $user): bool
    {
        return User::query()
            ->where('role', UserRole::Admin->value)
            ->where('is_active', true)
            ->orderBy('id')
            ->lockForUpdate()
            ->pluck('id')
            ->contains(fn ($id) => (int) $id !== (int) $user->id);
    }
}
