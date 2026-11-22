import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/barang_model.dart';
import 'package:inventaris_instansi/pages/perbaikan/perbaikan_page.dart';
import 'package:inventaris_instansi/providers/perbaikan_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/perbaikan_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';
import 'package:provider/provider.dart';

class _PerbaikanTestService extends PerbaikanService {
  _PerbaikanTestService() : super(ApiClient(StorageService()));

  @override
  Future<List<BarangModel>> fetchPerbaikan({
    String? search,
    String? ruangan,
    String? kategori,
  }) async => [
    BarangModel(
      id: 1,
      nama: 'Meja Pemeriksaan',
      kode: 'INV-001',
      tahunPembelian: 2024,
      jumlah: 1,
      hargaBeli: 1000,
      kondisi: 'Rusak',
      ruangan: 'Ruang Uji',
      kategori: 'Perabot',
      status: 'Aktif',
    ),
  ];
}

Widget _app(_PerbaikanTestService service) => MultiProvider(
  key: ObjectKey(service),
  providers: [
    ChangeNotifierProvider<PerbaikanProvider>(
      create: (_) => PerbaikanProvider(service),
    ),
  ],
  child: MaterialApp(
    key: ObjectKey(service),
    home: const Scaffold(body: PerbaikanPage()),
  ),
);

void main() {
  testWidgets('keeps repair action visible and header centered responsively', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final size in [
      const Size(360, 800),
      const Size(430, 844),
      const Size(768, 900),
      const Size(1024, 900),
      const Size(1280, 900),
      const Size(1920, 1080),
    ]) {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      await tester.pumpWidget(_app(_PerbaikanTestService()));
      await tester.pumpAndSettle();

      expect(find.text('Nilai Kondisi'), findsOneWidget);
      if (size.width >= 1024) {
        final heading = tester.getRect(find.text('Aksi'));
        final actionButton = tester.getRect(
          find.ancestor(
            of: find.text('Nilai Kondisi'),
            matching: find.byWidgetPredicate(
              (widget) => widget is FilledButton,
            ),
          ),
        );
        expect(
          (heading.center.dx - actionButton.center.dx).abs(),
          lessThan(1),
          reason: 'Action heading should align with its button at $size',
        );
      }
      expect(tester.takeException(), isNull);
    }
  });
}
