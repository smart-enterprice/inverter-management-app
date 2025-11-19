import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/media_query/media_query.dart';
import '../../../screen/superAdmin_home_screen.dart';
import '../controller/login_controller.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  bool _isButtonEnabled = false;
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController();
    _passwordController = TextEditingController();

    _emailController.addListener(_validateForm);
    _passwordController.addListener(_validateForm);
  }

  void _validateForm() {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final isEmailValid = RegExp(
      r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
    ).hasMatch(email);
    final isFormValid = isEmailValid && password.length >= 8;
    if (_isButtonEnabled != isFormValid) {
      setState(() {
        _isButtonEnabled = isFormValid;
      });
    }
  }

  void _togglePasswordVisibility() {
    setState(() {
      _obscurePassword = !_obscurePassword;
    });
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });

      try {
        final controller = ref.read(loginControllerProvider);
        final result = await controller.login(
          _emailController.text.trim(),
          _passwordController.text.trim(),
        );

        // Show message from LoginResult
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: result.success ? Colors.green : Colors.red,
            behavior: SnackBarBehavior.floating,
            content: Text(result.message),
            duration: const Duration(seconds: 3),
          ),
        );

        if (result.success) {
          switch (result.role) {
            case 'ROLE_SUPER_ADMIN':
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const SuperAdminHomeScreen()),
              );
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
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
              );
          }
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.06),
              child: Form(
                key: _formKey,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 20,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    border: Border.all(
                      color: CupertinoColors.lightBackgroundGray,
                      width: 1,
                    ),
                  ),
                  padding: EdgeInsets.all(screenWidth * 0.05),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Center(
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.lock_person,
                                size: 40,
                                color: Colors.blue,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              'Welcome Back',
                              style: TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            SizedBox(height: screenHeight * 0.005),
                            Text(
                              'Sign in to continue',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.04),

                      // Email Field
                      Text(
                        'Email',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Enter your email',
                          prefixIcon: Icon(
                            Icons.email_outlined,
                            color: Colors.grey.shade600,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Email is required";
                          }
                          final isEmailValid = RegExp(
                            r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                          ).hasMatch(value);
                          if (!isEmailValid) {
                            return "Enter a valid email address";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.02),

                      // Password Field
                      Text(
                        'Password',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.black87,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: screenHeight * 0.008),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        decoration: InputDecoration(
                          hintText: 'Enter your password',
                          prefixIcon: Icon(
                            Icons.lock_outline,
                            color: Colors.grey.shade600,
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: Colors.grey.shade600,
                            ),
                            onPressed: _togglePasswordVisibility,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: Colors.grey.shade300),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(color: Colors.blue),
                          ),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password is required";
                          }
                          if (value.length < 8) {
                            return "Password must be at least 8 characters";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight * 0.03),

                      // Login Button
                      SizedBox(
                        width: double.infinity,
                        height: screenHeight * 0.06,
                        child: ElevatedButton(
                          onPressed: _isButtonEnabled && !_isLoading
                              ? _handleLogin
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey.shade300,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 2,
                          ),
                          child: _isLoading
                              ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white),
                            ),
                          )
                              : Text(
                            'Login',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: _isButtonEnabled && !_isLoading
                                  ? Colors.white
                                  : Colors.grey.shade500,
                            ),
                          ),
                        ),),
                      SizedBox(height: screenHeight * 0.03),

                      // Forgot Password
                      Center(
                        child: GestureDetector(
                          onTap: () {
                            // Add forgot password functionality
                          },
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}