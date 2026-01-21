import 'package:flutter/material.dart';
import 'package:inverter_management_app/screen/superAdminMobileView.dart';
import 'package:inverter_management_app/screen/superAdminTabletView.dart';
import '../../../core/utils/screen_type.dart';


class SuperAdminHomePage extends StatelessWidget {
  const SuperAdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    switch (getScreenType(context)) {
      case ScreenType.tablet:
        return const SuperAdminTabletView();
      case ScreenType.mobile:
        return const SuperAdminMobileView();
    }
  }
}
