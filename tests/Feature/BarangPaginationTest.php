<?php

namespace Tests\Feature;

use App\Models\Barang;
use App\Models\Kategori;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class BarangPaginationTest extends TestCase
{
    use RefreshDatabase;

    private ?Kategori $kategori = null;

    public function test_barang_index_returns_sorted_pages_with_pagination_metadata(): void
    {
        $this->actingAs($this->user());
        $zebra = $this->barang('INV-001', 'Zebra');
        $alpha = $this->barang('INV-002', 'Alpha');
        $beta = $this->barang('INV-003', 'Beta');

        $firstPage = $this->getJson(
            '/api/barang?per_page=2&page=1&sort_by=nama_barang&sort_dir=asc',
        )->assertOk()
            ->assertJsonPath('meta.current_page', 1)
            ->assertJsonPath('meta.last_page', 2)
            ->assertJsonPath('meta.total', 3);

        $secondPage = $this->getJson(
            '/api/barang?per_page=2&page=2&sort_by=nama_barang&sort_dir=asc',
        )->assertOk()
            ->assertJsonPath('meta.current_page', 2);

        $this->assertSame(
            [$alpha->id, $beta->id],
            array_column($firstPage->json('data'), 'id'),
        );
        $this->assertSame([$zebra->id], array_column($secondPage->json('data'), 'id'));
    }

    public function test_barang_index_filters_each_page_by_condition(): void
    {
        $this->actingAs($this->user());
        $this->barang('INV-004', 'Barang Baik', 'Baik');
        $rusak = $this->barang('INV-005', 'Barang Rusak', 'Rusak');

        $this->getJson('/api/barang?per_page=1&kondisi=Rusak')
            ->assertOk()
            ->assertJsonPath('meta.total', 1)
            ->assertJsonPath('data.0.id', $rusak->id);
    }

    private function user(): User
    {
        return User::factory()->create([
            'name' => 'Admin Penguji',
            'username' => 'admin-barang-penguji',
            'email' => 'admin-barang-penguji@example.test',
            'role' => 'admin',
            'is_active' => true,
        ]);
    }

    private function barang(string $kode, string $nama, string $kondisi = 'Baik'): Barang
    {
        $this->kategori ??= Kategori::create([
            'nama_kategori' => 'Kategori Pengujian',
        ]);

        return Barang::create([
            'kategori_id' => $this->kategori->id,
            'nama_barang' => $nama,
            'tahun_pembelian' => 2024,
            'kode_barang' => $kode,
            'jumlah_barang' => 1,
            'harga_beli' => 1000,
            'kondisi_barang' => $kondisi,
            'lokasi_ruangan' => 'Ruang Uji',
            'status' => 'Aktif',
        ]);
    }
}
