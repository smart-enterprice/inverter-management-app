import 'package:flutter/material.dart';


class DeliveryScreen extends StatelessWidget {
  const DeliveryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Welcome to the Delivery Screen!',
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}
