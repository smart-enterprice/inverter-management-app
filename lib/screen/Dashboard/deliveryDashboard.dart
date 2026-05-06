import 'package:inverter_management_app/screen/rolesbasepanel/devileryPanal.dart';
import 'package:flutter/material.dart';

import 'base_dashboard.dart';

class DeliveryDashboard extends StatelessWidget {
  const DeliveryDashboard({super.key});
  @override
  Widget build(BuildContext context) => const BaseDashboard(
    quickAccessPanel: DeliveryPanel(),
  );
}
