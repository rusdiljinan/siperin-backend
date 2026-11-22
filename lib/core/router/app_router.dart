import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../pages/aktivitas/aktivitas_page.dart';
import '../../pages/barang/barang_detail_page.dart';
import '../../pages/barang/barang_form_page.dart';
import '../../pages/barang/penilaian_kondisi_page.dart';
import '../../pages/barang/barang_penilaian_edit_page.dart';
import '../../pages/barang/kondisi_barang_page.dart';
import '../../pages/barang/barang_list_page.dart';
import '../../pages/dashboard/dashboard_page.dart';
import '../../pages/login/login_page.dart';
import '../../pages/laporan/laporan_inventaris_page.dart';
import '../../pages/perbaikan/perbaikan_page.dart';
import '../../pages/profile/profile_page.dart';
import '../../pages/users/user_management_page.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/main_app_shell.dart';
import 'page_transitions.dart';

class AppRouter {
  static GoRouter create(BuildContext context) {
    final auth = context.read<AuthProvider>();

    return GoRouter(
      initialLocation: '/login',
      refreshListenable: auth,
      redirect: (context, state) {
        final loggedIn = auth.isAuthenticated;
        final onLogin = state.matchedLocation == '/login';
        final loc = state.matchedLocation;

        if (!loggedIn && !onLogin) return '/login';
        if (loggedIn && onLogin) return '/dashboard';
        if (loc.startsWith('/users') && auth.user?.role != 'admin') {
          return '/dashboard';
        }

        // Redirect route lama ke route baru
        if (loc == '/barang' || loc.startsWith('/barang?')) {
          return '/inventaris';
        }
        if (loc == '/laporan') return '/laporan-inventaris';
        return null;
      },
      routes: [
        GoRoute(
          path: '/login',
          pageBuilder: (context, state) =>
              AppTransitions.fade(state: state, child: const LoginPage()),
        ),
        ShellRoute(
          builder: (context, state, child) => MainAppShell(child: child),
          routes: [
            GoRoute(
              path: '/dashboard',
              pageBuilder: (context, state) => AppTransitions.fadeSlide(
                state: state,
                child: const DashboardPage(),
              ),
            ),
            GoRoute(
              path: '/laporan-inventaris',
              pageBuilder: (context, state) => AppTransitions.fadeSlide(
                state: state,
                child: const LaporanInventarisPage(),
              ),
            ),
            GoRoute(
              path: '/inventaris',
              pageBuilder: (context, state) => AppTransitions.fadeSlide(
                state: state,
                child: const BarangListPage(),
              ),
            ),
            GoRoute(
              path: '/inventaris/tambah',
              pageBuilder: (context, state) => AppTransitions.fadeSlide(
                state: state,
                slideBegin: const Offset(0, 0.02),
                child: const BarangFormPage(),
              ),
            ),
            GoRoute(
              path: '/inventaris/penilaian',
              pageBuilder: (context, state) {
                final extra = state.extra as Map<String, dynamic>?;
                final form =
                    extra != null && extra['form'] is Map<String, dynamic>
                    ? extra['form'] as Map<String, dynamic>
                    : <String, dynamic>{};
                final foto = extra != null ? extra['foto'] : null;
                return AppTransitions.fadeSlide(
                  state: state,
                  child: PenilaianKondisiPage(form: form, foto: foto),
                );
              },
            ),
            GoRoute(
              path: '/inventaris/:id',
              pageBuilder: (context, state) {
                try {
                  final idStr = state.pathParameters['id'];
                  final id = idStr != null ? int.parse(idStr) : 0;
                  if (id <= 0) {
                    return AppTransitions.slideFromRight(
                      state: state,
                      child: const Scaffold(
                        body: Center(child: Text('ID inventaris tidak valid')),
                      ),
                    );
                  }
                  return AppTransitions.slideFromRight(
                    state: state,
                    child: BarangDetailPage(barangId: id),
                  );
                } catch (e) {
                  debugPrint('[Router] Error parsing ID: $e');
                  return AppTransitions.slideFromRight(
                    state: state,
                    child: const Scaffold(
                      body: Center(
                        child: Text('Error: ID inventaris tidak valid'),
                      ),
                    ),
                  );
                }
              },
            ),
            // ✅ PERBAIKAN 2: Route halaman kondisi barang (view only)
            GoRoute(
              path: '/inventaris/:id/kondisi',
              pageBuilder: (context, state) {
                try {
                  final idStr = state.pathParameters['id'];
                  final id = idStr != null ? int.parse(idStr) : 0;
                  if (id <= 0) {
                    return AppTransitions.slideFromRight(
                      state: state,
                      child: const Scaffold(
                        body: Center(child: Text('ID inventaris tidak valid')),
                      ),
                    );
                  }
                  return AppTransitions.slideFromRight(
                    state: state,
                    child: KondisiBarangPage(barangId: id),
                  );
                } catch (e) {
                  debugPrint('[Router] Error parsing ID: $e');
                  return AppTransitions.slideFromRight(
                    state: state,
                    child: const Scaffold(
                      body: Center(
                        child: Text('Error: ID inventaris tidak valid'),
                      ),
                    ),
                  );
                }
              },
            ),
            // ✅ PERBAIKAN 2 (REVISED): Route penilaian kondisi barang untuk update
            GoRoute(
              path: '/inventaris/:id/nilai-ulang',
              pageBuilder: (context, state) {
                try {
                  final idStr = state.pathParameters['id'];
                  final id = idStr != null ? int.parse(idStr) : 0;
                  if (id <= 0) {
                    return AppTransitions.slideFromRight(
                      state: state,
                      child: const Scaffold(
                        body: Center(child: Text('ID inventaris tidak valid')),
                      ),
                    );
                  }
                  final extra = state.extra;
                  final data = extra is Map<String, dynamic> ? extra : null;
                  final draft = data?['form'];
                  return AppTransitions.slideFromRight(
                    state: state,
                    child: BarangPenilaianEditPage(
                      barangId: id,
                      draftForm: draft is Map<String, dynamic> ? draft : null,
                      foto: data?['foto'] is XFile
                          ? data!['foto'] as XFile
                          : null,
                      removeFoto: data?['removeFoto'] == true,
                      returnToEdit: data?['returnToEdit'] == true,
                    ),
                  );
                } catch (e) {
                  debugPrint('[Router] Error parsing ID: $e');
                  return AppTransitions.slideFromRight(
                    state: state,
                    child: const Scaffold(
                      body: Center(
                        child: Text('Error: ID inventaris tidak valid'),
                      ),
                    ),
                  );
                }
              },
            ),
            GoRoute(
              path: '/inventaris/:id/edit',
              pageBuilder: (context, state) {
                try {
                  final idStr = state.pathParameters['id'];
                  final id = idStr != null ? int.parse(idStr) : 0;
                  if (id <= 0) {
                    return AppTransitions.slideFromRight(
                      state: state,
                      child: const Scaffold(
                        body: Center(child: Text('ID inventaris tidak valid')),
                      ),
                    );
                  }
                  return AppTransitions.slideFromRight(
                    state: state,
                    child: BarangFormPage(barangId: id),
                  );
                } catch (e) {
                  debugPrint('[Router] Error parsing ID: $e');
                  return AppTransitions.slideFromRight(
                    state: state,
                    child: const Scaffold(
                      body: Center(
                        child: Text('Error: ID inventaris tidak valid'),
                      ),
                    ),
                  );
                }
              },
            ),
            GoRoute(
              path: '/perbaikan',
              pageBuilder: (context, state) => AppTransitions.fadeSlide(
                state: state,
                child: const PerbaikanPage(),
              ),
            ),
            GoRoute(
              path: '/aktivitas',
              pageBuilder: (context, state) => AppTransitions.fadeSlide(
                state: state,
                child: const AktivitasPage(),
              ),
            ),
            GoRoute(
              path: '/profile',
              pageBuilder: (context, state) => AppTransitions.fadeSlide(
                state: state,
                child: const ProfilePage(),
              ),
            ),
            GoRoute(
              path: '/users',
              pageBuilder: (context, state) => AppTransitions.fadeSlide(
                state: state,
                child: const UserManagementPage(),
              ),
            ),
          ],
        ),
        // Detail & edit now handled inside ShellRoute to keep context/menu visible
      ],
    );
  }
}
