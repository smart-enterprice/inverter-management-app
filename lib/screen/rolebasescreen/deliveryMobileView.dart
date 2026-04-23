import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import 'package:inverter_management_app/feature/order/screen/today_orders_screen.dart';
import '../../core/const/icons.dart';
import '../Dashboard/deliveryDashboard.dart';
import '../createSection.dart';

class _NavItem {
  const _NavItem({required this.icon, required this.label});
  final String icon;
  final String label;
}

const _navItems = [
  _NavItem(icon: AppIcons.home,     label: 'Home'),
  _NavItem(icon: AppIcons.orders,   label: 'Orders'),
  _NavItem(icon: AppIcons.add,      label: 'Create'),
  _NavItem(icon: AppIcons.delivery, label: 'Delivery'),
];

class DeliveryMobileView extends ConsumerStatefulWidget {
  const DeliveryMobileView({super.key});

  @override
  ConsumerState<DeliveryMobileView> createState() => _DeliveryMobileViewState();
}

class _DeliveryMobileViewState extends ConsumerState<DeliveryMobileView> {
  int _currentIndex = 0;

  static const List<Widget> _pages = [
    DeliveryDashboard(),
    OrdersViewPage(),
    CreateSection(),
    TodayOrdersScreen(),
  ];

  void _onNavTap(int index) {
    if (_currentIndex == index) return;
    setState(() => _currentIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _pages),
          Positioned(
            bottom: 20,
            left: 24,
            right: 24,
            child: _FloatingNavBar(
              currentIndex: _currentIndex,
              primaryColor: primaryColor,
              onTap: _onNavTap,
            ),
          ),
        ],
      ),
    );
  }
}

class _FloatingNavBar extends StatelessWidget {
  const _FloatingNavBar({
    required this.currentIndex,
    required this.primaryColor,
    required this.onTap,
  });

  final int currentIndex;
  final Color primaryColor;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    // Available width = screen width minus the 24+24 side margins
    final availableWidth = MediaQuery.sizeOf(context).width - 48;

    // Responsiveness thresholds:
    // < 300px → hide labels entirely (icon-only mode)
    // 300–340 → smaller padding, smaller font
    // > 340   → full size
    final bool showLabels   = availableWidth >= 300;
    final double pillVPad   = availableWidth < 340 ? 8.0  : 10.0;
    final double pillHPad   = availableWidth < 340 ? 10.0 : 16.0;
    final double labelSize  = availableWidth < 360 ? 12.0 : 14.0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
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
        children: List.generate(
          _navItems.length,
              (i) => _NavPill(
            item: _navItems[i],
            isSelected: currentIndex == i,
            primaryColor: primaryColor,
            showLabel: showLabels,
            pillVPad: pillVPad,
            pillHPad: pillHPad,
            labelSize: labelSize,
            onTap: () => onTap(i),
          ),
        ),
      ),
    );
  }
}

class _NavPill extends StatelessWidget {
  const _NavPill({
    required this.item,
    required this.isSelected,
    required this.primaryColor,
    required this.showLabel,
    required this.pillVPad,
    required this.pillHPad,
    required this.labelSize,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final Color primaryColor;
  final bool showLabel;
  final double pillVPad;
  final double pillHPad;
  final double labelSize;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        padding: EdgeInsets.symmetric(
          horizontal: pillHPad,
          vertical: pillVPad,
        ),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SvgPicture.asset(
              item.icon,
              height: 24,
              colorFilter: ColorFilter.mode(
                isSelected ? primaryColor : Colors.grey.shade500,
                BlendMode.srcIn,
              ),
            ),
            if (showLabel)
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: isSelected
                    ? Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Text(
                    item.label,
                    style: TextStyle(
                      color: primaryColor,
                      fontWeight: FontWeight.bold,
                      fontSize: labelSize,
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