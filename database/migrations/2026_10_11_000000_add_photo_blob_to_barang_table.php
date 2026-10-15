<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;

return new class extends Migration
{
    public function up(): void
    {
        $missingColumns = array_values(array_diff(
            ['foto_blob', 'foto_mime'],
            Schema::getColumnListing('barang')
        ));
        if ($missingColumns !== []) {
            if (DB::getDriverName() === 'mysql') {
                $definitions = array_map(
                    static fn (string $column): string => $column === 'foto_blob'
                        ? 'ADD `foto_blob` LONGBLOB NULL'
                        : 'ADD `foto_mime` VARCHAR(100) NULL',
                    $missingColumns
                );
                DB::statement('ALTER TABLE `barang` '.implode(', ', $definitions));
            } else {
                Schema::table('barang', function (Blueprint $table) use ($missingColumns) {
                    if (in_array('foto_blob', $missingColumns, true)) {
                        $table->binary('foto_blob')->nullable();
                    }
                    if (in_array('foto_mime', $missingColumns, true)) {
                        $table->string('foto_mime', 100)->nullable();
                    }
                });
            }
        }

        $disk = Storage::disk('public');
        DB::table('barang')
            ->whereNotNull('foto_barang')
            ->orderBy('id')
            ->chunkById(50, function ($barangs) use ($disk) {
                foreach ($barangs as $barang) {
                    if (! $disk->exists($barang->foto_barang)) {
                        Log::warning('Legacy inventory photo was not found during BLOB migration.', [
                            'barang_id' => $barang->id,
                            'legacy_path' => $barang->foto_barang,
                        ]);
                        continue;
                    }

                    $contents = $disk->get($barang->foto_barang);
                    $mime = (new finfo(FILEINFO_MIME_TYPE))->buffer($contents);
                    if (! is_string($mime) || ! str_starts_with($mime, 'image/')) {
                        Log::warning('Legacy inventory photo is not a valid image; legacy path retained.', [
                            'barang_id' => $barang->id,
                            'legacy_path' => $barang->foto_barang,
                        ]);
                        continue;
                    }

                    DB::table('barang')->where('id', $barang->id)->update([
                        'foto_blob' => $contents,
                        'foto_mime' => $mime,
                        'foto_barang' => null,
                    ]);
                }
            });
    }

    public function down(): void
    {
        $disk = Storage::disk('public');
        DB::table('barang')
            ->whereNotNull('foto_blob')
            ->orderBy('id')
            ->chunkById(50, function ($barangs) use ($disk) {
                foreach ($barangs as $barang) {
                    $extension = match ($barang->foto_mime) {
                        'image/jpeg' => 'jpg',
                        'image/png' => 'png',
                        'image/webp' => 'webp',
                        default => throw new RuntimeException(
                            "Cannot safely restore inventory photo for barang ID {$barang->id}: unsupported MIME type."
                        ),
                    };
                    $path = "barang/rollback-{$barang->id}.{$extension}";
                    if (! $disk->put($path, $barang->foto_blob)) {
                        throw new RuntimeException(
                            "Could not restore inventory photo for barang ID {$barang->id}."
                        );
                    }

                    DB::table('barang')->where('id', $barang->id)->update([
                        'foto_barang' => $path,
                    ]);
                }
            });

        Schema::table('barang', function (Blueprint $table) {
            $table->dropColumn(['foto_blob', 'foto_mime']);
        });
    }
};
