class EmployeeRegisterRequest {
  final String? employeeId;
  final String employeeName;
  final String employeeEmail;
  final String password;
  final String employeePhone; // Changed to String to avoid conversion issues
  final String role;
  final String photo;
  final String address;

  EmployeeRegisterRequest({
    this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.password,
    required this.employeePhone,
    required this.role,
    required this.photo,
    required this.address,
  });

  /// Convert Dart object to JSON (for sending to backend)
  Map<String, dynamic> toJson() {
    return {
      'employee_name': employeeName,
      'employee_email': employeeEmail,
      'password': password,
      'employee_phone': employeePhone, // No conversion needed
      'role': role,
      'photo': photo,
      'address': address,
    };
  }

  /// Create Dart object from JSON (for reading backend response)
  factory EmployeeRegisterRequest.fromJson(Map<String, dynamic> json) {
    return EmployeeRegisterRequest(
      employeeId: json['employee_id']?.toString() ?? '',
      employeeName: json['employee_name']?.toString() ?? '',
      employeeEmail: json['employee_email']?.toString() ?? '',
      password: json['password']?.toString() ?? '',
      employeePhone: json['employee_phone']?.toString() ?? '', // Safe string conversion
      role: json['role']?.toString() ?? '',
      photo: json['photo']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
    );
  }

  /// Create a modified copy of this object
  EmployeeRegisterRequest copyWith({
    String? employeeId,
    String? employeeName,
    String? employeeEmail,
    String? password,
    String? employeePhone, // Changed to String
    String? role,
    String? photo,
    String? address,
  }) {
    return EmployeeRegisterRequest(
      employeeId: employeeId ?? this.employeeId,
      employeeName: employeeName ?? this.employeeName,
      employeeEmail: employeeEmail ?? this.employeeEmail,
      password: password ?? this.password,
      employeePhone: employeePhone ?? this.employeePhone,
      role: role ?? this.role,
      photo: photo ?? this.photo,
      address: address ?? this.address,
    );
  }
}