import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import '../../../model/order_model.dart';

class DataCard extends StatelessWidget {
  final OrderModel order;

  const DataCard({super.key, required this.order});

  // ── Status style ──────────────────────────────────────────────────────────
  _StatusStyle _statusStyle(String? status) {
    switch (status?.toUpperCase()) {
      case 'PENDING':
        return _StatusStyle(const Color(0xFFB45309), const Color(0xFFFFFBEB),
            const Color(0xFFFCD28A));
      case 'INVOICE':
        return _StatusStyle(const Color(0xFF1B4FD8), const Color(0xFFEEF2FF),
            const Color(0xFFC7D2FE));
      case 'PRODUCTION':
        return _StatusStyle(const Color(0xFFEA580C), const Color(0xFFFFF7ED),
            const Color(0xFFFED7AA));
      case 'PACKED':
        return _StatusStyle(const Color(0xFF7C3AED), const Color(0xFFF5F3FF),
            const Color(0xFFDDD6FE));
      case 'SHIPPED':
        return _StatusStyle(const Color(0xFF4338CA), const Color(0xFFEEF2FF),
            const Color(0xFFC7D2FE));
      case 'DELIVERED':
      case 'COMPLETED':
        return _StatusStyle(const Color(0xFF0A8A5C), const Color(0xFFEDFAF4),
            const Color(0xFF9FE0C5));
      case 'CANCELLED':
        return _StatusStyle(const Color(0xFFDC2626), const Color(0xFFFEF2F2),
            const Color(0xFFFECACA));
      default:
        return _StatusStyle(const Color(0xFF6B7280), const Color(0xFFF3F4F6),
            const Color(0xFFE5E7EB));
    }
  }

  // ── Priority style ────────────────────────────────────────────────────────
  Color _priorityColor(String? p) {
    switch (p?.toUpperCase()) {
      case 'HIGH':   return const Color(0xFFDC2626);
      case 'MEDIUM': return const Color(0xFFB45309);
      default:       return const Color(0xFF0A8A5C);
    }
  }

  String _fmt(num? n) {
    if (n == null) return '0';
    return NumberFormat('#,##,###').format(n);
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final st = _statusStyle(order.status);
    final priColor = _priorityColor(order.priority);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(children: [
        // ── Top row ─────────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(
              sw * 0.04, sw * 0.04, sw * 0.04, sw * 0.025),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: sw * 0.115,
                height: sw * 0.115,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(sw * 0.03),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Center(
                  child: SvgPicture.asset(
                    AppIcons.box,
                    width: sw * 0.052,
                    height: sw * 0.052,
                    colorFilter: const ColorFilter.mode(
                        Color(0xFF1B4FD8), BlendMode.srcIn),
                  ),
                ),
              ),
              SizedBox(width: sw * 0.035),

              // Order number + dealer
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      order.orderNumber ?? 'N/A',
                      style: TextStyle(
                        fontSize: sw * 0.036,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: sh * 0.004),
                    Row(children: [
                      SvgPicture.asset(
                        AppIcons.dealers,
                        width: sw * 0.032,
                        height: sw * 0.032,
                        colorFilter: const ColorFilter.mode(
                            Color(0xFF6B7280), BlendMode.srcIn),
                      ),
                      SizedBox(width: sw * 0.012),
                      Expanded(
                        child: Text(
                          order.dealer?.employeeName ?? 'Unknown',
                          style: TextStyle(
                            fontSize: sw * 0.03,
                            color: const Color(0xFF6B7280),
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ]),
                    SizedBox(height: sh * 0.004),
                    if (order.dealer?.shopName != null)
                      Row(children: [
                        Icon(Icons.storefront_outlined,
                            size: sw * 0.032, color: const Color(0xFF9CA3AF)),
                        SizedBox(width: sw * 0.012),
                        Expanded(
                          child: Text(
                            order.dealer!.shopName,
                            style: TextStyle(
                              fontSize: sw * 0.028,
                              color: const Color(0xFF9CA3AF),
                              fontWeight: FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ]),
                  ],
                ),
              ),

              // Status chip
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.025, vertical: sw * 0.01),
                decoration: BoxDecoration(
                  color: st.bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: st.border),
                ),
                child: Text(
                  order.status ?? 'N/A',
                  style: TextStyle(
                    fontSize: sw * 0.024,
                    fontWeight: FontWeight.w700,
                    color: st.fg,
                  ),
                ),
              ),
            ],
          ),
        ),

        // ── Divider ──────────────────────────────────────────────────────
        const Divider(height: 1, color: Color(0xFFF3F4F6)),

        // ── Bottom row ───────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.03),
          child: Row(children: [
            // Items count
            _BottomChip(
              sw: sw,
              icon: Icons.inventory_2_outlined,
              label:
              '${order.orderDetails.length} item${order.orderDetails.length > 1 ? 's' : ''}',
              color: const Color(0xFF6B7280),
              bg: const Color(0xFFF9FAFB),
            ),
            SizedBox(width: sw * 0.02),

            // Total price
            if (order.totalPrice != null)
              _BottomChip(
                sw: sw,
                icon: Icons.currency_rupee_rounded,
                label: _fmt(order.totalPrice),
                color: const Color(0xFF0A8A5C),
                bg: const Color(0xFFEDFAF4),
              ),

            const Spacer(),

            // Priority badge
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.025, vertical: sw * 0.008),
              decoration: BoxDecoration(
                color: priColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: priColor.withValues(alpha: 0.25)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  width: sw * 0.018,
                  height: sw * 0.018,
                  decoration: BoxDecoration(
                      color: priColor, shape: BoxShape.circle),
                ),
                SizedBox(width: sw * 0.012),
                Text(
                  order.priority,
                  style: TextStyle(
                    fontSize: sw * 0.026,
                    fontWeight: FontWeight.w700,
                    color: priColor,
                  ),
                ),
              ]),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _StatusStyle {
  final Color fg, bg, border;
  const _StatusStyle(this.fg, this.bg, this.border);
}

class _BottomChip extends StatelessWidget {
  final double sw;
  final IconData icon;
  final String label;
  final Color color, bg;

  const _BottomChip({
    required this.sw,
    required this.icon,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
        horizontal: sw * 0.025, vertical: sw * 0.012),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: sw * 0.032, color: color),
      SizedBox(width: sw * 0.01),
      Text(label,
          style: TextStyle(
              fontSize: sw * 0.028,
              color: color,
              fontWeight: FontWeight.w600)),
    ]),
  );
}