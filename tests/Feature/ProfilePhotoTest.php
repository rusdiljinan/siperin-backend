<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Tests\TestCase;

class ProfilePhotoTest extends TestCase
{
    use RefreshDatabase;

    public function test_profile_update_keeps_supported_fields_and_ignores_legacy_photo_data(): void
    {
        $user = $this->userWithRole('user');
        DB::table('users')->where('id', $user->id)->update([
            'foto' => 'profiles/legacy.png',
        ]);
        $this->actingAs($user);

        $this->putJson('/api/profile', [
            'name' => 'Nama Baru',
            'email' => 'nama.baru@example.test',
            'phone' => '08123456789',
            'foto' => 'profiles/should-not-be-set.png',
        ])
            ->assertOk()
            ->assertJsonPath('success', true)
            ->assertJsonPath('data.name', 'Nama Baru')
            ->assertJsonPath('data.email', 'nama.baru@example.test')
            ->assertJsonPath('data.phone', '08123456789')
            ->assertJsonMissingPath('data.foto');

        $this->assertDatabaseHas('users', [
            'id' => $user->id,
            'name' => 'Nama Baru',
            'foto' => 'profiles/legacy.png',
        ]);
    }

    public function test_profile_update_still_supports_password_changes(): void
    {
        $user = $this->userWithRole('user');
        $this->actingAs($user);

        $this->putJson('/api/profile', [
            'password' => 'new-password',
            'password_confirmation' => 'new-password',
        ])
            ->assertOk()
            ->assertJsonPath('success', true);

        $this->assertTrue(Hash::check('new-password', $user->fresh()->password));
    }

    public function test_profile_upload_post_method_is_no_longer_supported(): void
    {
        $this->actingAs($this->userWithRole('user'));

        $this->postJson('/api/profile', [
            'foto' => 'profiles/unaccepted.png',
        ])->assertMethodNotAllowed();
    }

    public function test_profile_update_still_requires_authentication(): void
    {
        $this->putJson('/api/profile', ['name' => 'Nama Baru'])
            ->assertUnauthorized();
    }

    private function userWithRole(string $role): User
    {
        $suffix = fake()->unique()->numerify('#####');

        return User::factory()->create([
            'name' => ucfirst($role).' Profile Test',
            'username' => "{$role}-profile-{$suffix}",
            'email' => "{$role}-profile-{$suffix}@example.test",
            'role' => $role,
        ]);
    }
}
