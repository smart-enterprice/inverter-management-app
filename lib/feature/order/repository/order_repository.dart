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
 ///  create new order
  Future<void>createOrder(OrderModel order) async {
    try {
      await _dio.post('/order-details/create-order',
          data: order.toJson());
    } on DioException catch (e) {
      throw Exception(e.response?.data?["message"]??e.message??'unknown error');
    }
  }

  /// ✅ Get all orders
  Future<List<OrderModel>> getAllOrders() async {
    try {
      final response = await _dio.get('/order-details');
      if (response.statusCode == 200) {
        final data = (response.data['data'] as List);
        print('✅ Status: ${response.statusCode}');
        return  data.map((e) => OrderModel.fromJson(e['order'])).toList();
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
    required int year,
    required int month,
    required String startDate,
    required String endDate,
  }) async {
    try {
      final response = await _dio.get(
        '/order-details/date-filter',
        queryParameters: {
          'year': year,
          'month': month,
          'start_date': startDate,
          'end_date': endDate,
        },
      );

      if (response.statusCode == 200) {
        final List data = response.data;
        return data.map((e) => OrderModel.fromJson(e)).toList();
      } else {
        throw Exception('Failed to fetch filtered orders');
      }
    } on DioException catch (e) {
      final errorMsg = e.response?.data?['message'] ?? e.message ?? 'Unknown error';
      throw Exception(errorMsg);
    }
  }
}
