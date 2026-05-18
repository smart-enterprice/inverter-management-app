import 'package:flutter/material.dart';

import '../role_panels/role_panel.dart';
import 'base_dashboard.dart';


class PackingDashboard extends StatelessWidget {
  const PackingDashboard({super.key});
  @override
  Widget build(BuildContext context) => const BaseDashboard(
    quickAccessPanel: RolePanel(),
  );
}


