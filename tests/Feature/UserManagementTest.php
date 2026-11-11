<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Mail;
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

    public function test_admin_can_create_user_without_email_and_preserve_hashed_initial_password(): void
    {
        Mail::fake();
        $this->actingAs($this->admin());

        $response = $this->postJson('/api/users', [
            'name' => 'Petugas Inventaris',
            'role' => 'user',
            'password' => 'Siperin123',
        ]);

        $response->assertCreated()
            ->assertJsonPath('data.user.name', 'Petugas Inventaris')
            ->assertJsonPath('data.user.role', 'user')
            ->assertJsonPath('data.user.is_active', true)
            ->assertJsonPath('data.login_username', 'petugas.inventaris')
            ->assertJsonMissingPath('data.user.password')
            ->assertJsonMissingPath('data.user.email')
            ->assertJsonMissingPath('data.user.username');

        $user = User::where('username', 'petugas.inventaris')->firstOrFail();
        $this->assertNotSame('Siperin123', $user->password);
        $this->assertTrue(Hash::check('Siperin123', $user->password));
        $this->assertSame('petugas.inventaris@users.siperin.local', $user->email);
        $this->assertDatabaseMissing('password_reset_tokens', ['email' => $user->email]);
        Mail::assertNothingOutgoing();

        $login = $this->postJson('/api/login', [
            'username' => 'petugas.inventaris',
            'password' => 'Siperin123',
        ])->assertOk()->assertJsonPath('user.role', 'user');

        $this->app['auth']->forgetGuards();
        $this->withToken($login->json('token'))
            ->postJson('/api/logout')
            ->assertOk()
            ->assertJsonPath('message', 'Logout berhasil');
    }

    public function test_admin_can_create_user_without_email_or_username(): void
    {
        Mail::fake();
        $this->actingAs($this->admin());

        $response = $this->postJson('/api/users', [
            'name' => 'Petugas Kedua',
            'role' => 'user',
        ])->assertCreated()
            ->assertJsonPath('data.login_username', 'petugas.kedua');

        $user = User::where('id', $response->json('data.user.id'))->firstOrFail();
        $this->assertSame('petugas.kedua', $user->username);
        $this->assertSame('petugas.kedua@users.siperin.local', $user->email);
        $this->assertSame('user', $user->role->value);
        $this->assertNotEmpty($user->password);
        Mail::assertNothingOutgoing();

        $response = $this->postJson('/api/users', [
            'name' => 'Petugas Manual',
            'email' => 'email-tidak-dipakai@example.test',
            'username' => 'petugas-tanpa-email',
            'role' => 'user',
        ])->assertCreated();

        $this->assertSame(
            'petugas.manual@users.siperin.local',
            User::findOrFail($response->json('data.user.id'))->email
        );
        $this->assertDatabaseHas('users', [
            'email' => 'petugas.manual@users.siperin.local',
            'username' => 'petugas-tanpa-email',
        ]);
        Mail::assertNothingOutgoing();
    }

    public function test_admin_user_creation_validates_username_and_password_without_email(): void
    {
        $this->actingAs($this->admin());
        $payload = [
            'name' => 'Petugas Baru',
            'username' => 'petugas-baru',
            'role' => 'user',
        ];

        $this->postJson('/api/users', [
            ...$payload,
            'username' => 'admin-penguji',
        ])->assertUnprocessable()->assertJsonValidationErrors('username');

        $this->postJson('/api/users', [
            ...$payload,
            'password' => 'invalid',
        ])->assertUnprocessable()->assertJsonValidationErrors('password');

        $this->assertSame(1, User::count());
    }

    public function test_admin_user_endpoints_validate_fields_and_preserve_blank_password(): void
    {
        $admin = $this->admin();
        $this->actingAs($admin);

        $this->postJson('/api/users', [
            'name' => ' ',
            'role' => 'user',
            'password' => 'Siperin123',
        ])->assertUnprocessable()->assertJsonValidationErrors('name');

        $this->postJson('/api/users', [
            'name' => 'Petugas',
            'role' => 'superuser',
            'password' => 'Siperin123',
        ])->assertUnprocessable()->assertJsonValidationErrors('role');

        foreach (['staff', 'pimpinan'] as $legacyRole) {
            $this->postJson('/api/users', [
                'name' => 'Petugas',
                'role' => $legacyRole,
                'password' => 'Siperin123',
            ])->assertUnprocessable()->assertJsonValidationErrors('role');
        }

        $user = User::factory()->create([
            'name' => 'User Lama',
            'username' => 'user-lama',
            'email' => 'user-lama@example.test',
            'role' => 'user',
            'password' => Hash::make('OldPass123'),
        ]);

        $this->putJson("/api/users/{$user->id}", [
            'name' => 'User Baru',
            'role' => 'user',
            'password' => '',
        ])->assertOk()->assertJsonMissingPath('data.password');

        $user->refresh();
        $this->assertSame('User Baru', $user->name);
        $this->assertSame('user-lama', $user->username);
        $this->assertTrue(Hash::check('OldPass123', $user->password));

        $this->putJson("/api/users/{$user->id}", [
            'name' => 'User Baru',
            'role' => 'user',
            'password' => 'NewPass123',
        ])->assertOk();

        $this->assertTrue(Hash::check('NewPass123', $user->fresh()->password));
    }

    public function test_non_admin_cannot_access_user_management_endpoints(): void
    {
        $user = User::factory()->create([
            'username' => 'user-penguji',
            'email' => 'user-penguji@example.test',
            'role' => 'user',
        ]);

        $this->actingAs($user)
            ->getJson('/api/users')
            ->assertForbidden();
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
            'username' => 'user-hapus',
            'email' => 'user-hapus@example.test',
            'role' => 'user',
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
            'role' => 'user',
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
            'role' => 'user',
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
            'role' => 'user',
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
