import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/screen/rolebasescreen/managerMobileView.dart';
import '../../../core/media_query/media_query.dart';
import '../../../screen/rolebasescreen/AccountantMobileView.dart';
import '../../../screen/rolebasescreen/deliveryMobileView.dart';
import '../../../screen/rolebasescreen/packingMobileView.dart';
import '../../../screen/rolebasescreen/productionMobileView.dart';
import '../../../screen/rolebasescreen/salesmanmobileview.dart';
import '../../../screen/superAdmin_home_screen.dart';
import '../controller/login_controller.dart';

const _royalBlue = Color(0xFF1A3FBF);
const _royalBlueDark = Color(0xFF162FA0);
const _bgField = Color(0xFFF1F5F9);
const _borderField = Color(0xFFE2E8F0);
const _textDark = Color(0xFF1E293B);
const _textMid = Color(0xFF334155);
const _textMuted = Color(0xFF94A3B8);
const _placeholder = Color(0xFFCBD5E1);

class LoginMobileView extends ConsumerStatefulWidget {
  const LoginMobileView({super.key});

  @override
  ConsumerState<LoginMobileView> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginMobileView> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final controller = ref.read(loginControllerProvider);
        final result = await controller.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: result.success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            content: Text(result.message),
            duration: const Duration(seconds: 3),
          ),
        );
        if (result.success) _navigateToRoleScreen(result.role);
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  void _navigateToRoleScreen(String? role) {
    Widget targetScreen;
    switch (role) {
      case 'ROLE_SUPER_ADMIN':
      case 'ROLE_ADMIN':
        targetScreen = const SuperAdminHomePage();
        break;
      case 'ROLE_SALESMAN':
        targetScreen = const SalesmanMobileView();
        break;
      case 'ROLE_MANAGER':
        targetScreen = const ManagerMobileView();
        break;
      case 'ROLE_PACKING':
        targetScreen = const PackingMobileView();
        break;
      case 'ROLE_ACCOUNTS':
        targetScreen = const AccountantMobileView();
        break;
      case 'ROLE_PRODUCTION':
        targetScreen = const ProductionMobileView();
        break;
      case 'ROLE_DELIVERY':
        targetScreen = const DeliveryMobileView();
        break;
      default:
        targetScreen = const LoginMobileView();
    }
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => targetScreen),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final isKeyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return Scaffold(
      backgroundColor: _royalBlue,
      body: SafeArea(
        child: Stack(
          children: [
            // ── Grid overlay ──────────────────────────────────────────
            // Positioned.fill(
            //   child: CustomPaint(painter: _GridPainter()),
            // ),

            // ── Soft glow orbs ────────────────────────────────────────
            Positioned(
              top: -sh * 0.08,
              left: -sw * 0.15,
              child: _Orb(size: sw * 0.65),
            ),
            Positioned(
              top: sh * 0.04,
              right: -sw * 0.1,
              child: _Orb(size: sw * 0.5),
            ),

            // ── Main content ──────────────────────────────────────────
            Column(
              children: [
                // Top: logo + headline
                if (!isKeyboardVisible) ...[
                  SizedBox(height: sh * 0.07),
                  _buildTopSection(sw, sh),
                ] else ...[
                  SizedBox(height: sh * 0.03),
                ],

                // Bottom: white card
                Expanded(
                  child: _buildCard(sw, sh),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Top logo + headline ─────────────────────────────────────────────────────

  Widget _buildTopSection(double sw, double sh) {
    return Column(
      children: [
        // Logo box
        Container(
          width: sw * 0.2,
          height: sw * 0.2,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha:0.05),
            borderRadius: BorderRadius.circular(sw * 0.055),
            border: Border.all(
              color: Colors.white.withValues(alpha: .25),
              width: 1.5,
            ),
          ),
          padding: EdgeInsets.all(sw * 0.038),
          child: Image.asset(
            'assets/logo/smart_icon.png',
            fit: BoxFit.contain,
            // color: Colors.white,
          ),
        ),
        SizedBox(height: sh * 0.018),

        // Brand name
        Text(
          'Smart enterprises',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: sw * 0.03,
            letterSpacing: 3.5,
            color: Colors.white.withValues(alpha:0.6),
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: sh * 0.012),

        // Headline
        Text(
          'Welcome Back',
          style: TextStyle(
            fontFamily: 'Sora',
            fontSize: sw * 0.072,
            fontWeight: FontWeight.w700,
            color: Colors.white,
            height: 1.2,
          ),
        ),
        SizedBox(height: sh * 0.02),
      ],
    );
  }

  // ── White card ──────────────────────────────────────────────────────────────

  Widget _buildCard(double sw, double sh) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(sw * 0.064, sh * 0.038, sw * 0.064, sh * 0.03),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sign In',
            style: TextStyle(
              fontFamily: 'Sora',
              fontSize: sw * 0.055,
              fontWeight: FontWeight.w700,
              color: _royalBlue,
            ),
          ),
          SizedBox(height: sh * 0.006),
          Text(
            'Enter your credentials to access your account',
            style: TextStyle(
              fontSize: sw * 0.033,
              color: _textMuted,
            ),
          ),
          SizedBox(height: sh * 0.036),

          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const BouncingScrollPhysics(),
                children: [
                  _buildEmailField(sw, sh),
                  SizedBox(height: sh * 0.024),
                  _buildPasswordField(sw, sh),
                  SizedBox(height: sh * 0.04),
                  _buildLoginButton(sw, sh),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Email field ─────────────────────────────────────────────────────────────

  Widget _buildEmailField(double sw, double sh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Email Address', sw),
        SizedBox(height: sh * 0.009),
        TextFormField(
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
          style: TextStyle(fontSize: sw * 0.038, color: _textDark),
          decoration: _inputDecoration(
            sw: sw,
            sh: sh,
            hint: 'you@company.com',
            prefixIcon: Icons.email_outlined,
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Email is required';
            final valid = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$").hasMatch(value);
            if (!valid) return 'Enter a valid email address';
            return null;
          },
        ),
      ],
    );
  }

  // ── Password field ──────────────────────────────────────────────────────────

  Widget _buildPasswordField(double sw, double sh) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _fieldLabel('Password', sw),
        SizedBox(height: sh * 0.009),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          style: TextStyle(fontSize: sw * 0.038, color: _textDark),
          decoration: _inputDecoration(
            sw: sw,
            sh: sh,
            hint: '••••••••',
            prefixIcon: Icons.lock_outline,
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: _textMuted,
                size: sw * 0.05,
              ),
              onPressed: _togglePasswordVisibility,
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) return 'Password is required';
            if (value.length < 8) return 'Password must be at least 8 characters';
            return null;
          },
        ),
      ],
    );
  }

  // ── Login button ────────────────────────────────────────────────────────────

  Widget _buildLoginButton(double sw, double sh) {
    return SizedBox(
      height: sh * 0.065,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
        style: ElevatedButton.styleFrom(
          backgroundColor: _royalBlue,
          disabledBackgroundColor: _royalBlue.withValues(alpha:0.6),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        child: _isLoading
            ? SizedBox(
          width: sw * 0.055,
          height: sw * 0.055,
          child: const CircularProgressIndicator(
            strokeWidth: 2.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Text(
          'Sign In',
          style: TextStyle(
            fontSize: sw * 0.042,
            fontWeight: FontWeight.w600,
            color: Colors.white,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  Widget _fieldLabel(String text, double sw) {
    return Text(
      text,
      style: TextStyle(
        fontSize: sw * 0.033,
        fontWeight: FontWeight.w600,
        color: _textMid,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required double sw,
    required double sh,
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _placeholder, fontSize: sw * 0.038),
      prefixIcon: Icon(prefixIcon, color: _textMuted, size: sw * 0.05),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: _bgField,
      contentPadding: EdgeInsets.symmetric(
        horizontal: sw * 0.04,
        vertical: sh * 0.019,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderField),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _borderField, width: 1.5),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _royalBlue, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
      ),
    );
  }
}

// ── Grid background painter ──────────────────────────────────────────────────

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha:0.06)
      ..strokeWidth = 1;
    const step = 32.0;
    for (double x = 0; x <= size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y <= size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ── Soft glow orb widget ─────────────────────────────────────────────────────

class _Orb extends StatelessWidget {
  final double size;
  const _Orb({required this.size});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: .09),
            Colors.transparent,
          ],
        ),
      ),
    );
  }
}