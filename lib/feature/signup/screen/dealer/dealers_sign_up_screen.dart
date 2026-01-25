import 'package:dropdown_search/dropdown_search.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import 'package:multi_select_flutter/multi_select_flutter.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/const/icons.dart';
import '../../../../core/media_query/media_query.dart';
import '../../../../core/theme/theme.dart';
import '../../../../model/user_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../../../widgets/expandedSectionDropdown.dart';
import '../../../../widgets/scrollbar.dart';
import '../../../brand/controller/brand_controller.dart';
import '../../controller/signUp_controller.dart';

class AddDealerScreen extends ConsumerStatefulWidget {
  const AddDealerScreen({super.key});

  @override
  ConsumerState<AddDealerScreen> createState() => _AddUserScreenState();
}
class _AddUserScreenState extends ConsumerState<AddDealerScreen> {
  late bool isRoleDropdownOpen = false;
  final _formKey = GlobalKey<FormState>();
  final scrollController = ScrollController();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _townController = TextEditingController();
  final _shopController = TextEditingController();
  late ScrollController _roleScrollController; // define at State level
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
  String? _selectedDistrict;
  File? _selectedImage;
  final ImagePicker _picker = ImagePicker();
  List<String> _selectedBrands = [];
  String? _brandError;


  @override
  void initState() {
    super.initState();
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
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(Screen.w(context) * 0.04)),
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
  @override
  Widget build(BuildContext context) {
    final brandState = ref.watch(loadBrandsControllerProvider); // ✅ add this here
    return Scaffold(
      backgroundColor: AppTheme.background,
      body: brandState.when(
        data: (brands) {
          // ✅ Full form when brands are loaded
          return SafeArea(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircularIconButton(
                        icon: Icons.arrow_back_ios_sharp,
                        onTap: () {
                          Navigator.pop(context);
                        },
                      ),
                      _buildProfileImageSection(),
                      _buildInputField(label: 'Name', hint: 'Enter full name', controller: _nameController),
                      _buildInputField(label: 'Email', hint: 'Enter email address', controller: _emailController, keyboardType: TextInputType.emailAddress),
                      _buildInputField(label: 'Phone', hint: 'Enter phone number', controller: _phoneController, keyboardType: TextInputType.phone, digitsOnly: true),
                      _buildInputField(label: 'Shop', hint: 'Enter shop name', controller: _shopController,),
                      _buildDistrictDropdown(),
                      _buildInputField(label: 'Town', hint: 'Enter Town', controller: _townController),
                      _buildInputField(label: 'Address', hint: 'Enter address', controller: _addressController, maxLines: 3),
                      _buildBrandDropdown(ref), // ✅ brands loaded here
                      SizedBox(height: Screen.h(context) * 0.03),
                      Center(child: _buildSubmitButton(_handleSubmit)),
                      SizedBox(height: Screen.h(context) * 0.02),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
        loading: ()=>GlobalLoader(),
        error: (e, st) {
          // ❌ Retry option if brands not loaded
          return FutureBuilder(
            future: Future.delayed(const Duration(seconds: 2), () => true),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                // Show shimmer placeholders during 2 sec delay
                    return  Padding(
                      padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _shimmerCircle(), // profile image placeholder
                          SizedBox(height: Screen.h(context)*0.01),
                          ...List.generate(
                              7, (_) => _shimmerBox()), // input fields shimmer
                          SizedBox(height: Screen.h(context)*0.13),
                          Center(child: _shimmerButton()), // submit button shimmer
                        ],
                      ),
                    );
              }
              // After shimmer delay -> show No Internet
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off, size: 50, color: Colors.grey),
                    SizedBox(height: 10),
                    Text(
                      "No Internet Connection",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                    ),
                    SizedBox(height: Screen.h(context) * 0.01),
                    ElevatedButton(
                      onPressed: () {
                        ref.invalidate(loadBrandsControllerProvider); // retry
                      },
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
  AppBar _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: SvgPicture.asset(AppIcons.back_Arrow, width: Screen.w(context) * 0.06,colorFilter:ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn) ,),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title:  Text('Add user', style: Theme.of(context).textTheme.bodyLarge?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildProfileImageSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Screen.h(context) * 0.02),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showImagePickerDialog, // ✅ fixed
            child: Stack(
              children: [
                CircleAvatar(
                  radius: Screen.w(context) * 0.08,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!)
                      : const NetworkImage('https://i.pravatar.cc/150?img=3') as ImageProvider,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.all(Screen.w(context) * 0.02),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(
                      Icons.camera_alt,
                      color: Colors.white,
                      size: Screen.w(context) * 0.04,
                    ),
                  ),
                ),
              ],
            ),
          ),

