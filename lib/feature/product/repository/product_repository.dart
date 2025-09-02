// product_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/product_model.dart';
import '../../../network/dio_client.dart';

final productRepositoryProvider = Provider<ProductRepository>((ref) {
  return ProductRepository();
});

class ProductRepository {
  final Dio _dio = DioClient.instance;

  /// Create Product
  Future<void> createProduct(ProductModel product) async {
    print('product : ${product.toJson()}');
    await _dio.post('/product-details/create', data: product.toJson());
  }

  /// Get All Products
  Future<List<ProductModel>> getProducts() async {
    final response = await _dio.get('/product-details/');
    final products = (response.data['data'] as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
    return products;
  }

  /// Get Single Product by ID
  Future<ProductModel> getProductById(String productId) async {
    final response = await _dio.get('/product-details/$productId');
    return ProductModel.fromJson(response.data['data']);
  }

  /// Update Product
  Future<void> updateProduct(String productId, ProductModel updatedProduct) async {
    await _dio.put('/product-details/$productId', data: updatedProduct.toJson());
  }

  /// Delete Product
  Future<void> deleteProduct(String productId, String reason) async {
    await _dio.put('/products/update/delete-product', data: {
      'productId': productId,
      'reason': reason,
    });
  }
}
