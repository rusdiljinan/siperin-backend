import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/dashboard_model.dart';

void main() {
  test('parses all condition series and chart year from the API', () {
    final dashboard = DashboardModel.fromJson({
      'total_barang': 12,
      'barang_baik': 8,
      'barang_rusak': 4,
      'barang_perbaikan': 1,
      'chart_year': 2026,
      'chart': [
        {'label': 'Jan', 'sangat_baik': 10, 'baik': 8, 'rusak': 2},
        {'label': 'Feb', 'sangat_baik': 0, 'baik': 0, 'rusak': 0},
      ],
    });

    expect(dashboard.chartYear, 2026);
    expect(dashboard.chartData, hasLength(2));
    expect(dashboard.chartData.first.sangatBaik, 10);
    expect(dashboard.chartData.first.baik, 8);
    expect(dashboard.chartData.first.rusak, 2);
    expect(dashboard.chartData[1].sangatBaik, 0);
    expect(dashboard.chartData[1].baik, 0);
    expect(dashboard.chartData[1].rusak, 0);
  });
}
