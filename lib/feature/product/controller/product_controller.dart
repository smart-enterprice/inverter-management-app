import 'dart:async';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/product_model.dart';
import '../repository/product_repository.dart';

final productControllerProvider =
StateNotifierProvider<ProductController, AsyncValue<List<ProductModel>>>(
      (ref) => ProductController(ref),
);

final productByIdProvider =
FutureProvider.family<ProductModel?, String>((ref, id) {
  return ref.read(productControllerProvider.notifier).getProductById(id);
});

// ✅ String-keyed brand provider (comma-joined brand names)
final productByBrandProvider =
FutureProvider.family<List<ProductModel>, String>((ref, brandKey) async {
  final brands = brandKey.split(',');
  final controller = ref.read(productControllerProvider.notifier);
  return await controller.fetchProductsByBrand(brands);
});

final lowStockProvider =
FutureProvider.family<List<ProductModel>, int>((ref, threshold) async {
  return await ref
      .read(productControllerProvider.notifier)
      .fetchLowStockProducts(threshold);
});

class ProductController extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final Ref _ref;
  Timer? _timer;

  // ── Pagination state ──────────────────────────────────────────────────────
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  ProductController(this._ref) : super(const AsyncLoading()) {
    fetchProducts();
    _startAutoRefresh();
  }

  /// Initial / refresh fetch (page 1)
  Future<void> fetchProducts() async {
    try {
      _currentPage = 1;
      _hasMore = true;
      final products = await _ref
          .read(productRepositoryProvider)
          .getProducts(page: _currentPage, limit: _pageSize);
      if (products.length < _pageSize) _hasMore = false;
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Load next page and append to existing list (infinite scroll)
  Future<void> fetchMoreProducts() async {
    if (_isFetchingMore || !_hasMore) return;
    final current = state.value;
    if (current == null) return;

    _isFetchingMore = true;
    try {
      _currentPage++;
      final more = await _ref
          .read(productRepositoryProvider)
          .getProducts(page: _currentPage, limit: _pageSize);
      if (more.length < _pageSize) _hasMore = false;
      state = AsyncValue.data([...current, ...more]);
    } catch (_) {
      _currentPage--; // roll back on failure
    } finally {
      _isFetchingMore = false;
    }
  }

  /// Create Product
  Future<void> createProduct(ProductModel product) async {
    try {
      await _ref.read(productRepositoryProvider).createProduct(product);
      await fetchProducts();
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Something went wrong';
      throw errorMessage;
    }
  }

  /// Fetch Products by Brand (no pagination — brand filter returns full list)
  Future<List<ProductModel>> fetchProductsByBrand(List<String> brands) async {
    try {
      return await _ref
          .read(productRepositoryProvider)
          .getProductsByBrand(brands);
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Update Product
  Future<void> updateProduct(
      String productId, ProductModel updatedProduct) async {
    try {
      await _ref
          .read(productRepositoryProvider)
          .updateProduct(productId, updatedProduct);
      await fetchProducts();
    } on DioException catch (e) {
      print("DIO ERROR: ${e.response?.data}");
      rethrow;
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

  /// Get Product by ID
  Future<ProductModel?> getProductById(String id) async {
    try {
      return await _ref.read(productRepositoryProvider).getProductById(id);
    } catch (_) {
      return null;
    }
  }

  /// Fetch Low Stock Products
  Future<List<ProductModel>> fetchLowStockProducts(int threshold) async {
    try {
      return await _ref
          .read(productRepositoryProvider)
          .getLowStockProducts(threshold: threshold);
    } catch (e) {
      rethrow;
    }
  }

  void _startAutoRefresh() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(minutes: 1), (_) => fetchProducts());
    _ref.onDispose(() => _timer?.cancel());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}