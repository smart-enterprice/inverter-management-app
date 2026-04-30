import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../model/user_model.dart';
import '../repository/signUp_repository.dart';

// ─────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────

final signupControllerProvider =
AsyncNotifierProvider<SignupController, void>(
  SignupController.new,
);

final employeeByIdProvider =
FutureProvider.family<UserModel?, String>((ref, id) async {
  if (id.isEmpty) return null;
  return ref.read(signupControllerProvider.notifier).getEmployeeById(id);
});

final userListProvider = FutureProvider<List<UserModel>>((ref) async {
  return ref.read(signupRepositoryProvider).getEmployees();
});

final dealerListProvider =
AsyncNotifierProvider<DealerListNotifier, List<UserModel>>(
  DealerListNotifier.new,
);

final usersByRoleProvider =
FutureProvider.family<List<UserModel>, String>((ref, role) async {
  return ref.read(signupControllerProvider.notifier).getUsersByRole(role);
});

final currentUserProvider = FutureProvider<UserModel?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');
  if (userId == null) return null;
  print('Current user is refreshing');
  return ref.read(signupControllerProvider.notifier).getEmployeeById(userId);
});

// ─────────────────────────────────────────────
// SignupController — AsyncNotifier<void>
// ─────────────────────────────────────────────

class SignupController extends AsyncNotifier<void> {
  late final SignupRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.watch(signupRepositoryProvider);
  }

  /// Signup user
  Future<String?> signup(UserModel request, {File? photoFile}) async {
    state = const AsyncLoading();
    try {
      if (photoFile != null) {
        final fileUrl = await _repo.uploadFile(photoFile);
        request = request.copyWith(photo: fileUrl);
      }
      await _repo.userSignup(request);
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
  Future<UserModel> getEmployeeById(String id) async {
    try {
      return await _repo.getEmployeeById(id);
    } catch (e) {
      rethrow;
    }
  }

  /// Get employees
  Future<List<UserModel>> getEmployees() async {
    return _repo.getEmployees();
  }

  /// Get dealers
  Future<List<UserModel>> getDealers() async {
    return _repo.getDealers();
  }

  /// Update user
  Future<String?> updateUser({
    required UserModel oldUser,
    String? name,
    String? email,
    String? phone,
    String? shopName,
    String? role,
    String? photo,
    String? address,
    String? town,
    String? district,
    List<String>? brand,
    File? photoFile,
    List<String>? addBrands,
    List<String>? removeBrands,
  }) async {
    state = const AsyncLoading();
    try {
      String? finalPhotoUrl = photo;
      if (photoFile != null) {
        finalPhotoUrl = await _repo.uploadFile(photoFile);
      }

      final updatedUser = oldUser.copyWith(
        employeeName: name,
        employeeEmail: email,
        employeePhone: phone,
        shopName: shopName,
        role: role,
        photo: finalPhotoUrl,
        address: address,
        town: town,
        district: district,
        brand: brand,
      );

      if (updatedUser.employeeId == null || updatedUser.employeeId!.isEmpty) {
        throw Exception('employeeId is required for update');
      }

      await _repo.updateUser(
        updatedUser.employeeId!,
        updatedUser,
        addBrands: addBrands,
        removeBrands: removeBrands,
      );
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString();
    }
  }

  /// Get users by role
  Future<List<UserModel>> getUsersByRole(String role) async {
    try {
      return await _repo.getUsersByRole(role);
    } catch (e) {
      print('Error fetching users by role: $e');
      rethrow;
    }
  }

  /// Delete user
  Future<String?> deleteUser(String employeeId, String reason) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteUser(employeeId, reason);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Delete failed: $e';
    }
  }
}

// ─────────────────────────────────────────────
// DealerListNotifier — AsyncNotifier
// ─────────────────────────────────────────────

class DealerListNotifier extends AsyncNotifier<List<UserModel>> {
  late final SignupRepository _repo;
  int _page = 1;
  static const int _limit = 20;
  bool _hasMore = true;
  bool _isLoadingMore = false;

  bool get hasMore => _hasMore;
  bool get isLoadingMore => _isLoadingMore;

  @override
  Future<List<UserModel>> build() async {
    _repo = ref.watch(signupRepositoryProvider);
    _page = 1;
    _hasMore = true;
    return _repo.getDealers(page: _page, limit: _limit);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    try {
      _page = 1;
      _hasMore = true;
      final dealers = await _repo.getDealers(page: _page, limit: _limit);
      if (dealers.length < _limit) _hasMore = false;
      state = AsyncData(dealers);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !_hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _isLoadingMore = true;
    try {
      _page++;
      final more = await _repo.getDealers(page: _page, limit: _limit);
      if (more.length < _limit) _hasMore = false;
      state = AsyncData([...current, ...more]);
    } catch (_) {
      _page--;
      rethrow;
    } finally {
      _isLoadingMore = false;
    }
  }
}