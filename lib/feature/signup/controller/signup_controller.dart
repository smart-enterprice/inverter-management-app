import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../model/user_model.dart';
import '../../../core/network/app_exception.dart';
import '../repository/signup_repository.dart';

// ─────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────

final signupControllerProvider =
AsyncNotifierProvider<SignupController, void>(
  SignupController.new,
);

final employeeByIdProvider =
    FutureProvider.autoDispose.family<UserModel?, String>((ref, id) async {
  if (id.isEmpty) return null;
  return ref.read(signupControllerProvider.notifier).getEmployeeById(id);
});

final userListProvider =
    FutureProvider.autoDispose<List<UserModel>>((ref) async {
  return ref.read(signupRepositoryProvider).getEmployees();
});

final dealerListProvider =
AsyncNotifierProvider<DealerListNotifier, List<UserModel>>(
  DealerListNotifier.new,
);

/// Tracks whether next page is loading (footer spinner)
final dealerLoadingMoreProvider = StateProvider<bool>((ref) => false);

/// Tracks whether a search/filter is in flight (overlay spinner)
final dealerFilteringProvider = StateProvider<bool>((ref) => false);

final usersByRoleProvider =
    FutureProvider.autoDispose.family<List<UserModel>, String>((ref, role) async {
  return ref.read(signupControllerProvider.notifier).getUsersByRole(role);
});

/// Active salesmen for filter pickers. Keyed by search + page so the picker
/// can paginate independently of other consumers.
class SalesmanPickerArg {
  final String search;
  final int page;
  final int limit;
  const SalesmanPickerArg({
    required this.search,
    this.page = 1,
    this.limit = 30,
  });

  @override
  bool operator ==(Object other) =>
      other is SalesmanPickerArg &&
      other.search == search &&
      other.page == page &&
      other.limit == limit;
  @override
  int get hashCode => Object.hash(search, page, limit);
}

final salesmanListProvider = FutureProvider.autoDispose
    .family<List<UserModel>, SalesmanPickerArg>((ref, arg) async {
  return ref.read(signupRepositoryProvider).getSalesmen(
        search: arg.search.isEmpty ? null : arg.search,
        page: arg.page,
        limit: arg.limit,
      );
});

/// Dealers for the order-filter picker. Re-keys on salesmanId+search+page so it
/// stays independent from the main DealersScreen's [dealerListProvider].
class DealerPickerArg {
  final String? salesmanId;
  final String search;
  final int page;
  final int limit;
  const DealerPickerArg({
    this.salesmanId,
    required this.search,
    this.page = 1,
    this.limit = 30,
  });

  @override
  bool operator ==(Object other) =>
      other is DealerPickerArg &&
      other.salesmanId == salesmanId &&
      other.search == search &&
      other.page == page &&
      other.limit == limit;
  @override
  int get hashCode => Object.hash(salesmanId, search, page, limit);
}

final dealerPickerProvider = FutureProvider.autoDispose
    .family<List<UserModel>, DealerPickerArg>((ref, arg) async {
  final repo = ref.read(signupRepositoryProvider);
  if (arg.salesmanId != null) {
    return repo.getSalesmanDealers(
      salesmanId: arg.salesmanId!,
      search: arg.search.isEmpty ? null : arg.search,
      page: arg.page,
      limit: arg.limit,
    );
  }
  return repo.getDealers(
    search: arg.search.isEmpty ? null : arg.search,
    status: 'active',
    page: arg.page,
    limit: arg.limit,
  );
});

final currentUserProvider =
    FutureProvider.autoDispose<UserModel?>((ref) async {
  final prefs = await SharedPreferences.getInstance();
  final userId = prefs.getString('user_id');
  if (userId == null) return null;
  return ref.read(signupControllerProvider.notifier).getEmployeeById(userId);
});

// ── Salesman's assigned dealers (for DealerAssignmentScreen) ─────────────────

/// Arg = salesmanId
final salesmanDealersProvider =
AsyncNotifierProviderFamily<SalesmanDealersNotifier, List<UserModel>, String>(
  SalesmanDealersNotifier.new,
);

/// Tracks whether next page is loading (footer spinner) — assigned tab
final salesmanDealerLoadingMoreProvider = StateProvider<bool>((ref) => false);

/// Tracks whether a search is in flight (overlay spinner) — assigned tab
final salesmanDealerFilteringProvider = StateProvider<bool>((ref) => false);

// ─────────────────────────────────────────────
// SignupController
// ─────────────────────────────────────────────

class SignupController extends AsyncNotifier<void> {
  late final SignupRepository _repo;

  @override
  Future<void> build() async {
    _repo = ref.watch(signupRepositoryProvider);
  }

  Future<String?> signup(UserModel request, {File? photoFile}) async {
    state = const AsyncLoading();
    try {
      if (photoFile != null) {
        final fileUrl = await _repo.uploadFile(photoFile);
        request = request.copyWith(photo: fileUrl);
      }
      await _repo.userSignup(request);
      state = const AsyncData(null);
      return null;
    } on AppException catch (e, st) {
      state = AsyncError(e, st);
      return e.message;
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Something went wrong';
    }
  }

