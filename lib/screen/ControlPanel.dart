import 'package:flutter/material.dart';

import '../core/const/icons.dart';
import '../core/media_query/media_query.dart';
import '../feature/signup/screen/dealer/dealers_screen.dart';
import '../widgets/create_card.dart';

class ControlPanel extends StatelessWidget {
  const ControlPanel({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        "icon": AppIcons.orders,
        "title": "Orders",
        "color": Colors.white,
        'backgroundColor': Colors.lightBlueAccent.withValues(alpha: 0.25),
        "iconColor": Theme.of(context).primaryColor,
        "onTap": (){}
      },
      {
        "icon": AppIcons.box,
        "title": "Products",
        "color": Colors.white,
        'backgroundColor': Colors.purpleAccent.withValues(alpha: 0.25),
        "iconColor": Colors.purpleAccent,
        "onTap": (){}
      },
      {
        "icon": AppIcons.brand,
        "title": "Brands",
        "color": Colors.white,
        'backgroundColor': Colors.orangeAccent.withValues(alpha: 0.25),
        "iconColor": Colors.orange,
        "onTap": (){}
      },
      {
        "icon": AppIcons.dealers,
        "title": "Dealers",
        "color": Colors.white,
        'backgroundColor': Colors.greenAccent.withValues(alpha: 0.25),
        "iconColor": Colors.green,
        "onTap": ()=> Navigator.push(context, MaterialPageRoute(builder: (context)=>DealersScreen()))
      },
      {
        "icon": AppIcons.dealers,
        "title": "Employees",
        "color": Colors.white,
        'backgroundColor': Colors.deepPurpleAccent.withValues(alpha: 0.25),
        "iconColor": Colors.deepPurple,
        "onTap": (){}
      },
    ];
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04,vertical: screenHeight*0.04),
        child: GridView.count(
          crossAxisCount: 2, // two per row (adjust as needed)
          crossAxisSpacing: screenWidth * 0.04,
          mainAxisSpacing: screenHeight * 0.02,
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
