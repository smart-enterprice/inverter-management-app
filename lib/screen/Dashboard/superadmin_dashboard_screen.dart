import 'package:flutter/material.dart';
import 'package:inverter_management_app/screen/Dashboard/base_dashboard.dart';
import 'package:inverter_management_app/screen/rolesbasepanel/ControlPanel.dart';
import 'package:inverter_management_app/widgets/rolebaseinfo/info_card.dart';

class SuperadminDashboard extends StatelessWidget {
  const SuperadminDashboard({super.key});

  @override
  Widget build(BuildContext context) => const BaseDashboard(
    quickAccessPanel: ControlPanel(),
    statsPanel: InfoCard(),
  );
}