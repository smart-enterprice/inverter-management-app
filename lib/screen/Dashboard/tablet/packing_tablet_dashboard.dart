import 'package:flutter/material.dart';
import '../../../screen/rolesbasepanel/packingPanel.dart';
import '../dashboard_tablet_view.dart';

class PackingTabletDashboard extends StatelessWidget {
  const PackingTabletDashboard({super.key});
  @override
  Widget build(BuildContext context) => const DashboardTabletView(
    quickAccessPanel: PackingPanel(),
  );
}
