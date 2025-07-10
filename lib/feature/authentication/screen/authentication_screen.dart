import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/widgets/card.dart';

import '../../../screen/home_screen.dart';
import '../controller/login_controller.dart';
import '../widgets/email_controller.dart';
import '../widgets/login_button.dart';
import '../widgets/password_controller.dart';


class AuthenticationScreen extends ConsumerWidget {
   AuthenticationScreen({super.key});
   final TextEditingController _emailController = TextEditingController();
   final TextEditingController _passwordController = TextEditingController();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: Padding(
        padding:  EdgeInsets.symmetric(horizontal: screenWidth*0.04),
        child: Center(
          child: BoxCard(
              height: screenHeight*0.5,
              width: screenWidth*1,
              child: Column(
                children: [
                  Text('Smart Enterprise',style: Theme.of(context).textTheme.displayLarge,),
                  SizedBox(
                    height: screenHeight*0.1,
                  ),
                  EmailTextFormField(
                    controller: _emailController,
                  ),
                  SizedBox(
                    height: screenHeight*0.03,
                  ),
                  PasswordTextFormField(
                    controller: _passwordController,
                  ),
                  SizedBox(
                    height: screenHeight*0.07,
                  ),
                  LoginButton(
                    onTap: () async {
                      final controller = ref.read(loginControllerProvider);
                      final email = _emailController.text.trim();
                      final password = _passwordController.text.trim();
                      final result = await controller.login(email, password);
                      if (result == "Login successful") {
                        // navigate to home screen
                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(builder: (_) => HomeScreen()),
                          );
                          print(result);
                        }
                      } else {
                        // show error message
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text(result)),
                          );
                          print(result);
                        }
                      }
                    },
                  )

                ],
              ))
        ),
      ),
    );
  }
}