import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';

// Make sure to import your OrderModel!
import '../../../model/order_model.dart';

class DataCard extends StatelessWidget {
  final OrderModel order;

  const DataCard({super.key, required this.order});

  // 🔹 Helper function to set colors based on Priority
  Color _getPriorityColor(String? priority) {
    switch (priority?.toLowerCase()) {
      case 'high':
        return Colors.redAccent;
      case 'medium':
        return Colors.orangeAccent;
      case 'low':
        return Colors.green;
      default:
        return Colors.blueGrey; // Fallback color
    }
  }

  @override
  Widget build(BuildContext context) {
    // Get the dynamic color for this specific order's priority
    final priorityColor = _getPriorityColor(order.priority);

    return Container(
      padding: EdgeInsets.all(Screen.w(context) * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Row(
        children: [
          // Left: Icon
          Container(
            padding: EdgeInsets.all(Screen.w(context) * 0.03),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.green.withValues(alpha: 0.1),
            ),
            child: SvgPicture.asset(
              AppIcons.box,
              height: 24,
              width: 24,
              colorFilter: const ColorFilter.mode(Colors.green, BlendMode.srcIn),
            ),
          ),

          SizedBox(width: Screen.w(context) * 0.035),

          // Middle: Order Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order ID #${order.orderNumber}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: Screen.h(context) * 0.005),
                Text(
                  'Dealer: ${order.dealer?.employeeName ?? 'Unknown'}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          SizedBox(width: Screen.w(context) * 0.02),

          // Right: Dynamic Priority Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: Screen.w(context) * 0.03,
              vertical: Screen.h(context) * 0.006,
            ),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.1), // Soft background
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: priorityColor.withValues(alpha: 0.3)), // Soft border
            ),
            child: Text(
              order.priority ?? 'Normal', // ✅ Shows Priority only
              style: TextStyle(
                fontSize: 12,
                color: priorityColor, // Matching text color
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}