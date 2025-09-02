import 'package:flutter/material.dart';
import '../core/media_query/media_query.dart';
import '../widgets/data_card.dart';
import '../widgets/info_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SingleChildScrollView(
        child: Stack(
          children: [
            Padding(
              padding: EdgeInsets.only(top: screenWidth*0.015),
              child: Container(
                width: double.infinity,
                height: screenHeight*0.2,
                decoration: BoxDecoration(
                  color: Theme.of(context).primaryColor,
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(screenWidth*0.04),bottomRight: Radius.circular(screenWidth*0.04))
                ),
                child: Padding(
                  padding:  EdgeInsets.only(left: screenWidth*0.04),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Dashboard Overview',style: TextStyle(color: Colors.white,fontSize: 24,fontWeight: FontWeight.w500),),
                      Text('Welcome Back John',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.w400))
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding:EdgeInsets.symmetric(horizontal: screenWidth*0.04),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   SizedBox(height: screenHeight * 0.09),
                  const InfoCard(),
                  SizedBox(height: screenHeight * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Recent Orders', style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: Colors.black)),
                      // Text('View All', style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: )),
                    ],
                  ),
                   SizedBox(height: screenHeight* 0.01),
                  Container(
                    width: screenWidth*1,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1), // shadow color
                          blurRadius: 4, // how soft the shadow is
                          offset: const Offset(0, 1), // shadow direction
                        ),
                      ],
                    ),
                    child: Column(
                      children: List.generate(5, (_) => const DataCard()),
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
}
