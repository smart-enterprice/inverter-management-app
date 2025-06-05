import 'package:flutter/material.dart';

import '../../../core/media_query/media_query.dart';



class PasswordTextFormField extends StatelessWidget {
  final TextEditingController controller;

  const PasswordTextFormField({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration:  InputDecoration(
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(screenWidth*0.04)),
          borderSide: BorderSide(
              width: 1.5,
              color: Colors.grey),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(screenWidth*0.04)),
          borderSide: BorderSide(
              width: 2,
              color: Theme.of(context).primaryColor),
        ),
        labelText: 'Password',
        hintText: 'Enter your password',
        border: OutlineInputBorder(
        ),
      ),
      keyboardType: TextInputType.emailAddress,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Email is required';
        }
        if (value.length < 6) {
          return 'Enter a valid password with at least 6 characters';
        }
        return null;
      },
    );
  }
}
