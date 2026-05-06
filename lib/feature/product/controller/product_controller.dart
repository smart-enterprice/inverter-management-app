import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/product_model.dart';
import '../repository/product_repository.dart';

// ─────────────────────────────────────────────
// Pagination state — separate notifier
// ─────────────────────────────────────────────

class ProductPaginationState {
  final bool hasMore;
  final bool isFetchingMore;
  final int currentPage;

  const ProductPaginationState({
    this.hasMore = true,
    this.isFetchingMore = false,
    this.currentPage = 1,
  });

  ProductPaginationState copyWith({
    bool? hasMore,
    bool? isFetchingMore,
    int? currentPage,
  }) =>
      ProductPaginationState(
        hasMore: hasMore ?? this.hasMore,
        isFetchingMore: isFetchingMore ?? this.isFetchingMore,
        currentPage: currentPage ?? this.currentPage,
      );
}

final productPaginationProvider =
NotifierProvider<ProductPaginationNotifier, ProductPaginationState>(
  ProductPaginationNotifier.new,
);

class ProductPaginationNotifier extends Notifier<ProductPaginationState> {
  @override
  ProductPaginationState build() => const ProductPaginationState();

  void reset() => state = const ProductPaginationState();

  void setFetchingMore(bool value) =>
      state = state.copyWith(isFetchingMore: value);

  void nextPage() =>
      state = state.copyWith(currentPage: state.currentPage + 1);

  void rollbackPage() =>
      state = state.copyWith(currentPage: state.currentPage - 1);

  void setHasMore(bool value) => state = state.copyWith(hasMore: value);
}

// ─────────────────────────────────────────────
// FutureProvider families — unchanged
// ─────────────────────────────────────────────

final productByIdProvider =
FutureProvider.family<ProductModel?, String>((ref, id) {
  return ref.read(productControllerProvider.notifier).getProductById(id);
});

final productByBrandProvider =
FutureProvider.family<List<ProductModel>, String>((ref, brandKey) async {
  final brands = brandKey.split(',');
  return ref
      .read(productControllerProvider.notifier)
      .fetchProductsByBrand(brands);
});

final lowStockProvider =
FutureProvider.family<List<ProductModel>, int>((ref, threshold) async {
  return ref
      .read(productControllerProvider.notifier)
      .fetchLowStockProducts(threshold);
});

// ─────────────────────────────────────────────
// ProductController — AsyncNotifier
// ─────────────────────────────────────────────

final productControllerProvider =
AsyncNotifierProvider<ProductController, List<ProductModel>>(
  ProductController.new,
);

class ProductController extends AsyncNotifier<List<ProductModel>> {
  static const int _pageSize = 20;

  late final ProductRepository _repo;

  ProductPaginationNotifier get _pagination =>
      ref.read(productPaginationProvider.notifier);

  ProductPaginationState get _paginationState =>
      ref.read(productPaginationProvider);

  @override
  @override
  Future<List<ProductModel>> build() async {
    _repo = ref.watch(productRepositoryProvider);
    for (int attempt = 1; attempt <= 3; attempt++) {
      try {
        return await _fetchPage1();
      } catch (e) {
        if (attempt == 3) rethrow;
        await Future.delayed(Duration(seconds: attempt));
      }
    }
    throw Exception('Failed to load products');
  }

  // ── Internal helpers ───────────────────────────────────────────────────

  Future<List<ProductModel>> _fetchPage1() async {
    _pagination.reset();
    final products = await _repo.getProducts(page: 1, limit: _pageSize);
    if (products.length < _pageSize) _pagination.setHasMore(false);
    return products;
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Initial / pull-to-refresh fetch
  Future<void> fetchProducts() async {
    state = const AsyncValue.loading();
    try {
      final products = await _fetchPage1();
      state = AsyncValue.data(products);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Infinite scroll — append next page
  Future<void> fetchMoreProducts() async {
    if (_paginationState.isFetchingMore || !_paginationState.hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _pagination.setFetchingMore(true);
    try {
      _pagination.nextPage();
      final more = await _repo.getProducts(
        page: _paginationState.currentPage,
        limit: _pageSize,
      );
      if (more.length < _pageSize) _pagination.setHasMore(false);
      state = AsyncValue.data([...current, ...more]);
    } catch (_) {
      _pagination.rollbackPage();
      rethrow;
    } finally {
      _pagination.setFetchingMore(false);
    }
  }

  Future<void> createProduct(ProductModel product) async {
    try {
      await _repo.createProduct(product);
      await fetchProducts();
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data['message'] ?? 'Something went wrong';
      throw errorMessage;
    }
  }

  Future<List<ProductModel>> fetchProductsByBrand(List<String> brands) async {
    try {
      return await _repo.getProductsByBrand(brands);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateProduct(
      String productId, ProductModel updatedProduct) async {
    try {
      await _repo.updateProduct(productId, updatedProduct);
      await fetchProducts();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateStock(StockUpdate updatedStock) async {
    try {
      await _repo.updateStock(updatedStock);
      await fetchProducts();
    } catch (_) {
      rethrow;
    }
  }

  Future<ProductModel?> getProductById(String id) async {
    try {
      return await _repo.getProductById(id);
    } catch (_) {
      return null;
    }
  }

  Future<List<ProductModel>> fetchLowStockProducts(int threshold) async {
    try {
      return await _repo.getLowStockProducts(threshold: threshold);
    } catch (_) {
      rethrow;
    }
  }
  Future<void> fetchAllProducts() async {
    while (_paginationState.hasMore && !_paginationState.isFetchingMore) {
      await fetchMoreProducts();
    }
  }
}