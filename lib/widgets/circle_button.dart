import 'package:flutter/material.dart';

class CircularIconButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final double size;
  final Color? backgroundColor;
  final Color? iconColor;
  final double shadowOpacity;

  const CircularIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 42,
    this.backgroundColor,
    this.iconColor,
    this.shadowOpacity = 0.12,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: backgroundColor ?? Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: shadowOpacity),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Icon(
            icon,
            // size: size * 0.45,
            color: iconColor ?? Theme.of(context).primaryColor,
          ),
        ),
      ),
    );
  }
}
