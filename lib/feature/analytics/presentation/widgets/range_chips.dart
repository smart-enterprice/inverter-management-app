// Horizontal scroll chips: Today / 7d / 30d / MTD / Last Month.
// Sets the AnalyticsRange in the shared filter notifier.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/date_range_provider.dart';
import '_tokens.dart';

class RangeChipsRow extends ConsumerWidget {
  const RangeChipsRow({super.key, required this.onFilterTap});
  final VoidCallback onFilterTap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.sizeOf(context).width;
    final filter = ref.watch(analyticsFilterProvider);

    const items = <(AnalyticsRange, String)>[
      (AnalyticsRange.today, 'Today'),
      (AnalyticsRange.last7, '7d'),
      (AnalyticsRange.last30, '30d'),
      (AnalyticsRange.mtd, 'MTD'),
      (AnalyticsRange.lastMonth, 'Last Month'),
    ];

    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.018),
      child: Row(children: [
        Expanded(child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
          child: Row(children: [
            for (final (range, label) in items) ...[
              ChipToggle(
                label: label,
                selected: filter.range == range,
                onTap: () => ref
                    .read(analyticsFilterProvider.notifier)
                    .setRange(range),
              ),
              SizedBox(width: sw * 0.02),
            ],
            if (filter.range == AnalyticsRange.custom)
              ChipToggle(
                label: 'Custom',
                selected: true,
                onTap: onFilterTap,
              ),
          ]),
        )),
        Padding(
          padding: EdgeInsets.only(right: sw * 0.04, left: sw * 0.01),
          child: _FilterButton(
            active: filter.dealerId != null ||
                filter.range == AnalyticsRange.custom,
            onTap: onFilterTap,
          ),
        ),
      ]),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({required this.active, required this.onTap});
  final bool active;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final size = (sw * 0.09).clamp(32.0, 42.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: active ? kPBg : kSurface,
          shape: BoxShape.circle,
          border: Border.all(color: active ? kPBd : kBd, width: 0.5),
        ),
        child: Icon(Icons.tune_rounded,
            size: (sw * 0.045).clamp(15.0, 20.0),
            color: active ? kP : kT3),
      ),
    );
  }
}
