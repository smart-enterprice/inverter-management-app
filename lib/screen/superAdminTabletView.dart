import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import '../core/const/icons.dart';
import '../core/media_query/media_query.dart';
import '../feature/authentication/controller/login_controller.dart';
import '../feature/authentication/screen/login_mobile_view.dart';
import 'createSection.dart';
import 'dashboard_screen.dart';
import 'delivery_screen.dart';

class SuperAdminTabletView extends ConsumerStatefulWidget {
  const SuperAdminTabletView({super.key});
  @override
  ConsumerState<SuperAdminTabletView> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends ConsumerState<SuperAdminTabletView> {
  int _currentIndex = 0;
  late final List<Widget> pages = const [
    DashboardScreen(),   // 0
    OrdersViewPage(),    // 1
    CreateSection(),     // 2 (Accounts)
    DeliveryScreen(),    // 3
  ];

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        title: Text(
          'Inverter ERP',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: Icon(Icons.menu, color: Colors.black, size: screenWidth * 0.06),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: SvgPicture.asset(
              AppIcons.notification,
              colorFilter: ColorFilter.mode(Colors.black, BlendMode.srcIn),
            ),
          ),
          Padding(
            padding: EdgeInsets.only(right: screenWidth * 0.04),
            child: CircleAvatar(
              backgroundColor: Colors.blue,
              child: Icon(Icons.person, color: Colors.white),
            ),
          ),
        ],
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Colors.blue[700],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.person, size: 30, color: Colors.blue[700]),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Super Admin',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'admin@inverter.com',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Dashboard
            ListTile(
              leading: Icon(Icons.dashboard, color: _currentIndex == 0 ? Colors.blue : Colors.grey),
              title: Text(
                "Dashboard",
                style: TextStyle(
                  color: _currentIndex == 0 ? Colors.blue : Colors.black,
                  fontWeight: _currentIndex == 0 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 0);
              },
            ),

            // Dealers
            ListTile(
              leading: Icon(Icons.people, color: Colors.grey),
              title: Text("Dealers"),
              onTap: () {
                Navigator.pop(context);
                // Handle dealers navigation
              },
            ),

            // Employees
            ListTile(
              leading: Icon(Icons.badge, color: Colors.grey),
              title: Text("Employees"),
              onTap: () {
                Navigator.pop(context);
                // Handle employees navigation
              },
            ),

            // Orders
            ListTile(
              leading: Icon(Icons.shopping_cart, color: _currentIndex == 1 ? Colors.blue : Colors.grey),
              title: Text(
                "Orders",
                style: TextStyle(
                  color: _currentIndex == 1 ? Colors.blue : Colors.black,
                  fontWeight: _currentIndex == 1 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 1);
              },
            ),

            // Accounts
            ListTile(
              leading: Icon(Icons.account_balance, color: _currentIndex == 2 ? Colors.blue : Colors.grey),
              title: Text(
                "Accounts",
                style: TextStyle(
                  color: _currentIndex == 2 ? Colors.blue : Colors.black,
                  fontWeight: _currentIndex == 2 ? FontWeight.bold : FontWeight.normal,
                ),
              ),
              onTap: () {
                Navigator.pop(context);
                setState(() => _currentIndex = 2);
              },
            ),

            const Divider(),

            // Settings
            ListTile(
              leading: Icon(Icons.settings, color: Colors.grey),
              title: Text("Settings"),
              onTap: () {
                Navigator.pop(context);
                // Handle settings navigation
              },
            ),

            // Logout
            ListTile(
              leading: Icon(Icons.logout, color: Colors.red),
              title: Text(
                "Logout",
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                final controller = ref.read(loginControllerProvider);
                await controller.logout();
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginMobileView()),
                );
              },
            ),
          ],
        ),
      ),
      body: _currentIndex == 0 ? _buildDashboard() : pages[_currentIndex],
    );
  }

  Widget _buildDashboard() {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Welcome back section
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Welcome back! Here\'s your business overview.',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildStatCard(
                        title: 'Total Dealers',
                        value: '1,248',
                        icon: Icons.people,
                        color: Colors.blue,
                      ),
                      _buildStatCard(
                        title: 'Total Employees',
                        value: '342',
                        icon: Icons.badge,
                        color: Colors.green,
                      ),
                      _buildStatCard(
                        title: 'Total Orders',
                        value: '8,456',
                        icon: Icons.shopping_cart,
                        color: Colors.orange,
                      ),
                      _buildStatCard(
                        title: 'Pending Amount',
                        value: '¥12,45,890',
                        icon: Icons.account_balance_wallet,
                        color: Colors.red,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            SizedBox(height: 30),

            // Main Modules section
            Text(
              'Main Modules',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 10),
            Text(
              'Quick access to core features',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildModuleCard(
                    title: 'Dealers',
                    subtitle: 'Create & manage dealers',
                    icon: Icons.people,
                    color: Colors.blue,
                    actionText: '+ Create Dealer',
                    onTap: () {},
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: _buildModuleCard(
                    title: 'Orders',
                    subtitle: 'Create & track orders',
                    icon: Icons.shopping_cart,
                    color: Colors.orange,
                    actionText: '+ Create Order',
                    onTap: () {
                      setState(() => _currentIndex = 1);
                    },
                  ),
                ),
              ],
            ),

            SizedBox(height: 20),

            Row(
              children: [
                Expanded(
                  child: _buildModuleCard(
                    title: 'Employees',
                    subtitle: 'Create & manage employees',
                    icon: Icons.badge,
                    color: Colors.green,
                    actionText: '+ Create Employee',
                    onTap: () {},
                  ),
                ),
                SizedBox(width: 20),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.1),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.account_balance, color: Colors.purple),
                            SizedBox(width: 10),
                            Text(
                              'Accounts',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 10),
                        Text(
                          'Payments & pending amounts',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 20),
                        _buildAccountStat(
                          title: 'Total Ordered',
                          value: '¥45,67,890',
                          color: Colors.green,
                        ),
                        SizedBox(height: 10),
                        _buildAccountStat(
                          title: 'Pending',
                          value: '¥12,45,890',
                          color: Colors.red,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            SizedBox(height: 30),

            // Accounts Analytics section
            Container(
              padding: EdgeInsets.all(screenWidth * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.withOpacity(0.1),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Accounts Analytics',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Revenue trends and comparisons',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                  SizedBox(height: 20),
                  // Placeholder for chart
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Center(
                      child: Text(
                        'Chart visualization will be here',
                        style: TextStyle(color: Colors.grey[500]),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      width: screenWidth * 0.18,
      padding: EdgeInsets.all(screenWidth * 0.02),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          SizedBox(height: 15),
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(height: 5),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required String actionText,
    required VoidCallback onTap,
  }) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.03),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color),
              SizedBox(width: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
            ],
          ),
          SizedBox(height: 10),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: color,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            child: Text(
              actionText,
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountStat({
    required String title,
    required String value,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 14,
            color: Colors.grey[600],
          ),
        ),
        SizedBox(height: 5),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }
}