  Future<UserModel> getEmployeeById(String id) async =>
      _repo.getEmployeeById(id);

  Future<List<UserModel>> getEmployees() async => _repo.getEmployees();

  Future<List<UserModel>> getDealers() async => _repo.getDealers();

  Future<String?> updateUser({
    required UserModel oldUser,
    String? name,
    String? email,
    String? phone,
    String? shopName,
    String? role,
    String? photo,
    String? address,
    String? town,
    String? district,
    List<String>? brand,
    File? photoFile,
    List<String>? addBrands,
    List<String>? removeBrands,
  }) async {
    state = const AsyncLoading();
    try {
      String? finalPhotoUrl = photo;
      if (photoFile != null) {
        finalPhotoUrl = await _repo.uploadFile(photoFile);
      }
      final updatedUser = oldUser.copyWith(
        employeeName: name,
        employeeEmail: email,
        employeePhone: phone,
        shopName: shopName,
        role: role,
        photo: finalPhotoUrl,
        address: address,
        town: town,
        district: district,
        brand: brand,
      );
      if (updatedUser.employeeId == null || updatedUser.employeeId!.isEmpty) {
        throw Exception('employeeId is required for update');
      }
      await _repo.updateUser(
        updatedUser.employeeId!,
        updatedUser,
        addBrands: addBrands,
        removeBrands: removeBrands,
      );
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return e.toString();
    }
  }

  /// For salesperson — assign / unassign dealers
  Future<String?> updateDealers({
    required String employeeId,
    List<String>? addDealers,
    List<String>? removeDealers,
  }) async {
    try {
      await _repo.updateDealers(
        employeeId,
        addDealers: addDealers,
        removeDealers: removeDealers,
      );
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<List<UserModel>> getUsersByRole(String role) async =>
      _repo.getUsersByRole(role);

  Future<String?> deleteUser(String employeeId, String reason) async {
    state = const AsyncLoading();
    try {
      await _repo.deleteUser(employeeId, reason);
      state = const AsyncData(null);
      return null;
    } catch (e, st) {
      state = AsyncError(e, st);
      return 'Delete failed: $e';
    }
  }
}

// ─────────────────────────────────────────────
// DealerListNotifier — server-side search + pagination
// Old data stays visible during search (UI watches dealerFilteringProvider
// to show an overlay spinner instead of blanking the screen).
// ─────────────────────────────────────────────

class DealerListNotifier extends AsyncNotifier<List<UserModel>> {
  late final SignupRepository _repo;
  int _page = 1;
  static const int _limit = 20;
  bool _hasMore = true;
  String _currentSearch = '';
  Timer? _debounce;

  // Tags each search call so late stale responses are discarded
  int _searchRequestId = 0;

  // First-page cache — restored instantly when search clears
  List<UserModel>? _cachedFirstPage;

  bool get hasMore => _hasMore;
  String get currentSearch => _currentSearch;

  @override
  Future<List<UserModel>> build() async {
    _repo = ref.watch(signupRepositoryProvider);
    ref.onDispose(() => _debounce?.cancel());
    _page = 1;
    _hasMore = true;
    _currentSearch = '';
    final dealers = await _repo.getDealers(page: _page, limit: _limit);
    if (dealers.length < _limit) _hasMore = false;
    _cachedFirstPage = dealers;
    return dealers;
  }

  void searchDealers(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    // Cleared search: restore cache instantly, no API call, no overlay
    if (trimmed.isEmpty) {
      _searchRequestId++;
      _currentSearch = '';
      _page = 1;
      _hasMore = _cachedFirstPage != null
          ? _cachedFirstPage!.length >= _limit
          : true;
      ref.read(dealerFilteringProvider.notifier).state = false;
      if (_cachedFirstPage != null) {
        state = AsyncData(_cachedFirstPage!);
      } else {
        refresh();
      }
      return;
    }

    final myRequestId = ++_searchRequestId;

    // Keep old data visible. UI shows overlay spinner via dealerFilteringProvider.
    ref.read(dealerFilteringProvider.notifier).state = true;

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (myRequestId != _searchRequestId) return;

      _currentSearch = trimmed;
      try {
        _page = 1;
        _hasMore = true;
        final dealers = await _repo.getDealers(
          page: _page,
          limit: _limit,
          search: _currentSearch,
        );
        if (myRequestId != _searchRequestId) return; // stale
        if (dealers.length < _limit) _hasMore = false;
        state = AsyncData(dealers);
      } catch (e, st) {
        if (myRequestId != _searchRequestId) return;
        state = AsyncError(e, st);
      } finally {
        if (myRequestId == _searchRequestId) {
          ref.read(dealerFilteringProvider.notifier).state = false;
        }
      }
    });
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    _searchRequestId++;
    _currentSearch = '';
    _page = 1;
    _hasMore = true;
    ref.read(dealerFilteringProvider.notifier).state = true;
    try {
      final dealers = await _repo.getDealers(page: _page, limit: _limit);
      if (dealers.length < _limit) _hasMore = false;
      _cachedFirstPage = dealers;
      state = AsyncData(dealers);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      ref.read(dealerFilteringProvider.notifier).state = false;
    }
  }

