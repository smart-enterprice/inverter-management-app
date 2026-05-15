import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/brand_model.dart';
import '../../../network/app_exception.dart';
import '../../../network/dio_client.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepository(ref.watch(dioClientProvider));
});

class BrandRepository {
  const BrandRepository(this._dio);

  final Dio _dio;

  Future<void> createBrand(BrandModel request) {
    return guardDio(
      () => _dio.post(
        '/product-details/create/brands',
        data: [request.toJsonCreate()],
      ),
      fallback: 'Create brand failed',
    );
  }

  Future<List<BrandModel>> getBrands() {
    return guardDio(() async {
      final response = await _dio.get('/product-details/getAll/brands');
      return (response.data['data'] as List)
          .map((e) => BrandModel.fromJson(e))
          .toList();
    });
  }

  Future<BrandModel?> getBrandById(String brandId) {
    return guardDio(() async {
      final response = await _dio.get('/product-details/product-brand/$brandId');
      final data = response.data['data'];
      return data == null ? null : BrandModel.fromJson(data);
    });
  }

  Future<void> updateBrand(
    BrandModel updatedData,
    String name, {
    Map<String, String>? brandModelsUpdate,
    List<String>? deletedModels,
    List<String>? addModel,
  }) {
    return guardDio(
      () => _dio.put(
        '/product-details/brand/$name',
        data: updatedData.toJsonUpdate(
          brandModelsUpdate: brandModelsUpdate,
          deletedModels: deletedModels,
          addModel: addModel,
        ),
      ),
      fallback: 'Update brand failed',
    );
  }

  Future<List<BrandModel>> getActiveBrands() {
    return guardDio(() async {
      final response =
          await _dio.get('/product-details/getAll/brands?&status=active');
      return (response.data['data'] as List)
          .map((e) => BrandModel.fromJson(e))
          .where((b) => b.status?.toLowerCase() == 'active')
          .toList();
    });
  }

  Future<void> deleteBrand(String brandId) {
    return guardDio(
      () => _dio.delete('/brand/$brandId'),
      fallback: 'Delete brand failed',
    );
  }

  Future<List<BrandModel>> getBrandsByDealer(String dealerId) {
    return guardDio(() async {
      final response = await _dio.get(
        '/product-details/getAll/brands?dealerId=$dealerId&status=active',
      );
      return (response.data['data'] as List)
          .map((e) => BrandModel.fromJson(e))
          .toList();
    });
  }
}
