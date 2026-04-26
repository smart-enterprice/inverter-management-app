import 'package:flutter/material.dart';

/// | NAME           | SIZE |  HEIGHT |  WEIGHT |  SPACING |             |
/// |----------------|------|---------|---------|----------|-------------|
/// | displayLarge   | 57.0 |   64.0  | regular | -0.25    |             |
/// | displayMedium  | 45.0 |   52.0  | regular |  0.0     |             |
/// | displaySmall   | 36.0 |   44.0  | regular |  0.0     |             |
/// | headlineLarge  | 32.0 |   40.0  | regular |  0.0     |             |
/// | headlineMedium | 28.0 |   36.0  | regular |  0.0     |             |
/// | headlineSmall  | 24.0 |   32.0  | regular |  0.0     |             |
/// | titleLarge     | 22.0 |   28.0  | regular |  0.0     |             |
/// | titleMedium    | 16.0 |   24.0  | medium  |  0.15    |             |
/// | titleSmall     | 14.0 |   20.0  | medium  |  0.1     |             |
/// | bodyLarge      | 16.0 |   24.0  | regular |  0.5     |             |
/// | bodyMedium     | 14.0 |   20.0  | regular |  0.25    |             |
/// | bodySmall      | 12.0 |   16.0  | regular |  0.4     |             |
/// | labelLarge     | 14.0 |   20.0  | medium  |  0.1     |             |
/// | labelMedium    | 12.0 |   16.0  | medium  |  0.5     |             |
/// | labelSmall     | 11.0 |   16.0  | medium  |  0.5     |             |
///
class AppTheme {
  // Color Palette
  static const Color primaryColor = Color(0xFF256DEB);
  static const Color accentBlue = Color(0xFF3B82F6); // Light Blue
  static const Color accentGreen = Color(0xFF10B981); // Green
  static const Color accentYellow = Color(0xFFF59E0B); // Yellow
  static const Color accentRed = Color(0xFFEF4444); // Red
  static const Color background = Color(0xFFF9FAFB); // White
  static const Color cardColor = Color(0xFFFFFFFF); // White
  static const Color textPrimary = Color(0xFF111827); // Dark Grey
  static const Color textSecondary = Color(0xFF6B7280); // Soft Grey

  // Fixed Font Sizes
  static const double fontSizeAppBarTitle = 18.0;
  static const double fontSizeBodyLarge = 16.0;
  static const double fontSizeBodyMedium = 14.0;
  static const double fontSizeLabelLarge = 14.0;

  static final ThemeData theme = ThemeData(
    brightness: Brightness.light,
    primaryColor: primaryColor,
    scaffoldBackgroundColor: background,

    appBarTheme: AppBarTheme(
      backgroundColor: background,
      elevation: 1,
      iconTheme: const IconThemeData(color: primaryColor),
      titleTextStyle: TextStyle(
        color: textPrimary,
        fontSize: fontSizeAppBarTitle,
        fontWeight: FontWeight.w600,
      ),
    ),

    textTheme: const TextTheme(
      bodyLarge: TextStyle(color: textPrimary, fontSize: fontSizeBodyLarge),
      bodyMedium: TextStyle(color: textSecondary, fontSize: fontSizeBodyMedium),
      labelLarge: TextStyle(color: Colors.white, fontSize: fontSizeLabelLarge),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),

    // outlinedButtonTheme: OutlinedButtonThemeData(
    //   style: OutlinedButton.styleFrom(
    //     foregroundColor: primaryColor,
    //     side: const BorderSide(color: Colors.grey),
    //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    //   ),
    // ),

    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.grey.shade100,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: BorderSide.none,
      ),
      hintStyle: TextStyle(color: textSecondary, fontSize: fontSizeBodyMedium),
    ),
  );
}

/// Single source of truth for all app colour constants.
///
/// Add this one import to any file that needs colours:
/// ```dart
/// import 'package:inverter_management_app/core/theme/app_colors.dart';
/// ```
abstract final class AppColors {
  // ── Brand blue ─────────────────────────────────────────────────────────────
  static const Color blue       = Color(0xFF1B4FD8);
  static const Color blueBg     = Color(0xFFEEF2FF);
  static const Color blueBorder = Color(0xFFC7D4FF);

  // ── Neutrals ───────────────────────────────────────────────────────────────
  static const Color bg     = Color(0xFFF2F4F8);
  static const Color card   = Colors.white;
  static const Color border = Color(0xFFE5E7EB);

  // ── Text ───────────────────────────────────────────────────────────────────
  static const Color dark  = Color(0xFF111827);
  static const Color mid   = Color(0xFF374151);
  static const Color muted = Color(0xFF9CA3AF);

  // ── Green ──────────────────────────────────────────────────────────────────
  static const Color green       = Color(0xFF0A8A5C);
  static const Color greenBg     = Color(0xFFEDFAF4);
  static const Color greenBorder = Color(0xFF9FE0C5);

  // ── Red ────────────────────────────────────────────────────────────────────
  static const Color red       = Color(0xFFDC2626);
  static const Color redBg     = Color(0xFFFEF2F2);
  static const Color redBorder = Color(0xFFFECACA);

  // ── Amber ──────────────────────────────────────────────────────────────────
  static const Color amber       = Color(0xFFB45309);
  static const Color amberBg     = Color(0xFFFFFBEB);
  static const Color amberBorder = Color(0xFFFCD28A);

  // ── Purple ─────────────────────────────────────────────────────────────────
  static const Color purple       = Color(0xFF7C3AED);
  static const Color purpleBg     = Color(0xFFF5F3FF);
  static const Color purpleBorder = Color(0xFFDDD6FE);

  // ── Dashboard navy ─────────────────────────────────────────────────────────
  static const Color navyDark        = Color(0xFF0F1C3F);
  static const Color navyLight       = Color(0xFF1B3A7A);
  static const Color accentBlue      = Color(0xFF4C8FFF);
  static const Color accentBlueLight = Color(0xFF90BAFF);
}