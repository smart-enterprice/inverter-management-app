import 'package:flutter/material.dart';
import 'package:inverter_management_app/screen/superAdmin_home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../feature/authentication/screen/login_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 3), checkLoginStatus);
  }

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final isLoggedIn = prefs.getBool('is_logged_in') ?? false;
    final role = prefs.getString('user_role');

    if (!isLoggedIn || role == null) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => LoginScreen()));
      return;
    }

    switch (role) {
      case 'ROLE_SUPER_ADMIN':
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  SuperAdminHomeScreen()));
        break;
      case 'ROLE_ADMIN':
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AdminHomeScreen()));
        break;
      case 'ROLE_SALESMAN':
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const SalesmanHomeScreen()));
        break;
      case 'ROLE_ACCOUNT':
        // Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const AccountHomeScreen()));
        break;
      default:
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) =>  LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          SizedBox(height: screenHeight * 0.3), // 30% from top
          Center(
            child: Image.asset(
              'assets/logo/company_name.png',
              width: 150,
              height: 150,
            ),
          ),
        ],
      ),
    );
  }
}
