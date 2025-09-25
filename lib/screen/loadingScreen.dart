import 'package:flutter/material.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';

class GlobalLoader extends StatelessWidget {
  const GlobalLoader({super.key});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      child: Center(
        child: Image.asset(
          'assets/gif/loading.gif',
          width: screenWidth*0.15,
          height: screenHeight*0.15,
        ),
      ),
    );
  }
}
