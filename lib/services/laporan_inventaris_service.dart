import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../core/constants/api_constants.dart';
import '../models/laporan_inventaris_model.dart';
import '../utils/api_response_parser.dart';
import 'api_client.dart';

class LaporanInventarisService {
  final ApiClient _api;

  LaporanInventarisService(this._api);

  Future<LaporanInventarisModel> fetchReport(
    Map<String, dynamic> filters,
  ) async {
    try {
      final response = await _api.dio.get(
        ApiConstants.laporanInventaris,
        queryParameters: filters,
      );
      final json = _asMap(response.data);
      if (!ApiResponseParser.isSuccess(json)) {
        throw Exception(
          ApiResponseParser.extractErrorMessage(
            json,
            fallback: 'Gagal memuat laporan inventaris',
          ),
        );
      }
      return LaporanInventarisModel.fromJson(
        ApiResponseParser.extractObject(json),
      );
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Gagal memuat laporan inventaris'));
    }
  }

  Future<Uint8List> export(String format, Map<String, dynamic> filters) async {
    try {
      final response = await _api.dio.get<List<int>>(
        ApiConstants.laporanInventarisExport(format),
        queryParameters: filters,
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'Accept': format == 'pdf' ? 'application/pdf' : '*/*'},
        ),
      );
      final contentType = response.headers.value(Headers.contentTypeHeader);
      final bytes = response.data;
      if (response.statusCode != 200) {
        final body = _decodeErrorBody(bytes, contentType);
        if (body != null) {
          throw Exception(
            ApiResponseParser.extractErrorMessage(
              body,
              fallback:
                  'Gagal mengekspor laporan (HTTP ${response.statusCode}).',
            ),
          );
        }
        throw Exception(
          'Gagal mengekspor laporan (HTTP ${response.statusCode}).',
        );
      }
      if (bytes == null || bytes.isEmpty) {
        throw Exception('Server tidak mengembalikan file laporan yang valid.');
      }
      if (contentType?.contains('application/json') == true) {
        throw Exception('Server mengembalikan error, bukan file laporan.');
      }
      return Uint8List.fromList(bytes);
    } on DioException catch (e) {
      throw Exception(_errorMessage(e, 'Gagal mengekspor laporan'));
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Format respons laporan tidak valid.');
  }

  Map<String, dynamic>? _decodeErrorBody(
    List<int>? bytes,
    String? contentType,
  ) {
    if (bytes == null ||
        contentType == null ||
        !contentType.contains('application/json')) {
      return null;
    }

    try {
      final decoded = jsonDecode(utf8.decode(bytes));
      if (decoded is Map<String, dynamic>) return decoded;
      if (decoded is Map) return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
    return null;
  }

  String _errorMessage(DioException e, String fallback) {
    final body = e.response?.data;
    if (body is Map) {
      return ApiResponseParser.extractErrorMessage(
        Map<String, dynamic>.from(body),
        fallback: fallback,
      );
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout ||
        e.type == DioExceptionType.receiveTimeout) {
      return 'Tidak dapat terhubung ke server laporan.';
    }
    return e.message ?? fallback;
  }
}
