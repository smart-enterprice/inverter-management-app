import 'package:inverter_management_app/screen/Dashboard/productionDashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import 'package:inverter_management_app/feature/order/screen/today_orders_screen.dart';
import 'package:inverter_management_app/screen/createSection.dart';
import 'package:inverter_management_app/widgets/app_bottom_nav.dart';
class ProductionMobileView extends ConsumerStatefulWidget {
  const ProductionMobileView({super.key});
  @override
  ConsumerState<ProductionMobileView> createState() => _ProductionMobileViewState();
}

class _ProductionMobileViewState extends ConsumerState<ProductionMobileView> {
  int _idx = 0;
  // Production: no Create tab — uses kLimitedNavItems
  static const _pages = [
    ProductionDashboard(),
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
