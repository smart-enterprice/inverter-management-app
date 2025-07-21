// import 'package:flutter/material.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:inverter_management_app/core/const/icons.dart';
// import 'package:inverter_management_app/core/media_query/media_query.dart';
// import 'package:inverter_management_app/core/theme/theme.dart';
// import 'edit_dealer_screen.dart';
//
// class DealerView extends StatelessWidget {
//   final Map<String, dynamic> dealer;
//
//   const DealerView({super.key, required this.dealer});
//
//   // Constants for consistent styling
//   static const Color _primaryColor = Colors.black;
//   static const Color _whiteColor = Colors.white;
//   static const Color _editColor = Colors.blue;
//   static const Color _deleteColor = Colors.red;
//   static const Color _buttonBackgroundColor = Colors.white60;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _whiteColor,
//       appBar: _buildAppBar(context),
//       body: _buildBody(),
//     );
//   }
//
//   PreferredSizeWidget _buildAppBar(BuildContext context) {
//     return AppBar(
//       backgroundColor: _whiteColor,
//       elevation: 0,
//       surfaceTintColor: Colors.transparent,
//       title: Text(
//         dealer['name'] ?? 'Dealer Details',
//         style: AppTheme.appTitle1,
//       ),
//       centerTitle: true,
//       iconTheme: const IconThemeData(color: _primaryColor),
//       leading: IconButton(
//         icon:  SvgPicture.asset(AppIcons.back_Arrow,width: screenWidth*0.07,),
//         onPressed: () => Navigator.pop(context),
//       ),
//       actions: [
//         _buildActionButton(
//           icon: AppIcons.edit,
//           color: _editColor,
//           onPressed: () => _handleEdit(context),
//         ),
//         _buildActionButton(
//           icon: AppIcons.delete,
//           color: _deleteColor,
//           onPressed: () => _handleDelete(context),
//         ),
//         SizedBox(width: screenWidth * 0.02),
//       ],
//     );
//   }
//
//   Widget _buildActionButton({
//     required String icon,
//     required Color color,
//     required VoidCallback onPressed,
//   }) {
//     return Padding(
//       padding: EdgeInsets.only(right: screenWidth * 0.02),
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _buttonBackgroundColor,
//           shape: const CircleBorder(),
//           padding: EdgeInsets.all(screenWidth * 0.025),
//           elevation: 2,
//           shadowColor: Colors.black26,
//         ),
//         onPressed: onPressed,
//         child: SvgPicture.asset(
//           icon,
//           width: screenWidth * 0.05,
//           height: screenWidth * 0.05,
//           colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildBody() {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(height: screenHeight * 0.02),
//             _buildSectionHeader('Dealer Information'),
//             SizedBox(height: screenHeight * 0.02),
//             _buildDealerPhoto(),
//             SizedBox(height: screenHeight * 0.03),
//             _buildDealerInfo(),
//             SizedBox(height: screenHeight * 0.03),
//             _buildCallButton(),
//             SizedBox(height: screenHeight * 0.02),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title) {
//     return Text(
//       title,
//       style: AppTheme.normalText5?.copyWith(
//         fontWeight: FontWeight.w600,
//         color: _primaryColor,
//       ),
//     );
//   }
//
//   Widget _buildDealerPhoto() {
//     return Center(
//       child: Container(
//         width: screenWidth * 0.4,
//         height: screenWidth * 0.4,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           boxShadow: [
//             BoxShadow(
//               color: Colors.black.withOpacity(0.1),
//               spreadRadius: 2,
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: ClipOval(
//           child: Image.network(
//             dealer['image'] ?? '',
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) {
//               return _buildPlaceholderImage();
//             },
//             loadingBuilder: (context, child, loadingProgress) {
//               if (loadingProgress == null) return child;
//               return _buildLoadingImage();
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPlaceholderImage() {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.grey.shade200,
//       ),
//       child: Icon(
//         Icons.person,
//         size: screenWidth * 0.15,
//         color: Colors.grey.shade400,
//       ),
//     );
//   }
//
//   Widget _buildLoadingImage() {
//     return Container(
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.grey.shade200,
//       ),
//       child: Center(
//         child: SizedBox(
//           width: screenWidth * 0.08,
//           height: screenWidth * 0.08,
//           child: const CircularProgressIndicator(
//             strokeWidth: 2,
//             valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDealerInfo() {
//     final List<InfoItem> infoItems = [
//       InfoItem('Dealer Name', dealer['name']),
//       InfoItem('Shop Name', dealer['shop']),
//       InfoItem('Address', dealer['address']),
//       InfoItem('Town', dealer['town']),
//       InfoItem('District', dealer['district']),
//       InfoItem('Dealer ID', dealer['id']),
//       InfoItem('Total Orders', dealer['totalOrders']?.toString() ?? '0'),
//       InfoItem('Phone Number', dealer['phone']),
//       InfoItem('Brands', _formatBrands(dealer['brands'])),
//     ];
//
//     return Card(
//       elevation: 2,
//       color: _whiteColor,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(screenWidth * 0.03),
//       ),
//       child: Padding(
//         padding: EdgeInsets.all(screenWidth * 0.04),
//         child: Column(
//           children: infoItems
//               .where((item) => item.value != null && item.value!.isNotEmpty)
//               .map((item) => _buildInfoRow(item.label, item.value!))
//               .toList(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(
//             flex: 2,
//             child: Text(
//               label,
//               style: AppTheme.appTitle1.copyWith(
//                 fontWeight: FontWeight.w600,
//                 color: _primaryColor,
//               ),
//             ),
//           ),
//           SizedBox(width: screenWidth * 0.02),
//           Expanded(
//             flex: 3,
//             child: Text(
//               value,
//               style: AppTheme.normalText1.copyWith(
//                 color: Colors.grey.shade700,
//               ),
//               textAlign: TextAlign.right,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCallButton() {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: _primaryColor,
//           shape: RoundedRectangleBorder(
//             borderRadius: BorderRadius.circular(screenWidth * 0.03),
//           ),
//           padding: EdgeInsets.symmetric(
//             horizontal: screenWidth * 0.08,
//             vertical: screenHeight * 0.018,
//           ),
//           elevation: 3,
//         ),
//         onPressed: () => _handleCall(),
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(
//               Icons.phone,
//               color: _whiteColor,
//               size: screenWidth * 0.05,
//             ),
//             SizedBox(width: screenWidth * 0.02),
//             Text(
//               'Call Dealer',
//               style: AppTheme.normalText2.copyWith(
//                 color: _whiteColor,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatBrands(dynamic brands) {
//     if (brands == null) return 'N/A';
//     if (brands is List) {
//       return brands.isNotEmpty ? brands.join(', ') : 'N/A';
//     }
//     return brands.toString();
//   }
//
//   void _handleEdit(BuildContext context) {
//     Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (context) => EditDealerScreen(dealerData: dealer),
//       ),
//     );
//   }
//
//   void _handleDelete(BuildContext context) {showDialog(
//     context: context,
//     barrierDismissible: false, // Prevent accidental dismissal
//     builder: (BuildContext context) {
//       return AlertDialog(
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(16),
//         ),
//         title: Row(
//           children: [
//             Icon(
//               Icons.warning_amber_rounded,
//               color: Theme.of(context).colorScheme.error,
//               size: 24,
//             ),
//             const SizedBox(width: 12),
//             const Text(
//               'Delete Dealer',
//               style: TextStyle(
//                 fontSize: 18,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ],
//         ),
//         content: Column(
//           mainAxisSize: MainAxisSize.min,
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             const Text(
//               'Are you sure you want to delete this dealer?',
//               style: TextStyle(fontSize: 16),
//             ),
//             const SizedBox(height: 8),
//             Text(
//               'This action cannot be undone.',
//               style: TextStyle(
//                 fontSize: 14,
//                 color: Theme.of(context).colorScheme.onSurfaceVariant,
//                 fontStyle: FontStyle.italic,
//               ),
//             ),
//           ],
//         ),
//         actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(context).pop(),
//             style: TextButton.styleFrom(
//               padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//             ),
//             child: const Text(
//               'Cancel',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w500,
//               ),
//             ),
//           ),
//            SizedBox(width: screenWidth * 0.02),
//           ElevatedButton(
//             onPressed: () {
//               Navigator.of(context).pop();
//               _performDelete();
//             },
//             style: ElevatedButton.styleFrom(
//               backgroundColor: Theme.of(context).colorScheme.error,
//               foregroundColor: Theme.of(context).colorScheme.onError,
//               padding: EdgeInsets.symmetric(
//                 horizontal: (screenWidth * 0.05).clamp(16.0, 32.0),  // Min 16, Max 32
//                 vertical: (screenHeight * 0.02).clamp(12.0, 24.0),   // Min 12, Max 24
//               ),
//               shape: RoundedRectangleBorder(
//                 borderRadius: BorderRadius.circular(8),
//               ),
//               elevation: 2,
//             ),
//             child: const Text(
//               'Delete',
//               style: TextStyle(
//                 fontSize: 16,
//                 fontWeight: FontWeight.w600,
//               ),
//             ),
//           ),
//         ],
//       );
//     },
//   );
//   }
//
//   void _performDelete() {
//     // Implement actual delete logic here
//     debugPrint('Deleting dealer: ${dealer['name']}');
//   }
//
//   void _handleCall() {
//     final phoneNumber = dealer['phone'];
//     if (phoneNumber != null && phoneNumber.isNotEmpty) {
//       // Implement call functionality
//       debugPrint('Calling: $phoneNumber');
//     } else {
//       debugPrint('No phone number available');
//     }
//   }
// }
//
// // Helper class for better code organization
// class InfoItem {
//   final String label;
//   final String? value;
//
//   InfoItem(this.label, this.value);
// }