import 'package:cached_network_image/cached_network_image.dart';
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
import '../../../../core/const/district.dart';
import '../../../../model/brand_model.dart';
import '../../../brand/controller/brand_controller.dart';
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
  late TextEditingController _shopController;

  final List<String> _keralaDistricts = [
    "Kasaragod",
    "Kannur",
    "Wayanad",
    "Kozhikode",
    "Malappuram",
    "Palakkad",
    "Thrissur",
    "Ernakulam",
    "Idukki",
    "Kottayam",
    "Alappuzha",
    "Pathanamthitta",
    "Kollam",
    "Thiruvananthapuram",
  ];

  List<String>? _selectedBrands = [];
  List<String> _previousSelectedBrands = [];
  String? _selectedDistrict;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  late bool isRoleDropdownOpen = false;

  @override
  void initState() {
    super.initState();
    final dealer = widget.dealer;
    _nameController = TextEditingController(text: dealer.employeeName);
    _emailController = TextEditingController(text: dealer.employeeEmail);
    _phoneController = TextEditingController(text: dealer.employeePhone);
    _shopController = TextEditingController(text: dealer.shopName);
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
        SnackBar(
            content: Text('Error picking image: ${e.toString()}'),
            backgroundColor: Colors.red),
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
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.04)),
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
        oldUser: widget.dealer,
        name: _nameController.text,
        email: _emailController.text,
        phone: _phoneController.text,
        shopName: _shopController.text,
        address: _addressController.text,
        photo: widget.dealer.photo,
        photoFile: _selectedImage,
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
          const SnackBar(
              content: Text('Dealer updated successfully!'),
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
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 0,
        leading: IconButton(
          icon: SvgPicture.asset(AppIcons.back_Arrow,
              width: screenWidth * 0.06,
              colorFilter: ColorFilter.mode(
                  Theme.of(context).primaryColor, BlendMode.srcIn)),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text('Edit Dealer',
            style: Theme.of(context)
                .textTheme
                .bodyLarge
                ?.copyWith(fontWeight: FontWeight.bold)),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
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
                    label: 'Shop',
                    hint: 'Enter full Shop name',
                    controller: _shopController),
                _buildDistrict(),
                _buildInputField(
                    label: 'Town',
                    hint: 'Enter Town name',
                    controller: _townController),
                _buildInputField(
                    label: 'Address',
                    hint: 'Enter address',
                    controller: _addressController,
                    maxLines: 3),
                _buildBrandMultiSelect(ref),
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
              if (label == 'Password' && value.length < 6)
                return 'Password must be at least 6 characters';
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
                borderSide:
                    BorderSide(color: Theme.of(context).primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(
                  horizontal: screenWidth * 0.04,
                  vertical: screenHeight * 0.018),
              hintStyle: TextStyle(
                  fontSize: screenWidth * 0.038, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrict() {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: FormField<String>(
        // validator: (value) => value == null ? 'Please select a district' : null,
        builder: (state) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('District', style: Theme.of(context).textTheme.bodyLarge),
              SizedBox(height: screenHeight * 0.008),
              GestureDetector(
                onTap: () => _showDistrictDialog(state),
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
                  padding: EdgeInsets.symmetric(
                    horizontal: screenWidth * 0.04,
                    vertical: screenHeight * 0.018,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        _selectedDistrict ?? "Select District",
                        style: TextStyle(
                          fontSize: screenWidth * 0.038,
                          color: _selectedDistrict == null
                              ? Colors.grey
                              : Colors.black,
                        ),
                      ),
                      const Icon(Icons.arrow_drop_down),
                    ],
                  ),
                ),
              ),
              if (state.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 5),
                  child: Text(
                    state.errorText!,
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showDistrictDialog(FormFieldState<String> fieldState) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          title: const Text("Select District"),
          content: SizedBox(
            width: double.maxFinite,
            height: screenHeight * 0.5,
            child: ListView.builder(
              itemCount: keralaDistricts.length,
              itemBuilder: (context, index) {
                final district = _keralaDistricts[index];
                return RadioListTile<String>(
                  title: Text(district),
                  value: district,
                  groupValue: _selectedDistrict,
                  onChanged: (value) {
                    setState(() {
                      _selectedDistrict = value;
                      fieldState.didChange(value); // update validator
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

  Widget _buildBrandMultiSelect(WidgetRef ref) {
    final brandState = ref.watch(loadBrandsControllerProvider);

    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: FormField<List<String>>(
        validator: (value) {
          if (_selectedBrands!.isEmpty) {
            return 'Please select at least one brand';
          }
          return null;
        },
        builder: (fieldState) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Brands', style: Theme.of(context).textTheme.bodyLarge),
              SizedBox(height: screenHeight * 0.008),
              brandState.when(
                data: (brands) {
                  return InkWell(
                    onTap: () => _showBrandDialog(context, brands),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(screenWidth * 0.03),
                        border: Border.all(
                          color: fieldState.hasError
                              ? Colors.red
                              : Colors.grey.shade400,
                          width: 1,
                        ),
                      ),
                      child: _selectedBrands!.isEmpty
                          ? Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Select Brands",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: screenWidth * 0.038,
                            ),
                          ),
                          Icon(Icons.arrow_drop_down, color: Colors.grey[600]),
                        ],
                      )
                          : Wrap(
                        spacing: 6,
                        runSpacing: 6,
                        children: _selectedBrands!.map((id) {
                          // FIXED: Use where with orElse to handle missing brands safely
                          try {
                            final brand = brands.firstWhere(
                                  (b) => b.brandId.toString() == id,
                              orElse: () => BrandModel(
                                brandId: id,
                                brandName: 'Unknown Brand',
                                 brandModels: [], description: '',
                              ),
                            );

                            return Chip(
                              deleteIconColor: Colors.white,
                              backgroundColor: Theme.of(context).primaryColor,
                              label: Text(
                                brand.brandName,
                                style: const TextStyle(color: Colors.white),
                              ),
                              deleteIcon: const Icon(Icons.cancel, size: 18),
                              onDeleted: () {
                                setState(() {
                                  _selectedBrands?.remove(id);
                                  fieldState.didChange(_selectedBrands);
                                });
                              },
                            );
                          } catch (e) {
                            // If there's any error, just skip this chip
                            return const SizedBox.shrink();
                          }
                        }).toList(),
                      ),
                    ),
                  );
                },
                loading: () => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(color: Colors.grey.shade400, width: 1),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 10),
                      Text('Loading brands...',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                error: (e, _) => Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.03),
                    border: Border.all(color: Colors.red, width: 1),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red, size: 20),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Error loading brands',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (fieldState.hasError)
                Padding(
                  padding: const EdgeInsets.only(top: 5, left: 5),
                  child: Text(
                    fieldState.errorText ?? '',
                    style: const TextStyle(color: Colors.red, fontSize: 12),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  void _showBrandDialog(BuildContext context, List<BrandModel> brands) async { // ✅ typed list
    final List<String> tempSelected = List.from(_selectedBrands!);
    String searchQuery = "";

    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          title: const Text("Select Brands"),
          content: StatefulBuilder(
            builder: (context, setState) {
              final filteredBrands = brands
                  .where((b) => b.brandName
                  .toLowerCase()
                  .contains(searchQuery.toLowerCase()))
                  .toList();

              return SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search brand...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(screenWidth * 0.04),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: screenWidth * 0.1,
                          vertical: screenHeight * 0.01,
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filteredBrands.length,
                        itemBuilder: (context, index) {
                          final b = filteredBrands[index];
                          final id = b.brandId.toString();
                          final isSelected = tempSelected.contains(id);

                          return Row(
                            children: [
                              Checkbox(
                                checkColor: Colors.white,
                                activeColor: Theme.of(context).primaryColor,
                                value: isSelected,
                                onChanged: (checked) {
                                  setState(() {
                                    if (checked == true) {
                                      tempSelected.add(id);
                                    } else {
                                      tempSelected.remove(id);
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      if (isSelected) {
                                        tempSelected.remove(id);
                                      } else {
                                        tempSelected.add(id);
                                      }
                                    });
                                  },
                                  child: Text(
                                    b.brandName,
                                    style: const TextStyle(color: Colors.black),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                "Close",
                style: TextStyle(color: Theme.of(context).primaryColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _previousSelectedBrands = List.from(_selectedBrands!);
                  _selectedBrands = List.from(tempSelected);
                });
                Navigator.pop(context);
              },
              child: const Text("OK"),
            ),
          ],
        );
      },
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
                      : (widget.dealer.photo!.isNotEmpty
                              ? NetworkImage(widget.dealer.photo.toString())
                              : const NetworkImage(
                                  'https://i.pravatar.cc/150?img=3'))
                          as ImageProvider,
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
                    child: Icon(Icons.camera_alt,
                        color: Colors.white, size: screenWidth * 0.04),
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
                Text('Profile Image',
                    style: TextStyle(
                        fontSize: screenWidth * 0.04,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87)),
                SizedBox(height: screenHeight * 0.005),
                Text(
                  _selectedImage != null
                      ? 'Tap to change photo'
                      : 'Tap to add photo',
                  style: TextStyle(
                      fontSize: screenWidth * 0.032, color: Colors.grey[600]),
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
      height: screenHeight*0.06,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Theme.of(context).primaryColor,
        ),
        child:  Text('Update',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),),
      ),
    );
  }

}
