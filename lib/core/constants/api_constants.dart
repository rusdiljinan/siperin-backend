/// Konfigurasi endpoint REST API Laravel SIPERIN.
class ApiConstants {
  static const String baseUrl =
      'https://siperin-backend-production.up.railway.app/api';

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
