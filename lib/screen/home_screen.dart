import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:inverter_management_app/core/const/icons.dart';
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
  bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Colors.white,
        shape:  RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(screenWidth * 0.1),
            bottomRight: Radius.circular(screenWidth*0.1),
          ),
        ),
        child: Column(
          children: [
             SizedBox(height: screenHeight * 0.05),
            // Logo & Integration Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.all_inclusive, color: Colors.purple),
                SizedBox(width: 8),
                Text("Integration", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              ],
            ),
             SizedBox(height: screenHeight* 0.03),
            _drawerItem(AppIcons.shop, "Dealers", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DealersScreen()));
            }),
            _drawerItem(AppIcons.product, "Products", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
            }),
            _drawerItem(AppIcons.dealers, "Users", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
            }),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("SHORTCUTS", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
            // Settings after Users (swapped)

            _drawerItem(AppIcons.settings, "Settings", onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
            }),

            const Spacer(),
             SizedBox(height: screenHeight* 0.02),
          ],
        ),
      ),
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        leading: Builder(
          builder: (context) => IconButton(
            icon: SvgPicture.asset(
              AppIcons.menu_2, // your custom SVG path
              height: screenHeight * 0.03,
              width: screenWidth * 0.03,
            ),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        title: AnimatedSwitcher(
          duration: const Duration(milliseconds: 140),
          transitionBuilder: (child, animation) => FadeTransition(opacity: animation, child: child),
          child: _showSearchBar
              ? SizedBox(
            key: const ValueKey("search"),
            height: screenHeight * 0.045,
            child: TextField(
              controller: _searchController,
              autofocus: true,
              decoration: InputDecoration(
                hintText: 'Search...',
                hintStyle: TextStyle(color: Colors.grey[600]),
                filled: true,
                fillColor: Colors.grey[200],
                contentPadding:  EdgeInsets.symmetric(horizontal: screenWidth* 0.04, vertical: screenHeight * 0.01),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth* 0.045),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          )
              : SizedBox(),
        ),
        actions: [
          IconButton(
            icon:  SvgPicture.asset(
      _showSearchBar ?AppIcons.close: AppIcons.search,
        height: screenHeight* 0.03,
        width: screenWidth* 0.03,
      ),
            onPressed: () {
              setState(() {
                _showSearchBar = !_showSearchBar;
                if (!_showSearchBar) _searchController.clear();
              });
            },
          ),
          IconButton(
            icon:  SvgPicture.asset(
              AppIcons.notification,
              height: screenHeight* 0.03,
              width: screenWidth* 0.03,
            ),
            onPressed: () {
              // Notification action
            },
          ),
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: GestureDetector(
              onTap: () {
                // Profile action
              },
              child: const CircleAvatar(
                radius: 16,
                // backgroundImage: AssetImage(''),
              ),
            ),
          ),
        ],
      ),

      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: _screens[_selectedIndex],
      ),
      bottomNavigationBar: Container(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.03,
          vertical: screenHeight * 0.02,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).scaffoldBackgroundColor,
          // color: Colors.red,
          boxShadow: [
            BoxShadow(
              color: Colors.black12,
              blurRadius: 6,
              offset: Offset(0, -2),
            ),
          ],
          borderRadius: BorderRadius.only(topLeft: Radius.circular(screenWidth*0.06),topRight: Radius.circular(screenWidth*0.06))
        ),
        child: GNav(
          gap: screenWidth * 0.02,
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          color: Colors.grey[600],
          activeColor: AppTheme.primaryColor,
          tabBackgroundColor: AppTheme.primaryColorLight.withValues(alpha: 0.15),
          padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.03, vertical: screenHeight* 0.012),
          selectedIndex: _selectedIndex,
          onTabChange: _onNavItemTap,
          tabs: [
            GButton(
              icon: Icons.circle,
              text: 'Dashboard',
              leading: SvgPicture.asset(
                AppIcons.home,
                height: screenHeight* 0.03,
                width: screenWidth* 0.03,
                colorFilter: ColorFilter.mode(
                  _selectedIndex == 0 ? AppTheme.primaryColor : Colors.black,
                  BlendMode.srcIn,
                ),
              ),
            ),
             GButton(icon: Icons.circle,leading: SvgPicture.asset(
              AppIcons.orders,
               height: screenHeight* 0.03,
               width: screenWidth* 0.03,
               colorFilter: ColorFilter.mode(
                 _selectedIndex == 1 ? AppTheme.primaryColor : Colors.black,
                 BlendMode.srcIn,
               ),
            ), text: 'Orders'),
             GButton(icon: Icons.circle,leading:SvgPicture.asset(
              AppIcons.bills,
              height: screenHeight* 0.03,
              width: screenWidth* 0.03,
               colorFilter: ColorFilter.mode(
                 _selectedIndex == 2 ? AppTheme.primaryColor : Colors.black,
                 BlendMode.srcIn,
               ),
            ) , text: 'Bills'),
             GButton(icon: Icons.circle,leading: SvgPicture.asset(
               AppIcons.delivery,
               height: screenHeight* 0.03,
               width: screenWidth* 0.03,
               colorFilter: ColorFilter.mode(
                 _selectedIndex == 3 ? AppTheme.primaryColor : Colors.black,
                 BlendMode.srcIn,
               ),
             ), text: 'Delivery'),
          ],
        ),
      ),
    );
  }
}
Widget _drawerItem(String icon, String label, {VoidCallback? onTap}) {
  return Padding(
    padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.04, vertical: screenHeight* 0.01),
    child: InkWell(
      borderRadius: BorderRadius.circular(screenWidth* 0.04),
      onTap: onTap,
      child: Container(
        padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.04, vertical: screenHeight* 0.011),
        child: Row(
          children: [
          SvgPicture.asset(icon,
          height: screenHeight* 0.03,
          width: screenWidth* 0.03,
          // colorFilter: ColorFilter.mode(
          // ),
          ),
             SizedBox(width: screenWidth*0.03),
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.normal,
                color: Colors.black87,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
