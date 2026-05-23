// Sales trend card: chart-type toggle (Mixed / Area / Bar / Line) +
// interval dropdown (Day / Week / Month). Renders via fl_chart with two
// y-axes (left = orders count, right = ₹). Cached list pattern — keeps
// previous render visible during refetch.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../application/analytics_providers.dart';
import '../../application/date_range_provider.dart';
import '../../data/analytics_models.dart';
import '../../util/format.dart';
import '_tokens.dart';

const _bookingsColor  = kGreen;
const _deliveredColor = kViolet;
const _cancelledColor = kRose;
const _paidColor      = kP;
const _ordersColor    = kIndigo;

class SalesTrendCard extends ConsumerWidget {
  const SalesTrendCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.sizeOf(context).width;
    final filter = ref.watch(analyticsFilterProvider);
    final params = TrendParams(
      from: filter.from, to: filter.to,
      interval: filter.interval.api,
      dealerId: filter.dealerId, salesmanId: filter.salesmanId,
    );
    final async$ = ref.watch(salesTrendProvider(params));

    return AnalyticsCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnalyticsCardHeader(
          title: 'Sales Trend',
          subtitle: 'Bookings, delivered & paid over time',
          trailing: _IntervalDropdown(value: filter.interval, onChanged: (i) {
            ref.read(analyticsFilterProvider.notifier).setInterval(i);
          }),
        ),
        SizedBox(height: sw * 0.025),
        _ChartTypeRow(value: filter.chartType, onChanged: (t) {
          ref.read(analyticsFilterProvider.notifier).setChartType(t);
        }),
        SizedBox(height: sw * 0.03),

        Builder(builder: (_) {
          final cached = async$.valueOrNull;
          if (cached == null) {
            if (async$.hasError) return const ErrorCardBody();
            return const LoadingCardBody();
          }
          if (cached.series.isEmpty) {
            return const EmptyCardBody(
                message: 'No trend data for this range');
          }
          return _Chart(series: cached.series, chartType: filter.chartType);
        }),

        SizedBox(height: sw * 0.02),
        const _Legend(),
      ],
    ));
  }
}

// ── Interval dropdown ───────────────────────────────────────────────────────
class _IntervalDropdown extends StatelessWidget {
  const _IntervalDropdown({required this.value, required this.onChanged});
  final TrendInterval value;
  final ValueChanged<TrendInterval> onChanged;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.025).clamp(8.0, 12.0), vertical: 2),
      decoration: BoxDecoration(
        color: kBg, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kBd, width: 0.5),
      ),
      child: DropdownButton<TrendInterval>(
        value: value,
        isDense: true,
        underline: const SizedBox.shrink(),
        icon: Icon(Icons.keyboard_arrow_down_rounded,
            size: (sw * 0.045).clamp(14.0, 18.0), color: kT3),
        style: TextStyle(
            fontSize: (sw * 0.03).clamp(10.0, 13.0),
            fontWeight: FontWeight.w700, color: kT1),
        items: TrendInterval.values
            .map((i) => DropdownMenuItem(value: i, child: Text(i.label)))
            .toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    );
  }
}

// ── Chart type toggle row ───────────────────────────────────────────────────
class _ChartTypeRow extends StatelessWidget {
  const _ChartTypeRow({required this.value, required this.onChanged});
  final TrendChartType value;
  final ValueChanged<TrendChartType> onChanged;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    const all = TrendChartType.values;
    const labels = {
      TrendChartType.mixed: 'Mixed',
      TrendChartType.area: 'Area',
      TrendChartType.bar: 'Bar',
      TrendChartType.line: 'Line',
    };
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(children: [
        for (final t in all) ...[
          ChipToggle(
            label: labels[t]!,
            selected: t == value,
            onTap: () => onChanged(t),
          ),
          SizedBox(width: sw * 0.02),
        ],
      ]),
    );
  }
}

