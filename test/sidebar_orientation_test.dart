import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/user_model.dart';
import 'package:inventaris_instansi/providers/auth_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/auth_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';
import 'package:inventaris_instansi/widgets/app_sidebar.dart';
import 'package:provider/provider.dart';

class _LandscapeAuthProvider extends AuthProvider {
  _LandscapeAuthProvider()
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

void main() {
  testWidgets('keeps sidebar labels visible in tablet landscape', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 480);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _LandscapeAuthProvider(),
        child: const MaterialApp(
          home: Scaffold(body: AppSidebar(selectedIndex: 0, onLogout: _noop)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Inventaris'), findsOneWidget);
    expect(find.text('Perbaikan'), findsOneWidget);
  });

  testWidgets('keeps sidebar labels visible in tablet portrait', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _LandscapeAuthProvider(),
        child: const MaterialApp(
          home: Scaffold(body: AppSidebar(selectedIndex: 0, onLogout: _noop)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Dashboard'), findsOneWidget);
    expect(find.text('Inventaris'), findsOneWidget);
    expect(find.text('Perbaikan'), findsOneWidget);
  });
}

void _noop() {}
