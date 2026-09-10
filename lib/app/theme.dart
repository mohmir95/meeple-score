import 'package:flutter/material.dart';

/// Brand color requested for the UI: #3498DB.
class AppTheme {
  static const brand = Color(0xFF3498DB);
  static const brandDeep = Color(0xFF1F6FAD);
  static const canvas = Color(0xFFF4F8FC);
  static const gold = Color(0xFFF5B942);
  static const terracotta = Color(0xFFE67E22);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.light,
    ).copyWith(
      primary: brand,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD6EAF8),
      onPrimaryContainer: brandDeep,
      secondary: terracotta,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFDEBD0),
      onSecondaryContainer: const Color(0xFF6E2C00),
      tertiary: gold,
      onTertiary: const Color(0xFF3D2A08),
      tertiaryContainer: const Color(0xFFF8E5B0),
      onTertiaryContainer: const Color(0xFF3D2A08),
      surface: canvas,
      surfaceContainerLowest: Colors.white,
      surfaceContainerLow: const Color(0xFFEAF3FA),
      outline: const Color(0xFF8AA4B5),
    );
    return _fromScheme(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: brand,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF5DADE2),
      onPrimary: brandDeep,
      secondary: terracotta,
      onSecondary: Colors.white,
      tertiary: gold,
      onTertiary: const Color(0xFF3D2A08),
      surface: const Color(0xFF10212C),
    );
    return _fromScheme(scheme);
  }

  static ThemeData _fromScheme(ColorScheme scheme) {
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      visualDensity: VisualDensity.standard,
      scaffoldBackgroundColor: scheme.surface,
      appBarTheme: const AppBarTheme(
        backgroundColor: brand,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 18,
          fontWeight: FontWeight.w800,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 2,
        shadowColor: brand.withValues(alpha: 0.16),
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: StadiumBorder(
          side: BorderSide(color: scheme.outlineVariant),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: scheme.primary,
          foregroundColor: scheme.onPrimary,
          minimumSize: const Size(88, 48),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerLowest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
        ),
      ),
    );
  }
}
