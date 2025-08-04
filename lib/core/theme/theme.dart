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

  // ✅ Light Colors
  static const Color skyBlue = Color(0xFFE8F7FD);
  static const Color darkGrey = Color(0xFF0C1011);
  static const Color softIndigo = Color(0xFF7573C3);
  static const Color pureWhite = Color(0xFFFFFFFF);
  static const Color softLavender = Color(0xFFF4EDFF);
  static const Color mintWhite = Color(0xFFEBFFFD);
  static const Color softGreen = Color(0xFFEDFFE5);
  static const Color lightPink = Color(0xFFFDF0F7);
  static const Color lightBlue = Color(0xFFE6F2FE);
  static const Color paleYellow = Color(0xFFFFFBDD);
  static const Color softBlueWhite = Color(0xFFF3FBFF);
  static const Color paleBlue = Color(0xFFF5F6FF);
  static const Color softPink = Color(0xFFFAE1EE);
  static const Color lightGrey = Color(0xFFF3F3F6);

  // ✅ Dark Colors
  static const Color darkGray = Color(0xFF111111);
  static const Color deepGray = Color(0xFF222222);
  static const Color darkGreyOpposite = Color(0xFF0C0C09);

  // ✅ Text Styles
  static const TextStyle appTitle1 = TextStyle(fontSize: 18, color: Colors.white);
  static const TextStyle appTitle2 = TextStyle(fontSize: 18, color: Colors.black);
  static const TextStyle normalText1 = TextStyle(fontSize: 16, color: Colors.white);
  static const TextStyle normalText2 = TextStyle(fontSize: 16, color: Colors.black);
  static const TextStyle normalText3 = TextStyle(fontSize: 10, color: Colors.white);
  static const TextStyle normalText6 = TextStyle(fontSize: 10, color: Colors.black);
  static const TextStyle normalText4 = TextStyle(fontSize: 22, color: Colors.white);
  static const TextStyle normalText5 = TextStyle(fontSize: 22, color: Colors.black);
  static const TextStyle smallText1 = TextStyle(fontSize: 14, color: Colors.black);
  static const TextStyle smallText2 = TextStyle(fontSize: 14, color: Colors.white);
  static const TextStyle labelText = TextStyle(fontSize: 12, color: Colors.white);
  static const TextStyle labelText1 = TextStyle(fontSize: 12, color: Colors.black);

  // ✅ Light Theme
  static final ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    primaryColor: softIndigo,
    scaffoldBackgroundColor: pureWhite,
    cardColor: paleBlue,
    focusColor: lightGrey,
    textTheme: const TextTheme(
      displayLarge: appTitle2,
      displayMedium: appTitle1,
      bodyLarge: normalText2,
      bodyMedium: normalText1,
      bodySmall: normalText3,
      titleLarge: normalText4,
      titleMedium: normalText5,
      titleSmall: normalText6,
      labelLarge: labelText1,
      labelMedium: labelText,
      labelSmall: smallText1,
      headlineSmall: smallText1,
    ),
  );

  // ✅ Dark Theme
  static final ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    primaryColor: softIndigo,
    scaffoldBackgroundColor: darkGray,
    cardColor: darkGrey,
    focusColor: darkGrey,
    textTheme: const TextTheme(
      displayLarge: appTitle1,
      displayMedium: appTitle2,
      bodyLarge: normalText1,
      bodyMedium: normalText2,
      bodySmall: normalText3,
      titleLarge: normalText5,
      titleMedium: normalText4,
      titleSmall: normalText6,
      labelLarge: labelText,
      labelMedium: labelText1,
      labelSmall: smallText2,
      headlineSmall: smallText2,
    ),
  );
}
