import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../feature/product/model/product_model.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/dio_client.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository(ref.watch(dioClientProvider));
});

class ProductRepository {
  const ProductRepository(this._dio);

  final Dio _dio;

  Future<void> createProduct(ProductModel product) {
    return guardDio(
      () => _dio.post('/product-details/create-product', data: product.toJson()),
      fallback: 'Create product failed',
    );
  }

  Future<List<ProductModel>> getProducts({
    int page = 1,
    int limit = 20,
    String? search,
    String? type,
    String? status,
    String? category,
    String? brand,
    List<String>? brands,
    String? model,
  }) {
    return guardDio(() async {
      String? brandParam;
      if (brands != null && brands.isNotEmpty) {
        brandParam = brands.join(',');
      } else if (brand != null && brand.isNotEmpty) {
        brandParam = brand;
      }

      final response = await _dio.get(
        '/product-details/get/all',
        queryParameters: {
          'page': page,
          'limit': limit,
          if (search != null && search.isNotEmpty) 'search': search,
          if (type != null && type.isNotEmpty) 'type': type,
          if (status != null) 'status': status,
          if (category != null && category != 'All Categories')
            'category': category,
          if (brandParam != null) 'brand': brandParam,
          if (model != null && model.isNotEmpty) 'model': model,
        },
      );
      return (response.data['data'] as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    });
  }

  Future<List<ProductModel>> getProductsByBrand(List<String> brands) {
    return guardDio(() async {
      final response = await _dio.post(
        '/product-details/getAllProductsByBrand',
        data: {'brands': brands},
      );
      return (response.data['data'] as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
    });
  }

  Future<ProductModel> getProductById(String productId) {
    return guardDio(() async {
      final response = await _dio.get('/product-details/$productId');
      return ProductModel.fromJson(response.data['data']);
    });
  }

  Future<void> updateProduct(String productId, ProductModel updatedProduct) {
    return guardDio(
      () => _dio.put('/product-details/$productId', data: updatedProduct.toJson()),
      fallback: 'Update product failed',
    );
  }

  Future<void> updateStock(StockUpdate updateStockModel) {
    return guardDio(
      () => _dio.put(
        '/product-details/createOrUpdate/product-stocks',
        data: updateStockModel.toJson(),
      ),
      fallback: 'Update stock failed',
    );
  }

  Future<void> deleteProduct(String productId, String reason) {
    return guardDio(
      () => _dio.put(
        '/products/update/delete-product',
        data: {'productId': productId, 'reason': reason},
      ),
      fallback: 'Delete product failed',
    );
  }

  Future<List<ProductModel>> getLowStockProducts({int threshold = 5}) {
    return guardDio(
      () async {
        final response = await _dio.get(
          '/product-details/low-stock',
          queryParameters: {
            'page': 1,
            'limit': 1000,
            'threshold': threshold,
          },
        );
        final dynamic dataList = response.data['data'];
        final List productsList =
            dataList is List ? dataList : dataList['data'] ?? [];
        return productsList
            .map((json) => ProductModel.fromJson(json))
            .toList();
      },
      fallback: 'Failed to fetch low stock products',
    );
  }
}
