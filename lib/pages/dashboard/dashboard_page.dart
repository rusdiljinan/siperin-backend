import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/dashboard_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/inventory_chart.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/stat_card.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardProvider>().load();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<DashboardProvider>();
    final isDesktop = Responsive.isDesktop(context);
    final isCompactMobile = Responsive.isCompactMobile(context);

    if (provider.loading) {
      return const DashboardSkeleton();
    }

    if (provider.error != null) {
      return Center(
        child: Padding(
          padding: Responsive.adaptivePadding(context),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Theme.of(context).colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'Gagal memuat dashboard',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                provider.error ?? 'Kesalahan tidak diketahui',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => provider.load(),
                child: const Text('Coba Lagi'),
              ),
            ],
          ),
        ),
      );
    }

    if (provider.data == null) {
      return const DashboardSkeleton();
    }

    return SingleChildScrollView(
      padding: Responsive.adaptivePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildStatsGrid(context, provider, isDesktop, isCompactMobile),
              SizedBox(height: Responsive.spacing(context, desktop: 16)),
              Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  hoverColor: AppColors.primary.withValues(alpha: 0.08),
                  onTap: () => context.push('/laporan-inventaris'),
                  child: const ListTile(
                    leading: CircleAvatar(
                      child: Icon(Icons.description_outlined),
                    ),
                    title: Text('Laporan Inventaris'),
                    subtitle: Text(
                      'Lihat ringkasan, filter periode, dan ekspor laporan',
                    ),
                    trailing: Icon(Icons.chevron_right),
                  ),
                ),
              ),
              SizedBox(height: Responsive.spacing(context, desktop: 16)),
              Card(
                child: Padding(
                  padding: Responsive.adaptivePadding(context),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Jumlah Barang per Kondisi (${provider.data!.chartYear})',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      if (provider.data != null)
                        InventoryChart(data: provider.data!.chartData),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsGrid(
    BuildContext context,
    DashboardProvider provider,
    bool isDesktop,
    bool isCompactMobile,
  ) {
    final d = provider.data;
    if (d == null) {
      return const SizedBox.shrink();
    }
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final cards = [
      StatCard(
        title: 'Total Barang',
        value: '${d.totalBarang}',
        icon: Icons.inventory_2,
        color: AppColors.primary,
      ),
      StatCard(
        title: 'Barang Baik',
        value: '${d.barangBaik}',
        icon: Icons.check_circle_outline,
        color: isDark ? AppColors.darkSuccess : AppColors.success,
      ),
      StatCard(
        title: 'Barang Rusak',
        value: '${d.barangRusak}',
        icon: Icons.cancel_outlined,
        color: isDark ? AppColors.darkError : AppColors.error,
      ),
      StatCard(
        title: 'Perlu Perbaikan',
        value: '${d.barangPerbaikan}',
        icon: Icons.build_outlined,
        color: isDark ? AppColors.darkWarning : AppColors.warning,
      ),
    ];

    if (isDesktop) {
      return Row(children: cards.map((c) => Expanded(child: c)).toList());
    }

    if (isCompactMobile) {
      return Column(
        children: cards
            .map(
              (card) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: card,
              ),
            )
            .toList(),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: cards[0]),
            const SizedBox(width: 12),
            Expanded(child: cards[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: cards[2]),
            const SizedBox(width: 12),
            Expanded(child: cards[3]),
          ],
        ),
      ],
    );
  }
}
