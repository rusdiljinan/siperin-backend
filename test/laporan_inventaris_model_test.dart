import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/laporan_inventaris_model.dart';

Map<String, dynamic> reportJson({required dynamic conditions}) => {
  'period': 'monthly',
  'date_from': '2026-10-01',
  'date_to': '2026-10-31',
  'generated_at': '2026-10-11T22:00:00+07:00',
  'summary': {
    'total_entries': 0,
    'total_quantity': 0,
    'total_value': 0,
    'conditions': conditions,
  },
  'items': [],
};

Map<String, dynamic> allReportJson() => {
  'period': 'all',
  'date_from': null,
  'date_to': null,
  'generated_at': '2026-10-11T22:00:00+07:00',
  'summary': {
    'total_entries': 0,
    'total_quantity': 0,
    'total_value': 0,
    'conditions': <String, dynamic>{},
  },
  'items': [
    {
      'id': 1,
      'nama_barang': 'Meja',
      'kode_barang': 'INV-001',
      'jumlah_barang': 4,
      'harga_beli': 150000,
      'kondisi_barang': 'Baik',
      'kategori': 'Perabot',
      'lokasi_ruangan': 'Ruang A',
      'status': 'Aktif',
      'status_perawatan': null,
    },
  ],
};

void main() {
  test('parses an empty report with an empty JSON object', () {
    final report = LaporanInventarisModel.fromJson(
      reportJson(conditions: <String, dynamic>{}),
    );

    expect(report.totalEntries, 0);
    expect(report.conditions, isEmpty);
    expect(report.items, isEmpty);
  });

  test('parses an empty report with an empty JSON list from the API', () {
    final report = LaporanInventarisModel.fromJson(
      reportJson(conditions: <dynamic>[]),
    );

    expect(report.totalEntries, 0);
    expect(report.conditions, isEmpty);
    expect(report.items, isEmpty);
  });

  test('rejects a non-empty list where the conditions map is expected', () {
    expect(
      () => LaporanInventarisModel.fromJson(
        reportJson(conditions: <dynamic>['unexpected']),
      ),
      throwsA(isA<FormatException>()),
    );
  });

  test('parses all-data report with optional dates and database columns', () {
    final report = LaporanInventarisModel.fromJson(allReportJson());

    expect(report.period, 'all');
    expect(report.dateFrom, isNull);
    expect(report.dateTo, isNull);
    expect(report.items.single.namaBarang, 'Meja');
    expect(report.items.single.kategori, 'Perabot');
    expect(report.items.single.lokasiRuangan, 'Ruang A');
    expect(report.items.single.status, 'Aktif');
    expect(report.items.single.statusPerawatan, isNull);
  });
}
