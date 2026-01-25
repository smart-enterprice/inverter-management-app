import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import '../../../core/const/icons.dart';
import '../../../model/brand_model.dart';
import '../../../widgets/circle_button.dart';
import '../controller/brand_controller.dart';

class BrandCreateScreen extends ConsumerStatefulWidget {
  const BrandCreateScreen({super.key});

  @override
  ConsumerState<BrandCreateScreen> createState() => _BrandCreateScreenState();
}

class _BrandCreateScreenState extends ConsumerState<BrandCreateScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descController = TextEditingController();
  final List<TextEditingController> _modelControllers = [];
  bool _autoValidate = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _modelControllers.add(TextEditingController());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    for (final controller in _modelControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  void _addModelField() {
    setState(() => _modelControllers.add(TextEditingController()));
  }

  void _removeModelField(int index) {
    setState(() {
      _modelControllers[index].dispose();
      _modelControllers.removeAt(index);
    });
  }

  void _createBrand() async {
    setState(() => _autoValidate = true); // Enable validation only on submit
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final models = _modelControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final uniqueModels = models.toSet();
    if (uniqueModels.length != models.length) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Duplicate model names are not allowed')),
      );
      return;
    }

    final newBrand = BrandModel(
      brandName: _nameController.text.trim(),
      description: _descController.text.trim(),
      brandModels: models,
    );

    final errorMessage = await ref.read(loadBrandsControllerProvider.notifier).createBrand(newBrand);

    setState(() => _isLoading = false);
    await ref.read(loadBrandsControllerProvider.notifier).loadBrands();
    if (errorMessage != null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
          ),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Brand created successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    }
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
            autovalidateMode: _autoValidate
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscureText,
            maxLines: maxLines,
            inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter $label';
              // if (label == 'Desc' && value.length != 10) return 'Please enter a valid 10-digit phone number';
              // if (label == 'Password' && value.length < 6) return 'Password must be at least 6 characters';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(Screen.w(context) * 0.04),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircularIconButton(
                        icon: Icons.arrow_back_ios_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      SizedBox(width: Screen.w(context) * 0.2),
                      Text(
                        'Create Brand',
                        style: TextStyle(
                          fontSize: Screen.w(context) * 0.05,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: Screen.h(context) * 0.03),
                  _buildInputField(
                    label: 'Brand Name',
                    hint: 'Enter brand name',
                    controller: _nameController,
                  ),
                  _buildInputField(
                    label: 'Description',
                    hint: 'Enter brand description',
                    controller: _descController,
                    maxLines: 3,
                  ),
                  Text('Brand Models', style: TextStyle(fontSize: 18,fontWeight: FontWeight.bold,color: Colors.black)),
                  SizedBox(height: Screen.h(context) * 0.01),
              
                  ..._modelControllers.asMap().entries.map((entry) {
                    final index = entry.key;
                    final controller = entry.value;
              
                    return Row(
                      children: [
                        Expanded(
                          child: _buildInputField(
                            label: 'Model ${index + 1}',
                            hint: 'Enter model name',
                            controller: controller,
                          ),
                        ),
                        if (_modelControllers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _removeModelField(index),
                          ),
                      ],
                    );
                  }),
              
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _addModelField,
                      icon:  Icon(Icons.add,color: Theme.of(context).primaryColor,),
                      label: Text('Add Model',style: TextStyle(color: Theme.of(context).primaryColor),),
                    ),
                  ),
              
                  SizedBox(height: Screen.h(context) * 0.03),
                  Center(
                    child: SizedBox(
                      width: Screen.w(context) * 0.5,
                      height: Screen.h(context)*0.06,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                        ),
                        onPressed: _isLoading ? null : _createBrand,
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            :  Text('Create Brand',style: TextStyle(color: Colors.white,fontSize: 16,fontWeight: FontWeight.bold),),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
