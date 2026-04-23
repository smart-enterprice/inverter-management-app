import 'package:flutter/material.dart';

enum ScreenType { mobile, tablet }

ScreenType getScreenType(BuildContext context) {
  final width = MediaQuery.of(context).size.width;

  if (width >= 600) return ScreenType.tablet;
  return ScreenType.mobile;
}
