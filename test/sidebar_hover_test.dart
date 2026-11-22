import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/core/theme/app_colors.dart';
import 'package:inventaris_instansi/models/user_model.dart';
import 'package:inventaris_instansi/providers/auth_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/auth_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';
import 'package:inventaris_instansi/widgets/app_sidebar.dart';
import 'package:provider/provider.dart';

class _TestAuthProvider extends AuthProvider {
  _TestAuthProvider()
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
  Future<void> buildSidebar(
    WidgetTester tester, {
    required int selectedIndex,
    required VoidCallback onLogout,
    required ValueChanged<int> onNavigate,
  }) async {
    tester.view.physicalSize = const Size(1200, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      ChangeNotifierProvider<AuthProvider>(
        create: (_) => _TestAuthProvider(),
        child: MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                AppSidebar(
                  selectedIndex: selectedIndex,
                  onLogout: onLogout,
                  onNavigate: onNavigate,
                ),
                const Expanded(child: SizedBox()),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Color? menuBackground(WidgetTester tester, String label) {
    final menu = find.text(label);
    final container = find.ancestor(
      of: menu,
      matching: find.byType(AnimatedContainer),
    );
    return tester.widget<AnimatedContainer>(container.first).decoration
            is BoxDecoration
        ? (tester.widget<AnimatedContainer>(container.first).decoration
                  as BoxDecoration)
              .color
        : null;
  }

  testWidgets('menu hover changes inactive color and click still navigates', (
    tester,
  ) async {
    var navigatedIndex = -1;
    var logoutCalls = 0;
    await buildSidebar(
      tester,
      selectedIndex: 0,
      onLogout: () => logoutCalls++,
      onNavigate: (index) => navigatedIndex = index,
    );

    expect(menuBackground(tester, 'Inventaris'), Colors.transparent);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Inventaris')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(
      menuBackground(tester, 'Inventaris'),
      AppColors.silk.withValues(alpha: 0.12),
    );
    expect(logoutCalls, 0);

    await tester.tap(find.text('Inventaris'));
    await tester.pumpAndSettle();
    expect(navigatedIndex, 1);
    expect(logoutCalls, 0);

    await mouse.removePointer();
  });

  testWidgets('active menu stays selected while hovered and after exit', (
    tester,
  ) async {
    var logoutCalls = 0;
    await buildSidebar(
      tester,
      selectedIndex: 0,
      onLogout: () => logoutCalls++,
      onNavigate: (_) {},
    );
    final activeColor = menuBackground(tester, 'Dashboard');
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(find.text('Dashboard')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(menuBackground(tester, 'Dashboard'), activeColor);
    expect(logoutCalls, 0);

    await mouse.moveTo(const Offset(1100, 800));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));
    expect(menuBackground(tester, 'Dashboard'), activeColor);

    await mouse.removePointer();
  });

  testWidgets('logout hover is visual only until tapped', (tester) async {
    var logoutCalls = 0;
    await buildSidebar(
      tester,
      selectedIndex: 0,
      onLogout: () => logoutCalls++,
      onNavigate: (_) {},
    );

    final logout = find.text('Logout');
    expect(logout, findsOneWidget);
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: tester.getCenter(logout));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 220));

    expect(logoutCalls, 0);
    await tester.tap(logout);
    await tester.pump();
    expect(logoutCalls, 1);
    await mouse.removePointer();
  });
}
