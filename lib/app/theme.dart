import 'package:flutter/material.dart';

/// Palette sampled from [assets/branding/app-icon.png]:
/// forest green field, cream meeple, gold tally badge, terracotta corner.
class AppTheme {
  static const forest = Color(0xFF0E593A);
  static const forestDeep = Color(0xFF073D28);
  static const cream = Color(0xFFFDF5E0);
  static const gold = Color(0xFFDEA939);
  static const terracotta = Color(0xFFD4683A);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.light,
    ).copyWith(
      primary: forest,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFFD5EDE3),
      onPrimaryContainer: forestDeep,
      secondary: terracotta,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFF8DCCF),
      onSecondaryContainer: const Color(0xFF6B2A14),
      tertiary: gold,
      onTertiary: const Color(0xFF3D2A08),
      tertiaryContainer: const Color(0xFFF6E2B3),
      onTertiaryContainer: const Color(0xFF3D2A08),
      surface: cream,
      surfaceContainerLowest: const Color(0xFFFFFBF3),
      surfaceContainerLow: const Color(0xFFF7ECD4),
      outline: const Color(0xFF8A9A86),
    );
    return _fromScheme(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: forest,
      brightness: Brightness.dark,
    ).copyWith(
      primary: const Color(0xFF7DCEA0),
      onPrimary: forestDeep,
      secondary: const Color(0xFFE07A4A),
      onSecondary: Colors.white,
      tertiary: gold,
      onTertiary: const Color(0xFF3D2A08),
      surface: const Color(0xFF10241C),
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
        backgroundColor: forest,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: Colors.white),
        actionsIconTheme: IconThemeData(color: Colors.white),
      ),
      cardTheme: CardThemeData(
        elevation: 3,
        shadowColor: forest.withValues(alpha: 0.18),
        color: scheme.surfaceContainerLowest,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
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
