import 'package:inverter_management_app/screen/rolesbasepanel/ControlPanel.dart';
import 'package:inverter_management_app/widgets/rolebaseinfo/info_card.dart';
import 'package:flutter/material.dart';

import 'base_dashboard.dart';
class ManagerDashboard extends StatelessWidget {
  const ManagerDashboard({super.key});
  @override
  Widget build(BuildContext context) => const BaseDashboard(
    quickAccessPanel: ControlPanel(),
    statsPanel: InfoCard(),
  );
}
