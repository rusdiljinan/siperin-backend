import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../core/constants/api_constants.dart';
import 'storage_service.dart';

/// Client HTTP Dio dengan Bearer token Laravel Sanctum.
class ApiClient {
  late final Dio dio;
  final StorageService _storage;

  ApiClient(this._storage) {
    final baseUrl = ApiConstants.baseUrl;

    if (kDebugMode) {
      debugPrint('[API] Base URL: $baseUrl');
    }

    dio = Dio(
      BaseOptions(
        baseUrl: baseUrl,
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        sendTimeout: const Duration(seconds: 15),
        headers: {'Accept': 'application/json'},
        validateStatus: (status) => status != null && status < 500,
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await _storage.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }

          // FormData butuh boundary otomatis — jangan paksa application/json
          if (options.data is FormData) {
            options.headers.remove('Content-Type');
          } else if (!options.headers.containsKey('Content-Type')) {
            options.headers['Content-Type'] = 'application/json';
          }

          if (kDebugMode) {
            debugPrint('[API] ${options.method} ${options.uri}');
          }
          handler.next(options);
        },
        onResponse: (response, handler) {
          if (kDebugMode) {
            debugPrint(
              '[API] ${response.statusCode} ${response.requestOptions.path}',
            );
          }
          handler.next(response);
        },
        onError: (error, handler) {
          if (kDebugMode) {
            debugPrint('[API ERROR] ${error.type} ${error.message}');
            if (error.response?.statusCode == 401) {
              debugPrint('[API] Unauthorized — login ulang diperlukan');
            }
          }
          handler.next(error);
        },
      ),
    );
  }
}
