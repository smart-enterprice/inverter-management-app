class LoginRequest {
  final String employeeEmail;
  final String password;

  LoginRequest({
    required this.employeeEmail,
    required this.password,
  });

  Map<String, dynamic> toJson() {
    return {
      'employee_email': employeeEmail,
      'password': password,
    };
  }

  factory LoginRequest.fromJson(Map<String, dynamic> json) {
    return LoginRequest(
      employeeEmail: json['employee_email'],
      password: json['password'],
    );
  }
}
