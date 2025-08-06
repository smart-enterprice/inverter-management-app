import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/brand_model.dart';
import '../repository/brand_repository.dart';

final brandControllerProvider =
StateNotifierProvider<BrandController, AsyncValue<List<BrandModel>>>((ref) {
  final repository = ref.read(brandRepositoryProvider);
  return BrandController(repository)..loadBrands();
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

  /// Create a brand and refresh list
  Future<void> createBrand(BrandModel model) async {
    try {
      await _repository.createBrand(model);
      await loadBrands(); // refresh after create
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Update a brand and refresh list
  Future<void> updateBrand(BrandModel model,name) async {
    try {
      await _repository.updateBrand(model,name);
      await loadBrands(); // refresh after update
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Delete a brand and refresh list
  Future<void> deleteBrand(String brandId) async {
    try {
      await _repository.deleteBrand(brandId);
      await loadBrands(); // refresh after delete
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
}
