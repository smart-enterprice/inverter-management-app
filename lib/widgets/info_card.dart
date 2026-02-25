import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';

import '../feature/order/controller/order_controller.dart';
import '../feature/product/controller/product_controller.dart';

class InfoCard extends ConsumerWidget {
  const InfoCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lowStockAsync = ref.watch(lowStockProvider(5)); // 5 is your threshold
    final lowStockCount = lowStockAsync.asData?.value.length ?? 0;
    final ordersAsync = ref.watch(orderControllerProvider);
    final totalOrders = ordersAsync.value?.length ?? 0;
    final deliveredOrdersCount = ordersAsync.value?.where((order) => order.status == 'COMPLETED').length ?? 0;
    return Column(
      children: [
        // Top Row: Total Orders & Deliveries
        Row(
          children: [
            Expanded(
              child: _buildDashboardCard(
                context,
                title: "Total Orders",
                value: totalOrders.toString(), // Hook up to your state
                icon: AppIcons.box, // Assuming AppIcons.box is a String path to an SVG
                color: Colors.blueAccent,
                bgColor: Colors.blueAccent.withValues(alpha: 0.1),
              ),
            ),
            SizedBox(width: Screen.w(context) * 0.03),
            Expanded(
              child: _buildDashboardCard(
                context,
                title: "Delivered",
                value: deliveredOrdersCount.toString(), // Hook up to your state
                icon: AppIcons.delivery,
                color: Colors.green,
                bgColor: Colors.green.withValues(alpha: 0.1),
              ),
            ),
          ],
        ),
        SizedBox(height: Screen.h(context) * 0.015),

        // Bottom Row: Low Stock Alert (Full Width)
        _buildDashboardCard(
          context,
          title: "Low Stock Items",
          value: lowStockCount.toString(), // Hook up to your state
          icon: AppIcons.alert,
          color: Colors.redAccent,
          bgColor: const Color(0xFFFFF0F0), // Soft red background
          isFullWidth: true,
        ),
      ],
    );
  }

  // Extracted widget for a cleaner UI builder
  Widget _buildDashboardCard(
      BuildContext context, {
        required String title,
        required String value,
        required String icon,
        required Color color,
        required Color bgColor,
        bool isFullWidth = false,
      }) {
    return Container(
      padding: EdgeInsets.all(Screen.w(context) * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Icon Container
          Container(
            padding: EdgeInsets.all(Screen.w(context) * 0.025),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            // NOTE: Change to SvgPicture.asset(icon) if AppIcons are SVGs
            child: Icon(Icons.inventory_2_outlined, color: color, size: 24),
          ),
          SizedBox(width: Screen.w(context) * 0.03),

          // Texts
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                SizedBox(height: Screen.h(context) * 0.005),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: isFullWidth ? 22 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
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