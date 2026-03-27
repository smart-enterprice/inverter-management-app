import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/order_model.dart';
import '../../../widgets/circle_button.dart';
import '../controller/order_controller.dart';
import 'order_view_page.dart';

class DealerOrdersScreen extends ConsumerStatefulWidget {
  final String dealerId;
  final String dealerName;

  const DealerOrdersScreen({
    super.key,
    required this.dealerId,
    required this.dealerName,
  });

  @override
  ConsumerState<DealerOrdersScreen> createState() => _DealerOrdersScreenState();
}

class _DealerOrdersScreenState extends ConsumerState<DealerOrdersScreen> {
  String _searchQuery = '';
  String? _selectedStatus;
  final _searchController = TextEditingController();

  final List<String> _statuses = [
    'ALL',
    'PENDING',
    'CONFIRMED',
    'PRODUCTION',
    'PACKED',
    'INVOICE',
    'SHIPPED',
    'DELIVERED',
    'COMPLETED',
    'CANCELLED',
    'REJECTED',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<OrderModel> _filtered(List<OrderModel> orders) {
    return orders.where((o) {
      // status filter
      final statusMatch = _selectedStatus == null ||
          _selectedStatus == 'ALL' ||
          (o.status?.toUpperCase() == _selectedStatus);

      // search filter
      final q = _searchQuery.toLowerCase();
      final searchMatch = q.isEmpty ||
          (o.orderNumber?.toLowerCase().contains(q) ?? false) ||
          (o.priority.toLowerCase().contains(q)) ||
          (o.status?.toLowerCase().contains(q) ?? false);

      return statusMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final ordersAsync = ref.watch(ordersByDealerProvider(widget.dealerId));

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // ── AppBar ──
            Padding(
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04,
                vertical: sh * 0.018,
              ),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  SizedBox(width: sw * 0.03),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.dealerName,
                          style: TextStyle(
                            fontSize: sw * 0.045,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                            letterSpacing: -0.5,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Orders',
                          style: TextStyle(
                            fontSize: sw * 0.032,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Total count badge
                  ordersAsync.whenOrNull(
                    data: (orders) => Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.03,
                        vertical: sw * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(sw * 0.05),
                      ),
                      child: Text(
                        '${orders.length} orders',
                        style: TextStyle(
                          fontSize: sw * 0.03,
                          fontWeight: FontWeight.w600,
                          color: Theme.of(context).primaryColor,
                        ),
                      ),
                    ),
                  ) ?? const SizedBox.shrink(),
                ],
              ),
            ),

            // ── Search bar ──
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
              child: TextField(
                controller: _searchController,
                onChanged: (v) => setState(() => _searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search by order number or status...',
                  hintStyle: TextStyle(
                    fontSize: sw * 0.035,
                    color: Colors.grey[400],
                  ),
                  prefixIcon: Icon(Icons.search_rounded,
                      color: Colors.grey[400], size: sw * 0.05),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? GestureDetector(
                    onTap: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                    child: Icon(Icons.clear_rounded,
                        color: Colors.grey[400], size: sw * 0.045),
                  )
                      : null,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: sw * 0.04,
                    vertical: sh * 0.015,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw * 0.03),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw * 0.03),
                    borderSide: BorderSide(color: Colors.grey[200]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw * 0.03),
                    borderSide: BorderSide(
                        color: Theme.of(context).primaryColor, width: 1.5),
                  ),
                ),
              ),
            ),

            SizedBox(height: sh * 0.015),

            // ── Status filter chips ──
            SizedBox(
              height: sh * 0.045,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
                itemCount: _statuses.length,
                separatorBuilder: (_, __) => SizedBox(width: sw * 0.02),
                itemBuilder: (context, index) {
                  final status = _statuses[index];
                  final isSelected = (_selectedStatus == null && status == 'ALL') ||
                      _selectedStatus == status;
                  return GestureDetector(
                    onTap: () => setState(() {
                      _selectedStatus = status == 'ALL' ? null : status;
                    }),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.035,
                        vertical: sw * 0.015,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? _statusColor(status)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(sw * 0.05),
                        border: Border.all(
                          color: isSelected
                              ? _statusColor(status)
                              : Colors.grey[300]!,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        status,
                        style: TextStyle(
                          fontSize: sw * 0.03,
                          fontWeight: FontWeight.w600,
                          color: isSelected ? Colors.white : Colors.grey[600],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

            SizedBox(height: sh * 0.015),

            // ── Orders list ──
            Expanded(
              child: ordersAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.wifi_off_rounded,
                          size: sw * 0.15, color: Colors.grey[300]),
                      SizedBox(height: sh * 0.02),
                      Text(
                        'Failed to load orders',
                        style: TextStyle(
                          fontSize: sw * 0.04,
                          color: Colors.grey[500],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: sh * 0.02),
                      ElevatedButton.icon(
                        onPressed: () =>
                            ref.invalidate(ordersByDealerProvider(widget.dealerId)),
                        icon: const Icon(Icons.refresh_rounded),
                        label: const Text('Retry'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Theme.of(context).primaryColor,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                data: (orders) {
                  final filtered = _filtered(orders);

                  if (filtered.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.receipt_long_outlined,
                              size: sw * 0.18, color: Colors.grey[300]),
                          SizedBox(height: sh * 0.02),
                          Text(
                            _searchQuery.isNotEmpty || _selectedStatus != null
                                ? 'No orders match your filter'
                                : 'No orders yet',
                            style: TextStyle(
                              fontSize: sw * 0.04,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return RefreshIndicator(
                    color: Theme.of(context).primaryColor,
                    onRefresh: () async {
                      ref.invalidate(ordersByDealerProvider(widget.dealerId));
                      await Future.delayed(const Duration(seconds: 1));
                    },
                    child: ListView.separated(
                      padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.04,
                        vertical: sh * 0.01,
                      ),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => SizedBox(height: sh * 0.012),
                      itemBuilder: (context, index) {
                        return _buildOrderCard(filtered[index], context);
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(OrderModel order, BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final status = order.status?.toUpperCase() ?? '';

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => OrderViewPage(orderNumber: order.orderNumber!),
        ),
      ),
      child: Container(
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sw * 0.04),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 10,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Top row: order number + status ──
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.orderNumber ?? 'N/A',
                    style: TextStyle(
                      fontSize: sw * 0.038,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[900],
                      letterSpacing: -0.3,
                    ),
                  ),
                ),
                _buildStatusChip(status, context),
              ],
            ),

            SizedBox(height: sh * 0.012),
            Divider(height: 1, color: Colors.grey[100]),
            SizedBox(height: sh * 0.012),

            // ── Middle row: price + payment ──
            RoleGuard(
              feature: AppFeature.paymentView,
              child: Row(
                children: [
                  // Total price
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Amount',
                          style: TextStyle(
                            fontSize: sw * 0.028,
                            color: Colors.grey[500],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        SizedBox(height: sh * 0.003),
                        Text(
                          '₹${_formatNumber(order.orderTotalPrice ?? 0)}',
                          style: TextStyle(
                            fontSize: sw * 0.04,
                            fontWeight: FontWeight.bold,
                            color: Colors.grey[900],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Amount due
                  if (order.amountDue != null && order.amountDue! > 0)
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Amount Due',
                            style: TextStyle(
                              fontSize: sw * 0.028,
                              color: Colors.grey[500],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          SizedBox(height: sh * 0.003),
                          Text(
                            '₹${_formatNumber(order.amountDue)}',
                            style: TextStyle(
                              fontSize: sw * 0.038,
                              fontWeight: FontWeight.bold,
                              color: Colors.red[600],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Payment status
                  _buildPaymentChip(order.paymentStatus, context),
                ],
              ),
            ),

            SizedBox(height: sh * 0.012),

            // ── Bottom row: priority + date ──
            Row(
              children: [
                // Priority
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.025,
                    vertical: sw * 0.01,
                  ),
                  decoration: BoxDecoration(
                    color: _priorityColor(order.priority).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(sw * 0.02),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.flag_rounded,
                        size: sw * 0.032,
                        color: _priorityColor(order.priority),
                      ),
                      SizedBox(width: sw * 0.01),
                      Text(
                        order.priority,
                        style: TextStyle(
                          fontSize: sw * 0.028,
                          fontWeight: FontWeight.w600,
                          color: _priorityColor(order.priority),
                        ),
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Date
                Row(
                  children: [
                    Icon(Icons.calendar_today_outlined,
                        size: sw * 0.032, color: Colors.grey[400]),
                    SizedBox(width: sw * 0.015),
                    Text(
                      order.createdAt != null
                          ? DateFormat('dd MMM yyyy').format(order.createdAt!)
                          : 'N/A',
                      style: TextStyle(
                        fontSize: sw * 0.03,
                        color: Colors.grey[500],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),

                SizedBox(width: sw * 0.02),
                Icon(Icons.arrow_forward_ios_rounded,
                    size: sw * 0.03, color: Colors.grey[400]),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, BuildContext context) {
    final sw = Screen.w(context);
    final color = _statusColor(status);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sw * 0.025,
        vertical: sw * 0.012,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(sw * 0.05),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status,
        style: TextStyle(
          fontSize: sw * 0.028,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }

  Widget _buildPaymentChip(String? paymentStatus, BuildContext context) {
    final sw = Screen.w(context);
    Color color;
    switch (paymentStatus?.toUpperCase()) {
      case 'PAID':
        color = Colors.green;
        break;
      case 'PARTIAL':
        color = Colors.orange;
        break;
      case 'PENDING':
        color = Colors.red;
        break;
      default:
        color = Colors.grey;
    }
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: sw * 0.025,
        vertical: sw * 0.012,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(sw * 0.02),
      ),
      child: Text(
        paymentStatus ?? 'N/A',
        style: TextStyle(
          fontSize: sw * 0.028,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
        return Colors.amber[700]!;
      case 'CONFIRMED':
        return Colors.blue[700]!;
      case 'PRODUCTION':
        return Colors.orange[700]!;
      case 'PACKED':
        return Colors.blue[600]!;
      case 'INVOICE':
        return Colors.purple[700]!;
      case 'SHIPPED':
        return Colors.indigo[700]!;
      case 'DELIVERED':
        return Colors.teal[700]!;
      case 'COMPLETED':
        return Colors.green[700]!;
      case 'CANCELLED':
        return Colors.red[700]!;
      case 'REJECTED':
        return Colors.deepOrange[700]!;
      case 'ALL':
        return Colors.grey[700]!;
      default:
        return Colors.grey[600]!;
    }
  }

  Color _priorityColor(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return Colors.red[600]!;
      case 'MEDIUM':
        return Colors.orange[600]!;
      case 'LOW':
        return Colors.green[600]!;
      default:
        return Colors.grey[600]!;
    }
  }

  String _formatNumber(num? number) {
    if (number == null) return '0';
    final formatter = NumberFormat('#,##,###');
    return formatter.format(number);
  }
}