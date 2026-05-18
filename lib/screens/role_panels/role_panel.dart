import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/const/icons.dart';
import '../../core/role/app_role.dart';
import '../../feature/brand/screens/brands_page.dart';
import '../../feature/order/screens/order_create_page.dart';
import '../../feature/product/screens/products_screen.dart';
import '../../feature/signup/screens/dealer/dealers_screen.dart';
import '../../feature/signup/screens/user/users_screen.dart';
import '../../widgets/quick_access_card.dart';

/// Single role-aware quick-access panel.
/// Renders only the cards the current role is permitted to see — driven by
/// AppPermissions.canAccess(). Replaces the 6 per-role panel widgets.
class RolePanel extends ConsumerWidget {
  const RolePanel({super.key});

  // Master list — to add a quick-access card, just append here and make sure
  // the right roles have its `feature` in their permission set in app_role.dart.
  static const List<_PanelEntry> _all = [
    _PanelEntry(
      feature: AppFeature.createOrder,
      card: QuickAccessCardData(
        title: 'New Order',
        iconPath: AppIcons.add,
        accent: Color(0xFF185FA5),
        bg: Color(0xFFEBF4FF),
        border: Color(0xFFBFD9F5),
        page: OrderCreatePage(),
      ),
    ),
    _PanelEntry(
      feature: AppFeature.viewProducts,
      card: QuickAccessCardData(
        title: 'Products',
        iconPath: AppIcons.product,
        accent: Color(0xFF7C3AED),
        bg: Color(0xFFF5F3FF),
        border: Color(0xFFDDD6FE),
        page: ProductsScreen(),
      ),
    ),
    _PanelEntry(
      feature: AppFeature.viewBrands,
      card: QuickAccessCardData(
        title: 'Brands',
        iconPath: AppIcons.brand,
        accent: Color(0xFFEA580C),
        bg: Color(0xFFFFF7ED),
        border: Color(0xFFFED7AA),
        page: BrandsScreen(),
      ),
    ),
    _PanelEntry(
      feature: AppFeature.viewDealers,
      card: QuickAccessCardData(
        title: 'Dealers',
        iconPath: AppIcons.dealers,
        accent: Color(0xFF0A8A5C),
        bg: Color(0xFFEDFAF4),
        border: Color(0xFF9FE0C5),
        page: DealersScreen(),
      ),
    ),
    _PanelEntry(
      feature: AppFeature.viewEmployees,
      card: QuickAccessCardData(
        title: 'Users',
        iconPath: AppIcons.dealers,
        accent: Color(0xFF4338CA),
        bg: Color(0xFFEEF2FF),
        border: Color(0xFFC7D2FE),
        page: UsersScreen(),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleNotifierProvider);
    final visible = _all
        .where((e) => AppPermissions.canAccess(role, e.feature))
        .map((e) => e.card)
        .toList();
    if (visible.isEmpty) return const SizedBox.shrink();
    return buildQuickAccessRow(context: context, items: visible);
  }
}

class _PanelEntry {
  final String feature;
  final QuickAccessCardData card;
  const _PanelEntry({required this.feature, required this.card});
}
