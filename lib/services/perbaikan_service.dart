import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../models/barang_model.dart';
import '../utils/api_response_parser.dart';
import 'api_client.dart';

/// Menu Perbaikan — data inventaris dengan kondisi Rusak saja.
class PerbaikanService {
  final ApiClient _api;

  PerbaikanService(this._api);

  Future<List<BarangModel>> fetchPerbaikan({
    String? search,
    String? ruangan,
    String? kategori,
  }) async {
    try {
      final response = await _api.dio.get(
        ApiConstants.perbaikan,
        queryParameters: {
          if (search != null && search.isNotEmpty) 'search': search,
          if (ruangan != null && ruangan.isNotEmpty) 'ruangan': ruangan,
          if (kategori != null && kategori.isNotEmpty) 'kategori': kategori,
        },
      );

      final json = _asMap(response.data);
      if (!ApiResponseParser.isSuccess(json)) {
        throw Exception(
          ApiResponseParser.extractErrorMessage(
            json,
            fallback: 'Gagal memuat data perbaikan',
          ),
        );
      }

      final list = ApiResponseParser.extractList(json);
      if (kDebugMode) {
        debugPrint(
          '[PerbaikanService] /perbaikan → ${list.length} barang rusak',
        );
      }

      return list
          .map((e) => BarangModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal memuat data perbaikan'));
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Format response tidak valid');
  }

  String _dioMessage(DioException e, String fallback) {
    if (e.response?.data != null) {
      try {
        return ApiResponseParser.extractErrorMessage(
          _asMap(e.response!.data),
          fallback: fallback,
        );
      } catch (_) {}
    }
    return fallback;
  }
}
