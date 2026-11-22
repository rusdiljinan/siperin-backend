import 'dart:typed_data';

import 'package:file_saver/file_saver.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../models/laporan_inventaris_model.dart';
import '../../services/laporan_inventaris_service.dart';
import '../../utils/format_helper.dart';
import '../../utils/responsive.dart';

class LaporanInventarisPage extends StatefulWidget {
  const LaporanInventarisPage({super.key});

  @override
  State<LaporanInventarisPage> createState() => _LaporanInventarisPageState();
}

class _LaporanInventarisPageState extends State<LaporanInventarisPage> {
  final _dateFormat = DateFormat('yyyy-MM-dd');
  String _period = 'all';
  DateTime _referenceDate = DateTime.now();
  DateTime? _startDate;
  DateTime? _endDate;
  Future<LaporanInventarisModel>? _reportFuture;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _startDate = DateTime(DateTime.now().year, DateTime.now().month);
    _endDate = DateTime(DateTime.now().year, DateTime.now().month + 1, 0);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadReport());
  }

  Map<String, dynamic> get _filters {
    if (_period == 'all') {
      return {'period': 'all'};
    }
    if (_period == 'custom') {
      return {
        'period': _period,
        'start_date': _dateFormat.format(_startDate!),
        'end_date': _dateFormat.format(_endDate!),
      };
    }
    return {
      'period': _period,
      'reference_date': _dateFormat.format(_referenceDate),
    };
  }

  Future<void> _loadReport() async {
    if (_period == 'custom') {
      if (_startDate == null || _endDate == null) {
        setState(() => _error = 'Tanggal mulai dan akhir wajib dipilih.');
        return;
      }
      if (_startDate!.isAfter(_endDate!)) {
        setState(
          () => _error = 'Tanggal mulai tidak boleh setelah tanggal akhir.',
        );
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
      _reportFuture = context.read<LaporanInventarisService>().fetchReport(
        _filters,
      );
    });
    try {
      await _reportFuture;
    } catch (error) {
      if (mounted) {
        setState(() => _error = _message(error));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _chooseDate({required bool isStart}) async {
    final initial = isStart
        ? (_startDate ?? DateTime.now())
        : (_endDate ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (date == null || !mounted) return;
    setState(() {
      if (isStart) {
        _startDate = date;
      } else {
        _endDate = date;
      }
    });
  }

  Future<void> _chooseReferenceDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _referenceDate,
      firstDate: DateTime(2000),
      lastDate: DateTime.now().add(const Duration(days: 366)),
    );
    if (date != null && mounted) setState(() => _referenceDate = date);
  }

  Future<void> _export(String format) async {
    setState(() => _loading = true);
    try {
      final bytes = await context.read<LaporanInventarisService>().export(
        format,
        _filters,
      );
      final suffix = _period == 'all'
          ? 'semua-data'
          : _period == 'monthly'
          ? DateFormat('yyyy-MM').format(_referenceDate)
          : _period == 'weekly'
          ? '${_dateFormat.format(_referenceDate)}_minggu'
          : '${_dateFormat.format(_startDate!)}_${_dateFormat.format(_endDate!)}';
      final Uint8List fileBytes = bytes;
      final fileName = 'laporan_inventaris_$suffix';
      final fileExtension = format == 'excel' ? 'xlsx' : 'pdf';
      final mimeType = format == 'excel'
          ? MimeType.microsoftExcel
          : MimeType.pdf;
      final savedPath = kIsWeb
          ? await FileSaver.instance.saveFile(
              name: fileName,
              bytes: fileBytes,
              fileExtension: fileExtension,
              mimeType: mimeType,
            )
          : await FileSaver.instance.saveAs(
              name: fileName,
              bytes: fileBytes,
              fileExtension: fileExtension,
              mimeType: mimeType,
            );
      if (savedPath == null || (kIsWeb && savedPath != 'Downloads')) {
        throw Exception('Penyimpanan file dibatalkan atau gagal.');
      }
      if (mounted) {
        _showMessage(
          kIsWeb
              ? 'Unduhan ${format == 'excel' ? 'Excel' : 'PDF'} dimulai.'
              : 'File ${format == 'excel' ? 'Excel' : 'PDF'} tersimpan: $savedPath',
        );
      }
    } catch (error) {
      if (mounted) _showMessage(_message(error), isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _message(Object error) =>
      error.toString().replaceFirst('Exception: ', '');

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<LaporanInventarisModel>(
      future: _reportFuture,
      builder: (context, snapshot) {
        final report = snapshot.data;
        return RefreshIndicator(
          onRefresh: _loadReport,
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: Responsive.adaptivePadding(context),
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/inventaris');
                    }
                  },
                  icon: const Icon(Icons.arrow_back),
                  label: const Text('Kembali'),
                ),
              ),
              const SizedBox(height: 12),
              _buildFilters(context),
              const SizedBox(height: 16),
              if (_loading && report == null)
                const Padding(
                  padding: EdgeInsets.all(36),
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (_error != null)
                _buildError(context)
              else if (snapshot.hasError)
                _buildError(context)
              else if (report != null) ...[
                _buildSummary(context, report),
                const SizedBox(height: 16),
                _buildExportActions(),
                const SizedBox(height: 16),
                _buildTable(context, report),
              ] else
                const SizedBox(height: 220),
            ],
          ),
        );
      },
    );
  }

  Widget _buildFilters(BuildContext context) {
    return Card(
      child: Padding(
        padding: Responsive.adaptivePadding(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Filter Laporan',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              initialValue: _period,
              decoration: const InputDecoration(
                labelText: 'Periode laporan',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('Semua data')),
                DropdownMenuItem(value: 'weekly', child: Text('Mingguan')),
                DropdownMenuItem(value: 'monthly', child: Text('Bulanan')),
                DropdownMenuItem(
                  value: 'custom',
                  child: Text('Rentang khusus'),
                ),
              ],
              onChanged: _loading
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() {
                        _period = value;
                        if (value == 'custom') {
                          _startDate = DateTime.now();
                          _endDate = DateTime.now();
                        }
                      });
                    },
            ),
            const SizedBox(height: 12),
            if (_period == 'custom')
              Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _chooseDate(isStart: true),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      'Mulai: ${_startDate == null ? '-' : FormatHelper.date(_startDate!)}',
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: _loading
                        ? null
                        : () => _chooseDate(isStart: false),
                    icon: const Icon(Icons.calendar_month),
                    label: Text(
                      'Akhir: ${_endDate == null ? '-' : FormatHelper.date(_endDate!)}',
                    ),
                  ),
                ],
              )
            else if (_period != 'all')
              OutlinedButton.icon(
                onPressed: _loading ? null : _chooseReferenceDate,
                icon: const Icon(Icons.event),
                label: Text(
                  'Tanggal acuan: ${FormatHelper.date(_referenceDate)}',
                ),
              ),
            if (_period == 'all')
              Text(
                'Menampilkan semua inventaris aktif tanpa batas tanggal.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: _loading ? null : _loadReport,
                icon: const Icon(Icons.analytics_outlined),
                label: const Text('Tampilkan Laporan'),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Filter mingguan, bulanan, dan rentang khusus memakai tanggal pencatatan barang (created_at), bukan tanggal pembelian.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(BuildContext context) {
    return Card(
      child: Padding(
        padding: Responsive.adaptivePadding(context),
        child: Column(
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 8),
            Text(
              _error ?? 'Gagal memuat laporan.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _loading ? null : _loadReport,
              icon: const Icon(Icons.refresh),
              label: const Text('Muat Ulang'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummary(BuildContext context, LaporanInventarisModel report) {
    final cards = <(String, String, IconData)>[
      ('Total entri inventaris', '${report.totalEntries}', Icons.inventory_2),
      ('Total kuantitas barang', '${report.totalQuantity}', Icons.numbers),
      (
        'Nilai inventaris',
        FormatHelper.currency(report.totalValue),
        Icons.payments_outlined,
      ),
    ];
    for (final condition in ['Sangat Baik', 'Baik', 'Rusak']) {
      final count = report.conditions[condition];
      cards.add((
        '$condition (entri)',
        '${count?.entries ?? 0}',
        Icons.check_circle_outline,
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          report.period == 'all'
              ? 'Ringkasan • Semua data inventaris'
              : 'Ringkasan • ${FormatHelper.date(report.dateFrom!)} – ${FormatHelper.date(report.dateTo!)}',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 900
                ? 3
                : constraints.maxWidth >= 560
                ? 2
                : 1;
            final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
            return Wrap(
              spacing: 12,
              runSpacing: 12,
              children: cards
                  .map(
                    (card) => SizedBox(
                      width: width,
                      child: _summaryCard(card.$1, card.$2, card.$3),
                    ),
                  )
                  .toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _summaryCard(String title, String value, IconData icon) => Card(
    child: Padding(
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );

  Widget _buildExportActions() => Wrap(
    spacing: 10,
    runSpacing: 8,
    children: [
      FilledButton.tonalIcon(
        onPressed: _loading ? null : () => _export('pdf'),
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Ekspor PDF'),
      ),
      FilledButton.tonalIcon(
        onPressed: _loading ? null : () => _export('excel'),
        icon: const Icon(Icons.table_chart),
        label: const Text('Ekspor Excel'),
      ),
      if (_loading)
        const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
    ],
  );

  Widget _buildTable(BuildContext context, LaporanInventarisModel report) {
    if (report.items.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(28),
          child: Center(
            child: Text('Tidak ada data inventaris pada periode ini.'),
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Data Inventaris (${report.items.length})',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                columns: const [
                  DataColumn(label: Text('No')),
                  DataColumn(label: Text('Nama barang')),
                  DataColumn(label: Text('Merek')),
                  DataColumn(label: Text('Nomor seri')),
                  DataColumn(label: Text('Ukuran')),
                  DataColumn(label: Text('Bahan')),
                  DataColumn(label: Text('Tahun')),
                  DataColumn(label: Text('Kode')),
                  DataColumn(label: Text('Jumlah'), numeric: true),
                  DataColumn(label: Text('Harga beli/unit'), numeric: true),
                  DataColumn(label: Text('Kondisi')),
                  DataColumn(label: Text('Kategori')),
                  DataColumn(label: Text('Lokasi')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Status perawatan')),
                  DataColumn(label: Text('Keterangan')),
                ],
                rows: [
                  for (var index = 0; index < report.items.length; index++)
                    _itemRow(index + 1, report.items[index]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DataRow _itemRow(int number, LaporanInventarisItem item) => DataRow(
    cells: [
      DataCell(Text('$number')),
      DataCell(Text(item.namaBarang)),
      DataCell(Text(item.merek ?? '-')),
      DataCell(Text(item.nomorSeri ?? '-')),
      DataCell(Text(item.ukuran ?? '-')),
      DataCell(Text(item.bahan ?? '-')),
      DataCell(Text('${item.tahunPembelian}')),
      DataCell(Text(item.kodeBarang)),
      DataCell(Text('${item.jumlahBarang}')),
      DataCell(Text(FormatHelper.currency(item.hargaBeli))),
      DataCell(Text(item.kondisiBarang)),
      DataCell(Text(item.kategori ?? '-')),
      DataCell(Text(item.lokasiRuangan ?? '-')),
      DataCell(Text(item.status ?? '-')),
      DataCell(Text(item.statusPerawatan ?? '-')),
      DataCell(
        Text(item.keterangan?.isNotEmpty == true ? item.keterangan! : '-'),
      ),
    ],
  );
}
