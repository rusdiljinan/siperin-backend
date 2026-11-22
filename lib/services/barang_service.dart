import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import '../core/constants/api_constants.dart';
import '../models/barang_history_model.dart';
import '../models/barang_model.dart';
import '../utils/api_response_parser.dart';
import 'api_client.dart';

class BarangService {
  final ApiClient _api;
  final Map<int, Future<Uint8List?>> _fotoRequests = {};

  BarangService(this._api);

  Future<Map<String, int>> fetchKategori() async {
    try {
      final response = await _api.dio.get(ApiConstants.kategori);
      final json = _asMap(response.data);
      if (!ApiResponseParser.isSuccess(json)) {
        throw Exception(
          ApiResponseParser.extractErrorMessage(
            json,
            fallback: 'Gagal memuat kategori',
          ),
        );
      }

      final result = <String, int>{};
      for (final item in ApiResponseParser.extractList(json)) {
        if (item is Map) {
          final id = _readInt(item['id'], 0);
          final name = item['nama_kategori']?.toString().trim();
          if (id > 0 && name != null && name.isNotEmpty) {
            result[name] = id;
          }
        }
      }
      return result;
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal memuat kategori'));
    }
  }

  Future<BarangPage> fetchBarang({
    String? search,
    String? kategori,
    String? kondisi,
    int page = 1,
    int perPage = 50,
    String sortBy = 'nama',
    bool ascending = true,
  }) async {
    try {
      final params = {
        if (search != null && search.trim().isNotEmpty) 'search': search.trim(),
        if (kategori != null && kategori.isNotEmpty) 'kategori': kategori,
        if (kondisi != null && kondisi.isNotEmpty) 'kondisi': kondisi,
        'page': page,
        'per_page': perPage,
        'sort_by': _mapSortField(sortBy),
        'sort_dir': ascending ? 'asc' : 'desc',
      };
      if (kDebugMode) debugPrint('[BarangService] fetchBarang params: $params');
      final response = await _api.dio.get(
        ApiConstants.barang,
        queryParameters: params,
      );

      final json = _asMap(response.data);
      if (!ApiResponseParser.isSuccess(json)) {
        throw Exception(
          ApiResponseParser.extractErrorMessage(
            json,
            fallback: 'Gagal memuat data barang',
          ),
        );
      }

      final list = ApiResponseParser.extractList(json);
      if (kDebugMode) {
        debugPrint('[BarangService] /barang → ${list.length} item');
      }

      final items = list
          .map((e) => BarangModel.fromJson(e as Map<String, dynamic>))
          .toList();
      final meta = ApiResponseParser.extractMeta(json) ?? const {};

      return BarangPage(
        items: items,
        currentPage: _readInt(meta['current_page'], page),
        lastPage: _readInt(meta['last_page'], page),
        total: _readInt(meta['total'], items.length),
      );
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal memuat data barang'));
    }
  }

