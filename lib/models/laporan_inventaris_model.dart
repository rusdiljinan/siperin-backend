class LaporanInventarisModel {
  final String period;
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final DateTime generatedAt;
  final int totalEntries;
  final int totalQuantity;
  final double totalValue;
  final Map<String, ReportConditionCount> conditions;
  final List<LaporanInventarisItem> items;

  const LaporanInventarisModel({
    required this.period,
    required this.dateFrom,
    required this.dateTo,
    required this.generatedAt,
    required this.totalEntries,
    required this.totalQuantity,
    required this.totalValue,
    required this.conditions,
    required this.items,
  });

  factory LaporanInventarisModel.fromJson(Map<String, dynamic> json) {
    final summary = _asMap(json['summary'], 'summary');
    final rawConditions = _asMapOrEmpty(
      summary['conditions'],
      'summary.conditions',
    );
    final rawItems = json['items'];
    if (rawItems != null && rawItems is! List) {
      throw const FormatException('Field items laporan harus berupa daftar.');
    }

    return LaporanInventarisModel(
      period: json['period']?.toString() ?? 'custom',
      dateFrom: _asOptionalDate(json['date_from'], 'date_from'),
      dateTo: _asOptionalDate(json['date_to'], 'date_to'),
      generatedAt: DateTime.parse(json['generated_at'].toString()),
      totalEntries: _asInt(summary['total_entries']),
      totalQuantity: _asInt(summary['total_quantity']),
      totalValue: _asDouble(summary['total_value']),
      conditions: rawConditions.map(
        (key, value) => MapEntry(
          key,
          ReportConditionCount.fromJson(_asMap(value, 'conditions.$key')),
        ),
      ),
      items: (rawItems as List? ?? const [])
          .map(
            (item) => LaporanInventarisItem.fromJson(_asMap(item, 'items[]')),
          )
          .toList(),
    );
  }
}

class ReportConditionCount {
  final int entries;
  final int quantity;

  const ReportConditionCount({required this.entries, required this.quantity});

  factory ReportConditionCount.fromJson(Map<String, dynamic> json) =>
      ReportConditionCount(
        entries: _asInt(json['entries']),
        quantity: _asInt(json['quantity']),
      );
}

class LaporanInventarisItem {
  final int id;
  final String namaBarang;
  final String? merek;
  final String? nomorSeri;
  final String? ukuran;
  final String? bahan;
  final int tahunPembelian;
  final String kodeBarang;
  final int jumlahBarang;
  final double hargaBeli;
  final String kondisiBarang;
  final String? lokasiRuangan;
  final String? kategori;
  final String? keterangan;
  final String? status;
  final String? statusPerawatan;

  const LaporanInventarisItem({
    required this.id,
    required this.namaBarang,
    required this.merek,
    required this.nomorSeri,
    required this.ukuran,
    required this.bahan,
    required this.tahunPembelian,
    required this.kodeBarang,
    required this.jumlahBarang,
    required this.hargaBeli,
    required this.kondisiBarang,
    required this.lokasiRuangan,
    required this.kategori,
    required this.keterangan,
    required this.status,
    required this.statusPerawatan,
  });

  factory LaporanInventarisItem.fromJson(Map<String, dynamic> json) =>
      LaporanInventarisItem(
        id: _asInt(json['id']),
        namaBarang: json['nama_barang']?.toString() ?? '',
        merek: json['merek']?.toString(),
        nomorSeri: json['nomor_seri']?.toString(),
        ukuran: json['ukuran']?.toString(),
        bahan: json['bahan']?.toString(),
        tahunPembelian: _asInt(json['tahun_pembelian']),
        kodeBarang: json['kode_barang']?.toString() ?? '',
        jumlahBarang: _asInt(json['jumlah_barang']),
        hargaBeli: _asDouble(json['harga_beli']),
        kondisiBarang: json['kondisi_barang']?.toString() ?? '-',
        lokasiRuangan: json['lokasi_ruangan']?.toString(),
        kategori: json['kategori']?.toString(),
        keterangan: json['keterangan']?.toString(),
        status: json['status']?.toString(),
        statusPerawatan: json['status_perawatan']?.toString(),
      );
}

int _asInt(dynamic value) => (value as num?)?.toInt() ?? 0;

double _asDouble(dynamic value) => (value as num?)?.toDouble() ?? 0;

Map<String, dynamic> _asMap(dynamic value, String field) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  throw FormatException('Field $field laporan harus berupa objek.');
}

Map<String, dynamic> _asMapOrEmpty(dynamic value, String field) {
  if (value == null || (value is List && value.isEmpty)) {
    return <String, dynamic>{};
  }
  return _asMap(value, field);
}

DateTime? _asOptionalDate(dynamic value, String field) {
  if (value == null || value.toString().isEmpty) return null;
  try {
    return DateTime.parse(value.toString());
  } on FormatException {
    throw FormatException('Field $field laporan bukan tanggal yang valid.');
  }
}
