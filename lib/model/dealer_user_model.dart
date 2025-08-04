class DealerModel {
  final String employeeName;
  final String employeeEmail;
  final String password;
  final String employeePhone;
  final String role;
  final String shopName;
  final String photo;
  final String district;
  final String town;
  final List<String> brand;
  final String address;

  DealerModel({
    required this.employeeName,
    required this.employeeEmail,
    required this.password,
    required this.employeePhone,
    required this.role,
    required this.shopName,
    required this.photo,
    required this.district,
    required this.town,
    required this.brand,
    required this.address,
  });

  factory DealerModel.fromJson(Map<String, dynamic> json) {
    return DealerModel(
      employeeName: json['employee_name'] ?? '',
      employeeEmail: json['employee_email'] ?? '',
      password: json['password'] ?? '',
      employeePhone: json['employee_phone'] ?? '',
      role: json['role'] ?? '',
      shopName: json['shop_name'] ?? '',
      photo: json['photo'] ?? '',
      district: json['district'] ?? '',
      town: json['town'] ?? '',
      brand: List<String>.from(json['brand'] ?? []),
      address: json['address'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'employee_name': employeeName,
      'employee_email': employeeEmail,
      'password': password,
      'employee_phone': employeePhone,
      'role': role,
      'shop_name': shopName,
      'photo': photo,
      'district': district,
      'town': town,
      'brand': brand,
      'address': address,
    };
  }

  DealerModel copyWith({
    String? employeeName,
    String? employeeEmail,
    String? password,
    String? employeePhone,
    String? role,
    String? shopName,
    String? photo,
    String? district,
    String? town,
    List<String>? brand,
    String? address,
  }) {
    return DealerModel(
      employeeName: employeeName ?? this.employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      password: password ?? this.password,
      employeePhone: employeePhone ?? this.employeePhone,
      role: role ?? this.role,
      shopName: shopName ?? this.shopName,
      photo: photo ?? this.photo,
      district: district ?? this.district,
      town: town ?? this.town,
      brand: brand ?? this.brand,
      address: address ?? this.address,
    );
  }
}
