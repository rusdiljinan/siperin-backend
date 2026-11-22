import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/dashboard_model.dart';
import 'package:inventaris_instansi/pages/dashboard/dashboard_page.dart';
import 'package:inventaris_instansi/providers/dashboard_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/dashboard_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';
import 'package:inventaris_instansi/widgets/inventory_chart.dart';
import 'package:inventaris_instansi/widgets/loading_skeleton.dart';
import 'package:provider/provider.dart';

class _PendingDashboardService extends DashboardService {
  _PendingDashboardService() : super(ApiClient(StorageService()));

  final List<Completer<DashboardModel>> requests = [];

  @override
  Future<DashboardModel> fetchDashboard() {
    final request = Completer<DashboardModel>();
    requests.add(request);
    return request.future;
  }
}

DashboardModel _dashboard() => DashboardModel(
  totalBarang: 7,
  barangBaik: 5,
  barangRusak: 2,
  barangPerbaikan: 1,
  chartYear: 2026,
  chartData: List.generate(
    12,
    (index) =>
        ChartDataPoint(label: 'Bulan $index', sangatBaik: 2, baik: 3, rusak: 1),
  ),
);

void main() {
  testWidgets('retry reloads the dashboard and renders returned data', (
    tester,
  ) async {
    final service = _PendingDashboardService();
    final provider = DashboardProvider(service);
    addTearDown(provider.dispose);

    await tester.pumpWidget(
      ChangeNotifierProvider<DashboardProvider>.value(
        value: provider,
        child: const MaterialApp(home: Scaffold(body: DashboardPage())),
      ),
    );
    await tester.pump();

    expect(service.requests, hasLength(1));
    expect(find.byType(DashboardSkeleton), findsOneWidget);
    service.requests[0].completeError(
      const DashboardLoadException('API tidak dapat dihubungi.'),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('API tidak dapat dihubungi.'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pump();

    expect(service.requests, hasLength(2));
    expect(provider.loading, isTrue);
    expect(find.byType(DashboardSkeleton), findsOneWidget);

    service.requests[1].complete(_dashboard());
    await tester.pump();
    await tester.pump();

    expect(find.text('Jumlah Barang per Kondisi (2026)'), findsOneWidget);
    expect(find.byType(InventoryChart), findsOneWidget);
    expect(find.text('7'), findsOneWidget);
    expect(provider.loading, isFalse);
    expect(provider.error, isNull);
  });
}
