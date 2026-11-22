import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inventaris_instansi/models/barang_model.dart';
import 'package:inventaris_instansi/pages/barang/barang_form_widget.dart';
import 'package:inventaris_instansi/pages/barang/barang_penilaian_edit_page.dart';
import 'package:inventaris_instansi/providers/barang_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/barang_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';
import 'package:provider/provider.dart';

class _MockBarangService extends BarangService {
  _MockBarangService() : super(ApiClient(StorageService()));

  final barang = BarangModel(
    id: 42,
    nama: 'Meja',
    kode: 'INV-42',
    tahunPembelian: 2024,
    jumlah: 2,
    hargaBeli: 150000,
    kondisi: 'Baik',
    ruangan: 'Ruang A',
    kategori: 'Elektronik',
    status: 'Aktif',
  );
  int? detailId;
  int? updatedId;
  int createCalls = 0;
  int updateCalls = 0;
  Completer<BarangModel>? updateCompleter;
  bool failUpdate = false;
  Map<String, dynamic>? updatedData;

  @override
  Future<BarangModel> getDetail(int id) async {
    detailId = id;
    return barang;
  }

  @override
  Future<BarangModel> update(
    int id,
    Map<String, dynamic> data, {
    String? fotoPath,
    XFile? foto,
    bool removeFoto = false,
  }) async {
    updateCalls++;
    updatedId = id;
    updatedData = data;
    if (failUpdate) throw Exception('update gagal');
    if (updateCompleter != null) return updateCompleter!.future;
    return barang;
  }

  @override
  Future<BarangModel> create(
    Map<String, dynamic> data, {
    String? fotoPath,
    XFile? foto,
  }) async {
    createCalls++;
    return barang;
  }

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
}

GoRouter _router(_MockBarangService service) => GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(
      path: '/',
      builder: (context, state) =>
          const Scaffold(body: Center(child: Text('Halaman sebelumnya'))),
    ),
    GoRoute(
      path: '/edit',
      builder: (context, state) =>
          Scaffold(body: BarangFormWidget(barang: service.barang)),
    ),
    GoRoute(
      path: '/inventaris/:id/nilai-ulang',
      builder: (context, state) {
        final extra = state.extra! as Map<String, dynamic>;
        return BarangPenilaianEditPage(
          barangId: int.parse(state.pathParameters['id']!),
          draftForm: extra['form'] as Map<String, dynamic>,
          foto: extra['foto'] as XFile?,
          removeFoto: extra['removeFoto'] as bool,
          returnToEdit: extra['returnToEdit'] as bool,
        );
      },
    ),
  ],
);

Widget _app(_MockBarangService service, GoRouter router) => MultiProvider(
  providers: [
    Provider<BarangService>.value(value: service),
    ChangeNotifierProvider<BarangProvider>(
      create: (_) => BarangProvider(service),
    ),
  ],
  child: MaterialApp.router(routerConfig: router),
);

Future<void> _openSaveButton(WidgetTester tester) async {
  final saveButton = find.text('Simpan Perubahan');
  await tester.ensureVisible(saveButton);
  await tester.tap(saveButton);
  await tester.pumpAndSettle();
}

