import 'package:inverter_management_app/screen/Dashboard/managerDashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import 'package:inverter_management_app/feature/order/screen/today_orders_screen.dart';
import 'package:inverter_management_app/screen/createSection.dart';
import 'package:inverter_management_app/widgets/app_bottom_nav.dart';
class ManagerMobileView extends ConsumerStatefulWidget {
  const ManagerMobileView({super.key});
  @override
  ConsumerState<ManagerMobileView> createState() => _ManagerMobileViewState();
}

class _ManagerMobileViewState extends ConsumerState<ManagerMobileView> {
  int _idx = 0;
  static const _pages = [
    ManagerDashboard(),
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
