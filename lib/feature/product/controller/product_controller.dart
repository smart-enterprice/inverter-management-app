import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/product_model.dart';
import '../repository/product_repository.dart';

final productControllerProvider =
StateNotifierProvider<ProductController, AsyncValue<List<ProductModel>>>(
      (ref) => ProductController(ref),
);

final productByIdProvider = FutureProvider.family<ProductModel?, String>((ref, id) {
  return ref.read(productControllerProvider.notifier).getProductById(id);
});

final productByBrandProvider =
FutureProvider.family<List<ProductModel>, List<String>>((ref, brands) async {
  final controller = ref.read(productControllerProvider.notifier);
  return await controller.fetchProductsByBrand(brands);
});


class ProductController extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final Ref _ref;
  Timer? _timer;
  List<ProductModel> _allProducts = [];

  ProductController(this._ref) : super(const AsyncLoading()) {
    fetchProducts();
    _startAutoRefresh();
  }

  /// Create Product
  Future<void> createProduct(ProductModel product) async {
    try {
      await _ref.read(productRepositoryProvider).createProduct(product);
      await fetchProducts();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Something went wrong';
      throw errorMessage;
    }
  }

  /// Fetch All Products
  Future<void> fetchProducts() async {
    try {
      final products = await _ref.read(productRepositoryProvider).getProducts();
      _allProducts = products;
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Fetch Products by Brand
  Future<List<ProductModel>> fetchProductsByBrand(List<String> brands) async {
    try {
      final products =
      await _ref.read(productRepositoryProvider).getProductsByBrand(brands);
      state = AsyncValue.data(products);
      return products;
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }


  /// Update Product
  Future<void> updateProduct(String productId, ProductModel updatedProduct) async {
    try {
      await _ref.read(productRepositoryProvider).updateProduct(productId, updatedProduct);
      await fetchProducts();
    } catch (e) {
      rethrow;
    }
  }

  /// Update Stock
  Future<void> updateStock(StockUpdate updatedStock) async {
    try {
      await _ref.read(productRepositoryProvider).updateStock(updatedStock);
    } catch (e) {
      rethrow;
    }
  }

  /// Start Auto Refresh Every 1 Minute
  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) {
      fetchProducts();
    });

    _ref.onDispose(() {
      _timer?.cancel();
    });
  }

  /// Get Product by ID
  Future<ProductModel?> getProductById(String id) async {
    try {
      return await _ref.read(productRepositoryProvider).getProductById(id);
    } catch (_) {
      return null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}