  Future<void> loadMore() async {
    final loadingMore = ref.read(dealerLoadingMoreProvider);
    if (loadingMore || !_hasMore) return;

    final current = state.valueOrNull;
    if (current == null) return;

    ref.read(dealerLoadingMoreProvider.notifier).state = true;
    try {
      _page++;
      final more = await _repo.getDealers(
        page: _page,
        limit: _limit,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );
      if (more.length < _limit) _hasMore = false;
      state = AsyncData([...current, ...more]);
    } catch (e) {
      _page--;
      debugPrint('🔴 [loadMore] ERROR: $e');
    } finally {
      ref.read(dealerLoadingMoreProvider.notifier).state = false;
    }
  }
}

// ─────────────────────────────────────────────
// SalesmanDealersNotifier — assigned dealers for one salesman
// server-side search + pagination via salesmanIds param
// ─────────────────────────────────────────────

class SalesmanDealersNotifier
    extends FamilyAsyncNotifier<List<UserModel>, String> {
  late final SignupRepository _repo;
  late final String _salesmanId;

  int _page = 1;
  static const int _limit = 20;
  bool _hasMore = true;
  String _currentSearch = '';
  Timer? _debounce;
  int _requestId = 0;
  List<UserModel>? _cache;

  bool get hasMore => _hasMore;

  @override
  Future<List<UserModel>> build(String arg) async {
    _repo = ref.watch(signupRepositoryProvider);
    _salesmanId = arg;
    ref.onDispose(() => _debounce?.cancel());
    return _fetchFirstPage();
  }

  Future<List<UserModel>> _fetchFirstPage() async {
    _page = 1;
    _hasMore = true;
    _currentSearch = '';
    final list = await _repo.getSalesmanDealers(
      salesmanId: _salesmanId,
      page: _page,
      limit: _limit,
    );
    if (list.length < _limit) _hasMore = false;
    _cache = list;
    return list;
  }

  void search(String query) {
    _debounce?.cancel();
    final trimmed = query.trim();

    // Cleared search: restore cache instantly
    if (trimmed.isEmpty) {
      _requestId++;
      _currentSearch = '';
      _page = 1;
      _hasMore = _cache != null ? _cache!.length >= _limit : true;
      ref.read(salesmanDealerFilteringProvider.notifier).state = false;
      if (_cache != null) {
        state = AsyncData(_cache!);
      } else {
        refresh();
      }
      return;
    }

    final myId = ++_requestId;
    // Keep old data visible — overlay spinner via salesmanDealerFilteringProvider
    ref.read(salesmanDealerFilteringProvider.notifier).state = true;

    _debounce = Timer(const Duration(milliseconds: 500), () async {
      if (myId != _requestId) return;
      _currentSearch = trimmed;
      try {
        _page = 1;
        _hasMore = true;
        final list = await _repo.getSalesmanDealers(
          salesmanId: _salesmanId,
          page: _page,
          limit: _limit,
          search: _currentSearch,
        );
        if (myId != _requestId) return; // stale
        if (list.length < _limit) _hasMore = false;
        state = AsyncData(list);
      } catch (e, st) {
        if (myId != _requestId) return;
        state = AsyncError(e, st);
      } finally {
        if (myId == _requestId) {
          ref.read(salesmanDealerFilteringProvider.notifier).state = false;
        }
      }
    });
  }

  Future<void> refresh() async {
    _debounce?.cancel();
    _requestId++;
    ref.read(salesmanDealerFilteringProvider.notifier).state = true;
    try {
      final list = await _fetchFirstPage();
      state = AsyncData(list);
    } catch (e, st) {
      state = AsyncError(e, st);
    } finally {
      ref.read(salesmanDealerFilteringProvider.notifier).state = false;
    }
  }

  Future<void> loadMore() async {
    if (ref.read(salesmanDealerLoadingMoreProvider) || !_hasMore) return;
    final current = state.valueOrNull;
    if (current == null) return;

    ref.read(salesmanDealerLoadingMoreProvider.notifier).state = true;
    try {
      _page++;
      final more = await _repo.getSalesmanDealers(
        salesmanId: _salesmanId,
        page: _page,
        limit: _limit,
        search: _currentSearch.isEmpty ? null : _currentSearch,
      );
      if (more.length < _limit) _hasMore = false;
      state = AsyncData([...current, ...more]);
    } catch (e) {
      _page--;
      debugPrint('🔴 [SalesmanDealersNotifier loadMore] ERROR: $e');
    } finally {
      ref.read(salesmanDealerLoadingMoreProvider.notifier).state = false;
    }
  }
}