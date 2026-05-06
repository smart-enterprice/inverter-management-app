import 'package:flutter/material.dart';

import '../../core/const/icons.dart';

import '../../feature/brand/screen/brands_page.dart';
import '../../feature/product/screen/products_screen.dart';
import '../../feature/signup/screen/dealer/dealers_screen.dart';

import '../../widgets/quick_access_card.dart';


class AccountantPanel extends StatelessWidget {
  const AccountantPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return buildQuickAccessRow(
      context: context,
      items: const [
        QuickAccessCardData(
          title: 'Products',
          iconPath: AppIcons.product,
          accent: Color(0xFF7C3AED),
          bg: Color(0xFFF5F3FF),
          border: Color(0xFFDDD6FE),
          page: ProductsScreen(),
        ),
        QuickAccessCardData(
          title: 'Brands',
          iconPath: AppIcons.brand,
          accent: Color(0xFFEA580C),
          bg: Color(0xFFFFF7ED),
          border: Color(0xFFFED7AA),
          page: BrandsScreen(),
        ),
        QuickAccessCardData(
          title: 'Dealers',
          iconPath: AppIcons.dealers,
          accent: Color(0xFF0A8A5C),
          bg: Color(0xFFEDFAF4),
          border: Color(0xFF9FE0C5),
          page: DealersScreen(),
        ),
      ],
    );
  }
}
