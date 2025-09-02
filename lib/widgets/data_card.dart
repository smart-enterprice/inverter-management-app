import 'package:flutter/material.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';

class DataCard extends StatelessWidget {
  const DataCard({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(screenWidth * 0.04),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // ✅ Left: Order Info
          Container(
            padding: EdgeInsets.all(screenWidth*0.025),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.all(Radius.circular(screenWidth*0.03)),
                color: Colors.greenAccent.withValues(alpha: 0.25)
            ),
            child: SvgPicture.asset(
              AppIcons.box,
              colorFilter: ColorFilter.mode(Colors.green, BlendMode.srcIn),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order ID #12345',
                style: TextStyle(fontSize: 14,fontWeight: FontWeight.bold,color: Colors.black), // 16sp, w700
              ),
              SizedBox(height: screenHeight * 0.008),
              Text(
                'Dealer: Green Energy Solutions',
                style: TextStyle(fontSize: 12,fontWeight: FontWeight.w500), // 14sp, w400
              ),
            ],
          ),
          // ✅ Right: Priority Badge
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: screenWidth * 0.03,
              vertical: screenHeight * 0.004,
            ),
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(5),
            ),
            child: Center(
              child: Text(
                'High',
                style: TextStyle(fontSize: 14,color: Colors.white,fontWeight: FontWeight.bold)
                    , // 12sp, w500
              ),
            ),
          ),
        ],
      ),
    );
  }
}
