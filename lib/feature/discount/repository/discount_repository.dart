import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../network/dio_client.dart';
import '../../../model/dealer_discount_model.dart';

final dealerDiscountRepositoryProvider =
    Provider<DealerDiscountRepository>((ref) {
  return DealerDiscountRepository();
});

class DealerDiscountRepository {
  final Dio _dio = DioClient.instance;

  /// ------------------------- Create Dealer Discount
  Future<void> createDealerDiscounts(
      List<Map<String, dynamic>> discounts) async {
    try {
      final response = await _dio.post(
        "/employees/dealer/create-discounts",
        data: discounts,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return; // success
      } else {
        throw "❌ Failed to create dealer discounts"; // throw only message
      }
    } on DioException catch (e) {
      final errorMessage = e.response?.data?['message']?.toString() ?? e.message.toString();
      throw errorMessage; // 👈 throw only string message
    } catch (e) {
      throw "Unexpected error: $e"; // still clean message
    }
  }


  /// Get all discounts for a dealer
  Future<List<DealerDiscountModel>> getDealerDiscounts(String dealerId) async {
    try {
      final response = await _dio.post(
        '/employees/dealer/get-discounts?page=1&limit=30',
        data: {
          "dealer_id": dealerId,
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        return data.map((e) => DealerDiscountModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to fetch dealer discounts');
      }
    } on DioException catch (e) {
      throw Exception(e.response?.data ?? e.message);
    }
  }
  Future<DealerDiscountModel?> getDealerProductDiscounts({
    required String dealerId,
    required String productId,
  }) async {
    try {
      final response = await _dio.post(
        '/employees/dealer/get-discounts?page=1&limit=30',
        data: {
          "dealer_id": dealerId,
          "product_id": productId,
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data['data'] ?? [];
        if (data.isEmpty) return null; // No discount found
        return DealerDiscountModel.fromJson(data.first);
      } else {
        throw "❌ Failed to fetch dealer product discounts";
      }
    } on DioException catch (e) {
      final msg = e.response?.data?['message'] ?? e.message;
      throw msg.toString();
    } catch (e) {
      throw "Unexpected error: $e";
    }
  }



  /// ------------------------- Update Dealer Discount

  Future<void> updateDealerDiscount(DealerDiscountModel discount) async {
    try {
      final response = await _dio.put(
        "/employees/dealer/update-discount",
        data: discount.toJson(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return; // ✅ success
      } else {
        throw "❌ Failed to update dealer discount";
      }
    } on DioException catch (e) {
      final errorMessage =
          e.response?.data?['message']?.toString() ?? e.message.toString();
      throw errorMessage; // 👈 throw only string message
    } catch (e) {
      throw "Unexpected error: $e";
    }
  }
}
