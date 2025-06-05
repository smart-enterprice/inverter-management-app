import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/widgets/card.dart';

import '../../../screen/home_screen.dart';
import '../widgets/email_controller.dart';
import '../widgets/login_button.dart';
import '../widgets/password_controller.dart';


class AuthenticationScreen extends ConsumerWidget {
   AuthenticationScreen({super.key});
   final TextEditingController _emailController = TextEditingController();
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
                    controller: _emailController,
                  ),
                  SizedBox(
                    height: screenHeight*0.07,
                  ),
                  LoginButton(
                    onTap:(){
                      Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => HomeScreen(),));
                    }
                  )
                ],
              ))
        ),
      ),
    );
  }
}