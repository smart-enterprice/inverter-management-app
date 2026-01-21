import 'package:flutter/material.dart';

import '../../../core/utils/screen_type.dart';
import 'login_mobile_view.dart';
import 'order_tablet_view.dart';


class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.of(context).size.width;

    debugPrint('LOGIN WIDTH: $width');
    debugPrint('SCREEN TYPE: ${getScreenType(context)}');
    switch (getScreenType(context)) {
      case ScreenType.tablet:
        return const LoginTabletView();
      case ScreenType.mobile:
        return const LoginMobileView();
    }
  }
}
