import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/feature/order/screen/order_create_page.dart';
import 'package:inverter_management_app/feature/product/screen/product_create_screen.dart';
import '../feature/brand/screen/brand_create.dart';
import '../feature/signup/screen/dealer/dealers_sign_up_screen.dart';
import '../feature/signup/screen/user/sign_up_screen.dart';
import '../widgets/create_card.dart';

class CreateSection extends StatelessWidget {
  const CreateSection({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "icon": AppIcons.orders,
        "title": "New Order",
        "color": Colors.white,
        'backgroundColor': Colors.lightBlueAccent.withValues(alpha: 0.25),
        "iconColor": Theme.of(context).primaryColor,
        "onTap": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => OrderCreatePage())),
      },
      {
        "icon": AppIcons.box,
        "title": "Add Product",
        "color": Colors.white,
        'backgroundColor': Colors.purpleAccent.withValues(alpha: 0.25),
        "iconColor": Colors.purpleAccent,
        "onTap": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => ProductCreateScreen())),
      },
      {
        "icon": AppIcons.brand,
        "title": "New Brand",
        "color": Colors.white,
        'backgroundColor': Colors.orangeAccent.withValues(alpha: 0.25),
        "iconColor": Colors.orange,
        "onTap": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => BrandCreateScreen())),
      },
      {
        "icon": AppIcons.dealers,
        "title": "New Dealer",
        "color": Colors.white,
        'backgroundColor': Colors.greenAccent.withValues(alpha: 0.25),
        "iconColor": Colors.green,
        "onTap": () => Navigator.push(context,
            MaterialPageRoute(builder: (context) => AddDealerScreen())),
      },
      {
        "icon": AppIcons.dealers,
        "title": "New Employee",
        "color": Colors.white,
        'backgroundColor': Colors.deepPurpleAccent.withValues(alpha: 0.25),
        "iconColor": Colors.deepPurple,
        "onTap": () => Navigator.push(
            context, MaterialPageRoute(builder: (context) => AddUserScreen())),
      },
      {
        "icon": AppIcons.bills,
        "title": "Reports",
        "color": Colors.white,
        'backgroundColor': Colors.cyanAccent.withValues(alpha: 0.25),
        "iconColor": Colors.cyan,
        "onTap": () {},
      },
    ];
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: Screen.w(context) * 0.04,
            vertical: Screen.h(context) * 0.04),
        child: GridView.count(
          crossAxisCount: 2, // two per row (adjust as needed)
          crossAxisSpacing: Screen.w(context) * 0.04,
          mainAxisSpacing: Screen.h(context) * 0.02,
          children: items.map((item) {
            return CreateCard(
              iconPath: item["icon"] as String,
              title: item["title"] as String,
              color: item["color"] as Color,
              iconColor: item["iconColor"] as Color,
              onTap: item["onTap"] as VoidCallback,
              backgroundColor: item['backgroundColor'] as Color,
            );
          }).toList(),
        ),
      ),
    );
  }
}
