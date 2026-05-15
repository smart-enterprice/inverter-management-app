import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../../../network/app_exception.dart';
import '../../../network/dio_client.dart';

final signupRepositoryProvider = Provider<SignupRepository>((ref) {
  return SignupRepository(ref.watch(dioClientProvider));
});

class SignupRepository {
  const SignupRepository(this._dio);

  final Dio _dio;

  Future<Response> userSignup(UserModel request) {
    return guardDio(
      () => _dio.post('/employees/signup', data: request.toJson()),
      fallback: 'Signup failed',
    );
  }

  Future<List<UserModel>> getEmployees({int page = 1, int limit = 20}) {
    return guardDio(() async {
      final response =
          await _dio.get('/employees?page=$page&limit=$limit');
      return (response.data['data']['employees'] as List)
          .map((e) => UserModel.fromJson(e))
          .where((user) => user.role != 'ROLE_DEALER')
          .toList();
    });
  }

  Future<List<UserModel>> getDealers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status,
  }) {
    return guardDio(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'role': 'ROLE_DEALER',
        'includePassword': false,
        'includeDealers': true,
        if (search != null && search.isNotEmpty) 'search': search,
        if (status != null && status.isNotEmpty) 'status': status,
      };
      final response = await _dio.get('/employees', queryParameters: queryParams);
      return (response.data['data']['employees'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
    });
  }

  Future<List<UserModel>> getSalesmanDealers({
    required String salesmanId,
    int page = 1,
    int limit = 20,
    String? search,
  }) {
    return guardDio(() async {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
        'role': 'ROLE_DEALER',
        'status': 'active',
        'includeDealers': true,
        'salesmanIds': salesmanId,
        if (search != null && search.isNotEmpty) 'search': search,
      };
      final response = await _dio.get('/employees', queryParameters: queryParams);
      final rawList = response.data['data']?['employees'] as List? ?? [];
      return rawList.map((e) => UserModel.fromJson(e)).toList();
    });
  }

  Future<UserModel> getEmployeeById(String id) {
    return guardDio(() async {
      final response = await _dio.get('/employees/$id');
      return UserModel.fromJson(response.data['data']);
    });
  }

  Future<void> updateUser(
    String employeeId,
    UserModel updatedData, {
    List<String>? addBrands,
    List<String>? removeBrands,
  }) {
    return guardDio(
      () async {
        final body = Map<String, dynamic>.from(updatedData.toJson());
        body.remove('brand');
        if (addBrands != null && addBrands.isNotEmpty) body['brand'] = addBrands;
        if (removeBrands != null && removeBrands.isNotEmpty) {
          body['remove_brands'] = removeBrands;
        }
        await _dio.put('/employees/$employeeId', data: body);
      },
      fallback: 'Update failed',
    );
  }

  Future<List<UserModel>> getUsersByRole(String role) {
    return guardDio(() async {
      final response = await _dio.get('/employees/getByRole/$role');
      final List data = response.data['data'] ?? [];
      return data.map((e) => UserModel.fromJson(e)).toList();
    });
  }

  Future<void> deleteUser(String employeeId, String reason) {
    return guardDio(
      () => _dio.put(
        '/employees/update/delete-employee',
        data: {'employeeId': employeeId, 'reason': reason},
      ),
      fallback: 'Delete failed',
    );
  }

  Future<void> updateDealers(
    String employeeId, {
    List<String>? addDealers,
    List<String>? removeDealers,
  }) {
    return guardDio(
      () async {
        final body = <String, dynamic>{};
        if (addDealers != null && addDealers.isNotEmpty) {
          body['dealers'] = addDealers;
        }
        if (removeDealers != null && removeDealers.isNotEmpty) {
          body['remove_dealers'] = removeDealers;
        }
        await _dio.put('/employees/$employeeId', data: body);
      },
      fallback: 'Update failed',
    );
  }

  Future<String?> uploadFile(File file) {
    return guardDio(
      () async {
        final fileName = file.path.split('/').last;
        final formData = FormData.fromMap({
          'file': await MultipartFile.fromFile(file.path, filename: fileName),
        });
        final response = await _dio.post('/upload-files', data: formData);
        final data = response.data;
        final success = data['success'].toString().toLowerCase() == 'true';
        if (success) {
          return Uri.decodeFull(data['fileUrl'].toString());
        }
        throw AppException(
          (data['message'] as String?) ?? 'File upload failed',
        );
      },
      fallback: 'File upload failed',
    );
  }
}
