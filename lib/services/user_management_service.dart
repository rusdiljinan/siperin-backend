import 'package:dio/dio.dart';
import '../core/constants/api_constants.dart';
import '../models/managed_user_model.dart';
import '../utils/api_response_parser.dart';
import 'api_client.dart';

class UserManagementService {
  final ApiClient _api;

  UserManagementService(this._api);

  Future<ManagedUserPage> getUsers({
    String search = '',
    String? role,
    int page = 1,
  }) async {
    try {
      final response = await _api.dio.get(
        ApiConstants.users,
        queryParameters: {
          if (search.trim().isNotEmpty) 'search': search.trim(),
          if (role != null) 'role': role,
          'page': page,
        },
      );
      final json = _asJson(response.data);
      _ensureSuccess(json);
      final users = ApiResponseParser.extractList(json)
          .map(
            (item) => ManagedUserModel.fromJson(
              Map<String, dynamic>.from(item as Map),
            ),
          )
          .toList();
      final meta = ApiResponseParser.extractMeta(json) ?? const {};
      return ManagedUserPage(
        users: users,
        currentPage: meta['current_page'] as int? ?? page,
        lastPage: meta['last_page'] as int? ?? 1,
        total: meta['total'] as int? ?? users.length,
      );
    } on DioException catch (error) {
      throw Exception(_message(error));
    }
  }

  Future<Map<String, dynamic>> createUser({
    required String name,
    required String role,
    String? username,
    String? password,
  }) async {
    try {
      final payload = {
        'name': name,
        'role': role,
        if (username != null && username.trim().isNotEmpty)
          'username': username.trim(),
        if (password != null && password.isNotEmpty) 'password': password,
      };
      final response = await _api.dio.post(ApiConstants.users, data: payload);
      final json = _asJson(response.data);
      _ensureSuccess(json);
      final data = json['data'];
      if (data is Map) {
        return Map<String, dynamic>.from(data);
      }
      return const {};
    } on DioException catch (error) {
      throw Exception(_message(error));
    }
  }

  Future<void> updateUser({
    required int id,
    required String name,
    required String role,
    String? password,
  }) async {
    try {
      final response = await _api.dio.put(
        ApiConstants.userDetail(id),
        data: {
          'name': name,
          'role': role,
          if (password != null && password.isNotEmpty) 'password': password,
        },
      );
      final json = _asJson(response.data);
      _ensureSuccess(json);
    } on DioException catch (error) {
      throw Exception(_message(error));
    }
  }

  Future<void> updateStatus(int id, bool isActive) async {
    try {
      final response = await _api.dio.patch(
        ApiConstants.userStatus(id),
        data: {'is_active': isActive},
      );
      final json = _asJson(response.data);
      _ensureSuccess(json);
    } on DioException catch (error) {
      throw Exception(_message(error));
    }
  }

  Future<void> deleteUser(int id) async {
    try {
      final response = await _api.dio.delete(ApiConstants.userDetail(id));
      final json = _asJson(response.data);
      _ensureSuccess(json);
    } on DioException catch (error) {
      throw Exception(_message(error));
    }
  }

  Map<String, dynamic> _asJson(dynamic value) {
    if (value is Map<String, dynamic>) return value;
    if (value is Map) return Map<String, dynamic>.from(value);
    throw Exception('Format response server tidak valid');
  }

  void _ensureSuccess(Map<String, dynamic> json) {
    if (!ApiResponseParser.isSuccess(json)) {
      throw Exception(
        ApiResponseParser.extractErrorMessage(
          json,
          fallback: 'Permintaan gagal',
        ),
      );
    }
  }

  String _message(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      return ApiResponseParser.extractErrorMessage(
        Map<String, dynamic>.from(data),
        fallback:
            'Permintaan gagal (${error.response?.statusCode ?? 'jaringan'})',
      );
    }
    return 'Tidak dapat terhubung ke server';
  }
}

class ManagedUserPage {
  final List<ManagedUserModel> users;
  final int currentPage;
  final int lastPage;
  final int total;

  const ManagedUserPage({
    required this.users,
    required this.currentPage,
    required this.lastPage,
    required this.total,
  });
}
