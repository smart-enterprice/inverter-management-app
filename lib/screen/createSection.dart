import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/feature/order/screen/order_create_page.dart';
import 'package:inverter_management_app/feature/product/screen/product_create_screen.dart';
import '../feature/brand/screen/brand_create.dart';
import '../feature/signup/screen/dealer/dealers_sign_up_screen.dart';
import '../feature/signup/screen/user/sign_up_screen.dart';

class CreateSection extends StatelessWidget {
  const CreateSection({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. Define the items
    final List<Map<String, dynamic>> items = [
      {
        "icon": AppIcons.orders,
        "title": "New Order",
        "subtitle": "Create a new order for a dealer",
        'backgroundColor': Colors.lightBlueAccent.withValues(alpha: 0.15),
        "iconColor": Theme.of(context).primaryColor,
        "onTap": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const OrderCreatePage())),
      },
      {
        "icon": AppIcons.box,
        "title": "Add Product",
        "subtitle": "Register a new inverter or battery",
        'backgroundColor': Colors.purpleAccent.withValues(alpha: 0.15),
        "iconColor": Colors.purple,
        "onTap": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const ProductCreateScreen())),
      },
      {
        "icon": AppIcons.brand,
        "title": "New Brand",
        "subtitle": "Add a new brand to the system",
        'backgroundColor': Colors.orangeAccent.withValues(alpha: 0.15),
        "iconColor": Colors.orange,
        "onTap": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const BrandCreateScreen())),
      },
      {
        "icon": AppIcons.dealers,
        "title": "New Dealer",
        "subtitle": "Onboard a new dealer",
        'backgroundColor': Colors.greenAccent.withValues(alpha: 0.15),
        "iconColor": Colors.green,
        "onTap": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => const AddDealerScreen())),
      },
      {
        "icon": AppIcons.dealers, // You might want to change this to a user icon
        "title": "New Employee",
        "subtitle": "Add staff members to the app",
        'backgroundColor': Colors.deepPurpleAccent.withValues(alpha: 0.15),
        "iconColor": Colors.deepPurple,
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => const AddUserScreen())),
      },
      {
        "icon": AppIcons.bills,
        "title": "Reports",
        "subtitle": "View system reports and analytics",
        'backgroundColor': Colors.cyanAccent.withValues(alpha: 0.15),
        "iconColor": Colors.cyan.shade700,
        "onTap": () {
          // Add your Reports Screen routing here
        },
      },
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA), // Clean off-white background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- Stylish Header ---
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: Screen.w(context) * 0.05,
                vertical: Screen.h(context) * 0.02,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create & Manage',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      letterSpacing: 0.3,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Add new records to the system',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // --- The Modern ListView ---
            Expanded(
              child: ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(
                  horizontal: Screen.w(context) * 0.04,
                  vertical: Screen.h(context) * 0.01,
                ),
                itemCount: items.length,
                separatorBuilder: (context, index) => SizedBox(height: Screen.h(context) * 0.015),
                itemBuilder: (context, index) {
                  final item = items[index];

                  return GestureDetector(
                    onTap: item["onTap"] as VoidCallback,
                    child: Container(
                      padding: EdgeInsets.all(Screen.w(context) * 0.04),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.03),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Row(
                        children: [
                          // 1. Icon Container
                          Container(
                            height: Screen.w(context) * 0.13,
                            width: Screen.w(context) * 0.13,
                            decoration: BoxDecoration(
                              color: item['backgroundColor'] as Color,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Padding(
                              padding: EdgeInsets.all(Screen.w(context) * 0.03),
                              child: SvgPicture.asset(
                                item["icon"] as String,
                                colorFilter: ColorFilter.mode(
                                  item["iconColor"] as Color,
                                  BlendMode.srcIn,
                                ),
                              ),
                            ),
                          ),

                          SizedBox(width: Screen.w(context) * 0.04),

                          // 2. Titles (Expanded to prevent overflow)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item["title"] as String,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black87,
                                  ),
                                ),
                                SizedBox(height: Screen.h(context) * 0.004),
                                Text(
                                  item["subtitle"] as String,
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),

                          // 3. Navigation Chevron
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 16,
                            color: Colors.grey.shade400,
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),

            // Padding at the bottom to account for your floating bottom navigation bar
            SizedBox(height: Screen.h(context) * 0.1),
          ],
        ),
      ),
    );
  }
}