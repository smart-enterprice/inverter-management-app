class UserModel {
  final String? employeeId;
  final String employeeName;
  final String employeeEmail;
  final String password;
  final String employeePhone;
  final String role;
  final String? photo;
  final String address;
  final String? status;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;

  // Optional fields for ROLE_DEALER
  final String? shopName;
  final String? district;
  final String? town;
  final List<String>? brand;

  // Dealer management fields
  final List<String>? dealers;
  final List<String>? removeDealers;

  UserModel({
    this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.password,
    required this.employeePhone,
    required this.role,
    this.photo,
    required this.address,
    this.status,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.shopName,
    this.district,
    this.town,
    this.brand,
    this.dealers,
    this.removeDealers,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_name': employeeName,
      'employee_email': employeeEmail,
      'password': password,
      'employee_phone': employeePhone,
      'role': role,
      'photo': photo,
      'address': address,
      'shop_name': shopName,
      'district': district,
      'town': town,
      if (brand != null) 'brand': brand,
      if (dealers != null) 'dealers': dealers,
      if (removeDealers != null) 'remove_dealers': removeDealers,
    };
  }

  Map<String, dynamic> toUpdateJson() {
    return {
      'employee_name': employeeName,
      'employee_email': employeeEmail,
      'employee_phone': employeePhone,
      'role': role,
      'photo': photo,
      'address': address,
      'shop_name': shopName,
      'district': district,
      'town': town,
      if (dealers != null) 'dealers': dealers,
      if (removeDealers != null) 'remove_dealers': removeDealers,
    };
  }

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      employeeId: json['employee_id']?.toString(),
      employeeName: json['employee_name']?.toString() ?? '',
      employeeEmail: json['employee_email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      employeePhone: json['employee_phone']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      status: json['status']?.toString(),
      createdBy: json['created_by']?.toString(),
      createdAt: json['created_at']?.toString(),
      updatedAt: json['updated_at']?.toString(),
      shopName: json['shop_name']?.toString(),
      district: json['district']?.toString(),
      town: json['town']?.toString(),
      brand: (json['brand'] as List?)?.map((e) => e.toString()).toList(),
      dealers: (json['dealers'] as List?)?.map((e) => e.toString()).toList(),
      removeDealers: (json['remove_dealers'] as List?)?.map((e) => e.toString()).toList(),
    );
  }

  UserModel copyWith({
    String? employeeId,
    String? employeeName,
    String? employeeEmail,
    String? password,
    String? employeePhone,
    String? role,
    String? photo,
    String? address,
    String? status,
    String? createdBy,
    String? createdAt,
    String? updatedAt,
    String? shopName,
    String? district,
    String? town,
    List<String>? brand,
    List<String>? dealers,
    List<String>? removeDealers,
  }) {
    return UserModel(
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      password: password ?? this.password,
      employeePhone: employeePhone ?? this.employeePhone,
      role: role ?? this.role,
      photo: photo ?? this.photo,
      address: address ?? this.address,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      shopName: shopName ?? this.shopName,
      district: district ?? this.district,
      town: town ?? this.town,
      brand: brand ?? this.brand,
      dealers: dealers ?? this.dealers,
      removeDealers: removeDealers ?? this.removeDealers,
    );
  }
}