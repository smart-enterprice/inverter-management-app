import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kBorder  = Color(0xFFE5E7EB);
const _kTextDark = Color(0xFF111827);
const _kTextMuted = Color(0xFF6B7280);

/// A single stat card — responsive, Zoho Books style.
///
/// Usage:
/// ```dart
/// SingleInfoCard(
///   icon: AppIcons.orders,
///   title: 'Total Orders',
///   value: '1,284',
///   iconColor: Color(0xFF185FA5),
///   iconBackground: Color(0xFFEBF4FF),
/// )
/// ```
class SingleInfoCard extends StatelessWidget {
  const SingleInfoCard({
    super.key,
    required this.icon,
    required this.title,
    required this.value,
    required this.iconBackground,
    this.iconColor = const Color(0xFF185FA5),
    this.subtitle,
    this.subtitleColor,
  });

  final String icon;
  final String title;
  final String value;
  final Color iconColor;
  final Color iconBackground;

  /// Optional small text below the value (e.g. "↑ 12% this week")
  final String? subtitle;
  final Color? subtitleColor;

  @override
  Widget build(BuildContext context) {
    final mq      = MediaQuery.of(context);
    final sw      = mq.size.width;
    final sh      = mq.size.height;
    final isTab   = sw >= 600;

    final iconBoxSz = (sw * 0.1).clamp(36.0, 52.0);
    final iconSz    = (sw * 0.052).clamp(18.0, 26.0);
    final iconR     = (sw * 0.025).clamp(8.0, 14.0);
    final titleFs   = (sw * (isTab ? 0.022 : 0.028)).clamp(10.0, 13.0);
    final valueFs   = (sw * (isTab ? 0.036 : 0.044)).clamp(14.0, 22.0);
    final subFs     = (sw * 0.024).clamp(9.0, 11.5);
    final padH      = sw * 0.04;
    final padV      = sh * 0.018;
    final gap       = sw * 0.035;
    final cardR     = (sw * 0.03).clamp(10.0, 16.0);

    return Container(
      padding: EdgeInsets.symmetric(horizontal: padH, vertical: padV),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardR),
        border: Border.all(color: _kBorder, width: 0.5),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Icon box ────────────────────────────────────────────────────
          Container(
            width: iconBoxSz,
            height: iconBoxSz,
            decoration: BoxDecoration(
              color: iconBackground,
              borderRadius: BorderRadius.circular(iconR),
            ),
            child: Center(
              child: SvgPicture.asset(
                icon,
                width: iconSz,
                height: iconSz,
                colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
              ),
            ),
          ),
          SizedBox(width: gap),

          // ── Label + value ────────────────────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: titleFs,
                    color: _kTextMuted,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: sh * 0.004),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFs,
                    color: _kTextDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.3,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle != null) ...[
                  SizedBox(height: sh * 0.003),
                  Text(
                    subtitle!,
                    style: TextStyle(
                      fontSize: subFs,
                      color: subtitleColor ?? const Color(0xFF0F6E56),
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}