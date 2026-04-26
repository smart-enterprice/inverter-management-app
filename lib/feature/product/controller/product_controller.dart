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

final productByBrandProvider =
FutureProvider.family<List<ProductModel>, String>((ref, brandKey) async {
  final brands = brandKey.split(',');
  return ref.read(productControllerProvider.notifier).fetchProductsByBrand(brands);
});

final lowStockProvider =
FutureProvider.family<List<ProductModel>, int>((ref, threshold) async {
  return ref.read(productControllerProvider.notifier).fetchLowStockProducts(threshold);
});

class ProductController extends StateNotifier<AsyncValue<List<ProductModel>>> {
  final Ref _ref;

  // ── Pagination state ───────────────────────────────────────────────────────
  int _currentPage = 1;
  static const int _pageSize = 20;
  bool _hasMore = true;
  bool _isFetchingMore = false;

  bool get hasMore => _hasMore;
  bool get isFetchingMore => _isFetchingMore;

  // ✅ FIX: No Timer — removed the 1-minute background auto-refresh.
  // The timer was firing constantly even when the user was not on the
  // products screen, wasting bandwidth and resetting scroll position.
  //
  // Products are now refreshed by:
  //   1. Pull-to-refresh on the products list screen (already implemented).
  //   2. Calling ref.invalidate(productControllerProvider) after any mutation
  //      (create / update / stock update) — already done in those methods.
  //   3. Navigating back to the products screen triggers a provider rebuild
  //      if the provider has been invalidated.

  ProductController(this._ref) : super(const AsyncLoading()) {
    fetchProducts();
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

  /// Load next page and append (infinite scroll)
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

  /// Create product then refresh list
  Future<void> createProduct(ProductModel product) async {
    try {
      await _ref.read(productRepositoryProvider).createProduct(product);
      await fetchProducts();
    } on DioException catch (e) {
      final errorMessage = e.response?.data['message'] ?? 'Something went wrong';
      throw errorMessage;
    }
  }

  /// Fetch products by brand (no pagination — brand filter returns full list)
  Future<List<ProductModel>> fetchProductsByBrand(List<String> brands) async {
    try {
      return await _ref.read(productRepositoryProvider).getProductsByBrand(brands);
    } on DioException {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Update product then refresh list
  Future<void> updateProduct(String productId, ProductModel updatedProduct) async {
    try {
      await _ref.read(productRepositoryProvider).updateProduct(productId, updatedProduct);
      await fetchProducts();
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
      rethrow;
    }
  }

  /// Update stock
  Future<void> updateStock(StockUpdate updatedStock) async {
    try {
      await _ref.read(productRepositoryProvider).updateStock(updatedStock);
      // ✅ Refresh after stock change so UI reflects new quantities immediately
      await fetchProducts();
    } catch (e) {
      rethrow;
    }
  }

  /// Get single product by ID
  Future<ProductModel?> getProductById(String id) async {
    try {
      return await _ref.read(productRepositoryProvider).getProductById(id);
    } catch (_) {
      return null;
    }
  }

  /// Fetch low stock products
  Future<List<ProductModel>> fetchLowStockProducts(int threshold) async {
    try {
      return await _ref
          .read(productRepositoryProvider)
          .getLowStockProducts(threshold: threshold);
    } catch (e) {
      rethrow;
    }
  }

  // ✅ FIX: dispose() is now a no-op — no timer to cancel.
  // Kept here so the override is explicit and clear.
  @override
  void dispose() {
    super.dispose();
  }
}