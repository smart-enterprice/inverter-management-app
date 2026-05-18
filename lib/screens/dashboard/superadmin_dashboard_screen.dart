import 'package:flutter/material.dart';
import 'package:inverter_management_app/screens/dashboard/base_dashboard.dart';
import '../role_panels/role_panel.dart';
import 'package:inverter_management_app/widgets/role_info/info_card.dart';

class SuperadminDashboard extends StatelessWidget {
  const SuperadminDashboard({super.key});

  @override
  Widget build(BuildContext context) => const BaseDashboard(
    quickAccessPanel: RolePanel(),
    statsPanel: InfoCard(),
  );
}