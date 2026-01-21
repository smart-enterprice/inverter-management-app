import 'package:flutter/material.dart';
import '../core/media_query/media_query.dart';
import '../widgets/data_card.dart';
import '../widgets/info_card.dart';
import 'ControlPanel.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: Screen.h(context) * 0.01),
            const InfoCard(),
            SizedBox(height: Screen.h(context) * 0.01),
            Text('Quick access',
                style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black)),
            SizedBox(height: Screen.h(context) * 0.02),
            ControlPanel(),
            SizedBox(height: Screen.h(context) * 0.02),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Recent Orders',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: Colors.black)),
                // Text('View All', style: TextStyle(fontSize: 16,fontWeight: FontWeight.w500,color: )),
              ],
            ),
            SizedBox(height: Screen.h(context) * 0.01),
            Container(
              width: Screen.w(context) * 1,
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
    );
  }
}
