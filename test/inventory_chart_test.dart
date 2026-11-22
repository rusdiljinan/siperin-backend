import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/dashboard_model.dart';
import 'package:inventaris_instansi/widgets/inventory_chart.dart';

void main() {
  testWidgets(
    'shows all condition series without overflow on mobile and desktop',
    (tester) async {
      final data = List.generate(
        12,
        (index) => ChartDataPoint(
          label: 'B${index + 1}',
          sangatBaik: index + 1,
          baik: index,
          rusak: 0,
        ),
      );

      Future<void> pumpChart(Size size) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: InventoryChart(data: data),
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text('Sangat Baik'), findsOneWidget);
        expect(find.text('Baik'), findsOneWidget);
        expect(find.text('Rusak'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }

      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await pumpChart(const Size(360, 800));
      await pumpChart(const Size(1280, 900));
    },
  );
}
