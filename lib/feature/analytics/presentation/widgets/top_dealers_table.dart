// Top dealers leaderboard. Hidden when a specific dealer is selected —
// it's meaningless for a single-dealer view.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/analytics_providers.dart';
import '../../application/date_range_provider.dart';
import '../../data/analytics_models.dart';
import '../../util/format.dart';
import '_tokens.dart';

class TopDealersCard extends ConsumerWidget {
  const TopDealersCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.sizeOf(context).width;
    final filter = ref.watch(analyticsFilterProvider);

    // Hidden when a dealer is already selected.
    if (filter.dealerId != null) return const SizedBox.shrink();

    final async$ = ref.watch(topDealersProvider(TopDealersParams(
      from: filter.from, to: filter.to,
      limit: 10, salesmanId: filter.salesmanId,
    )));

    return AnalyticsCard(child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const AnalyticsCardHeader(
          title: 'Top Dealers',
          subtitle: 'By revenue (with paid / due breakdown)',
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
                icon: Icons.store_mall_directory_outlined,
                message: 'No dealer activity in this range');
          }
          return _List(items: cached);
        }),
      ],
    ));
  }
}

class _List extends StatelessWidget {
  const _List({required this.items});
  final List<TopDealerItem> items;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Column(children: [
      for (var i = 0; i < items.length; i++) ...[
        if (i > 0) Divider(height: 1, color: kBdSoft),
        Padding(
          padding: EdgeInsets.symmetric(vertical: sw * 0.025),
          child: _Row(rank: i + 1, item: items[i]),
        ),
      ],
    ]);
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.rank, required this.item});
  final int rank;
  final TopDealerItem item;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final pillC = rank <= 3 ? kP : kT4;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        width: (sw * 0.07).clamp(24.0, 32.0),
        height: (sw * 0.07).clamp(24.0, 32.0),
        decoration: BoxDecoration(
          color: pillC.withValues(alpha: 0.10),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: pillC.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Center(child: Text('$rank',
            style: TextStyle(
                fontSize: (sw * 0.028).clamp(9.5, 12.0),
                fontWeight: FontWeight.w800, color: pillC))),
      ),
      SizedBox(width: sw * 0.025),
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(item.dealerName, maxLines: 1, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: (sw * 0.034).clamp(11.5, 15.0),
                fontWeight: FontWeight.w700, color: kT1)),
        if (item.shopName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(item.shopName,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: (sw * 0.028).clamp(9.5, 12.0),
                    color: kT3, fontWeight: FontWeight.w500)),
          ),
        if (item.district.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 1),
            child: Text(item.district,
                maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontSize: (sw * 0.026).clamp(9.0, 11.5), color: kT4)),
          ),
        SizedBox(height: sw * 0.018),
        Wrap(spacing: sw * 0.02, runSpacing: 4, children: [
          _MicroPill(icon: Icons.shopping_bag_outlined,
              label: '${item.ordersCount} ord', color: kP, bg: kPBg),
          _MicroPill(icon: Icons.payments_outlined,
              label: 'Paid ${formatINR(item.paid)}',
              color: kGreen, bg: kGreenBg),
          if (item.due > 0)
            _MicroPill(icon: Icons.error_outline,
                label: 'Due ${formatINR(item.due)}',
                color: kRed, bg: kRedBg),
        ]),
      ])),
      SizedBox(width: sw * 0.02),
      Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(formatINR(item.revenue),
            style: TextStyle(
                fontSize: (sw * 0.034).clamp(11.5, 15.0),
                fontWeight: FontWeight.w800, color: kT1)),
        SizedBox(height: 2),
        Text('Revenue', style: TextStyle(
            fontSize: (sw * 0.024).clamp(8.5, 11.0),
            color: kT4, fontWeight: FontWeight.w600)),
      ]),
    ]);
  }
}

class _MicroPill extends StatelessWidget {
  const _MicroPill({
    required this.icon, required this.label,
    required this.color, required this.bg,
  });
  final IconData icon;
  final String label;
  final Color color, bg;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.02, vertical: sw * 0.008),
      decoration: BoxDecoration(color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: (sw * 0.03).clamp(10.0, 12.5), color: color),
        SizedBox(width: sw * 0.012),
        Text(label, style: TextStyle(
            fontSize: (sw * 0.026).clamp(9.0, 11.0),
            color: color, fontWeight: FontWeight.w700)),
      ]),
    );
  }
}
