<?php

use App\Http\Controllers\Api\AktivitasController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\BarangController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\KategoriController;
use App\Http\Controllers\Api\LaporanInventarisController;
use App\Http\Controllers\Api\NotifikasiController;
use App\Http\Controllers\Api\PerbaikanController;
use App\Http\Controllers\Api\ProfileController;
use App\Http\Controllers\Api\UserManagementController;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Route;

/*
|--------------------------------------------------------------------------
| SIPERIN - Sistem Pengelolaan Inventaris API Routes
|--------------------------------------------------------------------------
*/

Route::get('/health', function () {
    try {
        DB::connection()->getPdo();
        $dbOk = true;
        $dbName = DB::connection()->getDatabaseName();
    } catch (Throwable $e) {
        Log::error('API database health check failed.', [
            'exception' => $e,
        ]);
        $dbOk = false;
        $dbName = null;
    }

    return response()->json([
        'success' => $dbOk,
        'message' => $dbOk ? 'SIPERIN API & database OK' : 'API jalan tetapi database tidak terhubung',
        'data' => [
            'app' => 'SIPERIN',
            'version' => '1.0.0',
            'database' => $dbName,
            'driver' => config('database.default'),
        ],
    ], $dbOk ? 200 : 503);
});

// Authentication (public)
Route::post('/login', [AuthController::class, 'login']);
Route::post('/register', [AuthController::class, 'register']);
Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
Route::post('/reset-password', [AuthController::class, 'resetPassword']);

Route::middleware('auth:sanctum')->group(function () {
    Route::post('/logout', [AuthController::class, 'logout']);
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/profile', [ProfileController::class, 'update']);

    Route::middleware('role:admin')->group(function () {
        Route::get('/users', [UserManagementController::class, 'index']);
        Route::get('/users/{id}', [UserManagementController::class, 'show']);
        Route::post('/users', [UserManagementController::class, 'store']);
        Route::put('/users/{id}', [UserManagementController::class, 'update']);
        Route::patch('/users/{id}/status', [UserManagementController::class, 'updateStatus']);
        Route::delete('/users/{id}', [UserManagementController::class, 'destroy']);
    });

    Route::get('/dashboard', [DashboardController::class, 'index']);
    Route::get('/laporan-inventaris', [LaporanInventarisController::class, 'index']);
    Route::get('/laporan-inventaris/export/{format}', [LaporanInventarisController::class, 'export'])
        ->where('format', 'pdf|excel');

    // Riwayat aktivitas — semua user & role
    Route::get('/aktivitas', [AktivitasController::class, 'index']);
    Route::post('/aktivitas/log-print', [AktivitasController::class, 'logPrint']);

    Route::get('/notifikasi', [NotifikasiController::class, 'index']);
    Route::patch('/notifikasi/{id}/read', [NotifikasiController::class, 'markRead']);

    // Menu Perbaikan — hanya barang kondisi Rusak
    Route::get('/perbaikan', [PerbaikanController::class, 'index']);

    // Inventaris (tabel barang)
    Route::get('/barang', [BarangController::class, 'index']);
    Route::get('/barang/{id}/foto', [BarangController::class, 'foto']);
    Route::get('/barang/export/{format}', [BarangController::class, 'export'])
        ->where('format', 'pdf|excel');
    Route::get('/barang/{id}', [BarangController::class, 'show']);
    Route::get('/barang/{id}/history', [BarangController::class, 'history']);
    Route::middleware('role:admin')->delete(
        '/barang/bulk-delete',
        [BarangController::class, 'bulkDestroy']
    );

    Route::get('/kategori', [KategoriController::class, 'index']);
    Route::get('/kategori/{kategori}', [KategoriController::class, 'show']);

    Route::middleware('role:admin,user')->group(function () {
        Route::post('/barang', [BarangController::class, 'store']);
        Route::match(['put', 'post'], '/barang/{id}', [BarangController::class, 'update']);
        Route::delete('/barang/{id}', [BarangController::class, 'destroy']);
        Route::post('/barang/{id}/verify', [BarangController::class, 'verify']);

        Route::post('/kategori', [KategoriController::class, 'store']);
        Route::put('/kategori/{kategori}', [KategoriController::class, 'update']);
        Route::delete('/kategori/{kategori}', [KategoriController::class, 'destroy']);
    });

});
