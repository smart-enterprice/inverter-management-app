import 'package:flutter/material.dart';

// Global variables for backward compatibility
// These should be initialized in the build method of widgets
double screenWidth = 0;
double screenHeight = 0;

class Screen {
  static double w(BuildContext context) => MediaQuery.of(context).size.width;
  static double h(BuildContext context) => MediaQuery.of(context).size.height;
}
