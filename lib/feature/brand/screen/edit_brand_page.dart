import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/brand_model.dart';
import '../controller/brand_controller.dart';

class EditBrandScreen extends ConsumerStatefulWidget {
  final BrandModel brand;
  const EditBrandScreen({super.key, required this.brand});

  @override
  ConsumerState<EditBrandScreen> createState() => _EditBrandScreenState();
}

class _EditBrandScreenState extends ConsumerState<EditBrandScreen> {
  late TextEditingController nameController;
  late TextEditingController descriptionController;
  late TextEditingController modelController;
  late List<String> models;
  late String selectedStatus;

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.brand.brandName);
    descriptionController = TextEditingController(text: widget.brand.description);
    modelController = TextEditingController();
    models = List<String>.from(widget.brand.brandModels);
    selectedStatus = widget.brand.status ?? 'active';
  }

  @override
  void dispose() {
    nameController.dispose();
    descriptionController.dispose();
    modelController.dispose();
    super.dispose();
  }

  void addModel() {
    final model = modelController.text.trim();
    if (model.isNotEmpty) {
      setState(() {
        models.add(model);
        modelController.clear();
      });
    }
  }

  void removeModel(String model) {
    setState(() {
      models.remove(model);
    });
  }

  void submit() {
    final BrandModel updatedBrand = widget.brand.copyWith(
      brandName: nameController.text.trim(),
      description: descriptionController.text.trim(),
      brandModels: models,
      status: selectedStatus,
    );

    // ✅ Use updatedBrand directly
    ref.read(brandControllerProvider.notifier).updateBrand(updatedBrand,updatedBrand.brandName);

    Navigator.pop(context, updatedBrand);
  }



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Edit Brand"),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Brand Name
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Brand Name"),
            ),

            SizedBox(height: screenHeight * 0.02),

            /// Description
            TextField(
              controller: descriptionController,
              decoration: const InputDecoration(labelText: "Description"),
              maxLines: 2,
            ),

            SizedBox(height: screenHeight * 0.02),

            /// Brand Models Input
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: modelController,
                    decoration: const InputDecoration(labelText: "Add Model"),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add),
                  onPressed: addModel,
                ),
              ],
            ),

            Wrap(
              spacing: 8,
              children: models.map((model) {
                return Chip(
                  label: Text(model),
                  onDeleted: () => removeModel(model),
                );
              }).toList(),
            ),

            SizedBox(height: screenHeight * 0.02),

            /// Status Dropdown
            DropdownButtonFormField<String>(
              value: selectedStatus,
              decoration: const InputDecoration(labelText: "Status"),
              items: ['active', 'inactive'].map((value) {
                return DropdownMenuItem(
                  value: value,
                  child: Text(value.toUpperCase()),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedStatus = value!);
              },
            ),

            SizedBox(height: screenHeight * 0.05),

            /// Save Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: submit,
                child: const Text("Save"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
