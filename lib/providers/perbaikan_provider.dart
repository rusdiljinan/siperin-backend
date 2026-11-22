import 'package:flutter/foundation.dart';
import '../models/barang_model.dart';
import '../services/perbaikan_service.dart';

class PerbaikanProvider extends ChangeNotifier {
  final PerbaikanService _service;
  List<BarangModel> _items = [];
  bool _loading = false;
  String? _error;
  String _search = '';
  String? _ruangan;

  PerbaikanProvider(this._service);

  List<BarangModel> get items {
    if (_search.isEmpty) return _items;
    final q = _search.toLowerCase();
    return _items.where((b) {
      return b.nama.toLowerCase().contains(q) ||
          b.kode.toLowerCase().contains(q) ||
          b.ruangan.toLowerCase().contains(q);
    }).toList();
  }

  bool get loading => _loading;
  String? get error => _error;
  String? get ruangan => _ruangan;

  void setSearch(String value) {
    _search = value;
    notifyListeners();
  }

  void setRuangan(String? ruangan) {
    _ruangan = ruangan;
    notifyListeners();
  }

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.fetchPerbaikan(
        search: _search.isNotEmpty ? _search : null,
        ruangan: _ruangan,
      );
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _items = [];
    }
    _loading = false;
    notifyListeners();
  }
}
