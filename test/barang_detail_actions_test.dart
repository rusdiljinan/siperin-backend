import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inventaris_instansi/models/barang_history_model.dart';
import 'package:inventaris_instansi/models/barang_model.dart';
import 'package:inventaris_instansi/pages/barang/barang_detail_page.dart';
import 'package:inventaris_instansi/providers/barang_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/barang_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';
import 'package:provider/provider.dart';

class _DetailService extends BarangService {
  _DetailService() : super(ApiClient(StorageService()));

  final barang = BarangModel(
    id: 7,
    nama: 'Meja',
    kode: 'INV-007',
    tahunPembelian: 2024,
    jumlah: 2,
    hargaBeli: 150000,
    kondisi: 'Baik',
    ruangan: 'Ruang A',
    kategori: 'Perabot',
    status: 'Aktif',
    keterangan: 'Perlu diperiksa berkala',
  );
  int detailCalls = 0;
  int? deletedId;
  bool failFirstDetail = false;

  @override
  Future<BarangModel> getDetail(int id) async {
    detailCalls++;
    if (failFirstDetail) {
      failFirstDetail = false;
      throw Exception('Gagal memuat detail uji');
    }
    return barang;
  }

  @override
  Future<List<BarangHistoryModel>> getHistory(int id) async => [];

  @override
  Future<BarangPage> fetchBarang({
    String? search,
    String? kategori,
    String? kondisi,
    int page = 1,
    int perPage = 50,
    String sortBy = 'nama',
    bool ascending = true,
  }) async =>
      BarangPage(items: [barang], currentPage: 1, lastPage: 1, total: 1);

  @override
  Future<void> delete(int id) async {
    deletedId = id;
  }
}

GoRouter _router() => GoRouter(
  initialLocation: '/inventaris/7',
  routes: [
    GoRoute(
      path: '/inventaris/:id',
      builder: (context, state) => Scaffold(
        body: BarangDetailPage(
          barangId: int.parse(state.pathParameters['id']!),
        ),
      ),
    ),
    GoRoute(
      path: '/inventaris',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Daftar Inventaris'))),
    ),
    GoRoute(
      path: '/inventaris/:id/edit',
      builder: (context, state) => Scaffold(
        body: Center(
          child: FilledButton(
            onPressed: () => context.pop(true),
            child: const Text('Kembali dari Edit'),
          ),
        ),
      ),
    ),
  ],
);

Widget _app(_DetailService service, GoRouter router) => MultiProvider(
  providers: [
    Provider<BarangService>.value(value: service),
    ChangeNotifierProvider<BarangProvider>(
      create: (_) => BarangProvider(service),
    ),
  ],
  child: MaterialApp.router(routerConfig: router),
);

void main() {
  testWidgets('places matching Edit and Hapus actions after Keterangan', (
    tester,
  ) async {
    final service = _DetailService();
    final router = _router();
    addTearDown(router.dispose);

    for (final size in [const Size(390, 844), const Size(1280, 900)]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_app(service, router));
      await tester.pumpAndSettle();

      expect(find.text('Meja'), findsOneWidget);
      final keterangan = tester.getRect(find.text('Keterangan'));
      final edit = tester.getRect(
        find.ancestor(
          of: find.text('Edit'),
          matching: find.byWidgetPredicate(
            (widget) => widget is ButtonStyleButton,
          ),
        ),
      );
      final delete = tester.getRect(
        find.ancestor(
          of: find.text('Hapus'),
          matching: find.byWidgetPredicate(
            (widget) => widget is ButtonStyleButton,
          ),
        ),
      );
      expect(edit.top, greaterThan(keterangan.bottom));
      expect(delete.top, edit.top);
      expect(edit.height, 48);
      expect(delete.height, 48);
      expect(tester.takeException(), isNull);
    }

    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  });

  testWidgets('Edit navigates and Hapus confirms before deleting', (
    tester,
  ) async {
    final service = _DetailService();
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Edit'));
    await tester.pumpAndSettle();
    expect(find.text('Kembali dari Edit'), findsOneWidget);
    await tester.tap(find.text('Kembali dari Edit'));
    await tester.pumpAndSettle();
    expect(service.detailCalls, 2);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    expect(find.text('Hapus Barang'), findsOneWidget);
    expect(service.deletedId, isNull);

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();
    expect(service.deletedId, isNull);

    await tester.tap(find.text('Hapus'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ya, Hapus'));
    await tester.pumpAndSettle();
    expect(service.deletedId, 7);
    expect(find.text('Daftar Inventaris'), findsOneWidget);
  });

  testWidgets('detail load failure has an actionable retry', (tester) async {
    final service = _DetailService()..failFirstDetail = true;
    final router = _router();
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await tester.pumpAndSettle();

    expect(find.text('Gagal memuat detail uji'), findsOneWidget);
    await tester.tap(find.text('Coba Lagi'));
    await tester.pumpAndSettle();
    expect(find.text('Meja'), findsOneWidget);
    expect(service.detailCalls, 2);
  });
}
