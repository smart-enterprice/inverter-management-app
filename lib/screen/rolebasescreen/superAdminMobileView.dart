import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import '../../core/const/icons.dart';
import '../createSection.dart';
import '../dashboard_screen.dart';

class SuperAdminMobileView extends ConsumerStatefulWidget {
  const SuperAdminMobileView({super.key});
  @override
  ConsumerState<SuperAdminMobileView> createState() =>
      _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends ConsumerState<SuperAdminMobileView> {
  int _currentIndex = 0;

  // ✅ Fix 1: Make sure you have 4 screens here to match your 4 nav items!
  final List<Widget> body = const [
    DashboardScreen(),
    OrdersViewPage(),
    // CreateSection(),
    CreateSection(),
  ];

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          SafeArea(child: body[_currentIndex]),

          // The Custom Floating Bottom Navigation Bar
          Positioned(
            bottom: 20,
            left: 16, // ✅ Fix 2: Reduced outer margins slightly so 4 items can fit
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12), // ✅ Reduced inner padding
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.08),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildNavItem(
                    index: 0,
                    icon: AppIcons.home,
                    label: 'Home',
                    primaryColor: primaryColor,
                  ),
                  _buildNavItem(
                    index: 1,
                    icon: AppIcons.orders,
                    label: 'Orders',
                    primaryColor: primaryColor,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: AppIcons.add,
                    label: 'Create', // Capitalized label
                    primaryColor: primaryColor,
                  ),
                  _buildNavItem(
                    index: 2, // ✅ Fix 3: Changed this from 2 to 3!
                    icon: AppIcons.delivery,
                    label: 'Delivery', // Capitalized label
                    primaryColor: primaryColor,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Custom Nav Item Widget with Animation
  Widget _buildNavItem({
    required int index,
    required String icon,
    required String label,
    required Color primaryColor,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () {
        setState(() {
          _currentIndex = index;
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        // ✅ Fix 4: Unselected items have smaller padding to save horizontal space
        padding: EdgeInsets.symmetric(horizontal: isSelected ? 12 : 8, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? primaryColor.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            SvgPicture.asset(
              icon,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? primaryColor : Colors.grey.shade500,
                BlendMode.srcIn,
              ),
            ),
            // The expanding label animation
            AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              child: isSelected
                  ? Padding(
                padding: const EdgeInsets.only(left: 6.0), // Slightly tighter text padding
                child: Text(
                  label,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 13, // Slightly smaller font to guarantee fit on small phones
                  ),
                ),
              )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}