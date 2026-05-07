// lib/screen/responsive_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/screen/tablet_shell.dart';
import '../core/utils/orientation_lock.dart';
import '../feature/order/screen/tablet/orders_tablet_view.dart';
import '../feature/order/screen/tablet/today_orders_tablet_view.dart';
import '../widgets/app_bottom_nav.dart';
import 'Dashboard/base_dashboard.dart';
import 'Dashboard/dashboard_tablet_view.dart';
import '../feature/order/screen/orders_view_page.dart';
import '../feature/order/screen/today_orders_screen.dart';
import 'createSection.dart';

class _RoleConfig {
  const _RoleConfig({
    required this.phonePages,
    required this.tabletPages,
    required this.navItems,
    required this.tabletItems,
  });
  final List<Widget>        phonePages;
  final List<Widget>        tabletPages;
  final List<AppNavItem>    navItems;
  final List<TabletNavItem> tabletItems;
}

// ── Nav builders ──────────────────────────────────────────────────────────────
List<TabletNavItem> _tabletNav({required bool hasCreate}) => [
  const TabletNavItem(label: 'Dashboard', icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard_rounded),
  const TabletNavItem(label: 'Orders',    icon: Icons.receipt_long_outlined,  activeIcon: Icons.receipt_long_rounded),
  if (hasCreate)
    const TabletNavItem(label: 'Create',  icon: Icons.add_circle_outline_rounded, activeIcon: Icons.add_circle_rounded),
  const TabletNavItem(label: 'Today',     icon: Icons.today_outlined,          activeIcon: Icons.today_rounded),
];

List<AppNavItem> _mobileNav({required bool hasCreate}) => [
  const AppNavItem(label: 'Home',   icon: Icons.dashboard_outlined,    activeIcon: Icons.dashboard_rounded),
  const AppNavItem(label: 'Orders', icon: Icons.receipt_long_outlined,  activeIcon: Icons.receipt_long_rounded),
  if (hasCreate)
    const AppNavItem(label: 'Create', icon: Icons.add_circle_outline_rounded, activeIcon: Icons.add_circle_rounded),
  const AppNavItem(label: 'Today',  icon: Icons.today_outlined,          activeIcon: Icons.today_rounded),
];

// ── Page lists ────────────────────────────────────────────────────────────────
List<Widget> _phonePagesWithCreate() => [
  const BaseDashboard(quickAccessPanel: SizedBox.shrink()),
  const OrdersViewPage(),
  const CreateSection(),
  const TodayOrdersScreen(),
];

List<Widget> _phonePagesNoCreate() => [
  const BaseDashboard(quickAccessPanel: SizedBox.shrink()),
  const OrdersViewPage(),
  const TodayOrdersScreen(),
];

List<Widget> _tabletPagesWithCreate() => [
  const DashboardTabletView(),
  const OrdersTabletView(),
  const CreateSection(),
  const TodayOrdersTabletView(),
];

List<Widget> _tabletPagesNoCreate() => [
  const DashboardTabletView(),
  const OrdersTabletView(),
  const TodayOrdersTabletView(),
];

// ── Role mapping ──────────────────────────────────────────────────────────────
_RoleConfig _configForRole(String? role) {
  switch (role?.toUpperCase()) {
    case 'ROLE_SUPER_ADMIN': case 'SUPER_ADMIN':
    case 'ROLE_ADMIN':       case 'ADMIN':
    case 'ROLE_MANAGER':     case 'MANAGER':
    case 'ROLE_SALESMAN':    case 'SALESMAN':
    case 'ROLE_ACCOUNTS':    case 'ACCOUNTS':
    return _RoleConfig(
      phonePages:  _phonePagesWithCreate(),
      tabletPages: _tabletPagesWithCreate(),
      navItems:    _mobileNav(hasCreate: true),
      tabletItems: _tabletNav(hasCreate: true),
    );
    default:
      return _RoleConfig(
        phonePages:  _phonePagesNoCreate(),
        tabletPages: _tabletPagesNoCreate(),
        navItems:    _mobileNav(hasCreate: false),
        tabletItems: _tabletNav(hasCreate: false),
      );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ResponsiveShell
// ═════════════════════════════════════════════════════════════════════════════
class ResponsiveShell extends ConsumerStatefulWidget {
  const ResponsiveShell._({required this.role});
  factory ResponsiveShell.forRole(String? role) => ResponsiveShell._(role: role);
  final String? role;

  @override
  ConsumerState<ResponsiveShell> createState() => _ResponsiveShellState();
}

class _ResponsiveShellState extends ConsumerState<ResponsiveShell> {
  int  _index       = 0;
  bool _lockApplied = false;

  @override
  Widget build(BuildContext context) {
    if (!_lockApplied) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) { OrientationLock.apply(context); _lockApplied = true; }
      });
    }

    final isTablet = MediaQuery.sizeOf(context).width >= 600;
    final config   = _configForRole(widget.role);

    if (isTablet) {
      return TabletShell(
        pages:    config.tabletPages,
        navItems: config.tabletItems,
      );
    }

    return RoleShell(
      pages:        config.phonePages,
      navItems:     config.navItems,
      currentIndex: _index,
      onTap:        (i) => setState(() => _index = i),
    );
  }
}