import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/feature/order/screen/orders_view_page.dart';
import '../core/const/icons.dart';
import '../core/media_query/media_query.dart';
import 'createSection.dart';
import 'Dashboard/superadmin_dashboard_screen.dart';
import 'package:inverter_management_app/feature/order/screen/today_orders_screen.dart';

class SuperAdminTabletView extends ConsumerStatefulWidget {
  const SuperAdminTabletView({super.key});
  @override
  ConsumerState<SuperAdminTabletView> createState() => _SuperAdminHomeScreenState();
}

class _SuperAdminHomeScreenState extends ConsumerState<SuperAdminTabletView> {
   int _currentIndex  = 0;
  List<Widget> body = const[
    SuperadminDashboard(),
    OrdersViewPage(),
    CreateSection(),
    TodayOrdersScreen()
  ];

  @override
  Widget build(BuildContext context) {
    screenHeight = MediaQuery.of(context).size.height;
    screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        title: Text('Smart Enterprises',style: TextStyle(color: Theme.of(context).primaryColor,fontSize: 20,fontWeight: FontWeight.w500)),
        actions: [
          IconButton(onPressed: (){}, icon: SvgPicture.asset(AppIcons.notification,colorFilter: ColorFilter.mode(Colors.black,BlendMode.srcIn),),),
          Padding(
            padding: EdgeInsets.only(right: screenWidth*0.04),
            child: CircleAvatar(
              backgroundColor: Theme.of(context).primaryColor,
              child: SvgPicture.asset(AppIcons.dealers,colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),),
            ),
          )
        ],
      ),
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
                  icon: SvgPicture.asset(AppIcons.orders,
                      colorFilter: ColorFilter.mode(
                        _currentIndex == 1
                            ? Theme.of(context).primaryColor   // selected
                            : Colors.black,                    // unselected
                        BlendMode.srcIn,
                      )
                  ),
                  label: 'Orders',
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
                  label: 'Delivery',
                ),
              ],
            )
        )
    );
  }

}