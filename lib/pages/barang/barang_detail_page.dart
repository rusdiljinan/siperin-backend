import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_colors.dart';
import '../../models/barang_history_model.dart';
import '../../models/barang_model.dart';
import '../../providers/barang_provider.dart';
import '../../services/barang_service.dart';
import '../../utils/format_helper.dart';
import '../../utils/responsive.dart';
import '../../utils/snackbar_helper.dart';
import '../../widgets/confirm_dialog.dart';
import '../../widgets/kondisi_badge.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/barang_foto.dart';

class BarangDetailPage extends StatefulWidget {
  final int barangId;
  final bool standalone;

  const BarangDetailPage({
    super.key,
    required this.barangId,
    this.standalone = false,
  });

  @override
  State<BarangDetailPage> createState() => _BarangDetailPageState();
}

class _BarangDetailPageState extends State<BarangDetailPage> {
  BarangModel? _barang;
  List<BarangHistoryModel> _history = [];
  bool _loading = true;
  bool _refreshing = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final (barang, history) = await _fetchDetail(widget.barangId);
      if (!mounted) return;
      setState(() {
        _barang = barang;
        _history = history;
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<(BarangModel, List<BarangHistoryModel>)> _fetchDetail(int id) async {
    final service = context.read<BarangService>();
    final results = await Future.wait<Object>([
      service.getDetail(id),
      service.getHistory(id),
    ]);
    return (results[0] as BarangModel, results[1] as List<BarangHistoryModel>);
  }

  Future<void> _refresh() async {
    if (_loading || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      final (barang, history) = await _fetchDetail(widget.barangId);
      if (!mounted) return;
      setState(() {
        _barang = barang;
        _history = history;
        _error = null;
      });
    } catch (error) {
      if (!mounted) return;
      SnackbarHelper.show(
        context,
        message:
            'Gagal memperbarui detail inventaris: ${error.toString().replaceFirst('Exception: ', '')}',
        isError: true,
      );
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  Widget _errorView(BuildContext context) => Center(
    child: Padding(
      padding: Responsive.adaptivePadding(context),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 48, color: AppColors.error),
          const SizedBox(height: 12),
          Text(
            _error ?? 'Barang tidak ditemukan.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
          ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    // Build content without Scaffold when embedded in ShellRoute so the
    // AppScaffoldShell provides the AppBar and navigation chrome.
    if (_loading) {
      if (widget.standalone) {
        return Scaffold(
          appBar: AppBar(title: const Text('Detail Inventaris')),
          body: Padding(
            padding: Responsive.adaptivePadding(context),
            child: const LoadingSkeleton(height: 300),
          ),
        );
      }
      return Padding(
        padding: Responsive.adaptivePadding(context),
        child: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null || _barang == null) {
      final errorView = _errorView(context);
      return widget.standalone
          ? Scaffold(
              appBar: AppBar(title: const Text('Detail Inventaris')),
              body: errorView,
            )
          : errorView;
    }

    final b = _barang!;

    final content = Responsive.withPullToRefresh(
      context,
      onRefresh: _refresh,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: Responsive.adaptivePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Responsive.refreshButton(
                    context,
                    loading: _refreshing,
                    onRefresh: _refresh,
                  ),
                ),
                Card(
                  child: Padding(
                    padding: Responsive.adaptivePadding(context),
                    child: LayoutBuilder(
                      builder: (context, c) {
                        final isWide = c.maxWidth > 600;
                        return isWide
                            ? Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(child: _fotoSection(b)),
                                  const SizedBox(width: 24),
                                  Expanded(flex: 2, child: _infoSection(b)),
                                ],
                              )
                            : Column(
                                children: [
                                  _fotoSection(b),
                                  const SizedBox(height: 20),
                                  _infoSection(b),
                                ],
                              );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: Responsive.adaptivePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Riwayat Perubahan',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        ..._history.map(
                          (h) => ListTile(
                            leading: const Icon(
                              Icons.history,
                              color: AppColors.primary,
                            ),
                            title: Text(h.perubahan),
                            subtitle: Text(
                              '${h.userName} • ${FormatHelper.dateTime(h.waktu)}',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    if (widget.standalone) {
      return Scaffold(
        appBar: AppBar(title: const Text('Detail Inventaris')),
        body: content,
      );
    }

    return content;
  }

  Widget _fotoSection(BarangModel b) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final imageSize = constraints.maxWidth.clamp(0.0, 320.0);
        return Column(
          children: [
            SizedBox(
              width: imageSize,
              child: AspectRatio(
                aspectRatio: 1,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: b.hasFoto && b.fotoUrl != null
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: BarangFoto(
                            barangId: b.id,
                            fotoUrl: b.fotoUrl,
                            service: context.read<BarangService>(),
                            width: imageSize,
                            height: imageSize,
                          ),
                        )
                      : Icon(
                          Icons.inventory_2,
                          size: 80,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _infoSection(BarangModel b) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          b.nama,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        KondisiBadge(kondisi: b.kondisi),
        const SizedBox(height: 16),
        _infoRow('Kode', b.kode),
        _infoRow('Merek', b.merek ?? '-'),
        _infoRow('Nomor Seri', b.nomorSeri ?? '-'),
        _infoRow('Ukuran', b.ukuran ?? '-'),
        _infoRow('Bahan', b.bahan ?? '-'),
        _infoRow('Ruangan', b.ruangan),
        _infoRow('Kategori', b.kategori),
        _infoRow('Tahun Pembelian', '${b.tahunPembelian}'),
        _infoRow('Jumlah', '${b.jumlah}'),
        _infoRow('Harga Beli', FormatHelper.currency(b.hargaBeli)),
        _infoRow('Status', b.status),
        _infoRow(
          'Keterangan',
          b.keterangan?.isNotEmpty == true ? b.keterangan! : '-',
        ),
        const SizedBox(height: 16),
        _buildActionButtons(b),
      ],
    );
  }

  Widget _buildActionButtons(BarangModel barang) => LayoutBuilder(
    builder: (context, constraints) {
      final edit = ElevatedButton.icon(
        onPressed: () => _edit(context, barang),
        icon: const Icon(Icons.edit_outlined),
        label: const Text('Edit'),
        style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
      );
      final delete = FilledButton.icon(
        onPressed: () => _delete(context, barang),
        icon: const Icon(Icons.delete_outline),
        label: const Text('Hapus'),
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
      );

      if (constraints.maxWidth < 320) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [edit, const SizedBox(height: 10), delete],
        );
      }

      return Row(
        children: [
          Expanded(child: edit),
          const SizedBox(width: 12),
          Expanded(child: delete),
        ],
      );
    },
  );

  Future<void> _edit(BuildContext context, BarangModel barang) async {
    final target = '/inventaris/${barang.id}/edit';
    try {
      final location = GoRouterState.of(context).uri.toString();
      if (location == target) return;

      final result = await context.push<bool?>(target);
      if (result != true || !mounted) return;

      final (updatedBarang, history) = await _fetchDetail(barang.id);
      if (!mounted) return;
      setState(() {
        _barang = updatedBarang;
        _history = history;
      });
    } catch (error) {
      if (!context.mounted) return;
      SnackbarHelper.show(
        context,
        message: 'Gagal membuka halaman edit: ${error.toString()}',
        isError: true,
      );
    }
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _delete(BuildContext context, BarangModel b) async {
    final ok = await showConfirmDialog(
      context,
      title: 'Hapus Barang',
      message:
          'Apakah Anda yakin ingin menghapus data "${b.nama}"?\nData akan dihapus permanen dari database.',
      confirmText: 'Ya, Hapus',
    );
    if (!context.mounted) return;
    if (ok != true) return;

    final success = await context.read<BarangProvider>().deleteBarang(b.id);
    if (!context.mounted) return;
    if (success) {
      SnackbarHelper.show(
        context,
        message: 'Barang berhasil dihapus dari database',
      );
      context.go('/inventaris');
    } else {
      final err =
          context.read<BarangProvider>().error ?? 'Gagal menghapus barang';
      SnackbarHelper.show(context, message: err, isError: true);
    }
  }
}
