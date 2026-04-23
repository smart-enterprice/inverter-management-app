import 'package:inverter_management_app/model/product_model.dart';
import 'dealer_discount_model.dart';

class SelectedProduct {
  final ProductModel product;
  int quantity;
  bool isScheme;
  num? discountAmount;
  String? dealerDiscountId;
  bool useDealerDiscount;
  final DealerDiscountModel? dealerDiscount;
  DateTime? deliveryDate;

  SelectedProduct({
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
    int? quantity,
    bool? isScheme,
    num? discountAmount,
    String? dealerDiscountId,
    bool? useDealerDiscount,
    DealerDiscountModel? dealerDiscount,
    DateTime? deliveryDate,
  }) {
    return SelectedProduct(
      product: product,
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