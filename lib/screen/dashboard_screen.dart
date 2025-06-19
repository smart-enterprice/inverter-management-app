import 'package:flutter/material.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import '../core/media_query/media_query.dart';
import '../widgets/data_card.dart';
import '../widgets/info_card.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             SizedBox(height: screenHeight * 0.05),
            const InfoCard(),
            SizedBox(height: screenHeight * 0.01),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders', style: AppTheme.normalText5),
                Text('View All', style: AppTheme.smallText2),
              ],
            ),
             SizedBox(height: screenHeight* 0.01),
            Column(
              children: List.generate(5, (_) => const DataCard()),
            ),
          ],
        ),
      ),
    );
  }
}
