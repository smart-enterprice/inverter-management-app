import 'package:flutter/material.dart';


class ProductsScreen extends StatelessWidget {
  const ProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Welcome to the Products Screen!',
        style: Theme.of(context).textTheme.displaySmall,
      ),
    );
  }
}
