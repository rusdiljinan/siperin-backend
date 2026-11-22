import 'package:dio/dio.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/pages/users/user_management_page.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';

void main() {
  testWidgets(
    'role filter aligns on desktop, adapts on mobile, and filters users',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final api = ApiClient(StorageService());
      final rolesRequested = <String?>[];
      api.dio.interceptors.add(
        InterceptorsWrapper(
          onRequest: (options, handler) {
            rolesRequested.add(options.queryParameters['role'] as String?);
            handler.resolve(
              Response<dynamic>(
                requestOptions: options,
                statusCode: 200,
                data: {
                  'success': true,
                  'data': <dynamic>[],
                  'meta': {'current_page': 1, 'last_page': 1, 'total': 0},
                },
              ),
            );
          },
        ),
      );

      Future<void> pumpAt(Size size) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          Provider<ApiClient>.value(
            value: api,
            child: const MaterialApp(
              home: Scaffold(body: UserManagementPage()),
            ),
          ),
        );
        await tester.pumpAndSettle();
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpAt(const Size(1280, 900));
      final search = tester.getRect(find.byType(TextField));
      final role = tester.getRect(
        find.byType(DropdownButtonFormField<String?>),
      );
      expect(role.top, search.top);
      expect(role.height, search.height);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsOneWidget);

      final roleDropdown = find.byType(DropdownButtonFormField<String?>);
      final inputDecorator = find.descendant(
        of: roleDropdown,
        matching: find.byType(InputDecorator),
      );
      final idleBorder =
          tester
                  .widget<InputDecorator>(inputDecorator)
                  .decoration
                  .enabledBorder!
              as OutlineInputBorder;
      final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
      await mouse.addPointer(location: tester.getCenter(roleDropdown));
      await tester.pumpAndSettle();
      final hoverBorder =
          tester
                  .widget<InputDecorator>(inputDecorator)
                  .decoration
                  .enabledBorder!
              as OutlineInputBorder;
      expect(hoverBorder.borderSide.color, isNot(idleBorder.borderSide.color));
      await mouse.removePointer();

      await tester.tap(roleDropdown);
      await tester.pumpAndSettle();
      final focusedBorder =
          tester
                  .widget<InputDecorator>(inputDecorator)
                  .decoration
                  .focusedBorder!
              as OutlineInputBorder;
      expect(focusedBorder.borderSide.width, 2);
      await tester.tap(find.text('Admin').last);
      await tester.pumpAndSettle();
      expect(rolesRequested, [null, 'admin']);

      await pumpAt(const Size(390, 844));
      expect(tester.takeException(), isNull);
      final mobileSearch = tester.getRect(find.byType(TextField));
      final mobileRole = tester.getRect(
        find.byType(DropdownButtonFormField<String?>),
      );
      expect(mobileRole.top, greaterThan(mobileSearch.bottom));
      expect(mobileRole.left, greaterThanOrEqualTo(0));
      expect(mobileRole.right, lessThanOrEqualTo(390));
      expect(tester.takeException(), isNull);
    },
  );
}
