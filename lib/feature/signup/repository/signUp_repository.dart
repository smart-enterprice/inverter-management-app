import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/user_model.dart';
import '../../../network/dio_client.dart';

final signupRepositoryProvider = Provider<SignupRepository>((ref) {
  return SignupRepository();
});

class SignupRepository {
  final Dio _dio = DioClient.instance;

  ///---------------------------- User Signup function
  Future<Response> userSignup(UserModel request) async {
    return await _dio.post('/employees/signup', data: request.toJson());
  }

  /// ------------------------- Get list of employees
  Future<List<UserModel>> getEmployees({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/employees?page=$page&limit=$limit');

    final employeeList = (response.data['data']['employees'] as List)
        .map((e) => UserModel.fromJson(e))
        .where((user) => user.role != 'ROLE_DEALER')
        .toList();

    return employeeList;
  }

  /// ------------------------- Get list of dealers
  Future<List<UserModel>> getDealers({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/employees?page=$page&limit=$limit');

    final dealerList = (response.data['data']['employees'] as List)
        .map((e) => UserModel.fromJson(e))
        .where((user) => user.role == 'ROLE_DEALER')
        .toList();

    return dealerList;
  }

  /// ------------------------- Get single employee by ID ✅
  Future<UserModel> getEmployeeById(String id) async {
    final response = await _dio.get('/employees/$id');
    return UserModel.fromJson(response.data['data']);
  }

  /// ---------------------------- user update function
  Future<void> updateUser(String employeeId, UserModel updatedData) async {
    try {
      final response = await DioClient.instance.put(
        '/employees/$employeeId',
        data: updatedData.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('------------------update success-------------------');
        return;
      } else {
        return response.data['message'];
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String errorMessage = 'Update failed';

      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ?? errorMessage;
        }
      }

      print('Repository DioException: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      print('Repository non-Dio exception: $e');
      throw Exception('Update error: $e');
    }
  }

  /// ------------------------- user delete function
  Future<void> deleteUser(String employeeId, String reason) async {
    try {
      final response = await DioClient.instance.put(
        '/employees/update/delete-employee',
        data: {
          'employeeId': employeeId,
          'reason': reason,
        },
      );

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('Employee deleted successfully');
      } else {
        throw Exception('Failed to delete employee');
      }
    } catch (e) {
      throw Exception('Delete error: $e');
    }
  }
}
