import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/brand_model.dart';
import '../repository/brand_repository.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

/// All brands list — used by most screens
final brandControllerProvider =
AsyncNotifierProvider<BrandController, List<BrandModel>>(
  BrandController.new,
);

/// Active brands only — separate notifier, separate state
final activeBrandControllerProvider =
AsyncNotifierProvider<ActiveBrandController, List<BrandModel>>(
  ActiveBrandController.new,
);

/// Single brand by ID
final brandByIdProvider =
FutureProvider.family<BrandModel, String>((ref, brandId) {
  return ref.watch(brandRepositoryProvider).getBrandById(brandId).then(
        (b) => b ?? (throw Exception('Brand not found')),
  );
});

/// Brands by dealer ID
final dealerBrandsProvider =
FutureProvider.family<List<BrandModel>, String>((ref, dealerId) {
  return ref.watch(brandRepositoryProvider).getBrandsByDealer(dealerId);
});

// ─── BrandController (all brands + mutations) ─────────────────────────────────

class BrandController extends AsyncNotifier<List<BrandModel>> {
  late  BrandRepository _repo;

  @override
  Future<List<BrandModel>> build() async {
    _repo = ref.watch(brandRepositoryProvider);
    print('🔄 BrandController: fetching brands...');
    try {
      final result = await _repo.getBrands();
      print('✅ BrandController: got ${result.length} brands');
      return result;
    } catch (e, st) {
      print('❌ BrandController ERROR: $e');
      print('📍 StackTrace: $st');
      rethrow;
    }
  }

  Future<String?> createBrand(BrandModel model) async {
    try {
      await _repo.createBrand(model);
      ref.invalidateSelf(); // re-fetch list
      return null;
    } on DioException catch (e) {
      return _extractDioError(e, fallback: 'Create brand failed');
    } catch (_) {
      return 'Something went wrong';
    }
  }

  Future<String?> updateBrand(
      BrandModel model,
      String name, {
        Map<String, String>? brandModelsUpdate,
        List<String>? deletedModels,
        List<String>? addModel,
      }) async {
    try {
      await _repo.updateBrand(
        model,
        name,
        brandModelsUpdate: brandModelsUpdate,
        deletedModels: deletedModels,
        addModel: addModel,
      );
      ref.invalidateSelf();
      return null;
    } on DioException catch (e) {
      return _extractDioError(e, fallback: 'Update brand failed');
    } catch (_) {
      return 'Something went wrong';
    }
  }

  Future<String?> deleteBrand(String brandId) async {
    try {
      await _repo.deleteBrand(brandId);
      ref.invalidateSelf();
      return null;
    } on DioException catch (e) {
      return _extractDioError(e, fallback: 'Delete brand failed');
    } catch (_) {
      return 'Something went wrong';
    }
  }

  // ── Synchronous helpers (read from current state) ───────────────────────────

  List<String> get brandNames {
    final brands = state.valueOrNull;
    if (brands == null) return [];
    return brands
        .map((b) => b.brandName)
        .where((n) => n.isNotEmpty)
        .toList()
      ..sort();
  }
  BrandModel? getBrandByName(String name) => state.valueOrNull
      ?.where((b) => b.brandName == name)
      .firstOrNull;
}

// ─── ActiveBrandController (read-only, separate state) ────────────────────────

class ActiveBrandController extends AsyncNotifier<List<BrandModel>> {
  @override
  Future<List<BrandModel>> build() {
    return ref.watch(brandRepositoryProvider).getActiveBrands();
  }
}

// ─── Shared error helper ──────────────────────────────────────────────────────

String _extractDioError(DioException e, {required String fallback}) {
  final data = e.response?.data;
  if (data is Map<String, dynamic>) {
    if (data['message'] != null) return data['message'] as String;
    final errors = data['errors'];
    if (errors is List && errors.isNotEmpty) {
      return errors[0]['message'] as String? ?? fallback;
    }
  }
  if (data is String) return data;
  return fallback;
}