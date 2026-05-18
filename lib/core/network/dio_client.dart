import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curl_logger_dio_interceptor/curl_logger_dio_interceptor.dart';
import 'package:flutter/foundation.dart';
import '../utils/navigation_service.dart';
import '../../feature/authentication/screens/login_mobile_view.dart';


final dioClientProvider = Provider<Dio>((ref) => DioClient.instance);
class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'https://api.smartenterprises.online/api/v1',
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {'Content-Type': 'application/json'},
    ),
  )
  // ── Auth token injector ──────────────────────────────────────────────────
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');
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
            final prefs = await SharedPreferences.getInstance();
            await prefs.remove('token');
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