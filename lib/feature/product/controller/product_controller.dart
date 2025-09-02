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

class ProductController extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final Ref _ref;
  Timer? _timer;
  List<ProductModel> _allProducts = [];

  ProductController(this._ref) : super(const AsyncLoading()) {
    fetchProducts();
    _startAutoRefresh();
  }

  /// In ProductController
  Future<void> createProduct(ProductModel product) async {
    try {
      await _ref.read(productRepositoryProvider).createProduct(product);
      await fetchProducts();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Something went wrong';
      throw errorMessage; // pass the message up to the UI
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

  /// Filter products by brand name
  void filterByBrand(String brandName) {
    final filtered = _allProducts
        .where((p) => p.brand?.toLowerCase() == brandName.toLowerCase())
        .toList();
    state = AsyncValue.data(filtered);
  }

  /// Clear brand filter
  void clearFilter() {
    state = AsyncValue.data(_allProducts);
  }

  /// Get unique brand names for the filter dropdown
  List<String?> get uniqueBrandNames {
    final brands = _allProducts.map((p) => p.brand).toSet().toList();
    brands.sort();
    return brands;
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
