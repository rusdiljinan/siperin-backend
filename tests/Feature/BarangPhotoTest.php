<?php

namespace Tests\Feature;

use App\Models\Barang;
use App\Models\Kategori;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Tests\TestCase;

class BarangPhotoTest extends TestCase
{
    use RefreshDatabase;

    public function test_store_and_read_inventory_photo_as_binary(): void
    {
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
        $this->assertSame($expectedBytes, $barang->foto_blob);
        $this->assertSame('image/png', $barang->foto_mime);
        $this->assertDatabaseCount('barang', 1);

        $this->get("/api/barang/{$barang->id}/foto")
            ->assertOk()
            ->assertHeader('Content-Type', 'image/png')
            ->assertContent($expectedBytes);
    }

    public function test_update_keeps_or_replaces_photo_without_duplicating_barang(): void
    {
        $this->actingAs($this->admin());
        $file = $this->uploadedImage('first.png');
        $firstBytes = file_get_contents($file->getPathname());

        $this->post('/api/barang', [
            ...$this->barangPayload(),
            'foto' => $file,
        ], ['Accept' => 'application/json'])->assertCreated();

        $barang = Barang::where('kode_barang', 'PHOTO-001')->firstOrFail();

        $this->put("/api/barang/{$barang->id}", [
            'nama_barang' => 'Nama Diperbarui',
        ], ['Accept' => 'application/json'])->assertOk();

        $this->assertSame($firstBytes, $barang->fresh()->foto_blob);
        $this->assertDatabaseCount('barang', 1);

        $replacement = $this->uploadedImage('replacement.png');
        $replacementBytes = file_get_contents($replacement->getPathname());
        $this->put("/api/barang/{$barang->id}", [
            'foto' => $replacement,
        ], ['Accept' => 'application/json'])->assertOk();

        $this->assertSame($replacementBytes, $barang->fresh()->foto_blob);
        $this->get("/api/barang/{$barang->id}/foto")
            ->assertOk()
            ->assertContent($replacementBytes);

        $this->put("/api/barang/{$barang->id}", [
            'remove_foto' => true,
        ], ['Accept' => 'application/json'])
            ->assertOk()
            ->assertJsonPath('data.has_foto', false);
        $this->assertNull($barang->fresh()->foto_blob);
        $this->get("/api/barang/{$barang->id}/foto")->assertNotFound();
        $this->assertDatabaseCount('barang', 1);
    }

    public function test_invalid_update_does_not_replace_existing_photo(): void
    {
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

        $this->assertSame($originalBytes, $barang->fresh()->foto_blob);
        $this->assertDatabaseCount('barang', 1);
    }

    public function test_invalid_upload_is_rejected_without_creating_barang(): void
    {
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
