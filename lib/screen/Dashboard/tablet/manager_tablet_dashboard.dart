import 'package:flutter/material.dart';
import '../../../screen/rolesbasepanel/ControlPanel.dart';
import '../../../widgets/rolebaseinfo/info_card.dart';
import '../dashboard_tablet_view.dart';

class ManagerTabletDashboard extends StatelessWidget {
  const ManagerTabletDashboard({super.key});
  @override
  Widget build(BuildContext context) => const DashboardTabletView(
    statsPanel:       InfoCard(),
    quickAccessPanel: ControlPanel(),
  );
}
