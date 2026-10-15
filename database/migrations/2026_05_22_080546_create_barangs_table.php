<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('barang', function (Blueprint $table) {
            $table->id();
            $table->foreignId('kategori_id')->constrained('kategori')->cascadeOnDelete();
            $table->string('nama_barang');
            $table->string('merek')->nullable();
            $table->string('nomor_seri')->nullable();
            $table->string('ukuran')->nullable();
            $table->string('bahan')->nullable();
            $table->year('tahun_pembelian');
            $table->string('kode_barang')->unique();
            $table->unsignedInteger('jumlah_barang')->default(1);
            $table->decimal('harga_beli', 15, 2)->default(0);
            $table->enum('kondisi_barang', ['Sangat Baik', 'Baik', 'Rusak']);
            $table->string('lokasi_ruangan');
            $table->text('keterangan')->nullable();
            $table->string('foto_barang')->nullable();
            $table->string('qr_code_path')->nullable();
            $table->enum('status', ['Aktif', 'Nonaktif'])->default('Aktif');
            $table->string('status_perawatan')->nullable();
            $table->foreignId('created_by')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('updated_by')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamps();
            $table->softDeletes();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('barang');
    }
};
