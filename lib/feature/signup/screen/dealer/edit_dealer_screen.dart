import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:multi_select_flutter/chip_display/multi_select_chip_display.dart';
import 'package:multi_select_flutter/dialog/multi_select_dialog_field.dart';
import 'package:multi_select_flutter/util/multi_select_item.dart';
import 'package:multi_select_flutter/util/multi_select_list_type.dart';
import 'dart:io';
import '../../../../../../../../../core/media_query/media_query.dart';
import '../../../../../../../../../core/theme/theme.dart';
import '../../../../../../../../../core/const/icons.dart';
import '../../../../../../../core/theme/theme.dart';
import '../../../../../../../model/user_model.dart';
import '../../controller/signUp_controller.dart';

class EditDealerScreen extends ConsumerStatefulWidget {
  final UserModel dealer;
  const EditDealerScreen({super.key, required this.dealer});

  @override
  ConsumerState<EditDealerScreen> createState() => _EditDealerScreenState();
}

class _EditDealerScreenState extends ConsumerState<EditDealerScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _townController;
  late TextEditingController _addressController;

  final List<String> _districts = [
    'Alappuzha', 'Ernakulam', 'Idukki', 'Kannur', 'Kasaragod', 'Kollam',
    'Kottayam', 'Kozhikode', 'Malappuram', 'Palakkad', 'Pathanamthitta',
    'Thrissur', 'Thiruvananthapuram', 'Wayanad',
  ];

  final List<String> _brands = [
    'SAMSUNG', 'HTC', 'APPLE', 'VIVO', 'OPPO', 'MI',
  ];

  List<String> _selectedBrands = [];
  String? _selectedDistrict;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    final dealer = widget.dealer;
    _nameController = TextEditingController(text: dealer.employeeName);
    _emailController = TextEditingController(text: dealer.employeeEmail);
    _phoneController = TextEditingController(text: dealer.employeePhone);
    _townController = TextEditingController(text: dealer.town);
    _addressController = TextEditingController(text: dealer.address);
    _selectedDistrict = dealer.district;
    _selectedBrands = List<String>.from(dealer.brand!);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _townController.dispose();
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
    setState(() => _selectedImage = null);
  }

  void _showImagePickerDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
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
        oldUser: widget.dealer,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        address: _addressController.text,
        photo: _selectedImage?.path ?? widget.dealer.photo,
        role: widget.dealer.role,
        town: _townController.text,
        district: _selectedDistrict,
        brand: _selectedBrands,
      );

      Navigator.pop(context);
      if (error != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error), backgroundColor: Colors.red),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Dealer updated successfully!'), backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppIcons.back_Arrow, width: screenWidth * 0.06, colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Edit Dealer', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
      ),
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
                _buildRoleDropdown(),
                _buildInputField(label: 'Town', hint: 'Enter Town name', controller: _townController),
                _buildInputField(label: 'Address', hint: 'Enter address', controller: _addressController, maxLines: 3),
                _buildBrandMultiSelect(),
                SizedBox(height: screenHeight * 0.03),
                _buildSubmitButton(_handleSubmit),
                SizedBox(height: screenHeight * 0.02),
              ],
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
              return null;
            },
            decoration: InputDecoration(
              filled: true,
              fillColor: Theme.of(context).focusColor,
              hintText: hint,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide(color: Theme.of(context).scaffoldBackgroundColor, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
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
          Text('District', style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: screenHeight * 0.008),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).focusColor,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor),
            ),
            padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.02),
            child: DropdownButtonFormField<String>(
              value: _selectedDistrict,
              icon: const Icon(Icons.arrow_drop_down),
              decoration: const InputDecoration(border: InputBorder.none),
              items: _districts.map((district) => DropdownMenuItem(
                value: district,
                child: Text(district, style: TextStyle(fontSize: screenWidth * 0.038)),
              )).toList(),
              onChanged: (value) => setState(() => _selectedDistrict = value),
              validator: (value) => value == null ? 'Please select a district' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBrandMultiSelect() {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Brands', style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: screenHeight * 0.008),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).focusColor,
              borderRadius: BorderRadius.circular(screenWidth * 0.03),
              border: Border.all(color: Theme.of(context).scaffoldBackgroundColor),
            ),
            child: MultiSelectDialogField(
              items: _brands.map((brand) => MultiSelectItem<String>(brand, brand)).toList(),
              initialValue: _selectedBrands,
              title: const Text("Select Brands"),
              selectedColor: Theme.of(context).primaryColor,
              selectedItemsTextStyle: Theme.of(context).textTheme.bodyLarge,
              itemsTextStyle: Theme.of(context).textTheme.bodyLarge,
              decoration: BoxDecoration(
                color: Theme.of(context).focusColor,
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                border: Border.all(color: Theme.of(context).scaffoldBackgroundColor),
              ),
              buttonIcon: Icon(Icons.arrow_drop_down, color: Theme.of(context).primaryColor),
              buttonText: Text("Select Brands", style: TextStyle(color: Color(0xFFB0B0B0), fontSize: screenWidth * 0.038)),
              dialogHeight: screenHeight * 0.5,
              listType: MultiSelectListType.LIST,
              chipDisplay: MultiSelectChipDisplay(
                chipColor: Theme.of(context).primaryColor,
                textStyle: Theme.of(context).textTheme.bodyMedium,
              ),
              onConfirm: (values) => setState(() => _selectedBrands = List<String>.from(values)),
              validator: (values) => (values == null || values.isEmpty) ? 'Please select at least one brand' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileImageSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.02),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showImagePickerDialog,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: screenWidth * 0.08,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : (widget.dealer.photo.isNotEmpty ? NetworkImage(widget.dealer.photo) : const NetworkImage('https://i.pravatar.cc/150?img=3')) as ImageProvider,
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

  Widget _buildSubmitButton(VoidCallback onTap) {
    return SizedBox(
      width: screenWidth * 0.5,
      height: screenHeight * 0.06,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).primaryColor),
        child: Text('Update', style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500)),
      ),
    );
  }
}
