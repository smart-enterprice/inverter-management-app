// order_controller.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../model/order_model.dart';
import '../repository/order_repository.dart';

// ─────────────────────────────────────────────
// Params classes — unchanged
// ─────────────────────────────────────────────

class OrderStatusParams {
  final String? status;
  const OrderStatusParams({this.status});
  bool get isAll => status == null || status == 'ALL';

  @override
  bool operator ==(Object other) =>
      other is OrderStatusParams && other.status == status;
  @override
  int get hashCode => status.hashCode;
}

class PaginatedOrderParams {
  final String? status;
  final int page;
  final int limit;
  const PaginatedOrderParams({this.status, required this.page, required this.limit});
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

class DateFilterParams {
  final String? startDate;
  final String? endDate;
  final String? deliveryStartDate;
  final String? deliveryEndDate;
  final int page;
  final int limit;

  const DateFilterParams({
    this.startDate,
    this.endDate,
    this.deliveryStartDate,
    this.deliveryEndDate,
    this.page = 1,
    this.limit = 20,
  });

  DateFilterParams copyWith({
    String? startDate,
    String? endDate,
    String? deliveryStartDate,
    String? deliveryEndDate,
    int? page,
    int? limit,
  }) => DateFilterParams(
    startDate: startDate ?? this.startDate,
    endDate: endDate ?? this.endDate,
    deliveryStartDate: deliveryStartDate ?? this.deliveryStartDate,
    deliveryEndDate: deliveryEndDate ?? this.deliveryEndDate,
    page: page ?? this.page,
    limit: limit ?? this.limit,
  );

  @override
  bool operator ==(Object other) =>
      other is DateFilterParams &&
          other.startDate == startDate &&
          other.endDate == endDate &&
          other.deliveryStartDate == deliveryStartDate &&
          other.deliveryEndDate == deliveryEndDate &&
          other.page == page &&
          other.limit == limit;

  @override
  int get hashCode =>
      Object.hash(startDate, endDate, deliveryStartDate, deliveryEndDate, page, limit);
}

// ─────────────────────────────────────────────
// FutureProvider family — unchanged
// ─────────────────────────────────────────────

final paginatedOrdersProvider = FutureProvider.autoDispose
    .family<List<OrderModel>, PaginatedOrderParams>((ref, params) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getAllOrders(
    status: params.isAll ? null : params.status,
    page: params.page,
    limit: params.limit,
  );
});

final ordersProvider = FutureProvider.autoDispose
    .family<List<OrderModel>, OrderStatusParams>((ref, params) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getAllOrders(
    status: params.isAll ? null : params.status,
  );
});

final filteredOrdersProvider = FutureProvider.autoDispose
    .family<List<OrderModel>, DateFilterParams>((ref, params) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrdersByDateFilter(
    startDate: params.startDate,
    endDate: params.endDate,
    deliveryStartDate: params.deliveryStartDate,
    deliveryEndDate: params.deliveryEndDate,
    page: params.page,
    limit: params.limit,
  );
});

final orderByIdProvider = FutureProvider.autoDispose
    .family<OrderModel?, String>((ref, orderId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrderById(orderId);
});

final recentOrdersProvider =
    FutureProvider.autoDispose<List<OrderModel>>((ref) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getAllOrders(limit: 5);
});

final ordersByDealerProvider = FutureProvider.autoDispose
    .family<List<OrderModel>, String>((ref, dealerId) async {
  final repository = ref.watch(orderRepositoryProvider);
  return repository.getOrdersByDealer(dealerId);
});

// ─────────────────────────────────────────────
// OrderController — AsyncNotifier
// ─────────────────────────────────────────────

final orderControllerProvider =
AsyncNotifierProvider<OrderController, List<OrderModel>>(
  OrderController.new,
);

class OrderController extends AsyncNotifier<List<OrderModel>> {
  late final OrderRepository _repo;

  @override
  Future<List<OrderModel>> build() async {
    _repo = ref.watch(orderRepositoryProvider);
    return _repo.getAllOrders(limit: 10000);
  }

  Future<void> createOrder(OrderModel order) {
    return _repo.createOrder(order);
  }

  Future<void> getAllOrders({int limit = 10000}) async {
    state = const AsyncValue.loading();
    try {
      final orders = await _repo.getAllOrders(limit: limit);
      state = AsyncValue.data(orders);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<OrderModel?> getOrderById(String orderId) async {
    try {
      return await _repo.getOrderById(orderId);
    } catch (_) {
      rethrow;
    }
  }

  Future<void> updateOrderItemStatus(OrderModel order) async {
    await _repo.updateOrderItemStatus(order);
    await getAllOrders();
  }

  Future<void> updateOrder(OrderModel order) async {
    await _repo.updateOrder(order);
    await getAllOrders();
  }

  Future<void> updatePaymentOrder(OrderModel order) async {
    await _repo.updateOrderPayment(order);
    await getAllOrders();
  }

  Future<List<OrderModel>> getOrdersByDealer(
    String dealerId, {
    int limit = 10000,
  }) {
    return _repo.getOrdersByDealer(dealerId, limit: limit);
  }
}