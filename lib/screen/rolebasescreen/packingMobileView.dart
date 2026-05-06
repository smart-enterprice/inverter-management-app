import 'package:inverter_management_app/screen/Dashboard/packingDashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import 'package:inverter_management_app/feature/order/screen/today_orders_screen.dart';
import 'package:inverter_management_app/widgets/app_bottom_nav.dart';
class PackingMobileView extends ConsumerStatefulWidget {
  const PackingMobileView({super.key});
  @override
  ConsumerState<PackingMobileView> createState() => _PackingMobileViewState();
}

class _PackingMobileViewState extends ConsumerState<PackingMobileView> {
  int _idx = 0;
  static const _pages = [
    PackingDashboard(),
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
