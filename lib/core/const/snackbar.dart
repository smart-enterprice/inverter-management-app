
import 'package:flutter/material.dart';

import '../theme/theme.dart';

/// Shows a floating snack bar from anywhere that has a [BuildContext].
///
/// Replaces the 30+ identical `_showSnack(msg, color)` private helpers
/// scattered across every screen file.
///
/// Usage:
/// ```dart
/// import 'package:inverter_management_app/core/const/snackbar.dart';
///
/// // success
/// showAppSnackBar(context, 'Brand created successfully!');
///
/// // error
/// showAppSnackBar(context, 'Something went wrong', isError: true);
///
/// // custom colour
/// showAppSnackBar(context, 'Item cancelled', color: AppColors.amber);
/// ```
void showAppSnackBar(
    BuildContext context,
    String message, {
      bool isError = false,
      Color? color,
      Duration duration = const Duration(seconds: 3),
      IconData? icon,
    }) {
  // Resolve background colour
  final bg = color ??
      (isError ? AppColors.red : AppColors.green);

  // Resolve leading icon
  final resolvedIcon = icon ??
      (isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded);

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        content: Row(
          children: [
            Icon(resolvedIcon, color: Colors.white, size: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
}
