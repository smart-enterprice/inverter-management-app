import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../core/const/icons.dart';
import '../core/media_query/media_query.dart';
import '../feature/authentication/controller/login_controller.dart';
import '../feature/authentication/screen/login_screen.dart';
import 'createSection.dart';
import 'dashboard_screen.dart';
import 'delivery_screen.dart';
import 'orders_screen.dart';

class SuperAdminHomeScreen extends ConsumerStatefulWidget {
  const SuperAdminHomeScreen({super.key});
  @override
  ConsumerState<SuperAdminHomeScreen> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends ConsumerState<SuperAdminHomeScreen> {
  int _selectedIndex = 0;
  int _currentIndex  = 0;
  List<Widget> body = const[
    DashboardScreen(),
    Icon(Icons.dashboard),
    CreateSection(),
    Icon(Icons.settings)
  ];
  final List<Widget> _screens = [
    OrdersScreen(),
    // BillsScreen(),
    DeliveryScreen(),
    IconButton(onPressed: (){}, icon: Icon(Icons.logout)),
  ];

  void _onNavItemTap(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  final bool _showSearchBar = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).primaryColor,
        title: Text('Smart Enterprises',style: TextStyle(color: Colors.white,fontSize: 26,fontWeight: FontWeight.w500)),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black, size: screenWidth * 0.08),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(onPressed: (){}, icon: SvgPicture.asset(AppIcons.notification,colorFilter: ColorFilter.mode(Colors.white,BlendMode.srcIn),),),
          Padding(
            padding: EdgeInsets.only(right: screenWidth*0.04),
            child: CircleAvatar(
              backgroundColor: Colors.white,
              child: SvgPicture.asset(AppIcons.dealers),
            ),
          )
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: Theme.of(context).primaryColor),
              child: Text(
                'Super Admin',
                style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ),
            ListTile(
              leading: Icon(Icons.dashboard),
              title: Text("Dashboard"),
              onTap: () {
                // Navigator.pushReplacement(
                //     context, MaterialPageRoute(builder: (_) => DashboardScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.people),
              title: Text("Users"),
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => UsersScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.store),
              title: Text("Dealers"),
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => DealersScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.branding_watermark),
              title: Text("Brands"),
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => BrandsPage()));
              },
            ),
            ListTile(
              leading: Icon(Icons.inventory),
              title: Text("Products"),
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => ProductsScreen()));
              },
            ),
            ListTile(
              leading: Icon(Icons.settings),
              title: Text("Settings"),
              onTap: () {
                // Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsScreen()));
              },
            ),
            const Divider(),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text("Logout", style: TextStyle(color: Colors.red)),
              onTap: () async {
                final controller = ref.read(loginControllerProvider);
                await controller.logout();
                // ignore: use_build_context_synchronously
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                );
              },
            ),
          ],
        ),
      ),
      // body: _screens[_selectedIndex],
      body: body[_currentIndex],
        bottomNavigationBar: Theme(
          data: Theme.of(context).copyWith(
            splashColor: Colors.transparent,
            highlightColor: Colors.transparent,
          ),
          child: BottomNavigationBar(
            elevation: 1,
            unselectedItemColor: Colors.black,
            type: BottomNavigationBarType.fixed,
            backgroundColor: Colors.white,
            currentIndex: _currentIndex,
            selectedFontSize: 14,
            selectedLabelStyle: TextStyle(fontWeight: FontWeight.bold),
            unselectedFontSize: 14,
            selectedItemColor: Theme.of(context).primaryColor,
            onTap: (int index) {
              setState(() {
                _currentIndex = index;
              });
            },
            items: [
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  AppIcons.home,
                  colorFilter: ColorFilter.mode(
                    _currentIndex == 0
                        ? Theme.of(context).primaryColor   // selected
                        : Colors.black,                    // unselected
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  AppIcons.orders,
                  colorFilter: ColorFilter.mode(
                    _currentIndex == 1
                        ? Theme.of(context).primaryColor
                        : Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Orders',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  AppIcons.add,
                  colorFilter: ColorFilter.mode(
                    _currentIndex == 2
                        ? Theme.of(context).primaryColor
                        : Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Create',
              ),
              BottomNavigationBarItem(
                icon: SvgPicture.asset(
                  AppIcons.delivery,
                  colorFilter: ColorFilter.mode(
                    _currentIndex == 3
                        ? Theme.of(context).primaryColor
                        : Colors.black,
                    BlendMode.srcIn,
                  ),
                ),
                label: 'Settings',
              ),
            ],
          )

        )

    );
  }
}
