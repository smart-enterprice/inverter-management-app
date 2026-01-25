import 'package:flutter/material.dart';
import 'package:inverter_management_app/feature/order/screen/order_create_page.dart';

import '../core/const/icons.dart';
import '../core/media_query/media_query.dart';
import '../feature/brand/screen/brands_page.dart';
import '../feature/order/screen/orders_view_page.dart';
import '../feature/product/screen/products_screen.dart';
import '../feature/signup/screen/dealer/dealers_screen.dart';
import '../feature/signup/screen/user/users_screen.dart';
import '../widgets/create_card.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          CreateCard(
            iconPath: AppIcons.add,
            title: 'Order',
            color: Colors.white,
            backgroundColor: Colors.blue.shade50,
            iconColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const OrderCreatePage(  )),
              );
            },
          ),
          SizedBox(width: Screen.w(context)*0.01,),
          CreateCard(
            iconPath: AppIcons.product,
            title: 'Products',
            color: Colors.white,
            backgroundColor: Colors.blue.shade50,
            iconColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProductsScreen()),
              );
            },
          ),
          SizedBox(width: Screen.w(context)*0.01,),
          CreateCard(
            iconPath: AppIcons.brand,
            title: 'Brands',
            color: Colors.white,
            backgroundColor: Colors.blue.shade50,
            iconColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BrandsScreen()),
              );
            },
          ),
          SizedBox(width: Screen.w(context)*0.01,),
          CreateCard(
            iconPath: AppIcons.dealers,
            title: 'Dealers',
            color: Colors.white,
            backgroundColor: Colors.blue.shade50,
            iconColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const DealersScreen()),
              );
            },
          ),
          SizedBox(width: Screen.w(context)*0.01,),
          CreateCard(
            iconPath: AppIcons.dealers,
            title: 'Users',
            color: Colors.white,
            backgroundColor: Colors.blue.shade50,
            iconColor: Colors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UsersScreen()),
              );
            },
          ),
        ],
      ),
    );
}
}
