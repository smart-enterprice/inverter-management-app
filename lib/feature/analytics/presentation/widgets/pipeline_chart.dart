// Order pipeline distribution. Donut / horizontal bar toggle. Reads from
// summary.statusDistribution.

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/analytics_providers.dart';
import '../../application/date_range_provider.dart';
import '../../util/format.dart';
import '_tokens.dart';

enum _Mode { donut, bar }

const _statusOrder = [
  'PENDING', 'CONFIRMED', 'PRODUCTION', 'PACKED',
  'INVOICE', 'SHIPPED', 'DELIVERED', 'COMPLETED',
  'CANCELLED', 'REJECTED',
];

class PipelineCard extends ConsumerStatefulWidget {
  const PipelineCard({super.key});
  @override
  ConsumerState<PipelineCard> createState() => _PipelineCardState();
}

class _PipelineCardState extends ConsumerState<PipelineCard> {
  _Mode _mode = _Mode.donut;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final filter = ref.watch(analyticsFilterProvider);
    final async$ = ref.watch(summaryProvider(SummaryParams(
      from: filter.from, to: filter.to,
      dealerId: filter.dealerId, salesmanId: filter.salesmanId,
    )));

    return AnalyticsCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnalyticsCardHeader(
          title: 'Order Pipeline',
          subtitle: 'Items by current status',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            _ToggleIcon(
              icon: Icons.donut_large_rounded,
              selected: _mode == _Mode.donut,
              onTap: () => setState(() => _mode = _Mode.donut),
            ),
            SizedBox(width: sw * 0.015),
            _ToggleIcon(
              icon: Icons.bar_chart_rounded,
              selected: _mode == _Mode.bar,
              onTap: () => setState(() => _mode = _Mode.bar),
            ),
          ]),
        ),
        SizedBox(height: sw * 0.03),
        Builder(builder: (_) {
          final cached = async$.valueOrNull;
          if (cached == null) {
            if (async$.hasError) return const ErrorCardBody();
            return const LoadingCardBody();
          }
          final dist = cached.statusDistribution;
          final entries = _statusOrder
              .where((s) => (dist[s] ?? 0) > 0)
              .map((s) => MapEntry(s, dist[s]!))
              .toList();
          if (entries.isEmpty) {
            return const EmptyCardBody(
                icon: Icons.donut_large_rounded,
                message: 'No orders in this range');
          }
          if (_mode == _Mode.donut) {
            return _Donut(entries: entries);
          }
          return _Bars(entries: entries);
        }),
      ],
    ));
  }
}

class _ToggleIcon extends StatelessWidget {
  const _ToggleIcon({required this.icon, required this.selected, required this.onTap});
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final s = (sw * 0.085).clamp(30.0, 38.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: s, height: s,
        decoration: BoxDecoration(
          color: selected ? kPBg : kSurface, shape: BoxShape.circle,
          border: Border.all(color: selected ? kPBd : kBd, width: 0.5),
        ),
        child: Icon(icon,
            size: (sw * 0.045).clamp(15.0, 19.0),
            color: selected ? kP : kT3),
      ),
    );
  }
}

class _Donut extends StatelessWidget {
  const _Donut({required this.entries});
  final List<MapEntry<String, int>> entries;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final total = entries.fold<int>(0, (a, e) => a + e.value);
    return Column(children: [
      SizedBox(
        height: (sw * 0.55).clamp(180.0, 260.0),
        child: Stack(alignment: Alignment.center, children: [
          PieChart(PieChartData(
            sectionsSpace: 2,
            centerSpaceRadius: (sw * 0.14).clamp(48.0, 70.0),
            sections: [
              for (final e in entries)
                PieChartSectionData(
                  value: e.value.toDouble(),
                  title: '',
                  color: statusTone(e.key).fg,
                  radius: (sw * 0.085).clamp(26.0, 40.0),
                ),
            ],
          )),
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(formatCount(total), style: TextStyle(
                fontSize: (sw * 0.05).clamp(17.0, 22.0),
                fontWeight: FontWeight.w800, color: kT1)),
            Text('items', style: TextStyle(
                fontSize: (sw * 0.028).clamp(9.5, 12.0),
                color: kT4, fontWeight: FontWeight.w600)),
          ]),
        ]),
      ),
      SizedBox(height: sw * 0.02),
      _Legend(entries: entries, total: total),
    ]);
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.entries, required this.total});
  final List<MapEntry<String, int>> entries;
  final int total;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Wrap(spacing: sw * 0.04, runSpacing: 6, children: [
      for (final e in entries)
        Row(mainAxisSize: MainAxisSize.min, children: [
          Container(width: 9, height: 9,
            decoration: BoxDecoration(
                color: statusTone(e.key).fg, shape: BoxShape.circle)),
          SizedBox(width: sw * 0.018),
          Text('${e.key} · ${e.value}',
              style: TextStyle(
                  fontSize: (sw * 0.028).clamp(9.5, 11.5),
                  color: kT2, fontWeight: FontWeight.w600)),
        ]),
    ]);
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.entries});
  final List<MapEntry<String, int>> entries;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final max = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b);
    return Column(children: [
      for (final e in entries) Padding(
        padding: EdgeInsets.symmetric(vertical: sw * 0.012),
        child: _BarRow(label: e.key, value: e.value, max: max),
      ),
    ]);
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.max});
  final String label;
  final int value, max;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final tone = statusTone(label);
    final pct = max == 0 ? 0.0 : value / max;
    return Row(children: [
      SizedBox(
        width: (sw * 0.25).clamp(80.0, 110.0),
        child: Text(label, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: (sw * 0.028).clamp(9.5, 12.0),
                color: kT2, fontWeight: FontWeight.w700)),
      ),
      Expanded(child: Stack(children: [
        Container(height: 10,
            decoration: BoxDecoration(color: tone.bg,
                borderRadius: BorderRadius.circular(6))),
        FractionallySizedBox(widthFactor: pct,
            child: Container(height: 10,
                decoration: BoxDecoration(color: tone.fg,
                    borderRadius: BorderRadius.circular(6)))),
      ])),
      SizedBox(width: sw * 0.025),
      SizedBox(
        width: (sw * 0.1).clamp(34.0, 46.0),
        child: Text(formatCount(value),
            textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0),
                color: kT1, fontWeight: FontWeight.w700)),
      ),
    ]);
  }
}
