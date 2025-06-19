import 'package:flutter/material.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/screen/sign_up_screen.dart';
import '../core/media_query/media_query.dart';
import 'edit_user_screen.dart';

class UsersScreen extends StatelessWidget {
  const UsersScreen({super.key});
  void _showDeleteDialog(BuildContext context, String userName) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.backgroundColor,
        title: const Text('Delete User',style: TextStyle(color: Colors.black)),
        content: Text('Are you sure you want to delete "$userName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context), // Cancel
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Add your delete logic here
              print('Deleted $userName');
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child:  Text('Delete',style: TextStyle(color: AppTheme.backgroundColor),),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Map<String, String>> users = [
      {'name': 'John Doe', 'email': 'john.doe@example.com', 'phone': '+1234567890', 'role': 'Admin'},
      {'name': 'Jane Smith', 'email': 'jane.smith@example.com', 'phone': '+0987654321', 'role': 'Salesman'},
      {'name': 'Alex Johnson', 'email': 'alex.j@example.com', 'phone': '+1122334455', 'role': 'Production'},
    ];
    return Scaffold(
      appBar: AppBar(
        title: Text('Users', style: AppTheme.appTitle1),
        backgroundColor: AppTheme.backgroundColor,
        centerTitle: true,
        actions: [
        IconButton(onPressed: (){
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddUserScreen()));
        }, icon: Icon(Icons.add_box_rounded,size:30,))
        ],
      ),
      body:  Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                itemCount: users.length,
                itemBuilder: (context, index) {
                  final user = users[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: screenWidth * 0.02),
                    elevation: 2,
                    color: AppTheme.backgroundColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8.0),
                    ),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(screenWidth * 0.04),
                      title: Row(
                        children: [
                          Text(
                            user['name']!,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Spacer(),
                          IconButton(
                            icon: Icon(Icons.delete, color: Colors.red),
                            onPressed: () {
                              _showDeleteDialog(context, user['name']!);
                            },
                          ),

                          SizedBox(
                            width: screenWidth * 0.03,
                          ),
                          IconButton(
                            icon: Icon(Icons.edit, color: Colors.blue),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditUserScreen(
                                    name: user['name']!,
                                    email: user['email']!,
                                    phone: user['phone']!,
                                    role: user['role']!,
                                  ),
                                ),
                              );
                            },
                          ),

                        ],
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: screenWidth * 0.01),
                          Text(
                            'Email: ${user['email']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey, // Standard Flutter color
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.01),
                          Text(
                            'Phone: ${user['phone']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey, // Standard Flutter color
                            ),
                          ),
                          SizedBox(height: screenWidth * 0.01),
                          Text(
                            'Role: ${user['role']}',
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.black, // Standard Flutter color
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