  int _readInt(dynamic value, int fallback) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }

  Future<BarangModel> getDetail(int id) async {
    try {
      final response = await _api.dio.get(ApiConstants.barangDetail(id));
      return _parseBarangResponse(response.data);
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal memuat detail barang'));
    }
  }

  Future<List<BarangHistoryModel>> getHistory(int id) async {
    try {
      final response = await _api.dio.get(ApiConstants.barangHistory(id));
      final json = _asMap(response.data);
      if (!ApiResponseParser.isSuccess(json)) {
        throw Exception(
          ApiResponseParser.extractErrorMessage(
            json,
            fallback: 'Gagal memuat riwayat',
          ),
        );
      }
      final list = ApiResponseParser.extractList(json);
      return list
          .map((e) => BarangHistoryModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal memuat riwayat barang'));
    }
  }

  Future<BarangModel> create(
    Map<String, dynamic> data, {
    String? fotoPath,
    XFile? foto,
  }) async {
    try {
      final Response<dynamic> response;
      if (foto != null || fotoPath != null) {
        final form = FormData.fromMap({
          ...data,
          'foto': foto != null
              ? MultipartFile.fromBytes(
                  await foto.readAsBytes(),
                  filename: foto.name,
                )
              : await MultipartFile.fromFile(fotoPath!),
        });
        response = await _api.dio.post(ApiConstants.barang, data: form);
      } else {
        response = await _api.dio.post(ApiConstants.barang, data: data);
      }
      final barang = _parseBarangResponse(
        response.data,
        fallback: 'Gagal menambah barang',
      );
      invalidateFoto(barang.id);
      return barang;
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal menambah barang'));
    }
  }

  Future<BarangModel> update(
    int id,
    Map<String, dynamic> data, {
    String? fotoPath,
    XFile? foto,
    bool removeFoto = false,
  }) async {
    try {
      final Response<dynamic> response;
      if (foto != null || fotoPath != null || removeFoto) {
        final form = FormData.fromMap({
          ...data,
          if (foto != null)
            'foto': MultipartFile.fromBytes(
              await foto.readAsBytes(),
              filename: foto.name,
            )
          else if (fotoPath != null)
            'foto': await MultipartFile.fromFile(fotoPath),
          if (removeFoto) 'remove_foto': true,
        });
        response = await _api.dio.post(
          ApiConstants.barangDetail(id),
          data: form,
        );
      } else {
        response = await _api.dio.put(
          ApiConstants.barangDetail(id),
          data: data,
        );
      }
      final barang = _parseBarangResponse(
        response.data,
        fallback: 'Gagal memperbarui barang',
      );
      invalidateFoto(id);
      return barang;
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal memperbarui barang'));
    }
  }

  Future<Uint8List?> getFoto(int id) {
    return _fotoRequests.putIfAbsent(id, () => _loadFoto(id));
  }

  void invalidateFoto(int id) {
    _fotoRequests.remove(id);
  }

  Future<Uint8List?> _loadFoto(int id) async {
    try {
      final response = await _api.dio.get<List<int>>(
        ApiConstants.barangFoto(id),
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': 'image/*'},
        ),
      );
      if (response.statusCode == 404) return null;
      if (response.statusCode != 200 || response.data == null) {
        throw Exception(
          'Gagal memuat foto barang (HTTP ${response.statusCode})',
        );
      }
      return Uint8List.fromList(response.data!);
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal memuat foto barang'));
    }
  }

  Future<void> delete(int id) async {
    try {
      final response = await _api.dio.delete(ApiConstants.barangDetail(id));
      final json = _asMap(response.data);
      if (!ApiResponseParser.isSuccess(json)) {
        throw Exception(
          ApiResponseParser.extractErrorMessage(
            json,
            fallback: 'Gagal menghapus barang',
          ),
        );
      }
      invalidateFoto(id);
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal menghapus barang'));
    }
  }

  Future<void> deleteMany(List<int> ids) async {
    try {
      final response = await _api.dio.delete(
        ApiConstants.barangBulkDelete,
        data: {'ids': ids},
      );
      final json = _asMap(response.data);
      if (!ApiResponseParser.isSuccess(json)) {
        throw Exception(
          ApiResponseParser.extractErrorMessage(
            json,
            fallback: 'Gagal menghapus barang terpilih',
          ),
        );
      }
      for (final id in ids) {
        invalidateFoto(id);
      }
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal menghapus barang terpilih'));
    }
  }

  BarangModel _parseBarangResponse(
    dynamic data, {
    String fallback = 'Operasi gagal',
  }) {
    final json = _asMap(data);
    if (!ApiResponseParser.isSuccess(json)) {
      throw Exception(
        ApiResponseParser.extractErrorMessage(json, fallback: fallback),
      );
    }
    return BarangModel.fromJson(ApiResponseParser.extractObject(json));
  }

  String _mapSortField(String sortBy) {
    switch (sortBy) {
      case 'kode':
        return 'kode_barang';
      case 'tahun':
        return 'tahun_pembelian';
      case 'kondisi':
        return 'kondisi_barang';
      default:
        return 'nama_barang';
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Format response tidak valid');
  }

  String _dioMessage(DioException e, String fallback) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server tidak merespon. Pastikan Laravel aktif (php artisan serve).';
      case DioExceptionType.connectionError:
        return 'Tidak bisa terhubung ke API.\n'
            'Cek: backend jalan, URL benar (${ApiConstants.baseUrl}).\n'
            'Android emulator pakai 10.0.2.2, bukan 127.0.0.1.';
      case DioExceptionType.badResponse:
        if (e.response?.data != null) {
          try {
            return ApiResponseParser.extractErrorMessage(
              _asMap(e.response!.data),
              fallback: fallback,
            );
          } catch (_) {}
        }
        final status = e.response?.statusCode;
        final statusLabel = switch (status) {
          400 => 'Permintaan tidak valid',
          401 => 'Sesi tidak valid atau belum login',
          403 => 'Akses ditolak',
          404 => 'Endpoint atau data tidak ditemukan',
          422 => 'Validasi gagal',
          500 => 'Kesalahan server',
          _ => fallback,
        };
        return '$statusLabel (HTTP $status)';
      default:
        return e.message ?? fallback;
    }
  }
}

class BarangPage {
  final List<BarangModel> items;
  final int currentPage;
  final int lastPage;
  final int total;

  const BarangPage({
    required this.items,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
