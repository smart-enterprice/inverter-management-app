import 'package:inverter_management_app/screen/Dashboard/deliveryDashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import 'package:inverter_management_app/feature/order/screen/today_orders_screen.dart';
import 'package:inverter_management_app/widgets/app_bottom_nav.dart';
class DeliveryMobileView extends ConsumerStatefulWidget {
  const DeliveryMobileView({super.key});
  @override
  ConsumerState<DeliveryMobileView> createState() => _DeliveryMobileViewState();
}

class _DeliveryMobileViewState extends ConsumerState<DeliveryMobileView> {
  int _idx = 0;
  static const _pages = [
    DeliveryDashboard(),
    OrdersViewPage(),
    TodayOrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) => RoleShell(
    pages: _pages,
    currentIndex: _idx,
    onTap: (i) => setState(() => _idx = i),
    navItems: kLimitedNavItems,
  );
}