          SizedBox(width: Screen.w(context) * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Image', style: TextStyle(fontSize: Screen.w(context) * 0.04, fontWeight: FontWeight.w600, color: Colors.black87)),
                SizedBox(height: Screen.h(context) * 0.005),
                Text(
                  _selectedImage != null ? 'Tap to change photo' : 'Tap to add photo',
                  style: TextStyle(fontSize: Screen.w(context) * 0.032, color: Colors.grey[600]),
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
                borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
                borderSide: BorderSide(color: Colors.grey),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
                borderSide: BorderSide(color: Colors.grey.shade400, width: 1),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
                borderSide: BorderSide(color:Theme.of(context).primaryColor, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04, vertical: Screen.h(context) * 0.018),
              hintStyle: TextStyle(fontSize: Screen.w(context) * 0.038, color: Colors.grey[500]),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildBrandDropdown(WidgetRef ref) {
    final brandState = ref.watch(loadBrandsControllerProvider);
    return Padding(
      padding: EdgeInsets.only(bottom: Screen.h(context) * 0.02),
      child: FormField<List<String>>(
        validator: (value) {
          if (_selectedBrands.isEmpty) {
            return 'Please select at least one brand';
          }
          return null;
        },
        builder: (fieldState) {
          return Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text('Brands', style: Theme.of(context).textTheme.bodyLarge),
                SizedBox(height: Screen.h(context) * 0.008),
                brandState.when(
                  data: (brands) {
                    return InkWell(
                      onTap: () => _showBrandDialog(context, brands),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
                          border: Border.all(
                            color: fieldState.hasError
                                ? Colors.red
                                : Colors.grey.shade400,
                            width: 1,
                          ),
                        ),
                        child: _selectedBrands.isEmpty
                            ? const Text("Select Brands")
                            : Wrap(
                          spacing: 6,
                          children: _selectedBrands.map((id) {
                            final brand = brands.firstWhere(
                                    (b) => b.brandId.toString() == id);
                            return Chip(
                              deleteIconColor: Colors.white,
                              backgroundColor:
                              Theme.of(context).primaryColor,
                              label: Text(
                                brand.brandName,
                                style: const TextStyle(color: Colors.white),
                              ),
                              deleteIcon: const Icon(Icons.cancel),
                              onDeleted: () {
                                setState(() {
                                  _selectedBrands.remove(id);
                                  fieldState.didChange(_selectedBrands);
                                });
                              },
                            );
                          }).toList(),
                        ),
                      ),
                    );
                  },
                  loading: () => const LinearProgressIndicator(),
                  error: (e, _) => Text('Error: $e',
                      style: const TextStyle(color: Colors.red)),
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
            ),
          );
        },
      ),
    );
  }


  void _showBrandDialog(BuildContext context, List brands) async {
    final List<String> tempSelected = List.from(_selectedBrands);
    String searchQuery = ""; // to track search text
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
          ),
          title: const Text("Select Brands"),
          content: StatefulBuilder(
            builder: (context, setState) {
              // filter brands by search text
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
                    // 🔎 Search bar
                    TextField(
                      decoration: InputDecoration(
                        hintText: "Search brand...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(Screen.w(context)*0.04),
                        ),
                        contentPadding:
                         EdgeInsets.symmetric(horizontal: Screen.w(context)*0.1, vertical: Screen.h(context)*0.01),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                    const SizedBox(height: 10),
                    // ✅ Filtered brand list
                    Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: filteredBrands.map<Widget>((b) {
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
                        }).toList(),
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
              child:  Text("Close",style: TextStyle(color: Theme.of(context).primaryColor),),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _selectedBrands = tempSelected;
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





  Widget _buildDistrictDropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: Screen.h(context) * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('District', style: Theme.of(context).textTheme.bodyLarge),
          SizedBox(height: Screen.h(context) * 0.008),
          FormField<String>(
            validator: (value) => value == null ? 'Please select a District' : null,
            builder: (state) {
              return Column(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => isRoleDropdownOpen = !isRoleDropdownOpen),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Theme.of(context).focusColor,
                        borderRadius: BorderRadius.circular(Screen.w(context) * 0.03),
                        border: Border.all(
                          color: state.hasError
                              ? Colors.red
                              : Theme.of(context).scaffoldBackgroundColor,
                        ),
                      ),
                      padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.02),
                      height: Screen.h(context) * 0.065,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _selectedDistrict != null
                                ? _selectedDistrict!.replaceAll('District', '').replaceAll('_', ' ')
                                : 'Select District',
                            style: TextStyle(fontSize: Screen.w(context) * 0.038),
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
                    height: Screen.h(context)*0.01,
                    child: MyScrollbar(
                      builder: (context, scrollController) => ListView.builder(
                        controller: _roleScrollController,
                        shrinkWrap: true,
                        itemCount: _keralaDistricts.length,
                        itemBuilder: (context, index) {
                          final role = _keralaDistricts[index];
                          return RadioListTile<String>(
                            title: Text(
                              role.replaceAll('District', '').replaceAll('_', ' '),
                              style: TextStyle(fontSize: Screen.w(context) * 0.038),
                            ),
                            value: role,
                            groupValue: _selectedDistrict,
                            onChanged: (value) {
                              setState(() {
                                _selectedDistrict = value;
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
  Widget _buildSubmitButton(VoidCallback onTap) {
    return SizedBox(
      width: Screen.w(context) * 0.5,
      height: Screen.h(context)*0.06,
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
          password: 'Shahulvm@123',
          address: _addressController.text,
          role: 'ROLE_DEALER',
          brand:_selectedBrands, photo: '',
          town: _townController.text,
          shopName: _shopController.text,
          district: _selectedDistrict
        ),
        photoFile: _selectedImage, // ✅ send picked image for upload
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
            content: Text('Dealer created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        ref.watch(dealerListProvider);
        Navigator.pop(context); // Go back
      }
    }
  }

  /// Shimmer placeholder widget
  /// Rectangle shimmer (input fields)
  Widget _shimmerBox() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 8),
        height: Screen.h(context) * 0.06,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Circle shimmer (profile image)
  Widget _shimmerCircle() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: CircleAvatar(
        radius: Screen.w(context) * 0.1,
        backgroundColor: Colors.white,
      ),
    );
  }

  /// Button shimmer
  Widget _shimmerButton() {
    return Shimmer.fromColors(
      baseColor: Colors.grey.shade300,
      highlightColor: Colors.grey.shade100,
      child: Container(
        width: Screen.w(context) * 0.5,
        height: Screen.h(context) * 0.06,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

}

