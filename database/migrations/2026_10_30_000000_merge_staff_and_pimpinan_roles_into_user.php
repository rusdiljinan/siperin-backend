<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('role', ['admin', 'user', 'staff', 'pimpinan'])
                ->default('user')
                ->change();
        });

        DB::table('users')
            ->whereIn('role', ['staff', 'pimpinan'])
            ->update(['role' => 'user']);

        Schema::table('users', function (Blueprint $table) {
            $table->enum('role', ['admin', 'user'])
                ->default('user')
                ->change();
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            $table->enum('role', ['admin', 'user', 'staff', 'pimpinan'])
                ->default('staff')
                ->change();
        });

        // The previous distinction cannot be recovered; restore the lower-privilege role.
        DB::table('users')
            ->where('role', 'user')
            ->update(['role' => 'pimpinan']);

        Schema::table('users', function (Blueprint $table) {
            $table->enum('role', ['admin', 'staff', 'pimpinan'])
                ->default('staff')
                ->change();
        });
    }
};
