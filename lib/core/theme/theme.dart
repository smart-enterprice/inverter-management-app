import 'package:flutter/material.dart';


class AppTheme {
  // ✅ Colors
  static const Color primaryColorLight = Color(0x669C27B0);
  static const Color primaryColor = Color(0xFF9C27B0); // Purple 500
  static const Color backgroundColor = Colors.white;
  static const Color cardColor = Colors.white;
  static const Color textPrimary = Colors.black;
  static const Color textSecondary = Color(0xFF979797); // For small text
  static const Color buttonTextColor = Colors.white;

  // ✅ Text Styles
  static const TextStyle appTitle1 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: textPrimary,
  );
  static const TextStyle appTitle2 = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w800,
    color: cardColor,
  );
  static const TextStyle normalText1 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: textPrimary,
  );
  static const TextStyle normalText3 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: textPrimary,
  );

  static const TextStyle smallText1 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );
  static const TextStyle smallText2 = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    color: textPrimary,
  );
  static const TextStyle labelText = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: textSecondary,
  );

  static const TextStyle normalText2 = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: buttonTextColor,
  );
  static const TextStyle normalText4 = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: buttonTextColor,
  );

  // ✅ Light Theme Only (No Dark Theme)
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
      bodyMedium: normalText3
    ),
  );
}
