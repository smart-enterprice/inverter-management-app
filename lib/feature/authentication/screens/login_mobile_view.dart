import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../screens/responsive_shell.dart';
import '../controller/login_controller.dart';

// ── Zoho tokens ───────────────────────────────────────────────────────────────
const _kP     = Color(0xFF185FA5);
const _kBg    = Color(0xFFF7F8FA);
const _kWhite = Colors.white;
const _kBd    = Color(0xFFE5E7EB);
const _kT1    = Color(0xFF111827);
const _kT2    = Color(0xFF374151);
const _kT4    = Color(0xFF9CA3AF);
const _kRed   = Color(0xFFDC2626);
const _kGreen = Color(0xFF0F6E56);

class LoginMobileView extends ConsumerStatefulWidget {
  const LoginMobileView({super.key});
  @override ConsumerState<LoginMobileView> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginMobileView> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override void dispose() { _emailCtrl.dispose(); _passCtrl.dispose(); super.dispose(); }

  void _togglePass() => setState(() => _obscure = !_obscure);

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final result = await ref.read(loginControllerProvider.notifier).login(
          _emailCtrl.text.trim(), _passCtrl.text.trim());
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          duration: const Duration(seconds: 4),
          backgroundColor: result.success ? _kGreen : _kRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          content: Text(result.message, style: const TextStyle(fontWeight: FontWeight.w600))));
      if (result.success) _navigateByRole(result.role);
    } finally { if (mounted) setState(() => _loading = false); }
  }

  void _navigateByRole(String? role) {
    Navigator.pushReplacement(context,
        MaterialPageRoute(builder: (_) => ResponsiveShell.forRole(role)));
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final kb = MediaQuery.viewInsetsOf(context).bottom > 0;

    return Scaffold(
      backgroundColor: _kP,
      body: SafeArea(child: Column(children: [
        // ── Top section — logo + headline ─────────────────────────────────
        if (!kb) ...[
          SizedBox(height: sh * 0.06),
          // Logo
          Container(
              width: (sw * 0.18).clamp(60.0, 84.0),
              height: (sw * 0.18).clamp(60.0, 84.0),
              decoration: BoxDecoration(
                  color: _kWhite.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular((sw * 0.05).clamp(16.0, 24.0)),
                  border: Border.all(color: _kWhite.withValues(alpha: 0.2), width: 0.5)),
              padding: EdgeInsets.all((sw * 0.035).clamp(10.0, 16.0)),
              child: Image.asset('assets/logo/smart_icon.png', fit: BoxFit.contain)),
          SizedBox(height: sh * 0.018),

          // Brand
          Text('SMART ENTERPRISES', style: TextStyle(
              fontSize: (sw * 0.028).clamp(10.0, 13.0),
              letterSpacing: 3.0, color: _kWhite.withValues(alpha: 0.5),
              fontWeight: FontWeight.w600)),
          SizedBox(height: sh * 0.012),

          // Headline
          Text('Welcome Back', style: TextStyle(
              fontSize: (sw * 0.065).clamp(24.0, 32.0),
              fontWeight: FontWeight.w800, color: _kWhite, height: 1.2)),
          SizedBox(height: sh * 0.025),
        ] else
          SizedBox(height: sh * 0.025),

        // ── White card ───────────────────────────────────────────────────
        Expanded(child: Container(
            decoration: BoxDecoration(color: _kWhite,
                borderRadius: BorderRadius.vertical(
                    top: Radius.circular((sw * 0.08).clamp(24.0, 36.0)))),
            padding: EdgeInsets.fromLTRB(sw * 0.06, sh * 0.035, sw * 0.06, sh * 0.03),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Sign In', style: TextStyle(
                  fontSize: (sw * 0.052).clamp(18.0, 26.0),
                  fontWeight: FontWeight.w800, color: _kP)),
              SizedBox(height: sh * 0.006),
              Text('Enter your credentials to access your account', style: TextStyle(
                  fontSize: (sw * 0.033).clamp(11.0, 14.0), color: _kT4)),
              SizedBox(height: sh * 0.035),

              // Form
              Expanded(child: Form(key: _formKey,
                  child: ListView(physics: const BouncingScrollPhysics(), children: [
                    // Email
                    _label(sw, 'Email Address'),
                    SizedBox(height: sh * 0.008),
                    TextFormField(controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        style: TextStyle(fontSize: (sw * 0.038).clamp(13.0, 17.0), color: _kT1),
                        decoration: _deco(sw, sh, 'you@company.com', Icons.email_outlined),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Email is required';
                          if (!RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(v)) return 'Enter a valid email';
                          return null;
                        }),
                    SizedBox(height: sh * 0.024),

                    // Password
                    _label(sw, 'Password'),
                    SizedBox(height: sh * 0.008),
                    TextFormField(controller: _passCtrl, obscureText: _obscure,
                        style: TextStyle(fontSize: (sw * 0.038).clamp(13.0, 17.0), color: _kT1),
                        decoration: _deco(sw, sh, '••••••••', Icons.lock_outline,
                            suffix: IconButton(
                                icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                                    color: _kT4, size: (sw * 0.05).clamp(16.0, 22.0)),
                                onPressed: _togglePass)),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Password is required';
                          if (v.length < 6) return 'At least 6 characters';
                          return null;
                        }),
                    SizedBox(height: sh * 0.04),

                    // Button
                    SizedBox(height: (sh * 0.065).clamp(48.0, 56.0),
                        child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(backgroundColor: _kP,
                                disabledBackgroundColor: _kP.withValues(alpha: 0.6),
                                foregroundColor: _kWhite, elevation: 0,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular((sw * 0.035).clamp(10.0, 16.0)))),
                            child: _loading
                                ? SizedBox(width: (sw * 0.055).clamp(18.0, 24.0),
                                height: (sw * 0.055).clamp(18.0, 24.0),
                                child: const CircularProgressIndicator(strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(_kWhite)))
                                : Text('Sign In', style: TextStyle(
                                fontSize: (sw * 0.042).clamp(14.0, 19.0),
                                fontWeight: FontWeight.w700, letterSpacing: 0.3)))),
                  ]))),
            ]))),
      ])),
    );
  }

  Widget _label(double sw, String text) => Text(text, style: TextStyle(
      fontSize: (sw * 0.033).clamp(11.0, 14.0), fontWeight: FontWeight.w600, color: _kT2));

  InputDecoration _deco(double sw, double sh, String hint, IconData icon, {Widget? suffix}) {
    final r = (sw * 0.03).clamp(10.0, 14.0);
    return InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _kBd, fontSize: (sw * 0.038).clamp(13.0, 17.0)),
        prefixIcon: Icon(icon, color: _kT4, size: (sw * 0.05).clamp(16.0, 22.0)),
        suffixIcon: suffix,
        filled: true, fillColor: _kBg,
        contentPadding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sh * 0.019),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kP, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kRed)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kRed, width: 1.5)));
  }
}