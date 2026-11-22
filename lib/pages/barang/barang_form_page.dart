import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../utils/responsive.dart';
import '../../models/barang_model.dart';
import '../../services/barang_service.dart';
import 'barang_form_widget.dart';

class BarangFormPage extends StatefulWidget {
  final BarangModel? barang;
  final int? barangId;

  /// `true` jika halaman dibuka di luar [ShellRoute] (mis. dari detail inventaris).
  final bool standalone;

  const BarangFormPage({
    super.key,
    this.barang,
    this.barangId,
    this.standalone = false,
  });

  bool get isEdit => barang != null || barangId != null;

  @override
  State<BarangFormPage> createState() => _BarangFormPageState();
}

class _BarangFormPageState extends State<BarangFormPage> {
  BarangModel? _barang;
  bool _initializing = false;

  @override
  void initState() {
    super.initState();
    if (widget.barang != null) {
      _barang = widget.barang;
    } else if (widget.barangId != null) {
      _initializing = true;
      _loadBarang(widget.barangId!);
    }
  }

  Future<void> _loadBarang(int id) async {
    final service = context.read<BarangService>();
    final b = await service.getDetail(id);
    if (mounted) {
      setState(() {
        _barang = b;
        _initializing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final title = widget.isEdit ? 'Edit Inventaris' : 'Tambah Inventaris';

    if (_initializing) {
      if (!widget.standalone) {
        return const Center(child: CircularProgressIndicator());
      }
      return Scaffold(
        appBar: AppBar(
          title: Text(title),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/inventaris');
              }
            },
          ),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final form = BarangFormWidget(barang: _barang);

    if (!widget.standalone) {
      return form;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/inventaris');
            }
          },
        ),
      ),
      body: SingleChildScrollView(
        padding: Responsive.adaptivePadding(context),
        child: Center(
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: Responsive.contentMaxWidth(context),
            ),
            child: form,
          ),
        ),
      ),
    );
  }
}
