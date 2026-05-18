import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../feature/brand/model/brand_model.dart';
import '../../../core/network/app_exception.dart';
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
    FutureProvider.autoDispose.family<BrandModel, String>((ref, brandId) {
  return ref.watch(brandRepositoryProvider).getBrandById(brandId).then(
        (b) => b ?? (throw Exception('Brand not found')),
      );
});

/// Brands by dealer ID
final dealerBrandsProvider =
    FutureProvider.autoDispose.family<List<BrandModel>, String>((ref, dealerId) {
  return ref.watch(brandRepositoryProvider).getBrandsByDealer(dealerId);
});

// ─── BrandController (all brands + mutations) ─────────────────────────────────

class BrandController extends AsyncNotifier<List<BrandModel>> {
  late BrandRepository _repo;

  @override
  Future<List<BrandModel>> build() {
    _repo = ref.watch(brandRepositoryProvider);
    return _repo.getBrands();
  }

  Future<String?> createBrand(BrandModel model) async {
    try {
      await _repo.createBrand(model);
      ref.invalidateSelf();
      return null;
    } on AppException catch (e) {
      return e.message;
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
    } on AppException catch (e) {
      return e.message;
    }
  }

  Future<String?> deleteBrand(String brandId) async {
    try {
      await _repo.deleteBrand(brandId);
      ref.invalidateSelf();
      return null;
    } on AppException catch (e) {
      return e.message;
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

