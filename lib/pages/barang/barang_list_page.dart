import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_colors.dart';
import '../../models/barang_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/barang_provider.dart';
import '../../services/barang_service.dart';
import '../../utils/responsive.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/kondisi_badge.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/barang_foto.dart';

class BarangListPage extends StatefulWidget {
  const BarangListPage({super.key});

  @override
  State<BarangListPage> createState() => _BarangListPageState();
}

class _BarangListPageState extends State<BarangListPage> {
  static const double _loadMoreThreshold = 320;

  final _searchController = TextEditingController();
  final Set<int> _selectedBarangIds = {};
  late final ScrollController _scrollController;
  bool _loadMoreCheckScheduled = false;

  @override
  void initState() {
    super.initState();
    // Create scroll controller using saved offset from provider so position
    // is preserved when returning from detail/edit pages.
    final provider = context.read<BarangProvider>();
    _scrollController = ScrollController(
      initialScrollOffset: provider.scrollOffset,
    );
    _scrollController.addListener(_handleScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<BarangProvider>();
      if (!provider.hasLoaded) unawaited(provider.load());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BarangProvider>();
    final useCardLayout = Responsive.isMobile(context);
    if (kDebugMode) {
      debugPrint(
        '[BarangListPage] build -> kategori=${provider.kategoriFilter} loading=${provider.loading} items=${provider.items.length}',
      );
    }
    if (provider.hasLoaded && provider.hasMore) {
      _scheduleLoadMoreCheck();
    }

    return Column(
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
                  onPressed: () {
                    _scrollToTop();
                    unawaited(provider.load());
                  },
                  child: const Text('Muat ulang'),
                ),
              ],
            ),
          ),
        _buildToolbar(context, provider),
        Expanded(
          child: Responsive.withPullToRefresh(
            context,
            onRefresh: () => _refresh(provider),
            child: provider.loading
                ? ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    itemCount: 6,
                    controller: _scrollController,
                    padding: Responsive.adaptivePadding(context),
                    itemBuilder: (ctx2, __) => Padding(
                      padding: Responsive.adaptivePadding(ctx2),
                      child: const LoadingSkeleton(height: 72),
                    ),
                  )
                : provider.items.isEmpty
                ? provider.hasMore
                      ? ListView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          controller: _scrollController,
                          children: const [
                            SizedBox(
                              height: 240,
                              child: Center(child: CircularProgressIndicator()),
                            ),
                          ],
                        )
                      : _buildEmptyList(context)
                : useCardLayout
                ? _buildCardList(context, provider)
                : _buildDesktopTable(context, provider),
          ),
        ),
        _buildLoadMoreFooter(provider),
      ],
    );
  }

  void _handleScroll() {
    if (!_scrollController.hasClients) return;

    final provider = context.read<BarangProvider>();
    provider.setScrollOffset(_scrollController.offset);
    if (_scrollController.position.extentAfter <= _loadMoreThreshold) {
      unawaited(provider.loadMore());
    }
  }

  void _scheduleLoadMoreCheck() {
    if (_loadMoreCheckScheduled) return;
    _loadMoreCheckScheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadMoreCheckScheduled = false;
      if (!mounted) return;

      final provider = context.read<BarangProvider>();
      if (!provider.hasMore ||
          provider.loading ||
          provider.loadingMore ||
          provider.error != null) {
        return;
      }

      if (provider.items.isEmpty ||
          !_scrollController.hasClients ||
          _scrollController.position.extentAfter <= _loadMoreThreshold) {
        unawaited(provider.loadMore());
      }
    });
  }

  void _scrollToTop() {
    if (_scrollController.hasClients) {
      _scrollController.jumpTo(0);
    }
  }

  Future<void> _refresh(BarangProvider provider) async {
    if (provider.loading || provider.loadingMore) return;
    _scrollToTop();
    await provider.load();
  }

  Widget _buildEmptyList(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) => ListView(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        SizedBox(
          height: constraints.maxHeight,
          child: _buildEmptyState(context),
        ),
      ],
    ),
  );

  Widget _buildLoadMoreFooter(BarangProvider provider) {
    return Padding(
      padding: Responsive.adaptivePadding(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            tooltip: 'Kembali ke atas',
            onPressed: _scrollToTop,
            icon: const Icon(Icons.chevron_left),
          ),
          Flexible(
            child: Text(
              'Menampilkan ${provider.items.length} dari ${provider.totalItems} barang',
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          IconButton(
            tooltip: 'Muat data berikutnya',
            onPressed: provider.hasMore && !provider.loadingMore
                ? () => unawaited(provider.loadMore())
                : null,
            icon: provider.loadingMore
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: Responsive.adaptivePadding(context),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 72,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 12),
            const Text(
              'Belum ada data inventaris',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Tambahkan item pertama ke inventaris',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: () => context.push('/inventaris/tambah'),
              icon: const Icon(Icons.add),
              label: const Text('Tambah Inventaris'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolbar(BuildContext context, BarangProvider provider) {
    final isMobile = Responsive.isMobile(context);
    final isTablet = Responsive.isTablet(context);
    final isDesktop = Responsive.isDesktop(context);
    final isAdmin = context.watch<AuthProvider>().user?.role == 'admin';

    final wrappedToolbar = Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        SizedBox(
          width: isTablet ? 240 : 320,
          child: TextField(
            controller: _searchController,
            decoration: const InputDecoration(
              hintText: 'Cari inventaris...',
              prefixIcon: Icon(Icons.search),
              isDense: true,
            ),
            onChanged: (value) {
              _scrollToTop();
              provider.setSearch(value);
            },
          ),
        ),
        SizedBox(
          width: 180,
          child: DropdownButton<String?>(
            value: provider.kategoriFilter,
            hint: const Text('Filter Kategori'),
            isExpanded: true,
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('Semua Kategori'),
              ),
              ...AppConstants.kategoriBarang.map(
                (k) => DropdownMenuItem(value: k, child: Text(k)),
              ),
            ],
            onChanged: (value) {
              _scrollToTop();
              provider.setKategori(value);
            },
          ),
        ),
        SizedBox(
          width: 140,
          child: DropdownButton<String?>(
            value: provider.kondisiFilter,
            hint: const Text('Filter Kondisi'),
            isExpanded: true,
            items: [
              const DropdownMenuItem(value: null, child: Text('Semua Kondisi')),
              ...AppConstants.kondisiBarang.map(
                (k) => DropdownMenuItem(value: k, child: Text(k)),
              ),
            ],
            onChanged: (value) {
              _scrollToTop();
              provider.setKondisi(value);
            },
          ),
        ),
        PopupMenuButton<String>(
          icon: const Icon(Icons.sort),
          tooltip: 'Urutkan',
          onSelected: (v) {
            final parts = v.split(':');
            _scrollToTop();
            provider.setSort(parts[0], parts[1] == 'asc');
          },
          itemBuilder: (_) => const [
            PopupMenuItem(value: 'nama:asc', child: Text('Nama A-Z')),
            PopupMenuItem(value: 'nama:desc', child: Text('Nama Z-A')),
            PopupMenuItem(value: 'kode:asc', child: Text('Kode A-Z')),
            PopupMenuItem(value: 'tahun:desc', child: Text('Tahun Terbaru')),
          ],
        ),
        Responsive.refreshButton(
          context,
          loading: provider.loading,
          onRefresh: () => _refresh(provider),
        ),
        FilledButton.icon(
          onPressed: () => context.push('/inventaris/tambah'),
          icon: const Icon(Icons.add, size: 18),
          label: const Text('Tambah'),
          style: FilledButton.styleFrom(minimumSize: const Size(0, 48)),
        ),
        if (isAdmin) _buildBulkDeleteControls(provider),
      ],
    );

    return Padding(
      padding: Responsive.adaptivePadding(context),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Cari inventaris...',
                    prefixIcon: Icon(Icons.search),
                    isDense: true,
                  ),
                  onChanged: (value) {
                    _scrollToTop();
                    provider.setSearch(value);
                  },
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButton<String?>(
                        value: provider.kategoriFilter,
                        hint: const Text('Kategori'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Semua Kategori'),
                          ),
                          ...AppConstants.kategoriBarang.map(
                            (k) => DropdownMenuItem(value: k, child: Text(k)),
                          ),
                        ],
                        onChanged: (value) {
                          _scrollToTop();
                          provider.setKategori(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: DropdownButton<String?>(
                        value: provider.kondisiFilter,
                        hint: const Text('Kondisi'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Semua Kondisi'),
                          ),
                          ...AppConstants.kondisiBarang.map(
                            (k) => DropdownMenuItem(value: k, child: Text(k)),
                          ),
                        ],
                        onChanged: (value) {
                          _scrollToTop();
                          provider.setKondisi(value);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Tooltip(
                      message: 'Tambah inventaris',
                      child: FilledButton(
                        onPressed: () => context.push('/inventaris/tambah'),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(48, 48),
                          padding: EdgeInsets.zero,
                        ),
                        child: const Icon(Icons.add, size: 22),
                      ),
                    ),
                    if (isAdmin) const SizedBox(width: 8),
                    if (isAdmin)
                      _buildBulkDeleteControls(provider, compact: true),
                  ],
                ),
              ],
            )
          : isDesktop
          ? LayoutBuilder(
              builder: (context, constraints) {
                if (constraints.maxWidth < 800) return wrappedToolbar;

                return Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          hintText: 'Cari inventaris...',
                          prefixIcon: Icon(Icons.search),
                          isDense: true,
                        ),
                        onChanged: (value) {
                          _scrollToTop();
                          provider.setSearch(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 180,
                      child: DropdownButton<String?>(
                        value: provider.kategoriFilter,
                        hint: const Text('Filter Kategori'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Semua Kategori'),
                          ),
                          ...AppConstants.kategoriBarang.map(
                            (k) => DropdownMenuItem(value: k, child: Text(k)),
                          ),
                        ],
                        onChanged: (value) {
                          _scrollToTop();
                          provider.setKategori(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 140,
                      child: DropdownButton<String?>(
                        value: provider.kondisiFilter,
                        hint: const Text('Filter Kondisi'),
                        isExpanded: true,
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('Semua Kondisi'),
                          ),
                          ...AppConstants.kondisiBarang.map(
                            (k) => DropdownMenuItem(value: k, child: Text(k)),
                          ),
                        ],
                        onChanged: (value) {
                          _scrollToTop();
                          provider.setKondisi(value);
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    PopupMenuButton<String>(
                      icon: const Icon(Icons.sort),
                      tooltip: 'Urutkan',
                      onSelected: (v) {
                        final parts = v.split(':');
                        _scrollToTop();
                        provider.setSort(parts[0], parts[1] == 'asc');
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(
                          value: 'nama:asc',
                          child: Text('Nama A-Z'),
                        ),
                        PopupMenuItem(
                          value: 'nama:desc',
                          child: Text('Nama Z-A'),
                        ),
                        PopupMenuItem(
                          value: 'kode:asc',
                          child: Text('Kode A-Z'),
                        ),
                        PopupMenuItem(
                          value: 'tahun:desc',
                          child: Text('Tahun Terbaru'),
                        ),
                      ],
                    ),
                    Responsive.refreshButton(
                      context,
                      loading: provider.loading,
                      onRefresh: () => _refresh(provider),
                    ),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      onPressed: () => context.push('/inventaris/tambah'),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Tambah'),
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                      ),
                    ),
                    if (isAdmin) const SizedBox(width: 8),
                    if (isAdmin) _buildBulkDeleteControls(provider),
                  ],
                );
              },
            )
          : wrappedToolbar,
    );
  }

  Widget _buildBulkDeleteControls(
    BarangProvider provider, {
    bool compact = false,
  }) {
    final count = _selectedBarangIds.length;
    if (compact) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Tooltip(
            message: 'Hapus Terpilih ($count)',
            child: FilledButton(
              onPressed: count == 0 ? null : () => _confirmBulkDelete(provider),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: AppColors.white,
                minimumSize: const Size(48, 48),
                padding: EdgeInsets.zero,
              ),
              child: const Icon(Icons.delete_sweep_outlined),
            ),
          ),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Tooltip(
              message: 'Batalkan pilihan',
              child: IconButton(
                onPressed: () => setState(_selectedBarangIds.clear),
                icon: const Icon(Icons.clear),
                constraints: const BoxConstraints.tightFor(
                  width: 48,
                  height: 48,
                ),
              ),
            ),
          ],
        ],
      );
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        FilledButton.icon(
          onPressed: count == 0 ? null : () => _confirmBulkDelete(provider),
          icon: const Icon(Icons.delete_sweep_outlined),
          label: Text('Hapus Terpilih ($count)'),
          style: FilledButton.styleFrom(
            backgroundColor: AppColors.error,
            foregroundColor: AppColors.white,
            minimumSize: const Size(0, 48),
          ),
        ),
        if (count > 0)
          OutlinedButton(
            onPressed: () => setState(_selectedBarangIds.clear),
            style: OutlinedButton.styleFrom(minimumSize: const Size(0, 48)),
            child: const Text('Batalkan pilihan'),
          ),
      ],
    );
  }

  Widget _buildDesktopTable(BuildContext context, BarangProvider provider) {
    final rows = provider.items
        .map((b) => _dataRow(context, b, provider))
        .toList();
    if (provider.hasMore) {
      rows.add(
        DataRow(
          cells: [
            DataCell(
              Center(
                child: provider.loadingMore
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const SizedBox(height: 20),
              ),
            ),
            ...List.generate(7, (_) => const DataCell(SizedBox.shrink())),
          ],
        ),
      );
    }

    return ListView(
      controller: _scrollController,
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
                    columnSpacing: 16,
                    headingRowColor: MaterialStateProperty.all(
                      Theme.of(context).colorScheme.primary.withOpacity(0.08),
                    ),
                    columns: const [
                      DataColumn(label: Text('Foto')),
                      DataColumn(label: Text('Nama')),
                      DataColumn(label: Text('Kode')),
                      DataColumn(label: Text('Ruangan')),
                      DataColumn(label: Text('Tahun')),
                      DataColumn(label: Text('Kondisi')),
                      DataColumn(label: Text('Status')),
                      DataColumn(label: Text('Aksi')),
                    ],
                    rows: rows,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  DataRow _dataRow(
    BuildContext context,
    BarangModel b,
    BarangProvider provider,
  ) {
    return DataRow(
      cells: [
        DataCell(_fotoThumb(b)),
        DataCell(
          SizedBox(
            width: 160,
            child: Text(b.nama, overflow: TextOverflow.ellipsis, maxLines: 2),
          ),
        ),
        DataCell(Text(b.kode)),
        DataCell(
          SizedBox(
            width: 120,
            child: Text(b.ruangan, overflow: TextOverflow.ellipsis),
          ),
        ),
        DataCell(Text('${b.tahunPembelian}')),
        DataCell(KondisiBadge(kondisi: b.kondisi)),
        DataCell(Text(b.status)),
        DataCell(_actionButtons(context, b, provider)),
      ],
    );
  }

  Widget _buildCardList(BuildContext context, BarangProvider provider) {
    return ListView.builder(
      controller: _scrollController,
      physics: const AlwaysScrollableScrollPhysics(),
      padding: Responsive.adaptivePadding(context),
      itemCount: provider.items.length + (provider.hasMore ? 1 : 0),
      itemBuilder: (_, i) {
        if (i == provider.items.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: provider.loadingMore
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const SizedBox(height: 24),
            ),
          );
        }

        final b = provider.items[i];
        return Card(
          margin: const EdgeInsets.only(bottom: 10),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _fotoThumb(b, size: 52),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        b.nama,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${b.kode} • ${b.ruangan}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          KondisiBadge(kondisi: b.kondisi),
                          Text(b.status, style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ],
                  ),
                ),
                if (context.watch<AuthProvider>().user?.role == 'admin')
                  _barangCheckbox(b),
                PopupMenuButton<String>(
                  onSelected: (v) => _handleAction(context, v, b, provider),
                  itemBuilder: (_) => const [
                    PopupMenuItem(value: 'detail', child: Text('Detail')),
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'hapus', child: Text('Hapus')),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _fotoThumb(BarangModel b, {double size = 40}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(8),
      child: SizedBox.square(
        dimension: size,
        child: ColoredBox(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          child: b.hasFoto && b.fotoUrl != null && b.fotoUrl!.isNotEmpty
              ? BarangFoto(
                  barangId: b.id,
                  fotoUrl: b.fotoUrl,
                  service: context.read<BarangService>(),
                  width: size,
                  height: size,
                )
              : Icon(
                  Icons.image,
                  size: size * 0.5,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
        ),
      ),
    );
  }

  Widget _actionButtons(
    BuildContext context,
    BarangModel b,
    BarangProvider provider,
  ) {
    final isAdmin = context.watch<AuthProvider>().user?.role == 'admin';
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isAdmin) _barangCheckbox(b),
        IconButton(
          icon: const Icon(Icons.visibility_outlined, size: 20),
          tooltip: 'Detail',
          onPressed: () {
            final target = '/inventaris/${b.id}';
            try {
              final loc = GoRouterState.of(context).uri.toString();
              if (loc != target) context.push(target);
            } catch (e) {
              SnackbarHelper.show(
                context,
                message: 'Gagal membuka halaman detail: ${e.toString()}',
                isError: true,
              );
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.edit_outlined, size: 20),
          tooltip: 'Edit',
          onPressed: () {
            final target = '/inventaris/${b.id}/edit';
            try {
              final loc = GoRouterState.of(context).uri.toString();
              if (loc != target) context.push(target);
            } catch (e) {
              SnackbarHelper.show(
                context,
                message: 'Gagal membuka halaman edit: ${e.toString()}',
                isError: true,
              );
            }
          },
        ),
        IconButton(
          icon: Icon(
            Icons.delete_outline,
            size: 20,
            color: Theme.of(context).colorScheme.error,
          ),
          tooltip: 'Hapus',
          onPressed: () => _confirmDelete(context, b, provider),
        ),
      ],
    );
  }

  Widget _barangCheckbox(BarangModel barang) {
    return SizedBox(
      width: 48,
      height: 48,
      child: Checkbox(
        value: _selectedBarangIds.contains(barang.id),
        onChanged: (selected) {
          setState(() {
            if (selected == true) {
              _selectedBarangIds.add(barang.id);
            } else {
              _selectedBarangIds.remove(barang.id);
            }
          });
        },
        semanticLabel: 'Pilih ${barang.nama}',
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    String action,
    BarangModel b,
    BarangProvider provider,
  ) {
    switch (action) {
      case 'detail':
        try {
          final target = '/inventaris/${b.id}';
          final loc = GoRouterState.of(context).uri.toString();
          if (loc != target) context.push(target);
        } catch (e) {
          SnackbarHelper.show(
            context,
            message: 'Gagal membuka halaman detail: ${e.toString()}',
            isError: true,
          );
        }
        break;
      case 'edit':
        try {
          final target = '/inventaris/${b.id}/edit';
          final loc = GoRouterState.of(context).uri.toString();
          if (loc != target) context.push(target);
        } catch (e) {
          SnackbarHelper.show(
            context,
            message: 'Gagal membuka halaman edit: ${e.toString()}',
            isError: true,
          );
        }
        break;
      case 'hapus':
        _confirmDelete(context, b, provider);
        break;
    }
  }

  Future<void> _confirmDelete(
    BuildContext context,
    BarangModel b,
    BarangProvider provider,
  ) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus Inventaris',
      message:
          'Apakah Anda yakin ingin menghapus "${b.nama}"?\nData akan dihapus permanen dari database.',
      confirmText: 'Ya, Hapus',
    );
    if (!context.mounted) return;
    if (ok != true) return;

    final success = await provider.deleteBarang(b.id);
    if (!context.mounted) return;
    if (success) {
      SnackbarHelper.show(
        context,
        message: 'Inventaris berhasil dihapus dari database',
      );
    } else {
      SnackbarHelper.show(
        context,
        message: provider.error ?? 'Gagal menghapus barang',
        isError: true,
      );
    }
  }

  Future<void> _confirmBulkDelete(BarangProvider provider) async {
    final ids = _selectedBarangIds.toList(growable: false);
    if (ids.isEmpty || context.read<AuthProvider>().user?.role != 'admin') {
      return;
    }

    final ok = await showConfirmDialog(
      context,
      title: 'Hapus Inventaris Terpilih',
      message:
          'Apakah Anda yakin ingin menghapus ${ids.length} barang yang dipilih? Data akan dihapus permanen dari database.',
      confirmText: 'Ya, Hapus ${ids.length} Barang',
    );
    if (!mounted || ok != true) return;

    final success = await provider.deleteBarangMany(ids);
    if (!mounted) return;
    if (success) {
      setState(_selectedBarangIds.clear);
      SnackbarHelper.show(
        context,
        message: '${ids.length} barang berhasil dihapus dari database',
      );
    } else {
      SnackbarHelper.show(
        context,
        message: provider.error ?? 'Gagal menghapus barang terpilih',
        isError: true,
      );
    }
  }
}
