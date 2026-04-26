import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import 'package:inverter_management_app/feature/order/screen/today_orders_screen.dart';
import 'package:inverter_management_app/screen/Dashboard/salesman_dashboard.dart';
import 'package:inverter_management_app/screen/createSection.dart';
import 'package:inverter_management_app/widgets/app_bottom_nav.dart';

class SalesmanMobileView extends ConsumerStatefulWidget {
  const SalesmanMobileView({super.key});
  @override
  ConsumerState<SalesmanMobileView> createState() => _SalesmanMobileViewState();
}

class _SalesmanMobileViewState extends ConsumerState<SalesmanMobileView> {
  int _idx = 0;
  static const _pages = [
    SalesManDashboard(),
    OrdersViewPage(),
    CreateSection(),
    TodayOrdersScreen(),
  ];

  @override
  Widget build(BuildContext context) => RoleShell(
    pages: _pages,
    currentIndex: _idx,
    onTap: (i) => setState(() => _idx = i),
  );
}
