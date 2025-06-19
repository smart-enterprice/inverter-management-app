import 'package:flutter/material.dart';
import '../core/media_query/media_query.dart';
import '../core/theme/theme.dart';
import '../widgets/add_button.dart';

class EditUserScreen extends StatefulWidget {
  final String name;
  final String email;
  final String phone;
  final String role;

  const EditUserScreen({
    super.key,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
  });

  @override
  State<EditUserScreen> createState() => _EditUserScreenState();
}

class _EditUserScreenState extends State<EditUserScreen> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late String _email;
  late String _phone;
  late String _selectedRole;

  final List<String> _roles = [
    'Admin',
    'Salesman',
    'Production',
    'Packing',
    'Accounts',
    'Delivery'
  ];

  @override
  void initState() {
    super.initState();
    _name = widget.name;
    _email = widget.email;
    _phone = widget.phone;
    _selectedRole = widget.role;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: AppBar(
        title: Text('Edit User', style: AppTheme.appTitle1),
        centerTitle: true,
        backgroundColor: AppTheme.backgroundColor,
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Edit Details', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                SizedBox(height: screenHeight * 0.03),
                TextFormField(
                  initialValue: _name,
                  decoration: _inputDecoration('Name', Icons.person),
                  validator: _requiredValidator,
                  onSaved: (value) => _name = value!,
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  initialValue: _email,
                  decoration: _inputDecoration('Email', Icons.email),
                  validator: _emailValidator,
                  onSaved: (value) => _email = value!,
                ),
                SizedBox(height: screenHeight * 0.02),
                TextFormField(
                  initialValue: _phone,
                  decoration: _inputDecoration('Phone', Icons.phone),
                  validator: _phoneValidator,
                  onSaved: (value) => _phone = value!,
                ),
                SizedBox(height: screenHeight * 0.02),
                const Text('Select Role', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
                ..._roles.map((role) {
                  return RadioListTile<String>(
                    title: Text(role),
                    value: role,
                    groupValue: _selectedRole,
                    onChanged: (value) {
                      setState(() => _selectedRole = value!);
                    },
                    contentPadding: EdgeInsets.zero,
                  );
                }),
                SizedBox(height: screenHeight * 0.03),
                SizedBox(
                  width: screenWidth * 0.33,
                  child: AddButton(
                    text: 'Update',
                    onTap: () {
                      if (_formKey.currentState!.validate()) {
                        _formKey.currentState!.save();
                        // 🔁 Replace with your update logic
                        print('Updated: $_name, $_email, $_phone, $_selectedRole');
                        Navigator.pop(context);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8.0)),
    );
  }

  String? _requiredValidator(String? value) =>
      (value == null || value.isEmpty) ? 'Please enter this field' : null;

  String? _emailValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter an email';
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _phoneValidator(String? value) {
    if (value == null || value.isEmpty) return 'Please enter a phone number';
    if (!RegExp(r'^\+?[\d\s-]{10,}$').hasMatch(value)) return 'Invalid phone';
    return null;
  }
}
