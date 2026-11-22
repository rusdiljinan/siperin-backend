import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

class StorageService {
  SharedPreferences? _prefs;

  Future<SharedPreferences> get prefs async {
    _prefs ??= await SharedPreferences.getInstance();
    return _prefs!;
  }

  Future<void> saveToken(String token) async {
    final p = await prefs;
    await p.setString(AppConstants.tokenKey, token);
  }

  Future<String?> getToken() async {
    final p = await prefs;
    return p.getString(AppConstants.tokenKey);
  }

  Future<void> saveUser(UserModel user) async {
    final p = await prefs;
    await p.setString(AppConstants.userKey, jsonEncode(user.toJson()));
  }

  Future<UserModel?> getUser() async {
    final p = await prefs;
    final raw = p.getString(AppConstants.userKey);
    if (raw == null) return null;
    return UserModel.fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  Future<void> clearSession() async {
    final p = await prefs;
    await p.remove(AppConstants.tokenKey);
    await p.remove(AppConstants.userKey);
  }

  Future<void> saveThemeMode(String mode) async {
    final p = await prefs;
    await p.setString(AppConstants.themeKey, mode);
  }

  Future<String?> getThemeMode() async {
    final p = await prefs;
    return p.getString(AppConstants.themeKey);
  }
}
