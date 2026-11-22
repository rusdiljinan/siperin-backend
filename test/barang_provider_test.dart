import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/barang_model.dart';
import 'package:inventaris_instansi/providers/barang_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/barang_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';

class MockBarangService extends BarangService {
  MockBarangService(this.pages) : super(ApiClient(StorageService()));

  final Map<int, BarangPage> pages;
  final Map<int, Completer<BarangPage>> pendingPages = {};
  final List<int> requestedPages = [];

  @override
  Future<BarangPage> fetchBarang({
    String? search,
    String? kategori,
    String? kondisi,
    int page = 1,
    int perPage = 50,
    String sortBy = 'nama',
    bool ascending = true,
  }) {
    requestedPages.add(page);
    return pendingPages[page]?.future ??
        Future.value(
          pages[page] ??
              BarangPage(
                items: const [],
                currentPage: page,
                lastPage: page,
                total: 0,
              ),
        );
  }
}

BarangModel _barang(int id, String nama, String kode) {
  return BarangModel(
    id: id,
    nama: nama,
    kode: kode,
    tahunPembelian: 2024,
    jumlah: 1,
    hargaBeli: 1000,
    kondisi: 'Baik',
    ruangan: 'Ruang Uji',
    kategori: 'Elektronik',
    status: 'Aktif',
  );
}

void main() {
  test(
    'appends all server pages without duplicating inventory items',
    () async {
      final service = MockBarangService({
        1: BarangPage(
          items: [_barang(1, 'Zebra', 'B-02'), _barang(2, 'Alpha', 'A-01')],
          currentPage: 1,
          lastPage: 2,
          total: 3,
        ),
        2: BarangPage(
          items: [_barang(2, 'Alpha', 'A-01'), _barang(3, 'Beta', 'B-01')],
          currentPage: 2,
          lastPage: 2,
          total: 3,
        ),
      });
      final provider = BarangProvider(service);

      await provider.load();
      expect(provider.hasMore, isTrue);

      await provider.loadMore();

      expect(provider.items.map((item) => item.id), [2, 3, 1]);
      expect(provider.items.map((item) => item.id).toSet().length, 3);
      expect(provider.totalItems, 3);
      expect(provider.hasMore, isFalse);
      expect(service.requestedPages, [1, 2]);

      provider.dispose();
    },
  );

  test('does not request the same next page while it is loading', () async {
    final service = MockBarangService({
      1: BarangPage(
        items: [_barang(1, 'Alpha', 'A-01')],
        currentPage: 1,
        lastPage: 2,
        total: 2,
      ),
    });
    final pendingPage = Completer<BarangPage>();
    service.pendingPages[2] = pendingPage;
    final provider = BarangProvider(service);

    await provider.load();
    final firstLoad = provider.loadMore();
    final duplicateLoad = provider.loadMore();

    expect(service.requestedPages, [1, 2]);

    pendingPage.complete(
      BarangPage(
        items: [_barang(2, 'Beta', 'B-01')],
        currentPage: 2,
        lastPage: 2,
        total: 2,
      ),
    );
    await Future.wait([firstLoad, duplicateLoad]);

    expect(provider.items.map((item) => item.id), [1, 2]);
    expect(service.requestedPages, [1, 2]);

    provider.dispose();
  });
}
