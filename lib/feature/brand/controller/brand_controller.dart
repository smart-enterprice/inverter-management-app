import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/brand_model.dart';
import '../repository/brand_repository.dart';

final brandControllerProvider =
StateNotifierProvider<BrandController, AsyncValue<List<BrandModel>>>((ref) {
  final repository = ref.read(brandRepositoryProvider);
  return BrandController(repository)..loadActiveBrands();
});

class BrandController extends StateNotifier<AsyncValue<List<BrandModel>>> {
  final BrandRepository _repository;

  BrandController(this._repository) : super(const AsyncLoading());

  /// Load all brands
  Future<void> loadBrands() async {
    try {
      final brands = await _repository.getBrands();
      state = AsyncValue.data(brands);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Load only active brands
  Future<void> loadActiveBrands() async {
    try {
      final brands = await _repository.getActiveBrands();
      state = AsyncValue.data(brands);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create a brand and refresh list
  Future<String?> createBrand(BrandModel model) async {
    try {
      await _repository.createBrand(model);
      await loadBrands();
      return null;
    } on DioException catch (e, st) {
      String msg = 'Create brand failed.';
      final responseData = e.response?.data;

      if (responseData is Map<String, dynamic>) {
        // First check for direct message (matches your error format)
        if (responseData['message'] != null) {
          msg = responseData['message'];
        }
        // Then check for nested errors structure
        else if (responseData['errors'] != null &&
            responseData['errors'] is List &&
            responseData['errors'].isNotEmpty &&
            responseData['errors'][0]['message'] != null) {
          msg = responseData['errors'][0]['message'];
        }
      } else if (responseData is String) {
        msg = responseData;
      }

      print('Create brand failed: $msg');
      state = AsyncError(e, st);
      return msg;
    } catch (e, st) {
      print('Unexpected error: $e');
      state = AsyncError(e, st);
      return 'Something went wrong';
    }
  }



  /// Update a brand and refresh list
  Future<void> updateBrand(BrandModel model, String name) async {
    try {
      await _repository.updateBrand(model, name);
      await loadBrands(); // refresh all brands
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a brand and refresh list
  Future<void> deleteBrand(String brandId) async {
    try {
      await _repository.deleteBrand(brandId);
      await loadBrands(); // refresh all brands
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Get only brand names for dropdowns
  List<String> get brandNames {
    return state.when(
      data: (brands) => brands
          .map((b) => b.brandName)
          .where((name) => name.isNotEmpty)
          .toList()
        ..sort(),
      loading: () => [],
      error: (_, __) => [],
    );
  }
  /// Get full BrandModel by name
  BrandModel? getBrandByName(String name) {
    return state.whenOrNull(
      data: (brands) {
        for (final b in brands) {
          if (b.brandName == name) return b;
        }
        return null;
      },
    );
  }
}
