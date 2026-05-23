// Salesman Target vs Achievement card.
//
// IMPORTANT: this card uses its OWN month picker (◀ May 2026 ▶) — independent
// of the page-level date filter. Default is the current month (1st → today
// when current, 1st → last day when looking at previous months).

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/analytics_providers.dart';
import '../../application/date_range_provider.dart';
import '../../data/analytics_models.dart';
import '../../util/format.dart';
import '_tokens.dart';

class AchievementCard extends ConsumerWidget {
  const AchievementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.sizeOf(context).width;
    final monthStart = ref.watch(achievementMonthProvider);
    final notifier = ref.read(achievementMonthProvider.notifier);
    final isCurrent = notifier.isCurrentMonth;
    final dealerId = ref.watch(analyticsFilterProvider).dealerId;

    final now = DateTime.now();
    final from = monthStart;
    final to = isCurrent
        ? DateTime(now.year, now.month, now.day)
        : DateTime(monthStart.year, monthStart.month + 1, 0);

    final async$ = ref.watch(achievementProvider(AchievementParams(
      from: from, to: to, dealerId: dealerId,
    )));

    return AnalyticsCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnalyticsCardHeader(
          title: 'Target vs Achievement',
          subtitle: 'Salesman targets for the month',
          trailing: _MonthPicker(
            month: monthStart,
            canGoNext: !isCurrent,
            onPrev: () => notifier.prev(),
            onNext: () => notifier.next(),
          ),
        ),
        SizedBox(height: sw * 0.03),
        Builder(builder: (_) {
          final cached = async$.valueOrNull;
          if (cached == null) {
            if (async$.hasError) return const ErrorCardBody();
            return const LoadingCardBody(height: 220);
          }
          if (cached.items.isEmpty) {
            return const EmptyCardBody(
                icon: Icons.flag_outlined,
                message: 'No salesman activity this month');
          }
          return _Chart(data: cached);
        }),
      ],
    ));
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({
    required this.month, required this.canGoNext,
    required this.onPrev, required this.onNext,
  });
  final DateTime month;
  final bool canGoNext;
  final VoidCallback onPrev, onNext;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final label = DateFormat('MMM yyyy').format(month);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.015, vertical: 2),
      decoration: BoxDecoration(
        color: kBg, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: kBd, width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: onPrev,
          icon: Icon(Icons.chevron_left_rounded,
              size: (sw * 0.05).clamp(16.0, 22.0), color: kT2),
        ),
        SizedBox(
          width: (sw * 0.18).clamp(70.0, 96.0),
          child: Text(label, textAlign: TextAlign.center,
              style: TextStyle(
                  fontSize: (sw * 0.03).clamp(10.5, 13.5),
                  fontWeight: FontWeight.w700, color: kT1)),
        ),
        IconButton(
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 28, minHeight: 28),
          onPressed: canGoNext ? onNext : null,
          icon: Icon(Icons.chevron_right_rounded,
              size: (sw * 0.05).clamp(16.0, 22.0),
              color: canGoNext ? kT2 : kT4),
        ),
      ]),
    );
  }
}

class _Chart extends StatelessWidget {
  const _Chart({required this.data});
  final AchievementResponse data;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final items = data.items;
    final maxV = items
        .map((e) => e.targetQty > e.achievedQty ? e.targetQty : e.achievedQty)
        .fold<int>(0, (a, b) => b > a ? b : a)
        .toDouble();