Future<void> _openEditPage(WidgetTester tester, GoRouter router) async {
  router.push<void>('/edit').then((_) {});
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('No then Batal keeps the edit form without saving', (
    tester,
  ) async {
    final service = _MockBarangService();
    final router = _router(service);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await _openEditPage(tester, router);

    await _openSaveButton(tester);
    expect(find.text('Konfirmasi Pembaruan Kondisi'), findsOneWidget);
    expect(find.text('Apakah ingin memperbarui kondisi?'), findsOneWidget);

    await tester.tap(find.text('Tidak'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Simpan Perubahan'), findsOneWidget);
    expect(
      find.text(
        'Apakah Anda yakin ingin menyimpan perubahan data inventaris ini?',
      ),
      findsOneWidget,
    );

    await tester.tap(find.text('Batal'));
    await tester.pumpAndSettle();

    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(service.updatedId, isNull);
    expect(service.createCalls, 0);
  });

  testWidgets('No then Simpan updates the item without reassessing condition', (
    tester,
  ) async {
    final service = _MockBarangService();
    final router = _router(service);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await _openEditPage(tester, router);

    await _openSaveButton(tester);
    await tester.tap(find.text('Tidak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(service.updatedId, 42);
    expect(service.updatedData?['kondisi_barang'], 'Baik');
    expect(service.updatedData?.containsKey('total_score'), isFalse);
    expect(service.createCalls, 0);
    expect(
      find.text('Perubahan inventaris berhasil disimpan.'),
      findsOneWidget,
    );
    expect(router.routeInformationProvider.value.uri.path, '/');
  });

  testWidgets(
    'Iya assesses and updates the existing item with the edit draft',
    (tester) async {
      final service = _MockBarangService();
      final router = _router(service);
      addTearDown(router.dispose);
      await tester.pumpWidget(_app(service, router));
      await _openEditPage(tester, router);

      await tester.enterText(
        find.byType(TextFormField).first,
        'Meja diperbarui',
      );
      await _openSaveButton(tester);
      await tester.tap(find.text('Iya'));
      await tester.pumpAndSettle();

      expect(find.text('Kondisi Barang'), findsOneWidget);
      expect(service.detailId, 42);
      expect(service.updatedId, isNull);

      await tester.ensureVisible(find.text('Hitung & Simpan'));
      await tester.tap(find.text('Hitung & Simpan'));
      await tester.pumpAndSettle();
      expect(find.text('Hasil Kondisi'), findsOneWidget);

      await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
      await tester.pumpAndSettle();

      expect(service.updatedId, 42);
      expect(service.updatedData?['nama'], 'Meja diperbarui');
      expect(service.updatedData?['barang_id'], 42);
      expect(service.createCalls, 0);
      expect(router.routeInformationProvider.value.uri.path, '/');
    },
  );

  testWidgets('returning from assessment keeps the unsaved edit draft', (
    tester,
  ) async {
    final service = _MockBarangService();
    final router = _router(service);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await _openEditPage(tester, router);

    await tester.enterText(find.byType(TextFormField).first, 'Draft tetap ada');
    await _openSaveButton(tester);
    await tester.tap(find.text('Iya'));
    await tester.pumpAndSettle();
    final backButton = find.widgetWithText(TextButton, 'Kembali');
    await tester.ensureVisible(backButton);
    await tester.tap(backButton);
    await tester.pumpAndSettle();

    expect(find.text('Simpan Perubahan'), findsOneWidget);
    expect(
      tester
          .widget<TextFormField>(find.byType(TextFormField).first)
          .controller!
          .text,
      'Draft tetap ada',
    );
    expect(service.updatedId, isNull);
    expect(service.createCalls, 0);
  });

  testWidgets('failed assessment update stays on the form for retry', (
    tester,
  ) async {
    final service = _MockBarangService()..failUpdate = true;
    final router = _router(service);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await _openEditPage(tester, router);

    await _openSaveButton(tester);
    await tester.tap(find.text('Iya'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Hitung & Simpan'));
    await tester.tap(find.text('Hitung & Simpan'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Simpan'));
    await tester.pumpAndSettle();

    expect(find.text('Kondisi Barang'), findsOneWidget);
    expect(find.textContaining('update gagal'), findsOneWidget);
    expect(service.updatedId, 42);
    expect(service.createCalls, 0);
  });

  testWidgets('invalid edits are not saved after confirmation', (tester) async {
    final service = _MockBarangService();
    final router = _router(service);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await _openEditPage(tester, router);

    await tester.enterText(find.byType(TextFormField).first, '');
    await _openSaveButton(tester);
    await tester.tap(find.text('Tidak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pumpAndSettle();

    expect(service.updatedId, isNull);
    expect(service.createCalls, 0);
    expect(find.text('Konfirmasi Simpan Perubahan'), findsNothing);
  });

  testWidgets('repeated save taps do not submit duplicate updates', (
    tester,
  ) async {
    final service = _MockBarangService()
      ..updateCompleter = Completer<BarangModel>();
    final router = _router(service);
    addTearDown(router.dispose);
    await tester.pumpWidget(_app(service, router));
    await _openEditPage(tester, router);

    await _openSaveButton(tester);
    await tester.tap(find.text('Tidak'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Simpan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(service.updateCalls, 1);
    expect(find.text('Simpan Perubahan'), findsNothing);
    expect(find.byType(CircularProgressIndicator), findsWidgets);

    service.updateCompleter!.complete(service.barang);
    await tester.pumpAndSettle();
    expect(service.updateCalls, 1);
    expect(service.createCalls, 0);
  });
}
