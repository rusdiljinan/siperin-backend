<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class UserManagementTest extends TestCase
{
    use RefreshDatabase;

    private function admin(): User
    {
        return User::factory()->create([
            'name' => 'Admin Penguji',
            'username' => 'admin-penguji',
            'email' => 'admin-penguji@example.test',
            'role' => 'admin',
            'is_active' => true,
        ]);
    }

    public function test_admin_can_create_user_with_generated_login_and_hashed_password(): void
    {
        $this->actingAs($this->admin());

        $response = $this->postJson('/api/users', [
            'name' => 'Petugas Inventaris',
            'role' => 'staff',
            'password' => 'Siperin123',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.user.name', 'Petugas Inventaris')
            ->assertJsonPath('data.user.role', 'staff')
            ->assertJsonPath('data.user.is_active', true)
            ->assertJsonMissingPath('data.user.password')
            ->assertJsonMissingPath('data.user.email')
            ->assertJsonMissingPath('data.user.username');

        $username = $response->json('data.login_username');
        $user = User::where('username', $username)->firstOrFail();
        $this->assertNotSame('Siperin123', $user->password);
        $this->assertTrue(Hash::check('Siperin123', $user->password));
    }

    public function test_admin_user_endpoints_validate_fields_and_preserve_blank_password(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $this->postJson('/api/users', [
            'name' => ' ',
            'role' => 'staff',
            'password' => 'Siperin123',
        ])->assertUnprocessable()->assertJsonValidationErrors('name');

        $this->postJson('/api/users', [
            'name' => 'Petugas',
            'role' => 'superuser',
            'password' => 'Siperin123',
        ])->assertUnprocessable()->assertJsonValidationErrors('role');

        $user = User::factory()->create([
            'name' => 'Staff Lama',
            'username' => 'staff-lama',
            'email' => 'staff-lama@example.test',
            'role' => 'staff',
            'password' => Hash::make('OldPass123'),
        ]);

        $this->putJson("/api/users/{$user->id}", [
            'name' => 'Staff Baru',
            'role' => 'pimpinan',
            'password' => '',
        ])->assertOk()->assertJsonMissingPath('data.password');

        $user->refresh();
        $this->assertSame('Staff Baru', $user->name);
        $this->assertSame('staff-lama', $user->username);
        $this->assertTrue(Hash::check('OldPass123', $user->password));

        $this->putJson("/api/users/{$user->id}", [
            'name' => 'Staff Baru',
            'role' => 'pimpinan',
            'password' => 'NewPass123',
        ])->assertOk();

        $this->assertTrue(Hash::check('NewPass123', $user->fresh()->password));
    }

    public function test_non_admin_cannot_access_user_management_endpoints(): void
    {
        foreach (['staff', 'pimpinan'] as $role) {
            $user = User::factory()->create([
                'username' => "{$role}-penguji",
                'email' => "{$role}-penguji@example.test",
                'role' => $role,
            ]);

            $this->actingAs($user)
                ->getJson('/api/users')
                ->assertForbidden();
        }
    }

    public function test_admin_cannot_deactivate_self_or_last_active_admin(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $this->patchJson("/api/users/{$admin->id}/status", ['is_active' => false])
            ->assertUnprocessable();

        $anotherAdmin = User::factory()->create([
            'username' => 'admin-kedua',
            'email' => 'admin-kedua@example.test',
            'role' => 'admin',
            'is_active' => true,
            'password' => Hash::make('AdminPass123'),
        ]);
        $anotherAdmin->createToken('mobile');

        $this->patchJson("/api/users/{$anotherAdmin->id}/status", ['is_active' => false])
            ->assertOk();

        $anotherAdmin->refresh();
        $this->assertFalse($anotherAdmin->is_active);
        $this->assertDatabaseHas('users', ['id' => $anotherAdmin->id]);
        $this->assertDatabaseMissing('personal_access_tokens', [
            'tokenable_id' => $anotherAdmin->id,
        ]);
        $this->postJson('/api/login', [
            'username' => 'admin-kedua',
            'password' => 'AdminPass123',
        ])->assertUnauthorized();
    }

    public function test_admin_can_delete_user_and_revoke_their_tokens(): void
    {
        $admin = $this->admin();
        $user = User::factory()->create([
            'username' => 'staff-hapus',
            'email' => 'staff-hapus@example.test',
            'role' => 'staff',
        ]);
        $token = $user->createToken('mobile')->accessToken;

        $this->actingAs($admin)
            ->deleteJson("/api/users/{$user->id}")
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('message', 'Pengguna berhasil dihapus');

        $this->assertDatabaseMissing('users', ['id' => $user->id]);
        $this->assertDatabaseMissing('personal_access_tokens', ['id' => $token->id]);
    }

    public function test_admin_cannot_delete_self_or_last_active_admin(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $this->deleteJson("/api/users/{$admin->id}")
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Anda tidak dapat menghapus akun sendiri.');

        $this->deleteJson('/api/users/999999')->assertNotFound();
    }

    public function test_admin_cannot_delete_the_last_active_admin(): void
    {
        $admin = $this->admin();
        User::query()->whereKey($admin->id)->update(['is_active' => false]);
        $lastActiveAdmin = User::factory()->create([
            'username' => 'admin-terakhir',
            'email' => 'admin-terakhir@example.test',
            'role' => 'admin',
            'is_active' => true,
        ]);
        $this->actingAs($admin);

        $this->deleteJson("/api/users/{$lastActiveAdmin->id}")
            ->assertUnprocessable()
            ->assertJsonPath('message', 'Minimal harus ada satu Admin aktif.');

        $this->assertDatabaseHas('users', ['id' => $admin->id]);
        $this->assertDatabaseHas('users', ['id' => $lastActiveAdmin->id]);
    }

    public function test_missing_user_returns_not_found_for_read_update_and_status(): void
    {
        $this->actingAs($this->admin());

        $this->getJson('/api/users/999999')->assertNotFound();
        $this->putJson('/api/users/999999', [
            'name' => 'Nama Baru',
            'role' => 'staff',
        ])->assertNotFound();
        $this->patchJson('/api/users/999999/status', [
            'is_active' => false,
        ])->assertNotFound();
    }

    public function test_inactive_user_is_rejected_by_existing_login_flow(): void
    {
        User::factory()->create([
            'username' => 'akun-nonaktif',
            'email' => 'akun-nonaktif@example.test',
            'role' => 'staff',
            'is_active' => false,
            'password' => Hash::make('Siperin123'),
        ]);

        $this->postJson('/api/login', [
            'username' => 'akun-nonaktif',
            'password' => 'Siperin123',
        ])->assertUnauthorized();
    }

    public function test_existing_username_login_still_works(): void
    {
        User::factory()->create([
            'name' => 'Pengguna Lama',
            'username' => 'pengguna-lama',
            'email' => 'pengguna-lama@example.test',
            'role' => 'staff',
            'is_active' => true,
            'password' => Hash::make('OldPass123'),
        ]);

        $this->postJson('/api/login', [
            'username' => 'pengguna-lama',
            'password' => 'OldPass123',
        ])->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('user.username', 'pengguna-lama')
            ->assertJsonMissingPath('user.password');
    }
}
