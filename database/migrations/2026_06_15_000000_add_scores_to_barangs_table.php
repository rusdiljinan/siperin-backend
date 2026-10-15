<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('barang', function (Blueprint $table) {
            $table->unsignedTinyInteger('kelengkapan_score')->nullable()->after('kondisi_barang');
            $table->unsignedTinyInteger('fungsional_score')->nullable()->after('kelengkapan_score');
            $table->unsignedTinyInteger('fisik_score')->nullable()->after('fungsional_score');
            $table->unsignedTinyInteger('usia_score')->nullable()->after('fisik_score');
            $table->unsignedTinyInteger('perawatan_score')->nullable()->after('usia_score');
            $table->unsignedTinyInteger('keamanan_score')->nullable()->after('perawatan_score');
            $table->unsignedSmallInteger('total_score')->nullable()->after('keamanan_score');
        });
    }

    public function down(): void
    {
        Schema::table('barang', function (Blueprint $table) {
            $table->dropColumn([
                'kelengkapan_score',
                'fungsional_score',
                'fisik_score',
                'usia_score',
                'perawatan_score',
                'keamanan_score',
                'total_score',
            ]);
        });
    }
};
