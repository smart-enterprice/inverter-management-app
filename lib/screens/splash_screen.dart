import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/screens/responsive_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:inverter_management_app/feature/authentication/controller/login_controller.dart';
import 'package:inverter_management_app/feature/authentication/screens/login_mobile_view.dart';
import '../core/role/app_role.dart';
import '../core/utils/navigation_service.dart';

const _kP     = Color(0xFF185FA5);
const _kWhite = Colors.white;
const _kRed   = Color(0xFFDC2626);

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});
  @override ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() { super.initState(); _init(); }

  static const _minSplashTime  = Duration(milliseconds: 1000);
  static const _retryInterval  = Duration(seconds: 3);

  Future<void> _init() async {
    final minDelay = Future.delayed(_minSplashTime);
    bool shownOfflineSnack = false;

    while (mounted) {
      bool? isActive;
      bool isOffline = false;
      try {
        isActive = await ref.read(loginControllerProvider.notifier).isTokenActive();
      } catch (e, s) {
        debugPrint('Splash init error: $e\n$s');
        isOffline = true;
      }
      if (!mounted) return;

      if (isOffline) {
        if (!shownOfflineSnack) {
          shownOfflineSnack = true;
          NavigationService.showSnack(
            'Something went wrong. Check your connection.',
            bg: _kRed,
            duration: const Duration(seconds: 4),
          );
        }
        await Future.delayed(_retryInterval);
        continue; // retry
      }

      // Got a definite answer from server. Wait out the min splash time.
      await minDelay;
      if (!mounted) return;

      // Server explicitly rejected token → logout, send to login
      if (isActive == false) {
        await ref.read(loginControllerProvider.notifier).forceLogout();
        if (!mounted) return;
        _goTo(const LoginMobileView());
        return;
      }

      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      if (role != null && role.isNotEmpty) {
        ref.read(roleNotifierProvider.notifier).setRole(role);
        _goTo(ResponsiveShell.forRole(role));
      } else {
        _goTo(const LoginMobileView());
      }
      return;
    }
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
      backgroundColor: _kP,
      body: SafeArea(
        child: Stack(children: [
          // Centered logo + brand
          Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: (sw * 0.32).clamp(108.0, 156.0),
              height: (sw * 0.32).clamp(108.0, 156.0),
              decoration: BoxDecoration(
                color: _kWhite,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.12),
                    blurRadius: 24,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: EdgeInsets.all((sw * 0.05).clamp(16.0, 26.0)),
              child: Image.asset(
                'assets/logo/smart_icon.png',
                fit: BoxFit.contain,
              ),
            ),
            SizedBox(height: sh * 0.035),
            Text('Smart Enterprises', style: TextStyle(
              fontSize: (sw * 0.062).clamp(22.0, 30.0),
              fontWeight: FontWeight.w800,
              color: _kWhite,
              letterSpacing: -0.4,
            )),
            SizedBox(height: sh * 0.008),
            Text('INVERTER MANAGEMENT', style: TextStyle(
              fontSize: (sw * 0.03).clamp(10.0, 13.0),
              color: _kWhite.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
              letterSpacing: 2.0,
            )),
          ])),

          // Animated dots loader at bottom
          Positioned(
            left: 0, right: 0, bottom: sh * 0.06,
            child: const Center(child: _DotsLoader()),
          ),
        ]),
      ),
    );
  }
}

// ── Three pulsing dots loader ────────────────────────────────────────────────
class _DotsLoader extends StatefulWidget {
  const _DotsLoader();
  @override
  State<_DotsLoader> createState() => _DotsLoaderState();
}

class _DotsLoaderState extends State<_DotsLoader>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(mainAxisSize: MainAxisSize.min, children: List.generate(3, (i) {
          final t = (_ctrl.value - i * 0.15) % 1.0;
          final scale = 0.6 + 0.4 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
          final opacity = 0.4 + 0.6 * (1 - (t - 0.5).abs() * 2).clamp(0.0, 1.0);
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: 9, height: 9,
                decoration: BoxDecoration(
                  color: _kWhite.withValues(alpha: opacity),
                  shape: BoxShape.circle,
                ),
              ),
            ),
          );
        }));
      },
    );
  }
}
