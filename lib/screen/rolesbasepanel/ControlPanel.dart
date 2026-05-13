import 'package:flutter/material.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/feature/brand/screen/brands_page.dart';
import 'package:inverter_management_app/feature/brand/screen/tablet/brands_tablet_view.dart';
import 'package:inverter_management_app/feature/order/screen/order_create_page.dart';
import 'package:inverter_management_app/feature/product/screen/products_screen.dart';
import 'package:inverter_management_app/feature/product/screen/tablet/products_tablet_view.dart';
import 'package:inverter_management_app/feature/signup/screen/dealer/dealers_screen.dart';
import 'package:inverter_management_app/feature/signup/screen/dealer/tablet/dealers_tablet_view.dart';
import 'package:inverter_management_app/feature/signup/screen/user/users_screen.dart';
import 'package:inverter_management_app/feature/signup/screen/user/tablet/users_tablet_view.dart';
import 'package:inverter_management_app/widgets/quick_access_card.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return buildQuickAccessRow(
      context: context,
      items: const [
        QuickAccessCardData(
          title: 'New Order',
          iconPath: AppIcons.add,
          accent: Color(0xFF185FA5),
          bg: Color(0xFFEBF4FF),
          border: Color(0xFFBFD9F5),
          page: OrderCreatePage(),
        ),
        QuickAccessCardData(
          title: 'Products',
          iconPath: AppIcons.product,
          accent: Color(0xFF7C3AED),
          bg: Color(0xFFF5F3FF),
          border: Color(0xFFDDD6FE),
          page: ProductsScreen(),
          tabletPage: ProductsTabletView(),
        ),
        QuickAccessCardData(
          title: 'Brands',
          iconPath: AppIcons.brand,
          accent: Color(0xFFEA580C),
          bg: Color(0xFFFFF7ED),
          border: Color(0xFFFED7AA),
          page: BrandsScreen(),
          tabletPage: BrandsTabletView(),
        ),
        QuickAccessCardData(
          title: 'Dealers',
          iconPath: AppIcons.dealers,
          accent: Color(0xFF0A8A5C),
          bg: Color(0xFFEDFAF4),
          border: Color(0xFF9FE0C5),
          page: DealersScreen(),
          tabletPage: DealersTabletView(),
        ),
        QuickAccessCardData(
          title: 'Users',
          iconPath: AppIcons.dealers,
          accent: Color(0xFF4338CA),
          bg: Color(0xFFEEF2FF),
          border: Color(0xFFC7D2FE),
          page: UsersScreen(),
          tabletPage: UsersTabletView(),
        ),
      ],
    );
  }
}