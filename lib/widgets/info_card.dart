import 'package:flutter/material.dart';
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
                  children: [
                    Text('Total Dealers',style: AppTheme.normalText3,),
                    Text('50',style: AppTheme.normalText3,)
                  ],
                ),
              ),
            ),
            SizedBox(width: screenWidth*0.015,),
            Expanded(child: BoxCard(
              color: Colors.black,
              child: Column(
                children: [
                  Text('Total Orders',style: AppTheme.normalText3,),
                  Text('200',style: AppTheme.normalText3,)
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
                  children: [
                    Text('This Month\'s Goal ',style: AppTheme.normalText3,),
                    Padding(
                      padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.04),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('50/200',style: AppTheme.normalText3,),
                          Text('25%',style: AppTheme.normalText3,),
                        ],
                      ),
                    )
                  ],
                ),
              ),
            ),
            SizedBox(width: screenWidth*0.015,),
            Expanded(child: BoxCard(
              color: Colors.black,
              child: Column(
                children: [
                  Text('Ongoing Orders',style: AppTheme.normalText3,),
                  Text('20',style: AppTheme.normalText3,)
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
                  children: [
                    Text('Low Stock Products',style: AppTheme.normalText3,),
                    Text('50',style: AppTheme.normalText3,)
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
