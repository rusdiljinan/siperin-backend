/// Metadata navigasi berdasarkan path URL.
class RouteMeta {
  final int selectedIndex;
  final String? title;

  const RouteMeta({required this.selectedIndex, this.title});

  static RouteMeta fromLocation(String location) {
    if (location.startsWith('/dashboard')) {
      return const RouteMeta(selectedIndex: 0, title: 'Dashboard Inventaris');
    }
    if (location.startsWith('/laporan-inventaris')) {
      return const RouteMeta(selectedIndex: 0, title: 'Laporan Inventaris');
    }
    if (location.startsWith('/inventaris/tambah')) {
      return const RouteMeta(selectedIndex: 1, title: 'Tambah Inventaris');
    }
    // Edit dibuka di luar shell — tetap sorot menu Inventaris
    if (RegExp(r'^/inventaris/\d+/edit$').hasMatch(location)) {
      return const RouteMeta(selectedIndex: 1, title: 'Edit Inventaris');
    }
    // ✅ FIX #1: Kondisi barang & penilaian ulang adalah bagian dari menu Perbaikan
    if (RegExp(r'^/inventaris/\d+/kondisi$').hasMatch(location)) {
      return const RouteMeta(selectedIndex: 2, title: 'Kondisi Barang');
    }
    if (RegExp(r'^/inventaris/\d+/nilai-ulang$').hasMatch(location)) {
      return const RouteMeta(selectedIndex: 2, title: 'Penilaian Kondisi');
    }
    if (RegExp(r'^/inventaris/\d+$').hasMatch(location)) {
      return const RouteMeta(selectedIndex: 1, title: 'Detail Inventaris');
    }
    if (location == '/inventaris' || location.startsWith('/inventaris?')) {
      return const RouteMeta(selectedIndex: 1, title: 'Inventaris');
    }
    if (location.startsWith('/perbaikan')) {
      return const RouteMeta(selectedIndex: 2, title: 'Perbaikan');
    }
    if (location.startsWith('/aktivitas')) {
      return const RouteMeta(selectedIndex: 3, title: 'Riwayat Aktivitas');
    }
    if (location.startsWith('/profile')) {
      return const RouteMeta(selectedIndex: 4, title: 'Profile');
    }
    if (location.startsWith('/users')) {
      return const RouteMeta(selectedIndex: 5, title: 'Mengelola Pengguna');
    }
    return const RouteMeta(selectedIndex: 0);
  }
}
