import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/theme/theme.dart';

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
    final data = widget.dealerData;
    _dealerNameController.text = data['name'] ?? '';
    _shopNameController.text = data['shopName'] ?? '';
    _phoneController.text = data['phone'] ?? '';
    _townController.text = data['town'] ?? '';
    _addressController.text = data['address'] ?? '';
    _selectedDistrict = data['district'] ?? _districts.first;
    _selectedBrand = _brands.first;
    _selectedBrands = List<String>.from(data['brands'] ?? []);
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF141414)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Edit Dealer', style: AppTheme.appTitle1),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF141414)),
            onPressed: (){},
          ),
        ],
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04, vertical: screenHeight * 0.015),
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        _buildTextField('Dealer Name', 'Enter dealer name', _dealerNameController),
                        _buildTextField('Shop Name', 'Enter shop name', _shopNameController),
                        _buildTextField('Phone Number', 'Enter phone number', _phoneController,
                            keyboardType: TextInputType.phone, digitsOnly: true),
                        _buildTextField('Town', 'Enter town', _townController),
                        _buildDropdownField('District', _selectedDistrict!, _districts, (value) {
                          setState(() => _selectedDistrict = value);
                        }, validatorMessage: 'Please select a valid district'),
                        _buildAddressField(),
                        _buildDropdownField('Select a Brand to Add', _selectedBrand!, _brands, (value) {
                          if (value != null && value != _brands.first && !_selectedBrands.contains(value)) {
                            setState(() {
                              _selectedBrands.add(value);
                              _selectedBrand = _brands.first;
                            });
                          }
                        }),
                        _buildSelectedBrands(),
                        SizedBox(height: screenWidth * 0.02),
                        _buildSubmitButton(),
                        SizedBox(height: screenWidth * 0.02),
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

  Widget _buildTextField(String label, String placeholder, TextEditingController controller,
      {TextInputType keyboardType = TextInputType.text, bool digitsOnly = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.017),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.normalText1),
          SizedBox(height: screenHeight * 0.006),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            validator: (value) => value == null || value.isEmpty ? 'Please enter $label' : null,
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xFFF2F2F2),
              hintText: placeholder,
              hintStyle: TextStyle(color: Colors.grey),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddressField() {
    return Padding(
      padding: EdgeInsets.only(bottom: screenWidth * 0.02),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Address', style: AppTheme.normalText1),
          SizedBox(height: screenWidth * 0.007),
          TextFormField(
            controller: _addressController,
            maxLines: 5,
            textAlignVertical: TextAlignVertical.top,
            validator: (value) => value == null || value.isEmpty ? 'Please enter address' : null,
            decoration: InputDecoration(
              hintStyle: TextStyle(color: Colors.grey),
              hintText: 'Enter address',
              fillColor: const Color(0xFFF2F2F2),
              filled: true,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.02),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField(String label, String value, List<String> items, Function(String?) onChanged,
      {String? validatorMessage}) {
    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.017),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.006),
            child: Text(label, style: AppTheme.normalText1),
          ),
          Container(
            height: screenHeight * 0.055,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F2F2),
              borderRadius: BorderRadius.circular(screenWidth * 0.02),
            ),
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFFF2F2F2),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(screenWidth* 0.02),
                  borderSide: BorderSide.none,
                ),
                contentPadding: EdgeInsets.all(screenWidth * 0.03),
              ),
              icon: const Icon(Icons.expand_more, color: Color(0xFF757575)),
              dropdownColor: Colors.white,
              style: AppTheme.normalText1,
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(item, style: AppTheme.normalText1),
                );
              }).toList(),
              onChanged: onChanged,
              validator: (v) => (v == items.first) ? validatorMessage ?? 'Please select $label' : null,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectedBrands() {
    return Wrap(
      spacing: screenWidth * 0.02,
      children: _selectedBrands.map((brand) {
        return Chip(
          label: Text(brand),
          deleteIcon: const Icon(Icons.close, size: 18),
          onDeleted: () {
            setState(() {
              _selectedBrands.remove(brand);
            });
          },
        );
      }).toList(),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: screenHeight * 0.055,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
        ),
        onPressed: _handleSubmit,
        child: const Text('Update Dealer', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  void _handleSubmit() {
    if (_formKey.currentState!.validate()) {
      if (_selectedBrands.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select at least one brand'), backgroundColor: Colors.red),
        );
        return;
      }
      print('Updated Dealer Name: ${_dealerNameController.text}');
      print('Updated Brands: $_selectedBrands');
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dealer updated successfully!'), backgroundColor: Colors.green),
      );
    }
  }
}