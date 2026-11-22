import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/aktivitas_model.dart';
import '../utils/api_response_parser.dart';
import 'api_client.dart';

class AktivitasService {
  final ApiClient _api;

  AktivitasService(this._api);

  Future<void> logPrint({String? deskripsi}) async {
    try {
      await _api.dio.post(
        ApiConstants.aktivitasLogPrint,
        data: {if (deskripsi != null) 'deskripsi': deskripsi},
      );
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal mencatat aktivitas print'));
    }
  }

  Future<List<AktivitasModel>> fetchAktivitas({int perPage = 100}) async {
    try {
      final response = await _api.dio.get(
        ApiConstants.aktivitas,
        queryParameters: {'per_page': perPage},
      );
      final json = _asMap(response.data);
      if (!ApiResponseParser.isSuccess(json)) {
        throw Exception(
          ApiResponseParser.extractErrorMessage(
            json,
            fallback: 'Gagal memuat riwayat aktivitas',
          ),
        );
      }
      final list = ApiResponseParser.extractList(json);
      return list
          .map((e) => AktivitasModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } on DioException catch (e) {
      throw Exception(_dioMessage(e, 'Gagal memuat riwayat aktivitas'));
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
