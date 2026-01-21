// import 'package:flutter/material.dart';
//
// import '../../../core/media_query/media_query.dart';
// import '../../../model/product_list_model.dart';
// import '../../../model/user_model.dart';
//
// class ProductCard extends StatefulWidget {
//   final SelectedProduct selectedProduct;
//   final int index;
//   final Function(int, SelectedProduct) onUpdate;
//   final VoidCallback onDelete;
//   final UserModel? selectedDealer;
//
//   const ProductCard({
//     super.key,
//     required this.selectedProduct,
//     required this.index,
//     required this.onUpdate,
//     required this.onDelete,
//     required this.selectedDealer,
//   });
//
//   @override
//   State<ProductCard> createState() => _ProductCardState();
// }
//
// class _ProductCardState extends State<ProductCard> {
//   @override
//   Widget build(BuildContext context) {
//     return Card(
//       margin:  EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//       child: Padding(
//         padding: const EdgeInsets.all(16),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // Product Info
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Expanded(
//                   child: Column(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Text(
//                         widget.selectedProduct.product.brand.toString(),
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       Text(
//                         widget.selectedProduct.product.productName.toString(),
//                         style: const TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 16,
//                         ),
//                       ),
//                       Row(
//                         children: [
//                           Text(
//                             widget.selectedProduct.product.model.toString(),
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                           SizedBox(width: Screen.w(context) * 0.02),
//                           Text(
//                             widget.selectedProduct.product.productType.toString(),
//                             style: TextStyle(color: Colors.grey[600]),
//                           ),
//                         ],
//                       ),
//                       Text(
//                         "PRICE: ${widget.selectedProduct.product.price}",
//                         style: TextStyle(color: Colors.grey[600]),
//                       ),
//                     ],
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.delete, color: Colors.red),
//                   onPressed: widget.onDelete,
//                 ),
//               ],
//             ),
//
//             const SizedBox(height: 12),
//
//             // Quantity
//             Row(
//               children: [
//                 const Text('Quantity:'),
//                 const SizedBox(width: 8),
//                 IconButton(
//                   icon: const Icon(Icons.remove),
//                   onPressed: () {
//                     if (widget.selectedProduct.quantity > 1) {
//                       widget.onUpdate(
//                         widget.index,
//                         widget.selectedProduct.copyWith(
//                           quantity: widget.selectedProduct.quantity - 1,
//                         ),
//                       );
//                     }
//                   },
//                 ),
//                 Text(
//                   widget.selectedProduct.quantity.toString(),
//                   style: const TextStyle(fontSize: 16),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.add),
//                   onPressed: () {
//                     widget.onUpdate(
//                       widget.index,
//                       widget.selectedProduct.copyWith(
//                         quantity: widget.selectedProduct.quantity + 1,
//                       ),
//                     );
//                   },
//                 ),
//               ],
//             ),
//
//             // Scheme Toggle
//             Row(
//               children: [
//                 const Text('Scheme:'),
//                 const SizedBox(width: 8),
//                 Switch(
//                   value: widget.selectedProduct.isScheme,
//                   onChanged: (value) {
//                     widget.onUpdate(
//                       widget.index,
//                       widget.selectedProduct.copyWith(isScheme: value),
//                     );
//                   },
//                 ),
//               ],
//             ),
//
//             // Discount Options
//             if (widget.selectedDealer != null)
//               _buildDiscountOptions(widget.selectedProduct, widget.index),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildDiscountOptions(SelectedProduct selectedProduct, int index) {
//     // ✅ Fix 1: Use widget.selectedDealer
//     print('🟡 selectedDealer: ${widget.selectedDealer?.employeeId}');
//     print('🟡 selectedProductId: ${selectedProduct.product.productId}');
//
//     final discount = selectedProduct.dealerDiscount;
//
//     // 🔹 If product is scheme → hide everything, use dealer discount by default
//     if (selectedProduct.isScheme) {
//       if (discount != null && selectedProduct.useDealerDiscount != true) {
//         WidgetsBinding.instance.addPostFrameCallback((_) {
//           // ✅ Fix 2: Use widget.onUpdate instead of setState
//           widget.onUpdate(
//             index,
//             selectedProduct.copyWith(
//               useDealerDiscount: true,
//               discountAmount: null,
//               dealerDiscountId: discount.dealerDiscountId,
//             ),
//           );
//         });
//       }
//       return const SizedBox.shrink();
//     }
//
//     // 🔹 No dealer discount found → manual input
//     if (discount == null) {
//       print('⚠️ No dealer discount found — showing manual discount input');
//       return Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           const Text('Discount Amount:'),
//           SizedBox(
//             width: Screen.w(context) * 0.4,
//             child: TextFormField(
//               initialValue: selectedProduct.discountAmount?.toString() ?? '',
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 hintText: 'Enter discount amount',
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 print('📝 Manual discount entered: $value');
//                 // ✅ Fix 3: Use widget.onUpdate instead of setState
//                 widget.onUpdate(
//                   index,
//                   selectedProduct.copyWith(
//                     discountAmount: num.tryParse(value),
//                     useDealerDiscount: false,
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//       );
//     }
//
//     // 🔹 Dealer discount exists
//     print('🎯 Dealer discount available -> ID: ${discount.dealerDiscountId}, Value: ${discount.discountValue}');
//
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         const Text('Discount Option:'),
//         Row(
//           children: [
//             Expanded(
//               child: RadioListTile<bool>(
//                 title: const Text('Manual Discount'),
//                 value: false,
//                 groupValue: selectedProduct.useDealerDiscount,
//                 onChanged: (value) {
//                   print('🔘 Manual discount selected');
//                   // ✅ Fix 4: Use widget.onUpdate instead of setState
//                   widget.onUpdate(
//                     index,
//                     selectedProduct.copyWith(
//                       useDealerDiscount: false,
//                       dealerDiscountId: null,
//                     ),
//                   );
//                 },
//               ),
//             ),
//             Expanded(
//               child: RadioListTile<bool>(
//                 title: const Text('Dealer Discount'),
//                 value: true,
//                 groupValue: selectedProduct.useDealerDiscount,
//                 onChanged: (value) {
//                   print('🔘 Dealer discount selected');
//                   // ✅ Fix 5: Use widget.onUpdate instead of setState
//                   widget.onUpdate(
//                     index,
//                     selectedProduct.copyWith(
//                       useDealerDiscount: true,
//                       discountAmount: null,
//                       dealerDiscountId: discount.dealerDiscountId,
//                     ),
//                   );
//                 },
//               ),
//             ),
//           ],
//         ),
//
//         if (!selectedProduct.useDealerDiscount) ...[
//           const SizedBox(height: 8),
//           SizedBox(
//             width: Screen.w(context) * 0.4,
//             child: TextFormField(
//               initialValue: selectedProduct.discountAmount?.toString() ?? '',
//               keyboardType: TextInputType.number,
//               decoration: const InputDecoration(
//                 hintText: 'Enter discount amount',
//                 border: OutlineInputBorder(),
//               ),
//               onChanged: (value) {
//                 print('✏️ Manual discount field updated: $value');
//                 // ✅ Fix 6: Use widget.onUpdate instead of setState
//                 widget.onUpdate(
//                   index,
//                   selectedProduct.copyWith(
//                     discountAmount: num.tryParse(value),
//                   ),
//                 );
//               },
//             ),
//           ),
//         ],
//
//         if (selectedProduct.useDealerDiscount) ...[
//           const SizedBox(height: 8),
//           Card(
//             child: ListTile(
//               title: Text(
//                 '${discount.isPercentage == false ? '₹' : ''}${discount.discountValue}${discount.isPercentage ? '%' : ''}',
//               ),
//               subtitle: Text(discount.description ?? ''),
//             ),
//           ),
//         ],
//       ],
//     );
//   }
// }