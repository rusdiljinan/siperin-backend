import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import '../models/user_model.dart';
import '../utils/api_response_parser.dart';
import 'api_client.dart';
import 'storage_service.dart';

class AuthService {
  final ApiClient _api;
  final StorageService _storage;

  AuthService(this._api, this._storage);

  Future<UserModel> login(String username, String password) async {
    try {
      final response = await _api.dio.post(
        ApiConstants.login,
        data: {'username': username, 'password': password},
      );

      if (kDebugMode) {
        debugPrint('[AuthService] login status: ${response.statusCode}');
      }

      final json = _normalizeJson(response.data);

      if (!ApiResponseParser.isSuccess(json)) {
        throw Exception(
          ApiResponseParser.extractErrorMessage(json, fallback: 'Login gagal'),
        );
      }

      final token = ApiResponseParser.extractToken(json);
      if (token == null || token.isEmpty) {
        throw Exception(
          'Token tidak diterima dari server. Pastikan backend menggunakan Laravel Sanctum.',
        );
      }

      final userJson = ApiResponseParser.extractUser(json);
      if (userJson == null) {
        throw Exception('Data user tidak ditemukan dalam response server');
      }

      await _storage.saveToken(token);
      final user = UserModel.fromJson(userJson);
      await _storage.saveUser(user);

      if (kDebugMode) {
        debugPrint(
          '[AuthService] token Sanctum tersimpan, user: ${user.username}',
        );
      }

      return user;
    } on DioException catch (e) {
      throw Exception(_dioErrorMessage(e));
    }
  }

  Future<void> logout() async {
    try {
      await _api.dio.post(ApiConstants.logout);
    } catch (_) {
      // Tetap bersihkan sesi lokal meski server tidak terjangkau
    }
    await _storage.clearSession();
  }

  Future<bool> isLoggedIn() async {
    final token = await _storage.getToken();
    if (token == null || token.isEmpty) return false;

    try {
      final response = await _api.dio.get(ApiConstants.me);
      final json = _normalizeJson(response.data);
      if (ApiResponseParser.isSuccess(json)) {
        final userJson = ApiResponseParser.extractObject(json);
        if (userJson.containsKey('id')) {
          final user = UserModel.fromJson(userJson);
          await _storage.saveUser(user);
          return true;
        }
      }
      await _storage.clearSession();
      return false;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        await _storage.clearSession();
      }
      return false;
    }
  }

  Future<UserModel?> getCurrentUser() => _storage.getUser();

  Map<String, dynamic> _normalizeJson(dynamic data) {
    if (data is Map<String, dynamic>) return data;
    if (data is Map) return Map<String, dynamic>.from(data);
    throw Exception('Format response server tidak valid (bukan JSON object)');
  }

  String _dioErrorMessage(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Server tidak merespon. Pastikan Laravel berjalan: php artisan serve';
      case DioExceptionType.connectionError:
        return 'Tidak dapat terhubung ke API. Periksa URL: ${ApiConstants.baseUrl} '
            '(Android emulator gunakan http://10.0.2.2:8000/api)';
      case DioExceptionType.badResponse:
        if (e.response?.data != null) {
          try {
            final json = _normalizeJson(e.response!.data);
            return ApiResponseParser.extractErrorMessage(
              json,
              fallback: 'Login gagal (${e.response?.statusCode})',
            );
          } catch (_) {
            return 'Login gagal (HTTP ${e.response?.statusCode})';
          }
        }
        return 'Login gagal (HTTP ${e.response?.statusCode})';
      default:
        return e.message ?? 'Kesalahan jaringan saat login';
    }
  }
}
