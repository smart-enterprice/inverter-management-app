import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/user_model.dart';
import '../../../network/dio_client.dart';

final employeeSignupRepositoryProvider = Provider<EmployeeSignupRepository>((ref) {
  return EmployeeSignupRepository();
});

class EmployeeSignupRepository {
  final Dio _dio = DioClient.instance;


  ///---------------------------- Signup function
  Future<Response> signup(EmployeeRegisterRequest request) async {
    return await _dio.post('/employees/signup', data: request.toJson());
  }

  //  Get list of employees
  Future<List<EmployeeRegisterRequest>> getEmployees({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/employees?page=$page&limit=$limit');

    final employeeList = (response.data['data']['employees'] as List)
        .map((e) => EmployeeRegisterRequest.fromJson(e))
        .toList();

    return employeeList;
  }
  ///---------------------------- update function
  Future<void> updateEmployee(String employeeId, EmployeeRegisterRequest updatedData) async {
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
      // Extract the error message from DioException and throw a custom exception
      final statusCode = e.response?.statusCode;
      String errorMessage = 'Update failed';

      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ?? errorMessage;
        }
      }

      print('Repository DioException: $errorMessage');
      throw Exception(errorMessage); // Throw with the extracted message
    } catch (e) {
      print('Repository non-Dio exception: $e');
      throw Exception('Update error: $e');
    }
  }
///--------------------------------delete function

  Future<void> deleteEmployee(String employeeId, String reason) async {
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
