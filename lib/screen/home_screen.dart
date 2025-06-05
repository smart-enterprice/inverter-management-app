import 'package:flutter/material.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/screen/products_screen.dart';
import 'package:inverter_management_app/screen/settings_screen.dart';
import 'package:inverter_management_app/screen/users_screen.dart';
import 'bills_screen.dart';
import 'dashboard_screen.dart';
import 'dealers_screen.dart';
import 'delivery_screen.dart';
import 'orders_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    OrdersScreen(),
    BillsScreen(),
    DeliveryScreen(),
  ];
  void _onNavItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }
  Widget buildNavItem({required IconData icon, required String label, required int index}) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => _onNavItemTap(index),
      child: Container(
        width: screenWidth * 1 / 5,
        margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColorLight : null,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppTheme.textPrimary, size: 24),
            const SizedBox(height: 4),
            Text(label, style: AppTheme.smallText2, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: TextField(
          decoration: InputDecoration(
            hintText: 'Search...',
            hintStyle: TextStyle(color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.grey[200],
            contentPadding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(30),
              borderSide: BorderSide.none,
            ),
            prefixIcon: const Icon(Icons.search, color: Colors.grey),
          ),
        ),
        actions: [
          PopupMenuButton<int>(
            color: AppTheme.backgroundColor,
            icon: const Icon(Icons.more_vert, color: AppTheme.textPrimary),
            onSelected: (value) {
              switch (value) {
                case 1:
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const UsersScreen()));
                  break;
                case 2:
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const DealersScreen()));
                  break;
                case 3:
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const ProductsScreen()));
                  break;
                case 4:
                  Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
                  break;
              }
            },
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 1,
                child: Text('Users'),
              ),
              PopupMenuItem(
                value: 2,
                child: Text('Dealers'),
              ),
              PopupMenuItem(
                value: 3,
                child: Text('Products'),
              ),
              PopupMenuItem(
                value: 4,
                child: Text('Settings'),
              ),
            ],
          ),
        ],

      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.only(bottom: screenHeight * 0.03),
        color: Theme.of(context).scaffoldBackgroundColor,
        height: screenHeight * 0.1,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              buildNavItem(icon: Icons.bar_chart, label: 'Dashboard', index: 0),
              buildNavItem(icon: Icons.shopping_cart_outlined, label: 'Orders', index: 1),
              buildNavItem(icon: Icons.note_outlined, label: 'Bills', index: 2),
              buildNavItem(icon: Icons.local_shipping_outlined, label: 'Delivery', index: 3),
            ],
          ),
        ),
      ),
    );
  }
}
