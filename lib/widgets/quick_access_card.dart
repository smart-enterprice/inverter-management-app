import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';

// ── Shared QuickAccessCard ────────────────────────────────────────────────────
// Previously copy-pasted identically into ControlPanel, SalesmanPanel,
// PackingPanel, ProductionPanel, DeliveryPanel, AccountantPanel.
// Now lives here once — all panels import from this file.

class QuickAccessCard extends StatefulWidget {
  const QuickAccessCard({
    super.key,
    required this.title,
    required this.iconPath,
    required this.accent,
    required this.bg,
    required this.border,
    required this.onTap,
  });

  final String title;
  final String iconPath;
  final Color accent;
  final Color bg;
  final Color border;
  final VoidCallback onTap;

  @override
  State<QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<QuickAccessCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 110),
    );
    _scale = Tween(begin: 1.0, end: 0.94).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq      = MediaQuery.of(context);
    final sw      = mq.size.width;
    final sh      = mq.size.height;
    final isTab   = sw >= 600;

    // All sizes from MediaQuery — no fixed px
    final cardW   = (sw * (isTab ? 0.16 : 0.22)).clamp(72.0, 130.0);
    final vPad    = sh * 0.018;
    final hPad    = sw * 0.02;
    final circleD = (sw * 0.12).clamp(40.0, 60.0);
    final iconSz  = (sw * 0.052).clamp(18.0, 28.0);
    final labelFs = (sw * 0.028).clamp(9.5, 13.0);
    final radius  = (sw * 0.04).clamp(10.0, 18.0);
    final gap     = sh * 0.012;

    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: cardW,
          padding: EdgeInsets.symmetric(vertical: vPad, horizontal: hPad),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(color: widget.border, width: 0.5),
            // Zoho Books uses border-only — no shadow
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Icon circle
              Container(
                width: circleD,
                height: circleD,
                decoration: BoxDecoration(
                  color: widget.bg,
                  shape: BoxShape.circle,
                  border: Border.all(color: widget.border, width: 1.0),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    widget.iconPath,
                    width: iconSz,
                    height: iconSz,
                    colorFilter:
                    ColorFilter.mode(widget.accent, BlendMode.srcIn),
                  ),
                ),
              ),
              SizedBox(height: gap),
              // Label
              Text(
                widget.title,
                style: TextStyle(
                  fontSize: labelFs,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827),
                  letterSpacing: 0.1,
                  height: 1.2,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Shared panel row builder ──────────────────────────────────────────────────
// All panel files call this instead of duplicating the Row+ScrollView logic.
Widget buildQuickAccessRow({
  required BuildContext context,
  required List<QuickAccessCardData> items,
}) {
  final sw = MediaQuery.sizeOf(context).width;
  final gap = sw * 0.03;

  return SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    physics: const BouncingScrollPhysics(),
    clipBehavior: Clip.none,
    child: Row(
      children: items.asMap().entries.map((e) {
        final isLast = e.key == items.length - 1;
        return Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : gap),
          child: QuickAccessCard(
            title: e.value.title,
            iconPath: e.value.iconPath,
            accent: e.value.accent,
            bg: e.value.bg,
            border: e.value.border,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => e.value.page),
            ),
          ),
        );
      }).toList(),
    ),
  );
}

// ── Data model for each panel item ────────────────────────────────────────────
class QuickAccessCardData {
  const QuickAccessCardData({
    required this.title,
    required this.iconPath,
    required this.accent,
    required this.bg,
    required this.border,
    required this.page,
  });

  final String title;
  final String iconPath;
  final Color accent;
  final Color bg;
  final Color border;
  final Widget page;
}