import 'package:flutter/material.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';

class AppTheme {
  // Color Palette
  static const Color primaryColor = Color(0xFF256DEB);
  static const Color accentBlue     = Color(0xFF3B82F6); // Light Blue
  static const Color accentGreen    = Color(0xFF10B981); // Green
  static const Color accentYellow   = Color(0xFFF59E0B); // Yellow
  static const Color accentRed      = Color(0xFFEF4444); // Red
  static const Color background     = Color(0xFFF9FAFB); // White
  static const Color cardColor      = Color(0xFFFFFFFF); // White
  static const Color textPrimary    = Color(0xFF111827); // Dark Grey
  static const Color textSecondary  = Color(0xFF6B7280); // Soft Grey

  // Fixed Font Sizes
  static const double fontSizeAppBarTitle = 18.0;
  static const double fontSizeBodyLarge   = 16.0;
  static const double fontSizeBodyMedium  = 14.0;
  static const double fontSizeLabelLarge  = 14.0;

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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth*0.04)),
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
