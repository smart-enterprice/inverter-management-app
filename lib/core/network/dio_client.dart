import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curl_logger_dio_interceptor/curl_logger_dio_interceptor.dart';
import 'package:flutter/foundation.dart';
import '../utils/navigation_service.dart';
import '../utils/secure_store.dart';
import '../../feature/authentication/screens/login_mobile_view.dart';


final dioClientProvider = Provider<Dio>((ref) => DioClient.instance);
class DioClient {
  // ── Backends ────────────────────────────────────────────────────────────────
  // Pick the one that matches where you're running. To switch, change the
  // single `baseUrl` line at the bottom of this block.

  // Only one is referenced at a time — the others are kept as documented
  // switch-targets, so the lint that flags them as unused is silenced.
  // ignore_for_file: unused_field
  static const String _production     = 'https://api.smartenterprises.online/api/v1';
  static const String _androidEmu     = 'http://10.0.2.2:1280/api/v1';     // Android emulator
  static const String _iosSim         = 'http://localhost:1280/api/v1';    // iOS simulator
  static const String _realDeviceLan  = 'http://192.168.29.68:1280/api/v1';// Physical phone over Wi-Fi
  static const String _flutterWeb     = 'http://localhost:1280/api/v1';    // flutter run -d chrome

  // 👇 ACTIVE URL — change this one line to switch environment.
  static const String baseUrl = _production;

  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: baseUrl,

      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )
  // ── Auth token injector ──────────────────────────────────────────────────
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final token = await SecureStore.getToken();
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers.remove('content-length');
          return handler.next(options);
        },

        // ✅ FIX: Handle 401 — clear session and redirect to login
        onError: (DioException error, handler) async {
          if (error.response?.statusCode == 401) {
            // Clear all stored credentials
            await SecureStore.clearToken();
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('user_role');
            await prefs.remove('user_id');
            await prefs.remove('is_logged_in');

            // Navigate to login, clearing the entire stack
            // Uses NavigationService so no BuildContext is needed here
            NavigationService.pushAndRemoveAll(const LoginMobileView());

            // Reject the request so no further error handling runs
            return handler.reject(
              DioException(
                requestOptions: error.requestOptions,
                error: 'Session expired. Please log in again.',
                type: DioExceptionType.cancel,
              ),
            );
          }

          // All other errors pass through normally
          return handler.next(error);
        },
      ),
    )
  // ── cURL logging (debug builds only) ────────────────────────────────────
    ..interceptors.addAll(kDebugMode ? [CurlLoggerDioInterceptor()] : const []);

  static Dio get instance => _dio;
}