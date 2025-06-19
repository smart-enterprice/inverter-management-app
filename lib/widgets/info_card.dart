import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';

import 'card.dart';

class InfoCard extends StatelessWidget {
  const InfoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: BoxCard(
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(AppIcons.shop),
                    SizedBox(height: screenHeight*0.01,),
                    Text('50',style: AppTheme.appTitle1,),
                    Text('Active Dealers',style: AppTheme.normalText3)
                  ],
                ),
              ),
            ),
            SizedBox(width: screenWidth*0.015,),
            Expanded(child: BoxCard(
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(AppIcons.box),
                  SizedBox(height: screenHeight*0.01,),
                  Text('200',style: AppTheme.appTitle1,),
                  Text('Total Orders placed',style: AppTheme.normalText3,)
                ],
              ),))
          ],
        ),
        SizedBox(height: screenHeight*0.01,),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: BoxCard(
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(AppIcons.chart),
                    SizedBox(height: screenHeight*0.01,),
                    Text('50/200',style: AppTheme.appTitle1,),
                    Text('25%',style: AppTheme.appTitle1,),
                    Text('This Month\'s Goal ',style: AppTheme.normalText3,),
                  ],
                ),
              ),
            ),
            SizedBox(width: screenWidth*0.015,),
            Expanded(child: BoxCard(
              color: Colors.black,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SvgPicture.asset(AppIcons.delivery),
                  SizedBox(height: screenHeight*0.01,),
                  Text('200',style: AppTheme.appTitle1,),
                  Text('Deliveries completed',style: AppTheme.normalText3,)
                ],
              ),))
          ],
        ),
        SizedBox(height: screenHeight*0.01,),
        Row(
          children: [
            Expanded(
              child: BoxCard(
                color: Colors.black,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SvgPicture.asset(AppIcons.alert),
                    SizedBox(height: screenHeight*0.01,),
                    Text('2',style: AppTheme.appTitle1,),
                    Text('Low Stock',style: AppTheme.normalText3,)
                  ],
                ),
              ),
            ),
            SizedBox(width: screenWidth*0.015,),
            Expanded(child: SizedBox())
          ],
        ),
      ],
    );
  }
}
