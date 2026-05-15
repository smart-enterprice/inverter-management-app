import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/order_model.dart';
import '../../../network/app_exception.dart';
import '../../../network/dio_client.dart';

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
  }) {
    return guardDio(() async {
      final queryParameters = <String, dynamic>{
        'includeRejected': false,
        'page': page ?? 1,
        if (limit != null) 'limit': limit,
        if (status != null && status != 'ALL') 'status': status,
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
      () => _dio.put(
        '/order-details/status/${order.orderNumber}',
        data: order.toUpdatePaymentJson(),
      ),
      fallback: 'Update payment failed',
    );
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
