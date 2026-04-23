import 'dart:io';

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
    final response = await _dio.get('/employees/dealers/get/?page=$page&limit=$limit');
    final dealerList = (response.data['data']['employees'] as List)
        .map((e) => UserModel.fromJson(e)).toList();
    return dealerList;
  }
  /// ------------------------- Get single employee by ID ✅
  Future<UserModel> getEmployeeById(String id) async {
    final response = await _dio.get('/employees/$id');
    return UserModel.fromJson(response.data['data']);
  }
  /// ---------------------------- user update function
  Future<void> updateUser(String employeeId, UserModel updatedData, {
    List<String>? addBrands,
    List<String>? removeBrands,
  }) async
  {
    try {
      // ✅ Build a fresh modifiable map instead of relying on toJson()
      final Map<String, dynamic> body = Map<String, dynamic>.from(updatedData.toJson());

      // ✅ Always remove brand key from existing user data
      body.remove('brand');

      // ✅ Only add 'brand' key if there are NEW brands to add
      if (addBrands != null && addBrands.isNotEmpty) {
        body['brand'] = addBrands;
      }

      // ✅ Only add 'remove_brands' if there are brands to remove
      if (removeBrands != null && removeBrands.isNotEmpty) {
        body['remove_brands'] = removeBrands;
      }

      print('Update body: $body'); // should NOT have brand key unless adding new

      final response = await DioClient.instance.put(
        '/employees/$employeeId',
        data: body,
      );
      if (response.statusCode == 200 || response.statusCode == 204) return;
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message'] ?? 'Update failed';
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Update error: $e');
    }
  }

  /// ------------------------- Get Users by Role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final response = await _dio.get('/employees/getByRole/$role');

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => UserModel.fromJson(e)).toList();
      } else {
        throw Exception('❌ Failed to fetch users by role');
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message']?.toString() ?? e.message.toString();
      throw Exception(errorMessage);
    } catch (e) {
      throw Exception('Unexpected error: $e');
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

  /// photo upload
  Future<String?> uploadFile(File file) async {
    final fileName = file.path.split('/').last;

    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });

    final response = await _dio.post('/upload-files', data: formData);

    print('response raw: ${response.data}');

    final data = response.data;

    final success = data['success'].toString().toLowerCase() == 'true';

    print('response raw is ooooooji : $data : $success : ${data['success']} : ${response.statusCode}');

    if ((response.statusCode == 200 || response.statusCode == 201) && success) {
      return Uri.decodeFull(data['fileUrl'].toString());
    } else {
      throw Exception('File upload failed: ${data['message']}');
    }
  }


}
