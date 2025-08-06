import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/user_model.dart';
import '../repository/signUp_repository.dart';

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

/// Optional: Provider to get dealer list
final dealerListProvider = FutureProvider.autoDispose<List<UserModel>>((ref) async {
  final repository = ref.read(signupRepositoryProvider);
  // Keeps the provider alive even if widgets using it are disposed
  final keepAlive = ref.keepAlive();
  // Cancel autoDispose after some time if needed (optional)
  final timer = Timer(const Duration(minutes: 5), () => keepAlive.close());
  ref.onDispose(() => timer.cancel());
  return repository.getDealers();
});


class SignupController extends StateNotifier<AsyncValue<void>> {
  final SignupRepository _repository;

  SignupController(this._repository) : super(const AsyncData(null));

  /// Signup user
  Future<String?> signup(UserModel request) async {
    state = const AsyncLoading();
    try {
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
    String? role,
    String? photo,
    String? address,
    String? town,
    String? district,
    List<String>? brand,
  }) async {
    state = const AsyncLoading();

    try {
      final updatedUser = oldUser.copyWith(
        employeeName: name,
        employeeEmail: email,
        employeePhone: phone,
        role: role,
        photo: photo,
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
