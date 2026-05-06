import 'package:inverter_management_app/screen/Dashboard/accountantDashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import 'package:inverter_management_app/feature/order/screen/today_orders_screen.dart';
import 'package:inverter_management_app/widgets/app_bottom_nav.dart';
class AccountantMobileView extends ConsumerStatefulWidget {
  const AccountantMobileView({super.key});
  @override
  ConsumerState<AccountantMobileView> createState() => _AccountantMobileViewState();
}

class _AccountantMobileViewState extends ConsumerState<AccountantMobileView> {
  int _idx = 0;
  static const _pages = [
    AccountantDashboard(),
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

