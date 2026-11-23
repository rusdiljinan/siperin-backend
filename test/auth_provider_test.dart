import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inventaris_instansi/models/user_model.dart';
import 'package:inventaris_instansi/providers/auth_provider.dart';
import 'package:inventaris_instansi/services/api_client.dart';
import 'package:inventaris_instansi/services/auth_service.dart';
import 'package:inventaris_instansi/services/storage_service.dart';

class _ControlledAuthService extends AuthService {
  _ControlledAuthService()
    : super(ApiClient(StorageService()), StorageService());

  final Completer<UserModel> result = Completer<UserModel>();
  int loginCalls = 0;

  @override
  Future<UserModel> login(String username, String password) {
    loginCalls++;
    return result.future;
  }
}

void main() {
  test('ignores repeated login while the first request is running', () async {
    final service = _ControlledAuthService();
    final provider = AuthProvider(service);

    final request = provider.login('user', 'password');
    expect(provider.isLoading, isTrue);

    expect(await provider.login('user', 'password'), isFalse);
    expect(service.loginCalls, 1);
    expect(provider.isLoading, isTrue);

    service.result.complete(
      UserModel(
        id: 1,
        name: 'User',
        username: 'user',
        email: 'user@example.com',
        role: 'user',
      ),
    );
    expect(await request, isTrue);
    expect(provider.isLoading, isFalse);
  });

  test('stops loading and exposes the error when login fails', () async {
    final service = _ControlledAuthService();
    final provider = AuthProvider(service);
    final request = provider.login('user', 'password');

    service.result.completeError(Exception('Koneksi gagal'));

    expect(await request, isFalse);
    expect(provider.isLoading, isFalse);
    expect(provider.error, 'Koneksi gagal');
  });
}
