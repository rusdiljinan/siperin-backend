import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import '../core/theme/app_colors.dart';
import '../models/dashboard_model.dart';

class InventoryChart extends StatelessWidget {
  final List<ChartDataPoint> data;

  const InventoryChart({super.key, required this.data});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    if (data.isEmpty) {
      return SizedBox(
        height: _getChartHeight(context),
        child: const Center(child: Text('Tidak ada data grafik')),
      );
    }

    final maxValue = data.fold<int>(0, (max, month) {
      final monthMax = [
        month.sangatBaik,
        month.baik,
        month.rusak,
      ].reduce((a, b) => a > b ? a : b);
      return monthMax > max ? monthMax : max;
    });

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: _getChartHeight(context),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final chartWidth = constraints.maxWidth > data.length * 62
                  ? constraints.maxWidth
                  : data.length * 62.0;
              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: SizedBox(
                  width: chartWidth,
                  child: BarChart(
                    BarChartData(
                      alignment: BarChartAlignment.spaceAround,
                      maxY: maxValue == 0 ? 10 : maxValue * 1.2,
                      barTouchData: BarTouchData(enabled: true),
                      titlesData: FlTitlesData(
                        show: true,
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= data.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 8),
                                child: Text(
                                  data[i].label,
                                  style: const TextStyle(fontSize: 11),
                                ),
                              );
                            },
                          ),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 32,
                            getTitlesWidget: (value, meta) => Text(
                              value.toInt().toString(),
                              style: TextStyle(
                                fontSize: 10,
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                      ),
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: colorScheme.outlineVariant.withValues(
                            alpha: 0.5,
                          ),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      barGroups: List.generate(data.length, (i) {
                        final month = data[i];
                        return BarChartGroupData(
                          x: i,
                          barsSpace: 3,
                          barRods: [
                            _bar(month.sangatBaik, 'Sangat Baik', isDark),
                            _bar(month.baik, 'Baik', isDark),
                            _bar(month.rusak, 'Rusak', isDark),
                          ],
                        );
                      }),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 16,
          runSpacing: 8,
          children: [
            _legendItem('Sangat Baik', isDark),
            _legendItem('Baik', isDark),
            _legendItem('Rusak', isDark),
          ],
        ),
      ],
    );
  }

  BarChartRodData _bar(int value, String kondisi, bool dark) => BarChartRodData(
    toY: value.toDouble(),
    color: AppColors.kondisiColor(kondisi, dark: dark),
    width: 12,
    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
  );

  Widget _legendItem(String kondisi, bool dark) => Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        width: 12,
        height: 12,
        decoration: BoxDecoration(
          color: AppColors.kondisiColor(kondisi, dark: dark),
          borderRadius: BorderRadius.circular(3),
        ),
      ),
      const SizedBox(width: 6),
      Text(kondisi, style: const TextStyle(fontSize: 12)),
    ],
  );

  double _getChartHeight(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    if (width < 600) {
      return 250;
    } else if (width < 1024) {
      return 300;
    } else {
      return 350;
    }
  }
}
