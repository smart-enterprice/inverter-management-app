import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:inverter_management_app/screen/rolebasescreen/AccountantMobileView.dart';
import 'package:inverter_management_app/screen/rolebasescreen/deliveryMobileView.dart';
import 'package:inverter_management_app/screen/rolebasescreen/managerMobileView.dart';
import 'package:inverter_management_app/screen/rolebasescreen/packingMobileView.dart';
import 'package:inverter_management_app/screen/rolebasescreen/productionMobileView.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/feature/authentication/controller/login_controller.dart';
import 'package:inverter_management_app/feature/authentication/screen/login_page.dart';
import 'package:inverter_management_app/screen/rolebasescreen/salesmanmobileview.dart';
import 'package:inverter_management_app/screen/superAdmin_home_screen.dart';

import '../core/role/app_role.dart';
import '../feature/authentication/screen/login_mobile_view.dart';
import 'Dashboard/accountantDashboard.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {

  static const Color splashBlue = Color(0xFF4A90E2);

  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.forward();
    _initApp();
  }

  Future<void> _initApp() async {
    final results = await Future.wait([
      ref.read(loginControllerProvider).isTokenActive(),
      Future.delayed(const Duration(milliseconds: 2500)),
    ]);

    final isActive = results[0] as bool;
    if (!context.mounted) return;

    if (!isActive) {
      await ref.read(loginControllerProvider).forceLogout();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginMobileView()),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final role = prefs.getString('user_role');
    ref.read(roleNotifierProvider.notifier).setRole(role);
    if (!context.mounted) return;

    switch (role) {
      case 'ROLE_SUPER_ADMIN':
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const SuperAdminHomePage()));
        break;
      case 'ROLE_ADMIN':
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const SuperAdminHomePage()));
        break;
      case 'ROLE_SALESMAN':
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const SalesmanMobileView()));
        break;
      case 'ROLE_PRODUCTION':
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ProductionMobileView()));
        break;
      case 'ROLE_PACKING':
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const PackingMobileView()));
        break;

    case 'ROLE_MANAGER':
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const ManagerMobileView()));
        break;
      case 'ROLE_ACCOUNTS':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AccountantMobileView()));
        break;
      case 'ROLE_DELIVERY':
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const DeliveryMobileView()));
        break;
      default:
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const LoginMobileView()));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // ✅ white background
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [

                // 🔹 Your app icon (from assets)
                Image.asset(
                  "assets/logo/smart_icon.png",
                  width: Screen.w(context)*0.4,
                  height: Screen.h(context)*0.2,
                ),

                 SizedBox(height: Screen.h(context)*0.02), // Spacing between icon and text

                // 🔹 Company name
                Text(
                  'Smart Enterprises',
                  style: GoogleFonts.nunito(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}