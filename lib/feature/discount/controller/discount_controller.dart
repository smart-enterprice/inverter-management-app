import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/dealer_discount_model.dart';
import '../repository/discount_repository.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final dealerDiscountControllerProvider =
AsyncNotifierProvider<DealerDiscountController, List<DealerDiscountModel>>(
  DealerDiscountController.new,
);

final dealerProductDiscountProvider = FutureProvider.autoDispose
    .family<DealerDiscountModel?, Map<String, String>>((ref, params) async {
  final repository = ref.read(dealerDiscountRepositoryProvider);
  return repository.getDealerProductDiscounts(
    dealerId: params['dealerId']!,
    productId: params['productId']!,
  );
});

// ─── Controller ───────────────────────────────────────────────────────────────

class DealerDiscountController
    extends AsyncNotifier<List<DealerDiscountModel>> {
  late final DealerDiscountRepository _repo;

  @override
  Future<List<DealerDiscountModel>> build() async {
    _repo = ref.watch(dealerDiscountRepositoryProvider);
    return []; // empty until getDealerDiscounts is called
  }

  /// Fetch all discounts for a dealer
  Future<void> getDealerDiscounts(String dealerId) async {
    state = const AsyncValue.loading();
    try {
      final discounts = await _repo.getDealerDiscounts(dealerId);
      state = AsyncValue.data(discounts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// Create discounts and refresh
  Future<void> createDealerDiscounts(List<DealerDiscountModel> discounts) async {
    try {
      final data = discounts.map((d) => d.toJson()).toList();
      await _repo.createDealerDiscounts(data);
      if (discounts.isNotEmpty) {
        await getDealerDiscounts(discounts.first.dealerId);
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Get discount for a specific product
  Future<DealerDiscountModel?> getDealerProductDiscount({
    required String dealerId,
    required String productId,
  }) {
    return _repo.getDealerProductDiscounts(
      dealerId: dealerId,
      productId: productId,
    );
  }

  /// Update a discount and refresh
  Future<void> updateDealerDiscount(DealerDiscountModel discount) async {
    try {
      await _repo.updateDealerDiscount(discount);
      await getDealerDiscounts(discount.dealerId);
    } catch (e) {
      rethrow;
    }
  }
}