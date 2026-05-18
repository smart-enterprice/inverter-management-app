import 'package:flutter/material.dart';

/// A global navigator key that allows navigation from anywhere in the app
/// without needing a BuildContext — used by the Dio interceptor to redirect
/// to the login screen when a 401 is received.
///
/// Register it in main.dart:
/// ```dart
/// MaterialApp(
///   navigatorKey: NavigationService.navigatorKey,
///   ...
/// )
/// ```
class NavigationService {
  NavigationService._();

  static final GlobalKey<NavigatorState> navigatorKey =
  GlobalKey<NavigatorState>();

  static final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey =
  GlobalKey<ScaffoldMessengerState>();

  static NavigatorState? get navigator => navigatorKey.currentState;

  /// Show a SnackBar from anywhere in the app — works without a BuildContext.
  static void showSnack(String message,
      {Color? bg, Duration duration = const Duration(seconds: 3)}) {
    final messenger = scaffoldMessengerKey.currentState;
    if (messenger == null) return;
    messenger.clearSnackBars();
    messenger.showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      duration: duration,
    ));
  }

  /// Navigate to a named route, clearing the entire stack.
  static void pushReplacementNamed(String routeName) {
    navigator?.pushNamedAndRemoveUntil(routeName, (_) => false);
  }

  /// Navigate to a widget, clearing the entire stack.
  static void pushAndRemoveAll(Widget page) {
    navigator?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => page),
          (_) => false,
    );
  }
}