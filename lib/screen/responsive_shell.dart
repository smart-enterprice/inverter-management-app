// lib/screen/responsive_shell.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/utils/orientation_lock.dart';
import '../widgets/app_bottom_nav.dart';
import 'Dashboard/superadmin_dashboard_screen.dart';
import 'Dashboard/managerDashboard.dart';
import 'Dashboard/salesman_dashboard.dart';
import 'Dashboard/accountantDashboard.dart';
import 'Dashboard/productionDashboard.dart';
import 'Dashboard/packingDashboard.dart';
import 'Dashboard/deliveryDashboard.dart';
import 'Dashboard/base_dashboard.dart';
import '../feature/order/screen/orders_view_page.dart';
import '../feature/order/screen/today_orders_screen.dart';
import 'createSection.dart';

class _RoleConfig {
  const _RoleConfig({required this.phonePages, required this.navItems});
  final List<Widget> phonePages;
  final List<AppNavItem> navItems;
}

// ── Nav builder ───────────────────────────────────────────────────────────────
List<AppNavItem> _mobileNav({required bool hasCreate}) => [
  const AppNavItem(label: 'Home',   icon: Icons.dashboard_outlined,         activeIcon: Icons.dashboard_rounded),
  const AppNavItem(label: 'Orders', icon: Icons.receipt_long_outlined,       activeIcon: Icons.receipt_long_rounded),
  if (hasCreate)
    const AppNavItem(label: 'Create', icon: Icons.add_circle_outline_rounded, activeIcon: Icons.add_circle_rounded),
  const AppNavItem(label: 'Today',  icon: Icons.today_outlined,              activeIcon: Icons.today_rounded),
];

// ── Mobile dashboard per role ─────────────────────────────────────────────────
Widget _dashboardForRole(String? role) {
  switch (role?.toUpperCase()) {
    case 'ROLE_SUPER_ADMIN': case 'SUPER_ADMIN':
    case 'ROLE_ADMIN':       case 'ADMIN':
      return const SuperadminDashboard();
    case 'ROLE_MANAGER':     case 'MANAGER':
      return const ManagerDashboard();
    case 'ROLE_SALESMAN':    case 'SALESMAN':
      return const SalesManDashboard();
    case 'ROLE_ACCOUNTS':    case 'ACCOUNTS':
      return const AccountantDashboard();
    case 'ROLE_PRODUCTION':  case 'PRODUCTION':
      return const ProductionDashboard();
    case 'ROLE_PACKING':     case 'PACKING':
      return const PackingDashboard();
    case 'ROLE_DELIVERY':    case 'DELIVERY':
      return const DeliveryDashboard();
    default:
      return const BaseDashboard(quickAccessPanel: SizedBox.shrink());
  }
}

// ── Page lists ────────────────────────────────────────────────────────────────
List<Widget> _phonePagesWithCreate(Widget dashboard) => [
  dashboard,
  const OrdersViewPage(),
  const CreateSection(),
  const TodayOrdersScreen(),
];

List<Widget> _phonePagesNoCreate(Widget dashboard) => [
  dashboard,
  const OrdersViewPage(),
  const TodayOrdersScreen(),
];

// ── Role mapping ──────────────────────────────────────────────────────────────
_RoleConfig _configForRole(String? role) {
  final phoneDash = _dashboardForRole(role);
  switch (role?.toUpperCase()) {
    case 'ROLE_SUPER_ADMIN': case 'SUPER_ADMIN':
    case 'ROLE_ADMIN':       case 'ADMIN':
    case 'ROLE_MANAGER':     case 'MANAGER':
    case 'ROLE_SALESMAN':    case 'SALESMAN':
    case 'ROLE_ACCOUNTS':    case 'ACCOUNTS':
      return _RoleConfig(
        phonePages: _phonePagesWithCreate(phoneDash),
        navItems:   _mobileNav(hasCreate: true),
      );
    default:
      return _RoleConfig(
        phonePages: _phonePagesNoCreate(phoneDash),
        navItems:   _mobileNav(hasCreate: false),
      );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// ResponsiveShell — mobile only (tablet shells removed; will rebuild later)
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

    final config = _configForRole(widget.role);
    return RoleShell(
      pages:        config.phonePages,
      navItems:     config.navItems,
      currentIndex: _index,
      onTap:        (i) => setState(() => _index = i),
    );
  }
}
