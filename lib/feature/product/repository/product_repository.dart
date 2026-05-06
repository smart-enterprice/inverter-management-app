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
    await _dio.post('/product-details/create-product', data: product.toJson());
  }

  /// Get All Products with pagination + filters
  ///
  /// Both `brand` (single, kept for backward compatibility) and `brands`
  /// (multi-select list) are supported. If `brands` has values, they are
  /// joined with commas — e.g. `brand=Acme,Globex`. Adjust the join format
  /// to whatever your backend expects.
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
  }) async {
    // Normalize brand selection: prefer multi-select if provided,
    // otherwise fall back to single brand string.
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
        if (category != null && category != 'All Categories') 'category': category,
        if (brandParam != null) 'brand': brandParam,
        if (model != null && model.isNotEmpty) 'model': model,
      },
    );
    final products = (response.data['data'] as List)
        .map((json) => ProductModel.fromJson(json))
        .toList();
    return products;
  }

  /// Get Products by Brand
  Future<List<ProductModel>> getProductsByBrand(List<String> brands) async {
    try {
      final response = await _dio.post(
        '/product-details/getAllProductsByBrand',
        data: {'brands': brands},
      );
      final products = (response.data['data'] as List)
          .map((json) => ProductModel.fromJson(json))
          .toList();
      return products;
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Something went wrong';
      print('❌ Error: $errorMessage');
      throw errorMessage;
    } catch (e) {
      print('⚠️ Unknown error: $e');
      throw Exception('Unexpected error occurred');
    }
  }

  /// Get Single Product by ID
  Future<ProductModel> getProductById(String productId) async {
    final response = await _dio.get('/product-details/$productId');
    return ProductModel.fromJson(response.data['data']);
  }

  /// Update Product
  Future<void> updateProduct(
      String productId, ProductModel updatedProduct) async {
    try {
      final response = await _dio.put(
        '/product-details/$productId',
        data: updatedProduct.toJson(),
      );
      print("SUCCESS: ${response.data}");
    } on DioException catch (e) {
      print("DIO ERROR:");
      print("Message: ${e.message}");
      print("Status: ${e.response?.statusCode}");
      print("Data: ${e.response?.data}");
      throw Exception(e.response?.data['message'] ?? e.message);
    } catch (e) {
      print("UNKNOWN ERROR: $e");
      throw Exception(e.toString());
    }
  }

  /// Update Stock
  Future<void> updateStock(StockUpdate updateStockModel) async {
    await _dio.put('/product-details/createOrUpdate/product-stocks',
        data: updateStockModel.toJson());
  }

  /// Delete Product
  Future<void> deleteProduct(String productId, String reason) async {
    await _dio.put('/products/update/delete-product', data: {
      'productId': productId,
      'reason': reason,
    });
  }

  /// Low Stock Products
  Future<List<ProductModel>> getLowStockProducts({int threshold = 5}) async {
    try {
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
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ??
          'Failed to fetch low stock products';
      print('❌ Error: $errorMessage');
      throw errorMessage;
    } catch (e) {
      print('⚠️ Unknown error: $e');
      throw Exception('Unexpected error occurred while fetching low stock');
    }
  }
}