import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../feature/order/model/order_model.dart';
import '../../../feature/order/model/production_summary_model.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/dio_client.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository(ref.watch(dioClientProvider));
});

class OrderRepository {
  const OrderRepository(this._dio);

  final Dio _dio;

  Future<void> createOrder(OrderModel order) {
    return guardDio(
      () => _dio.post('/order-details/create-order', data: order.toJson()),
      fallback: 'Create order failed',
    );
  }

  Future<List<OrderModel>> getAllOrders({
    int? page,
    int? limit,
    String? status,
    String? salesman,
    String? dealer,
  }) {
    return guardDio(() async {
      final queryParameters = <String, dynamic>{
        'includeRejected': false,
        'page': page ?? 1,
        if (limit != null) 'limit': limit,
        if (status != null && status != 'ALL') 'status': status,
        if (salesman != null && salesman.isNotEmpty) 'salesman': salesman,
        if (dealer != null && dealer.isNotEmpty) 'dealer': dealer,
      };
      final response = await _dio.get(
        '/order-details',
        queryParameters: queryParameters,
      );
      final data = response.data['data'] as List;
      return data.map((e) => OrderModel.fromJson(e['order'])).toList();
    });
  }

  Future<OrderModel> getOrderById(String orderNumber) {
    return guardDio(() async {
      final response = await _dio.get('/order-details/$orderNumber');
      return OrderModel.fromJson(response.data['data']['order']);
    });
  }

  Future<List<OrderModel>> getOrdersByDateFilter({
    String? startDate,
    String? endDate,
    String? deliveryStartDate,
    String? deliveryEndDate,
    int page = 1,
    int limit = 20,
    String? salesman,
    String? dealer,
  }) {
    return guardDio(() async {
      final queryParameters = <String, dynamic>{
        'page': page,
        'limit': limit,
        if (startDate != null && startDate.isNotEmpty) 'startDate': startDate,
        if (endDate != null && endDate.isNotEmpty) 'endDate': endDate,
        if (deliveryStartDate != null && deliveryStartDate.isNotEmpty)
          'deliveryStartDate': deliveryStartDate,
        if (deliveryEndDate != null && deliveryEndDate.isNotEmpty)
          'deliveryEndDate': deliveryEndDate,
        if (salesman != null && salesman.isNotEmpty) 'salesman': salesman,
        if (dealer != null && dealer.isNotEmpty) 'dealer': dealer,
      };
      final response = await _dio.get(
        '/order-details',
        queryParameters: queryParameters,
      );
      final data = response.data['data'] as List;
      return data.map((e) => OrderModel.fromJson(e['order'])).toList();
    });
  }

  Future<void> updateOrderItemStatus(OrderModel order) {
    return guardDio(
      () => _dio.put(
        '/order-details/status/${order.orderNumber}',
        data: order.toUpdateItemJson(),
      ),
      fallback: 'Update order item status failed',
    );
  }

  Future<void> updateOrder(OrderModel order, {bool isPaymentUpdate = false}) {
    return guardDio(
      () => _dio.put(
        '/order-details/status/${order.orderNumber}',
        data: order.toUpdateJson(isPaymentUpdate: isPaymentUpdate),
      ),
      fallback: 'Update order failed',
    );
  }

  Future<void> updateOrderPayment(OrderModel order) {
    return guardDio(
      () async {
        final response = await _dio.put(
          '/order-details/status/${order.orderNumber}',
          data: order.toUpdatePaymentJson(),
        );
        final body = response.data;
        if (body is Map<String, dynamic> && body['success'] == false) {
          throw AppException(
            body['message']?.toString() ?? 'Update payment failed',
            statusCode: response.statusCode,
          );
        }
      },
      fallback: 'Update payment failed',
    );
  }

  /// Append new line items to an existing order.
  ///
  /// Wraps `POST /order-details/:orderNumber/items`. Server-side rules: order
  /// must not be in DELIVERED / COMPLETED / CANCELLED / REJECTED, caller must
  /// be the order's creator or have SUPER_ADMIN / ADMIN / MANAGER role.
  ///
  /// `items` is a list of payloads in the same shape as `order_details[]` on
  /// create:
  ///   { product_id, qty_ordered, delivery_date, is_product_scheme,
  ///     dealer_discount_id?, discount_price? }
  Future<OrderModel> addItemsToOrder(
    String orderNumber,
    List<Map<String, dynamic>> items,
  ) {
    return guardDio(() async {
      final response = await _dio.post(
        '/order-details/$orderNumber/items',
        data: {'order_details': items},
      );
      // Backend returns `{ success, message, data: { order: {...} } }`.
      final data = response.data['data'];
      final orderJson = (data is Map && data['order'] != null)
          ? data['order'] as Map<String, dynamic>
          : (data as Map<String, dynamic>);
      return OrderModel.fromJson(orderJson);
    }, fallback: 'Add items failed');
  }

  Future<List<ProductionSummaryRow>> getProductionSummary() {
    return guardDio(() async {
      final response = await _dio.get('/order-details/production-summary');
      final data = response.data['data'] as List;
      return data
          .map((e) => ProductionSummaryRow.fromJson(e as Map<String, dynamic>))
          .toList();
    });
  }

  Future<List<OrderModel>> getOrdersByDealer(
    String dealerId, {
    int limit = 10000,
  }) {
    return guardDio(() async {
      final response = await _dio.get(
        '/order-details',
        queryParameters: {
          'includeRejected': false,
          'limit': limit,
          'page': 1,
          'dealer': dealerId,
        },
      );
      final data = response.data['data'] as List;
      return data.map((e) => OrderModel.fromJson(e['order'])).toList();
    });
  }
}
