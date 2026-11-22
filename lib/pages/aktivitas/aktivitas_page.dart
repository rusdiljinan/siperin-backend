import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async';
import '../../core/theme/app_colors.dart';
import '../../utils/responsive.dart';
import '../../providers/aktivitas_provider.dart';
import '../../utils/format_helper.dart';
import '../../widgets/loading_skeleton.dart';

class AktivitasPage extends StatefulWidget {
  const AktivitasPage({super.key});

  @override
  State<AktivitasPage> createState() => _AktivitasPageState();
}

class _AktivitasPageState extends State<AktivitasPage> {
  late Timer _refreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AktivitasProvider>().load();
    });

    // Refresh the UI every 10 seconds to update relative times
    _refreshTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AktivitasProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.load(),
      child: provider.loading
          ? ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Responsive.adaptivePadding(context),
              itemCount: 5,
              itemBuilder: (_, __) => const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LoadingSkeleton(height: 80),
              ),
            )
          : provider.error != null
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Responsive.adaptivePadding(context),
              children: [
                MaterialBanner(
                  content: Text(provider.error!),
                  leading: Icon(
                    Icons.error_outline,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => provider.load(),
                      child: const Text('Coba lagi'),
                    ),
                  ],
                ),
              ],
            )
          : provider.items.isEmpty
          ? ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Responsive.adaptivePadding(context),
              children: [
                SizedBox(height: MediaQuery.sizeOf(context).height * 0.2),
                Icon(
                  Icons.history,
                  size: 72,
                  color: Theme.of(context).colorScheme.outline,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Belum ada riwayat aktivitas',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Padding(
                  padding: Responsive.adaptivePadding(context),
                  child: const Text(
                    'Aktivitas login, CRUD inventaris, export, dan lainnya akan tercatat otomatis di sini.',
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            )
          : ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: Responsive.adaptivePadding(context),
              itemCount: provider.items.length,
              itemBuilder: (context, index) {
                final item = provider.items[index];
                final isLast = index == provider.items.length - 1;
                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Column(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: AppColors.paleGold,
                              size: 22,
                            ),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: AppColors.mediumGray,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 16),
                          child: Padding(
                            padding: Responsive.adaptivePadding(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.deskripsi,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 15,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 4,
                                  children: [
                                    Chip(
                                      label: Text(item.userName),
                                      visualDensity: VisualDensity.compact,
                                      avatar: const Icon(
                                        Icons.person,
                                        size: 16,
                                      ),
                                    ),
                                    Chip(
                                      label: Text(item.role.toUpperCase()),
                                      visualDensity: VisualDensity.compact,
                                      backgroundColor: AppColors.primary
                                          .withValues(alpha: 0.1),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  FormatHelper.relativeDateTime(item.waktu),
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
