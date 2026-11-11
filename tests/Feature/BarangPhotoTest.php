<?php

namespace Tests\Feature;

use App\Models\Barang;
use App\Models\Kategori;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class BarangPhotoTest extends TestCase
{
    use RefreshDatabase;

    public function test_store_and_read_inventory_photo_from_public_storage(): void
    {
        Storage::fake('public');
        $this->actingAs($this->admin());
        $file = $this->uploadedImage('inventory.png');
        $expectedBytes = file_get_contents($file->getPathname());

        $response = $this->post('/api/barang', [
            ...$this->barangPayload(),
            'foto' => $file,
        ], ['Accept' => 'application/json']);

        $response->assertCreated()
            ->assertJsonPath('data.has_foto', true)
            ->assertJsonMissingPath('data.foto_blob');

        $barang = Barang::where('kode_barang', 'PHOTO-001')->firstOrFail();
        $this->assertNotEmpty($barang->foto_barang);
        $this->assertNull($barang->foto_blob);
        $this->assertNull($barang->foto_mime);
        Storage::disk('public')->assertExists($barang->foto_barang);
        $this->assertDatabaseCount('barang', 1);

        $this->get("/api/barang/{$barang->id}/foto")
            ->assertOk()
            ->assertHeader('Content-Type', 'image/png')
            ->assertContent($expectedBytes);
    }

    public function test_update_keeps_or_replaces_photo_without_duplicating_barang(): void
    {
        Storage::fake('public');
        $this->actingAs($this->admin());
        $file = $this->uploadedImage('first.png');

        $this->post('/api/barang', [
            ...$this->barangPayload(),
            'foto' => $file,
        ], ['Accept' => 'application/json'])->assertCreated();

        $barang = Barang::where('kode_barang', 'PHOTO-001')->firstOrFail();

        $this->put("/api/barang/{$barang->id}", [
            'nama_barang' => 'Nama Diperbarui',
        ], ['Accept' => 'application/json'])->assertOk();

        $originalPath = $barang->fresh()->foto_barang;
        $this->assertNotEmpty($originalPath);
        Storage::disk('public')->assertExists($originalPath);
        $this->assertDatabaseCount('barang', 1);

        $replacement = $this->uploadedImage('replacement.png');
        $replacementBytes = file_get_contents($replacement->getPathname());
        $this->post("/api/barang/{$barang->id}", [
            'foto' => $replacement,
        ], ['Accept' => 'application/json'])->assertOk();

        $replacementPath = $barang->fresh()->foto_barang;
        $this->assertNotSame($originalPath, $replacementPath);
        $this->assertNull($barang->fresh()->foto_blob);
        Storage::disk('public')->assertExists($replacementPath);
        Storage::disk('public')->assertMissing($originalPath);
        $this->get("/api/barang/{$barang->id}/foto")
            ->assertOk()
            ->assertContent($replacementBytes);

        $this->put("/api/barang/{$barang->id}", [
            'remove_foto' => true,
        ], ['Accept' => 'application/json'])
            ->assertOk()
            ->assertJsonPath('data.has_foto', false);
        $this->assertNull($barang->fresh()->foto_barang);
        Storage::disk('public')->assertMissing($replacementPath);
        $this->get("/api/barang/{$barang->id}/foto")->assertNotFound();
        $this->assertDatabaseCount('barang', 1);
    }

    public function test_invalid_update_does_not_replace_existing_photo(): void
    {
        Storage::fake('public');
        $this->actingAs($this->admin());
        $file = $this->uploadedImage('original.png');
        $originalBytes = file_get_contents($file->getPathname());

        $this->post('/api/barang', [
            ...$this->barangPayload(),
            'foto' => $file,
        ], ['Accept' => 'application/json'])->assertCreated();

        $barang = Barang::where('kode_barang', 'PHOTO-001')->firstOrFail();
        $invalidReplacement = UploadedFile::fake()->create('notes.txt', 2, 'text/plain');

        $this->put("/api/barang/{$barang->id}", [
            'nama_barang' => '',
            'foto' => $invalidReplacement,
        ], ['Accept' => 'application/json'])->assertUnprocessable();

        $originalPath = $barang->fresh()->foto_barang;
        $this->assertNotEmpty($originalPath);
        Storage::disk('public')->assertExists($originalPath);
        $this->assertSame($originalBytes, Storage::disk('public')->get($originalPath));
        $this->assertDatabaseCount('barang', 1);
    }

    public function test_invalid_upload_is_rejected_without_creating_barang(): void
    {
        Storage::fake('public');
        $this->actingAs($this->admin());
        $invalidFile = UploadedFile::fake()->create('notes.txt', 2, 'text/plain');

        $this->post('/api/barang', [
            ...$this->barangPayload(),
            'foto' => $invalidFile,
        ], ['Accept' => 'application/json'])->assertUnprocessable();

        $this->assertDatabaseCount('barang', 0);
    }

    public function test_barang_without_photo_is_saved_and_photo_endpoint_returns_not_found(): void
    {
        Storage::fake('public');
        $this->actingAs($this->admin());

        $response = $this->postJson('/api/barang', $this->barangPayload());

        $response->assertCreated()
            ->assertJsonPath('data.has_foto', false)
            ->assertJsonPath('data.foto', null);

        $barang = Barang::where('kode_barang', 'PHOTO-001')->firstOrFail();
        $this->assertNull($barang->foto_blob);
        $this->assertNull($barang->foto_mime);
        $this->get("/api/barang/{$barang->id}/foto")->assertNotFound();
        $this->assertDatabaseCount('barang', 1);
    }

    public function test_legacy_blob_photo_remains_readable(): void
    {
        Storage::fake('public');
        $this->actingAs($this->admin());
        $this->postJson('/api/barang', $this->barangPayload())->assertCreated();
        $barang = Barang::where('kode_barang', 'PHOTO-001')->firstOrFail();
        $legacyFile = $this->uploadedImage('legacy.png');
        $legacyBytes = file_get_contents($legacyFile->getPathname());
        $barang->forceFill([
            'foto_blob' => $legacyBytes,
            'foto_mime' => 'image/png',
        ])->save();

        $this->get("/api/barang/{$barang->id}/foto")
            ->assertOk()
            ->assertContent($legacyBytes);
    }

    public function test_upload_larger_than_five_megabytes_is_rejected(): void
    {
        $this->actingAs($this->admin());
        $validPng = base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/pN8AAAAASUVORK5CYII=',
            true
        );
        $oversizedImage = UploadedFile::fake()->createWithContent(
            'oversized.png',
            $validPng.str_repeat("\0", 5 * 1024 * 1024 + 1)
        );

        $this->post('/api/barang', [
            ...$this->barangPayload(),
            'foto' => $oversizedImage,
        ], ['Accept' => 'application/json'])->assertUnprocessable();

        $this->assertDatabaseCount('barang', 0);
    }

    private function admin(): User
    {
        return User::factory()->create([
            'name' => 'Photo Test Admin',
            'username' => 'photo-admin-'.fake()->unique()->numerify('#####'),
            'email' => fake()->unique()->safeEmail(),
            'role' => 'admin',
        ]);
    }

    private function barangPayload(): array
    {
        $kategori = Kategori::create(['nama_kategori' => 'Kategori Foto']);

        return [
            'kategori_id' => $kategori->id,
            'nama_barang' => 'Barang Foto',
            'tahun_pembelian' => 2024,
            'kode_barang' => 'PHOTO-001',
            'jumlah_barang' => 1,
            'harga_beli' => 100000,
            'kondisi_barang' => 'Baik',
            'lokasi_ruangan' => 'Ruang Foto',
        ];
    }

    private function uploadedImage(string $name): UploadedFile
    {
        $contents = base64_decode(
            'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/pN8AAAAASUVORK5CYII=',
            true
        );

        return UploadedFile::fake()->createWithContent($name, $contents);
    }
}
