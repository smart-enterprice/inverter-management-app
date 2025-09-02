import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../../core/media_query/media_query.dart';
import '../../../../../../core/theme/theme.dart';
import '../../../../../../core/const/icons.dart';
import '../../../../widgets/expandedSectionDropdown.dart';
import '../../../../widgets/scrollbar.dart';
import '../../controller/signUp_controller.dart';
import '../../../../model/user_model.dart';

class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  late bool isRoleDropdownOpen = false;
  final _formKey = GlobalKey<FormState>();
  final scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  late ScrollController _roleScrollController; // define at State level
  final List<String> _roles = [
    'ROLE_ADMIN',
    'ROLE_SALESMAN',
    'ROLE_PRODUCTION',
    'ROLE_PACKING',
    'ROLE_ACCOUNTS',
    'ROLE_DELIVERY',
  ];
  String? _selectedRole;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _selectedRole = _roles.first;
    _roleScrollController = ScrollController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _roleScrollController.dispose();
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
        SnackBar(content: Text('Error picking image: ${e.toString()}'), backgroundColor: Colors.red),
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
      builder: (BuildContext context,) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.04)),
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
              if (_selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete, color: Colors.red),
                  title: const Text('Remove Photo'),
                  onTap: () {
                    Navigator.pop(context);
                    _removeImage();
                  },
                ),
            ],
          ),
        );
      },
    );
  }
  bool isPasswordHidden = true;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:AppTheme.background,
      // bottomNavigationBar: Padding(
      //   padding: EdgeInsets.only(left: screenWidth * 0.04,right: screenWidth * 0.04,bottom:  screenWidth * 0.04),
      //   child: _buildSubmitButton(),
      // ),
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildProfileImageSection(),
                _buildInputField(label: 'Name', hint: 'Enter full name', controller: _nameController),
                _buildInputField(label: 'Email', hint: 'Enter email address', controller: _emailController, keyboardType: TextInputType.emailAddress),
                _buildInputField(label: 'Phone', hint: 'Enter phone number', controller: _phoneController, keyboardType: TextInputType.phone, digitsOnly: true),
                _buildInputField(label: 'Password', hint: 'Enter password', controller: _passwordController, obscureText: isPasswordHidden,suffixIcon:IconButton(
                  icon: Icon(
                    isPasswordHidden ? Icons.visibility_off : Icons.visibility,
                    color: Colors.grey,
                  ),
                  onPressed: () {
                    setState(() {
                      isPasswordHidden = !isPasswordHidden;
                    });
                  },
                ), ),
                _buildInputField(label: 'Address', hint: 'Enter address', controller: _addressController, maxLines: 3),
                _buildRoleDropdown(),
                SizedBox(height: screenHeight * 0.03),
                _buildSubmitButton(
                    _handleSubmit
                ),
                SizedBox(height: screenHeight * 0.02),
              ],
            ),
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: SvgPicture.asset(AppIcons.back_Arrow, width: screenWidth * 0.06,colorFilter:ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn) ,),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title:  Text('Add user', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProfileImageSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      child: Row(
        children: [
          GestureDetector(
            onTap: ()=>_showImagePickerDialog,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: screenWidth * 0.08,
                  backgroundImage: _selectedImage != null ? FileImage(_selectedImage!) : const NetworkImage('https://i.pravatar.cc/150?img=3') as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(screenWidth * 0.02),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.camera_alt, color: Colors.white, size: screenWidth * 0.04),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Image', style: TextStyle(fontSize: screenWidth * 0.04, fontWeight: FontWeight.w600, color: Colors.black87)),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  _selectedImage != null ? 'Tap to change photo' : 'Tap to add photo',
                  style: TextStyle(fontSize: screenWidth * 0.032, color: Colors.grey[600]),
                ),
              ],
            ),
          ),
        ],
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
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: screenHeight * 0.008),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter $label';
              if (label == 'Email' && !_isValidEmail(value)) return 'Please enter a valid email';
              if (label == 'Phone' && value.length != 10) return 'Please enter a valid 10-digit phone number';
              if (label == 'Password' && value.length < 6) return 'Password must be at least 6 characters';
              return null;
            },
            decoration: InputDecoration(
              suffixIcon: suffixIcon,
              filled: false,
              fillColor: Theme.of(context).focusColor,
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide(color:Theme.of(context).primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.018),
              hintStyle: TextStyle(fontSize: screenWidth * 0.038, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleDropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Role', style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: screenHeight * 0.008),
          FormField<String>(
            validator: (value) => value == null ? 'Please select a role' : null,
            builder: (state) {
              return Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isRoleDropdownOpen = !isRoleDropdownOpen),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).focusColor,
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        border: Border.all(
                          color: state.hasError
                              ? Colors.red
                              : Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
                      height: screenHeight * 0.065,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedRole != null
                                ? _selectedRole!.replaceAll('ROLE_', '').replaceAll('_', ' ')
                                : 'Select Role',
                            style: TextStyle(fontSize: screenWidth * 0.038),
                          ),
                          Icon(
                            isRoleDropdownOpen
                                ? Icons.arrow_upward
                                : Icons.arrow_downward,
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 5),
                  ExpandedSection(
                    expand: isRoleDropdownOpen,
                    height: screenHeight*0.01,
                    child: MyScrollbar(
                      builder: (context, scrollController) => ListView.builder(
                        controller: _roleScrollController,
                        shrinkWrap: true,
                        itemCount: _roles.length,
                        itemBuilder: (context, index) {
                          final role = _roles[index];
                          return RadioListTile<String>(
                            title: Text(
                              role.replaceAll('ROLE_', '').replaceAll('_', ' '),
                              style: TextStyle(fontSize: screenWidth * 0.038),
                            ),
                            value: role,
                            groupValue: _selectedRole,
                            onChanged: (value) {
                              setState(() {
                                _selectedRole = value;
                                isRoleDropdownOpen = false;
                                state.didChange(value); // updates FormField validation
                              });
                            },
                          );
                        },
                      ), scrollController:scrollController ,
                    ),
                  ),
                  if (state.hasError)
                    Padding(
                      padding: const EdgeInsets.only(top: 5),
                      child: Text(
                        state.errorText!,
                        style: TextStyle(color: Colors.red, fontSize: 12),
                      ),
                    ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }



  Widget _buildSubmitButton(onTap) {
    return SizedBox(
      width: screenWidth * 0.5,
      height: screenHeight*0.06,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
        ),
        child:  Text('Submit',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),),
      ),
    );
  }


  bool _isValidEmail(String email) {
    return  RegExp(r'^[\w\-\.]+@([\w\-]+\.)+[\w\-]{2,4}$').hasMatch(email);

  }

  void _handleSubmit() async {
    if (_formKey.currentState!.validate()) {
      final controller = ref.read(signupControllerProvider.notifier);

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) => const Center(child: CircularProgressIndicator()),
      );

      final error = await controller.signup(
        UserModel(
          employeeName: _nameController.text,
          employeeEmail: _emailController.text,
          employeePhone: _phoneController.text,
          password: _passwordController.text,
          address: _addressController.text,
          role: _selectedRole!,
          photo: _selectedImage?.path ?? '',
        ),
      );

      Navigator.pop(context); // Remove loader

      if (error != null) {
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(error),
            backgroundColor: Colors.red,
          ),
        );
      } else {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context); // Go back
      }
    }
  }
  }




