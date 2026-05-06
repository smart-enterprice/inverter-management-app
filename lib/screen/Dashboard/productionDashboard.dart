import 'package:inverter_management_app/screen/rolesbasepanel/productionPanal.dart';
import 'package:flutter/material.dart';

import 'base_dashboard.dart';
class ProductionDashboard extends StatelessWidget {
  const ProductionDashboard({super.key});
  @override
  Widget build(BuildContext context) => const BaseDashboard(
    quickAccessPanel: ProductionPanel(),
  );
}
