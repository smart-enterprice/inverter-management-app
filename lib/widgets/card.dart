import 'package:flutter/material.dart';
import '../core/media_query/media_query.dart';

class BoxCard extends StatelessWidget {
  const BoxCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.color,
  });

  final Widget child;
  final double? height;
  final double? width;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 10,
        vertical: screenHeight * 0.05,
      ),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white, // white background
        borderRadius: BorderRadius.circular(
          MediaQuery.of(context).size.width * 0.04,
        ),
        border: Border.all(
          color: Colors.grey.shade300, // light grey border
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
