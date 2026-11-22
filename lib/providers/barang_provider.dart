import 'dart:async';

import 'package:flutter/foundation.dart';
import '../models/barang_model.dart';
import '../services/barang_service.dart';

class BarangProvider extends ChangeNotifier {
  static const int _perPage = 50;

  final BarangService _service;
  List<BarangModel> _items = [];
  List<BarangModel> _filtered = [];
  bool _loading = false;
  bool _loadingMore = false;
  bool _hasLoaded = false;
  String _search = '';
  String? _kategoriFilter;
  String? _kondisiFilter;
  String _sortBy = 'nama';
  bool _ascending = true;
  int _currentPage = 0;
  int _totalPages = 1;
  int _totalItems = 0;
  int _requestVersion = 0;
  double _scrollOffset = 0.0;
  Timer? _searchDebounce;

  BarangProvider(this._service);

  List<BarangModel> get items => _filtered;
  List<BarangModel> get allFiltered => _filtered;
  bool get loading => _loading;
  bool get loadingMore => _loadingMore;
  bool get hasLoaded => _hasLoaded;
  bool get hasMore => _hasLoaded && _currentPage < _totalPages;
  String get search => _search;
  String? get kategoriFilter => _kategoriFilter;
  int get currentPage => _currentPage;
  int get totalPages => _totalPages;
  int get totalItems => _totalItems;
  double get scrollOffset => _scrollOffset;

  String? _error;

  String? get error => _error;
  String? get kondisiFilter => _kondisiFilter;

  Future<void> load() async {
    _searchDebounce?.cancel();
    final requestVersion = ++_requestVersion;
    _loading = true;
    _loadingMore = false;
    _error = null;
    _items = [];
    _filtered = [];
    _currentPage = 0;
    _totalPages = 1;
    _totalItems = 0;
    _hasLoaded = false;
    _scrollOffset = 0;
    notifyListeners();

    if (kDebugMode) {
      debugPrint(
        '[BarangProvider] load -> search=$_search kategori=$_kategoriFilter kondisi=$_kondisiFilter sort=$_sortBy asc=$_ascending page=1',
      );
    }

    try {
      final result = await _service.fetchBarang(
        search: _search,
        kategori: _kategoriFilter,
        kondisi: _kondisiFilter,
        page: 1,
        perPage: _perPage,
        sortBy: _sortBy,
        ascending: _ascending,
      );
      if (requestVersion != _requestVersion) return;

      _items = _deduplicate(result.items);
      _currentPage = result.currentPage;
      _totalPages = result.lastPage < result.currentPage
          ? result.currentPage
          : result.lastPage;
      _totalItems = result.total;
      _hasLoaded = true;
      _applyLocalFilter();
      if (kDebugMode) {
        debugPrint(
          '[BarangProvider] load -> fetched ${_items.length}/$_totalItems items (page $_currentPage/$_totalPages)',
        );
      }
    } catch (e) {
      if (requestVersion != _requestVersion) return;
      _error = e.toString().replaceFirst('Exception: ', '');
      _items = [];
      _filtered = [];
      if (kDebugMode) debugPrint('[BarangProvider] load -> error: $_error');
    } finally {
      if (requestVersion == _requestVersion) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> loadMore() async {
    if (_loading || _loadingMore || !hasMore || _error != null) return;

    final requestVersion = _requestVersion;
    final requestedPage = _currentPage + 1;
    _loadingMore = true;
    notifyListeners();

    try {
      final result = await _service.fetchBarang(
        search: _search,
        kategori: _kategoriFilter,
        kondisi: _kondisiFilter,
        page: requestedPage,
        perPage: _perPage,
        sortBy: _sortBy,
        ascending: _ascending,
      );
      if (requestVersion != _requestVersion) return;

      final knownIds = _items.map((item) => item.id).toSet();
      _items = [
        ..._items,
        ...result.items.where((item) => knownIds.add(item.id)),
      ];
      _totalPages = result.lastPage < requestedPage
          ? requestedPage
          : result.lastPage;
      _totalItems = result.total;
      _currentPage = result.items.isEmpty
          ? _totalPages
          : result.currentPage < requestedPage
          ? requestedPage
          : result.currentPage;
      _applyLocalFilter();
    } catch (e) {
      if (requestVersion != _requestVersion) return;
      _error = e.toString().replaceFirst('Exception: ', '');
      if (kDebugMode) {
        debugPrint('[BarangProvider] loadMore -> error: $_error');
      }
    } finally {
      if (requestVersion == _requestVersion) {
        _loadingMore = false;
        notifyListeners();
      }
    }
  }

  void setSearch(String value) {
    if (_search == value) return;
    _search = value;
    _reloadForFilterChange(debounceSearch: true);
  }

  void setKategori(String? kategori) {
    if (_kategoriFilter == kategori) return;
    _kategoriFilter = kategori;
    if (kDebugMode) debugPrint('[BarangProvider] setKategori -> $kategori');
    _reloadForFilterChange();
  }

  void setKondisi(String? kondisi) {
    if (_kondisiFilter == kondisi) return;
    _kondisiFilter = kondisi;
    _reloadForFilterChange();
  }

  void setSort(String field, bool ascending) {
    if (_sortBy == field && _ascending == ascending) return;
    _sortBy = field;
    _ascending = ascending;
    _reloadForFilterChange();
  }

  void _reloadForFilterChange({bool debounceSearch = false}) {
    _searchDebounce?.cancel();
    ++_requestVersion;
    _loading = true;
    _loadingMore = false;
    _error = null;
    _items = [];
    _filtered = [];
    _currentPage = 0;
    _totalPages = 1;
    _totalItems = 0;
    _hasLoaded = false;
    _scrollOffset = 0;
    notifyListeners();

    if (debounceSearch) {
      _searchDebounce = Timer(
        const Duration(milliseconds: 350),
        () => unawaited(load()),
      );
    } else {
      unawaited(load());
    }
  }

  List<BarangModel> _deduplicate(List<BarangModel> items) {
    final knownIds = <int>{};
    return items.where((item) => knownIds.add(item.id)).toList();
  }

  /// Save vertical scroll offset for list caching across navigation.
  void setScrollOffset(double offset) {
    _scrollOffset = offset;
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }

  void _applyLocalFilter() {
    var list = List<BarangModel>.from(_items);
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((b) {
        return b.nama.toLowerCase().contains(q) ||
            b.kode.toLowerCase().contains(q) ||
            b.ruangan.toLowerCase().contains(q);
      }).toList();
    }
    if (_kategoriFilter != null && _kategoriFilter!.isNotEmpty) {
      list = list.where((b) => b.kategori == _kategoriFilter).toList();
    }
    if (_kondisiFilter != null && _kondisiFilter!.isNotEmpty) {
      list = list.where((b) => b.kondisi == _kondisiFilter).toList();
    }
    list.sort((a, b) {
      final cmp = switch (_sortBy) {
        'kode' => a.kode.compareTo(b.kode),
        'tahun' => a.tahunPembelian.compareTo(b.tahunPembelian),
        'kondisi' => a.kondisi.compareTo(b.kondisi),
        _ => a.nama.compareTo(b.nama),
      };
      return _ascending ? cmp : -cmp;
    });
    _filtered = list;
  }

  Future<bool> deleteBarang(int id) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.delete(id);
      await load();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBarangMany(List<int> ids) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      await _service.deleteMany(ids);
      await load();
      return true;
    } catch (e) {
      _error = e.toString().replaceFirst('Exception: ', '');
      _loading = false;
      notifyListeners();
      return false;
    }
  }
}
