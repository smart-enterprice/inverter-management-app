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
      width: width,
      height: height,
      padding:  EdgeInsets.all(screenWidth*0.03),
      decoration: BoxDecoration(
        color:Colors.white,
        borderRadius: BorderRadius.circular(screenWidth*0.03),
        border: Border.all(
          color: Colors.grey.shade300,
          width: 1,
        ),
      ),
      child: child,
    );
  }
}
