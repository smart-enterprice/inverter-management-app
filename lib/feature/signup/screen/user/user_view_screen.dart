// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/flutter_svg.dart';
// import 'package:inverter_management_app/core/const/icons.dart';
// import 'package:inverter_management_app/feature/signup/screen/user/edit_user_screen.dart';
// import '../../../../core/media_query/media_query.dart';
// import '../../../../core/theme/theme.dart';
// import '../../../../model/user_model.dart';
// import '../../controller/signUp_controller.dart';
//
//
// class UserViewScreen extends ConsumerWidget {
//   const UserViewScreen({super.key, required this.user});
//   final UserModel user;
//   @override
//   Widget build(BuildContext context,WidgetRef ref) {
//     return Scaffold(
//          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//          body: SafeArea(
//              child: Padding(
//                padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04,vertical: screenHeight*0.01,),
//                child: Column(
//                            mainAxisAlignment: MainAxisAlignment.start,
//                  children: [
//                    Row(
//                      children: [
//                    IconButton(
//                        onPressed: () {
//                          Navigator.pop(context);
//                        },
//                        icon: SvgPicture.asset(
//                          width: screenWidth*0.08,
//                          // height: 30,
//                          AppIcons.back_Arrow,colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),)),
//                        Spacer(),
//                        IconButton(
//                            onPressed: () {
//                              Navigator.push(context, MaterialPageRoute(builder: (context)=>EditUserScreen(user: user)));
//                            },
//                            icon: SvgPicture.asset(
//                              width: screenWidth*0.06,
//                              // height: 30,
//                              AppIcons.edit,colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),)),
//                        SizedBox(width: screenWidth*0.05,),
//                        IconButton(
//                            onPressed: () {
//                              _showDeleteDialog(context, ref, user.employeeName, user.employeeId.toString());
//                            },
//                            icon: SvgPicture.asset(
//                              width: screenWidth*0.06,
//                              // height: 30,
//                              AppIcons.delete,colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),)),
//                      ],
//                    ),
//                    Expanded(
//                      child:SingleChildScrollView(
//                        child: Container(
//                          height: screenHeight*0.9,
//                          padding: EdgeInsets.all(screenWidth * 0.05),
//                          decoration: BoxDecoration(
//                            color: Theme.of(context).cardColor,
//                            borderRadius: BorderRadius.all(Radius.circular(screenWidth * 0.07)),
//                          ),
//                          child: Column(
//                            crossAxisAlignment: CrossAxisAlignment.start,
//                            children: [
//                              Center(
//                                child: CircleAvatar(
//                                  radius: screenWidth * 0.32,
//                                  backgroundImage: user.photo.isNotEmpty
//                                      ? NetworkImage(user.photo)
//                                      : AssetImage('assets/images/profile.jpg') as ImageProvider,
//                                ),
//                              ),
//                              SizedBox(height: screenWidth * 0.05),
//                              Text('Name: ${user.employeeName}', style: Theme.of(context).textTheme.bodyLarge),
//                              SizedBox(height: screenWidth * 0.02),
//                              Text('Email: ${user.employeeEmail}', style: Theme.of(context).textTheme.bodyLarge),
//                              SizedBox(height: screenWidth * 0.02),
//                              Text('Phone: ${user.employeePhone}', style: Theme.of(context).textTheme.bodyLarge),
//                              SizedBox(height: screenWidth * 0.02),
//                              Text('Role: ${user.role}', style: Theme.of(context).textTheme.bodyLarge),
//                              SizedBox(height: screenWidth * 0.02),
//                              Text('Address: ${user.address}', style: Theme.of(context).textTheme.bodyLarge),
//                              // If you want to show employeeId and password too (optional)
//                              Text('ID: ${user.employeeId ?? "N/A"}',style: Theme.of(context).textTheme.bodyLarge),
//                              // Text('Password: ${user.password}',style: Theme.of(context).textTheme.bodyLarge), // Avoid showing passwords in UI
//                            ],
//                          ),
//                        ),
//                      )
//
//                    )
//                  ],
//                         ),
//              )),
//     );
//   }
//
//
//   void _showDeleteDialog(BuildContext context,ref, String userName, String employeeId) {
//     final TextEditingController _reasonController = TextEditingController();
//     int secondsRemaining = 10;
//     bool canDelete = false;
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (context) {
//         return StatefulBuilder(
//           builder: (context, setState) {
//             // Start countdown
//             if (secondsRemaining > 0) {
//               Future.delayed(const Duration(seconds: 1), () {
//                 setState(() {
//                   secondsRemaining--;
//                   if (secondsRemaining == 0) canDelete = true;
//                 });
//               });
//             }
//
//             return AlertDialog(
//               backgroundColor: Theme.of(context).focusColor,
//               title:  Text('Delete User', style: Theme.of(context).textTheme.labelSmall),
//               content: Column(
//                 mainAxisSize: MainAxisSize.min,
//                 children: [
//                   Text('Are you sure you want to delete "$userName"?',style:Theme.of(context).textTheme.labelSmall ,),
//                   const SizedBox(height: 16),
//                   TextFormField(
//                     controller: _reasonController,
//                     maxLines: 5,
//                     decoration: const InputDecoration(
//                       hintText: 'Enter reason for deleting',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                   const SizedBox(height: 12),
//                   if (!canDelete)
//                     Text(
//                       'Please wait $secondsRemaining seconds...',
//                       style: const TextStyle(color: Colors.grey),
//                     ),
//                 ],
//               ),
//               actions: [
//                 TextButton(
//                   onPressed: () => Navigator.pop(context),
//                   child: const Text('Cancel'),
//                 ),
//                 ElevatedButton(
//                   onPressed: canDelete
//                       ? () async {
//                     final reason = _reasonController.text.trim();
//                     if (reason.isEmpty) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(
//                           content: Text('Reason is required'),
//                           backgroundColor: Colors.red,
//                         ),
//                       );
//                       return;
//                     }
//
//                     // Call delete from controller
//                     final error = await ref.read(signupControllerProvider.notifier)
//                         .deleteUser(employeeId, reason);
//
//                     if (error != null) {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         SnackBar(content: Text(error), backgroundColor: Colors.red),
//                       );
//                     } else {
//                       ScaffoldMessenger.of(context).showSnackBar(
//                         const SnackBar(content: Text('User deleted successfully'), backgroundColor: Colors.green),
//                       );
//                       Navigator.pop(context); // Close dialog
//                       Navigator.pop(context); // Go back to previous screen
//                     }
//                   }
//                       : null,
//                   style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//                   child: Text(
//                     canDelete ? 'Delete' : 'Wait...',
//                     style: TextStyle(color: AppTheme.backgroundColor),
//                   ),
//                 ),
//               ],
//             );
//           },
//         );
//       },
//     );
//   }
//
// }
