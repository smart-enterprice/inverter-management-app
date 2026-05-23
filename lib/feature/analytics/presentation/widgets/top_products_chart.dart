// Top products horizontal-bar card with Revenue/Qty metric toggle.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/analytics_providers.dart';
import '../../application/date_range_provider.dart';
import '../../data/analytics_models.dart';
import '../../util/format.dart';
import '_tokens.dart';

class TopProductsCard extends ConsumerStatefulWidget {
  const TopProductsCard({super.key});
  @override
  ConsumerState<TopProductsCard> createState() => _TopProductsCardState();
}

class _TopProductsCardState extends ConsumerState<TopProductsCard> {
  String _metric = 'revenue';

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final filter = ref.watch(analyticsFilterProvider);
    final async$ = ref.watch(topProductsProvider(TopMetricParams(
      from: filter.from, to: filter.to,
      limit: 10, metric: _metric,
      dealerId: filter.dealerId, salesmanId: filter.salesmanId,
    )));

    return AnalyticsCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AnalyticsCardHeader(
          title: 'Top Products',
          subtitle: 'By ${_metric == 'revenue' ? 'revenue' : 'qty sold'}',
          trailing: Row(mainAxisSize: MainAxisSize.min, children: [
            ChipToggle(label: 'Revenue',
                selected: _metric == 'revenue',
                onTap: () => setState(() => _metric = 'revenue')),
            SizedBox(width: sw * 0.015),
            ChipToggle(label: 'Qty',
                selected: _metric == 'qty',
                onTap: () => setState(() => _metric = 'qty')),
          ]),
        ),
        SizedBox(height: sw * 0.03),
        Builder(builder: (_) {
          final cached = async$.valueOrNull;
          if (cached == null) {
            if (async$.hasError) return const ErrorCardBody();
            return const LoadingCardBody(height: 200);
          }
          if (cached.isEmpty) {
            return const EmptyCardBody(
                icon: Icons.shopping_bag_outlined,
                message: 'No product sales in this range');
          }
          return _Bars(items: cached, metric: _metric);
        }),
      ],
    ));
  }
}

class _Bars extends StatelessWidget {
  const _Bars({required this.items, required this.metric});
  final List<TopProductItem> items;
  final String metric;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    double valueOf(TopProductItem p) =>
        metric == 'qty' ? p.qtySold.toDouble() : p.revenue;
    final max = items.map(valueOf).fold<double>(0,
        (a, b) => b > a ? b : a);
    return Column(children: [
      for (var i = 0; i < items.length; i++) Padding(
        padding: EdgeInsets.symmetric(vertical: sw * 0.012),
        child: _Row(
          rank: i + 1,
          item: items[i],
          value: valueOf(items[i]),
          max: max,
          metric: metric,
        ),
      ),
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.rank, required this.item,
    required this.value, required this.max, required this.metric,
  });
  final int rank;
  final TopProductItem item;
  final double value, max;
  final String metric;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final pct = max == 0 ? 0.0 : value / max;
    final color = _palette[rank % _palette.length];
    final valueText = metric == 'qty'
        ? '${formatCount(item.qtySold)} units'
        : formatINR(item.revenue);
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
      Container(
        width: (sw * 0.06).clamp(22.0, 28.0),
        height: (sw * 0.06).clamp(22.0, 28.0),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 0.5)),
        child: Center(child: Text('$rank',
            style: TextStyle(
                fontSize: (sw * 0.028).clamp(9.5, 12.0),
                fontWeight: FontWeight.w800, color: color))),
      ),
      SizedBox(width: sw * 0.025),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.productName, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: (sw * 0.032).clamp(11.0, 14.0),
                fontWeight: FontWeight.w700, color: kT1)),
        SizedBox(height: 2),
        Text('${item.productBrand} • ${item.productModel}',
            maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: (sw * 0.026).clamp(9.0, 11.5), color: kT4)),
        SizedBox(height: 4),
        Stack(children: [
          Container(height: 6, decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(4))),
          FractionallySizedBox(widthFactor: pct,
              child: Container(height: 6, decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(4)))),
        ]),
      ])),
      SizedBox(width: sw * 0.025),
      SizedBox(
        width: (sw * 0.2).clamp(70.0, 100.0),
        child: Text(valueText, textAlign: TextAlign.right,
            style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0),
                fontWeight: FontWeight.w700, color: kT1)),
      ),
    ]);
  }
}

const _palette = <Color>[
  kP, kGreen, kViolet, kOrange, kBlue,
  kRose, kIndigo, kTeal, kAmber, kRed,
];
