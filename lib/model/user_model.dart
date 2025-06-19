class AddUserRequest {
  final String employeeId;
  final String employeeName;
  final String employeeEmail;
  final String password;
  final String employeePhone;
  final String role;
  final String createdBy;
  final String shopName;
  final String photo;
  final String district;
  final String town;
  final String brand;
  final String address;
  AddUserRequest({
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.password,
    required this.employeePhone,
    required this.role,
    required this.createdBy,
    required this.shopName,
    required this.photo,
    required this.district,
    required this.town,
    required this.brand,
    required this.address,
  });
  /// ✅ Convert class to JSON
  Map<String, dynamic> toJson() {
    return {
      'employee_id': employeeId,
      'employee_name': employeeName,
      'employee_email': employeeEmail,
      'password': password,
      'employee_phone': employeePhone,
      'role': role,
      'created_by': createdBy,
      'shop_name': shopName,
      'photo': photo,
      'district': district,
      'town': town,
      'brand': brand,
      'address': address,
    };
  }

  /// ✅ Create class from JSON
  factory AddUserRequest.fromJson(Map<String, dynamic> json) {
    return AddUserRequest(
      employeeId: json['employee_id'],
      employeeName: json['employee_name'],
      employeeEmail: json['employee_email'],
      password: json['password'],
      employeePhone: json['employee_phone'],
      role: json['role'],
      createdBy: json['created_by'],
      shopName: json['shop_name'],
      photo: json['photo'],
      district: json['district'],
      town: json['town'],
      brand: json['brand'],
      address: json['address'],
    );
  }

  /// ✅ Clone with changes
  AddUserRequest copyWith({
    String? employeeId,
    String? employeeName,
    String? employeeEmail,
    String? password,
    String? employeePhone,
    String? role,
    String? createdBy,
    String? shopName,
    String? photo,
    String? district,
    String? town,
    String? brand,
    String? address,
  }) {
    return AddUserRequest(
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      password: password ?? this.password,
      employeePhone: employeePhone ?? this.employeePhone,
      role: role ?? this.role,
      createdBy: createdBy ?? this.createdBy,
      shopName: shopName ?? this.shopName,
      photo: photo ?? this.photo,
      district: district ?? this.district,
      town: town ?? this.town,
      brand: brand ?? this.brand,
      address: address ?? this.address,
    );
  }
}