    // We render rows rather than a single BarChart because per-row labels
    // (% achieved + name + numbers) are clearer than X-axis labels on mobile.
    return Column(children: [
      for (final it in items) Padding(
        padding: EdgeInsets.symmetric(vertical: sw * 0.018),
        child: _Row(item: it, maxV: maxV),
      ),
      SizedBox(height: sw * 0.02),
      _ChartBars(items: items),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.item, required this.maxV});
  final AchievementItem item;
  final double maxV;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final tgtPct = maxV == 0 ? 0.0 : item.targetQty / maxV;
    final achPct = maxV == 0 ? 0.0 : item.achievedQty / maxV;
    final pctText = '${item.achievementPct.toStringAsFixed(0)}%';
    final pctColor = item.achievementPct >= 100
        ? kGreen
        : item.achievementPct >= 60 ? kAmber : kRed;

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(child: Text(item.salesmanName,
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: (sw * 0.032).clamp(11.0, 14.0),
                fontWeight: FontWeight.w700, color: kT1))),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.022, vertical: 2),
          decoration: BoxDecoration(
            color: pctColor.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
                color: pctColor.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Text(pctText, style: TextStyle(
              fontSize: (sw * 0.028).clamp(9.5, 12.0),
              fontWeight: FontWeight.w800, color: pctColor)),
        ),
      ]),
      SizedBox(height: sw * 0.015),
      // Target bar (grey)
      Stack(children: [
        Container(height: 7, decoration: BoxDecoration(
            color: kBdSoft, borderRadius: BorderRadius.circular(4))),
        FractionallySizedBox(widthFactor: tgtPct,
            child: Container(height: 7, decoration: BoxDecoration(
                color: kT4.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(4)))),
      ]),
      SizedBox(height: 4),
      // Achievement bar (green)
      Stack(children: [
        Container(height: 7, decoration: BoxDecoration(
            color: kGreenBg, borderRadius: BorderRadius.circular(4))),
        FractionallySizedBox(widthFactor: achPct,
            child: Container(height: 7, decoration: BoxDecoration(
                color: kGreen, borderRadius: BorderRadius.circular(4)))),
      ]),
      SizedBox(height: 6),
      Row(children: [
        _Tag(color: kT4, label: 'Target ${item.targetQty}'),
        SizedBox(width: sw * 0.02),
        _Tag(color: kGreen, label: 'Done ${item.achievedQty}'),
        const Spacer(),
        Text(formatINR(item.revenue),
            style: TextStyle(
                fontSize: (sw * 0.028).clamp(9.5, 12.0),
                color: kT3, fontWeight: FontWeight.w700)),
      ]),
    ]);
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.color, required this.label});
  final Color color;
  final String label;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 7, height: 7,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
      SizedBox(width: sw * 0.014),
      Text(label, style: TextStyle(
          fontSize: (sw * 0.026).clamp(9.0, 11.5),
          color: kT3, fontWeight: FontWeight.w600)),
    ]);
  }
}

// ── Optional summary grouped-bar chart (kept compact at the bottom) ───────
class _ChartBars extends StatelessWidget {
  const _ChartBars({required this.items});
  final List<AchievementItem> items;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final h = (sw * 0.45).clamp(140.0, 200.0);
    final maxV = items
        .map((e) => e.targetQty > e.achievedQty ? e.targetQty : e.achievedQty)
        .fold<int>(0, (a, b) => b > a ? b : a)
        .toDouble();
    if (maxV == 0) return const SizedBox.shrink();
    return SizedBox(
      height: h,
      child: BarChart(BarChartData(
        maxY: maxV * 1.1,
        gridData: FlGridData(show: true, horizontalInterval: maxV / 4,
            drawVerticalLine: false,
            getDrawingHorizontalLine: (_) =>
                const FlLine(color: kBdSoft, strokeWidth: 1)),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 30,
              getTitlesWidget: (v, _) => Text(formatCount(v),
                  style: const TextStyle(
                      fontSize: 9, color: kT4,
                      fontWeight: FontWeight.w600)))),
          bottomTitles: AxisTitles(sideTitles: SideTitles(
              showTitles: true, reservedSize: 28,
              interval: (items.length / 5)
                  .clamp(1, double.infinity).toDouble(),
              getTitlesWidget: (v, _) {
                final i = v.toInt();
                if (i < 0 || i >= items.length) return const SizedBox.shrink();
                final name = items[i].salesmanName;
                final short = name.length > 6
                    ? '${name.substring(0, 6)}…' : name;
                return Padding(padding: const EdgeInsets.only(top: 4),
                    child: Text(short, style: const TextStyle(
                        fontSize: 9, color: kT4,
                        fontWeight: FontWeight.w600)));
              })),
        ),
        barGroups: [
          for (var i = 0; i < items.length; i++)
            BarChartGroupData(x: i, barsSpace: 2, barRods: [
              BarChartRodData(
                toY: items[i].targetQty.toDouble(),
                color: kT4.withValues(alpha: 0.6), width: 7,
                borderRadius: BorderRadius.circular(2),
              ),
              BarChartRodData(
                toY: items[i].achievedQty.toDouble(),
                color: kGreen, width: 7,
                borderRadius: BorderRadius.circular(2),
              ),
            ]),
        ],
      )),
    );
  }
}
