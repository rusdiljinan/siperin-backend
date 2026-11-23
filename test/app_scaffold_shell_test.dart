import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inventaris_instansi/models/user_model.dart';
import 'package:inventaris_instansi/providers/auth_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/auth_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';
import 'package:inventaris_instansi/widgets/main_app_shell.dart';
import 'package:provider/provider.dart';

class _AdminAuthProvider extends AuthProvider {
  _AdminAuthProvider()
    : super(AuthService(ApiClient(StorageService()), StorageService()));

  @override
  UserModel? get user => UserModel(
    id: 1,
    name: 'Admin',
    username: 'admin',
    email: 'admin@example.test',
    role: 'admin',
  );
}

GoRouter _router() => GoRouter(
  initialLocation: '/dashboard',
  routes: [
    ShellRoute(
      builder: (_, __, child) => MainAppShell(child: child),
      routes: [
        GoRoute(
          path: '/dashboard',
          builder: (_, __) => const Scaffold(body: Text('Dashboard content')),
        ),
        GoRoute(
          path: '/inventaris',
          builder: (_, __) => const Scaffold(body: Text('Inventaris content')),
        ),
      ],
    ),
  ],
);

void main() {
  for (final (label, width) in [
    ('laptop', 1280.0),
    ('tablet', 800.0),
    ('mobile', 390.0),
  ]) {
    testWidgets('removes bottom navigation and retains sidebar on $label', (
      tester,
    ) async {
      tester.view.physicalSize = Size(width, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final router = _router();
      final auth = _AdminAuthProvider();
      addTearDown(router.dispose);
      addTearDown(auth.dispose);

      await tester.pumpWidget(
        ChangeNotifierProvider<AuthProvider>.value(
          value: auth,
          child: MaterialApp.router(routerConfig: router),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(NavigationBar), findsNothing);
      expect(find.byType(BottomNavigationBar), findsNothing);

      if (width >= 1024) {
        expect(find.text('Dashboard'), findsOneWidget);
        expect(find.text('Profile'), findsOneWidget);
      } else {
        await tester.tap(find.byIcon(Icons.menu).first);
        await tester.pumpAndSettle();
        expect(find.text('Inventaris'), findsOneWidget);
        await tester.tap(find.text('Inventaris'));
        await tester.pumpAndSettle();
        expect(router.routeInformationProvider.value.uri.path, '/inventaris');
        expect(find.text('Inventaris content'), findsOneWidget);
      }
    });
  }
}
