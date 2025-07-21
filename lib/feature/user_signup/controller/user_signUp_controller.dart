import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/user_model.dart';
import '../repository/user_signUp_repository.dart';

import 'package:dio/dio.dart'; // Make sure this is imported
final signupControllerProvider =
StateNotifierProvider<SignupController, AsyncValue<void>>((ref) {
  final repository = ref.read(employeeSignupRepositoryProvider);
  return SignupController(repository);
});

final employeeListProvider = FutureProvider<List<EmployeeRegisterRequest>>((ref) async {
  final repository = ref.read(employeeSignupRepositoryProvider);
  return repository.getEmployees();
});



class SignupController extends StateNotifier<AsyncValue<void>> {
  final EmployeeSignupRepository _repository;

  SignupController(this._repository) : super(const AsyncData(null));

  /// Signup user
  Future<String?> signup(EmployeeRegisterRequest request) async {
    state = const AsyncLoading();
    try {
      await _repository.signup(request);
      state = const AsyncData(null);
      return null; // success
    } on DioException catch (e, st) {
      final statusCode = e.response?.statusCode;
      print('DioException caught: $statusCode');
      print('Response data: ${e.response?.data}');

      String msg = 'Update failed.';

      final responseData = e.response?.data;

      if (responseData is Map<String, dynamic>) {
        if (responseData['errors'] != null &&
            responseData['errors'] is List &&
            responseData['errors'].isNotEmpty &&
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

      print('Signup failed with status $statusCode: $msg');
      state = AsyncError(e, st);
      return msg; // <- just return the message directly
    } catch (e, st) {
      print('Unexpected error: $e');
      state = AsyncError(e, st);
      return 'Something went wrong';
    }
  }


  /// get users
  Future<List<EmployeeRegisterRequest>> getEmployees() async {
    final allUsers = await _repository.getEmployees();
    final users = allUsers.toList();
    return users;
  }

  /// update user data
  Future<String?> updateUser({
    required EmployeeRegisterRequest oldUser,
    String? name,
    String? email,
    String? phone,
    String? role,
    String? photo,
    String? address,
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
        // password: widget.user.password
      );
      // Ensure employeeId exists before calling
      if (updatedUser.employeeId == null || updatedUser.employeeId!.isEmpty) {
        throw Exception('employeeId is required for update');
      }

      await _repository.updateEmployee(updatedUser.employeeId!, updatedUser);

      state = const AsyncData(null);
      return null;
    }  on DioException catch (e, st) {
      final statusCode = e.response?.statusCode;
      final msg = e.response?.data['message'] ?? 'update failed.';
      // Log for debug (optional)
      print('Signup failed with status $statusCode: $msg');
      state = AsyncError(e, st);
      return msg;
    }catch (e, st) {
      state = AsyncError(e, st);
      // return 'something went wrong';
      return e.toString();
    }
  }

  Future<String?> deleteUser(String employeeId, String reason) async {
    state = const AsyncLoading();
    try {
      await _repository.deleteEmployee(employeeId, reason);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Delete failed: $e';
    }
  }


}

