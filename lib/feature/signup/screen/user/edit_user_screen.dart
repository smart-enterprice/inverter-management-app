import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/const/icons.dart';
import '../../../../core/const/role.dart';
import '../../../../core/media_query/media_query.dart';
import '../../../../core/theme/theme.dart';
import '../../../../widgets/circle_button.dart';
import '../../controller/signUp_controller.dart';
import '../../../../model/user_model.dart';

class EditUserScreen extends ConsumerStatefulWidget {
  final UserModel user;

  const EditUserScreen({
    super.key,
    required this.user,
  });

  @override
  ConsumerState<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends ConsumerState<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _addressController;

  String? _selectedRole;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();


  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.employeeName);
    _emailController = TextEditingController(text: widget.user.employeeEmail);
    _phoneController =
        TextEditingController(text: widget.user.employeePhone.toString());
    _addressController = TextEditingController(text: widget.user.address);
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red),
      );
    }
  }

  void _removeImage() {
    setState(() {
      _selectedImage = null;
    });
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Screen.w(context) * 0.04)),
        title: const Text('Select Photo'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.camera_alt, color: Colors.blue),
              title: const Text('Camera'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library, color: Colors.green),
              title: const Text('Gallery'),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w\.-]+@[\w\.-]+\.\w{2,}$').hasMatch(email);
  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final controller = ref.read(signupControllerProvider.notifier);
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final error = await controller.updateUser(
        oldUser: widget.user,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        photo:widget.user.photo,
        photoFile: _selectedImage,
        role: _selectedRole,
      );

      Navigator.pop(context);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('User updated successfully!'),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(
                      top: Screen.w(context) * 0.02,
                      bottom: Screen.w(context) * 0.03,
                    ),
                    child: CircularIconButton(
                      icon: Icons.arrow_back_ios_sharp,
                      onTap: () {
                        Navigator.pop(context);
                      },
                    ),
                  ),
                  _buildProfileImageSection(),
                  _buildInputField(
                      label: 'Name',
                      hint: 'Enter full name',
                      controller: _nameController),
                  _buildInputField(
                      label: 'Email',
                      hint: 'Enter email address',
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress),
                  _buildInputField(
                      label: 'Phone',
                      hint: 'Enter phone number',
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      digitsOnly: true),
                  _buildInputField(
                      label: 'Address',
                      hint: 'Enter address',
                      controller: _addressController,
                      maxLines: 3),
                  _buildRoleDropdown(),
                  SizedBox(height: Screen.h(context) * 0.03),
                  Center(child: _buildSubmitButton(_handleSubmit)),
                  SizedBox(height: Screen.h(context) * 0.02),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required String label,
    required String hint,
    required TextEditingController controller,
    TextInputType keyboardType = TextInputType.text,
    bool obscureText = false,
    bool digitsOnly = false,
    int maxLines = 1,
    Widget? suffixIcon,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: Screen.h(context) * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: Screen.h(context) * 0.008),
          TextFormField(
            autovalidateMode: AutovalidateMode.disabled,
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            inputFormatters:
            digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            validator: (value) {
              if (value == null || value.trim().isEmpty)
                return 'Please enter $label';
              if (label == 'Email' && !_isValidEmail(value))
                return 'Please enter a valid email';
              if (label == 'Phone' && value.length != 10)
                return 'Please enter a valid 10-digit phone number';
              return null;
            },
            decoration: InputDecoration(
              suffixIcon: suffixIcon,
              filled: false,
              fillColor: Theme.of(context).focusColor,
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Screen.w(context)  * 0.03),
                borderSide: BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Screen.w(context)  * 0.03),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Screen.w(context)  * 0.03),
                borderSide:
                BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Screen.w(context)  * 0.03),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: Screen.w(context)  * 0.04,
                  vertical: Screen.h(context) * 0.018),
              hintStyle: TextStyle(
                  fontSize: Screen.w(context)  * 0.038, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: Screen.h(context) * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Role', style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: Screen.h(context) * 0.008),
          GestureDetector(
            onTap: () => _showRoleDialog(),
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).focusColor,
                borderRadius: BorderRadius.circular(Screen.w(context)  * 0.03),
                border: Border.all(
                  color: Colors.grey.shade400,
                  width: 1,
                ),
              ),
              padding: EdgeInsets.symmetric(
                horizontal: Screen.w(context)  * 0.04,
                vertical: Screen.h(context) * 0.018,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _selectedRole?.replaceAll('ROLE_', '').replaceAll('_', ' ') ?? "Select Role",
                    style: TextStyle(
                      fontSize: Screen.w(context)  * 0.038,
                      color: _selectedRole == null
                          ? Colors.grey[500]
                          : Colors.black,
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRoleDialog() {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Screen.w(context)  * 0.03),
          ),
          title: const Text("Select Role"),
          content: SizedBox(
            width: double.maxFinite,
            height: Screen.h(context) * 0.4,
            child: ListView.builder(
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                final displayRole = role.replaceAll('ROLE_', '').replaceAll('_', ' ');
                return RadioListTile<String>(
                  title: Text(displayRole),
                  value: role,
                  groupValue: _selectedRole,
                  onChanged: (value) {
                    setState(() {
                      _selectedRole = value;
                    });
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildProfileImageSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Screen.h(context) * 0.02),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showImagePickerDialog,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: Screen.w(context)  * 0.08,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (widget.user.photo!.isNotEmpty
                      ? NetworkImage(widget.user.photo!)
                      : const NetworkImage(
                      'https://i.pravatar.cc/150?img=3'))
                  as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(Screen.w(context)  * 0.02),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.camera_alt,
                        color: Colors.white, size: Screen.w(context)  * 0.04),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: Screen.w(context)  * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Image',
                    style: TextStyle(
                        fontSize: Screen.w(context)  * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                SizedBox(height: Screen.h(context) * 0.005),
                Text(
                  _selectedImage != null
                      ? 'Tap to change photo'
                      : 'Tap to add photo',
                  style: TextStyle(
                      fontSize: Screen.w(context)  * 0.032, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(VoidCallback onTap) {
    return SizedBox(
      width: Screen.w(context)  * 0.5,
      height: Screen.h(context) * 0.06,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
        ),
        child: Text(
          'Update',
          style: TextStyle(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}