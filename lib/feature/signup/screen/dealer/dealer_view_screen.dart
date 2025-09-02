// import 'package:flutter/material.dart';
// import 'package:flutter_riverpod/flutter_riverpod.dart';
// import 'package:flutter_svg/svg.dart';
// import 'package:inverter_management_app/core/const/icons.dart';
// import 'package:inverter_management_app/core/media_query/media_query.dart';
// import 'package:inverter_management_app/core/theme/theme.dart';
// import 'package:inverter_management_app/model/user_model.dart';
// import '../../controller/signUp_controller.dart';
// import 'edit_dealer_screen.dart';
//
// class DealerView extends ConsumerWidget {
//   final UserModel dealer;
//
//   const DealerView({super.key, required this.dealer});
//
//   static const Color _whiteColor = Colors.white;
//   static const Color _deleteColor = Colors.red;
//
//   @override
//   Widget build(BuildContext context, WidgetRef ref) {
//     return Scaffold(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       appBar: _buildAppBar(context, ref),
//       body: _buildBody(context),
//     );
//   }
//
//   PreferredSizeWidget _buildAppBar(BuildContext context, WidgetRef ref) {
//     return AppBar(
//       backgroundColor: Theme.of(context).scaffoldBackgroundColor,
//       elevation: 0,
//       surfaceTintColor: Colors.transparent,
//       title: Text(
//         dealer.employeeName ?? 'Dealer Details',
//         style: AppTheme.appTitle1,
//       ),
//       centerTitle: true,
//       iconTheme: IconThemeData(color: Theme.of(context).primaryColor),
//       leading: IconButton(
//         icon: SvgPicture.asset(
//           AppIcons.back_Arrow,
//           width: screenWidth * 0.07,
//           colorFilter: ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
//         ),
//         onPressed: () => Navigator.pop(context),
//       ),
//       actions: [
//         _buildActionButton(
//           context: context,
//           icon: AppIcons.edit,
//           color: Theme.of(context).primaryColor,
//           onPressed: () => _handleEdit(context),
//         ),
//         _buildActionButton(
//           context: context,
//           icon: AppIcons.delete,
//           color: _deleteColor,
//           onPressed: () => _showDeleteDialog(context, ref, dealer.employeeName ?? 'Unknown', dealer.employeeId ?? ''),
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
//     required BuildContext context,
//   }) {
//     return Padding(
//       padding: EdgeInsets.only(right: screenWidth * 0.02),
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Theme.of(context).focusColor,
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
//   Widget _buildBody(BuildContext context) {
//     return SingleChildScrollView(
//       child: Padding(
//         padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             SizedBox(height: screenHeight * 0.02),
//             _buildSectionHeader('Dealer Information', context),
//             SizedBox(height: screenHeight * 0.02),
//             _buildDealerPhoto(),
//             SizedBox(height: screenHeight * 0.03),
//             _buildDealerInfo(context),
//             SizedBox(height: screenHeight * 0.03),
//             _buildCallButton(context),
//             SizedBox(height: screenHeight * 0.02),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildSectionHeader(String title, BuildContext context) {
//     return Text(
//       title,
//       style: Theme.of(context).textTheme.titleMedium,
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
//               color: Colors.black12,
//               spreadRadius: 2,
//               blurRadius: 8,
//               offset: const Offset(0, 4),
//             ),
//           ],
//         ),
//         child: ClipOval(
//           child: Image.network(
//             dealer.photo ?? '',
//             fit: BoxFit.cover,
//             errorBuilder: (context, error, stackTrace) => _buildPlaceholderImage(),
//             loadingBuilder: (context, child, loadingProgress) {
//               if (loadingProgress == null) return child;
//               return _buildLoadingImage(context);
//             },
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildPlaceholderImage() {
//     return Container(
//       decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
//       child: Icon(Icons.person, size: screenWidth * 0.15, color: Colors.grey.shade400),
//     );
//   }
//
//   Widget _buildLoadingImage(BuildContext context) {
//     return Container(
//       decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade200),
//       child: Center(
//         child: SizedBox(
//           width: screenWidth * 0.08,
//           height: screenWidth * 0.08,
//           child: CircularProgressIndicator(
//             strokeWidth: 2,
//             valueColor: AlwaysStoppedAnimation<Color>(Theme.of(context).primaryColor),
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDealerInfo(BuildContext context) {
//     final List<InfoItem> infoItems = [
//       InfoItem('Dealer Name', dealer.employeeName),
//       InfoItem('Shop Name', dealer.shopName),
//       InfoItem('Address', dealer.address),
//       InfoItem('Town', dealer.town),
//       InfoItem('District', dealer.district),
//       InfoItem('Dealer ID', dealer.employeeId),
//       InfoItem('Total Orders', "0"),
//       InfoItem('Phone Number', dealer.employeePhone),
//       InfoItem('Brands', _formatBrands(dealer.brand)),
//     ];
//
//     return Card(
//       elevation: 0.1,
//       color: Theme.of(context).focusColor,
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
//       child: Padding(
//         padding: EdgeInsets.all(screenWidth * 0.04),
//         child: Column(
//           children: infoItems
//               .where((item) => item.value != null && item.value!.isNotEmpty)
//               .map((item) => _buildInfoRow(item.label, item.value!, context))
//               .toList(),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildInfoRow(String label, String value, BuildContext context) {
//     return Padding(
//       padding: EdgeInsets.symmetric(vertical: screenHeight * 0.012),
//       child: Row(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Expanded(flex: 2, child: Text(label, style: Theme.of(context).textTheme.displayLarge)),
//           SizedBox(width: screenWidth * 0.02),
//           Expanded(
//             flex: 3,
//             child: Text(
//               value,
//               style: Theme.of(context).textTheme.bodyLarge,
//               textAlign: TextAlign.right,
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildCallButton(BuildContext context) {
//     return SizedBox(
//       width: double.infinity,
//       child: ElevatedButton(
//         style: ElevatedButton.styleFrom(
//           backgroundColor: Theme.of(context).primaryColor,
//           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(screenWidth * 0.03)),
//           padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.08, vertical: screenHeight * 0.018),
//           elevation: 3,
//         ),
//         onPressed: _handleCall,
//         child: Row(
//           mainAxisAlignment: MainAxisAlignment.center,
//           children: [
//             Icon(Icons.phone, color: _whiteColor, size: screenWidth * 0.05),
//             SizedBox(width: screenWidth * 0.02),
//             Text(
//               'Call Dealer',
//               style: AppTheme.normalText2.copyWith(color: _whiteColor, fontWeight: FontWeight.w600),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   String _formatBrands(dynamic brands) {
//     if (brands == null) return 'N/A';
//     if (brands is List) return brands.isNotEmpty ? brands.join(', ') : 'N/A';
//     return brands.toString();
//   }
//
//   void _handleEdit(BuildContext context) {
//     Navigator.push(context, MaterialPageRoute(builder: (context) => EditDealerScreen(dealer: dealer)));
//   }
//
//   void _showDeleteDialog(BuildContext context, WidgetRef ref, String userName, String employeeId) {
//     showDialog(
//       context: context,
//       barrierDismissible: false,
//       builder: (dialogContext) => _DeleteDialogWidget(
//         context: context,
//         ref: ref,
//         userName: userName,
//         employeeId: employeeId,
//       ),
//     );
//   }
//
//   void _handleCall() {
//     final phoneNumber = dealer.employeePhone;
//     if (phoneNumber != null && phoneNumber.isNotEmpty) {
//       debugPrint('Calling: $phoneNumber');
//     } else {
//       debugPrint('No phone number available');
//     }
//   }
// }
//
// // Separate StatefulWidget for the delete dialog to handle state properly
// class _DeleteDialogWidget extends StatefulWidget {
//   final BuildContext context;
//   final WidgetRef ref;
//   final String userName;
//   final String employeeId;
//
//   const _DeleteDialogWidget({
//     required this.context,
//     required this.ref,
//     required this.userName,
//     required this.employeeId,
//   });
//
//   @override
//   State<_DeleteDialogWidget> createState() => _DeleteDialogWidgetState();
// }
//
// class _DeleteDialogWidgetState extends State<_DeleteDialogWidget> {
//   late final TextEditingController _reasonController;
//   int _secondsRemaining = 10;
//   bool _canDelete = false;
//   bool _isDeleting = false;
//
//   @override
//   void initState() {
//     super.initState();
//     _reasonController = TextEditingController();
//     _startCountdown();
//   }
//
//   @override
//   void dispose() {
//     _reasonController.dispose();
//     super.dispose();
//   }
//
//   void _startCountdown() {
//     if (_secondsRemaining > 0) {
//       Future.delayed(const Duration(seconds: 1), () {
//         if (mounted) {
//           setState(() {
//             _secondsRemaining--;
//             if (_secondsRemaining == 0) _canDelete = true;
//           });
//           _startCountdown();
//         }
//       });
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return AlertDialog(
//       backgroundColor: Theme.of(context).focusColor,
//       title: Text('Delete User', style: Theme.of(context).textTheme.labelSmall),
//       content: SingleChildScrollView(
//         child: ConstrainedBox(
//           constraints: BoxConstraints(
//             maxHeight: MediaQuery.of(context).size.height * 0.6,
//           ),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               Text(
//                 'Are you sure you want to delete "${widget.userName}"?',
//                 style: Theme.of(context).textTheme.labelSmall,
//               ),
//               const SizedBox(height: 16),
//               ConstrainedBox(
//                 constraints: const BoxConstraints(maxHeight: 120),
//                 child: TextFormField(
//                   controller: _reasonController,
//                   maxLines: 4,
//                   decoration: const InputDecoration(
//                     hintText: 'Enter reason for deleting',
//                     border: OutlineInputBorder(),
//                     isDense: true,
//                   ),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               if (!_canDelete)
//                 Text(
//                   'Please wait $_secondsRemaining seconds...',
//                   style: const TextStyle(color: Colors.grey),
//                 ),
//             ],
//           ),
//         ),
//       ),
//       actions: [
//         TextButton(
//           onPressed: _isDeleting ? null : () => Navigator.pop(context),
//           child: const Text('Cancel'),
//         ),
//         ElevatedButton(
//           onPressed: (_canDelete && !_isDeleting) ? _handleDelete : null,
//           style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//           child: _isDeleting
//               ? const SizedBox(
//             width: 16,
//             height: 16,
//             child: CircularProgressIndicator(
//               strokeWidth: 2,
//               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//             ),
//           )
//               : Text(
//             _canDelete ? 'Delete' : 'Wait...',
//             style: const TextStyle(color: Colors.white),
//           ),
//         ),
//       ],
//     );
//   }
//
//   Future<void> _handleDelete() async {
//     final reason = _reasonController.text.trim();
//     if (reason.isEmpty) {
//       _showSnackBar('Reason is required', Colors.red);
//       return;
//     }
//
//     setState(() => _isDeleting = true);
//
//     try {
//       final error = await widget.ref
//           .read(signupControllerProvider.notifier)
//           .deleteUser(widget.employeeId, reason);
//
//       if (mounted) {
//         if (error != null) {
//           setState(() => _isDeleting = false);
//           _showSnackBar(error, Colors.red);
//         } else {
//           _showSnackBar('User deleted successfully', Colors.green);
//           Navigator.pop(context); // Close dialog
//           Navigator.pop(widget.context); // Go back to previous screen
//         }
//       }
//     } catch (e) {
//       if (mounted) {
//         setState(() => _isDeleting = false);
//         _showSnackBar('An error occurred: ${e.toString()}', Colors.red);
//       }
//     }
//   }
//
//   void _showSnackBar(String message, Color backgroundColor) {
//     ScaffoldMessenger.of(widget.context).showSnackBar(
//       SnackBar(
//         content: Text(message),
//         backgroundColor: backgroundColor,
//         duration: const Duration(seconds: 3),
//       ),
//     );
//   }
// }
//
// class InfoItem {
//   final String label;
//   final String? value;
//   InfoItem(this.label, this.value);
// }