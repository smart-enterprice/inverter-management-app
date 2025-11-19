import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/model/user_model.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../screen/loadingScreen.dart';
import '../controller/order_controller.dart';
import '../../../model/order_model.dart';

class OrderViewPage extends ConsumerStatefulWidget {
  const OrderViewPage({super.key, required this.orderNumber});
  final String orderNumber;

  @override
  ConsumerState<OrderViewPage> createState() => _OrderViewPageState();
}

class _OrderViewPageState extends ConsumerState<OrderViewPage> {
  @override
  Widget build(BuildContext context) {
    final orderAsync = ref.watch(orderByIdProvider(widget.orderNumber));

    return orderAsync.when(
      loading: () => const Scaffold(body: GlobalLoader()),
      error: (err, st) => _buildErrorState(context, err.toString()),
      data: (order) => _buildOrderDetails(context, order!),
    );
  }

  Widget _buildErrorState(BuildContext context, String error) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off, size: 50, color: Colors.grey),
            const SizedBox(height: 10),
            const Text(
              "No Internet Connection",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: screenHeight * 0.01),
            ElevatedButton(
              onPressed: () {
                ref.read(orderByIdProvider(widget.orderNumber));
              },
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderDetails(BuildContext context, OrderModel order) {
    final (priorityColor, priorityBg) = _getPriorityColors(order.priority);
    final isDelivered = order.status == "DELIVERED";

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          'Order #${order.orderNumber}',
          style: TextStyle(
            fontSize: screenWidth * 0.042,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black12,
        actions: [
          IconButton(
            icon: Icon(Icons.share_outlined, size: screenWidth * 0.05),
            onPressed: _shareOrderDetails,
          ),
          // PopupMenuButton<String>(
          //   icon: Icon(Icons.more_vert_rounded, size: screenWidth * 0.05),
          //   onSelected: (value) => _handleMenuSelection(value, order),
          //   itemBuilder: (context) => [
          //     PopupMenuItem(
          //       value: 'invoice',
          //       child: Row(
          //         children: [
          //           Icon(Icons.receipt_long_rounded, size: screenWidth * 0.04),
          //           SizedBox(width: screenWidth * 0.03),
          //           Text('Generate Invoice'),
          //         ],
          //       ),
          //     ),
          //     // PopupMenuItem(
          //     //   value: 'repeat',
          //     //   child: Row(
          //     //     children: [
          //     //       Icon(Icons.replay_rounded, size: screenWidth * 0.04),
          //     //       SizedBox(width: screenWidth * 0.03),
          //     //       Text('Repeat Order'),
          //     //     ],
          //     //   ),
          //     // ),
          //     // PopupMenuItem(
          //     //   value: 'support',
          //     //   child: Row(
          //     //     children: [
          //     //       Icon(Icons.support_agent_rounded, size: screenWidth * 0.04),
          //     //       SizedBox(width: screenWidth * 0.03),
          //     //       Text('Contact Support'),
          //     //     ],
          //     //   ),
          //     // ),
          //   ],
          // ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(bottom: screenHeight * 0.03),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with Status
            _buildOrderHeader(order, isDelivered, priorityColor, priorityBg),
            SizedBox(height: screenHeight * 0.025),

            // Quick Actions
            _buildQuickActions(order),
            SizedBox(height: screenHeight * 0.025),

            // Order Timeline
            _buildOrderTimeline(order),
            SizedBox(height: screenHeight * 0.025),

            // Dealer Information
            if (order.dealer != null) _buildDealerSection(order.dealer!),
            SizedBox(height: screenHeight * 0.025),

            // Order Details
            _buildOrderDetailsSection(order),
            SizedBox(height: screenHeight * 0.025),

            // Order Items
            _buildOrderItemsSection(order),
            SizedBox(height: screenHeight * 0.025),

            // Summary
            if (order.orderDetails.isNotEmpty) _buildSummarySection(order),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderHeader(
      OrderModel order,
      bool isDelivered,
      Color priorityColor,
      Color priorityBg,
      ) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Order #${order.orderNumber}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.045,
                      fontWeight: FontWeight.w700,
                      color: Colors.grey[900],
                      letterSpacing: -0.3,
                    ),
                  ),
                  SizedBox(height: screenHeight * 0.004),
                  Text(
                    'Placed on ${_formatDate(order.createdAt)}',
                    style: TextStyle(
                      fontSize: screenWidth * 0.034,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              _buildStatusBadge(isDelivered, order.status ?? ''),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          Divider(color: Colors.grey[200], height: 1),
          SizedBox(height: screenHeight * 0.02),
          Row(
            children: [
              _buildHeaderInfo(
                'Payment Status',
                order.paymentStatus ?? '',
                Icons.payment_rounded,
                Colors.blue,
              ),
              SizedBox(width: screenWidth * 0.06),
              _buildHeaderInfo(
                'Priority',
                order.priority,
                Icons.flag_rounded,
                priorityColor,
                isPriority: true,
                bgColor: priorityBg,
              ),
              SizedBox(width: screenWidth * 0.06),
              _buildHeaderInfo(
                'Amount',
                '₹${order.amountPaid}',
                Icons.currency_rupee_rounded,
                Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderInfo(
      String label,
      String value,
      IconData icon,
      Color color, {
        bool isPriority = false,
        Color? bgColor,
      }) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(screenWidth * 0.02),
                decoration: BoxDecoration(
                  color: bgColor ?? color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  size: screenWidth * 0.04,
                  color: color,
                ),
              ),
              SizedBox(width: screenWidth * 0.02),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            value,
            style: TextStyle(
              fontSize: screenWidth * 0.036,
              fontWeight: FontWeight.w700,
              color: Colors.grey[900],
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(OrderModel order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.04,
        vertical: screenHeight * 0.02,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // _buildActionButton(
          //   Icons.chat_rounded,
          //   'Support',
          //   Colors.blue,
          //       () => _contactSupport(order),
          // ),
          _buildActionButton(
            Icons.receipt_long_rounded,
            'Invoice',
            Colors.green,
                () => _generateInvoice(order),
          ),
          _buildActionButton(
            Icons.track_changes_rounded,
            'Track',
            Colors.orange,
                () => _trackOrder(order),
          ),
          // _buildActionButton(
          //   Icons.replay_rounded,
          //   'Repeat',
          //   Colors.purple,
          //       () => _repeatOrder(order),
          // ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: screenWidth * 0.12,
            height: screenWidth * 0.12,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              size: screenWidth * 0.05,
              color: color,
            ),
          ),
          SizedBox(height: screenHeight * 0.008),
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.03,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderTimeline(OrderModel order) {
    final steps = [
      _TimelineStep('Order Placed', _formatDate(order.createdAt), true, Icons.shopping_cart_rounded),
      _TimelineStep('Processing', _getProcessingStatus(order), _isStepCompleted(order, 'PROCESSING'), Icons.build_rounded),
      _TimelineStep('Production', _getProcessingStatus(order), _isStepCompleted(order, 'PROCESSING'), Icons.build_rounded),
      _TimelineStep('Packing', _getProcessingStatus(order), _isStepCompleted(order, 'PROCESSING'), Icons.build_rounded),
      _TimelineStep('Shipped', _getShippingStatus(order), _isStepCompleted(order, 'SHIPPED'), Icons.local_shipping_rounded),
      _TimelineStep('Delivered', _getDeliveryStatus(order), _isStepCompleted(order, 'DELIVERED'), Icons.verified_rounded),
    ];
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.timeline_rounded, size: screenWidth * 0.045, color: Colors.blue),
              SizedBox(width: screenWidth * 0.02),
              Text(
                'Order Timeline',
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          ...steps.map((step) => _buildTimelineStep(step)),
        ],
      ),
    );
  }

  Widget _buildTimelineStep(_TimelineStep step) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: screenHeight * 0.008),
      child: Row(
        children: [
          Container(
            width: screenWidth * 0.06,
            height: screenWidth * 0.06,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: step.isCompleted ? Colors.green : Colors.grey[300],
              border: Border.all(
                color: step.isCompleted ? Colors.green : Colors.grey[400]!,
                width: 2,
              ),
            ),
            child: step.isCompleted
                ? Icon(Icons.check_rounded, size: screenWidth * 0.035, color: Colors.white)
                : Icon(step.icon, size: screenWidth * 0.03, color: Colors.grey[600]),
          ),
          SizedBox(width: screenWidth * 0.03),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.title,
                  style: TextStyle(
                    fontSize: screenWidth * 0.035,
                    fontWeight: FontWeight.w500,
                    color: step.isCompleted ? Colors.grey[900] : Colors.grey[600],
                  ),
                ),
                Text(
                  step.subtitle,
                  style: TextStyle(
                    fontSize: screenWidth * 0.03,
                    color: step.isCompleted ? Colors.green[600]! : Colors.grey[500],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDealerSection(DealerModel dealer) {
    return _buildSectionCard(
      title: 'Dealer Information',
      icon: Icons.business_center_rounded,
      children: [
        _buildDetailRow(label: 'Name', value: dealer.employeeName),
        _buildDetailRow(label: 'Shop Name', value: dealer.shopName ?? 'N/A'),
        _buildDetailRow(label: 'Phone', value: dealer.employeePhone.toString()),
        _buildDetailRow(label: 'Email', value: dealer.employeeEmail),
        _buildDetailRow(label: 'Town', value: dealer.town ?? 'N/A'),
        _buildDetailRow(label: 'District', value: dealer.district ?? 'N/A'),
        _buildDetailRow(label: 'Address', value: dealer.address),
      ],
    );
  }

  Widget _buildOrderDetailsSection(OrderModel order) {
    return _buildSectionCard(
      title: 'Order Information',
      icon: Icons.receipt_long_rounded,
      children: [
        _buildDetailRow(
          label: 'Order Date',
          value: _formatDate(order.createdAt),
        ),
        _buildDetailRow(
          label: 'Amount Paid',
          value: '₹${order.amountPaid}',
          isBold: true,
        ),
        _buildDetailRow(label: 'Payment Method', value: order.paymentType),
        _buildDetailRow(
          label: 'Order Note',
          value: order.orderNote.isNotEmpty ? order.orderNote : 'No additional notes',
        ),
      ],
    );
  }

  Widget _buildOrderItemsSection(OrderModel order) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.only(bottom: screenHeight * 0.015),
            child: Text(
              'Order Items (${order.orderDetails.length})',
              style: TextStyle(
                fontSize: screenWidth * 0.04,
                fontWeight: FontWeight.w700,
                color: Colors.grey[900],
                letterSpacing: -0.3,
              ),
            ),
          ),
          ...order.orderDetails.map((item) => _buildOrderItemCard(item)),
        ],
      ),
    );
  }

  Widget _buildSummarySection(OrderModel order) {
    final totalItems = order.orderDetails.length;
    final totalQuantity = order.orderDetails.fold<int>(
      0, (sum, item) => sum + item.qtyOrdered!.toInt() ?? 0,
    );
    final deliveredQuantity = order.orderDetails.fold<int>(
      0, (sum, item) => sum + (item.deliveredQty ?? 0),
    );
    final progressPercentage = totalQuantity > 0 ? (deliveredQuantity / totalQuantity) * 100 : 0;

    return _buildSectionCard(
      title: 'Order Summary',
      icon: Icons.summarize_rounded,
      children: [
        _buildDetailRow(label: 'Total Items', value: totalItems.toString()),
        _buildDetailRow(label: 'Total Quantity', value: totalQuantity.toString()),
        _buildDetailRow(
          label: 'Delivered Quantity',
          value: deliveredQuantity.toString(),
        ),
        Divider(color: Colors.grey[200], height: screenHeight * 0.02),
        _buildDetailRow(
          label: 'Delivery Progress',
          value: '${progressPercentage.toStringAsFixed(1)}%',
          isBold: true,
        ),
      ],
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
      padding: EdgeInsets.all(screenWidth * 0.05),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: screenWidth * 0.045, color: Colors.blue),
              SizedBox(width: screenWidth * 0.02),
              Text(
                title,
                style: TextStyle(
                  fontSize: screenWidth * 0.038,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.02),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow({
    required String label,
    required String value,
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: screenHeight * 0.012),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: screenWidth * 0.035,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                fontSize: screenWidth * 0.035,
                color: Colors.grey[800],
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(bool isDelivered, String status) {
    final color = isDelivered ? Colors.green : Colors.orange;
    final icon = isDelivered ? Icons.local_shipping_rounded : Icons.schedule_rounded;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: screenWidth * 0.03,
        vertical: screenHeight * 0.008,
      ),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: color[100]!,
          width: 1.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: screenWidth * 0.04,
            color: color[700],
          ),
          SizedBox(width: screenWidth * 0.015),
          Text(
            status,
            style: TextStyle(
              color: color[700],
              fontWeight: FontWeight.w700,
              fontSize: screenWidth * 0.034,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderItemCard(OrderDetailsModel item) {
    final progress = (item.deliveredQty ?? 0) / (item.qtyOrdered ?? 1);

    return Container(
      margin: EdgeInsets.only(bottom: screenHeight * 0.015),
      padding: EdgeInsets.all(screenWidth * 0.04),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: Colors.white,
        border: Border.all(
          color: Colors.grey.withOpacity(0.15),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: screenWidth * 0.1,
                height: screenWidth * 0.1,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.inventory_2_rounded,
                  size: screenWidth * 0.05,
                  color: Colors.blue[600],
                ),
              ),
              SizedBox(width: screenWidth * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.productName,
                      style: TextStyle(
                        fontSize: screenWidth * 0.038,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[900],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.004),
                    Text(
                      '${item.productBrand} • ${item.productModel}',
                      style: TextStyle(
                        fontSize: screenWidth * 0.032,
                        color: Colors.grey[600],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.008),
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: screenWidth * 0.025,
                            vertical: screenHeight * 0.005,
                          ),
                          decoration: BoxDecoration(
                            color: _getStatusColor(item.status?? '').withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: _getStatusColor(item.status?? '').withOpacity(0.3),
                            ),
                          ),
                          child: Text(
                            item.status?? '',
                            style: TextStyle(
                              color: _getStatusColor(item.status?? ''),
                              fontWeight: FontWeight.w600,
                              fontSize: screenWidth * 0.028,
                            ),
                          ),
                        ),
                        SizedBox(width: screenWidth * 0.02),
                        Text(
                          'Type: ${item.productType}',
                          style: TextStyle(
                            fontSize: screenWidth * 0.03,
                            color: Colors.grey[500],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: screenHeight * 0.015),
          Divider(color: Colors.grey[200], height: 1),
          SizedBox(height: screenHeight * 0.015),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildItemInfo('Ordered', '${item.qtyOrdered}'),
              _buildItemInfo('Delivered', '${item.deliveredQty ?? 0}'),
              _buildItemInfo('Pending', '${item.qtyOrdered! - (item.deliveredQty ?? 0)}'),
              Container(
                width: screenWidth * 0.2,
                child: Column(
                  children: [
                    LinearProgressIndicator(
                      value: progress,
                      backgroundColor: Colors.grey[200],
                      color: progress == 1 ? Colors.green : Colors.blue,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    SizedBox(height: screenHeight * 0.004),
                    Text(
                      '${(progress * 100).toStringAsFixed(0)}%',
                      style: TextStyle(
                        fontSize: screenWidth * 0.028,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildItemInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: screenWidth * 0.03,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: screenHeight * 0.004),
        Text(
          value,
          style: TextStyle(
            fontSize: screenWidth * 0.034,
            color: Colors.grey[800],
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // Helper Methods
  Color _getStatusColor(String status) {
    switch (status.toUpperCase()) {
      case 'DELIVERED':
        return Colors.green;
      case 'PROCESSING':
        return Colors.blue;
      case 'SHIPPED':
        return Colors.orange;
      case 'PENDING':
        return Colors.yellow[700]!;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return '${date.day}/${date.month}/${date.year}';
  }

  (Color, Color) _getPriorityColors(String priority) {
    switch (priority.toUpperCase()) {
      case 'HIGH':
        return (Colors.red[600]!, Colors.red[50]!);
      case 'MEDIUM':
        return (Colors.orange[600]!, Colors.orange[50]!);
      case 'LOW':
        return (Colors.green[600]!, Colors.green[50]!);
      default:
        return (Colors.grey[600]!, Colors.grey[100]!);
    }
  }

  bool _isStepCompleted(OrderModel order, String stepStatus) {
    final statusOrder = ['PLACED', 'PROCESSING', 'SHIPPED', 'DELIVERED'];
    final currentIndex = statusOrder.indexWhere((status) => order.status!.toUpperCase().contains(status));
    final stepIndex = statusOrder.indexWhere((status) => status == stepStatus);
    return currentIndex >= stepIndex;
  }

  String _getProcessingStatus(OrderModel order) {
    return order.status == 'PROCESSING' ? 'In progress' : 'Completed';
  }

  String _getShippingStatus(OrderModel order) {
    return order.status == 'SHIPPED' ? 'In transit' :
    order.status == 'DELIVERED' ? 'Completed' : 'Pending';
  }

  String _getDeliveryStatus(OrderModel order) {
    return order.status == 'DELIVERED' ? 'Completed' : 'Pending';
  }

  // Action Methods
  void _shareOrderDetails() {
    // Implement share functionality
  }

  void _handleMenuSelection(String value, OrderModel order) {
    switch (value) {
      case 'invoice':
        _generateInvoice(order);
        break;
      case 'repeat':
        _repeatOrder(order);
        break;
      case 'support':
        _contactSupport(order);
        break;
    }
  }

  void _contactSupport(OrderModel order) {
    // Implement contact support
  }

  void _generateInvoice(OrderModel order) {
    // Implement invoice generation
  }

  void _trackOrder(OrderModel order) {
    // Implement order tracking
  }

  void _repeatOrder(OrderModel order) {
    // Implement repeat order
  }
}

class _TimelineStep {
  final String title;
  final String subtitle;
  final bool isCompleted;
  final IconData icon;

  _TimelineStep(this.title, this.subtitle, this.isCompleted, this.icon);
}