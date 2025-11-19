import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/user_model.dart';
import '../repository/signUp_repository.dart';
import '../screen/dealer/dealers_screen.dart';

final signupControllerProvider =
StateNotifierProvider<SignupController, AsyncValue<void>>((ref) {
  final repository = ref.read(signupRepositoryProvider);
  return SignupController(repository);
});

/// Provider to get employee list (excluding dealers)
final userListProvider = FutureProvider<List<UserModel>>((ref) async {
  final repository = ref.read(signupRepositoryProvider);
  return repository.getEmployees();
});

/// Provider to get dealer list
final dealerListProvider =
StateNotifierProvider<DealerListNotifier, AsyncValue<List<UserModel>>>(
      (ref) => DealerListNotifier(ref.read(signupRepositoryProvider)),
);

/// Provider to get users by role
final usersByRoleProvider = FutureProvider.family<List<UserModel>, String>((ref, role) async {
  final controller = ref.read(signupControllerProvider.notifier);
  return await controller.getUsersByRole(role);
});


class SignupController extends StateNotifier<AsyncValue<void>> {
  final SignupRepository _repository;

  SignupController(this._repository) : super(const AsyncData(null));

  /// Signup user
  Future<String?> signup(UserModel request,{File? photoFile}) async {
    state = const AsyncLoading();
    try {
      // ✅ Step 1: Upload photo if selected
      if (photoFile != null) {
        final fileUrl = await _repository.uploadFile(photoFile);

        request = request.copyWith(photo: fileUrl); // replace local path with URL
      }

      // ✅ Step 2: Call signup API
      await _repository.userSignup(request);

      state = const AsyncData(null);
      return null;
    } on DioException catch (e, st) {
      String msg = 'Signup failed.';
      final responseData = e.response?.data;

      if (responseData is Map<String, dynamic>) {
        if (responseData['errors'] != null &&
            responseData['errors'] is List &&
            responseData['errors'][0]['message'] != null) {
          msg = responseData['errors'][0]['message'];
        } else if (responseData['message'] != null) {
          msg = responseData['message'];
        }
      } else if (responseData is String) {
        msg = responseData;
      } else {
        msg = responseData.toString();
      }

      print('Signup failed: $msg');
      state = AsyncError(e, st);
      return msg;
    } catch (e, st) {
      print('Unexpected error: $e');
      state = AsyncError(e, st);
      return 'Something went wrong';
    }
  }

  /// Get employee by ID
  Future<UserModel?> getEmployeeById(String id) async {
    try {
      return await _repository.getEmployeeById(id);
    } catch (e) {
      print('Error fetching user by ID: $e');
      return null;
    }
  }


  /// Get users
  Future<List<UserModel>> getEmployees() async {
    return await _repository.getEmployees();
  }

  /// Get dealers
  Future<List<UserModel>> getDealers() async {
    return await _repository.getDealers();
  }

  /// Update user
  Future<String?> updateUser({
    required UserModel oldUser,
    String? name,
    String? email,
    String? phone,
    String? shopName,
    String? role,
    String? photo, // This could be local path or existing URL
    String? address,
    String? town,
    String? district,
    List<String>? brand,
    File? photoFile, // Add this parameter for new photo file
  }) async {
    state = const AsyncLoading();

    try {
      String? finalPhotoUrl = photo;

      // If a new photo file is provided, upload it first
      if (photoFile != null) {
        finalPhotoUrl = await _repository.uploadFile(photoFile);
      }

      final updatedUser = oldUser.copyWith(
        employeeName: name,
        employeeEmail: email,
        employeePhone: phone,
        shopName: shopName,
        role: role,
        photo: finalPhotoUrl, // Use uploaded URL or existing URL
        address: address,
        town: town,
        district: district,
        brand: brand,
      );

      if (updatedUser.employeeId == null || updatedUser.employeeId!.isEmpty) {
        throw Exception('employeeId is required for update');
      }

      await _repository.updateUser(updatedUser.employeeId!, updatedUser);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString();
    }
  }

  /// ----------------- Get Users by Role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      final users = await _repository.getUsersByRole(role);
      return users;
    } catch (e) {
      print('Error fetching users by role: $e');
      rethrow;
    }
  }

  /// Delete user
  Future<String?> deleteUser(String employeeId, String reason) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteUser(employeeId, reason);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Delete failed: $e';
    }
  }

}
