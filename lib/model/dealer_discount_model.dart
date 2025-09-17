class DealerDiscountModel {
  final String? dealerDiscountId;
  final String brandName;
  final String modelName;
  final String dealerId;
  final num discountValue;
  final bool isPercentage;
  final String description;

  DealerDiscountModel({
    this.dealerDiscountId,
    required this.brandName,
    required this.modelName,
    required this.dealerId,
    required this.discountValue,
    required this.isPercentage,
    required this.description,
  });

  factory DealerDiscountModel.fromJson(Map<String, dynamic> json) {
    return DealerDiscountModel(
      dealerDiscountId: json["dealer_discount_id"],
      brandName: json["brand_name"] ?? "",
      modelName: json["model_name"] ?? "",
      dealerId: json["dealer_id"] ?? "",
      discountValue: json["discount_value"] ?? 0,
      isPercentage: json["is_percentage"] ?? false,
      description: json["description"] ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "dealer_discount_id": dealerDiscountId,
      "brand_name": brandName,
      "model_name": modelName,
      "dealer_id": dealerId,
      "discount_value": discountValue,
      "is_percentage": isPercentage,
      "description": description,
    };
  }

  DealerDiscountModel copyWith({
    String? dealerDiscountId,
    String? brandName,
    String? modelName,
    String? dealerId,
    num? discountValue,
    bool? isPercentage,
    String? description,
  }) {
    return DealerDiscountModel(
      dealerDiscountId: dealerDiscountId ?? this.dealerDiscountId,
      brandName: brandName ?? this.brandName,
      modelName: modelName ?? this.modelName,
      dealerId: dealerId ?? this.dealerId,
      discountValue: discountValue ?? this.discountValue,
      isPercentage: isPercentage ?? this.isPercentage,
      description: description ?? this.description,
    );
  }
}
