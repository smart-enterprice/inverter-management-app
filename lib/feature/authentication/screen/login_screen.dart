import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
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
    // email is required and must be valid; password >=8 chars
    final isFormValid = isEmailValid && password.length >= 8;
    if (_isButtonEnabled != isFormValid) {
      setState(() {
        _isButtonEnabled = isFormValid;
      });
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
    return Scaffold(
      body: Center(
        child: Padding(
          padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.04),
          child: Form(
            key: _formKey,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(color: CupertinoColors.lightBackgroundGray,width: 2,),
                    borderRadius: BorderRadius.all(Radius.circular(10))
              ),
              child: SizedBox(
                height: screenHeight*0.5,
                child: Padding(
                  padding:  EdgeInsets.symmetric(horizontal:screenWidth*0.02),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Email',style: TextStyle(fontSize: 18,color: Colors.black,fontWeight: FontWeight.w400),),
                      SizedBox(height: screenHeight*0.01,),
                      TextFormField(
                        controller: _emailController,
                        decoration: InputDecoration(
                          labelText: 'Email',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Email required";
                          }
                          final isEmailValid = RegExp(
                            r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$",
                          ).hasMatch(value);
                          if (!isEmailValid) {
                            return "Enter a valid email";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight*0.01,),
                      Text('Password',style: TextStyle(fontSize: 18,color: Colors.black,fontWeight: FontWeight.w400),),
                      SizedBox(height: screenHeight*0.01,),
                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: InputDecoration(labelText: 'Password'),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Password required";
                          }
                          if (value.length < 8) {
                            return "Password must be at least 8 characters";
                          }
                          return null;
                        },
                      ),
                      SizedBox(height: screenHeight*0.05),
                      Center(
                        child: SizedBox(
                          width: screenWidth*0.8,
                          height: screenHeight*0.05,
                          child: ElevatedButton(
                            onPressed: _isButtonEnabled
                                ? () async {
                              if (_formKey.currentState!.validate()) {
                                final controller = ref.read(loginControllerProvider);
                                final result = await controller.login(
                                  _emailController.text.trim(),
                                  _passwordController.text.trim(),
                                );
                                // Show message from LoginResult
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      backgroundColor: result.success ? Colors.green :Colors.red,
                                      content: Text(result.message)),
                                );
                                if (result.success) {
                                  switch (result.role) {
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
                              }
                            }
                                : null,
                            child:Text('Login',style: TextStyle(fontSize: 16,color: _isButtonEnabled?Colors.white:Colors.grey),),
                          ),
                        ),
                      ),
                      SizedBox(height: screenHeight*0.05),
                       Center(child: GestureDetector(onTap: (){}, child:Text('Forget password?',style: TextStyle(color:Colors.blueAccent,fontWeight: FontWeight.bold,fontSize: 16),)))
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
