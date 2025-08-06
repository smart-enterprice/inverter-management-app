class BrandModel {
  final String? brandId; // optional for create, needed for update/list
  final String brandName;
  final List<String> brandModels;
  final String description;
  final String? status;
  final String? createdBy;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  BrandModel({
    this.brandId,
    required this.brandName,
    required this.brandModels,
    required this.description,
    this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
  });

  factory BrandModel.fromJson(Map<String, dynamic> json) {
    return BrandModel(
      brandId: json['brand_id'],
      brandName: json['brand_name'],
      brandModels: List<String>.from(json['brand_models'] ?? []),
      description: json['description'],
      status: json['status'],
      createdBy: json['created_by'],
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : null,
      updatedAt: json['updated_at'] != null ? DateTime.parse(json['updated_at']) : null,
    );
  }

  /// For creating a brand
  Map<String, dynamic> toJsonCreate() {
    return {
      "brand_name": brandName,
      "brand_models": brandModels,
      "description": description,
    };
  }

  /// For updating a brand
  Map<String, dynamic> toJsonUpdate() {
    return {
      "brand_id": brandId,
      "brand_name": brandName,
      "brand_models": brandModels,
      "description": description,
      "status": status,
    };
  }

  BrandModel copyWith({
    String? brandId,
    String? brandName,
    List<String>? brandModels,
    String? description,
    String? status,
    String? createdBy,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return BrandModel(
      brandId: brandId ?? this.brandId,
      brandName: brandName ?? this.brandName,
      brandModels: brandModels ?? this.brandModels,
      description: description ?? this.description,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
