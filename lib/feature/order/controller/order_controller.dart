// order_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../../model/order_model.dart';
import '../repository/order_repository.dart';

// ─────────────────────────────────────────────
// Params classes
// ─────────────────────────────────────────────

/// Used for status-based fetching (ALL or a specific status)
class OrderStatusParams {
  final String? status; // null / 'ALL' → no status param in API

  const OrderStatusParams({this.status});

  bool get isAll => status == null || status == 'ALL';

  @override
  bool operator ==(Object other) =>
      other is OrderStatusParams && other.status == status;

  @override
  int get hashCode => status.hashCode;
}

/// Used for paginated fetching with optional status filter
class PaginatedOrderParams {
  final String? status; // null or 'ALL' → no status param
  final int page;
  final int limit;

  const PaginatedOrderParams({
    this.status,
    required this.page,
    required this.limit,
  });

  bool get isAll => status == null || status == 'ALL';

  @override
  bool operator ==(Object other) =>
      other is PaginatedOrderParams &&
          other.status == status &&
          other.page == page &&
          other.limit == limit;

  @override
  int get hashCode => Object.hash(status, page, limit);
}

/// Used for date-range fetching (separate endpoint, no status)
class DateFilterParams {
  final String startDate; // 'yyyy-MM-dd'
  final String endDate;   // 'yyyy-MM-dd'

  const DateFilterParams({required this.startDate, required this.endDate});

  @override
  bool operator ==(Object other) =>
      other is DateFilterParams &&
          other.startDate == startDate &&
          other.endDate == endDate;

  @override
  int get hashCode => Object.hash(startDate, endDate);
}

// ─────────────────────────────────────────────
// Providers
// ─────────────────────────────────────────────

/// ALL orders or filtered by status (with pagination)
/// → /order-details?includeRejected=false&page=N&limit=N[&status=CANCELLED]
final paginatedOrdersProvider =
FutureProvider.family<List<OrderModel>, PaginatedOrderParams>(
        (ref, params) async {
      final repository = ref.watch(orderRepositoryProvider);
      return await repository.getAllOrders(
        status: params.isAll ? null : params.status,
        page: params.page,
        limit: params.limit,
      );
    });

/// Legacy provider - kept for backward compatibility
final ordersProvider =
FutureProvider.family<List<OrderModel>, OrderStatusParams>(
        (ref, params) async {
      final repository = ref.watch(orderRepositoryProvider);
      return await repository.getAllOrders(
        status: params.isAll ? null : params.status,
      );
    });

/// Date-range filtered orders (no status)
/// → /order-details/date-filter?year=...&month=...&start_date=...&end_date=...
final filteredOrdersProvider =
FutureProvider.family<List<OrderModel>, DateFilterParams>(
        (ref, params) async {
      final repository = ref.watch(orderRepositoryProvider);
      return await repository.getOrdersByDateFilter(
        startDate: params.startDate,
        endDate: params.endDate,
      );
    });

/// Single order by ID
final orderByIdProvider =
FutureProvider.family<OrderModel?, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getOrderById(orderId);
});

/// Recent 5 orders for dashboard
final recentOrdersProvider = FutureProvider<List<OrderModel>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getAllOrders(limit: 5);
});

/// Orders by dealer
final ordersByDealerProvider =
FutureProvider.family<List<OrderModel>, String>((ref, dealerId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return await repository.getOrdersByDealer(dealerId);
});

// ─────────────────────────────────────────────
// OrderController (create / update operations)
// ─────────────────────────────────────────────

final orderControllerProvider =
StateNotifierProvider<OrderController, AsyncValue<List<OrderModel>>>((ref) {
  return OrderController(ref.read(orderRepositoryProvider));
});

class OrderController extends StateNotifier<AsyncValue<List<OrderModel>>> {
  final OrderRepository _orderRepository;

  OrderController(this._orderRepository) : super(const AsyncValue.loading()) {
    getAllOrders();
  }

  Future<void> createOrder(OrderModel order) async {
    try {
      await _orderRepository.createOrder(order);
    } on DioException {
      rethrow;
    }
  }

  Future<void> getAllOrders({int limit = 10000}) async {
    try {
      state = const AsyncValue.loading();
      final orders = await _orderRepository.getAllOrders(limit: limit);
      state = AsyncValue.data(orders);
    } catch (e) {
      rethrow;
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      return await _orderRepository.getOrderById(orderId);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateOrderItemStatus(OrderModel order) async {
    try {
      final jsonData = order.toUpdateItemJson();
      print('📤 Sending to API (updateOrderItemStatus): $jsonData');
      await _orderRepository.updateOrderItemStatus(order);
      await getAllOrders();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateOrder(OrderModel order) async {
    try {
      final jsonData = order.toUpdateJson();

      print('📤 Sending to API (updateOrder): $jsonData');
      await _orderRepository.updateOrder(order);
      await getAllOrders();
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updatePaymentOrder(OrderModel order) async {
    try {
      final jsonData = order.toUpdatePaymentJson();

      print('📤 Sending to API (updatePayment): $jsonData');
      await _orderRepository.updateOrderPayment(order);
      await getAllOrders();
    } catch (_) {
      rethrow;
    }
  }

  Future<List<OrderModel>> getOrdersByDealer(String dealerId,
      {int limit = 10000}) async {
    try {
      return await _orderRepository.getOrdersByDealer(dealerId, limit: limit);
    } catch (_) {
      rethrow;
    }
  }
}