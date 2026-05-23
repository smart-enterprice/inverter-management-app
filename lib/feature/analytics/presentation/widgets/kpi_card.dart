// Single KPI tile: label + value + optional delta % chip + icon.
// Used by the KPI strip grid on the analytics screen.

import 'package:flutter/material.dart';
import '../../util/format.dart';
import '_tokens.dart';

class KpiCard extends StatelessWidget {
  const KpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.iconColor = kP,
    this.iconBg = kPBg,
    this.delta,
    this.previousValue,
    this.deltaIsCount = false,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  /// Current and previous raw numbers — used to compute the delta chip.
  /// Pass either both or neither. If `null`, no chip is shown.
  final num? delta;
  final num? previousValue;

  /// If true, delta is interpreted as a count (no ₹). Doesn't affect math.
  final bool deltaIsCount;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;

    final showDelta = delta != null && previousValue != null;
    final d = showDelta ? deltaPct(delta, previousValue) : null;

    return Container(
      padding: EdgeInsets.all((sw * 0.035).clamp(10.0, 16.0)),
      decoration: BoxDecoration(
        color: kSurface,
        borderRadius: BorderRadius.circular((sw * 0.03).clamp(10.0, 14.0)),
        border: Border.all(color: kBd, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            Container(
              padding: EdgeInsets.all((sw * 0.018).clamp(6.0, 9.0)),
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: iconColor,
                  size: (sw * 0.038).clamp(13.0, 17.0)),
            ),
            const Spacer(),
            if (d != null && d.meaningful) _DeltaChip(text: d.text, isUp: d.isUp),
          ]),
          SizedBox(height: sw * 0.022),
          Text(label, style: TextStyle(
            fontSize: (sw * 0.028).clamp(9.5, 12.0),
            color: kT4, fontWeight: FontWeight.w600,
          )),
          SizedBox(height: sw * 0.008),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: TextStyle(
              fontSize: (sw * 0.048).clamp(16.0, 22.0),
              fontWeight: FontWeight.w800,
              color: kT1, letterSpacing: -0.3,
            )),
          ),
        ],
      ),
    );
  }
}

class _DeltaChip extends StatelessWidget {
  const _DeltaChip({required this.text, required this.isUp});
  final String text;
  final bool isUp;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final fg = isUp ? kGreen : kRed;
    final bg = isUp ? kGreenBg : kRedBg;
    final bd = isUp ? kGreenBd : kRedBd;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.018).clamp(6.0, 9.0),
          vertical: (sw * 0.005).clamp(2.0, 4.0)),
      decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(12),
        border: Border.all(color: bd, width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
            size: (sw * 0.028).clamp(9.5, 12.5), color: fg),
        SizedBox(width: sw * 0.005),
        Text(text, style: TextStyle(
          fontSize: (sw * 0.024).clamp(8.5, 11.0),
          fontWeight: FontWeight.w800, color: fg, height: 1.0,
        )),
      ]),
    );
  }
}

class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.tiles});
  final List<Widget> tiles;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final cols = sw >= 600 ? 4 : 2;
    final gap = (sw * 0.025).clamp(8.0, 14.0);
    return LayoutBuilder(builder: (_, c) {
      final tileW = (c.maxWidth - gap * (cols - 1)) / cols;
      return Wrap(
        spacing: gap, runSpacing: gap,
        children: [
          for (final t in tiles)
            SizedBox(width: tileW, child: t),
        ],
      );
    });
  }
}
