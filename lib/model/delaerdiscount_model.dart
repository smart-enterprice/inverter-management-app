class DealerDiscountModel {
  final String brandName;
  final String modelName;
  final String dealerId;
  final double discountValue;
  final bool isPercentage;
  final String description;

  DealerDiscountModel({
    required this.brandName,
    required this.modelName,
    required this.dealerId,
    required this.discountValue,
    required this.isPercentage,
    required this.description,
  });

  factory DealerDiscountModel.fromJson(Map<String, dynamic> json) {
    return DealerDiscountModel(
      brandName: json['brand_name'] ?? '',
      modelName: json['model_name'] ?? '',
      dealerId: json['dealer_id'] ?? '',
      discountValue: (json['discount_value'] is int)
          ? (json['discount_value'] as int).toDouble()
          : (json['discount_value'] ?? 0.0).toDouble(),
      isPercentage: json['is_percentage'] ?? false,
      description: json['description'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "brand_name": brandName,
      "model_name": modelName,
      "dealer_id": dealerId,
      "discount_value": discountValue,
      "is_percentage": isPercentage,
      "description": description,
    };
  }

  DealerDiscountModel copyWith({
    String? brandName,
    String? modelName,
    String? dealerId,
    double? discountValue,
    bool? isPercentage,
    String? description,
  }) {
    return DealerDiscountModel(
      brandName: brandName ?? this.brandName,
      modelName: modelName ?? this.modelName,
      dealerId: dealerId ?? this.dealerId,
      discountValue: discountValue ?? this.discountValue,
      isPercentage: isPercentage ?? this.isPercentage,
      description: description ?? this.description,
    );
  }
}
