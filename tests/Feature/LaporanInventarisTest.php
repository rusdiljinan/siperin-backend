<?php

namespace Tests\Feature;

use App\Models\Barang;
use App\Models\Kategori;
use App\Models\User;
use Carbon\Carbon;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class LaporanInventarisTest extends TestCase
{
    use RefreshDatabase;

    public function test_monthly_report_calculates_entry_quantity_value_and_condition_counts(): void
    {
        $this->actingAs($this->user('admin'));
        $this->createBarang('REPORT-01', 3, 12000, 'Baik', '2040-06-01');
        $this->createBarang('REPORT-02', 2, 5000, 'Rusak', '2040-06-20');
        $this->createBarang('REPORT-03', 8, 1000, 'Sangat Baik', '2040-05-31');

        $this->getJson('/api/laporan-inventaris?period=monthly&reference_date=2040-06-11')
            ->assertOk()
            ->assertJsonPath('data.date_from', '2040-06-01')
            ->assertJsonPath('data.date_to', '2040-06-30')
            ->assertJsonPath('data.summary.total_entries', 2)
            ->assertJsonPath('data.summary.total_quantity', 5)
            ->assertJsonPath('data.summary.total_value', 46000)
            ->assertJsonPath('data.summary.conditions.Baik.entries', 1)
            ->assertJsonPath('data.summary.conditions.Baik.quantity', 3)
            ->assertJsonPath('data.summary.conditions.Rusak.entries', 1)
            ->assertJsonPath('data.items.0.kode_barang', 'REPORT-01');
    }

    public function test_weekly_report_uses_monday_through_sunday_and_custom_dates_validate(): void
    {
        $this->actingAs($this->user('user'));
        $reference = Carbon::parse('2040-06-07');
        $weekStart = $reference->copy()->startOfWeek();
        $this->createBarang('WEEK-IN', 1, 2000, 'Baik', $weekStart->toDateString());
        $this->createBarang(
            'WEEK-OUT',
            4,
            3000,
            'Rusak',
            $weekStart->copy()->addWeek()->toDateString()
        );

        $this->getJson('/api/laporan-inventaris?period=weekly&reference_date='.$reference->toDateString())
            ->assertOk()
            ->assertJsonPath('data.date_from', $weekStart->toDateString())
            ->assertJsonPath('data.date_to', $weekStart->copy()->endOfWeek()->toDateString())
            ->assertJsonPath('data.summary.total_entries', 1)
            ->assertJsonPath('data.summary.total_quantity', 1);

        $this->getJson('/api/laporan-inventaris?period=custom&start_date=2040-06-12&end_date=2040-06-01')
            ->assertUnprocessable()
            ->assertJsonValidationErrors('start_date');
    }

    public function test_report_endpoints_require_authentication_and_allow_user_role(): void
    {
        $this->getJson('/api/laporan-inventaris?period=monthly&reference_date=2026-10-11')
            ->assertUnauthorized();

        $this->actingAs($this->user('user'))
            ->getJson('/api/laporan-inventaris?period=monthly&reference_date=2026-10-11')
            ->assertOk();
    }

    public function test_empty_report_returns_empty_condition_object_and_items(): void
    {
        $this->actingAs($this->user('user'));

        $response = $this->getJson('/api/laporan-inventaris?period=monthly&reference_date=2040-06-11')
            ->assertOk()
            ->assertJsonPath('data.summary.total_entries', 0)
            ->assertJsonPath('data.summary.total_quantity', 0)
            ->assertJsonPath('data.summary.total_value', 0)
            ->assertJsonPath('data.items', []);

        $payload = json_decode($response->getContent());
        $this->assertInstanceOf(\stdClass::class, $payload->data->summary->conditions);
        $this->assertSame([], (array) $payload->data->summary->conditions);
    }

    public function test_all_period_returns_every_active_inventory_without_date_filter(): void
    {
        $this->actingAs($this->user('user'));
        $this->createBarang('ALL-OLD', 2, 3000, 'Baik', '2020-01-05');
        $this->createBarang('ALL-NEW', 4, 5000, 'Rusak', '2040-06-12');
        $deleted = $this->createBarang('ALL-DELETED', 8, 1000, 'Baik', '2040-06-12');
        $deleted->delete();

        $this->getJson('/api/laporan-inventaris?period=all')
            ->assertOk()
            ->assertJsonPath('data.period', 'all')
            ->assertJsonPath('data.date_from', null)
            ->assertJsonPath('data.date_to', null)
            ->assertJsonPath('data.summary.total_entries', 2)
            ->assertJsonPath('data.summary.total_quantity', 6)
            ->assertJsonPath('data.summary.total_value', 26000)
            ->assertJsonPath('data.items.0.kode_barang', 'ALL-OLD')
            ->assertJsonPath('data.items.1.kode_barang', 'ALL-NEW')
            ->assertJsonPath('data.items.0.status_perawatan', null)
            ->assertJsonPath('data.items.1.kategori', 'Kategori Laporan')
            ->assertJsonPath('data.items.1.lokasi_ruangan', 'Ruang Uji')
            ->assertJsonPath('data.items.1.status', 'Aktif')
            ->assertJsonMissingPath('data.items.2');
    }

    public function test_report_tracks_inventory_created_updated_and_deleted_through_api(): void
    {
        Storage::fake('public');
        $this->actingAs($this->user('user'));
        $category = Kategori::firstOrCreate(['nama_kategori' => 'Kategori Laporan']);

        $created = $this->postJson('/api/barang', [
            'kategori_id' => $category->id,
            'nama_barang' => 'Barang laporan API',
            'tahun_pembelian' => 2024,
            'kode_barang' => 'REPORT-API-CRUD',
            'jumlah_barang' => 4,
            'harga_beli' => 1000,
            'kondisi_barang' => 'Baik',
            'lokasi_ruangan' => 'Ruang Uji',
        ])->assertCreated()
            ->assertJsonPath('data.kode_barang', 'REPORT-API-CRUD');

        $barangId = $created->json('data.id');
        $this->getJson('/api/laporan-inventaris?period=all')
            ->assertOk()
            ->assertJsonPath('data.summary.total_entries', 1)
            ->assertJsonPath('data.summary.total_quantity', 4)
            ->assertJsonPath('data.summary.total_value', 4000)
            ->assertJsonPath('data.items.0.id', $barangId);

        $this->putJson("/api/barang/{$barangId}", [
            'jumlah_barang' => 5,
            'harga_beli' => 1500,
        ])->assertOk();

        $this->getJson('/api/laporan-inventaris?period=all')
            ->assertOk()
            ->assertJsonPath('data.summary.total_entries', 1)
            ->assertJsonPath('data.summary.total_quantity', 5)
            ->assertJsonPath('data.summary.total_value', 7500)
            ->assertJsonPath('data.items.0.jumlah_barang', 5)
            ->assertJsonPath('data.items.0.harga_beli', 1500);

        $this->deleteJson("/api/barang/{$barangId}")->assertOk();

        $this->getJson('/api/laporan-inventaris?period=all')
            ->assertOk()
            ->assertJsonPath('data.summary.total_entries', 0)
            ->assertJsonPath('data.summary.total_quantity', 0)
            ->assertJsonPath('data.summary.total_value', 0)
            ->assertJsonPath('data.items', []);
    }

    public function test_pdf_and_excel_exports_return_real_files_with_same_period_filter(): void
    {
        $this->actingAs($this->user('user'));
        $this->createBarang('EXPORT-01', 2, 15000, 'Baik', '2040-06-06');
        $query = '?period=weekly&reference_date=2040-06-07';

        $pdf = $this->get('/api/laporan-inventaris/export/pdf'.$query);
        $pdf->assertOk()->assertHeader('content-type', 'application/pdf');
        $this->assertStringStartsWith('%PDF-', $pdf->getContent());

        $excel = $this->get('/api/laporan-inventaris/export/excel'.$query);
        $excel->assertOk()->assertHeader(
            'content-type',
            'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet'
        );
        $excelContent = $excel->streamedContent();
        $this->assertSame('PK', substr($excelContent, 0, 2));

        $temporaryFile = tempnam(sys_get_temp_dir(), 'siperin-report-');
        try {
            file_put_contents($temporaryFile, $excelContent);
            $sheet = \PhpOffice\PhpSpreadsheet\IOFactory::load($temporaryFile)->getActiveSheet();
            $this->assertSame('EXPORT-01', $sheet->getCell('H11')->getValue());
            $this->assertSame(
                '"Rp" #,##0.00',
                $sheet->getStyle('J11')->getNumberFormat()->getFormatCode()
            );
            $this->assertSame(
                '"Rp" #,##0.00',
                $sheet->getStyle('B7')->getNumberFormat()->getFormatCode()
            );
        } finally {
            unlink($temporaryFile);
        }
    }

    private function createBarang(
        string $code,
        int $quantity,
        int $unitPrice,
        string $condition,
        string $createdAt
    ): Barang {
        $category = Kategori::firstOrCreate(['nama_kategori' => 'Kategori Laporan']);

        $barang = Barang::create([
            'kategori_id' => $category->id,
            'nama_barang' => "Barang {$code}",
            'merek' => 'Merek',
            'nomor_seri' => "SN-{$code}",
            'ukuran' => 'Sedang',
            'bahan' => 'Logam',
            'tahun_pembelian' => 2024,
            'kode_barang' => $code,
            'jumlah_barang' => $quantity,
            'harga_beli' => $unitPrice,
            'kondisi_barang' => $condition,
            'lokasi_ruangan' => 'Ruang Uji',
        ]);

        DB::table('barang')
            ->where('id', $barang->id)
            ->update(['created_at' => Carbon::parse($createdAt)]);

        return $barang;
    }

    private function user(string $role): User
    {
        return User::factory()->create([
            'name' => 'Report '.$role,
            'username' => "report-{$role}-".fake()->unique()->numerify('#####'),
            'email' => fake()->unique()->safeEmail(),
            'role' => $role,
        ]);
    }
}
