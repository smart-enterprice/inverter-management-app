import '../role_panels/role_panel.dart';
import 'package:flutter/material.dart';

import 'base_dashboard.dart';
class ProductionDashboard extends StatelessWidget {
  const ProductionDashboard({super.key});
  @override
  Widget build(BuildContext context) => const BaseDashboard(
    quickAccessPanel: RolePanel(),
  );
}
