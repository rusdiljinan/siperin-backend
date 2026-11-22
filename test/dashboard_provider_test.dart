import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/dashboard_model.dart';
import 'package:inventaris_instansi/providers/dashboard_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/dashboard_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';

class MockDashboardService extends DashboardService {
  MockDashboardService() : super(ApiClient(StorageService()));

  final List<Completer<DashboardModel>> requests = [];

  int get requestCount => requests.length;

  @override
  Future<DashboardModel> fetchDashboard() {
    final request = Completer<DashboardModel>();
    requests.add(request);
    return request.future;
  }
}

DashboardModel _dashboard({required int total}) => DashboardModel(
  totalBarang: total,
  barangBaik: total,
  barangRusak: 0,
  barangPerbaikan: 0,
  chartYear: 2026,
  chartData: const [],
);

void main() {
  test('coalesces concurrent dashboard loads into one request', () async {
    final service = MockDashboardService();
    final provider = DashboardProvider(service);

    final firstLoad = provider.load();
    final duplicateLoad = provider.load();

    expect(service.requestCount, 1);
    expect(provider.loading, isTrue);

    service.requests.single.complete(_dashboard(total: 3));
    await Future.wait([firstLoad, duplicateLoad]);

    expect(provider.data?.totalBarang, 3);
    expect(provider.error, isNull);
    expect(provider.loading, isFalse);
    provider.dispose();
  });

  test(
    'retry sends a new request after a failure and updates dashboard data',
    () async {
      final service = MockDashboardService();
      final provider = DashboardProvider(service);

      final failedLoad = provider.load();
      service.requests[0].completeError(
        const DashboardLoadException('API tidak dapat dihubungi.'),
      );
      await failedLoad;

      expect(provider.error, 'API tidak dapat dihubungi.');
      expect(provider.loading, isFalse);

      final retry = provider.load();
      expect(service.requestCount, 2);
      expect(provider.error, isNull);
      expect(provider.loading, isTrue);

      service.requests[1].complete(_dashboard(total: 5));
      await retry;

      expect(provider.data?.totalBarang, 5);
      expect(provider.error, isNull);
      expect(provider.loading, isFalse);
      provider.dispose();
    },
  );
}
