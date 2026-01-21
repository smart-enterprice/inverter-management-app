import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/widgets/single_infocard.dart';
import '../feature/signup/controller/signUp_controller.dart';

class InfoCard extends ConsumerWidget {
  const InfoCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dealersAsync = ref.watch(dealerListProvider);
    final dealerCount = dealersAsync.asData?.value.length ?? 0;
    return Column(
      children: [
        SingleInfoCard(
          iconBackground: Colors.lightBlueAccent.withValues(alpha: 0.25),
          icon: AppIcons.shop,
          title: "Dealers",
          value: dealerCount.toString(),
          iconColor: Theme.of(context).primaryColor,
        ),
        SizedBox(height: Screen.h(context) * 0.01),
        SingleInfoCard(
          iconBackground: Colors.greenAccent.withValues(alpha: 0.25),
          icon: AppIcons.box,
          title: "Total Orders placed",
          value: "200",
          iconColor: Colors.green,
        ),
        SizedBox(height: Screen.h(context) * 0.01),
        SingleInfoCard(
          iconBackground: Colors.purpleAccent.withValues(alpha: 0.25),
          icon: AppIcons.chart,
          title: "This Month's Goal",
          value: "50/200 (25%)",
          iconColor: Colors.purple,
        ),
        SizedBox(height: Screen.h(context) * 0.01),
        SingleInfoCard(
          iconBackground: Colors.orangeAccent.withValues(alpha: 0.25),
          icon: AppIcons.delivery,
          title: "Deliveries completed",
          value: "200",
          iconColor: Colors.orange,
        ),
        SizedBox(height: Screen.h(context) * 0.01),
        SingleInfoCard(
          iconBackground: Colors.redAccent.withValues(alpha: 0.25),
          icon: AppIcons.alert,
          title: "Low Stock",
          value: "2",
          iconColor: Colors.red,
        ),
      ],
    );
  }
}
