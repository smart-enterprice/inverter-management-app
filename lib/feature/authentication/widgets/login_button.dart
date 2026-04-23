import 'package:flutter/material.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';

class LoginButton extends StatelessWidget {
  const LoginButton({super.key,required this.onTap});
final void Function()? onTap;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: Screen.h(context)*0.05,
        decoration: BoxDecoration(
          color: Theme.of(context).primaryColor,
          borderRadius: BorderRadius.circular(Screen.w(context)*0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.shade100,
              blurRadius: 5,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(child: Text('Login',style: Theme.of(context).textTheme.labelLarge,)),
      ),
    );
  }
}
