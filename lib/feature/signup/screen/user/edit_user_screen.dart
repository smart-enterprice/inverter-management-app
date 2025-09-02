// import 'package:flutter/material.dart';
// import 'package:flutter/services.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:image_picker/image_picker.dart';
// import 'dart:io';
// import '../../../../core/const/icons.dart';
// import '../../../../core/media_query/media_query.dart';
// import '../../../../core/theme/theme.dart';
// import '../../controller/signUp_controller.dart';
// import '../../../../model/user_model.dart';
//
// class EditUserScreen extends ConsumerStatefulWidget {
//   final UserModel user;
//
//   const EditUserScreen({
//     super.key,
//     required this.user,
//   });
//
//   @override
//   ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
// }
//
// class _EditUserScreenState extends ConsumerState<EditUserScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _nameController;
//   late TextEditingController _emailController;
//   late TextEditingController _phoneController;
//   late TextEditingController _addressController;
//
//   String? _selectedRole;
//   File? _selectedImage;
//   final ImagePicker _picker = ImagePicker();
//
//   final List<String> _roles = [
//     'ROLE_ADMIN',
//     'ROLE_SALESMAN',
//     'ROLE_PRODUCTION',
//     'ROLE_PACKING',
//     'ROLE_ACCOUNTS',
//     'ROLE_DELIVERY',
//   ];
//
//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.user.employeeName);
//     _emailController = TextEditingController(text: widget.user.employeeEmail);
//     _phoneController =
//         TextEditingController(text: widget.user.employeePhone.toString());
//     _addressController = TextEditingController(text: widget.user.address);
//     _selectedRole = widget.user.role;
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _phoneController.dispose();
//     _addressController.dispose();
//     super.dispose();
//   }
//
//   Future<void> _pickImage(ImageSource source) async {
//     try {
//       final XFile? pickedFile = await _picker.pickImage(
//         source: source,
//         maxWidth: 512,
//         maxHeight: 512,
//         imageQuality: 85,
//       );
//       if (pickedFile != null) {
//         setState(() {
//           _selectedImage = File(pickedFile.path);
//         });
//       }
//     } catch (e) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//             content: Text('Error picking image: ${e.toString()}'),
//             backgroundColor: Colors.red),
//       );
//     }
//   }
//
//   void _removeImage() {
//     setState(() {
//       _selectedImage = null;
//     });
//   }
//
//   void _showImagePickerDialog() {
//     showDialog(
//       context: context,
//       builder: (BuildContext context) {
//         return AlertDialog(
//           shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(screenWidth * 0.04)),
//           title: const Text('Select Photo'),
//           content: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               ListTile(
//                 leading: const Icon(Icons.camera_alt, color: Colors.blue),
//                 title: const Text('Camera'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _pickImage(ImageSource.camera);
//                 },
//               ),
//               ListTile(
//                 leading: const Icon(Icons.photo_library, color: Colors.green),
//                 title: const Text('Gallery'),
//                 onTap: () {
//                   Navigator.pop(context);
//                   _pickImage(ImageSource.gallery);
//                 },
//               ),
//               if (_selectedImage != null)
//                 ListTile(
//                   leading: const Icon(Icons.delete, color: Colors.red),
//                   title: const Text('Remove Photo'),
//                   onTap: () {
//                     Navigator.pop(context);
//                     _removeImage();
//                   },
//                 ),
//             ],
//           ),
//         );
//       },
//     );
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: _buildAppBar(),
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//         child: Form(
//           key: _formKey,
//           child: SingleChildScrollView(
//             child: Column(
//               children: [
//                 _buildProfileImageSection(),
//                 _buildInputField(
//                     label: 'Name',
//                     hint: 'Enter full name',
//                     controller: _nameController),
//                 _buildInputField(
//                     label: 'Email',
//                     hint: 'Enter email address',
//                     controller: _emailController,
//                     keyboardType: TextInputType.emailAddress),
//                 _buildInputField(
//                     label: 'Phone',
//                     hint: 'Enter phone number',
//                     controller: _phoneController,
//                     keyboardType: TextInputType.phone,
//                     digitsOnly: true),
//                 _buildInputField(
//                     label: 'Address',
//                     hint: 'Enter address',
//                     controller: _addressController,
//                     maxLines: 3),
//                 _buildRoleDropdown(),
//                 SizedBox(height: screenHeight * 0.03),
//                 _buildSubmitButton(_handleSubmit),
//                 SizedBox(height: screenHeight * 0.02),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSubmitButton(onTap) {
//     return SizedBox(
//       width: screenWidth * 0.5,
//       height: screenHeight * 0.06,
//       child: ElevatedButton(
//         onPressed: onTap,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Theme.of(context).primaryColor,
//         ),
//         child: Text(
//           'Submit',
//           style: Theme.of(context)
//               .textTheme
//               .labelSmall
//               ?.copyWith(fontWeight: FontWeight.w500),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildProfileImageSection() {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
//       child: Row(
//         children: [
//           GestureDetector(
//             onTap: _showImagePickerDialog,
//             child: Stack(
//               children: [
//                 CircleAvatar(
//                   radius: screenWidth * 0.08,
//                   backgroundImage: _selectedImage != null
//                       ? FileImage(_selectedImage!)
//                       : (widget.user.photo.isNotEmpty
//                               ? NetworkImage(widget.user.photo)
//                               : const AssetImage('assets/images/profile.jpg'))
//                           as ImageProvider,
//                 ),
//                 Positioned(
//                   bottom: 0,
//                   right: 0,
//                   child: Container(
//                     padding: EdgeInsets.all(screenWidth * 0.02),
//                     decoration: BoxDecoration(
//                       color: AppTheme.primaryColor,
//                       shape: BoxShape.circle,
//                       border: Border.all(color: Colors.white, width: 2),
//                     ),
//                     child: Icon(Icons.camera_alt,
//                         color: Colors.white, size: screenWidth * 0.04),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//           SizedBox(width: screenWidth * 0.04),
//           Expanded(
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 Text('Profile Image',
//                     style: TextStyle(
//                         fontSize: screenWidth * 0.04,
//                         fontWeight: FontWeight.w600,
//                         color: Colors.black87)),
//                 SizedBox(height: screenHeight * 0.005),
//                 Text(
//                   _selectedImage != null
//                       ? 'Tap to change photo'
//                       : 'Tap to add photo',
//                   style: TextStyle(
//                       fontSize: screenWidth * 0.032, color: Colors.grey[600]),
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildInputField({
//     required String label,
//     required String hint,
//     required TextEditingController controller,
//     TextInputType keyboardType = TextInputType.text,
//     bool obscureText = false,
//     bool digitsOnly = false,
//     int maxLines = 1,
//   }) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: screenHeight * 0.02),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label, style: Theme.of(context).textTheme.bodyLarge),
//           SizedBox(height: screenHeight * 0.008),
//           TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             obscureText: obscureText,
//             maxLines: maxLines,
//             inputFormatters:
//                 digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
//             validator: (value) {
//               if (value == null || value.trim().isEmpty)
//                 return 'Please enter $label';
//               if (label == 'Email' && !_isValidEmail(value))
//                 return 'Please enter a valid email';
//               if (label == 'Phone' && value.length != 10)
//                 return 'Please enter a valid phone number';
//               return null;
//             },
//             decoration: InputDecoration(
//               filled: true,
//               fillColor: Theme.of(context).focusColor,
//               hintText: hint,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                 borderSide: BorderSide.none,
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                 borderSide: BorderSide(
//                     color: Theme.of(context).scaffoldBackgroundColor, width: 1),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                 borderSide:
//                     BorderSide(color: Theme.of(context).primaryColor, width: 2),
//               ),
//               errorBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                 borderSide: const BorderSide(color: Colors.red, width: 1),
//               ),
//               contentPadding: EdgeInsets.symmetric(
//                   horizontal: screenWidth * 0.04,
//                   vertical: screenHeight * 0.018),
//               hintStyle: TextStyle(
//                   fontSize: screenWidth * 0.038, color: Colors.grey[500]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRoleDropdown() {
//     return Padding(
//       padding: EdgeInsets.only(bottom: screenHeight * 0.02),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Role', style: Theme.of(context).textTheme.bodyLarge),
//           SizedBox(height: screenHeight * 0.008),
//           Container(
//             decoration: BoxDecoration(
//               color: Theme.of(context).focusColor,
//               borderRadius: BorderRadius.circular(screenWidth * 0.03),
//               border:
//                   Border.all(color: Theme.of(context).scaffoldBackgroundColor),
//             ),
//             padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
//             child: DropdownButtonFormField<String>(
//               value: _selectedRole,
//               icon: const Icon(Icons.arrow_drop_down),
//               decoration: const InputDecoration(
//                 border: InputBorder.none,
//               ),
//               items: _roles
//                   .map((role) => DropdownMenuItem(
//                         value: role,
//                         child: Text(
//                           role.replaceAll('ROLE_', '').replaceAll('_', ' '),
//                           style: TextStyle(fontSize: screenWidth * 0.038),
//                         ),
//                       ))
//                   .toList(),
//               onChanged: (value) => setState(() => _selectedRole = value),
//               validator: (value) =>
//                   value == null ? 'Please select a role' : null,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   AppBar _buildAppBar() {
//     return AppBar(
//       surfaceTintColor: Colors.transparent,
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       elevation: 0,
//       leading: IconButton(
//         icon: SvgPicture.asset(
//           AppIcons.back_Arrow,
//           width: screenWidth * 0.06,
//           colorFilter:
//               ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
//         ),
//         onPressed: () => Navigator.pop(context),
//       ),
//       centerTitle: true,
//       title: Text('Edit user',
//           style: Theme.of(context)
//               .textTheme
//               .bodyLarge
//               ?.copyWith(fontWeight: FontWeight.bold)),
//     );
//   }
//
//   bool _isValidEmail(String email) {
//     return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email.trim());
//   }
//
//
//   void _handleSubmit() async {
//     if (_formKey.currentState!.validate()) {
//       final controller = ref.read(signupControllerProvider.notifier);
//       // 1. Create updated model
//       final updatedUser = widget.user.copyWith(
//           employeeName: _nameController.text.trim(),
//           employeeEmail: _emailController.text.trim(),
//           employeePhone: _phoneController.text.trim(),
//           role: _selectedRole,
//           photo: _selectedImage?.path ?? widget.user.photo,
//           address: _addressController.text.trim(),
//           password: widget.user.password);
//
//       try {
//         // 2. Call update through your controller/provider
//
//         final error = await controller.updateUser(
//           oldUser: widget.user,
//           name: _nameController.text,
//           email: _emailController.text,
//           phone: _phoneController.text,
//           address: _addressController.text,
//           photo: _selectedImage?.path ?? widget.user.photo,
//           role: widget.user.role,
//         );
//
//
//         // 3. Show success feedback
//         if (error != null) {
//           // Show error message
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(error),
//               backgroundColor: Colors.red,
//             ),
//           );
//         } else {
//           // Show success message
//           ScaffoldMessenger.of(context).showSnackBar(
//             const SnackBar(
//               content: Text('User updated successfully'),
//               backgroundColor: Colors.green,
//             ),
//           );
//           Navigator.pop(context); // Go back
//         } // Go back after success
//       } catch (e) {
//         // 4. Handle error
//         ScaffoldMessenger.of(context).showSnackBar(
//           SnackBar(
//               content: Text('Update failed: $e'), backgroundColor: Colors.red),
//         );
//       }
//     }
//   }
// }
