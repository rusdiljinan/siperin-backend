<?php

namespace Tests\Feature;

use App\Models\Barang;
use App\Models\Kategori;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BulkDeleteBarangTest extends TestCase
{
    use RefreshDatabase;

    private ?Kategori $kategori = null;

    public function test_admin_can_delete_only_the_selected_barang(): void
    {
        $this->actingAs($this->user('admin'));
        $selected = [$this->barang('INV-001'), $this->barang('INV-002')];
        $untouched = $this->barang('INV-003');

        $this->deleteJson('/api/barang/bulk-delete', [
            'ids' => array_map(fn (Barang $barang) => $barang->id, $selected),
        ])->assertOk()
            ->assertJsonPath('message', '2 barang berhasil dihapus dari database');

        foreach ($selected as $barang) {
            $this->assertDatabaseMissing('barang', ['id' => $barang->id]);
        }
        $this->assertDatabaseHas('barang', ['id' => $untouched->id]);
    }

    public function test_user_cannot_bulk_delete_barang(): void
    {
        $this->actingAs($this->user('user'));
        $barang = $this->barang('INV-004');

        $this->deleteJson('/api/barang/bulk-delete', [
            'ids' => [$barang->id],
        ])->assertForbidden();

        $this->assertDatabaseHas('barang', ['id' => $barang->id]);
    }

    public function test_bulk_delete_rejects_duplicate_or_missing_ids_without_deleting_anything(): void
    {
        $this->actingAs($this->user('admin'));
        $barang = $this->barang('INV-005');

        $this->deleteJson('/api/barang/bulk-delete', [
            'ids' => [$barang->id, $barang->id],
        ])->assertUnprocessable();

        $this->deleteJson('/api/barang/bulk-delete', [
            'ids' => [$barang->id, 999999],
        ])->assertUnprocessable();

        $this->assertDatabaseHas('barang', ['id' => $barang->id]);
    }

    private function user(string $role): User
    {
        return User::factory()->create([
            'name' => ucfirst($role).' Penguji',
            'username' => $role.'-penguji',
            'email' => $role.'-penguji@example.test',
            'role' => $role,
            'is_active' => true,
        ]);
    }

    private function barang(string $kode): Barang
    {
        $this->kategori ??= Kategori::create([
            'nama_kategori' => 'Kategori Pengujian',
        ]);

        return Barang::create([
            'kategori_id' => $this->kategori->id,
            'nama_barang' => 'Barang '.$kode,
            'tahun_pembelian' => 2024,
            'kode_barang' => $kode,
            'jumlah_barang' => 1,
            'harga_beli' => 1000,
            'kondisi_barang' => 'Baik',
            'lokasi_ruangan' => 'Ruang Uji',
            'status' => 'Aktif',
        ]);
    }
}
