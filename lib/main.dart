import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/screen/splash_screen.dart';

void main() {
  runApp(const ProviderScope(child: MyApp())); // Wrap with ProviderScope
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: AppTheme.theme,
        themeMode: ThemeMode.light,
        debugShowCheckedModeBanner: false,
        home: SplashScreen());
  }
}
