// Centralised design tokens used by every analytics widget. Kept private
// to the analytics feature (file name leads with `_`).

import 'package:flutter/material.dart';

// ── Brand + text ────────────────────────────────────────────────────────────
const kP        = Color(0xFF185FA5); // primary blue
const kPBg      = Color(0xFFEBF4FF);
const kPBd      = Color(0xFFBFD9F5);
const kBg       = Color(0xFFF7F8FA);
const kSurface  = Color(0xFFFFFFFF);
const kBd       = Color(0xFFE5E7EB);
const kBdSoft   = Color(0xFFF3F4F6);
const kT1       = Color(0xFF111827);
const kT2       = Color(0xFF374151);
const kT3       = Color(0xFF6B7280);
const kT4       = Color(0xFF9CA3AF);

// ── Semantics ───────────────────────────────────────────────────────────────
const kGreen    = Color(0xFF0F6E56);
const kGreenBg  = Color(0xFFEDFAF5);
const kGreenBd  = Color(0xFF9FE0C5);
const kRed      = Color(0xFFDC2626);
const kRedBg    = Color(0xFFFEF2F2);
const kRedBd    = Color(0xFFFECACA);
const kAmber    = Color(0xFFB45309);
const kAmberBg  = Color(0xFFFFFBEB);
const kAmberBd  = Color(0xFFFCD28A);

// ── Categorical (chart palette) ─────────────────────────────────────────────
const kViolet   = Color(0xFF7C3AED);
const kRose     = Color(0xFFE11D48);
const kIndigo   = Color(0xFF4338CA);
const kBlue     = Color(0xFF0369A1);
const kTeal     = Color(0xFF0F766E);
const kOrange   = Color(0xFFEA580C);

/// Status badge colours. Falls back to neutral for unknowns.
({Color fg, Color bg, Color bd}) statusTone(String? s) {
  switch ((s ?? '').toUpperCase()) {
    case 'PENDING':    return (fg: kAmber, bg: kAmberBg, bd: kAmberBd);
    case 'CONFIRMED':  return (fg: kP, bg: kPBg, bd: kPBd);
    case 'PRODUCTION': return (fg: kOrange, bg: const Color(0xFFFFF7ED), bd: const Color(0xFFFED7AA));
    case 'PACKED':     return (fg: kViolet, bg: const Color(0xFFF5F3FF), bd: const Color(0xFFDDD6FE));
    case 'INVOICE':    return (fg: kIndigo, bg: const Color(0xFFEEF2FF), bd: const Color(0xFFC7D2FE));
    case 'SHIPPED':    return (fg: kBlue, bg: const Color(0xFFE0F2FE), bd: const Color(0xFFBAE6FD));
    case 'DELIVERED':
    case 'COMPLETED':  return (fg: kGreen, bg: kGreenBg, bd: kGreenBd);
    case 'CANCELLED':  return (fg: kRed, bg: kRedBg, bd: kRedBd);
    case 'REJECTED':   return (fg: kP, bg: kPBg, bd: kPBd);
    default:           return (fg: kT3, bg: kBdSoft, bd: kBd);
  }
}

// ── Generic card wrapper ────────────────────────────────────────────────────
class AnalyticsCard extends StatelessWidget {
  const AnalyticsCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
  });
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Container(
      margin: margin,
      padding: padding ?? EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular((sw * 0.035).clamp(10.0, 16.0)),
        border: Border.all(color: kBd, width: 0.5),
      ),
      child: child,
    );
  }
}

class AnalyticsCardHeader extends StatelessWidget {
  const AnalyticsCardHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.trailing,
  });
  final String title;
  final String? subtitle;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: TextStyle(
          fontSize: (sw * 0.038).clamp(13.0, 17.0),
          fontWeight: FontWeight.w700, color: kT1, letterSpacing: -0.2,
        )),
        if (subtitle != null)
          Padding(
            padding: EdgeInsets.only(top: sw * 0.005),
            child: Text(subtitle!, style: TextStyle(
              fontSize: (sw * 0.028).clamp(9.5, 12.0), color: kT4,
              fontWeight: FontWeight.w500,
            )),
          ),
      ])),
      if (trailing != null) trailing!,
    ]);
  }
}

class EmptyCardBody extends StatelessWidget {
  const EmptyCardBody({super.key, this.message = 'No data', this.icon});
  final String message;
  final IconData? icon;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.08),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(
          width: (sw * 0.13).clamp(44.0, 68.0),
          height: (sw * 0.13).clamp(44.0, 68.0),
          decoration: BoxDecoration(color: kBdSoft, shape: BoxShape.circle),
          child: Icon(icon ?? Icons.insights_outlined,
              size: (sw * 0.06).clamp(20.0, 32.0), color: kT4),
        ),
        SizedBox(height: sw * 0.025),
        Text(message, style: TextStyle(
          fontSize: (sw * 0.032).clamp(11.0, 14.0),
          fontWeight: FontWeight.w600, color: kT3,
        )),
      ]),
    );
  }
}

class LoadingCardBody extends StatelessWidget {
  const LoadingCardBody({super.key, this.height});
  final double? height;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return SizedBox(
      height: height ?? sw * 0.6,
      child: const Center(
        child: SizedBox(
          width: 22, height: 22,
          child: CircularProgressIndicator(color: kP, strokeWidth: 2.2),
        ),
      ),
    );
  }
}

class ErrorCardBody extends StatelessWidget {
  const ErrorCardBody({super.key, this.message = 'Couldn\'t load this'});
  final String message;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.08),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.error_outline_rounded,
            size: (sw * 0.06).clamp(20.0, 28.0), color: kRed),
        SizedBox(height: sw * 0.018),
        Text(message, style: TextStyle(
          fontSize: (sw * 0.032).clamp(11.0, 14.0),
          fontWeight: FontWeight.w600, color: kRed,
        )),
      ]),
    );
  }
}

// ── Reusable small UI atoms ─────────────────────────────────────────────────
class ChipToggle extends StatelessWidget {
  const ChipToggle({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.color = kP,
  });
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: EdgeInsets.symmetric(
            horizontal: (sw * 0.03).clamp(10.0, 14.0),
            vertical: (sw * 0.014).clamp(5.0, 8.0)),
        decoration: BoxDecoration(
          color: selected ? color : kSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : kBd, width: 0.5),
        ),
        child: Text(label, style: TextStyle(
          fontSize: (sw * 0.028).clamp(9.5, 12.5),
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : kT3,
        )),
      ),
    );
  }
}
