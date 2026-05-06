import 'package:flutter/material.dart';
import 'package:inverter_management_app/screen/Dashboard/base_dashboard.dart';
import 'package:inverter_management_app/screen/rolesbasepanel/salesmanpanel.dart';
import 'package:inverter_management_app/widgets/rolebaseinfo/salesman_infocard.dart';

class SalesManDashboard extends StatelessWidget {
  const SalesManDashboard({super.key});
  @override
  Widget build(BuildContext context) => const BaseDashboard(
    quickAccessPanel: SalesmanPanel(),
    statsPanel: SalesmanInfoCard(),
  );
}
