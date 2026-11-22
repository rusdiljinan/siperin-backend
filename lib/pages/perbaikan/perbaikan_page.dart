import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../providers/perbaikan_provider.dart';
import '../../utils/responsive.dart';
import '../../widgets/kondisi_badge.dart';
import '../../widgets/loading_skeleton.dart';

class PerbaikanPage extends StatefulWidget {
  const PerbaikanPage({super.key});

  @override
  State<PerbaikanPage> createState() => _PerbaikanPageState();
}

class _PerbaikanPageState extends State<PerbaikanPage> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerbaikanProvider>().load();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PerbaikanProvider>();

    return RefreshIndicator(
      onRefresh: () => provider.load(),
      child: Column(
        children: [
          if (provider.error != null)
            Padding(
              padding: Responsive.adaptivePadding(context),
              child: MaterialBanner(
                content: Text(provider.error!),
                leading: Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                ),
                actions: [
                  TextButton(
                    onPressed: () => provider.load(),
                    child: const Text('Muat ulang'),
                  ),
                ],
              ),
            ),
          Padding(
            padding: Responsive.adaptivePadding(context),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(' ', style: Theme.of(context).textTheme.bodySmall),
            ),
          ),
          Padding(
            padding: Responsive.adaptivePadding(context),
            child: Wrap(
              spacing: 12,
              runSpacing: 12,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                SizedBox(
                  width: Responsive.isMobile(context) ? double.infinity : 280,
                  child: TextField(
                    controller: _searchController,
                    decoration: const InputDecoration(
                      hintText: 'Cari barang rusak...',
                      prefixIcon: Icon(Icons.search),
                      isDense: true,
                    ),
                    onChanged: provider.setSearch,
                  ),
                ),
                DropdownButton<String?>(
                  hint: const Text('Ruangan'),
                  value: provider.ruangan,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Text('Semua Ruangan'),
                    ),
                    ...AppConstants.ruanganList.map(
                      (r) => DropdownMenuItem(value: r, child: Text(r)),
                    ),
                  ],
                  onChanged: (v) async {
                    provider.setRuangan(v);
                    await provider.load();
                  },
                ),
                IconButton(
                  onPressed: () => provider.load(),
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Muat ulang',
                ),
              ],
            ),
          ),
          Expanded(
            child: provider.loading
                ? ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: Responsive.adaptivePadding(context),
                    itemCount: 5,
                    itemBuilder: (_, __) => const Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 6,
                      ),
                      child: LoadingSkeleton(height: 72),
                    ),
                  )
                : provider.items.isEmpty
                ? ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: Responsive.adaptivePadding(context),
                    children: [
                      SizedBox(
                        height: MediaQuery.sizeOf(context).height * 0.15,
                      ),
                      Icon(
                        Icons.build_circle_outlined,
                        size: 72,
                        color: AppColors.error.withValues(alpha: 0.6),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Tidak ada barang rusak',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Padding(
                        padding: Responsive.adaptivePadding(context),
                        child: const Text(
                          'Barang dengan kondisi Rusak dari inventaris akan muncul di sini secara otomatis.',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  )
                : Responsive.isDesktop(context)
                ? _buildTable(provider)
                : _buildCards(provider),
          ),
        ],
      ),
    );
  }

  Widget _buildTable(PerbaikanProvider provider) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Responsive.adaptivePadding(context),
      children: [
        Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: Card(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: Responsive.adaptivePadding(context),
                  child: DataTable(
                    columns: const [
                      DataColumn(label: Text('Kode')),
                      DataColumn(label: Text('Nama')),
                      DataColumn(label: Text('Ruangan')),
                      DataColumn(label: Text('Kondisi')),
                      DataColumn(label: Text('Status')),
                      DataColumn(
                        label: SizedBox(
                          width: 180,
                          child: Center(child: Text('Aksi')),
                        ),
                      ),
                    ],
                    rows: provider.items.map((b) {
                      return DataRow(
                        cells: [
                          DataCell(Text(b.kode)),
                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Text(
                                b.nama,
                                overflow: TextOverflow.ellipsis,
                                maxLines: 2,
                              ),
                            ),
                          ),
                          DataCell(Text(b.ruangan)),
                          DataCell(KondisiBadge(kondisi: b.kondisi)),
                          DataCell(Text(b.status)),
                          DataCell(
                            SizedBox(
                              width: 180,
                              child: Center(
                                child: FilledButton.icon(
                                  onPressed: () => context.push(
                                    '/inventaris/${b.id}/nilai-ulang',
                                  ),
                                  icon: const Icon(Icons.fact_check_outlined),
                                  label: const Text('Nilai Kondisi'),
                                  style: FilledButton.styleFrom(
                                    minimumSize: const Size(0, 40),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCards(PerbaikanProvider provider) {
    return ListView.builder(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Responsive.adaptivePadding(context),
      itemCount: provider.items.length,
      itemBuilder: (_, i) {
        final b = provider.items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => context.push('/inventaris/${b.id}/nilai-ulang'),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(
                        Icons.warning_amber_rounded,
                        color: AppColors.error,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.nama,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 4),
                            Text('${b.kode} • ${b.ruangan}'),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.spaceBetween,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    runSpacing: 8,
                    children: [
                      KondisiBadge(kondisi: b.kondisi),
                      FilledButton.icon(
                        onPressed: () =>
                            context.push('/inventaris/${b.id}/nilai-ulang'),
                        icon: const Icon(Icons.fact_check_outlined),
                        label: const Text('Nilai Kondisi'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 40),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
