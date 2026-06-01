import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// OS-keystore-backed storage for the auth bearer token.
///
/// The bearer token is the only true secret in the session — `user_role`,
/// `user_id` and `is_logged_in` are non-sensitive identifiers and stay in
/// SharedPreferences. On Android this is backed by the Keystore (via
/// EncryptedSharedPreferences); on iOS by the Keychain.
class SecureStore {
  SecureStore._();

  static const FlutterSecureStorage _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  static const String _tokenKey = 'auth_token';

  static Future<void> setToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  static Future<String?> getToken() => _storage.read(key: _tokenKey);

  static Future<void> clearToken() => _storage.delete(key: _tokenKey);
}
