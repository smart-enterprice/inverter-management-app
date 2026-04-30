import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/brand_model.dart';
import '../../../network/dio_client.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepository(ref.watch(dioClientProvider));
});

class BrandRepository {
  const BrandRepository(this._dio);

  final Dio _dio;

  Future<void> createBrand(BrandModel request) async {
    await _dio.post(
      '/product-details/create/brands',
      data: [request.toJsonCreate()],
    );
  }

  Future<List<BrandModel>> getBrands() async {
    print('🌐 Repository: calling /product-details/getAll/brands');
    try {
      final response = await _dio.get('/product-details/getAll/brands');
      print('📦 Response status: ${response.statusCode}');
      print('📦 Response data: ${response.data}');
      return (response.data['data'] as List)
          .map((e) => BrandModel.fromJson(e))
          .toList();
    } catch (e) {
      print('❌ Repository ERROR: $e');
      rethrow;
    }
  }

  Future<BrandModel?> getBrandById(String brandId) async {
    final response =
    await _dio.get('/product-details/product-brand/$brandId');
    if (response.statusCode == 200 && response.data['data'] != null) {
      return BrandModel.fromJson(response.data['data']);
    }
    return null;
  }

  Future<void> updateBrand(
      BrandModel updatedData,
      String name, {
        Map<String, String>? brandModelsUpdate,
        List<String>? deletedModels,
        List<String>? addModel,
      }) async {
    final response = await _dio.put(
      '/product-details/brand/$name',
      data: updatedData.toJsonUpdate(
        brandModelsUpdate: brandModelsUpdate,
        deletedModels: deletedModels,
        addModel: addModel,
      ),
    );
    if (response.statusCode != 200 && response.statusCode != 204) {
      throw Exception('Failed to update brand');
    }
  }

  Future<List<BrandModel>> getActiveBrands() async {
    final response =
    await _dio.get('/product-details/getAll/brands?&status=active');
    return (response.data['data'] as List)
        .map((e) => BrandModel.fromJson(e))
        .where((b) => b.status?.toLowerCase() == 'active')
        .toList();
  }

  Future<void> deleteBrand(String brandId) async {
    await _dio.delete('/brand/$brandId');
  }

  Future<List<BrandModel>> getBrandsByDealer(String dealerId) async {
    final response = await _dio.get(
      '/product-details/getAll/brands?dealerId=$dealerId&status=active',
    );
    return (response.data['data'] as List)
        .map((e) => BrandModel.fromJson(e))
        .toList();
  }
}