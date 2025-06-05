import 'package:flutter/material.dart';

class DealersScreen extends StatelessWidget {
  const DealersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Welcome to the Dealers Screen!',
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}
