import 'package:inverter_management_app/model/product_model.dart';
import 'dealer_discount_model.dart';

class SelectedProduct {
  final ProductModel product;
  final int quantity;
  final bool isScheme;
  final num? discountAmount;
  final String? dealerDiscountId;
  final bool useDealerDiscount;
  final DealerDiscountModel? dealerDiscount;
  final DateTime? deliveryDate;

  const SelectedProduct({
    required this.product,
    this.quantity = 1,
    this.isScheme = false,
    this.discountAmount,
    this.dealerDiscountId,
    this.useDealerDiscount = false,
    this.dealerDiscount,
    this.deliveryDate,
  });

  SelectedProduct copyWith({
    ProductModel? product,
    int? quantity,
    bool? isScheme,
    num? discountAmount,
    String? dealerDiscountId,
    bool? useDealerDiscount,
    DealerDiscountModel? dealerDiscount,
    DateTime? deliveryDate,
  }) {
    return SelectedProduct(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      isScheme: isScheme ?? this.isScheme,
      discountAmount: discountAmount ?? this.discountAmount,
      dealerDiscountId: dealerDiscountId ?? this.dealerDiscountId,
      useDealerDiscount: useDealerDiscount ?? this.useDealerDiscount,
      dealerDiscount: dealerDiscount ?? this.dealerDiscount,
      deliveryDate: deliveryDate ?? this.deliveryDate,
    );
  }
}