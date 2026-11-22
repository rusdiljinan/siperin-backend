import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../models/barang_model.dart';
import '../../services/barang_service.dart';
import 'penilaian_kondisi_page.dart';

/// ✅ PERBAIKAN 2 (REVISED): Halaman Penilaian Kondisi untuk Barang Existing
/// Digunakan untuk update/menilai ulang kondisi barang yang sudah ada di database
/// Flow: Halaman Perbaikan → Detail Barang → Penilaian Kondisi
class BarangPenilaianEditPage extends StatefulWidget {
  final int barangId;
  final bool standalone;
  final Map<String, dynamic>? draftForm;
  final XFile? foto;
  final bool removeFoto;
  final bool returnToEdit;

  const BarangPenilaianEditPage({
    super.key,
    required this.barangId,
    this.standalone = false,
    this.draftForm,
    this.foto,
    this.removeFoto = false,
    this.returnToEdit = false,
  });

  @override
  State<BarangPenilaianEditPage> createState() =>
      _BarangPenilaianEditPageState();
}

class _BarangPenilaianEditPageState extends State<BarangPenilaianEditPage> {
  BarangModel? _barang;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBarang();
  }

  Future<void> _loadBarang() async {
    try {
      final service = context.read<BarangService>();
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

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Penilaian Kondisi Barang'),
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
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_barang == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Penilaian Kondisi Barang')),
        body: Center(
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
        ),
      );
    }

    // Prepare form data dari barang existing
    // ✅ FIX #2: Include barang_id sehingga PenilaianKondisiPage bisa update (bukan create)
    final form = <String, dynamic>{
      'barang_id': _barang!.id, // ← KUNCI untuk update
      'id': _barang!.id, // ← Backup untuk update method
      'nama': _barang!.nama,
      'kode': _barang!.kode,
      'jumlah': _barang!.jumlah,
      'kondisi': _barang!.kondisi,
      'ruangan': _barang!.ruangan,
      'kategori': _barang!.kategori,
      'merek': _barang!.merek,
      'nomor_seri': _barang!.nomorSeri,
      'ukuran': _barang!.ukuran,
      'bahan': _barang!.bahan,
      'tahun_pembelian': _barang!.tahunPembelian,
      'kode_barang': _barang!.kode,
      'harga_beli': _barang!.hargaBeli,
      'keterangan': _barang!.keterangan,
      ...?widget.draftForm,
    };
    form['barang_id'] = _barang!.id;
    form['id'] = _barang!.id;

    // Render PenilaianKondisiPage dengan form data barang existing
    return PenilaianKondisiPage(
      form: form,
      foto: widget.foto,
      removeFoto: widget.removeFoto,
      returnToEdit: widget.returnToEdit,
    );
  }
}
