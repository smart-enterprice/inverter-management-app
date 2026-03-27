import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/feature/authentication/controller/login_controller.dart';
import 'package:inverter_management_app/feature/authentication/screen/login_page.dart';
import 'package:inverter_management_app/screen/rolebasescreen/salesmanmobileview.dart';
import 'package:inverter_management_app/screen/superAdmin_home_screen.dart';

import '../core/role/app_role.dart';
import '../feature/authentication/screen/login_mobile_view.dart';

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
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
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
      case 'ROLE_SALESMAN':
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const SalesmanMobileView()));
        break;
      case 'ROLE_PRODUCTION':
        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (_) => const SuperAdminHomePage()));
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
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: splashBlue,
      body: FadeTransition(
        opacity: _fadeAnimation,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // ── White circle logo ──
                Container(
                  width: Screen.w(context) * 0.25,   // 👈
                  height: Screen.w(context) * 0.25,  // 👈
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.bolt_rounded,
                    size: Screen.w(context) * 0.13,  // 👈
                    color: splashBlue,
                  ),
                ),

                SizedBox(height: Screen.h(context) * 0.03), // 👈

                // ── Brand name ──
                Text(
                  'Smart Enterprises',
                  style: GoogleFonts.nunito(
                    fontSize: Screen.w(context) * 0.07, // 👈
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.5,
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