import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_colors.dart';
import '../../services/barang_service.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/responsive.dart';

class PenilaianKondisiPage extends StatefulWidget {
  final Map<String, dynamic> form;
  final XFile? foto;
  final bool removeFoto;
  final bool returnToEdit;

  const PenilaianKondisiPage({
    super.key,
    required this.form,
    this.foto,
    this.removeFoto = false,
    this.returnToEdit = false,
  });

  @override
  State<PenilaianKondisiPage> createState() => _PenilaianKondisiPageState();
}

class _PenilaianKondisiPageState extends State<PenilaianKondisiPage> {
  int kelengkapan = 3;
  int fungsional = 3;
  int fisik = 3;
  int usia = 3;
  int perawatan = 3;
  int keamanan = 3;
  bool _loading = false;

  int get totalScore =>
      kelengkapan + fungsional + fisik + usia + perawatan + keamanan;

  String _inferCondition(int total) {
    if (total >= 15) return 'Sangat Baik';
    if (total >= 10) return 'Baik';
    return 'Rusak';
  }

  Color _conditionColor(String kondisi) {
    return AppColors.kondisiColor(kondisi);
  }

  Widget _buildCriterion({
    required String title,
    required String desc,
    required int value,
    required Function(int?) onChanged,
    required List<Map<String, Object>> options,
  }) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Text(
              desc,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            ...options.map((opt) {
              final label = opt.keys.first;
              final val = opt.values.first as int;
              return RadioListTile<int>(
                value: val,
                groupValue: value,
                title: Text(label),
                onChanged: onChanged,
                dense: true,
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmAndSave() async {
    final total = totalScore;
    final kondisi = _inferCondition(total);

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hasil Kondisi'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.circle, size: 12, color: _conditionColor(kondisi)),
                const SizedBox(width: 8),
                Text(
                  'Kondisi: $kondisi',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 16,
                    color: _conditionColor(kondisi),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Total Nilai: $total',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Kembali'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (ok == true) await _saveToServer(kondisi, total);
  }

  Future<void> _saveToServer(String kondisi, int total) async {
    setState(() => _loading = true);
    try {
      final service = context.read<BarangService>();
      final payload = {
        ...widget.form,
        'kelengkapan_score': kelengkapan,
        'fungsional_score': fungsional,
        'fisik_score': fisik,
        'usia_score': usia,
        'perawatan_score': perawatan,
        'keamanan_score': keamanan,
        'total_score': total,
        'kondisi_barang': kondisi,
      };

      // ✅ FIX #3: Conditional logic - jika barang_id ada (update existing), jika tidak ada (create baru)
      final barangId = widget.form['barang_id'] ?? widget.form['id'];

      if (barangId != null && barangId > 0) {
        // Update existing barang
        await service.update(
          barangId as int,
          payload,
          foto: widget.foto,
          removeFoto: widget.removeFoto,
        );
        if (!mounted) return;
        if (widget.returnToEdit) {
          context.pop(true);
        } else {
          SnackbarHelper.show(
            context,
            message: 'Kondisi barang berhasil diperbarui',
          );
          try {
            context.go('/perbaikan');
          } catch (_) {
            context.pop();
          }
        }
      } else {
        // Create new barang (fallback untuk case baru)
        final created = await service.create(payload, foto: widget.foto);
        if (!mounted) return;
        SnackbarHelper.show(context, message: 'Barang berhasil disimpan');
        try {
          context.go('/inventaris/${created.id}');
        } catch (_) {
          context.go('/inventaris');
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, message: e.toString(), isError: true);
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = (totalScore - 6) / 12.0;

    return Scaffold(
      appBar: AppBar(title: const Text('Kondisi Barang')),
      body: SingleChildScrollView(
        padding: Responsive.adaptivePadding(context),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top progress indicator (visual feedback only)
              LinearProgressIndicator(
                value: progress.clamp(0.0, 1.0),
                minHeight: 6.0,
              ),
              const SizedBox(height: 12),
              Text(
                'Isi penilaian berikut untuk menentukan kondisi barang',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 12),
              _buildCriterion(
                title: 'Kelengkapan Inventaris',
                desc: 'Lengkap berarti seluruh komponen tersedia.',
                value: kelengkapan,
                onChanged: (v) => setState(() => kelengkapan = v ?? 3),
                options: const [
                  {'Lengkap (L)': 3},
                  {'Kurang Lengkap (KL)': 2},
                  {'Tidak Lengkap (TL)': 1},
                ],
              ),
              _buildCriterion(
                title: 'Fungsional Inventaris',
                desc: 'Berfungsi berarti normal.',
                value: fungsional,
                onChanged: (v) => setState(() => fungsional = v ?? 3),
                options: const [
                  {'Berfungsi (Bf)': 3},
                  {'Berfungsi Sebagian (BfS)': 2},
                  {'Tidak Berfungsi (TBf)': 1},
                ],
              ),
              _buildCriterion(
                title: 'Kesesuaian Fisik',
                desc: 'Bagus berarti fisik baik.',
                value: fisik,
                onChanged: (v) => setState(() => fisik = v ?? 3),
                options: const [
                  {'Bagus (Bs)': 3},
                  {'Kurang Bagus (KBs)': 2},
                  {'Tidak Bagus (TBs)': 1},
                ],
              ),
              _buildCriterion(
                title: 'Usia Pemakaian',
                desc: 'Baru = usia pemakaian rendah.',
                value: usia,
                onChanged: (v) => setState(() => usia = v ?? 3),
                options: const [
                  {'Baru (Br)': 3},
                  {'Sedang (S)': 2},
                  {'Lama (La)': 1},
                ],
              ),
              _buildCriterion(
                title: 'Riwayat Perawatan',
                desc: 'Terawat = rutin maintenance.',
                value: perawatan,
                onChanged: (v) => setState(() => perawatan = v ?? 3),
                options: const [
                  {'Terawat (T)': 3},
                  {'Jarang Dirawat (JR)': 2},
                  {'Tidak Dirawat (TR)': 1},
                ],
              ),
              _buildCriterion(
                title: 'Keamanan',
                desc: 'Aman = tidak berisiko.',
                value: keamanan,
                onChanged: (v) => setState(() => keamanan = v ?? 3),
                options: const [
                  {'Aman (A)': 3},
                  {'Kurang Aman (KA)': 2},
                  {'Tidak Aman (TA)': 1},
                ],
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _loading ? null : () => context.pop(),
                    child: const Text('Kembali'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _loading ? null : _confirmAndSave,
                    child: _loading
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Hitung & Simpan'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
