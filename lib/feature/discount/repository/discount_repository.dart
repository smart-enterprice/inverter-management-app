import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../feature/discount/model/dealer_discount_model.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/dio_client.dart';

final dealerDiscountRepositoryProvider =
    Provider<DealerDiscountRepository>((ref) {
  return DealerDiscountRepository(ref.watch(dioClientProvider));
});

class DealerDiscountRepository {
  const DealerDiscountRepository(this._dio);

  final Dio _dio;

  Future<void> createDealerDiscounts(List<Map<String, dynamic>> discounts) {
    return guardDio(
      () => _dio.post(
        '/employees/dealer/create-discounts',
        data: discounts,
      ),
      fallback: 'Failed to create dealer discounts',
    );
  }

  Future<List<DealerDiscountModel>> getDealerDiscounts(String dealerId) {
    return guardDio(
      () async {
        final response = await _dio.post(
          '/employees/dealer/get-discounts?page=1&limit=30',
          data: {'dealer_id': dealerId},
        );
        final List data = response.data['data'] ?? [];
        return data.map((e) => DealerDiscountModel.fromJson(e)).toList();
      },
      fallback: 'Failed to fetch dealer discounts',
    );
  }

  Future<DealerDiscountModel?> getDealerProductDiscounts({
    required String dealerId,
    required String productId,
  }) {
    return guardDio(
      () async {
        final response = await _dio.post(
          '/employees/dealer/get-discounts?page=1&limit=30',
          data: {
            'dealer_id': dealerId,
            'product_id': productId,
          },
        );
        final List data = response.data['data'] ?? [];
        if (data.isEmpty) return null;
        return DealerDiscountModel.fromJson(data.first);
      },
      fallback: 'Failed to fetch dealer product discounts',
    );
  }

  Future<void> updateDealerDiscount(DealerDiscountModel discount) {
    return guardDio(
      () => _dio.put(
        '/employees/dealer/update-discount',
        data: discount.toJson(),
      ),
      fallback: 'Failed to update dealer discount',
    );
  }
}
