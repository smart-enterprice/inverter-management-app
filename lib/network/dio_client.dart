import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:curl_logger_dio_interceptor/curl_logger_dio_interceptor.dart';

class DioClient {
  static final Dio _dio = Dio(
    BaseOptions(
      baseUrl: 'http://88.222.245.191:1280/api/v1',
      connectTimeout: Duration(seconds: 10),
      receiveTimeout: Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
      },
    ),
  )
    ..interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('token');

          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          options.headers.remove('content-length');
          return handler.next(options); // Continue with request
        },
      ),
    )
    ..interceptors.add(CurlLoggerDioInterceptor()); // Add cURL logging

  static Dio get instance => _dio;
}
