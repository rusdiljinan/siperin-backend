class DashboardModel {
  final int totalBarang;
  final int barangBaik;
  final int barangRusak;
  final int barangPerbaikan;
  final int chartYear;
  final List<ChartDataPoint> chartData;

  DashboardModel({
    required this.totalBarang,
    required this.barangBaik,
    required this.barangRusak,
    required this.barangPerbaikan,
    required this.chartYear,
    required this.chartData,
  });

  factory DashboardModel.fromJson(Map<String, dynamic> json) {
    final chart = (json['chart'] as List<dynamic>? ?? [])
        .map((e) => ChartDataPoint.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardModel(
      totalBarang: json['total_barang'] as int? ?? json['total'] as int? ?? 0,
      barangBaik: json['barang_baik'] as int? ?? 0,
      barangRusak: json['barang_rusak'] as int? ?? 0,
      barangPerbaikan: json['barang_perbaikan'] as int? ?? 0,
      chartYear: json['chart_year'] as int? ?? DateTime.now().year,
      chartData: chart,
    );
  }
}

class ChartDataPoint {
  final String label;
  final int sangatBaik;
  final int baik;
  final int rusak;

  ChartDataPoint({
    required this.label,
    required this.sangatBaik,
    required this.baik,
    required this.rusak,
  });

  factory ChartDataPoint.fromJson(Map<String, dynamic> json) {
    return ChartDataPoint(
      label: json['label']?.toString() ?? '',
      sangatBaik: (json['sangat_baik'] as num?)?.toInt() ?? 0,
      baik: (json['baik'] as num?)?.toInt() ?? 0,
      rusak: (json['rusak'] as num?)?.toInt() ?? 0,
    );
  }
}
