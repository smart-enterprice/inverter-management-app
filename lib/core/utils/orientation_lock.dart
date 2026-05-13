// lib/core/utils/orientation_lock.dart
//
// Call OrientationLock.apply(context) once in main() or in the first
// StatefulWidget that knows the screen size.
//
// Phone  (width < 600) → portrait-only
// Tablet (width ≥ 600) → landscape-only

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class OrientationLock {
  OrientationLock._();

  /// Call this inside WidgetsBinding.instance.addPostFrameCallback or
  /// inside a build method AFTER MediaQuery is available.
  static void apply(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width >= 600) {
      // Tablet → landscape only
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    } else {
      // Phone → portrait only
      SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    }
  }

  /// Call once at app start from main() before runApp to set a safe default
  /// (portrait). The real lock is applied after the first frame.
  static void setDefault() {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
}