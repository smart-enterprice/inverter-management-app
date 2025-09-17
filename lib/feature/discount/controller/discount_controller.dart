import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../model/dealer_discount_model.dart';
import '../repository/discount_repository.dart';

final dealerDiscountControllerProvider =
StateNotifierProvider<DealerDiscountController, AsyncValue<List<DealerDiscountModel>>>(
      (ref) => DealerDiscountController(ref.watch(dealerDiscountRepositoryProvider)),
);

class DealerDiscountController extends StateNotifier<AsyncValue<List<DealerDiscountModel>>> {
  final DealerDiscountRepository _repository;

  DealerDiscountController(this._repository) : super(const AsyncValue.data([]));

  /// Create a new discount
  Future<void> createDealerDiscounts(List<DealerDiscountModel> discounts) async {
    try {
      final data = discounts.map((d) => d.toJson()).toList();
      await _repository.createDealerDiscounts(data);

      if (discounts.isNotEmpty) {
        await getDealerDiscounts(discounts.first.dealerId);
      }
    } catch (e) {
      rethrow; // 👈 send error back to UI
    }
  }

  /// Get all discounts for a dealer
  Future<void> getDealerDiscounts(String dealerId) async {
    state = const AsyncValue.loading();
    try {
      final discounts = await _repository.getDealerDiscounts(dealerId);
      state = AsyncValue.data(discounts);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  /// ----------------- Update Dealer Discount
  Future<void> updateDealerDiscount(DealerDiscountModel discount) async {
    try {
      await _repository.updateDealerDiscount(discount);
      // refresh list after update
      await getDealerDiscounts(discount.dealerId);
    } catch (e) {
      rethrow;
    }
  }
}
