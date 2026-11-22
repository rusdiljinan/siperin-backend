import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../models/barang_model.dart';
import '../../providers/barang_provider.dart';
import '../../services/barang_service.dart';
import '../../utils/image_utils.dart';
import '../../utils/snackbar_helper.dart';
import '../../utils/validators.dart';
import '../../utils/responsive.dart';
import '../../widgets/barang_foto.dart';

class BarangFormWidget extends StatefulWidget {
  final BarangModel? barang;

  const BarangFormWidget({super.key, this.barang});

  bool get isEdit => barang != null;

  @override
  State<BarangFormWidget> createState() => _BarangFormWidgetState();
}

class _BarangFormWidgetState extends State<BarangFormWidget> {
  final _formKey = GlobalKey<FormState>();
  final _nama = TextEditingController();
  final _merek = TextEditingController();
  final _nomorSeri = TextEditingController();
  final _ukuran = TextEditingController();
  final _bahan = TextEditingController();
  final _tahun = TextEditingController();
  final _kode = TextEditingController();
  final _jumlah = TextEditingController(text: '1');
  final _harga = TextEditingController();
  final _keterangan = TextEditingController();
  String _kondisi = 'Baik';
  String _ruangan = AppConstants.ruanganList.first;
  String _kategori = AppConstants.kategoriBarang.first;
  DateTime? _tahunDate;
  XFile? _foto;
  Future<Uint8List>? _selectedFotoBytes;
  bool _loading = false;
  String? _uploadStatus;
  bool _removeExistingFoto = false;
  String? _existingFotoUrl;
  int? _kategoriId;
  Map<String, int> _kategoriIds = {};
  List<MapEntry<String, int>> _kategoriOptions = [];
  bool _kategoriLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.barang != null) _fillFromBarang(widget.barang!);
    _loadKategori();
  }

  Future<void> _loadKategori() async {
    try {
      final ids = await context.read<BarangService>().fetchKategori();
      if (!mounted) return;
      setState(() {
        _kategoriIds = ids;
        _kategoriOptions = AppConstants.kategoriBarang
            .map((name) => MapEntry(name, ids[name] ?? 0))
            .toList();
        for (final entry in ids.entries) {
          if (!_kategoriOptions.any((option) => option.key == entry.key)) {
            _kategoriOptions.add(MapEntry(entry.key, entry.value));
          }
        }
        _kategoriLoading = false;
        _kategoriId = widget.barang?.kategoriId ?? ids[_kategori];
        if (_kategoriId == null &&
            _kategoriOptions.any((option) => option.key == _kategori)) {
          _kategoriId = ids[_kategori];
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _kategoriLoading = false;
        _kategoriOptions = AppConstants.kategoriBarang
            .map((name) => MapEntry(name, 0))
            .toList();
        _kategoriIds = {};
        _kategoriId = null;
        _kategori = _kategoriOptions.first.key;
      });
    }
  }

  void _fillFromBarang(BarangModel b) {
    _nama.text = b.nama;
    _merek.text = b.merek ?? '';
    _nomorSeri.text = b.nomorSeri ?? '';
    _ukuran.text = b.ukuran ?? '';
    _bahan.text = b.bahan ?? '';
    _tahun.text = b.tahunPembelian.toString();
    _kode.text = b.kode;
    _jumlah.text = b.jumlah.toString();
    _harga.text = b.hargaBeli.toStringAsFixed(0);
    _keterangan.text = b.keterangan ?? '';
    _ruangan = b.ruangan.trim();
    _kategori = b.kategori.trim();
    _kategoriId = b.kategoriId;
    _kondisi = b.kondisi.trim();
    _tahunDate = DateTime(b.tahunPembelian);
    _existingFotoUrl = b.fotoUrl;
  }

  void _resetForm() {
    _formKey.currentState?.reset();
    _nama.clear();
    _merek.clear();
    _nomorSeri.clear();
    _ukuran.clear();
    _bahan.clear();
    _tahun.clear();
    _kode.clear();
    _jumlah.text = '1';
    _harga.clear();
    _keterangan.clear();
    _ruangan = AppConstants.ruanganList.first;
    _kategori = AppConstants.kategoriBarang.first;
    _kategoriId = null;
    // ✅ PERBAIKAN 1: Reset kondisi ke default
    _kondisi = 'Baik';
    _tahunDate = null;
    _foto = null;
    _selectedFotoBytes = null;
    _uploadStatus = null;
    _removeExistingFoto = false;
    _existingFotoUrl = null;
  }

  @override
  void dispose() {
    _nama.dispose();
    _merek.dispose();
    _nomorSeri.dispose();
    _ukuran.dispose();
    _bahan.dispose();
    _tahun.dispose();
    _kode.dispose();
    _jumlah.dispose();
    _harga.dispose();
    _keterangan.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = await ImageUtils.pickCompressed(source);
      if (file != null && mounted) {
        setState(() {
          _foto = file;
          _selectedFotoBytes = file.readAsBytes();
          _removeExistingFoto = false;
        });
      }
    } catch (error) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          message: source == ImageSource.camera
              ? 'Kamera tidak dapat digunakan. Silakan pilih foto dari galeri.'
              : 'Foto gagal dipilih: ${_errorMessage(error)}',
          isError: true,
        );
      }
    }
  }

  Future<void> _pickYear() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _tahunDate ?? DateTime.now(),
      firstDate: DateTime(1990),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() {
        _tahunDate = picked;
        _tahun.text = picked.year.toString();
      });
    }
  }

  Map<String, dynamic> _formData() {
    final data = <String, dynamic>{
      'nama_barang': _nama.text.trim(),
      'nama': _nama.text.trim(),
      'merek': _merek.text.trim(),
      'nomor_seri': _nomorSeri.text.trim(),
      'ukuran': _ukuran.text.trim(),
      'bahan': _bahan.text.trim(),
      'tahun_pembelian': int.parse(_tahun.text),
      'kode_barang': _kode.text.trim(),
      'kode': _kode.text.trim(),
      'jumlah_barang': int.parse(_jumlah.text),
      'jumlah': int.parse(_jumlah.text),
      'harga_beli': double.parse(_harga.text),
      'keterangan': _keterangan.text.trim(),
      'lokasi_ruangan': _ruangan,
      'ruangan': _ruangan,
      'kategori': _kategori,
      if (_kategoriId != null) 'kategori_id': _kategoriId,
      'status': 'Aktif',
    };

    if (widget.isEdit) {
      data['kondisi_barang'] = _kondisi;
    }

    return data;
  }

  String? _selectedKategoriName() {
    for (final option in _kategoriOptions) {
      if (option.value == _kategoriId) return option.key;
    }
    for (final option in _kategoriOptions) {
      if (option.key == _kategori) return option.key;
    }
    return null;
  }

  Future<void> _closeOnSuccess(String message) async {
    if (!mounted) return;
    SnackbarHelper.show(context, message: message);
    final canReturnToPreviousPage = context.canPop();
    if (canReturnToPreviousPage) {
      await context.read<BarangProvider>().load();
    }
    if (!mounted) return;

    try {
      // Jika kita bisa kembali (edit dibuka via push), lakukan pop sehingga
      // history tetap terjaga dan AppBar back button muncul kembali.
      if (canReturnToPreviousPage) {
        // Return true to the caller so it knows an update occurred.
        context.pop(true);
        return;
      }

      // Jika tidak bisa pop (mis. halaman edit dibuka langsung), fallback:
      // jika ini edit, arahkan ke detail barang (go -> reload), jika bukan ke list.
      if (widget.isEdit && widget.barang != null) {
        final id = widget.barang!.id;
        context.go('/inventaris/$id');
        return;
      }

      context.go('/inventaris');
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          message: 'Navigasi gagal: ${e.toString()}',
          isError: true,
        );
      }
    }
  }

  String _errorMessage(Object e) {
    return e
        .toString()
        .replaceFirst('Exception: ', '')
        .replaceFirst('Exception: ', '');
  }

  Future<void> _submit() async {
    if (_loading) return;

    if (widget.isEdit) {
      final updateCondition = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text('Konfirmasi Pembaruan Kondisi'),
          content: const Text('Apakah ingin memperbarui kondisi?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Iya'),
            ),
          ],
        ),
      );
      if (!mounted || updateCondition == null) return;

      if (updateCondition) {
        if (!_formKey.currentState!.validate()) return;
        await _openConditionAssessment();
        return;
      }
    } else if (!_formKey.currentState!.validate()) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(
          widget.isEdit ? 'Konfirmasi Simpan Perubahan' : 'Tambah Barang',
        ),
        content: Text(
          widget.isEdit
              ? 'Apakah Anda yakin ingin menyimpan perubahan data inventaris ini?'
              : 'Simpan barang baru ke inventaris?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _loading = true;
      _uploadStatus = _foto != null || _removeExistingFoto
          ? 'Mengunggah foto...'
          : 'Menyimpan data...';
    });

    final service = context.read<BarangService>();
    try {
      if (widget.isEdit && widget.barang != null) {
        await service.update(
          widget.barang!.id,
          _formData(),
          foto: _foto,
          removeFoto: _removeExistingFoto,
        );
        await _closeOnSuccess('Perubahan inventaris berhasil disimpan.');
      } else {
        await service.create(_formData(), foto: _foto);
        _resetForm();
        await _closeOnSuccess('Barang berhasil disimpan');
      }
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(context, message: _errorMessage(e), isError: true);
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
          _uploadStatus = null;
        });
      }
    }
  }

  Future<void> _openConditionAssessment() async {
    final barangId = widget.barang!.id;
    final form = _formData()
      ..['barang_id'] = barangId
      ..['id'] = barangId;
    final result = await context.push<bool>(
      '/inventaris/$barangId/nilai-ulang',
      extra: {
        'form': form,
        'foto': _foto,
        'removeFoto': _removeExistingFoto,
        'returnToEdit': true,
      },
    );

    if (result == true && mounted) {
      await _closeOnSuccess('Perubahan inventaris berhasil disimpan.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: Responsive.adaptivePadding(context),
      child: Center(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: Responsive.contentMaxWidth(context),
          ),
          child: Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 6,
            child: Padding(
              padding: Responsive.adaptivePadding(context),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_uploadStatus != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                _uploadStatus!,
                                style: const TextStyle(fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    _buildFotoPicker(),
                    const SizedBox(height: 16),
                    _row2(
                      TextFormField(
                        controller: _nama,
                        decoration: const InputDecoration(
                          labelText: 'Nama Barang *',
                        ),
                        validator: (v) =>
                            Validators.required(v, field: 'Nama barang'),
                      ),
                      TextFormField(
                        controller: _merek,
                        decoration: const InputDecoration(labelText: 'Merek'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _row2(
                      TextFormField(
                        controller: _nomorSeri,
                        decoration: const InputDecoration(
                          labelText: 'Nomor Seri',
                        ),
                      ),
                      TextFormField(
                        controller: _ukuran,
                        decoration: const InputDecoration(labelText: 'Ukuran'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _row2(
                      TextFormField(
                        controller: _bahan,
                        decoration: const InputDecoration(labelText: 'Bahan'),
                      ),
                      TextFormField(
                        controller: _kode,
                        decoration: const InputDecoration(
                          labelText: 'Kode Barang *',
                        ),
                        validator: (v) =>
                            Validators.required(v, field: 'Kode barang'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    _row2(
                      TextFormField(
                        controller: _tahun,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Tahun Pembelian *',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: _pickYear,
                          ),
                        ),
                        validator: Validators.year,
                        onTap: _pickYear,
                      ),
                      TextFormField(
                        controller: _jumlah,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah *',
                        ),
                        validator: (v) => Validators.number(v, field: 'Jumlah'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _harga,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Harga Beli (Rp) *',
                      ),
                      validator: (v) => Validators.number(v, field: 'Harga'),
                    ),
                    const SizedBox(height: 12),
                    _row2(
                      // Kondisi dihapus dari form — akan dihitung menggunakan RBS.
                      DropdownButtonFormField<String>(
                        key: ValueKey('ruangan_$_ruangan'),
                        decoration: const InputDecoration(labelText: 'Ruangan'),
                        items: (() {
                          final list = AppConstants.ruanganList
                              .map((s) => s.trim())
                              .toList();
                          final cur = _ruangan.trim();
                          if (cur.isNotEmpty && !list.contains(cur)) {
                            list.insert(0, cur);
                          }
                          return list
                              .map(
                                (r) =>
                                    DropdownMenuItem(value: r, child: Text(r)),
                              )
                              .toList();
                        })(),
                        initialValue: (() {
                          final list = AppConstants.ruanganList
                              .map((s) => s.trim())
                              .toList();
                          final cur = _ruangan.trim();
                          return list.contains(cur)
                              ? cur
                              : (list.isNotEmpty ? list.first : null);
                        })(),
                        onChanged: (v) => setState(() => _ruangan = v ?? ''),
                      ),
                      const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    _row2(
                      DropdownButtonFormField<String>(
                        key: ValueKey('kategori_$_kategori'),
                        decoration: const InputDecoration(
                          labelText: 'Kategori',
                          helperText: 'Pilih kategori dari data backend',
                        ),
                        items: _kategoriLoading
                            ? null
                            : _kategoriOptions
                                  .map(
                                    (option) => DropdownMenuItem(
                                      value: option.key,
                                      child: Text(option.key),
                                    ),
                                  )
                                  .toList(),
                        initialValue: _selectedKategoriName(),
                        onChanged: (v) => setState(() {
                          _kategori = v ?? '';
                          _kategoriId = _kategoriIds[_kategori];
                        }),
                        validator: (value) {
                          if (widget.isEdit) return null;
                          if (_kategoriLoading) {
                            return 'Daftar kategori sedang dimuat.';
                          }
                          if (_kategori.trim().isEmpty) {
                            return 'Silakan pilih kategori barang.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _keterangan,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Keterangan',
                      ),
                    ),
                    const SizedBox(height: 18),
                    SizedBox(
                      height: Responsive.buttonHeight(context),
                      child: ElevatedButton(
                        onPressed: _loading
                            ? null
                            : (widget.isEdit ? _submit : _nextStep),
                        child: _loading
                            ? SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onPrimary,
                                ),
                              )
                            : Text(
                                widget.isEdit
                                    ? 'Simpan Perubahan'
                                    : 'Lanjut ke Penilaian',
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFotoPicker() {
    return Column(
      children: [
        Container(
          height: 140,
          width: 140,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Theme.of(context).colorScheme.outline),
          ),
          child: _foto != null
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: FutureBuilder<Uint8List>(
                    future: _selectedFotoBytes,
                    builder: (context, snapshot) {
                      if (snapshot.hasError) {
                        return Icon(
                          Icons.broken_image_outlined,
                          size: 48,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        );
                      }
                      if (!snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      return Image.memory(
                        snapshot.data!,
                        width: 140,
                        height: 140,
                        fit: BoxFit.contain,
                      );
                    },
                  ),
                )
              : _existingFotoUrl != null && !_removeExistingFoto
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: BarangFoto(
                    barangId: widget.barang!.id,
                    fotoUrl: _existingFotoUrl,
                    service: context.read<BarangService>(),
                    width: 140,
                    height: 140,
                  ),
                )
              : Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_a_photo_outlined,
                      size: 42,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _removeExistingFoto
                          ? 'Foto akan dihapus'
                          : 'Belum ada foto barang',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
        ),
        const SizedBox(height: 4),
        Text(
          widget.isEdit
              ? 'Foto barang saat ini atau foto baru'
              : 'Foto dikompresi otomatis (max 800px)',
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          alignment: WrapAlignment.center,
          spacing: 8,
          runSpacing: 4,
          children: [
            TextButton.icon(
              onPressed: _loading ? null : () => _pickImage(ImageSource.camera),
              icon: const Icon(Icons.camera_alt),
              label: const Text('Kamera'),
            ),
            TextButton.icon(
              onPressed: _loading
                  ? null
                  : () => _pickImage(ImageSource.gallery),
              icon: const Icon(Icons.photo_library),
              label: const Text('Galeri'),
            ),
            if (_foto != null)
              TextButton.icon(
                onPressed: _loading
                    ? null
                    : () => setState(() {
                        _foto = null;
                        _selectedFotoBytes = null;
                      }),
                icon: const Icon(Icons.undo),
                label: const Text('Batalkan foto baru'),
              ),
            if (widget.isEdit &&
                (_existingFotoUrl != null || _removeExistingFoto))
              TextButton.icon(
                onPressed: _loading
                    ? null
                    : () {
                        setState(() {
                          _removeExistingFoto = !_removeExistingFoto;
                        });
                      },
                icon: const Icon(Icons.delete_outline),
                label: Text(
                  _removeExistingFoto ? 'Batalkan hapus' : 'Hapus foto',
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _row2(Widget left, Widget right) {
    return LayoutBuilder(
      builder: (context, c) {
        // Use tablet breakpoint (>=600) to switch to two-column layout.
        if (c.maxWidth >= 600) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: left),
              const SizedBox(width: 12),
              Expanded(child: right),
            ],
          );
        }
        return Column(children: [left, const SizedBox(height: 12), right]);
      },
    );
  }

  Future<void> _nextStep() async {
    if (_loading) return;
    if (!_formKey.currentState!.validate()) return;
    if (_kategori.trim().isEmpty) return;

    final data = _formData();
    setState(() => _loading = true);
    try {
      await context.push(
        '/inventaris/penilaian',
        extra: {'form': data, 'foto': _foto},
      );
    } catch (e) {
      if (mounted) {
        SnackbarHelper.show(
          context,
          message: 'Navigasi gagal: ${e.toString()}',
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}
