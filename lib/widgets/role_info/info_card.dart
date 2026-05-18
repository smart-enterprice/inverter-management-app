import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/feature/order/controller/order_controller.dart';
import 'package:inverter_management_app/feature/product/controller/product_controller.dart';

class InfoCard extends ConsumerWidget {
  const InfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mq   = MediaQuery.of(context);
    final sw   = mq.size.width;
    final sh   = mq.size.height;

    final lowStockAsync  = ref.watch(lowStockProvider(5));
    final lowStockCount  = lowStockAsync.asData?.value.length ?? 0;
    final ordersAsync    = ref.watch(orderControllerProvider);
    final totalOrders    = ordersAsync.value?.length ?? 0;
    final completedCount = ordersAsync.value
        ?.where((o) => o.status == 'COMPLETED').length ?? 0;
    final pendingCount   = ordersAsync.value
        ?.where((o) => o.status == 'PENDING').length ?? 0;

    final gap = sw * 0.03;

    return Column(
      children: [
        Row(children: [
          Expanded(
            child: _StatTile(
              sw: sw, sh: sh,
              label: 'Total Orders',
              value: totalOrders.toString(),
              icon: Icons.receipt_long_rounded,
              accent: const Color(0xFF185FA5),
              accentBg: const Color(0xFFEBF4FF),
              accentBorder: const Color(0xFFBFD9F5),
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            child: _StatTile(
              sw: sw, sh: sh,
              label: 'Completed',
              value: completedCount.toString(),
              icon: Icons.task_alt_rounded,
              accent: const Color(0xFF0F6E56),
              accentBg: const Color(0xFFEDFAF5),
              accentBorder: const Color(0xFF9FE0C5),
            ),
          ),
        ]),
        SizedBox(height: gap),
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
          SizedBox(width: gap),
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
      ],
    );
  }
}

// ── Stat tile — Zoho Books style ──────────────────────────────────────────────
class _StatTile extends StatelessWidget {
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

  final double sw, sh;
  final String label, value;
  final IconData icon;
  final Color accent, accentBg, accentBorder;
  final bool highlight;

  @override
  Widget build(BuildContext context) {
    // All sizes from MediaQuery
    final pad      = sw * 0.038;
    final iconBox  = (sw * 0.105).clamp(36.0, 52.0);
    final iconSz   = (sw * 0.05).clamp(18.0, 26.0);
    final iconR    = (sw * 0.025).clamp(8.0, 12.0);
    final labelFs  = (sw * 0.027).clamp(9.5, 12.5);
    final valueFs  = (sw * 0.05).clamp(18.0, 28.0);
    final cardR    = (sw * 0.035).clamp(10.0, 16.0);
    final gap      = sw * 0.025;

    return Container(
      padding: EdgeInsets.all(pad),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(cardR),
        // Zoho Books: border only — no boxShadow
        border: Border.all(
          color: highlight ? accentBorder : const Color(0xFFE5E7EB),
          width: 0.5,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon box
          Container(
            width: iconBox,
            height: iconBox,
            decoration: BoxDecoration(
              color: accentBg,
              borderRadius: BorderRadius.circular(iconR),
            ),
            child: Icon(icon, color: accent, size: iconSz),
          ),
          SizedBox(width: gap),

          // Label + value
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: labelFs,
                    color: const Color(0xFF6B7280),
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: sh * 0.004),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: valueFs,
                    fontWeight: FontWeight.w800,
                    color: highlight ? accent : const Color(0xFF111827),
                    letterSpacing: -0.5,
                    height: 1.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}