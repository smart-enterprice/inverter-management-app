// order_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../model/order_model.dart';
import '../repository/order_repository.dart';

final orderControllerProvider =
StateNotifierProvider<OrderController, AsyncValue<List<OrderModel>>>((ref) {
  return OrderController(ref.read(orderRepositoryProvider));
});
final orderByIdProvider = FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getOrderById(orderId);
});
class OrderController extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final OrderRepository _orderRepository;

  OrderController(this._orderRepository) : super(const AsyncValue.loading()) {
    getAllOrders();
  }

  Future<void> createOrder(OrderModel order) async {
    try {
await _orderRepository.createOrder(order);
    } on DioException catch (e) {
       rethrow;
    }
  }
  /// Fetch all orders
  Future<void> getAllOrders() async {
    try {
      state = const AsyncValue.loading();
      final orders = await _orderRepository.getAllOrders();
      state = AsyncValue.data(orders);
    } on DioException catch (e, st) {
      state = AsyncValue.error(_handleDioError(e), st);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  /// Fetch single order by ID
  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      return await _orderRepository.getOrderById(orderId);
    } on DioException {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  /// Fetch orders by date filter
  Future<void> getOrdersByDateFilter({
    required int year,
    required int month,
    required String startDate,
    required String endDate,
  }) async {
    try {
      state = const AsyncValue.loading();
      final orders = await _orderRepository.getOrdersByDateFilter(
        year: year,
        month: month,
        startDate: startDate,
        endDate: endDate,
      );
      state = AsyncValue.data(orders);
    } on DioException catch (e, st) {
      state = AsyncValue.error(_handleDioError(e), st);
    } catch (e, st) {
      state = AsyncValue.error(e.toString(), st);
    }
  }

  /// Centralized Dio error handler
  String _handleDioError(DioException e) {
    if (e.response != null && e.response?.data is Map<String, dynamic>) {
      return e.response?.data['message'] ??
          e.response?.statusMessage ??
          'Something went wrong';
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
        return 'Connection timeout';
      case DioExceptionType.sendTimeout:
        return 'Request send timeout';
      case DioExceptionType.receiveTimeout:
        return 'Response receive timeout';
      case DioExceptionType.badResponse:
        return 'Bad response from server';
      case DioExceptionType.connectionError:
        return 'No internet connection';
      default:
        return e.message ?? 'Unexpected error occurred';
    }
  }
}
