import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../models/barang_model.dart';
import '../../services/barang_service.dart';
import '../../utils/format_helper.dart';
import '../../utils/responsive.dart';
import '../../widgets/kondisi_badge.dart';
import '../../widgets/loading_skeleton.dart';
import '../../widgets/barang_foto.dart';

/// ✅ PERBAIKAN 2: Halaman Kondisi Barang
/// Menampilkan detail barang dengan fokus pada kondisi dan rule-based system scores
class KondisiBarangPage extends StatefulWidget {
  final int barangId;
  final bool standalone;

  const KondisiBarangPage({
    super.key,
    required this.barangId,
    this.standalone = false,
  });

  @override
  State<KondisiBarangPage> createState() => _KondisiBarangPageState();
}

class _KondisiBarangPageState extends State<KondisiBarangPage> {
  BarangModel? _barang;
  bool _loading = true;
  bool _refreshing = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final service = context.read<BarangService>();
    try {
      final barang = await service.getDetail(widget.barangId);
      if (mounted) {
        setState(() {
          _barang = barang;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    }
  }

  Future<void> _refresh() async {
    if (_loading || _refreshing) return;
    setState(() => _refreshing = true);
    try {
      final barang = await context.read<BarangService>().getDetail(
        widget.barangId,
      );
      if (mounted) setState(() => _barang = barang);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text('Gagal memperbarui data: $error')),
          );
      }
    } finally {
      if (mounted) setState(() => _refreshing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      if (widget.standalone) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Kondisi Barang'),
            leading: IconButton(
              icon: const Icon(Icons.arrow_back),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/perbaikan');
                }
              },
            ),
          ),
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

    if (_barang == null) {
      final content = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            const Text('Barang tidak ditemukan'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/perbaikan');
                }
              },
              child: const Text('Kembali'),
            ),
          ],
        ),
      );

      if (widget.standalone) {
        return Scaffold(
          appBar: AppBar(title: const Text('Kondisi Barang')),
          body: content,
        );
      }
      return content;
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
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Align(
                  alignment: Alignment.centerRight,
                  child: Responsive.refreshButton(
                    context,
                    loading: _refreshing,
                    onRefresh: _refresh,
                  ),
                ),
                // Foto Barang
                if (b.hasFoto && b.fotoUrl != null && b.fotoUrl!.isNotEmpty)
                  Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 280),
                      child: AspectRatio(
                        aspectRatio: 1,
                        child: Card(
                          margin: const EdgeInsets.only(bottom: 24),
                          elevation: 4,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          clipBehavior: Clip.antiAlias,
                          child: BarangFoto(
                            barangId: b.id,
                            fotoUrl: b.fotoUrl,
                            service: context.read<BarangService>(),
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Informasi Dasar Barang
                Text(
                  'Informasi Barang',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: Responsive.adaptivePadding(context),
                    child: Column(
                      children: [
                        _buildInfoRow('Nama Barang', b.nama),
                        _buildDivider(),
                        _buildInfoRow('Kode Barang', b.kode),
                        _buildDivider(),
                        _buildInfoRow('Kategori', b.kategori),
                        _buildDivider(),
                        _buildInfoRow('Ruangan', b.ruangan),
                        _buildDivider(),
                        _buildInfoRow(
                          'Tahun Pembelian',
                          b.tahunPembelian.toString(),
                        ),
                        _buildDivider(),
                        _buildInfoRow('Merek', b.merek ?? '-'),
                        _buildDivider(),
                        _buildInfoRow('Nomor Seri', b.nomorSeri ?? '-'),
                        _buildDivider(),
                        _buildInfoRow('Status Barang', b.status),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Kondisi Barang
                Text(
                  'Kondisi Barang',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: Responsive.adaptivePadding(context),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Status Kondisi:'),
                            KondisiBadge(kondisi: b.kondisi),
                          ],
                        ),
                        if (b.keterangan != null &&
                            b.keterangan!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          const Divider(),
                          const SizedBox(height: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Keterangan:',
                                style: TextStyle(fontWeight: FontWeight.w600),
                              ),
                              const SizedBox(height: 8),
                              Text(b.keterangan!),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Informasi Detail Teknis
                if (b.ukuran != null || b.bahan != null) ...[
                  Text(
                    'Detail Teknis',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: Padding(
                      padding: Responsive.adaptivePadding(context),
                      child: Column(
                        children: [
                          if (b.ukuran != null && b.ukuran!.isNotEmpty)
                            _buildInfoRow('Ukuran', b.ukuran!),
                          if (b.ukuran != null &&
                              b.ukuran!.isNotEmpty &&
                              (b.bahan != null && b.bahan!.isNotEmpty))
                            _buildDivider(),
                          if (b.bahan != null && b.bahan!.isNotEmpty)
                            _buildInfoRow('Bahan', b.bahan!),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                // Informasi Harga
                Text(
                  'Informasi Harga',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                Card(
                  child: Padding(
                    padding: Responsive.adaptivePadding(context),
                    child: Column(
                      children: [
                        _buildInfoRow(
                          'Harga Beli',
                          FormatHelper.currency(b.hargaBeli),
                        ),
                        _buildDivider(),
                        _buildInfoRow('Jumlah', '${b.jumlah} unit'),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Tombol Aksi
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ElevatedButton.icon(
                      onPressed: () {
                        context.go('/inventaris/${b.id}/edit');
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/perbaikan');
                        }
                      },
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Kembali'),
                    ),
                  ],
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );

    if (!widget.standalone) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Kondisi Barang'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/perbaikan');
            }
          },
        ),
      ),
      body: content,
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Divider(height: 1),
    );
  }
}
