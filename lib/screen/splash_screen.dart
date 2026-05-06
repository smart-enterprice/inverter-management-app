import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/screen/responsive_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inverter_management_app/feature/authentication/controller/login_controller.dart';
import 'package:inverter_management_app/feature/authentication/screen/login_mobile_view.dart';
import '../core/role/app_role.dart';

const _kP    = Color(0xFF185FA5);
const _kT1   = Color(0xFF111827);
const _kT4   = Color(0xFF9CA3AF);
const _kBd   = Color(0xFFE5E7EB);
const _kBg   = Color(0xFFF7F8FA);
const _kWhite = Colors.white;
const _kRed  = Color(0xFFDC2626);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _hasError = false;
  String _errorMsg = '';

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    if (mounted) setState(() { _hasError = false; _errorMsg = ''; });
    try {
      final results = await Future.wait([
        ref.read(loginControllerProvider.notifier).isTokenActive(),
        Future.delayed(const Duration(milliseconds: 2200)),
      ]);
      final isActive = results[0] as bool;
      if (!mounted) return;
      if (!isActive) {
        await ref.read(loginControllerProvider.notifier).forceLogout();
        if (!mounted) return;
        _goTo(const LoginMobileView());
        return;
      }
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      ref.read(roleNotifierProvider.notifier).setRole(role);
      if (!mounted) return;
      _navigateByRole(role);
    } catch (_) {
      if (mounted) {
        setState(() {
        _hasError = true;
        _errorMsg = 'Could not connect. Please check your internet connection.';
      });
      }
    }
  }

  void _navigateByRole(String? role) {
    _goTo(ResponsiveShell.forRole(role));
  }

  void _goTo(Widget page) {
    if (!mounted) return;
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => page));
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: _kWhite,
      body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Logo
        Container(
            width: (sw * 0.22).clamp(72.0, 100.0),
            height: (sw * 0.22).clamp(72.0, 100.0),
            decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular((sw * 0.06).clamp(18.0, 28.0)),
                border: Border.all(color: _kBd, width: 0.5)),
            padding: EdgeInsets.all((sw * 0.04).clamp(12.0, 20.0)),
            child: Image.asset('assets/logo/smart_icon.png', fit: BoxFit.contain)),

        SizedBox(height: sh * 0.025),

        // Brand name
        Text('Smart Enterprises', style: TextStyle(
            fontSize: (sw * 0.055).clamp(20.0, 28.0),
            fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.5)),

        SizedBox(height: sh * 0.008),

        Text('Inverter Management', style: TextStyle(
            fontSize: (sw * 0.032).clamp(11.0, 14.0),
            color: _kT4, fontWeight: FontWeight.w500, letterSpacing: 0.5)),

        SizedBox(height: sh * 0.06),

        // Error or loading
        if (_hasError) ...[
          Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
              child: Container(
                  padding: EdgeInsets.all(sw * 0.04),
                  decoration: BoxDecoration(color: const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFFFECACA), width: 0.5)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Icon(Icons.wifi_off_rounded, size: (sw * 0.045).clamp(15.0, 20.0), color: _kRed),
                    SizedBox(width: sw * 0.03),
                    Expanded(child: Text(_errorMsg, style: TextStyle(
                        fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kRed, height: 1.5))),
                  ]))),
          SizedBox(height: sh * 0.025),
          ElevatedButton.icon(
              onPressed: _init,
              icon: Icon(Icons.refresh_rounded, size: (sw * 0.045).clamp(15.0, 20.0)),
              label: Text('Try Again', style: TextStyle(
                  fontSize: (sw * 0.036).clamp(12.0, 15.0), fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
                  padding: EdgeInsets.symmetric(
                      horizontal: (sw * 0.07).clamp(24.0, 32.0),
                      vertical: (sw * 0.03).clamp(10.0, 14.0)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0)),
          SizedBox(height: sh * 0.015),
          GestureDetector(onTap: () => _goTo(const LoginMobileView()),
              child: Text('Go to Login', style: TextStyle(
                  fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4, fontWeight: FontWeight.w500))),
        ] else
          SizedBox(width: 22, height: 22,
              child: CircularProgressIndicator(strokeWidth: 2.5, color: _kBd)),
      ])),
    );
  }
}