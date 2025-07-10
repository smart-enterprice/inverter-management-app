import '../../../model/login_model.dart';
import 'package:dio/dio.dart';
import '../../../network/dio_client.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
final loginRepositoryProvider = Provider<LoginRepository>((ref) {
  return LoginRepository();
});
class LoginRepository {
  final Dio _dio = DioClient.instance;
  Future<Response> login(LoginRequest request) async {
    return await _dio.post('/auth/signin', data: request.toJson());
  }
}
