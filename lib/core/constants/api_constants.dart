import 'dart:io' show Platform;

import 'package:flutter/foundation.dart' show kIsWeb;

/// Konfigurasi endpoint REST API Laravel SIPERIN.
///
/// ⚠️ IMPORTANT FOR MOBILE DEPLOYMENT:
///
/// Untuk Android Emulator, jalankan dengan:
/// --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
///
/// Untuk iOS Simulator / Web / Windows:
/// - Gunakan: http://127.0.0.1:8000/api
///
/// Untuk HP fisik (Android/iOS):
/// - Dapatkan IP komputer:
///   Windows: buka cmd, ketik `ipconfig`, cari IPv4 Address (contoh: 192.168.1.100)
///   Mac/Linux: buka terminal, ketik `ifconfig` atau `hostname -I`
/// - Update [deviceHost] di bawah dengan IP komputer
/// - Pastikan HP dan komputer dalam 1 jaringan WiFi
/// - Pastikan Laravel berjalan: php artisan serve --host=0.0.0.0
///
/// Untuk production, atur API_BASE_URL ke URL HTTPS backend termasuk `/api`.
class ApiConstants {
  /// ⚠️ UBAH INI: IP komputer Anda di jaringan WiFi untuk testing HP fisik
  /// Contoh: '192.168.1.100' (cek dengan ipconfig atau ifconfig)
  static const String deviceHost = '192.168.1.4';
  static const int apiPort = 8000;
  static const String _configuredBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
  );

  static String get baseUrl {
    // Override untuk emulator atau deployment: --dart-define=API_BASE_URL=...
    if (_configuredBaseUrl.isNotEmpty) {
      return _configuredBaseUrl;
    }

    // Web Browser dan desktop lokal
    if (kIsWeb) {
      return 'https://siperin-backend-production.up.railway.app/api';
    }

    // Android fisik - gunakan IP komputer di jaringan lokal
    if (!kIsWeb && Platform.isAndroid) {
      // Pastikan Laravel berjalan dengan --host=0.0.0.0.
      return 'http://$deviceHost:$apiPort/api';
    }

    // iOS Simulator - localhost
    if (!kIsWeb && Platform.isIOS) {
      // Untuk iOS Simulator:
      // return 'http://127.0.0.1:$apiPort/api';

      // Untuk iPhone fisik (sesuaikan deviceHost):
      return 'http://$deviceHost:$apiPort/api';
    }

    // Fallback untuk platform lain (macOS, Linux, Windows)
    return 'https://siperin-backend-production.up.railway.app/api';
  }

  static const String login = '/login';
  static const String logout = '/logout';
  static const String me = '/me';
  static const String profile = '/profile';

  static const String users = '/users';
  static String userDetail(int id) => '/users/$id';
  static String userStatus(int id) => '/users/$id/status';

  static const String barang = '/barang';
  static const String barangBulkDelete = '/barang/bulk-delete';
  static String barangDetail(int id) => '/barang/$id';
  static String barangFoto(int id) => '/barang/$id/foto';
  static String barangHistory(int id) => '/barang/$id/history';

  static const String kategori = '/kategori';
  static const String dashboard = '/dashboard';
  static const String laporanInventaris = '/laporan-inventaris';
  static String laporanInventarisExport(String format) =>
      '/laporan-inventaris/export/$format';
  static const String aktivitas = '/aktivitas';
  static const String aktivitasLogPrint = '/aktivitas/log-print';
  static const String perbaikan = '/perbaikan';
}
