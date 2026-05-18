import 'package:flutter/material.dart';
import 'package:inverter_management_app/screens/dashboard/base_dashboard.dart';
import '../role_panels/role_panel.dart';
import 'package:inverter_management_app/widgets/role_info/salesman_info_card.dart';

class SalesManDashboard extends StatelessWidget {
  const SalesManDashboard({super.key});
  @override
  Widget build(BuildContext context) => const BaseDashboard(
    quickAccessPanel: RolePanel(),
    statsPanel: SalesmanInfoCard(),
  );
}
