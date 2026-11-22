import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/barang_model.dart';
import 'package:inventaris_instansi/models/user_model.dart';
import 'package:inventaris_instansi/pages/barang/barang_list_page.dart';
import 'package:inventaris_instansi/providers/auth_provider.dart';
import 'package:inventaris_instansi/providers/barang_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/auth_service.dart';
import 'package:inventaris_instansi/services/barang_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';
import 'package:provider/provider.dart';

class _BulkDeleteService extends BarangService {
  _BulkDeleteService({List<BarangModel>? items})
    : items = items ?? [_barang(1, 'Zebra'), _barang(2, 'Alpha')],
      super(ApiClient(StorageService()));

  final List<BarangModel> items;
  List<int>? deletedIds;
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
  }) async {
    requestedPages.add(page);
    final start = (page - 1) * perPage;
    return BarangPage(
      items: items.skip(start).take(perPage).toList(),
      currentPage: page,
      lastPage: (items.length / perPage).ceil().clamp(1, 999),
      total: items.length,
    );
  }

  @override
  Future<void> deleteMany(List<int> ids) async {
    deletedIds = List<int>.from(ids);
    items.removeWhere((barang) => ids.contains(barang.id));
  }
}

class _AdminAuthProvider extends AuthProvider {
  _AdminAuthProvider()
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

BarangModel _barang(int id, String nama) => BarangModel(
  id: id,
  nama: nama,
  kode: 'INV-${id.toString().padLeft(3, '0')}',
  tahunPembelian: 2024,
  jumlah: 1,
  hargaBeli: 1000,
  kondisi: 'Baik',
  ruangan: 'Ruang Uji',
  kategori: 'Perabot',
  status: 'Aktif',
);

Widget _app(_BulkDeleteService service) => MultiProvider(
  key: ObjectKey(service),
  providers: [
    Provider<BarangService>.value(value: service),
    ChangeNotifierProvider<BarangProvider>(
      create: (_) => BarangProvider(service),
    ),
    ChangeNotifierProvider<AuthProvider>.value(value: _AdminAuthProvider()),
  ],
  child: MaterialApp(
    key: ObjectKey(service),
    home: const Scaffold(body: BarangListPage()),
  ),
);

void main() {
  testWidgets('scrolling to the bottom loads and exposes later API pages', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;

    final service = _BulkDeleteService(
      items: List.generate(
        51,
        (index) => _barang(
          index + 1,
          'Item ${(index + 1).toString().padLeft(3, '0')}',
        ),
      ),
    );
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    final provider = Provider.of<BarangProvider>(
      tester.element(find.byType(BarangListPage)),
      listen: false,
    );
    expect(provider.items, hasLength(50));
    expect(service.requestedPages, [1]);

    await tester.drag(find.byType(ListView), const Offset(0, -10000));
    await tester.pumpAndSettle();

    expect(service.requestedPages, [1, 2]);
    expect(provider.items, hasLength(51));
    expect(find.text('Item 051'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('desktop mouse-wheel scrolling loads later API pages', (
    tester,
  ) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;

    final service = _BulkDeleteService(
      items: List.generate(
        51,
        (index) => _barang(
          index + 1,
          'Item ${(index + 1).toString().padLeft(3, '0')}',
        ),
      ),
    );
    await tester.pumpWidget(_app(service));
    await tester.pumpAndSettle();

    final list = find.byType(ListView);
    final listCenter = tester.getRect(list).center;
    await tester.sendEventToBinding(
      PointerScrollEvent(
        position: listCenter,
        scrollDelta: const Offset(0, 2000),
      ),
    );
    await tester.pumpAndSettle();

    expect(service.requestedPages, [1, 2]);
    expect(
      Provider.of<BarangProvider>(
        tester.element(find.byType(BarangListPage)),
        listen: false,
      ).items,
      hasLength(51),
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'admin can select and confirm exactly one item at mobile, tablet, and desktop widths',
    (tester) async {
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      for (final size in [
        const Size(360, 800),
        const Size(430, 844),
        const Size(768, 900),
        const Size(1280, 900),
        const Size(1920, 1080),
      ]) {
        final service = _BulkDeleteService();
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        await tester.pumpWidget(_app(service));
        await tester.pumpAndSettle();

        final isMobile = size.width <= 599;
        if (isMobile) {
          expect(find.byTooltip('Tambah inventaris'), findsOneWidget);
          expect(find.byIcon(Icons.add), findsOneWidget);
          expect(find.text('Tambah'), findsNothing);
        } else if (size.width >= 1024) {
          final searchRect = tester.getRect(find.byType(TextField));
          final filters = find.byWidgetPredicate(
            (widget) => widget is DropdownButton<String?>,
          );
          final categoryRect = tester.getRect(filters.at(0));
          final conditionRect = tester.getRect(filters.at(1));
          final addButton = find.ancestor(
            of: find.text('Tambah'),
            matching: find.byWidgetPredicate(
              (widget) => widget is ButtonStyleButton,
            ),
          );
          final deleteButton = find.ancestor(
            of: find.text('Hapus Terpilih (0)'),
            matching: find.byWidgetPredicate(
              (widget) => widget is ButtonStyleButton,
            ),
          );
          final addRect = tester.getRect(addButton);
          final deleteRect = tester.getRect(deleteButton);

          expect(categoryRect.center.dy, searchRect.center.dy);
          expect(conditionRect.center.dy, searchRect.center.dy);
          expect(addRect.center.dy, searchRect.center.dy);
          expect(deleteRect.center.dy, searchRect.center.dy);
          expect(addRect.left, greaterThan(conditionRect.right));
          expect(deleteRect.left, greaterThan(addRect.right));
        }

        final zebraCheckbox = find.byWidgetPredicate(
          (widget) =>
              widget is Checkbox && widget.semanticLabel == 'Pilih Zebra',
        );
        await tester.ensureVisible(zebraCheckbox);
        expect(
          tester.getSize(zebraCheckbox),
          const Size(48, 48),
          reason: 'Checkbox should have a touch-friendly target at $size',
        );
        final initialDeleteControl = isMobile
            ? find.byTooltip('Hapus Terpilih (0)')
            : find.text('Hapus Terpilih (0)');
        expect(initialDeleteControl, findsOneWidget);
        if (isMobile) {
          expect(find.text('Hapus Terpilih (0)'), findsNothing);
          expect(find.byIcon(Icons.delete_sweep_outlined), findsOneWidget);
          final addRect = tester.getRect(find.byTooltip('Tambah inventaris'));
          final deleteRect = tester.getRect(initialDeleteControl);
          expect(addRect.center.dy, deleteRect.center.dy);
          expect(deleteRect.left, greaterThan(addRect.right));
        }
        await tester.tap(initialDeleteControl);
        await tester.pumpAndSettle();
        expect(find.byType(AlertDialog), findsNothing);

        await tester.tap(zebraCheckbox);
        await tester.pumpAndSettle();
        final selectedDeleteControl = isMobile
            ? find.byTooltip('Hapus Terpilih (1)')
            : find.text('Hapus Terpilih (1)');
        expect(selectedDeleteControl, findsOneWidget);
        if (isMobile) {
          final addRect = tester.getRect(find.byTooltip('Tambah inventaris'));
          final deleteRect = tester.getRect(selectedDeleteControl);
          final cancelRect = tester.getRect(find.byTooltip('Batalkan pilihan'));
          expect(addRect.center.dy, deleteRect.center.dy);
          expect(deleteRect.center.dy, cancelRect.center.dy);
        }
        await tester.tap(selectedDeleteControl);
        await tester.pumpAndSettle();
        expect(find.textContaining('menghapus 1 barang'), findsOneWidget);

        await tester.tap(find.text('Ya, Hapus 1 Barang'));
        await tester.pumpAndSettle();

        expect(service.deletedIds, [1]);
        expect(find.text('Zebra'), findsNothing);
        expect(find.text('Alpha'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
    },
  );
}
