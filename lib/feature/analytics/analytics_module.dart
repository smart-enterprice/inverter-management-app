// Single import surface for the analytics feature. Pushes the screen onto
// the navigator from a tap source elsewhere in the app (e.g., dashboard
// card). Centralises the role-gate so callers don't have to repeat it.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/role/app_role.dart';
import 'presentation/screens/analytics_screen.dart';

class AnalyticsModule {
  AnalyticsModule._();

  /// Push the Analytics screen if the current role can access it.
  /// Returns true if navigation happened.
  static bool open(BuildContext context, WidgetRef ref) {
    final role = ref.read(roleNotifierProvider);
    if (!AppPermissions.canAccess(role, AppFeature.viewAnalytics)) {
      return false;
    }
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => const AnalyticsScreen(),
    ));
    return true;
  }
}
