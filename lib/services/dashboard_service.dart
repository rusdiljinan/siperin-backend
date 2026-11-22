import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../models/dashboard_model.dart';
import '../utils/api_response_parser.dart';
import 'api_client.dart';

class DashboardLoadException implements Exception {
  const DashboardLoadException(this.message);

  final String message;

  @override
  String toString() => message;
}

class DashboardService {
  final ApiClient _api;

  DashboardService(this._api);

  Future<DashboardModel> fetchDashboard() async {
    try {
      final response = await _api.dio.get(ApiConstants.dashboard);
      final json = _asMap(response.data);
      if (!ApiResponseParser.isSuccess(json)) {
        if (kDebugMode) {
          debugPrint(
            '[Dashboard] API returned success=false '
            '(HTTP ${response.statusCode ?? 'unknown'}).',
          );
        }
        throw DashboardLoadException(_messageForStatus(response.statusCode));
      }
      final obj = ApiResponseParser.extractObject(json);

      _validateDashboardPayload(obj);

      return DashboardModel.fromJson(obj);
    } on DioException catch (e) {
      if (kDebugMode) {
        debugPrint(
          '[Dashboard] Request failed: ${e.type}; '
          'HTTP ${e.response?.statusCode ?? 'none'}; '
          '${e.requestOptions.uri}',
        );
      }
      throw DashboardLoadException(_messageForDioError(e));
    } on FormatException catch (e, stackTrace) {
      _logInvalidResponse(e, stackTrace);
      throw const DashboardLoadException(
        'Format respons dashboard dari server tidak valid.',
      );
    } on TypeError catch (e, stackTrace) {
      _logInvalidResponse(e, stackTrace);
      throw const DashboardLoadException(
        'Data dashboard dari server tidak sesuai format.',
      );
    }
  }

  Map<String, dynamic> _asMap(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const FormatException('Expected a JSON object.');
  }

  void _validateDashboardPayload(Map<String, dynamic> data) {
    const requiredNumbers = [
      'total_barang',
      'barang_baik',
      'barang_rusak',
      'barang_perbaikan',
      'chart_year',
    ];
    for (final key in requiredNumbers) {
      if (data[key] is! num) {
        throw const FormatException('Missing dashboard statistic.');
      }
    }

    final chart = data['chart'];
    if (chart is! List || chart.length != 12) {
      throw const FormatException('Expected twelve monthly chart points.');
    }

    for (final point in chart) {
      if (point is! Map ||
          point['label'] is! String ||
          point['sangat_baik'] is! num ||
          point['baik'] is! num ||
          point['rusak'] is! num) {
        throw const FormatException('Invalid monthly chart point.');
      }
    }
  }

  String _messageForStatus(int? status) {
    switch (status) {
      case 401:
        return 'Sesi login tidak valid atau telah berakhir. Silakan login kembali.';
      case 419:
        return 'Sesi permintaan telah kedaluwarsa. Silakan login kembali.';
      case 403:
        return 'Akun ini tidak memiliki izin untuk melihat dashboard.';
      case 404:
        return 'Endpoint dashboard tidak ditemukan. Periksa URL API dan route Laravel.';
      case 422:
        return 'Permintaan dashboard ditolak karena data tidak valid.';
      default:
        if (status != null && status >= 500) {
          return 'Server gagal memuat dashboard. Periksa log Laravel.';
        }
        return status == null
            ? 'API mengembalikan respons dashboard yang tidak valid.'
            : 'Permintaan dashboard gagal (HTTP $status).';
    }
  }

  String _messageForDioError(DioException error) {
    final status = error.response?.statusCode;
    if (status != null) {
      return _messageForStatus(status);
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.transformTimeout:
        return 'Koneksi ke server timeout. Pastikan API berjalan, lalu coba lagi.';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke API. Periksa URL dan pastikan Laravel berjalan.';
      case DioExceptionType.badCertificate:
        return 'Sertifikat HTTPS server tidak valid.';
      case DioExceptionType.cancel:
        return 'Permintaan dashboard dibatalkan. Silakan coba lagi.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
        return 'Terjadi gangguan saat menghubungi API dashboard.';
    }
  }

  void _logInvalidResponse(Object error, StackTrace stackTrace) {
    if (!kDebugMode) return;

    debugPrint('[Dashboard] Invalid API response: ${error.runtimeType}.');
    debugPrintStack(stackTrace: stackTrace);
  }
}
