import 'package:flutter/material.dart';
import '../core/media_query/media_query.dart';

class BoxCard extends StatelessWidget {
  const BoxCard({
    super.key,
    required this.child,
    this.height,
    this.width,
    this.color,
    this.elevation = 4,
  });

  final Widget child;
  final double? height;
  final double? width;
  final Color? color;
  final double elevation;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: width ?? double.infinity,
      height: height,
      padding: EdgeInsets.all(Screen.w(context) * 0.03),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1), // shadow color
            blurRadius: elevation, // how soft the shadow is
            offset: const Offset(0, 1), // shadow direction
          ),
        ],
      ),
      child: child,
    );
  }
}
