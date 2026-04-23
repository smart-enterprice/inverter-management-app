import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';

import '../../feature/order/controller/order_controller.dart';
import '../../feature/product/controller/product_controller.dart';

class InfoCard extends ConsumerWidget {
  const InfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    final lowStockAsync = ref.watch(lowStockProvider(5));
    final lowStockCount = lowStockAsync.asData?.value.length ?? 0;
    final ordersAsync = ref.watch(orderControllerProvider);
    final totalOrders = ordersAsync.value?.length ?? 0;
    final completedCount = ordersAsync.value
        ?.where((o) => o.status == 'COMPLETED')
        .length ??
        0;
    final pendingCount = ordersAsync.value
        ?.where((o) => o.status == 'PENDING')
        .length ??
        0;

    return Column(children: [
      // ── Row 1: Total + Completed ──────────────────────────────────────
      Row(children: [
        Expanded(
          child: _StatTile(
            sw: sw, sh: sh,
            label: 'Total Orders',
            value: totalOrders.toString(),
            icon: Icons.receipt_long_rounded,
            accent: const Color(0xFF1B4FD8),
            accentBg: const Color(0xFFEEF2FF),
            accentBorder: const Color(0xFFC7D2FE),
          ),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: _StatTile(
            sw: sw, sh: sh,
            label: 'Completed',
            value: completedCount.toString(),
            icon: Icons.task_alt_rounded,
            accent: const Color(0xFF0A8A5C),
            accentBg: const Color(0xFFEDFAF4),
            accentBorder: const Color(0xFF9FE0C5),
          ),
        ),
      ]),
      SizedBox(height: sw * 0.03),

      // ── Row 2: Pending + Low Stock ────────────────────────────────────
      Row(children: [
        Expanded(
          child: _StatTile(
            sw: sw, sh: sh,
            label: 'Pending',
            value: pendingCount.toString(),
            icon: Icons.pending_actions_rounded,
            accent: const Color(0xFFB45309),
            accentBg: const Color(0xFFFFFBEB),
            accentBorder: const Color(0xFFFCD28A),
          ),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          child: _StatTile(
            sw: sw, sh: sh,
            label: 'Low Stock',
            value: lowStockCount.toString(),
            icon: Icons.inventory_2_outlined,
            accent: const Color(0xFFDC2626),
            accentBg: const Color(0xFFFEF2F2),
            accentBorder: const Color(0xFFFECACA),
            highlight: lowStockCount > 0,
          ),
        ),
      ]),
    ]);
  }
}

class _StatTile extends StatelessWidget {
  final double sw, sh;
  final String label, value;
  final IconData icon;
  final Color accent, accentBg, accentBorder;
  final bool highlight;

  const _StatTile({
    required this.sw,
    required this.sh,
    required this.label,
    required this.value,
    required this.icon,
    required this.accent,
    required this.accentBg,
    required this.accentBorder,
    this.highlight = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(sw * 0.042),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(
          color: highlight ? accentBorder : const Color(0xFFE5E7EB),
          width: highlight ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: highlight
                ? accent.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(children: [
        // Icon
        Container(
          width: sw * 0.11,
          height: sw * 0.11,
          decoration: BoxDecoration(
            color: accentBg,
            borderRadius: BorderRadius.circular(sw * 0.028),
            border: Border.all(color: accentBorder),
          ),
          child: Icon(icon, color: accent, size: sw * 0.052),
        ),
        SizedBox(width: sw * 0.03),

        // Text
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: sw * 0.028,
                  color: const Color(0xFF6B7280),
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: sh * 0.005),
              Text(
                value,
                style: TextStyle(
                  fontSize: sw * 0.052,
                  fontWeight: FontWeight.w800,
                  color: highlight ? accent : const Color(0xFF111827),
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
        ),
      ]),
    );
  }
}