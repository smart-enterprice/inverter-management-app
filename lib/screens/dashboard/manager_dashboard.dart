import '../role_panels/role_panel.dart';
import 'package:inverter_management_app/widgets/role_info/info_card.dart';
import 'package:flutter/material.dart';

import 'base_dashboard.dart';
class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});
  @override
  Widget build(BuildContext context) => const BaseDashboard(
    quickAccessPanel: RolePanel(),
    statsPanel: InfoCard(),
  );
}