// ── The chart itself ────────────────────────────────────────────────────────
class _Chart extends StatelessWidget {
  const _Chart({required this.series, required this.chartType});
  final List<TrendPoint> series;
  final TrendChartType chartType;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final h = (sw * 0.62).clamp(220.0, 320.0);

    if (chartType == TrendChartType.bar) {
      return SizedBox(height: h, child: _BarChart(series: series));
    }
    return SizedBox(height: h, child: _LineChart(
        series: series, chartType: chartType));
  }
}

// ── Line / Area / Mixed (we render lines for revenue + optional fill) ──────
class _LineChart extends StatelessWidget {
  const _LineChart({required this.series, required this.chartType});
  final List<TrendPoint> series;
  final TrendChartType chartType;

  @override
  Widget build(BuildContext context) {
    final maxRevenue = _maxOf(series, (p) =>
        [p.revenue, p.delivered, p.cancelled, p.paid].reduce(_max));
    final maxOrders = _maxOf(series, (p) => p.orders.toDouble());

    final fill = chartType == TrendChartType.area
        || chartType == TrendChartType.mixed;

    LineChartBarData line(double Function(TrendPoint) y, Color c,
        {bool isOrders = false}) {
      final spots = <FlSpot>[
        for (var i = 0; i < series.length; i++)
          FlSpot(i.toDouble(),
              isOrders
                  ? (maxOrders == 0 ? 0 : (y(series[i]) / maxOrders))
                  : (maxRevenue == 0 ? 0 : (y(series[i]) / maxRevenue))),
      ];
      return LineChartBarData(
        spots: spots,
        isCurved: true, curveSmoothness: 0.22,
        color: c, barWidth: 2.4,
        dotData: const FlDotData(show: false),
        belowBarData: fill && !isOrders
            ? BarAreaData(show: true,
                color: c.withValues(alpha: 0.12))
            : BarAreaData(show: false),
      );
    }

    return LineChart(LineChartData(
      minY: 0, maxY: 1.05,
      gridData: FlGridData(show: true, horizontalInterval: 0.25,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: kBdSoft, strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: _titles(series, maxRevenue, maxOrders),
      lineTouchData: LineTouchData(
        touchTooltipData: LineTouchTooltipData(
          getTooltipColor: (_) => kT1.withValues(alpha: 0.92),
          getTooltipItems: (spots) {
            if (spots.isEmpty) return const [];
            final i = spots.first.x.toInt().clamp(0, series.length - 1);
            final p = series[i];
            return [
              for (final s in spots)
                LineTooltipItem(
                  _tooltipLine(p, s.barIndex, maxRevenue, maxOrders),
                  const TextStyle(
                      color: Colors.white, fontSize: 10.5,
                      fontWeight: FontWeight.w600),
                ),
            ];
          },
        ),
      ),
      lineBarsData: [
        line((p) => p.revenue,   _bookingsColor),
        line((p) => p.delivered, _deliveredColor),
        line((p) => p.cancelled, _cancelledColor),
        line((p) => p.paid,      _paidColor),
        line((p) => p.orders.toDouble(), _ordersColor, isOrders: true),
      ],
    ));
  }
}

String _tooltipLine(TrendPoint p, int barIndex,
    double maxRev, double maxOrders) {
  switch (barIndex) {
    case 0: return 'Bookings  ${formatINRFull(p.revenue)}';
    case 1: return 'Delivered ${formatINRFull(p.delivered)}';
    case 2: return 'Cancelled ${formatINRFull(p.cancelled)}';
    case 3: return 'Paid      ${formatINRFull(p.paid)}';
    default: return 'Orders    ${formatCount(p.orders)}';
  }
}

// ── Bar chart variant ───────────────────────────────────────────────────────
class _BarChart extends StatelessWidget {
  const _BarChart({required this.series});
  final List<TrendPoint> series;

