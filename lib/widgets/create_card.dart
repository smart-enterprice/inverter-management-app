import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/media_query/media_query.dart';

class CreateCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final Color color;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;

  const CreateCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.color,
    required this.iconColor,
    required this.onTap,
    required this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: Screen.h(context) * 0.09,
        width: Screen.w(context) * 0.2,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              backgroundColor: backgroundColor,
              radius: Screen.w(context) * 0.04,
              child: SvgPicture.asset(
                iconPath,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                height: Screen.w(context) * 0.05,
              ),
            ),
            SizedBox(height: Screen.h(context) * 0.01),
            Text(
              title,
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
