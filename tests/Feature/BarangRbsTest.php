<?php

namespace Tests\Feature;

use Tests\TestCase;
use Illuminate\Foundation\Testing\RefreshDatabase;
use App\Models\Kategori;
use App\Models\Barang;
use App\Models\User;

class BarangRbsTest extends TestCase
{
    use RefreshDatabase;

    public function test_store_with_scores_sets_total_and_condition(): void
    {
        $kategori = Kategori::create(['nama_kategori' => 'Test Kategori']);

        $payload = [
            'kategori_id' => $kategori->id,
            'nama_barang' => 'Test Barang',
            'tahun_pembelian' => 2020,
            'kode_barang' => 'KB-TEST-001',
            'jumlah_barang' => 1,
            'harga_beli' => 1000,
            'lokasi_ruangan' => 'Ruang A',
            'kelengkapan_score' => 3,
            'fungsional_score' => 3,
            'fisik_score' => 3,
            'usia_score' => 3,
            'perawatan_score' => 3,
            'keamanan_score' => 3,
        ];

        $user = User::factory()->create([
            'name' => 'Test User',
            'username' => 'testuser',
            'email' => 'testuser@example.com',
            'role' => 'admin',
        ]);
        $this->actingAs($user);
        $resp = $this->postJson('/api/barang', $payload);
        if ($resp->status() !== 201) {
            fwrite(STDERR, "\nResponse body: " . $resp->getContent() . "\n");
        }
        $resp->assertStatus(201);

        $this->assertDatabaseHas('barang', [
            'kode_barang' => 'KB-TEST-001',
            'total_score' => 18,
            'kondisi_barang' => 'Sangat Baik',
        ]);
    }

    public function test_update_with_scores_updates_condition(): void
    {
        $kategori = Kategori::create(['nama_kategori' => 'Test Kategori']);
        $barang = Barang::create([
            'kategori_id' => $kategori->id,
            'nama_barang' => 'Exist Barang',
            'tahun_pembelian' => 2019,
            'kode_barang' => 'KB-TEST-002',
            'jumlah_barang' => 1,
            'harga_beli' => 1000,
            'lokasi_ruangan' => 'Ruang A',
            'kondisi_barang' => 'Sangat Baik',
        ]);

        $payload = [
            'kelengkapan_score' => 1,
            'fungsional_score' => 1,
            'fisik_score' => 1,
            'usia_score' => 1,
            'perawatan_score' => 1,
            'keamanan_score' => 1,
        ];

        $user = User::factory()->create([
            'name' => 'Test User',
            'username' => 'testuser2',
            'email' => 'testuser2@example.com',
            'role' => 'admin',
        ]);
        $this->actingAs($user);
        $resp = $this->postJson("/api/barang/{$barang->id}", $payload);
        if ($resp->status() !== 200) {
            fwrite(STDERR, "\nResponse body: " . $resp->getContent() . "\n");
        }
        $resp->assertStatus(200);

        $this->assertDatabaseHas('barang', [
            'id' => $barang->id,
            'total_score' => 6,
            'kondisi_barang' => 'Rusak',
        ]);
    }

    public function test_user_role_can_create_inventory(): void
    {
        $user = User::factory()->create([
            'name' => 'User Inventaris',
            'username' => 'user-inventaris',
            'email' => 'user-inventaris@example.test',
            'role' => 'user',
        ]);

        $categoryResponse = $this->actingAs($user)
            ->postJson('/api/kategori', ['nama_kategori' => 'Kategori User'])
            ->assertCreated();
        $kategoriId = $categoryResponse->json('data.id');

        $this->putJson("/api/kategori/{$kategoriId}", [
            'nama_kategori' => 'Kategori User Diperbarui',
        ])->assertOk();

        $this->postJson('/api/barang', [
            'kategori_id' => $kategoriId,
            'nama_barang' => 'Barang User',
            'tahun_pembelian' => 2020,
            'kode_barang' => 'KB-USER-001',
            'jumlah_barang' => 1,
            'harga_beli' => 1000,
            'lokasi_ruangan' => 'Ruang User',
            'kelengkapan_score' => 3,
            'fungsional_score' => 3,
            'fisik_score' => 3,
            'usia_score' => 3,
            'perawatan_score' => 3,
            'keamanan_score' => 3,
        ])
            ->assertCreated();
    }
}
