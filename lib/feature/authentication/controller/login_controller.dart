import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/role/app_role.dart';
import '../../notification/service/fcm_service.dart';
import '../../../feature/authentication/model/login_model.dart';
import '../../../core/network/app_exception.dart';
import '../repository/login_repository.dart';

// ─── Provider ────────────────────────────────────────────────────────────────

final loginControllerProvider =
AsyncNotifierProvider<LoginController, LoginResult?>(
  LoginController.new,
);

// ─── Notifier ────────────────────────────────────────────────────────────────

class LoginController extends AsyncNotifier<LoginResult?> {
  // Keys
  static const _roleKey     = 'user_role';
  static const _tokenKey    = 'token';
  static const _userIdKey   = 'user_id';
  static const _loggedInKey = 'is_logged_in';

  late final LoginRepository _repository;

  @override
  Future<LoginResult?> build() async {
    _repository = ref.watch(loginRepositoryProvider);
    return null; // initial state — no login action yet
  }

  // ── Public actions ──────────────────────────────────────────────────────────

  Future<LoginResult> login(String email, String password) async {
    if (email.trim().isEmpty || password.trim().isEmpty) {
      return _setFailure('Email and password required');
    }

    state = const AsyncLoading();

    try {
      final response = await _repository.login(
        LoginRequest(employeeEmail: email.trim(), password: password),
      );

      if (response.statusCode == 200) {
        return await _saveUserData(response.data?['data']);
      }
      return _setFailure('Something went wrong. Try again.');
    } on AppException catch (e) {
      final msg = e.statusCode == 400
          ? 'Password and email required'
          : 'Login error: ${e.message}';
      return _setFailure(msg);
    } catch (e, st) {
      state = AsyncError(e, st);
      return LoginResult.failure(e.toString());
    }
  }

  Future<LogoutResult> logout() async {
    try {
      await FcmService().clearLocalToken();

      final response = await _repository.logout();
      await _clearUserData();

      return response.statusCode == 200
          ? LogoutResult.success('Logout successful')
          : LogoutResult.failure('Server logout failed, local data cleared');
    } catch (_) {
      await _clearUserData();
      return LogoutResult.failure('Logout error, local data cleared');
    }
  }

  Future<void> forceLogout() async {
    await FcmService().clearLocalToken();
    await _clearUserData();
  }

  // ── Token / session helpers ─────────────────────────────────────────────────

  /// Returns true if server confirms token is active.
  /// Returns false if not logged in locally OR server rejected the token.
  /// Throws on network errors (offline) — caller can keep the session.
  Future<bool> isTokenActive() async {
    final loggedIn = await isLoggedIn();
    if (!loggedIn) return false;
    return await _repository.isTokenActive();
  }

  Future<bool>    isLoggedIn()  => _getBool(_loggedInKey);
  Future<String?> getUserRole() => _getString(_roleKey);
  Future<String?> getToken()    => _getString(_tokenKey);

  // ── Private helpers ─────────────────────────────────────────────────────────

  Future<LoginResult> _saveUserData(dynamic data) async {
    if (data == null) return _setFailure('Invalid response');

    final role  = data['employee']?['role']  as String?;
    final token = data['token']              as String?;
    final id    = data['employee']?['employee_id']?.toString();

    if (role == null || token == null) return _setFailure('Missing user data');

    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.setString(_roleKey,     role),
      prefs.setString(_tokenKey,    token),
      prefs.setBool(_loggedInKey,   true),
      if (id != null) prefs.setString(_userIdKey, id),
    ]);

    ref.read(roleNotifierProvider.notifier).setRole(role);

    final result = LoginResult.success('Login successful', role, token);
    state = AsyncData(result);
    return result;
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await Future.wait([
      prefs.remove(_roleKey),
      prefs.remove(_tokenKey),
      prefs.remove(_loggedInKey),
      prefs.remove(_userIdKey),
    ]);
    ref.read(roleNotifierProvider.notifier).clearRole();
    state = const AsyncData(null);
  }

  LoginResult _setFailure(String msg) {
    final result = LoginResult.failure(msg);
    state = AsyncData(result);
    return result;
  }

  Future<bool>    _getBool(String key)   async =>
      (await SharedPreferences.getInstance()).getBool(key)   ?? false;

  Future<String?> _getString(String key) async =>
      (await SharedPreferences.getInstance()).getString(key);
}

// ─── Result types ─────────────────────────────────────────────────────────────

class LoginResult {
  const LoginResult(this.success, this.message, {this.role, this.token});

  final bool    success;
  final String  message;
  final String? role;
  final String? token;

  factory LoginResult.success(String msg, String role, String token) =>
      LoginResult(true, msg, role: role, token: token);

  factory LoginResult.failure(String msg) => LoginResult(false, msg);
}

class LogoutResult {
  const LogoutResult(this.success, this.message);

  final bool   success;
  final String message;

  factory LogoutResult.success(String msg) => LogoutResult(true, msg);
  factory LogoutResult.failure(String msg) => LogoutResult(false, msg);
}