import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/feature/brand/screen/brands_page.dart';
import 'package:inverter_management_app/screen/products_screen.dart';
import 'package:inverter_management_app/screen/settings_screen.dart';
import '../feature/authentication/controller/login_controller.dart';
import '../feature/authentication/screen/login_screen.dart';
import '../feature/signup/screen/user/users_screen.dart';
import 'bills_screen.dart';
import 'dashboard_screen.dart';
import '../feature/signup/screen/dealer/dealers_screen.dart';
import 'delivery_screen.dart';
import 'orders_screen.dart';

class SuperAdminHomeScreen extends ConsumerStatefulWidget {
  const SuperAdminHomeScreen({super.key});

  @override
  ConsumerState<SuperAdminHomeScreen> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends ConsumerState<SuperAdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = [
    DashboardScreen(),
    OrdersScreen(),
    BillsScreen(),
    DeliveryScreen(),
    IconButton(onPressed: (){}, icon: Icon(Icons.logout))
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
        width: screenWidth*0.7,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        shape:  RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(screenWidth * 0.03),
            bottomRight: Radius.circular(screenWidth*0.03),
          ),
        ),
        child: Column(
          children: [
             SizedBox(height: screenHeight * 0.05),
            // Logo & Integration Header
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children:  [
                Icon(Icons.all_inclusive, color: Colors.purple),
                SizedBox(width: 8),
                Text("Integration", style: Theme.of(context).textTheme.displayLarge),
              ],
            ),
             SizedBox(height: screenHeight* 0.03),
            _drawerItem(AppIcons.dealers, "Users", context,onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const UsersScreen()));
            }),
            _drawerItem(AppIcons.shop, "Dealers", context,onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const DealersScreen()));
            }),
            _drawerItem(AppIcons.product, "Products",context, onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductsScreen()));
            }),
            _drawerItem(AppIcons.brand, "Brands", context,onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => const BrandsScreen()));
            }),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text("SHORTCUTS", style: TextStyle(fontSize: 12, color: Colors.grey)),
              ),
            ),
            // Settings after Users (swapped)

            _drawerItem(AppIcons.settings, "Settings",context, onTap: () {
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
              colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
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
                fillColor: Theme.of(context).focusColor,
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
              colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
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
              colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
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
              child:  CircleAvatar(
                radius: screenWidth*0.05,
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
Widget _drawerItem(String icon, String label,context, {VoidCallback? onTap}) {
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
          colorFilter: ColorFilter.mode(
            Theme.of(context).primaryColor,BlendMode.srcIn
          ),
          ),
             SizedBox(width: screenWidth*0.03),
            Text(
              label,
              style:Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    ),
  );
}
