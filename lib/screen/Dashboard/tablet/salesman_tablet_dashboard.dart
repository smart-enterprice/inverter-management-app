import 'package:flutter/material.dart';
import '../../../screen/rolesbasepanel/salesmanpanel.dart';
import '../../../widgets/rolebaseinfo/salesman_infocard.dart';
import '../dashboard_tablet_view.dart';

class SalesmanTabletDashboard extends StatelessWidget {
  const SalesmanTabletDashboard({super.key});
  @override
  Widget build(BuildContext context) => const DashboardTabletView(
    statsPanel:       SalesmanInfoCard(),
    quickAccessPanel: SalesmanPanel(),
  );
}
