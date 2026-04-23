// order_repository.dart
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/order_model.dart';
import '../../../network/dio_client.dart';

final orderRepositoryProvider = Provider<OrderRepository>((ref) {
  return OrderRepository();
});

class OrderRepository {
  final Dio _dio = DioClient.instance;

  /// Create new order
  Future<void> createOrder(OrderModel order) async {
    try {
      await _dio.post('/order-details/create-order',
          data: order.toJson());
    } on DioException catch (e) {
      throw Exception(e.response?.data?["message"]??e.message??'unknown error');
    }
  }

  /// ✅ Get all orders with pagination support
  Future<List<OrderModel>> getAllOrders({
    int? page,
    int? limit,
    String? status, // null or 'ALL' = no status param; else sent UPPERCASE
  }) async {
    try {
      final queryParameters = <String, dynamic>{
        'includeRejected': false,
        if (page != null) 'page': page,
        if (limit != null) 'limit': limit,
        if (status != null && status != 'ALL') 'status': status,
      };

      // If page is not provided, default to page 1
      if (page == null) {
        queryParameters['page'] = 1;
      }

      final response = await _dio.get(
        '/order-details',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = (response.data['data'] as List);
        print('✅ getAllOrders | page=${page ?? 1} | limit=${limit ?? 'default'} | status=$status | count=${data.length}');
        return data.map((e) => OrderModel.fromJson(e['order'])).toList();
      } else {
        throw Exception('Failed to fetch orders');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Unknown error';
      throw Exception(errorMsg);
    }
  }

  /// ✅ Get order by ID
  Future<OrderModel> getOrderById(String orderNumber) async {
    try {
      final response = await _dio.get('/order-details/$orderNumber');
      if (response.statusCode == 200) {
        final orderData = response.data['data']['order'];
        print(response.statusCode);
        print(response.data);
        return OrderModel.fromJson(orderData);
      } else {
        throw Exception('Failed to fetch order details');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Unknown error';
      throw Exception(errorMsg);
    }
  }

  /// ✅ Get orders by date filter
  Future<List<OrderModel>> getOrdersByDateFilter({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final start = DateTime.parse(startDate);

      final queryParameters = <String, dynamic>{
        // 'year': start.year,
        // 'month': start.month,
        'start_date': startDate,
        'end_date': endDate,
      };

      final response = await _dio.get(
        '/order-details/date-filter',
        queryParameters: queryParameters,
      );

      if (response.statusCode == 200) {
        final data = (response.data['data'] as List);
        print('✅ getOrdersByDateFilter | $queryParameters');
        return data.map((e) => OrderModel.fromJson(e['order'])).toList();
      } else {
        throw Exception('Failed to fetch orders by date');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Unknown error';
      throw Exception(errorMsg);
    }
  }

  /// 🔹 Update order status only (packed, production, unpack)
  Future<void> updateOrderItemStatus(OrderModel order) async {
    try {
      await _dio.put(
        '/order-details/status/${order.orderNumber}',
        data: order.toUpdateItemJson(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?["message"] ?? e.message ?? 'Unknown error');
    }
  }

  /// 🔹 Update entire order status
  Future<void> updateOrder(OrderModel order,{bool isPaymentUpdate = false}) async {
    try {
      await _dio.put(
        '/order-details/status/${order.orderNumber}',
        data: order.toUpdateJson(isPaymentUpdate: isPaymentUpdate),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?["message"] ?? e.message ?? 'Unknown error');
    }
  }

  Future<void> updateOrderPayment(OrderModel order) async {
    try {
      await _dio.put(
        '/order-details/status/${order.orderNumber}',
        data: order.toUpdatePaymentJson(),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.data?["message"] ?? e.message ?? 'Unknown error');
    }
  }

  Future<List<OrderModel>> getOrdersByDealer(String dealerId, {int limit = 10000}) async {
    try {
      final response = await _dio.get(
        '/order-details',
        queryParameters: {
          'includeRejected': false,
          'limit': limit,
          'page': 1,
          'dealer': dealerId, // ✅ dealer filter
        },
      );

      if (response.statusCode == 200) {
        final data = (response.data['data'] as List);
        return data.map((e) => OrderModel.fromJson(e['order'])).toList();
      } else {
        throw Exception('Failed to fetch dealer orders');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Unknown error';
      throw Exception(errorMsg);
    }
  }
}