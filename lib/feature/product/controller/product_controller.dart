import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/product_model.dart';
import '../../../network/app_exception.dart';
import '../repository/product_repository.dart';

// ─────────────────────────────────────────────
// Pagination state — separate notifier
// ─────────────────────────────────────────────

class ProductPaginationState {
  final bool hasMore;
  final bool isFetchingMore;
  final int currentPage;

  /// True while a filter change / pull-to-refresh fetch is in flight.
  /// Lets the UI show a small spinner over the list area instead of
  /// blanking the whole screen with AsyncValue.loading().
  final bool isFiltering;

  const ProductPaginationState({
    this.hasMore = true,
    this.isFetchingMore = false,
    this.currentPage = 1,
    this.isFiltering = false,
  });

  ProductPaginationState copyWith({
    bool? hasMore,
    bool? isFetchingMore,
    int? currentPage,
    bool? isFiltering,
  }) =>
      ProductPaginationState(
        hasMore:        hasMore        ?? this.hasMore,
        isFetchingMore: isFetchingMore ?? this.isFetchingMore,
        currentPage:    currentPage    ?? this.currentPage,
        isFiltering:    isFiltering    ?? this.isFiltering,
      );
}

final productPaginationProvider =
NotifierProvider<ProductPaginationNotifier, ProductPaginationState>(
  ProductPaginationNotifier.new,
);

class ProductPaginationNotifier extends Notifier<ProductPaginationState> {
  @override
  ProductPaginationState build() => const ProductPaginationState();

  /// Reset everything EXCEPT isFiltering — that's controlled separately
  /// so the UI can keep showing the list while the next page-1 loads.
  void reset() => state = ProductPaginationState(
    isFiltering: state.isFiltering,
  );

  void setFetchingMore(bool value) =>
      state = state.copyWith(isFetchingMore: value);

  void setFiltering(bool value) =>
      state = state.copyWith(isFiltering: value);

  void nextPage() =>
      state = state.copyWith(currentPage: state.currentPage + 1);

  void rollbackPage() =>
      state = state.copyWith(currentPage: state.currentPage - 1);

  void setHasMore(bool value) => state = state.copyWith(hasMore: value);
}

// ─────────────────────────────────────────────
// FutureProvider families
// ─────────────────────────────────────────────

final productByIdProvider =
    FutureProvider.autoDispose.family<ProductModel?, String>((ref, id) {
  return ref.read(productControllerProvider.notifier).getProductById(id);
});

final productByBrandProvider = FutureProvider.autoDispose
    .family<List<ProductModel>, String>((ref, brandKey) async {
  final brands = brandKey.split(',');
  return ref
      .read(productControllerProvider.notifier)
      .fetchProductsByBrand(brands);
});

final lowStockProvider =
    FutureProvider.autoDispose.family<List<ProductModel>, int>((ref, threshold) async {
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

  // ── Active filters ─────────────────────────────────────────────────────
  String?       _search;
  String?       _category;
  String?       _status;
  List<String>? _brands;

  // ── Race protection ────────────────────────────────────────────────────
  // Each filter-change fetch bumps this id; late responses for stale
  // requests are discarded so old data never overwrites new.
  int _filterRequestId = 0;

  void setFilters({
    String?       search,
    String?       category,
    String?       status,
    List<String>? brands,
  }) {
    _search   = search;
    _category = category;
    _status   = status;
    _brands   = (brands == null || brands.isEmpty) ? null : brands;
  }

  ProductPaginationNotifier get _pagination =>
      ref.read(productPaginationProvider.notifier);

  ProductPaginationState get _paginationState =>
      ref.read(productPaginationProvider);

  // ── build ──────────────────────────────────────────────────────────────
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

  Future<List<ProductModel>> _fetchPage1() async {
    _pagination.reset();
    final products = await _repo.getProducts(
      page:     1,
      limit:    _pageSize,
      search:   _search,
      category: _category,
      status:   _status,
      brands:   _brands, // ✅ pass through (no-op in repo if not implemented)
    );
    if (products.length < _pageSize) _pagination.setHasMore(false);
    return products;
  }

  // ── Public API ─────────────────────────────────────────────────────────

  /// Filter change / pull-to-refresh.
  ///
  /// IMPORTANT: does NOT set state to AsyncValue.loading() — the previous
  /// list stays visible while the new page-1 loads. The screen shows its
  /// own spinner by watching `isFiltering` on the pagination provider.
  Future<void> fetchProducts() async {
    final myId = ++_filterRequestId;
    _pagination.setFiltering(true);

    try {
      final products = await _fetchPage1();

      // Drop stale responses from earlier filter changes
      if (myId != _filterRequestId) return;

      state = AsyncValue.data(products);
    } catch (e, st) {
      if (myId != _filterRequestId) return;
      state = AsyncValue.error(e, st);
    } finally {
      if (myId == _filterRequestId) {
        _pagination.setFiltering(false);
      }
    }
  }

  /// Infinite scroll — append next page using current filters
  Future<void> fetchMoreProducts() async {
    if (_paginationState.isFetchingMore || !_paginationState.hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;

    _pagination.setFetchingMore(true);
    try {
      _pagination.nextPage();
      final more = await _repo.getProducts(
        page:     _paginationState.currentPage,
        limit:    _pageSize,
        search:   _search,
        category: _category,
        status:   _status,
        brands:   _brands,
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

  Future<void> fetchAllProducts() async {
    while (_paginationState.hasMore && !_paginationState.isFetchingMore) {
      await fetchMoreProducts();
    }
  }

  Future<void> createProduct(ProductModel product) async {
    try {
      await _repo.createProduct(product);
      await fetchProducts();
    } on AppException catch (e) {
      throw e.message;
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
}