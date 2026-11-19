<?php

namespace Tests\Feature;

use App\Models\Barang;
use App\Models\Kategori;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Tests\TestCase;

class DashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_chart_returns_monthly_condition_quantities_for_the_current_year(): void
    {
        Carbon::setTestNow('2026-03-15 12:00:00');
        try {
            $this->actingAs(User::factory()->create([
                'username' => 'dashboard-'.fake()->unique()->numerify('#####'),
                'role' => 'user',
            ]));

            $this->createBarang('CHART-JAN-SB-1', 10, 'Sangat Baik', '2026-01-02');
            $this->createBarang('CHART-JAN-B-1', 5, 'Baik', '2026-01-02');
            $this->createBarang('CHART-JAN-B-2', 3, 'Baik', '2026-01-15');
            $this->createBarang('CHART-JAN-R-1', 2, 'Rusak', '2026-01-31');
            $this->createBarang('CHART-FEB-SB-1', 7, 'Sangat Baik', '2026-02-01');
            $this->createBarang('CHART-MAR-R-1', 4, 'Rusak', '2026-03-01');
            $this->createBarang('CHART-LAST-YEAR', 99, 'Baik', '2025-12-31');

            $this->getJson('/api/dashboard')
                ->assertOk()
                ->assertJsonPath('data.total_barang', 7)
                ->assertJsonPath('data.total', 7)
                ->assertJsonPath('data.total_kategori', 1)
                ->assertJsonPath('data.barang_baik', 5)
                ->assertJsonPath('data.barang_rusak', 2)
                ->assertJsonPath('data.barang_perbaikan', 0)
                ->assertJsonPath('data.chart_year', 2026)
                ->assertJsonCount(12, 'data.chart')
                ->assertJsonPath('data.chart.0.label', 'Jan')
                ->assertJsonPath('data.chart.0.sangat_baik', 10)
                ->assertJsonPath('data.chart.0.baik', 8)
                ->assertJsonPath('data.chart.0.rusak', 2)
                ->assertJsonPath('data.chart.1.sangat_baik', 7)
                ->assertJsonPath('data.chart.1.baik', 0)
                ->assertJsonPath('data.chart.1.rusak', 0)
                ->assertJsonPath('data.chart.2.rusak', 4)
                ->assertJsonPath('data.chart.3.sangat_baik', 0);
        } finally {
            Carbon::setTestNow();
        }
    }

    public function test_dashboard_returns_zero_statistics_when_inventory_is_empty(): void
    {
        $this->actingAs(User::factory()->create([
            'username' => 'dashboard-empty-'.fake()->unique()->numerify('#####'),
            'role' => 'user',
        ]));

        $this->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('data.total_barang', 0)
            ->assertJsonPath('data.total_kategori', 0)
            ->assertJsonPath('data.barang_baik', 0)
            ->assertJsonPath('data.barang_rusak', 0)
            ->assertJsonPath('data.barang_perbaikan', 0)
            ->assertJsonCount(12, 'data.chart')
            ->assertJsonPath('data.chart.0.sangat_baik', 0)
            ->assertJsonPath('data.chart.0.baik', 0)
            ->assertJsonPath('data.chart.0.rusak', 0);
    }

    public function test_dashboard_requires_authentication(): void
    {
        $this->getJson('/api/dashboard')
            ->assertUnauthorized()
            ->assertJsonPath('success', false);
    }

    public function test_admin_can_access_dashboard(): void
    {
        $this->actingAs(User::factory()->create([
            'username' => 'dashboard-admin-'.fake()->unique()->numerify('#####'),
            'role' => 'admin',
        ]));

        $this->getJson('/api/dashboard')
            ->assertOk()
            ->assertJsonPath('success', true);
    }

    private function createBarang(
        string $code,
        int $quantity,
        string $condition,
        string $createdAt
    ): Barang {
        $category = Kategori::firstOrCreate(['nama_kategori' => 'Kategori Dashboard']);

        $barang = Barang::create([
            'kategori_id' => $category->id,
            'nama_barang' => "Barang {$code}",
            'tahun_pembelian' => 2020,
            'kode_barang' => $code,
            'jumlah_barang' => $quantity,
            'harga_beli' => 1000,
            'kondisi_barang' => $condition,
            'lokasi_ruangan' => 'Ruang Uji',
        ]);

        DB::table('barang')
            ->where('id', $barang->id)
            ->update(['created_at' => Carbon::parse($createdAt)]);

        return $barang;
    }
}
