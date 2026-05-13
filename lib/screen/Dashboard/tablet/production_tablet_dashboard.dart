import 'package:flutter/material.dart';
import '../../../screen/rolesbasepanel/productionPanal.dart';
import '../dashboard_tablet_view.dart';

class ProductionTabletDashboard extends StatelessWidget {
  const ProductionTabletDashboard({super.key});
  @override
  Widget build(BuildContext context) => const DashboardTabletView(
    quickAccessPanel: ProductionPanel(),
  );
}
