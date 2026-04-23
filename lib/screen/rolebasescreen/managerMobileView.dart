import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import 'package:inverter_management_app/feature/order/screen/today_orders_screen.dart';
import 'package:inverter_management_app/model/user_model.dart';
import 'package:inverter_management_app/screen/Dashboard/salesman_dashboard.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/const/icons.dart';
import '../../feature/signup/controller/signUp_controller.dart';
import '../Dashboard/managerDashboard.dart';
import '../createSection.dart';
import '../Dashboard/superadmin_dashboard_screen.dart';

class ManagerMobileView extends ConsumerStatefulWidget {
  const ManagerMobileView({super.key});
  @override
  ConsumerState<ManagerMobileView> createState() => _ManagerMobileViewState();
}

class _ManagerMobileViewState extends ConsumerState<ManagerMobileView> {
  int _currentIndex = 0;
  UserModel? _user;

  final List<Widget> body = const [
    ManagerDashboard(),
    OrdersViewPage(),
    CreateSection(),
    TodayOrdersScreen()
  ];

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      final user = await ref
          .read(signupControllerProvider.notifier)
          .getEmployeeById(userId);
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          body[_currentIndex],
          Positioned(
            bottom: 20, // Distance from the bottom of the screen
            left: 24, // Side margins
            right: 24,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(30), // Pill shape
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
                    index: 2,
                    icon: AppIcons.add,
                    label: 'Create',
                    primaryColor: primaryColor,
                  ),
                  _buildNavItem(
                    index: 3,
                    icon: AppIcons.time,
                    label: 'Today',
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
  Widget _buildNavItem({
    required int index,
    required String icon,
    required String label,
    required Color primaryColor,
  })
  {
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                padding: const EdgeInsets.only(left: 8.0),
                child: Text(
                  label,
                  style: TextStyle(
                    color: primaryColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              )
                  : const SizedBox.shrink(), // Hides the text when not selected
            ),
          ],
        ),
      ),
    );
  }
}