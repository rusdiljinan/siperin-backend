import 'package:flutter/foundation.dart';
import '../models/aktivitas_model.dart';
import '../services/aktivitas_service.dart';

class AktivitasProvider extends ChangeNotifier {
  final AktivitasService _service;
  List<AktivitasModel> _items = [];
  bool _loading = false;
  String? _error;

  AktivitasProvider(this._service);

  List<AktivitasModel> get items => _items;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _items = await _service.fetchAktivitas(perPage: 100);
      _items.sort((a, b) => b.waktu.compareTo(a.waktu));
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _items = [];
    }
    _loading = false;
    notifyListeners();
  }
}
