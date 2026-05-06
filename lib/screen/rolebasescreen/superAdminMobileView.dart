import 'package:inverter_management_app/screen/Dashboard/superadmin_dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import 'package:inverter_management_app/feature/order/screen/today_orders_screen.dart';
import 'package:inverter_management_app/screen/createSection.dart';
import 'package:inverter_management_app/widgets/app_bottom_nav.dart';

class SuperAdminHomePage extends ConsumerStatefulWidget {
  const SuperAdminHomePage({super.key});
  @override
  ConsumerState<SuperAdminHomePage> createState() => _SuperAdminHomePageState();
}

class _SuperAdminHomePageState extends ConsumerState<SuperAdminHomePage> {
  int _idx = 0;
  static const _pages = [
    SuperadminDashboard(),
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
