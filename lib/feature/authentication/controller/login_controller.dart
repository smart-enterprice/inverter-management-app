import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../model/login_model.dart';
import '../repository/login_repository.dart';


final loginControllerProvider = Provider((ref) {
  final repository = ref.read(loginRepositoryProvider);
  return LoginController(repository);
});

class LoginController {
  final LoginRepository _repository;

  LoginController(this._repository);

  Future<String> login(String email, String password) async {
    try {
      final request = LoginRequest(
        employeeEmail: email,
        password: password,
      );

      final response = await _repository.login(request);
      print(response);
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        final role = response.data['data']['employee']['role'];
        final token = response.data['data']['token'];
        await prefs.setString('user_role', role);
        print('-----------------$role-------------------');
        await prefs.setString('token', token);
        print('Token is : $token');
        await prefs.setBool('is_logged_in', true);
        print('logged in success');
        return "Login successful";
      } else if(response.statusCode == 401) {
        return "Email or password invalid";
      }else{
        return "Something wrong";
      }
    } catch (e) {
      return "Login error: $e";
    }
  }

  // To check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool('is_logged_in') ?? false;
  }

  // ✅ To log out
  Future<void> isLogout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('is_logged_in', false);
  }

  Future<String> logout() async {
    try {
      final response = await _repository.logout();
      if (response.statusCode == 200) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('token');
        await prefs.remove('user_role');
        await prefs.setBool('is_logged_in', false);
        print("Logged out successfully");
        return "Logout successful";
      } else {
        return "Logout failed";
      }
    } catch (e) {
      return "Logout error: $e";
    }
  }
}
