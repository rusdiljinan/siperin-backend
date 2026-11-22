import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'providers/aktivitas_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/barang_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/perbaikan_provider.dart';
import 'providers/theme_provider.dart';
import 'services/aktivitas_service.dart';
import 'services/api_client.dart';
import 'services/auth_service.dart';
import 'services/barang_service.dart';
import 'services/dashboard_service.dart';
import 'services/perbaikan_service.dart';
import 'services/laporan_inventaris_service.dart';
import 'services/storage_service.dart';
import 'utils/responsive.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Setup global error handlers for mobile crash safety
  FlutterError.onError = (FlutterErrorDetails details) {
    debugPrintStack(stackTrace: details.stack, label: 'FLUTTER ERROR');
    debugPrint('[AppError] ${details.exception}');
  };

  try {
    await initializeDateFormatting('id_ID', null);
  } catch (e) {
    debugPrint('[Initialization] Failed to initialize date formatting: $e');
  }

  final storage = StorageService();
  final apiClient = ApiClient(storage);
  final authService = AuthService(apiClient, storage);

  runApp(
    InventarisApp(
      storage: storage,
      apiClient: apiClient,
      authService: authService,
    ),
  );
}

class InventarisApp extends StatefulWidget {
  final StorageService storage;
  final ApiClient apiClient;
  final AuthService authService;

  const InventarisApp({
    super.key,
    required this.storage,
    required this.apiClient,
    required this.authService,
  });

  @override
  State<InventarisApp> createState() => _InventarisAppState();
}

class _InventarisAppState extends State<InventarisApp> {
  late final AuthProvider _authProvider;
  late final ThemeProvider _themeProvider;
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _authProvider = AuthProvider(widget.authService);
    _themeProvider = ThemeProvider(widget.storage);
    // ✅ COLD START FIX: Load theme synchronously before build
    // This prevents stale theme state from being retained after app restart
    _loadInitialTheme();
    // Initialize auth in parallel
    _authProvider.checkAuth().catchError((e) {
      debugPrint('[AuthInit] checkAuth failed: $e');
    });
  }

  Future<void> _loadInitialTheme() async {
    try {
      // Wait for theme to load before any UI is built
      await _themeProvider.loadTheme();
      if (mounted) setState(() {}); // Ensure UI rebuilds with correct theme
    } catch (e) {
      debugPrint('[ThemeInit] loadTheme failed: $e');
      // Fallback to default theme (light) is handled by ThemeProvider
    }
  }

  @override
  Widget build(BuildContext context) {
    final barangService = BarangService(widget.apiClient);

    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider.value(value: _themeProvider),
        Provider.value(value: widget.storage),
        Provider.value(value: widget.apiClient),
        Provider.value(value: widget.authService),
        Provider.value(value: barangService),
        Provider(create: (_) => LaporanInventarisService(widget.apiClient)),
        ChangeNotifierProvider(
          create: (_) => DashboardProvider(DashboardService(widget.apiClient)),
        ),
        ChangeNotifierProvider(create: (_) => BarangProvider(barangService)),
        ChangeNotifierProvider(
          create: (_) => AktivitasProvider(AktivitasService(widget.apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => PerbaikanProvider(PerbaikanService(widget.apiClient)),
        ),
      ],
      child: Consumer2<AuthProvider, ThemeProvider>(
        builder: (context, auth, theme, _) {
          _router ??= AppRouter.create(context);
          return MaterialApp.router(
            title: 'Inventaris Instansi',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme().copyWith(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                },
              ),
            ),
            darkTheme: AppTheme.darkTheme().copyWith(
              pageTransitionsTheme: const PageTransitionsTheme(
                builders: {
                  TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
                  TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
                  TargetPlatform.windows: FadeUpwardsPageTransitionsBuilder(),
                },
              ),
            ),
            themeMode: theme.themeMode,
            routerConfig: _router!,
            builder: (context, child) {
              final mediaQuery = MediaQuery.of(context);
              final systemScale = mediaQuery.textScaler.scale(1);
              final responsiveScale =
                  systemScale * Responsive.textScaleFactor(context);
              return MediaQuery(
                data: mediaQuery.copyWith(
                  textScaler: TextScaler.linear(responsiveScale),
                ),
                child: child ?? const SizedBox.shrink(),
              );
            },
          );
        },
      ),
    );
  }
}
