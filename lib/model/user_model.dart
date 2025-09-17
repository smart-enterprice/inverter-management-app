class UserModel {
  final String? employeeId;
  final String employeeName;
  final String employeeEmail;
  final String password;
  final String employeePhone;
  final String role;
  final String? photo;
  final String address;

  // Optional fields for ROLE_DEALER
  final String? shopName;
  final String? district;
  final String? town;
  final List<String>? brand;

  UserModel({
    this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.password,
    required this.employeePhone,
    required this.role,
    this.photo,
    required this.address,
    this.shopName,
    this.district,
    this.town,
    this.brand,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
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
      photo: json['photo']?.toString().toString() ?? '',
      address: json['address']?.toString() ?? '',
      shopName: json['shop_name']?.toString(),
      district: json['district']?.toString(),
      town: json['town']?.toString(),
      brand: (json['brand'] as List?)?.map((e) => e.toString()).toList(),
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
    String? shopName,
    String? district,
    String? town,
    List<String>? brand,
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
      shopName: shopName ?? this.shopName,
      district: district ?? this.district,
      town: town ?? this.town,
      brand: brand ?? this.brand,
    );
  }
}
