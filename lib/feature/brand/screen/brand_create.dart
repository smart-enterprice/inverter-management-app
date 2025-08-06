import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import '../../../core/const/icons.dart';
import '../../../model/brand_model.dart';
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final models = _modelControllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    final newBrand = BrandModel(
      brandName: _nameController.text.trim(),
      description: _descController.text.trim(),
      brandModels: models,
    );

    try {
      await ref.read(brandControllerProvider.notifier).createBrand(newBrand);
      if (mounted) Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
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
            inputFormatters:
            digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            validator: (value) {
              if (value == null || value.trim().isEmpty) return 'Please enter $label';
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
                borderSide: BorderSide(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  width: 1,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: BorderSide(
                  color: Theme.of(context).primaryColor,
                  width: 2,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(screenWidth * 0.03),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              contentPadding: EdgeInsets.symmetric(
                horizontal: screenWidth * 0.04,
                vertical: screenHeight * 0.018,
              ),
              hintStyle: TextStyle(
                fontSize: screenWidth * 0.038,
                color: Colors.grey[500],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        surfaceTintColor: Colors.transparent,
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        elevation: 1,
        leading: IconButton(
          padding: EdgeInsets.only(left: screenWidth * 0.04),
          icon: SvgPicture.asset(
            AppIcons.back_Arrow,
            width: screenWidth * 0.07,
            colorFilter: ColorFilter.mode(
              Theme.of(context).primaryColor,
              BlendMode.srcIn,
            ),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Text(
          'Create Brand',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Form(
          key: _formKey,
          child: ListView(
            children: [
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
              Text('Brand Models', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: screenHeight * 0.01),

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
                  icon: const Icon(Icons.add),
                  label: const Text('Add Model'),
                ),
              ),

              SizedBox(height: screenHeight * 0.03),
              SizedBox(
                width: screenWidth * 0.5,
                height: screenHeight*0.06,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).primaryColor,
                  ),
                  onPressed: _isLoading ? null : _createBrand,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      :  Text('Create Brand',style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w500)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
