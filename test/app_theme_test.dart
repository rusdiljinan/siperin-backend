import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inventaris_instansi/core/theme/app_colors.dart';
import 'package:inventaris_instansi/core/theme/app_theme.dart';
import 'package:inventaris_instansi/providers/theme_provider.dart';
import 'package:inventaris_instansi/services/storage_service.dart';

void main() {
  test('light and dark themes use the requested palette', () {
    final light = AppTheme.lightTheme();
    final dark = AppTheme.darkTheme();

    expect(light.scaffoldBackgroundColor, AppColors.paper);
    expect(light.colorScheme.primary, AppColors.paleGold);
    expect(light.colorScheme.secondary, AppColors.silk);
    expect(light.colorScheme.onSurface, AppColors.charcoal);
    expect(light.colorScheme.surfaceContainerHighest, AppColors.silk);
    expect(dark.scaffoldBackgroundColor, AppColors.darkBackground);
    expect(dark.colorScheme.surface, AppColors.charcoal);
    expect(dark.colorScheme.onSurface, AppColors.paper);
    expect(dark.colorScheme.surfaceContainerHighest, AppColors.darkSecondary);
  });

  test('system theme selection is persisted and restored', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = StorageService();
    final provider = ThemeProvider(storage);

    await provider.loadTheme();
    expect(provider.themeMode, ThemeMode.light);

    await provider.setTheme(ThemeMode.system);
    expect(await storage.getThemeMode(), 'system');

    final restoredProvider = ThemeProvider(storage);
    await restoredProvider.loadTheme();
    expect(restoredProvider.themeMode, ThemeMode.system);

    provider.dispose();
    restoredProvider.dispose();
  });
}
