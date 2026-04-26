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

  static NavigatorState? get navigator => navigatorKey.currentState;

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