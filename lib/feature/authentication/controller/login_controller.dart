import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../model/login_model.dart';
import '../repository/login_repository.dart';

/// SharedPreferences provider
final sharedPreferencesProvider = Provider<Future<SharedPreferences>>(
  (ref) => SharedPreferences.getInstance(),
);

/// LoginController provider
final loginControllerProvider = Provider(
  (ref) => LoginController(ref.read(loginRepositoryProvider), ref),
);

class LoginController {
  final LoginRepository _repository;
  final Ref _ref;

  LoginController(this._repository, this._ref);

  // Keys
  static const _roleKey = 'user_role';
  static const _tokenKey = 'token';
  static const _loggedInKey = 'is_logged_in';

  /// Login
  Future<LoginResult> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return LoginResult.failure('Email and password required');
    }
    try {
      final response = await _repository.login(
        LoginRequest(employeeEmail: email.trim(), password: password),
      );
      if (response.statusCode == 200) {
        return await _saveUserData(response.data?['data']);
      } else if (response.statusCode == 401) {
        return LoginResult.failure('Invalid email or password');
      } else {
        return LoginResult.failure('Something went wrong. Try again.');
      }
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        return LoginResult.failure('Invalid email or password');
      }

      if (e.response?.statusCode == 400) {
        return LoginResult.failure('password and email required');
      }
      return LoginResult.failure('Login error: ${e.message}');
    }
  }

  /// Save user data
  Future<LoginResult> _saveUserData(dynamic data) async {
    if (data == null) return LoginResult.failure('Invalid response');

    final role = data['employee']?['role'];
    final token = data['token'];

    if (role == null || token == null) {
      return LoginResult.failure('Missing user data');
    }

    final prefs = await _ref.read(sharedPreferencesProvider);
    await prefs.setString(_roleKey, role);
    await prefs.setString(_tokenKey, token);
    await prefs.setBool(_loggedInKey, true);

    return LoginResult.success('Login successful', role, token);
  }

  /// Logout
  Future<LogoutResult> logout() async {
    try {
      final response = await _repository.logout();
      if (response.statusCode == 200) {
        await _clearUserData();
        return LogoutResult.success('Logout successful');
      } else {
        await _clearUserData();
        return LogoutResult.failure(
            'Logout failed on server, but local cleared');
      }
    } catch (_) {
      await _clearUserData();
      return LogoutResult.failure('Logout error, local data cleared');
    }
  }

  Future<void> _clearUserData() async {
    final prefs = await _ref.read(sharedPreferencesProvider);
    await prefs.clear();
  }

  /// Force logout (without API call)
  Future<void> forceLogout() async => _clearUserData();

  /// Getters
  Future<bool> isLoggedIn() async =>
      (await _ref.read(sharedPreferencesProvider)).getBool(_loggedInKey) ??
      false;

  Future<String?> getUserRole() async =>
      (await _ref.read(sharedPreferencesProvider)).getString(_roleKey);

  Future<String?> getToken() async =>
      (await _ref.read(sharedPreferencesProvider)).getString(_tokenKey);
}

/// Result classes
class LoginResult {
  final bool success;
  final String message;
  final String? role, token;

  const LoginResult(this.success, this.message, {this.role, this.token});

  factory LoginResult.success(String msg, String role, String token) =>
      LoginResult(true, msg, role: role, token: token);

  factory LoginResult.failure(String msg) => LoginResult(false, msg);
}

class LogoutResult {
  final bool success;
  final String message;

  const LogoutResult(this.success, this.message);

  factory LogoutResult.success(String msg) => LogoutResult(true, msg);

  factory LogoutResult.failure(String msg) => LogoutResult(false, msg);
}
