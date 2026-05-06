import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../model/user_model.dart';
import '../../../network/dio_client.dart';

final signupRepositoryProvider = Provider<SignupRepository>((ref) {
  return SignupRepository();
});

class SignupRepository {
  final Dio _dio = DioClient.instance;

  Future<Response> userSignup(UserModel request) async {
    return await _dio.post('/employees/signup', data: request.toJson());
  }

  Future<List<UserModel>> getEmployees({int page = 1, int limit = 20}) async {
    final response = await _dio.get('/employees?page=$page&limit=$limit');
    final employeeList = (response.data['data']['employees'] as List)
        .map((e) => UserModel.fromJson(e))
        .where((user) => user.role != 'ROLE_DEALER')
        .toList();
    return employeeList;
  }

  /// ─────────────────────────────────────────────────────────────────────
  /// getDealers
  ///
  /// Hits GET /employees with role=ROLE_DEALER + includeDealers=true.
  /// This is the same endpoint the React web app uses and it supports
  /// server-side search out of the box.
  /// ─────────────────────────────────────────────────────────────────────
  Future<List<UserModel>> getDealers({
    int page = 1,
    int limit = 20,
    String? search,
    String? status, // "active" / "inactive" / "deleted"
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'role': 'ROLE_DEALER',
      'includePassword': false,
      'includeDealers': true,
      if (search != null && search.isNotEmpty) 'search': search,
      if (status != null && status.isNotEmpty) 'status': status,
    };

    debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');
    debugPrint('📤 [getDealers] /employees → $queryParams');

    try {
      // ✅ The correct endpoint
      final response = await _dio.get(
        '/employees',
        queryParameters: queryParams,
      );

      final rawList = response.data['data']?['employees'] as List?;
      final meta = response.data['data'] as Map?;
      debugPrint('📥 [getDealers] ${rawList?.length ?? 0} items '
          '(total=${meta?['total']}, pages=${meta?['pages']})');
      debugPrint('   Real URL: ${response.realUri}');
      debugPrint('━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━');

      return (response.data['data']['employees'] as List)
          .map((e) => UserModel.fromJson(e))
          .toList();
    } on DioException catch (e) {
      debugPrint('❌ [getDealers] ERROR: ${e.message}');
      debugPrint('   Response: ${e.response?.data}');
      rethrow;
    }
  }

  /// Fetches ONLY the dealers already assigned to a specific salesman.
  /// Uses salesmanIds param so the server filters server-side.
  Future<List<UserModel>> getSalesmanDealers({
    required String salesmanId,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      'role': 'ROLE_DEALER',
      'status': 'active',
      'includeDealers': true,
      'salesmanIds': salesmanId,
      if (search != null && search.isNotEmpty) 'search': search,
    };

    debugPrint('📤 [getSalesmanDealers] /employees → $queryParams');

    try {
      final response = await _dio.get(
        '/employees',
        queryParameters: queryParams,
      );
      final rawList = response.data['data']?['employees'] as List? ?? [];
      debugPrint('📥 [getSalesmanDealers] ${rawList.length} items');
      return rawList.map((e) => UserModel.fromJson(e)).toList();
    } on DioException catch (e) {
      debugPrint('❌ [getSalesmanDealers] ERROR: ${e.message}');
      rethrow;
    }
  }

  Future<UserModel> getEmployeeById(String id) async {
    final response = await _dio.get('/employees/$id');
    return UserModel.fromJson(response.data['data']);
  }

  Future<void> updateUser(String employeeId, UserModel updatedData, {
    List<String>? addBrands,
    List<String>? removeBrands,
  }) async {
    try {
      final Map<String, dynamic> body = Map<String, dynamic>.from(updatedData.toJson());
      body.remove('brand');
      if (addBrands != null && addBrands.isNotEmpty) body['brand'] = addBrands;
      if (removeBrands != null && removeBrands.isNotEmpty) body['remove_brands'] = removeBrands;
      final response = await DioClient.instance.put('/employees/$employeeId', data: body);
      if (response.statusCode == 200 || response.statusCode == 204) return;
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Update failed');
    } catch (e) {
      throw Exception('Update error: $e');
    }
  }

  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final response = await _dio.get('/employees/getByRole/$role');
      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => UserModel.fromJson(e)).toList();
      }
      throw Exception('Failed to fetch users by role');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message']?.toString() ?? e.message.toString());
    }
  }

  Future<void> deleteUser(String employeeId, String reason) async {
    try {
      final response = await DioClient.instance.put(
        '/employees/update/delete-employee',
        data: {'employeeId': employeeId, 'reason': reason},
      );
      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw Exception('Failed to delete employee');
    } catch (e) {
      throw Exception('Delete error: $e');
    }
  }
/// for salesman
  Future<void> updateDealers(String employeeId, {
    List<String>? addDealers,
    List<String>? removeDealers,
  }) async {
    try {
      final Map<String, dynamic> body = {};
      if (addDealers != null && addDealers.isNotEmpty) body['dealers'] = addDealers;
      if (removeDealers != null && removeDealers.isNotEmpty) body['remove_dealers'] = removeDealers;
      final response = await DioClient.instance.put('/employees/$employeeId', data: body);
      if (response.statusCode == 200 || response.statusCode == 204) return;
      throw Exception('Update failed');
    } on DioException catch (e) {
      throw Exception(e.response?.data?['message'] ?? 'Update failed');
    }
  }

  Future<String?> uploadFile(File file) async {
    final fileName = file.path.split('/').last;
    final formData = FormData.fromMap({
      'file': await MultipartFile.fromFile(file.path, filename: fileName),
    });
    final response = await _dio.post('/upload-files', data: formData);
    final data = response.data;
    final success = data['success'].toString().toLowerCase() == 'true';
    if ((response.statusCode == 200 || response.statusCode == 201) && success) {
      return Uri.decodeFull(data['fileUrl'].toString());
    }
    throw Exception('File upload failed: ${data['message']}');
  }
}