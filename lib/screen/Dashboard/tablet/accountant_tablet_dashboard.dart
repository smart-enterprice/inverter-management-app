import 'package:flutter/material.dart';
import '../../../screen/rolesbasepanel/accountantPanel.dart';
import '../dashboard_tablet_view.dart';

class AccountantTabletDashboard extends StatelessWidget {
  const AccountantTabletDashboard({super.key});
  @override
  Widget build(BuildContext context) => const DashboardTabletView(
    quickAccessPanel: AccountantPanel(),
  );
}
