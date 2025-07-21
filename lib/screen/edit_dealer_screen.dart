import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';

import '../core/const/icons.dart';

class EditDealerScreen extends StatefulWidget {
  final Map<String, dynamic> dealerData;
  const EditDealerScreen({super.key, required this.dealerData});

  @override
  State<EditDealerScreen> createState() => _EditDealerScreenState();
}

class _EditDealerScreenState extends State<EditDealerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dealerNameController = TextEditingController();
  final _shopNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _townController = TextEditingController();
  final _addressController = TextEditingController();

  String? _selectedDistrict;
  String? _selectedBrand;
  List<String> _selectedBrands = [];

  // Constants for consistent styling
  static const Color _primaryColor = Color(0xFF141414);
  static const Color _fillColor = Color(0xFFF2F2F2);
  static const Color _hintColor = Colors.grey;
  static const Color _dropdownIconColor = Color(0xFF757575);
  static const Color _whiteColor = Colors.white;
  static const Color _blackColor = Colors.black;
  static const Color _redColor = Colors.red;
  static const Color _greenColor = Colors.green;

  final List<String> _districts = [
    'Select district',
    'Malappuram',
    'Kozhikode',
    'Thrissur',
    'Kannur',
    'Kasaragod'
  ];

  final List<String> _brands = [
    'Select brand',
    'Brand A',
    'Brand B',
    'Brand C',
    'Brand D',
    'Brand E'
  ];

  @override
  void initState() {
    super.initState();
    _initializeFormData();
  }

  void _initializeFormData() {
    final data = widget.dealerData;
    _dealerNameController.text = data['name'] ?? '';
    _shopNameController.text = data['shop'] ?? data['shopName'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _townController.text = data['town'] ?? '';
    _addressController.text = data['address'] ?? '';

    // Initialize district
    String district = data['district'] ?? '';
    _selectedDistrict = _districts.contains(district) ? district : _districts.first;

    // Initialize brands
    _selectedBrand = _brands.first;
    if (data['brands'] != null) {
      _selectedBrands = List<String>.from(data['brands']);
    }
  }

  @override
  void dispose() {
    _dealerNameController.dispose();
    _shopNameController.dispose();
    _phoneController.dispose();
    _townController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _whiteColor,
      appBar: _buildAppBar(),
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.04,
          vertical: screenHeight * 0.015,
        ),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildProfileImageSection(),
                        _buildTextField('Dealer Name', 'Enter dealer name', _dealerNameController),
                        _buildTextField('Shop Name', 'Enter shop name', _shopNameController),
                        _buildTextField(
                          'Phone Number',
                          'Enter phone number',
                          _phoneController,
                          keyboardType: TextInputType.phone,
                          digitsOnly: true,
                        ),
                        _buildTextField('Town', 'Enter town', _townController),
                        _buildDistrictDropdown(),
                        _buildAddressField(),
                        _buildBrandSelectionSection(),
                        SizedBox(height: screenHeight * 0.02),
                        _buildSubmitButton(),
                        SizedBox(height: screenHeight * 0.02),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: _whiteColor,
      elevation: 0,
      leading: IconButton(
        icon: SvgPicture.asset(AppIcons.back_Arrow,width: screenWidth*0.07,),
        onPressed: () => Navigator.pop(context),
      ),
      // title: const Text('Edit Dealer', style: AppTheme.appTitle1),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.save, color: _primaryColor),
          onPressed: _handleSave,
        ),
      ],
    );
  }

  Widget _buildProfileImageSection() {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.015),
      child: Row(
        children: [
          CircleAvatar(
            radius: screenWidth * 0.05,
            backgroundImage: NetworkImage(
              widget.dealerData['image'] ??
                  'https://lh3.googleusercontent.com/aida-public/AB6AXuCBpqqTE0DINkLq4wycMpIPuldm5_mQ4d2PFkG-KyHYN7f0Z03jpkozeklIu6OSKsyf6wJGx1BhY4VESlWxvpwbSqUNBYE5qP2dDd2xihOBEpekIk1ZRw00MDJbWOO9xM1dwTwwol1W5GBPaXw_Ir8sxNa4Iv4WIhzuuDZurHQVsDYBkMLsAe0DbvxmmSPeEr_YzqVqrQLMgUyP-7afaBNsPWS8vRvHA-HJSSafBtosaCckRVYt3eiGLKAID2TW2jQTOoYHfyLjSK0',
            ),
          ),
          SizedBox(width: screenWidth * 0.04),
          Text(
            'Profile Image',
            style: TextStyle(
              fontSize: screenWidth * 0.04,
              color: _primaryColor,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField(
      String label,
      String placeholder,
      TextEditingController controller, {
        TextInputType keyboardType = TextInputType.text,
        bool digitsOnly = false,
      }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text(label, style: AppTheme.normalText1),
          SizedBox(height: screenHeight * 0.008),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
            decoration: _getInputDecoration(placeholder),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text('Address', style: AppTheme.normalText1),
          SizedBox(height: screenHeight * 0.008),
          TextFormField(
            controller: _addressController,
            maxLines: 5,
            textAlignVertical: TextAlignVertical.top,
            validator: (value) => value == null || value.isEmpty ? 'Please enter address' : null,
            decoration: _getInputDecoration('Enter address'),
          ),
        ],
      ),
    );
  }

  Widget _buildDistrictDropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text('District', style: AppTheme.normalText1),
          SizedBox(height: screenHeight * 0.008),
          DropdownButtonFormField<String>(
            value: _selectedDistrict,
            decoration: _getInputDecoration('Select district'),
            icon: const Icon(Icons.expand_more, color: _dropdownIconColor),
            dropdownColor: _whiteColor,
            // style: AppTheme.normalText1,
            items: _districts.map((String district) {
              return DropdownMenuItem<String>(
                value: district,
                child: Text(district),
              );
            }).toList(),
            onChanged: (value) {
              setState(() => _selectedDistrict = value);
            },
            validator: (value) => (value == _districts.first)
                ? 'Please select a valid district'
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildBrandSelectionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildBrandDropdown(),
        if (_selectedBrands.isNotEmpty) ...[
          SizedBox(height: screenHeight * 0.01),
          _buildSelectedBrandsSection(),
        ],
        SizedBox(height: screenHeight * 0.01),
      ],
    );
  }

  Widget _buildBrandDropdown() {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.01),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Text('Select Brands', style: AppTheme.normalText1),
          SizedBox(height: screenHeight * 0.008),
          DropdownButtonFormField<String>(
            value: _selectedBrand,
            decoration: _getInputDecoration('Select brand to add'),
            icon: const Icon(Icons.expand_more, color: _dropdownIconColor),
            dropdownColor: _whiteColor,
            // style: AppTheme.normalText1,
            items: _brands.map((String brand) {
              return DropdownMenuItem<String>(
                value: brand,
                child: Text(brand),
                enabled: brand == _brands.first || !_selectedBrands.contains(brand),
              );
            }).toList(),
            onChanged: (value) {
              if (value != null && value != _brands.first && !_selectedBrands.contains(value)) {
                setState(() {
                  _selectedBrands.add(value);
                  _selectedBrand = _brands.first;
                });
              }
            },
            validator: null, // No validation needed for brand selection dropdown
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBrandsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text(
        //   'Selected Brands (${_selectedBrands.length})',
        //   style: AppTheme.normalText1?.copyWith(
        //     fontWeight: FontWeight.w600,
        //     color: _primaryColor,
        //   ),
        // ),
        SizedBox(height: screenHeight * 0.008),
        Container(
          width: double.infinity,
          padding: EdgeInsets.all(screenWidth * 0.03),
          decoration: BoxDecoration(
            color: _fillColor,
            borderRadius: BorderRadius.circular(screenWidth * 0.02),
            border: Border.all(color: _fillColor, width: 1),
          ),
          child: _selectedBrands.isEmpty
              ? Text(
            'No brands selected',
            style: TextStyle(
              color: _hintColor,
              fontSize: screenWidth * 0.035,
            ),
          )
              : Wrap(
            spacing: screenWidth * 0.02,
            runSpacing: screenHeight * 0.008,
            children: _selectedBrands.map((brand) {
              return _buildBrandChip(brand);
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildBrandChip(String brand) {
    return Chip(
      label: Text(
        brand,
        style: TextStyle(
          fontSize: screenWidth * 0.032,
          fontWeight: FontWeight.w500,
          color: _primaryColor,
        ),
      ),
      deleteIcon: Icon(
        Icons.close,
        size: screenWidth * 0.04,
        color: _redColor,
      ),
      onDeleted: () {
        setState(() {
          _selectedBrands.remove(brand);
        });
      },
      backgroundColor: _whiteColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        side: BorderSide(color: _primaryColor.withOpacity(0.2), width: 1),
      ),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.06,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: _blackColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(screenWidth * 0.03),
          ),
          elevation: 2,
        ),
        onPressed: _handleSubmit,
        child: Text(
          'Update Dealer',
          style: TextStyle(
            color: _whiteColor,
            fontWeight: FontWeight.bold,
            fontSize: screenWidth * 0.04,
          ),
        ),
      ),
    );
  }

  InputDecoration _getInputDecoration(String hintText) {
    return InputDecoration(
      filled: true,
      fillColor: _fillColor,
      hintText: hintText,
      hintStyle: TextStyle(
        color: _hintColor,
        fontSize: screenWidth * 0.035,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(screenWidth * 0.02),
        borderSide: BorderSide.none,
      ),
      contentPadding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.015,
      ),
    );
  }

  void _handleSave() {
    // Implement save functionality
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Changes saved as draft!'),
        backgroundColor: _greenColor,
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBrands.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please select at least one brand'),
            backgroundColor: _redColor,
          ),
        );
        return;
      }

      // Create updated dealer data
      final updatedData = {
        'name': _dealerNameController.text,
        'shop': _shopNameController.text,
        'phone': _phoneController.text,
        'town': _townController.text,
        'district': _selectedDistrict,
        'address': _addressController.text,
        'brands': _selectedBrands,
        'id': widget.dealerData['id'], // Preserve original ID
        'image': widget.dealerData['image'], // Preserve original image
        'totalOrders': widget.dealerData['totalOrders'], // Preserve original order count
      };

      // Print updated data for debugging
      debugPrint('Updated Dealer Data: $updatedData');

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Dealer updated successfully!'),
          backgroundColor: _greenColor,
        ),
      );

      // Optionally navigate back with updated data
      Navigator.pop(context, updatedData);
    }
  }
}