  @override
  Widget build(BuildContext context) {
    final maxR = _maxOf(series, (p) =>
        [p.revenue, p.delivered, p.cancelled, p.paid].reduce(_max));

    return BarChart(BarChartData(
      maxY: 1.05,
      gridData: FlGridData(show: true, horizontalInterval: 0.25,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) =>
              const FlLine(color: kBdSoft, strokeWidth: 1)),
      borderData: FlBorderData(show: false),
      titlesData: _titles(series, maxR, 0),
      barTouchData: BarTouchData(
        touchTooltipData: BarTouchTooltipData(
          getTooltipColor: (_) => kT1.withValues(alpha: 0.92),
          getTooltipItem: (g, _, __, ___) {
            final p = series[g.x.toInt()];
            return BarTooltipItem(
              'Bookings ${formatINRFull(p.revenue)}\n'
              'Delivered ${formatINRFull(p.delivered)}',
              const TextStyle(
                  color: Colors.white, fontSize: 10.5,
                  fontWeight: FontWeight.w600),
            );
          },
        ),
      ),
      barGroups: [
        for (var i = 0; i < series.length; i++)
          BarChartGroupData(x: i, barsSpace: 2, barRods: [
            BarChartRodData(
              toY: maxR == 0 ? 0 : (series[i].revenue / maxR),
              color: _bookingsColor, width: 6,
              borderRadius: BorderRadius.circular(2),
            ),
            BarChartRodData(
              toY: maxR == 0 ? 0 : (series[i].delivered / maxR),
              color: _deliveredColor, width: 6,
              borderRadius: BorderRadius.circular(2),
            ),
          ]),
      ],
    ));
  }
}

// ── Axes / titles (shared between Line + Bar) ──────────────────────────────
FlTitlesData _titles(List<TrendPoint> series, double maxRev, double maxOrders) {
  return FlTitlesData(
    show: true,
    rightTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: maxOrders > 0,
        reservedSize: 38,
        getTitlesWidget: (v, _) {
          final realCount = (v * maxOrders).round();
          return Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(formatCount(realCount),
                style: const TextStyle(
                    fontSize: 9, color: kT4, fontWeight: FontWeight.w600)),
          );
        },
      ),
    ),
    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true, reservedSize: 44,
        getTitlesWidget: (v, _) {
          final realRev = v * maxRev;
          return Padding(
            padding: const EdgeInsets.only(right: 4),
            child: Text(formatINR(realRev),
                style: const TextStyle(
                    fontSize: 9, color: kT4, fontWeight: FontWeight.w600)),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true, reservedSize: 22,
        interval: (series.length / 5).clamp(1, double.infinity).toDouble(),
        getTitlesWidget: (v, _) {
          final i = v.toInt();
          if (i < 0 || i >= series.length) return const SizedBox.shrink();
          final d = series[i].date;
          return Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(DateFormat('d MMM').format(d),
                style: const TextStyle(
                    fontSize: 9, color: kT4, fontWeight: FontWeight.w600)),
          );
        },
      ),
    ),
  );
}

double _maxOf<T>(List<T> xs, double Function(T) f) {
  double m = 0;
  for (final x in xs) {
    final v = f(x);
    if (v > m) m = v;
  }
  return m;
}

double _max(double a, double b) => a > b ? a : b;

// ── Legend ──────────────────────────────────────────────────────────────────
class _Legend extends StatelessWidget {
  const _Legend();
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    Widget dot(Color c, String label) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
              width: 8, height: 8,
              decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          SizedBox(width: sw * 0.014),
          Text(label, style: TextStyle(
              fontSize: (sw * 0.026).clamp(9.0, 11.5),
              color: kT3, fontWeight: FontWeight.w600)),
        ]);
    return Wrap(spacing: sw * 0.03, runSpacing: 6, children: [
      dot(_bookingsColor, 'Bookings'),
      dot(_deliveredColor, 'Delivered'),
      dot(_cancelledColor, 'Cancelled'),
      dot(_paidColor, 'Paid'),
      dot(_ordersColor, 'Orders'),
    ]);
  }
}
