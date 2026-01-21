import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/model/user_model.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../screen/loadingScreen.dart';
import '../controller/order_controller.dart';
import '../../../model/order_model.dart';
import 'package:intl/intl.dart';

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
      error: (err, st) => Scaffold(
        appBar: AppBar(
          title: const Text('Order Details'),
        ),
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(Screen.w(context) * 0.05),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: Screen.w(context) * 0.2,
                  height: Screen.w(context) * 0.2,
                  decoration: BoxDecoration(
                    color: Colors.red.withAlpha(30),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.error_outline,
                    size: Screen.w(context) * 0.1,
                    color: Colors.red,
                  ),
                ),
                SizedBox(height: Screen.h(context) * 0.03),
                Text(
                  'Unable to Load Order',
                  style: TextStyle(
                    fontSize: Screen.w(context) * 0.045,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                SizedBox(height: Screen.h(context) * 0.01),
                Text(
                  'Error: ${err.toString()}',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: Screen.w(context) * 0.035,
                    color: Colors.grey[600],
                  ),
                ),
                SizedBox(height: Screen.h(context) * 0.03),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: Screen.w(context) * 0.06,
                      vertical: Screen.h(context) * 0.015,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Go Back',
                    style: TextStyle(
                      fontSize: Screen.w(context) * 0.038,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      data: (order) => Scaffold(
        backgroundColor: Colors.grey[50],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: IconButton(
            icon: SvgPicture.asset(
              AppIcons.back_Arrow,
              width: Screen.w(context) * 0.07,
              colorFilter:
              ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
            ),
            onPressed: () => Navigator.pop(context),
          ),
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Order Details',
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: Screen.w(context) * 0.042,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: Screen.h(context) * 0.002),
              Text(
                order!.orderNumber ?? 'N/A',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: Screen.w(context) * 0.03,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
          actions: [
            _buildStatusChip(order.status!, context,onTap:(){
              print('Packed status tapped');
              _showOrderStatusUpdateDialog(context, order);
            }),
            SizedBox(width: Screen.w(context) * 0.03),
          ],
        ),
        body: RefreshIndicator(
          backgroundColor: Colors.white,
          color: Theme.of(context).primaryColor,
          onRefresh: () async {
            await Future.delayed(Duration(seconds: 2));
            ref.refresh(orderByIdProvider(widget.orderNumber));
          },
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              children: [
                SizedBox(height: Screen.h(context) * 0.02),
          
                // Order Summary Card
                _buildOrderSummaryCard(order, context),
          
                // Dealer Information Card
                if (order.dealer != null)
                  _buildDealerCard(order.dealer!, context),
          
          
                // Order Items
                _buildOrderItemsSection(order.orderDetails, context,order),
          
                // Price Breakdown
                _buildPriceBreakdown(order, context),
          
                // Order Notes
                if (order.orderNote.isNotEmpty)
                  _buildNotesCard(order, context),
          
                // Payment Information Card
                _buildPaymentCard(order, context),
          
                SizedBox(height: Screen.h(context) * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatusChip(String status, BuildContext context,{required VoidCallback onTap})
  {
    Color bgColor;
    Color textColor;
    String displayText;
    Widget? iconWidget;
    bool isStatusUpdatable(String? status) {
      if (status == null) return false;

      final updatableStatuses = [
        'PENDING',
        'PACKED',
        'INVOICE',
      ];

      return updatableStatuses.contains(status.toUpperCase());
    }

    switch (status) {
      case 'pending':
        bgColor = const Color(0xFFFFF4E6);
        textColor = const Color(0xFFE65100);
        displayText = 'Pending';
        iconWidget = Icon(
          Icons.pending_actions,
          size: Screen.w(context) * 0.035,
          color: textColor,
        );
        break;

      case 'confirmed':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        displayText = 'Confirmed';
        iconWidget = Icon(
          Icons.verified,
          size: Screen.w(context) * 0.035,
          color: textColor,
        );
        break;

      case 'delivered':
        bgColor = const Color(0xFFE8F5E8);
        textColor = const Color(0xFF2E7D32);
        displayText = 'Delivered';
        iconWidget = Icon(
          Icons.local_shipping,
          size: Screen.w(context) * 0.035,
          color: textColor,
        );
        break;

      case 'cancelled':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        displayText = 'Cancelled';
        iconWidget = Icon(
          Icons.cancel,
          size: Screen.w(context) * 0.035,
          color: textColor,
        );
        break;

      case 'PACKED':
        bgColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        displayText = 'Packed';
        iconWidget = SvgPicture.asset(
          AppIcons.box,
          width: Screen.w(context) * 0.035,
          colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
        );
        break;

      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
        displayText = status;
        iconWidget = Icon(
          Icons.info,
          size: Screen.w(context) * 0.035,
          color: textColor,
        );
    }


    return GestureDetector(
        onTap: isStatusUpdatable(status)?onTap:null,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: Screen.w(context) * 0.03,
          vertical: Screen.h(context) * 0.008,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: textColor.withAlpha(80), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            iconWidget,
            SizedBox(width: Screen.w(context) * 0.015),
            Text(
              displayText,
              style: TextStyle(
                color: textColor,
                fontSize: Screen.w(context) * 0.03,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderSummaryCard(OrderModel order, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
      padding: EdgeInsets.all(Screen.w(context) * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withAlpha(15),
            blurRadius: 25,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Screen.w(context) * 0.035),
                decoration: BoxDecoration(
                  color: const Color(0xFFE3F2FD),
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  color: const Color(0xFF1976D2),
                  size: Screen.w(context) * 0.06,
                ),
              ),
              SizedBox(width: Screen.w(context) * 0.04),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Summary',
                      style: TextStyle(
                        fontSize: Screen.w(context) * 0.04,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    SizedBox(height: Screen.h(context) * 0.005),
                    Text(
                      'Created ${_formatDate(order.createdAt)}',
                      style: TextStyle(
                        fontSize: Screen.w(context) * 0.032,
                        color: const Color(0xFF757575),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: Screen.h(context) * 0.025),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SizedBox(height: Screen.h(context) * 0.025),
          _buildInfoRow('Priority', order.priority, Icons.flag_outlined, context),
          _buildInfoRow('Payment Type', order.paymentType, Icons.payment_rounded, context),
          if (order.totalCancelledQty != null && order.totalCancelledQty! > 0)
            _buildInfoRow(
              'Cancelled Qty',
              order.totalCancelledQty.toString(),
              Icons.cancel_outlined,
              context,
              valueColor: const Color(0xFFD32F2F),
            ),
        ],
      ),
    );
  }

  Widget _buildDealerCard(DealerModel dealer, BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        final isExpanded = ref.watch(_dealerCardExpandedProvider);

        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: Screen.w(context) * 0.04,
            vertical: Screen.h(context) * 0.01,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withAlpha(15),
                blurRadius: 25,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              // Header - Always visible
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: isExpanded ? Radius.zero : Radius.circular(20),
                    bottomRight: isExpanded ? Radius.zero : Radius.circular(20),
                  ),
                  onTap: () {
                    ref.read(_dealerCardExpandedProvider.notifier).state = !isExpanded;
                  },
                  child: Container(
                    padding: EdgeInsets.all(Screen.w(context) * 0.04),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: Screen.w(context) * 0.05,
                          backgroundColor: const Color(0xFFE1F5FE),
                          backgroundImage: dealer.photo.isNotEmpty
                              ? NetworkImage(dealer.photo)
                              : null,
                          child: dealer.photo.isEmpty
                              ? Text(
                            dealer.employeeName[0].toUpperCase(),
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.04,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0277BD),
                            ),
                          )
                              : null,
                        ),
                        SizedBox(width: Screen.w(context) * 0.04),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                dealer.employeeName,
                                style: TextStyle(
                                  fontSize: Screen.w(context) * 0.038,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: Screen.h(context) * 0.002),
                              Text(
                                'Dealer Information',
                                style: TextStyle(
                                  fontSize: Screen.w(context) * 0.032,
                                  color: const Color(0xFF757575),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        AnimatedRotation(
                          turns: isExpanded ? 0.5 : 0,
                          duration: const Duration(milliseconds: 300),
                          child: Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: Screen.w(context) * 0.035,
                            color: const Color(0xFF757575),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Expandable content
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                child: SizedBox(
                  height: isExpanded ? null : 0,
                  child: isExpanded
                      ? Padding(
                    padding: EdgeInsets.only(
                      left: Screen.w(context) * 0.04,
                      right: Screen.w(context) * 0.04,
                      bottom: Screen.w(context) * 0.04,
                    ),
                    child: Column(
                      children: [
                        const Divider(height: 1, color: Color(0xFFEEEEEE)),
                        SizedBox(height: Screen.h(context) * 0.02),
                        _buildInfoRow('Shop Name', dealer.shopName, Icons.storefront_rounded, context),
                        _buildInfoRow('Phone', dealer.employeePhone.toString(), Icons.phone_iphone_rounded, context),
                        _buildInfoRow('Email', dealer.employeeEmail, Icons.email_rounded, context),
                        _buildInfoRow('Location', '${dealer.town}, ${dealer.district}', Icons.location_on_rounded, context),
                        if (dealer.brand.isNotEmpty)
                          _buildInfoRow('Brands', dealer.brand.join(', '), Icons.branding_watermark_rounded, context),
                      ],
                    ),
                  )
                      : const SizedBox.shrink(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

// Add this provider for state management
  final _dealerCardExpandedProvider = StateProvider<bool>((ref) => false);

  Widget _buildPaymentCard(OrderModel order, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Screen.w(context) * 0.04,
        vertical: Screen.h(context) * 0.01,
      ),
      padding: EdgeInsets.all(Screen.w(context) * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withAlpha(15),
            blurRadius: 25,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Screen.w(context) * 0.035),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E8),
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFE8F5E8), Color(0xFFC8E6C9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Icon(
                  Icons.account_balance_wallet_rounded,
                  color: const Color(0xFF2E7D32),
                  size: Screen.w(context) * 0.06,
                ),
              ),
              SizedBox(width: Screen.w(context) * 0.04),
              Text(
                'Payment Information',
                style: TextStyle(
                  fontSize: Screen.w(context) * 0.04,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: Screen.h(context) * 0.025),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SizedBox(height: Screen.h(context) * 0.025),
          _buildInfoRow(
            'Payment Status',
            order.paymentStatus ?? 'N/A',
            Icons.info_outline_rounded,
            context,
            valueColor: _getPaymentStatusColor(order.paymentStatus),
          ),
          _buildInfoRow('Amount Paid', '₹${_formatNumber(order.amountPaid)}', Icons.payments_rounded, context),
          if (order.amountDue != null)
            _buildInfoRow(
              'Amount Due',
              '₹${_formatNumber(order.amountDue)}',
              Icons.money_off_rounded,
              context,
              valueColor: const Color(0xFFD32F2F),
            ),
        ],
      ),
    );
  }

  Widget _buildOrderItemsSection(List<OrderDetailsModel> items, BuildContext context,OrderModel order) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Screen.w(context) * 0.04,
        vertical: Screen.h(context) * 0.01,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withAlpha(15),
            blurRadius: 25,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.all(Screen.w(context) * 0.05),
            child: Row(
              children: [
                Container(
                  padding: EdgeInsets.all(Screen.w(context) * 0.035),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3E5F5),
                    borderRadius: BorderRadius.circular(16),
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF3E5F5), Color(0xFFE1BEE7)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    Icons.shopping_cart_rounded,
                    color: const Color(0xFF7B1FA2),
                    size: Screen.w(context) * 0.06,
                  ),
                ),
                SizedBox(width: Screen.w(context) * 0.04),
                Text(
                  'Order Items (${items.length})',
                  style: TextStyle(
                    fontSize: Screen.w(context) * 0.04,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: items.length,
            separatorBuilder: (context, index) => Divider(
              height: 1,
              color: const Color(0xFFEEEEEE),
              indent: Screen.w(context) * 0.05,
              endIndent: Screen.w(context) * 0.05,
            ),
            itemBuilder: (context, index) {
              final item = items[index];
              return _buildExpandableOrderItem(item, index + 1, context,order);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildExpandableOrderItem(OrderDetailsModel item, int index, BuildContext context,OrderModel order) {
    return Consumer(
      builder: (context, ref, child) {
        final isExpanded = ref.watch(_orderItemExpandedProvider(index));
        return Container(
          margin: EdgeInsets.symmetric(
            horizontal: Screen.w(context) * 0.04,
            vertical: Screen.h(context) * 0.008,
          ),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFEEEEEE), width: 1),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onLongPress: () {
                _showItemStatusUpdateDialog(context, item, index,order);
              },
              onTap: () {
                ref.read(_orderItemExpandedProvider(index).notifier).state = !isExpanded;
              },
              child: Padding(
                padding: EdgeInsets.all(Screen.w(context) * 0.04),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header - Always visible
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: Screen.w(context) * 0.08,
                          height: Screen.w(context) * 0.08,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                            gradient: const LinearGradient(
                              colors: [Color(0xFFE3F2FD), Color(0xFFBBDEFB)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: Center(
                            child: Text(
                              '$index',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: Screen.w(context) * 0.035,
                                color: const Color(0xFF1976D2),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Screen.w(context) * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      item.productName,
                                      style: TextStyle(
                                        fontSize: Screen.w(context) * 0.038,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ),
                                  if (item.isFree == true)
                                    Container(
                                      padding: EdgeInsets.symmetric(
                                        horizontal: Screen.w(context) * 0.025,
                                        vertical: Screen.h(context) * 0.005,
                                      ),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFE8F5E8),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(color: const Color(0xFF4CAF50), width: 1),
                                      ),
                                      child: Text(
                                        'FREE',
                                        style: TextStyle(
                                          color: const Color(0xFF2E7D32),
                                          fontSize: Screen.w(context) * 0.028,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              SizedBox(height: Screen.h(context) * 0.004),
                              _buildItemDetail(value:item.status.toString(), context: context),
                              SizedBox(height: Screen.h(context) * 0.004),
                              Text(
                                '${item.productBrand} • ${item.productModel}',
                                style: TextStyle(
                                  fontSize: Screen.w(context) * 0.033,
                                  color: const Color(0xFF757575),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              SizedBox(height: Screen.h(context) * 0.008),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [

                                  Text(
                                    'Qty: ${item.qtyOrdered}',
                                    style: TextStyle(
                                      fontSize: Screen.w(context) * 0.032,
                                      color: const Color(0xFF757575),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        item.totalProductPrice != null
                                            ? '₹${_formatNumber(item.totalProductPrice)}'
                                            : '₹${_formatNumber(item.productPrice)}',
                                        style: TextStyle(
                                          fontSize: Screen.w(context) * 0.036,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black87,
                                        ),
                                      ),
                                      SizedBox(width: Screen.w(context) * 0.02),
                                      AnimatedRotation(
                                        turns: isExpanded ? 0.5 : 0,
                                        duration: const Duration(milliseconds: 300),
                                        child: Icon(
                                          Icons.arrow_forward_ios_rounded,
                                          size: Screen.w(context) * 0.035,
                                          color: const Color(0xFF757575),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    // Expandable details
                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      child: SizedBox(
                        height: isExpanded ? null : 0,
                        child: isExpanded
                            ? Padding(
                          padding: EdgeInsets.only(top: Screen.h(context) * 0.02),
                          child: Column(
                            children: [
                              const Divider(height: 1, color: Color(0xFFEEEEEE)),
                              SizedBox(height: Screen.h(context) * 0.02),
                              Wrap(
                                spacing: Screen.w(context) * 0.04,
                                runSpacing: Screen.h(context) * 0.01,
                                children: [
                                  _buildItemDetail(value:item.status.toString(), context: context),
                                  _buildItemDetail(label: 'Type', value:item.productType,context:context),
                                  _buildItemDetail(label:'Qty Ordered',value:item.qtyOrdered.toString(),context:context),
                                  if (item.qtyDelivered != null)
                                    _buildItemDetail(label:'Qty Delivered',value:item.qtyDelivered.toString(),context:context),
                                  if (item.productType.isNotEmpty)
                                    _buildItemDetail(label:'Product Type',value:item.productType,context:context),
                                ],
                              ),
                              if (item.unitProductPrice != null) ...[
                                SizedBox(height: Screen.h(context) * 0.015),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Unit Price',
                                      style: TextStyle(
                                        fontSize: Screen.w(context) * 0.034,
                                        color: const Color(0xFF757575),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '₹${_formatNumber(item.unitProductPrice)}',
                                      style: TextStyle(
                                        fontSize: Screen.w(context) * 0.034,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (item.dealerDiscountAmount != null && item.dealerDiscountAmount! > 0) ...[
                                SizedBox(height: Screen.h(context) * 0.01),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      'Dealer Discount',
                                      style: TextStyle(
                                        fontSize: Screen.w(context) * 0.034,
                                        color: const Color(0xFF2E7D32),
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    Text(
                                      '-₹${_formatNumber(item.dealerDiscountAmount)}',
                                      style: TextStyle(
                                        fontSize: Screen.w(context) * 0.034,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF2E7D32),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              if (item.deliveryDate != null) ...[
                                SizedBox(height: Screen.h(context) * 0.015),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.local_shipping_rounded,
                                      size: Screen.w(context) * 0.035,
                                      color: const Color(0xFF757575),
                                    ),
                                    SizedBox(width: Screen.w(context) * 0.02),
                                    Expanded(
                                      child: Text(
                                        'Delivery Date: ${_formatDate(item.deliveryDate)}',
                                        style: TextStyle(
                                          fontSize: Screen.w(context) * 0.034,
                                          color: const Color(0xFF757575),
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        )
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  void _showOrderStatusUpdateDialog(
      BuildContext context,
      OrderModel order,
      ) {
    bool isConfirmed = false;
    String? nextStatus;
    String? statusLabel;

    // Determine next status based on current status
    switch (order.status?.toUpperCase()) {
      case 'PACKED':
        nextStatus = 'INVOICE';
        statusLabel = 'Invoice Generated';
        break;

      case 'INVOICE':
        nextStatus = 'SHIPPED';
        statusLabel = 'Product shipped';
        break;

      default:
        nextStatus = null;
        statusLabel = null;
    }

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Screen.w(context) * 0.05),
              ),
              child: Padding(
                padding: EdgeInsets.all(Screen.w(context) * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(Screen.w(context) * 0.02),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.update_rounded,
                            color: const Color(0xFF1976D2),
                            size: Screen.w(context) * 0.06,
                          ),
                        ),
                        SizedBox(width: Screen.w(context) * 0.03),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Update Order Status',
                                style: TextStyle(
                                  fontSize: Screen.w(context) * 0.045,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                              SizedBox(height: Screen.h(context) * 0.005),
                              Text(
                                'Current: ${order.status ?? "Unknown"}',
                                style: TextStyle(
                                  fontSize: Screen.w(context) * 0.032,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: Screen.h(context) * 0.03),

                    // Order info
                    Container(
                      padding: EdgeInsets.all(Screen.w(context) * 0.03),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Order: ${order.orderNumber ?? "N/A"}',
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.036,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          if (order.dealer != null) ...[
                            SizedBox(height: Screen.h(context) * 0.005),
                            Text(
                              'Dealer: ${order.dealer!.employeeName}',
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.032,
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),

                    SizedBox(height: Screen.h(context) * 0.025),

                    // Checkbox for status update
                    if (nextStatus != null && statusLabel != null)
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isConfirmed
                                ? Theme.of(context).primaryColor
                                : const Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isConfirmed
                              ? const Color(0xFFE3F2FD).withValues(alpha: 0.3)
                              : Colors.white,
                        ),
                        child: CheckboxListTile(
                          value: isConfirmed,
                          onChanged: (value) {
                            setState(() {
                              isConfirmed = value ?? false;
                            });
                          },
                          title: Text(
                            statusLabel,
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.038,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          subtitle: Text(
                            nextStatus.isEmpty
                                ? 'Mark this order as delivered'
                                : 'Generate invoice for this order',
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.032,
                              color: const Color(0xFF757575),
                            ),
                          ),
                          activeColor: Theme.of(context).primaryColor,
                          checkColor: Colors.white,
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: Screen.w(context) * 0.03,
                            vertical: Screen.h(context) * 0.005,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      )
                    else
                      Container(
                        padding: EdgeInsets.all(Screen.w(context) * 0.04),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: const Color(0xFFFFA726),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.info_outline_rounded,
                              color: const Color(0xFFF57C00),
                              size: Screen.w(context) * 0.05,
                            ),
                            SizedBox(width: Screen.w(context) * 0.03),
                            Expanded(
                              child: Text(
                                'No status updates available for this order.',
                                style: TextStyle(
                                  fontSize: Screen.w(context) * 0.034,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    SizedBox(height: Screen.h(context) * 0.03),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                vertical: Screen.h(context) * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFF757575)),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.036,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Screen.w(context) * 0.03),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: !isConfirmed
                                ? null
                                : () async {
                              try {
                                // Show loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) =>  Center(
                                    child: CircularProgressIndicator(color: Theme.of(context).primaryColor,),
                                  ),
                                );

                                // Update with next status
                                await ref
                                    .read(orderControllerProvider.notifier)
                                    .updateOrderStatus(
                                  order.copyWith(status: nextStatus),
                                );

                                // Refresh order data
                                ref.refresh(
                                  orderByIdProvider(order.orderNumber!),
                                );

                                // Close loading dialog
                                Navigator.pop(context);

                                // Close status dialog
                                Navigator.pop(context);

                                // Show success message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Order status updated successfully',
                                      style: TextStyle(
                                        fontSize: Screen.w(context) * 0.035,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFF4CAF50),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              } catch (e) {
                                // Close loading dialog
                                Navigator.pop(context);

                                // Show error message
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                      'Failed to update status: ${e.toString()}',
                                      style: TextStyle(
                                        fontSize: Screen.w(context) * 0.035,
                                      ),
                                    ),
                                    backgroundColor: const Color(0xFFD32F2F),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              disabledBackgroundColor: const Color(0xFFE0E0E0),
                              padding: EdgeInsets.symmetric(
                                vertical: Screen.h(context) * 0.015,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Update',
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.036,
                                fontWeight: FontWeight.w700,
                                color: !isConfirmed
                                    ? const Color(0xFF9E9E9E)
                                    : Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _showItemStatusUpdateDialog(BuildContext context, OrderDetailsModel item, int index,OrderModel order) {
    bool? hasProduction = item.hasProduction ;
    bool? hasUnpacked = item.hasUnpacked ;

    bool productionCompleted = false;
    bool packingCompleted = false;

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(Screen.w(context)*0.05),
              ),
              child: Padding(
                padding: EdgeInsets.all(Screen.w(context) * 0.05),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(Screen.w(context) * 0.02),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.assignment_turned_in_rounded,
                            color: const Color(0xFF1976D2),
                            size: Screen.w(context) * 0.06,
                          ),
                        ),
                        SizedBox(width: Screen.w(context) * 0.03),
                        Expanded(
                          child: Text(
                            'Update Status',
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.045,
                              fontWeight: FontWeight.w700,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: Screen.h(context) * 0.02),

                    // Product info
                    Container(
                      padding: EdgeInsets.all(Screen.w(context) * 0.03),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productName,
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.036,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                          SizedBox(height: Screen.h(context) * 0.005),
                          Text(
                            '${item.productBrand} • ${item.productModel}',
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.032,
                              color: const Color(0xFF757575),
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: Screen.h(context) * 0.025),

                    // If production is pending → show production completed checkbox
                    if (hasProduction == true) ...[
                      _buildCheckboxTile(
                        context: context,
                        title: 'Production Completed',
                        subtitle: 'Mark this item as production completed',
                        value: productionCompleted,
                        onChanged: (value) {
                          setState(() {
                            productionCompleted = value ?? false;
                          });
                        },
                      ),
                    ]

// If production done & packing pending → show packing completed checkbox
                    else if (hasUnpacked != false) ...[
                      _buildCheckboxTile(
                        context: context,
                        title: 'Packing Completed',
                        subtitle: 'Mark this item as packing completed',
                        value: packingCompleted,
                        onChanged: (value) {
                          setState(() {
                            packingCompleted = value ?? false;
                          });
                        },
                      ),
                    ]

// If everything done → show nothing (future expansion placeholder)
                    else ...[
                        SizedBox.shrink(),
                      ],
                    SizedBox(height: Screen.h(context) * 0.03),
                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: Screen.h(context) * 0.015),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              side: const BorderSide(color: Color(0xFF757575)),
                            ),
                            child: Text(
                              'Cancel',
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.036,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Screen.w(context) * 0.03),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: (productionCompleted || packingCompleted)
                                ? () {
                              // TODO: Replace with actual API call
                              _updateItemStatus(
                                item: item,
                                productionCompleted: productionCompleted,
                                packingCompleted: packingCompleted,
                              );
                              ref.refresh(
                                orderByIdProvider(order.orderNumber!),
                              );
                              Navigator.of(context).pop();

                              // Show success message
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    'Status updated successfully',
                                    style: TextStyle(fontSize: Screen.w(context) * 0.035),
                                  ),
                                  backgroundColor: const Color(0xFF4CAF50),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                ),
                              );
                            }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
                              disabledBackgroundColor: const Color(0xFFE0E0E0),
                              padding: EdgeInsets.symmetric(vertical: Screen.h(context) * 0.015),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: Text(
                              'Update',
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.036,
                                fontWeight: FontWeight.w700,
                                color: (productionCompleted || packingCompleted)
                                    ? Colors.white
                                    : const Color(0xFF9E9E9E),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildCheckboxTile({
    required BuildContext context,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool?> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(
          color: value ? const Color(0xFF1976D2) : const Color(0xFFE0E0E0),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(12),
        color: value ? const Color(0xFFE3F2FD).withValues(alpha: 0.3) : Colors.white,
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: onChanged,
        title: Text(
          title,
          style: TextStyle(
            fontSize: Screen.w(context) * 0.038,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: TextStyle(
            fontSize: Screen.w(context) * 0.032,
            color: const Color(0xFF757575),
          ),
        ),
        activeColor: const Color(0xFF1976D2),
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.symmetric(
          horizontal: Screen.w(context) * 0.03,
          vertical: Screen.h(context) * 0.005,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _updateItemStatus({
    required OrderDetailsModel item,
    bool? productionCompleted,
    bool? packingCompleted,
  }) async {
    try {
      // Create updated item with new status flags
      final updatedItem = item.copyWith(
        orderDetailsNumber: item.orderDetailsNumber,
        hasProductionCompleted: productionCompleted == true ? true : item.hasProductionCompleted,
        hasPackedCompleted: packingCompleted == true ? true : item.hasPackedCompleted,
      );

      // Get the current order
      final currentOrder = ref.read(orderByIdProvider(widget.orderNumber)).value;
      //
      if (currentOrder == null) {
        throw Exception('Order not found');
      }

      // Update the order details list with the modified item
      final updatedOrderDetails = currentOrder.orderDetails.map((detail) {
        if (detail.orderDetailsNumber == item.orderDetailsNumber) {
          return updatedItem;
        }
        return detail;
      }).toList();

      // Create updated order model
      final updatedOrder = currentOrder.copyWith(
        orderDetails: updatedOrderDetails,
      );

      // TODO: Call your API here
      // Example:
      final response = await ref.read(orderControllerProvider.notifier).updateOrderStatus(
      updatedOrder
      );


      // For now, just print the data that would be sent
      print('Order Number: ${widget.orderNumber}');
      print('Order Details Number: ${item.orderDetailsNumber}');
      print('Update Data: ${updatedItem.toUpdateJson()}');

      // Refresh the order data after successful update
      ref.refresh(orderByIdProvider(widget.orderNumber));

    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }

// Provider for managing expansion state of each order item
  final _orderItemExpandedProvider = StateProvider.family<bool, int>((ref, index) => false);



  Widget _buildItemDetail({String? label,  required String value,  required BuildContext context}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: Screen.w(context) * 0.025,
        vertical: Screen.h(context) * 0.004,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F5F5),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if(label != null)
          Text(
            '$label: ',
            style: TextStyle(
              fontSize: Screen.w(context) * 0.03,
              color: const Color(0xFF757575),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: Screen.w(context) * 0.03,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPriceBreakdown(OrderModel order, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Screen.w(context) * 0.04,
        vertical: Screen.h(context) * 0.01,
      ),
      padding: EdgeInsets.all(Screen.w(context) * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withAlpha(15),
            blurRadius: 25,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Breakdown',
            style: TextStyle(
              fontSize: Screen.w(context) * 0.04,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: Screen.h(context) * 0.02),
          if (order.orderTotalPrice != null)
            _buildPriceRow('Subtotal', order.orderTotalPrice!, context),
          if (order.orderTotalDiscount != null && order.orderTotalDiscount! > 0)
            _buildPriceRow('Discount', -order.orderTotalDiscount!, context, isDiscount: true),
          if (order.totalDealerDiscount != null && order.totalDealerDiscount! > 0)
            _buildPriceRow('Dealer Discount', -order.totalDealerDiscount!, context, isDiscount: true),
          SizedBox(height: Screen.h(context) * 0.015),
          const Divider(height: 1, color: Color(0xFFEEEEEE)),
          SizedBox(height: Screen.h(context) * 0.015),
          _buildPriceRow(
            'Total Amount',
            order.totalPrice ?? order.orderTotalPrice ?? 0,
            context,
            isTotal: true,
          ),
        ],
      ),
    );
  }

  Widget _buildPriceRow(String label, num amount, BuildContext context,
      {bool isDiscount = false, bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Screen.h(context) * 0.008),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: isTotal ? Screen.w(context) * 0.038 : Screen.w(context) * 0.035,
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? Colors.black87 : const Color(0xFF616161),
            ),
          ),
          Text(
            '${isDiscount ? '-' : ''}₹${_formatNumber(amount.abs())}',
            style: TextStyle(
              fontSize: isTotal ? Screen.w(context) * 0.042 : Screen.w(context) * 0.035,
              fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
              color: isDiscount
                  ? const Color(0xFF2E7D32)
                  : (isTotal ? const Color(0xFF1976D2) : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard(OrderModel order, BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(
        horizontal: Screen.w(context) * 0.04,
        vertical: Screen.h(context) * 0.01,
      ),
      padding: EdgeInsets.all(Screen.w(context) * 0.05),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF000000).withAlpha(15),
            blurRadius: 25,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(Screen.w(context) * 0.025),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF8E1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.note_alt_rounded,
                  color: const Color(0xFFF57C00),
                  size: Screen.w(context) * 0.05,
                ),
              ),
              SizedBox(width: Screen.w(context) * 0.03),
              Text(
                'Order Notes',
                style: TextStyle(
                  fontSize: Screen.w(context) * 0.038,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: Screen.h(context) * 0.02),
          Container(
            padding: EdgeInsets.all(Screen.w(context) * 0.04),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              order.orderNote,
              style: TextStyle(
                fontSize: Screen.w(context) * 0.035,
                color: const Color(0xFF616161),
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, IconData icon, BuildContext context,
      {Color? valueColor}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: Screen.h(context) * 0.01),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(Screen.w(context) * 0.025),
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              size: Screen.w(context) * 0.04,
              color: const Color(0xFF757575),
            ),
          ),
          SizedBox(width: Screen.w(context) * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: Screen.w(context) * 0.032,
                    color: const Color(0xFF9E9E9E),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: Screen.h(context) * 0.003),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: Screen.w(context) * 0.036,
                    fontWeight: FontWeight.w600,
                    color: valueColor ?? Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd MMM yyyy • hh:mm a').format(date);
  }

  String _formatNumber(num? number) {
    if (number == null) return '0';
    final formatter = NumberFormat('#,##,###');
    return formatter.format(number);
  }

  Color _getPaymentStatusColor(String? status) {
    if (status == null) return const Color(0xFF757575);
    switch (status.toLowerCase()) {
      case 'paid':
        return const Color(0xFF2E7D32);
      case 'pending':
        return const Color(0xFFF57C00);
      case 'failed':
        return const Color(0xFFD32F2F);
      default:
        return const Color(0xFF757575);
    }
  }
}