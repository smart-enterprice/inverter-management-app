import 'package:flutter/material.dart';

class AppTheme {
  // ✅ Colors
  static const Color primaryColorLight = Color(0x669333EA);
  static const Color primaryColor = Color(0xFF9333EA);
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF979797);
  static const Color buttonTextColor = Colors.white;

  // ✅ Text Styles
  static const TextStyle appTitle1 = TextStyle(
    fontSize: 18, // Dashboard title (text-lg)
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle appTitle2 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: cardColor,
  );

  static const TextStyle normalText1 = TextStyle(
    fontSize: 16, // Card headings (text-base)
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle normalText2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: buttonTextColor,
  );

  static const TextStyle normalText3 = TextStyle(
    fontSize: 13, // Chart label (text-[13px])
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle normalText4 = TextStyle(
    fontSize: 22, // Recent Activity heading
    fontWeight: FontWeight.w700,
    color: buttonTextColor,
  );
  static const TextStyle normalText5 = TextStyle(
    fontSize: 22, // Recent Activity heading
    fontWeight: FontWeight.w700,
    color: textPrimary,
  );

  static const TextStyle smallText1 = TextStyle(
    fontSize: 14, // Card subtext (text-sm)
    fontWeight: FontWeight.w400,
    color: textSecondary,
  );

  static const TextStyle smallText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );

  static const TextStyle labelText = TextStyle(
    fontSize: 12, // Bottom nav (text-xs)
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  static const TextStyle labelText1 = TextStyle(
    fontSize: 14, // Bottom nav (text-xs)
    fontWeight: FontWeight.w600,
    color: textSecondary,
  );

  // ✅ Light Theme Only
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    textTheme: const TextTheme(
      displayLarge: appTitle1,
      displayMedium: appTitle2,
      bodyLarge: normalText1,
      bodySmall: smallText1,
      labelLarge: normalText2,
      labelSmall: labelText,
      bodyMedium: normalText3,
      titleLarge: normalText4,
    ),
  );
}
