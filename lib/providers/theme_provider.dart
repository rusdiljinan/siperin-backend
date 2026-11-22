import 'package:flutter/material.dart';
import '../services/storage_service.dart';

class ThemeProvider extends ChangeNotifier {
  final StorageService _storage;
  ThemeMode _themeMode = ThemeMode.light;

  ThemeProvider(this._storage);

  ThemeMode get themeMode => _themeMode;
  bool get isDark =>
      _themeMode == ThemeMode.dark ||
      (_themeMode == ThemeMode.system &&
          WidgetsBinding.instance.platformDispatcher.platformBrightness ==
              Brightness.dark);

  Future<void> loadTheme() async {
    final saved = await _storage.getThemeMode();
    _themeMode = switch (saved) {
      'dark' => ThemeMode.dark,
      'system' => ThemeMode.system,
      _ => ThemeMode.light,
    };
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _themeMode = _themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await _storage.saveThemeMode(_themeMode.name);
    notifyListeners();
  }

  Future<void> setTheme(ThemeMode mode) async {
    _themeMode = mode;
    await _storage.saveThemeMode(mode.name);
    notifyListeners();
  }
}
