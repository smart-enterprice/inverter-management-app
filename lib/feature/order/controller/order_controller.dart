// order_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../model/order_model.dart';
import '../repository/order_repository.dart';

final orderControllerProvider =
StateNotifierProvider<OrderController, AsyncValue<List<OrderModel>>>((ref) {
  return OrderController(ref.read(orderRepositoryProvider),);
});
final orderByIdProvider = FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getOrderById(orderId);
});
class OrderController extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final OrderRepository _orderRepository;
  OrderController(this._orderRepository,) : super(const AsyncValue.loading()) {
    getAllOrders();
  }

  Future<void> createOrder(OrderModel order) async {
    try {
await _orderRepository.createOrder(order);
print(_orderRepository.createOrder(order));
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
    } on DioException catch (e) {
      rethrow;
    } catch (e, st) {
      rethrow;
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
    } on DioException catch (e) {
      rethrow;
    } catch (e) {
     rethrow;
    }
  }

  /// 🔹 Update order item status and refresh order list
  Future<void> updateOrderItemStatus(OrderModel order) async {
    try {
      await _orderRepository.updateOrderItemStatus(order);
      // Refresh orders after update
      await getAllOrders();
    } on DioException catch (e) {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }
  /// 🔹 Update entire order and refresh order list
  Future<void> updateOrder(OrderModel order) async {
    try {
      await _orderRepository.updateOrder(order);
      // Refresh orders after update
      await getAllOrders();
    } on DioException catch (e) {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updatePaymentOrder(OrderModel order) async {
    try {
      await _orderRepository.updateOrderPayment(order);
      // Refresh orders after update
      await getAllOrders();
    } on DioException catch (e) {
      rethrow;
    } catch (_) {
      rethrow;
    }
  }





}
