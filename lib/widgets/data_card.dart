import 'package:flutter/material.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';

class DataCard extends StatelessWidget {
  const DataCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.all(screenWidth * 0.02),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(screenWidth * 0.012),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.shade300,
            spreadRadius: 0.2,
            blurRadius: 5,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left side: Order ID & Dealer
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ID #12345',
                style: AppTheme.normalText3,
              ),
              SizedBox(height: screenHeight * 0.008),
              Text(
                'Dealer: Green Energy Solutions',
                style: AppTheme.smallText1,
              ),
            ],
          ),
          // Right side: Priority
          Container(
            width: screenWidth * 0.2,
            height: screenHeight * 0.028,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                'High',
                style: AppTheme.smallText2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
