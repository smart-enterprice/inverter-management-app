// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:inverter_management_app/screen/loadingScreen.dart';
// import '../../../core/const/icons.dart';
// import '../../../core/media_query/media_query.dart';
// import '../../../core/theme/theme.dart';
// import '../../../model/brand_model.dart';
// import '../controller/brand_controller.dart';
//
// class EditBrandScreen extends ConsumerStatefulWidget {
//   final BrandModel brand;
//   const EditBrandScreen({super.key, required this.brand});
//
//   @override
//   ConsumerState<EditBrandScreen> createState() => _EditBrandScreenState();
// }
//
// class _EditBrandScreenState extends ConsumerState<EditBrandScreen> {
//   final _formKey = GlobalKey<FormState>();
//   late TextEditingController _nameController;
//   late TextEditingController _descriptionController;
//   late TextEditingController _modelController;
//   late List<String> _models;
//   late String _selectedStatus;
//
//   final List<String> _statusOptions = ['active', 'inactive'];
//
//   @override
//   void initState() {
//     super.initState();
//     _nameController = TextEditingController(text: widget.brand.brandName);
//     _descriptionController =
//         TextEditingController(text: widget.brand.description);
//     _modelController = TextEditingController();
//     _models = List<String>.from(widget.brand.brandModels);
//     _selectedStatus = widget.brand.status ?? 'active';
//   }
//
//   @override
//   void dispose() {
//     _nameController.dispose();
//     _descriptionController.dispose();
//     _modelController.dispose();
//     super.dispose();
//   }
//
//   void _addModel() {
//     final model = _modelController.text.trim();
//     if (model.isNotEmpty) {
//       setState(() {
//         _models.add(model);
//         _modelController.clear();
//       });
//     }
//   }
//    final List<String> _deletedModels = [];
//   void _removeModel(String model) {
//     setState(() {
//       _models.remove(model);
//       _deletedModels.add(model);
//     });
//   }
//
//   Future<void> _handleSubmit() async {
//     print('Models to update: $_models');
//     print('Models to delete: $_deletedModels'); // Add this for debugging
//
//     if (_formKey.currentState!.validate()) {
//       final updatedBrand = widget.brand.copyWith(
//         brandName: _nameController.text.trim(),
//         description: _descriptionController.text.trim(),
//         brandModels: _models,
//         status: _selectedStatus,
//       );
//
//       final controller = ref.read(loadBrandsControllerProvider.notifier);
//
//       showDialog(
//         context: context,
//         barrierDismissible: false,
//         builder: (_) => const Center(child: GlobalLoader()),
//       );
//
//       // Pass deletedModels parameter correctly
//       await controller.updateBrand(
//           updatedBrand,
//           updatedBrand.brandName,
//           deletedModels: _deletedModels  // This should now work properly
//       );
//
//       Navigator.pop(context); // close loader
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//             content: Text('Brand updated successfully!'),
//             backgroundColor: Colors.green),
//       );
//       Navigator.pop(context, updatedBrand);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final theme = Theme.of(context);
//
//     return Scaffold(
//       backgroundColor: theme.scaffoldBackgroundColor,
//       appBar: AppBar(
//         surfaceTintColor: Colors.transparent,
//         backgroundColor: theme.scaffoldBackgroundColor,
//         elevation: 0,
//         centerTitle: true,
//         title: Text('Edit Brand',
//             style: theme.textTheme.bodyLarge
//                 ?.copyWith(fontWeight: FontWeight.bold)),
//         leading: IconButton(
//           padding: EdgeInsets.only(left: Screen.w(context) * 0.04),
//           icon: SvgPicture.asset(
//             AppIcons.back_Arrow,
//             width: Screen.w(context) * 0.07,
//             colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
//           ),
//           onPressed: () => Navigator.pop(context),
//         ),
//       ),
//       body: Padding(
//         padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
//         child: SingleChildScrollView(
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 // _buildInputField(
//                 //   label: 'Brand Name',
//                 //   hint: 'Enter brand name',
//                 //   controller: _nameController,
//                 // ),
//                 _buildInputField(
//                   label: 'Description',
//                   hint: 'Enter description',
//                   controller: _descriptionController,
//                   maxLines: 3,
//                 ),
//                 _buildModelsSection(),
//                 _buildStatusDropdown(),
//                 SizedBox(height: screenHeight * 0.03),
//                 _buildSubmitButton(_handleSubmit),
//                 SizedBox(height: screenHeight * 0.02),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInputField({
//     required String label,
//     required String hint,
//     required TextEditingController controller,
//     TextInputType keyboardType = TextInputType.text,
//     int maxLines = 1,
//   }) {
//     return Padding(
//       padding: EdgeInsets.only(bottom: screenHeight * 0.02),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(label, style: Theme.of(context).textTheme.bodyLarge),
//           SizedBox(height: screenHeight * 0.008),
//           TextFormField(
//             controller: controller,
//             keyboardType: keyboardType,
//             maxLines: maxLines,
//             validator: (value) {
//               if (value == null || value.trim().isEmpty) {
//                 return 'Please enter $label';
//               }
//               return null;
//             },
//             decoration: InputDecoration(
//               hintText: hint,
//               border: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(screenWidth * 0.03),
//               ),
//               enabledBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                 borderSide: BorderSide(color: Colors.grey.shade400),
//               ),
//               focusedBorder: OutlineInputBorder(
//                 borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                 borderSide:
//                 BorderSide(color: Theme.of(context).primaryColor, width: 2),
//               ),
//               contentPadding: EdgeInsets.symmetric(
//                   horizontal: screenWidth * 0.04,
//                   vertical: screenHeight * 0.018),
//               hintStyle: TextStyle(
//                   fontSize: screenWidth * 0.038, color: Colors.grey[500]),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildModelsSection() {
//     return Padding(
//       padding: EdgeInsets.only(bottom: screenHeight * 0.02),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Brand Models', style: Theme.of(context).textTheme.bodyLarge),
//           SizedBox(height: screenHeight * 0.008),
//           Row(
//             children: [
//               Expanded(
//                 child: TextFormField(
//                   controller: _modelController,
//                   decoration: InputDecoration(
//                     hintText: "Add a model",
//                     border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                     ),
//                   ),
//                 ),
//               ),
//               IconButton(
//                 icon: const Icon(Icons.add, color: AppTheme.primaryColor),
//                 onPressed: _addModel,
//               ),
//             ],
//           ),
//           Wrap(
//             spacing: 8,
//             children: _models.map((model) {
//               return Chip(
//                 backgroundColor: Theme.of(context).primaryColor,
//                 labelStyle: TextStyle(color: Colors.white),
//                 iconTheme: IconThemeData(color: Colors.white),
//                 label: Text(model),
//                 onDeleted: () => _removeModel(model),
//               );
//             }).toList(),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatusDropdown() {
//     return Padding(
//       padding: EdgeInsets.only(bottom: screenHeight * 0.02),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text('Status', style: Theme.of(context).textTheme.bodyLarge),
//           SizedBox(height: screenHeight * 0.008),
//           GestureDetector(
//             onTap: () => _showStatusDialog(),
//             child: Container(
//               decoration: BoxDecoration(
//                 borderRadius: BorderRadius.circular(screenWidth * 0.03),
//                 border: Border.all(color: Colors.grey.shade400),
//               ),
//               padding: EdgeInsets.symmetric(
//                   horizontal: screenWidth * 0.04,
//                   vertical: screenHeight * 0.018),
//               child: Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   Text(
//                     _selectedStatus,
//                     style: TextStyle(
//                       fontSize: screenWidth * 0.038,
//                       color: Colors.black,
//                     ),
//                   ),
//                   const Icon(Icons.arrow_drop_down),
//                 ],
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   void _showStatusDialog() {
//     showDialog(
//       context: context,
//       builder: (context) => AlertDialog(
//         backgroundColor: Colors.white,
//         shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(screenWidth * 0.03)),
//         title: const Text("Select Status"),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: _statusOptions.map((status) {
//             return RadioListTile<String>(
//               title: Text(status),
//               value: status,
//               groupValue: _selectedStatus,
//               onChanged: (value) {
//                 setState(() => _selectedStatus = value!);
//                 Navigator.pop(context);
//               },
//             );
//           }).toList(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSubmitButton(VoidCallback onTap) {
//     return SizedBox(
//       width: screenWidth * 0.5,
//       height: screenHeight * 0.06,
//       child: ElevatedButton(
//         onPressed: onTap,
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Theme.of(context).primaryColor,
//         ),
//         child: const Text(
//           'Update',
//           style: TextStyle(
//               color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
//         ),
//       ),
//     );
//   }
// }
