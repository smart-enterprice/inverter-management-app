import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/brand_model.dart';
import '../../../network/dio_client.dart';

final brandRepositoryProvider = Provider<BrandRepository>((ref) {
  return BrandRepository();
});


class BrandRepository {
  final Dio _dio = DioClient.instance;

  /// ------------------------- ✅ Create a new brand
  Future<void> createBrand(BrandModel request) async {
      final response = await _dio.post(
        '/product-details/create/brands',
        data: [request.toJsonCreate()], // ✅ Flat object, not wrapped
      );
  }

  /// ------------------------- Get list of all brands
  Future<List<BrandModel>> getBrands() async {
    final response = await _dio.get('/product-details/getAll/brands');

    final brandList = (response.data['data'] as List)
        .map((e) => BrandModel.fromJson(e))
        .toList();

    return brandList;
  }
  /// ------------------------- ✅ Get brand by ID
  Future<BrandModel?> getBrandById(String brandId) async {
    try {
      final response =
      await _dio.get('/product-details/product-brand/$brandId');

      if (response.statusCode == 200 && response.data['data'] != null) {
        return BrandModel.fromJson(response.data['data']);
      }
      return null;
    } on DioException catch(e) {
      throw e.message!;
    } catch (e) {
      throw Exception("Unexpected error: $e");
    }
  }

  /// ------------------------- Update an existing brand
  /// ------------------------- Update an existing brand
  Future<void> updateBrand(
      BrandModel updatedData,
      String name, {
        Map<String, String>? brandModelsUpdate,
        List<String>? deletedModels,
        List<String>? addModel
      }) async
  {
    try {
      final response = await _dio.put(
        '/product-details/brand/$name',
        data: updatedData.toJsonUpdate(
          brandModelsUpdate: brandModelsUpdate,
          deletedModels: deletedModels,
          addModel: addModel
        ),
      );


      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Brand updated successfully');
      } else {
        throw Exception('❌ Failed to update brand');
      }
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String errorMessage = 'Update failed';
      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ?? errorMessage;
        }
      }
      print('❌ DioException in updateBrand: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Non-Dio exception in updateBrand: $e');
      throw Exception('Update error: $e');
    }
  }

  /// ------------------------- Get active Brand
  Future<List<BrandModel>> getActiveBrands() async {
    final response = await _dio.get('/product-details/getAll/brands?&status=active');
    final brandList = (response.data['data'] as List)
        .map((e) => BrandModel.fromJson(e))
        .toList();

    // Filter only active brands
    final activeBrands = brandList
        .where((brand) => brand.status?.toLowerCase() == 'active')
        .toList();

    return activeBrands;
  }

  /// ------------------------- Delete brand by ID
  Future<void> deleteBrand(String brandId) async {
    try {
      final response = await _dio.delete('/brand/$brandId');

      if (response.statusCode == 200 || response.statusCode == 204) {
        print('✅ Brand deleted successfully');
      } else {
        throw Exception('❌ Failed to delete brand');
      }
    } catch (e) {
      throw Exception('Delete error: $e');
    }
  }
  //------------------------------------------------------------------//

  /// ------------------------- ✅ Get  brands by dealer ID
  Future<List<BrandModel>> getBrandsByDealer(String dealerId) async {
    try {
      final response = await _dio.get(
        '/product-details/getAll/brands?dealerId=$dealerId&status=active',
      );

      final brandList = (response.data['data'] as List)
          .map((e) => BrandModel.fromJson(e))
          .toList();

      return brandList;
    } on DioException catch (e) {
      final statusCode = e.response?.statusCode;
      String errorMessage = 'Failed to fetch active brands for dealer';

      if (e.response?.data != null) {
        final responseData = e.response!.data;
        if (responseData is Map<String, dynamic>) {
          errorMessage = responseData['message'] ?? errorMessage;
        }
      }

      print('❌ DioException in getActiveBrandsByDealer: $errorMessage');
      throw Exception(errorMessage);
    } catch (e) {
      print('❌ Non-Dio exception in getActiveBrandsByDealer: $e');
      throw Exception('Unexpected error: $e');
    }
  }


}
