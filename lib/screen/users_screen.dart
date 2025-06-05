import 'package:flutter/material.dart';
import 'package:inverter_management_app/core/theme/theme.dart';

import '../core/media_query/media_query.dart';
import '../widgets/add_button.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Users', style: AppTheme.appTitle1),
        backgroundColor: AppTheme.backgroundColor,
        centerTitle: true,
      ),
      body:  Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Manage users',style: AppTheme.appTitle1,),
                AddButton(
                  icon: Icons.add,
                  text: 'Add User',
                  onTap:(){}
                )
              ],
            )
          ],
        ),
      ),
    );
  }
}
