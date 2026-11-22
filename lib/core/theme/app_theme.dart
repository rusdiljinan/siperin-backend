import 'package:flutter/material.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData lightTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.paleGold,
          brightness: Brightness.light,
          primary: AppColors.paleGold,
          onPrimary: AppColors.charcoal,
          secondary: AppColors.silk,
          onSecondary: AppColors.charcoal,
          surface: AppColors.white,
          onSurface: AppColors.charcoal,
          error: AppColors.error,
          onError: AppColors.white,
          outline: AppColors.textGray,
          outlineVariant: AppColors.silk,
        ).copyWith(
          surfaceContainerLow: AppColors.paper,
          surfaceContainer: AppColors.silk,
          surfaceContainerHigh: AppColors.silk,
          surfaceContainerHighest: AppColors.silk,
        );

    return _theme(
      colorScheme: colorScheme,
      brightness: Brightness.light,
      scaffoldBackgroundColor: AppColors.paper,
      appBarColor: AppColors.white,
      cardColor: AppColors.white,
      inputColor: AppColors.white,
      borderColor: AppColors.silk,
      mutedColor: AppColors.textGray,
    );
  }

  static ThemeData darkTheme() {
    final colorScheme =
        ColorScheme.fromSeed(
          seedColor: AppColors.paleGold,
          brightness: Brightness.dark,
          primary: AppColors.paleGold,
          onPrimary: AppColors.charcoal,
          secondary: AppColors.silk,
          onSecondary: AppColors.charcoal,
          surface: AppColors.charcoal,
          onSurface: AppColors.paper,
          error: AppColors.darkError,
          onError: AppColors.white,
          outline: AppColors.darkBorder,
          outlineVariant: AppColors.darkBorder,
        ).copyWith(
          surfaceContainerLow: AppColors.darkBackground,
          surfaceContainer: AppColors.darkSecondary,
          surfaceContainerHigh: AppColors.darkSecondary,
          surfaceContainerHighest: AppColors.darkSecondary,
        );

    return _theme(
      colorScheme: colorScheme,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: AppColors.darkBackground,
      appBarColor: AppColors.charcoal,
      cardColor: AppColors.charcoal,
      inputColor: AppColors.darkSecondary,
      borderColor: AppColors.darkBorder,
      mutedColor: AppColors.silk,
    );
  }

  static ThemeData _theme({
    required ColorScheme colorScheme,
    required Brightness brightness,
    required Color scaffoldBackgroundColor,
    required Color appBarColor,
    required Color cardColor,
    required Color inputColor,
    required Color borderColor,
    required Color mutedColor,
  }) {
    final isDark = brightness == Brightness.dark;
    final border = OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: BorderSide(color: borderColor),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: scaffoldBackgroundColor,
      fontFamily: 'Roboto',
      appBarTheme: AppBarTheme(
        backgroundColor: appBarColor,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 0 : 1,
        shadowColor: AppColors.charcoal.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(8),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputColor,
        border: border,
        enabledBorder: border,
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.paleGold, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        hintStyle: TextStyle(color: mutedColor),
        labelStyle: TextStyle(color: mutedColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.paleGold,
          foregroundColor: AppColors.charcoal,
          overlayColor: AppColors.charcoal.withValues(alpha: 0.08),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          elevation: isDark ? 0 : 1,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.paleGold,
          foregroundColor: AppColors.charcoal,
          overlayColor: AppColors.charcoal.withValues(alpha: 0.08),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          side: BorderSide(color: borderColor),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? AppColors.paleGold : AppColors.charcoal,
          overlayColor: AppColors.paleGold.withValues(alpha: 0.14),
        ),
      ),
      iconButtonTheme: IconButtonThemeData(
        style: IconButton.styleFrom(
          foregroundColor: colorScheme.onSurface,
          overlayColor: AppColors.paleGold.withValues(alpha: 0.16),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: appBarColor,
        indicatorColor: AppColors.paleGold.withValues(alpha: 0.3),
        labelTextStyle: WidgetStateProperty.all(
          TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: colorScheme.onSurface,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: appBarColor,
        indicatorColor: AppColors.paleGold.withValues(alpha: 0.3),
        selectedIconTheme: const IconThemeData(color: AppColors.charcoal),
        unselectedIconTheme: IconThemeData(color: mutedColor),
      ),
      drawerTheme: DrawerThemeData(backgroundColor: AppColors.charcoal),
      dividerTheme: DividerThemeData(color: borderColor),
      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStatePropertyAll(
          AppColors.paleGold.withValues(alpha: isDark ? 0.2 : 0.32),
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return AppColors.paleGold.withValues(alpha: 0.12);
          }
          return null;
        }),
        dividerThickness: 0.7,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        titleTextStyle: TextStyle(
          color: colorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        contentTextStyle: TextStyle(color: colorScheme.onSurface),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: isDark ? AppColors.darkSecondary : AppColors.charcoal,
        contentTextStyle: const TextStyle(color: AppColors.paper),
        actionTextColor: AppColors.paleGold,
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: isDark ? AppColors.silk : AppColors.charcoal,
          borderRadius: BorderRadius.circular(6),
        ),
        textStyle: TextStyle(
          color: isDark ? AppColors.charcoal : AppColors.paper,
        ),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.paleGold,
        linearTrackColor: isDark ? AppColors.darkBorder : AppColors.silk,
      ),
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.darkSecondary : AppColors.silk,
        selectedColor: AppColors.paleGold,
        secondarySelectedColor: AppColors.paleGold,
        labelStyle: TextStyle(color: colorScheme.onSurface),
        side: BorderSide(color: borderColor),
      ),
    );
  }
}
