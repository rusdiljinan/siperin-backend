import 'package:flutter/foundation.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class DashboardProvider extends ChangeNotifier {
  final DashboardService _service;
  DashboardModel? _data;
  bool _loading = true;
  String? _error;
  Future<void>? _inFlight;

  DashboardProvider(this._service);

  DashboardModel? get data => _data;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> load() {
    final activeRequest = _inFlight;
    if (activeRequest != null) {
      return activeRequest;
    }

    final request = _performLoad();
    late final Future<void> trackedRequest;
    trackedRequest = request.whenComplete(() {
      if (identical(_inFlight, trackedRequest)) {
        _inFlight = null;
      }
    });
    _inFlight = trackedRequest;
    return trackedRequest;
  }

  Future<void> _performLoad() async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      _data = await _service.fetchDashboard();
      _loading = false;
      notifyListeners();
    } catch (error) {
      if (kDebugMode) {
        debugPrint('[Dashboard] Load failed: ${error.runtimeType}.');
      }
      _error = error is DashboardLoadException
          ? error.message
          : 'Terjadi kesalahan saat memuat dashboard. Coba lagi.';
      _loading = false;
      _data = null;
      notifyListeners();
    }
  }
}
