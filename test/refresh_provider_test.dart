import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/aktivitas_model.dart';
import 'package:inventaris_instansi/models/barang_model.dart';
import 'package:inventaris_instansi/providers/aktivitas_provider.dart';
import 'package:inventaris_instansi/providers/perbaikan_provider.dart';
import 'package:inventaris_instansi/services/aktivitas_service.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/perbaikan_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';

class _PendingAktivitasService extends AktivitasService {
  _PendingAktivitasService() : super(ApiClient(StorageService()));

  final Completer<List<AktivitasModel>> response =
      Completer<List<AktivitasModel>>();
  int requestCount = 0;

  @override
  Future<List<AktivitasModel>> fetchAktivitas({int perPage = 100}) {
    requestCount++;
    return response.future;
  }
}

class _PendingPerbaikanService extends PerbaikanService {
  _PendingPerbaikanService() : super(ApiClient(StorageService()));

  final Completer<List<BarangModel>> response = Completer<List<BarangModel>>();
  int requestCount = 0;

  @override
  Future<List<BarangModel>> fetchPerbaikan({
    String? search,
    String? ruangan,
    String? kategori,
  }) {
    requestCount++;
    return response.future;
  }
}

void main() {
  test(
    'coalesces repeated activity refreshes into the active request',
    () async {
      final service = _PendingAktivitasService();
      final provider = AktivitasProvider(service);
      addTearDown(provider.dispose);

      final firstRequest = provider.load();
      final duplicateRequest = provider.load();

      expect(identical(firstRequest, duplicateRequest), isTrue);
      expect(service.requestCount, 1);
      expect(provider.loading, isTrue);

      service.response.complete([]);
      await firstRequest;
      expect(provider.loading, isFalse);
    },
  );

  test('coalesces repeated repair refreshes into the active request', () async {
    final service = _PendingPerbaikanService();
    final provider = PerbaikanProvider(service);
    addTearDown(provider.dispose);

    final firstRequest = provider.load();
    final duplicateRequest = provider.load();

    expect(identical(firstRequest, duplicateRequest), isTrue);
    expect(service.requestCount, 1);
    expect(provider.loading, isTrue);

    service.response.complete([]);
    await firstRequest;
    expect(provider.loading, isFalse);
  });
}
