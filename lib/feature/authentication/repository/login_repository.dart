import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/login_model.dart';
import '../../../network/dio_client.dart';

final loginRepositoryProvider = Provider<LoginRepository>((ref) {
  return LoginRepository(ref.watch(dioClientProvider));
});

class LoginRepository {
  const LoginRepository(this._dio);

  final Dio _dio;

  Future<Response<Map<String, dynamic>>> login(LoginRequest request) =>
      _dio.post('/auth/signin', data: request.toJson());

  Future<Response<void>> logout() => _dio.post('/auth/logout');

  Future<bool> isTokenActive() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/auth/token/active');
      return res.statusCode == 200 && res.data?['active'] == true;
    } on DioException {
      return false;
    }
  }
}