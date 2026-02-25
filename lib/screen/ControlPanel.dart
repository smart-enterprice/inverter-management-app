import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/feature/order/screen/order_create_page.dart';
import '../core/const/icons.dart';
import '../core/media_query/media_query.dart';
import '../feature/brand/screen/brands_page.dart';
import '../feature/product/screen/products_screen.dart';
import '../feature/signup/screen/dealer/dealers_screen.dart';
import '../feature/signup/screen/user/users_screen.dart';
import '../widgets/create_card.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    // A clean list of your quick actions with distinct colors for better UX
    final List<Map<String, dynamic>> controlItems = [
      {
        'title': 'Order',
        'icon': AppIcons.add,
        'color': Colors.blue,
        'page': const OrderCreatePage(),
      },
      {
        'title': 'Products',
        'icon': AppIcons.product,
        'color': Colors.purple,
        'page': const ProductsScreen(),
      },
      {
        'title': 'Brands',
        'icon': AppIcons.brand,
        'color': Colors.orange,
        'page': const BrandsScreen(),
      },
      {
        'title': 'Dealers',
        'icon': AppIcons.dealers,
        'color': Colors.teal,
        'page': const DealersScreen(),
      },
      {
        'title': 'Users',
        'icon': AppIcons.dealers, // You might want to update this to a user icon
        'color': Colors.indigo,
        'page': const UsersScreen(),
      },
    ];

    return SizedBox(
      height: Screen.h(context) * 0.12, // Fixed height for the horizontal list
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: controlItems.length,
        separatorBuilder: (context, index) => SizedBox(width: Screen.w(context) * 0.035),
        itemBuilder: (context, index) {
          final item = controlItems[index];
          return CreateCard(
            iconPath: item['icon'],
            title: item['title'],
            iconColor: item['color'],
            backgroundColor: (item['color'] as MaterialColor).shade50,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => item['page']),
              );
            },
          );
        },
      ),
    );
  }
}
class CreateCard extends StatelessWidget {
  final String iconPath;
  final String title;
  final Color iconColor;
  final Color backgroundColor;
  final VoidCallback onTap;

  const CreateCard({
    super.key,
    required this.iconPath,
    required this.title,
    required this.iconColor,
    required this.backgroundColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Icon Container with soft shadow
          Container(
            height: Screen.w(context) * 0.15,
            width: Screen.w(context) * 0.15,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Container(
                padding: EdgeInsets.all(Screen.w(context) * 0.025),
                decoration: BoxDecoration(
                  color: backgroundColor,
                  shape: BoxShape.circle,
                ),
                child: SvgPicture.asset(
                  iconPath,
                  height: 24,
                  width: 24,
                  colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
                ),
              ),
            ),
          ),

          SizedBox(height: Screen.h(context) * 0.01),

          // Action Title
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}