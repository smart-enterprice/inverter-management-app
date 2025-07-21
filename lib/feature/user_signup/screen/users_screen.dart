import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/feature/user_signup/controller/user_signUp_controller.dart';
import 'package:inverter_management_app/feature/user_signup/screen/sign_up_screen.dart';
import '../../../core/media_query/media_query.dart';
import '../../../screen/edit_user_screen.dart';

class UsersScreen extends ConsumerWidget {
  const UsersScreen({super.key});

  void _showDeleteDialog(BuildContext context,ref, String userName, String employeeId) {
    final TextEditingController _reasonController = TextEditingController();
    int secondsRemaining = 10;
    bool canDelete = false;
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            // Start countdown
            if (secondsRemaining > 0) {
              Future.delayed(const Duration(seconds: 1), () {
                setState(() {
                  secondsRemaining--;
                  if (secondsRemaining == 0) canDelete = true;
                });
              });
            }

            return AlertDialog(
              backgroundColor: AppTheme.backgroundColor,
              title: const Text('Delete User', style: TextStyle(color: Colors.black)),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Are you sure you want to delete "$userName"?'),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _reasonController,
                    maxLines: 5,
                    decoration: const InputDecoration(
                      hintText: 'Enter reason for deleting',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  if (!canDelete)
                    Text(
                      'Please wait $secondsRemaining seconds...',
                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: canDelete
                      ? () async {
                    final reason = _reasonController.text.trim();
                    if (reason.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Reason is required'),
                          backgroundColor: Colors.red,
                        ),
                      );
                      return;
                    }

                    // Call delete from controller
                    final error = await ref.read(signupControllerProvider.notifier)
                        .deleteUser(employeeId, reason);

                    if (error != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(error), backgroundColor: Colors.red),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
                      );
                      Navigator.pop(context); // Close dialog
                      // Navigator.pop(context); // Go back to previous screen
                    }
                  }
                      : null,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                  child: Text(
                    canDelete ? 'Delete' : 'Wait...',
                    style: TextStyle(color: AppTheme.backgroundColor),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }


  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final employeesAsync = ref.watch(employeeListProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text('Users', style: Theme.of(context).textTheme.bodyLarge),
        backgroundColor: AppTheme.backgroundColor,
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => const AddUserScreen()));
            },
            icon: const Icon(Icons.add_box_rounded, size: 30),
          )
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: employeesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => Center(child: Text('Error: $e')),
          data: (users) {
            final filteredUsers = users
                .where((user) => user.role != 'ROLE_DEALER' && user.role != 'ROLE_SUPER_ADMIN')
                .toList();
            return Column
              (
              children: [
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () async {
                      ref.invalidate(
                          employeeListProvider); // 👈 This will re-call the API
                    },
                    child: ListView.builder(
                      itemCount: filteredUsers.length,
                      itemBuilder: (context, index) {
                        final user = filteredUsers[index];
                        return Card(
                          margin:
                          EdgeInsets.symmetric(vertical: screenWidth * 0.02),
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
                                  user.employeeName,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                                const Spacer(),
                                IconButton(
                                  icon:
                                  const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    _showDeleteDialog(
                                        context,ref,user.employeeName,user.employeeId.toString());
                                  },
                                ),
                                SizedBox(width: screenWidth * 0.03),
                                IconButton(
                                  icon:
                                  const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) =>
                                            EditUserScreen(
                                             user: user,
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
                                  'Email: ${user.employeeEmail}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.grey),
                                ),
                                SizedBox(height: screenWidth * 0.01),
                                _buildInfoRow(
                                  Icons.phone_outlined,
                                  'Phone',
                                  user.employeePhone,
                                ),
                                SizedBox(height: screenWidth * 0.01),
                                Text(
                                  'Role: ${user.role}',
                                  style: const TextStyle(
                                      fontSize: 14, color: Colors.black),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            );
          }
        ),
      ),
    );
  }
}
Widget _buildInfoRow(IconData icon, String label, String value) {
  return Row(
    children: [
      Icon(icon, size: 16, color: Colors.grey[600]),
      SizedBox(width: screenWidth * 0.02),
      Text(
        '$label: ',
        style: TextStyle(
          fontSize: 14,
          color: Colors.grey[600],
          fontWeight: FontWeight.w500,
        ),
      ),
      Expanded(
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
      ),
    ],
  );
}

