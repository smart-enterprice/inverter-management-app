import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/model/user_model.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../screen/loadingScreen.dart';
import '../../../widgets/circle_button.dart';
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
        body: SafeArea(
          child: Column(
            children: [
              /// TOP BAR (custom, no AppBar)
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Screen.w(context) * 0.04,
                  vertical: Screen.h(context) * 0.02,
                ),
                child: Row(
                  children: [
                    CircularIconButton(
                      icon: Icons.arrow_back_ios_rounded,
                      onTap: () => Navigator.pop(context),
                    ),
                    const Spacer(),
                    Text(
                      'Order Details',
                      style: Theme.of(context)
                          .textTheme
                          .bodyLarge
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    // keeps title centered
                    SizedBox(width: Screen.w(context) * 0.1),
                    // balance back button space
                  ],
                ),
              ),

              /// ERROR BODY
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.wifi_off,
                        size: 50,
                        color: Colors.grey,
                      ),
                      SizedBox(height: Screen.h(context) * 0.01),
                      const Text(
                        "No Internet Connection",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: Screen.h(context) * 0.02),
                      ElevatedButton(
                        onPressed: () {
                          ref.invalidate(orderByIdProvider(widget.orderNumber));
                        },
                        style: ElevatedButton.styleFrom(
                          shape: const CircleBorder(),
                          padding: const EdgeInsets.all(18),
                        ),
                        child: const Icon(Icons.refresh),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      data: (order) => Scaffold(
        backgroundColor: Colors.grey[50],
        body: SafeArea(
          child: Padding(
            padding:  EdgeInsets.symmetric(
          horizontal: Screen.w(context) * 0.04,
        ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.only(top :Screen.h(context) * 0.02),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      /// BACK BUTTON
                      CircularIconButton(
                        icon: Icons.arrow_back_ios_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      SizedBox(width: Screen.w(context) * 0.02),
                      /// TITLE + SUBTITLE
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
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
                              order?.orderNumber ?? 'N/A',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: Screen.w(context) * 0.03,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                          ],
                        ),
                      ),

                      /// STATUS CHIP
                      _buildStatusChip(
                        order!.status!,
                        context,
                        onTap: () {
                          print('Packed status tapped');
                          _showOrderStatusUpdateDialog(context, order);
                        },
                      ),

                    ],
                  ),
                ),
                SizedBox(height: Screen.h(context) * 0.02),
                // Order Summary Card
                Expanded(
                  child: RefreshIndicator(
                      backgroundColor: Colors.white,
                      color: Theme.of(context).primaryColor,
                      onRefresh: () async {
                        await Future.delayed(Duration(seconds: 2));
                        ref.invalidate(orderByIdProvider(widget.orderNumber));
                      },
                    child: SingleChildScrollView(
                      child: Column(
                        children: [
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
                        ],
                      ),
                    ),
                  ),
                ),
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
        'SHIPPED',
        'Delivered',
        'Completed',
        'CANCELLED',
        'Rejected',
      ];

      return updatableStatuses.contains(status.toUpperCase());
    }

    switch (status) {
      case 'pending':
        bgColor = Colors.amber.shade50;
        textColor = Colors.amber.shade800;
        displayText = status;
        iconWidget = Icon(
          Icons.pending_actions,
          size: Screen.w(context) * 0.045,
          color: textColor,
        );
        break;

      case 'confirmed':
        bgColor = Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        displayText = status;
        iconWidget = Icon(
          Icons.verified,
          size: Screen.w(context) * 0.045,
          color: textColor,
        );
        break;

      case 'PRODUCTION':
        bgColor = Colors.orange.shade50;
        textColor = Colors.orange.shade800;
        displayText = status;
        iconWidget = Icon(
          Icons.precision_manufacturing_rounded,
          size: Screen.w(context) * 0.045,
          color: textColor,
        );
        break;

      case 'PACKED':
        bgColor =Colors.blue.shade50;
        textColor = Colors.blue.shade800;
        displayText = status;
        iconWidget = SvgPicture.asset(
          AppIcons.box,
          width: Screen.w(context) * 0.045,
          colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
        );
        break;

      case 'INVOICE':
        bgColor = Colors.purple.shade50;
        textColor = Colors.purple.shade800;
        displayText = status;
        iconWidget = Icon(
          Icons.receipt_long,
          size: Screen.w(context) * 0.045,
          color: textColor,
        );
        break;

      case 'SHIPPED':
        bgColor = Colors.indigo.shade50;
        textColor = Colors.indigo.shade800;
        displayText = status;
        iconWidget = SvgPicture.asset(
          AppIcons.delivery,
          width: Screen.w(context) * 0.045,
          colorFilter: ColorFilter.mode(textColor, BlendMode.srcIn),
        );
        break;

      case 'COMPLETED':
        bgColor = Colors.green.shade50;
        textColor = Colors.green.shade800;
        displayText = status;
        iconWidget = Icon(
          Icons.check_circle_outline_rounded,
          size: Screen.w(context) * 0.045,
          color: textColor,
        );
        break;

      case 'delivered':
        bgColor = Colors.teal;
        textColor = Colors.white;
        displayText = status;
        iconWidget = Icon(
          Icons.local_shipping,
          size: Screen.w(context) * 0.045,
          color: textColor,
        );
        break;

      case 'cancelled':
        bgColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        displayText = status;
        iconWidget = Icon(
          Icons.cancel,
          size: Screen.w(context) * 0.045,
          color: textColor,
        );
        break;

      case 'REJECTED':
        bgColor = Colors.deepOrange.shade50;
        textColor = Colors.deepOrange.shade800;
        displayText = status;
        iconWidget = Icon(
          Icons.block,
          size: Screen.w(context) * 0.045,
          color: textColor,
        );
        break;


      default:
        bgColor = const Color(0xFFF5F5F5);
        textColor = const Color(0xFF616161);
        displayText = status;
        iconWidget = Icon(
          Icons.info,
          size: Screen.w(context) * 0.045,
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
      // margin: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
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
            // horizontal: Screen.w(context) * 0.04,
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
        // horizontal: Screen.w(context) * 0.04,
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
              SizedBox(width: Screen.w(context)*0.1,),
              TextButton(onPressed: (){
                final paymentController = TextEditingController();
                showDialog(
                  context: context,
                  builder: (ctx) {
                    bool isUpdating = false;
                    return StatefulBuilder(
                      builder: (context, setState) {
                        return Dialog(
                          backgroundColor: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.all(Screen.w(context) * 0.05),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Update Payment',style: TextStyle(
                                  fontSize: Screen.w(context) * 0.045,
                                  fontWeight: FontWeight.bold,
                                ),),
                                SizedBox(height: Screen.h(context) * 0.02),
                                TextField(
                                  controller: paymentController,
                                  keyboardType: TextInputType.number,
                                  decoration: InputDecoration(
                                    labelText: "Amount Paid",
                                    prefixText: "₹ ",
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                ),

                                SizedBox(height: Screen.h(context) * 0.03),

                                Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [

                                    TextButton(
                                      onPressed: isUpdating ? null : () => Navigator.pop(context),
                                      child:  Text("Cancel",style: TextStyle(color: Theme.of(context).primaryColor),),
                                    ),

                                    SizedBox(width: Screen.w(context) * 0.02),

                                    ElevatedButton(
                                      onPressed: isUpdating
                                          ? null
                                          : () async {

                                        final newAmount =
                                        double.tryParse(paymentController.text);

                                        if (newAmount == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              backgroundColor: Colors.red,
                                                content: Text("Enter valid amount")),
                                          );
                                          return;
                                        }

                                        setState(() => isUpdating = true);

                                        final updatedOrder = order.copyWith(
                                          amountPaid: newAmount,
                                        );

                                        try {
                                          await ref
                                              .read(orderControllerProvider.notifier)
                                              .updatePaymentOrder(updatedOrder);
                                            ref.invalidate(orderByIdProvider(order.orderNumber!));
                                          Navigator.pop(context);

                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(
                                              backgroundColor: Colors.green,
                                                content: Text("Payment updated")),
                                          );
                                        } catch (e) {
                                          setState(() => isUpdating = false);
                                          print('error: $e');
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              backgroundColor: Colors.red,
                                                content:
                                                Text("$e")),
                                          );
                                        }
                                      },

                                      child: isUpdating
                                          ? SizedBox(
                                        height: 18,
                                        width: 18,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                          : const Text("Update"),
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
              }, child: Text('Update',style: TextStyle(
                fontSize: Screen.w(context) * 0.03,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).primaryColor,
              ),))
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

  Widget paymentUpdateDialog({
    required BuildContext context,
    required TextEditingController paymentController,
    required VoidCallback onUpdate,
  }) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: EdgeInsets.all(Screen.w(context) * 0.05),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              "Update Payment",
              style: TextStyle(
                fontSize: Screen.w(context) * 0.045,
                fontWeight: FontWeight.bold,
              ),
            ),

            SizedBox(height: Screen.h(context) * 0.02),

            TextField(
              controller: paymentController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: "Amount Paid",
                prefixText: "₹ ",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            SizedBox(height: Screen.h(context) * 0.03),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text("Cancel"),
                ),

                SizedBox(width: Screen.w(context) * 0.02),

                ElevatedButton(
                  onPressed: onUpdate,
                  child: const Text("Update"),
                ),

              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderItemsSection(List<OrderDetailsModel> items, BuildContext context,OrderModel order) {
    return Container(
      margin: EdgeInsets.symmetric(
        // horizontal: Screen.w(context) * 0.04,
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
                                    GestureDetector(
                                        onTap: (){

                                        },
                                        child: _buildItemDetail(label:'Qty Delivered',value:item.qtyDelivered.toString(),context:context)),
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
                                      child: IconButton(
                                        icon: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              Icons.calendar_month,
                                              size: Screen.w(context) * 0.045,
                                              color: const Color(0xFF757575),
                                            ),
                                            SizedBox(width: Screen.w(context) * 0.015),
                                            Text(
                                              _formatDate(item.deliveryDate),
                                              style: TextStyle(
                                                fontSize: Screen.w(context) * 0.034,
                                                color: const Color(0xFF757575),
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        onPressed: () {
                                          _showDeliveryDateUpdateDialog(context, item, index, order);
                                        },
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
      )
  {
    bool isStatusConfirmed = false;
    bool isCancelled = false;

    // For PENDING: track which option is selected
    // 'CONFIRMED' or 'REJECTED' or null
    String? pendingSelection;

    String? nextStatus;
    String? statusLabel;

    final String currentStatus = order.status?.toUpperCase() ?? '';

    // Determine next status based on current status
    switch (currentStatus) {
      case 'PENDING':
      // Handled separately with two options
        break;
      case 'CONFIRMED':
        nextStatus = 'PACKED';
        statusLabel = 'Order Packed';
        break;
      case 'PACKED':
        nextStatus = 'INVOICE';
        statusLabel = 'Invoice Generated';
        break;
      case 'INVOICE':
        nextStatus = 'SHIPPED';
        statusLabel = 'Product Shipped';
        break;
      case 'SHIPPED':
        nextStatus = 'DELIVERED';
        statusLabel = 'Product Delivered';
        break;
      default:
        nextStatus = null;
        statusLabel = null;
    }

    // No update available for these statuses
    final bool isTerminalStatus =
        currentStatus == 'CANCELLED' ||
            currentStatus == 'REJECTED' ||
            currentStatus == 'DELIVERED';

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) {
            // What value will be sent to API
            final String? statusToSend = isCancelled
                ? 'CANCELLED'
                : currentStatus == 'PENDING'
                ? pendingSelection
                : isStatusConfirmed
                ? nextStatus
                : null;

            final bool canUpdate = isCancelled ||
                (currentStatus == 'PENDING'
                    ? pendingSelection != null
                    : isStatusConfirmed);

            // Button color logic
            final Color buttonColor = isCancelled
                ? const Color(0xFFC62828)
                : pendingSelection == 'REJECTED'
                ? const Color(0xFFE65100)
                : const Color(0xFF1976D2);

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
                    // ── Header ──
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(Screen.w(context) * 0.02),
                          decoration: BoxDecoration(
                            color: isCancelled
                                ? const Color(0xFFFFEBEE)
                                : const Color(0xFFE3F2FD),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.update_rounded,
                            color: isCancelled
                                ? const Color(0xFFC62828)
                                : const Color(0xFF1976D2),
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

                    SizedBox(height: Screen.h(context) * 0.025),

                    // ── Order Info ──
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

                    // ── Status Options ──

                    // CASE 1: Terminal status — no options
                    if (isTerminalStatus)
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
                                'No further updates available for a ${order.status} order.',
                                style: TextStyle(
                                  fontSize: Screen.w(context) * 0.034,
                                  color: const Color(0xFF757575),
                                ),
                              ),
                            ),
                          ],
                        ),
                      )

                    // CASE 2: PENDING — show CONFIRMED and REJECTED options
                    else if (currentStatus == 'PENDING') ...[
                      Text(
                        'Select Action',
                        style: TextStyle(
                          fontSize: Screen.w(context) * 0.035,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF757575),
                        ),
                      ),
                      SizedBox(height: Screen.h(context) * 0.01),

                      // CONFIRMED option
                      _buildSelectionTile(
                        context: context,
                        title: 'Confirm Order',
                        value: 'CONFIRMED',
                        groupValue: isCancelled ? null : pendingSelection,
                        isDisabled: isCancelled,
                        activeColor: const Color(0xFF1976D2),
                        activeBgColor: const Color(0xFFE3F2FD),
                        onTap: () {
                          setState(() {
                            pendingSelection = pendingSelection == 'CONFIRMED'
                                ? null
                                : 'CONFIRMED';
                          });
                        },
                      ),

                      SizedBox(height: Screen.h(context) * 0.01),

                      // REJECTED option
                      _buildSelectionTile(
                        context: context,
                        title: 'Reject Order',
                        value: 'REJECTED',
                        groupValue: isCancelled ? null : pendingSelection,
                        isDisabled: isCancelled,
                        activeColor: const Color(0xFFE65100),
                        activeBgColor: const Color(0xFFFFF4E6),
                        onTap: () {
                          setState(() {
                            pendingSelection = pendingSelection == 'REJECTED'
                                ? null
                                : 'REJECTED';
                          });
                        },
                      ),
                    ]

                    // CASE 3: Normal next status update
                    else if (nextStatus != null && statusLabel != null)
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: isStatusConfirmed
                                  ? Theme.of(context).primaryColor
                                  : const Color(0xFFE0E0E0),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(12),
                            color: isStatusConfirmed
                                ? const Color(0xFFE3F2FD).withValues(alpha: 0.3)
                                : Colors.white,
                          ),
                          child: CheckboxListTile(
                            value: isStatusConfirmed,
                            onChanged: isCancelled
                                ? null
                                : (value) {
                              setState(() {
                                isStatusConfirmed = value ?? false;
                              });
                            },
                            title: Text(
                              statusLabel,
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.038,
                                fontWeight: FontWeight.w600,
                                color: isCancelled ? Colors.grey : Colors.black87,
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
                        ),

                    // ── Cancel Option (hidden for terminal statuses and PENDING) ──
                    if (!isTerminalStatus && currentStatus != 'PENDING') ...[
                      SizedBox(height: Screen.h(context) * 0.015),
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: isCancelled
                                ? const Color(0xFFC62828)
                                : const Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          color: isCancelled
                              ? const Color(0xFFFFEBEE).withValues(alpha: 0.5)
                              : Colors.white,
                        ),
                        child: CheckboxListTile(
                          value: isCancelled,
                          onChanged: (value) {
                            setState(() {
                              isCancelled = value ?? false;
                              // Clear other selections when cancel is checked
                              if (isCancelled) {
                                isStatusConfirmed = false;
                                pendingSelection = null;
                              }
                            });
                          },
                          title: Text(
                            'Cancel Order',
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.038,
                              fontWeight: FontWeight.w600,
                              color: isCancelled
                                  ? const Color(0xFFC62828)
                                  : Colors.black87,
                            ),
                          ),
                          activeColor: const Color(0xFFC62828),
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
                      ),
                    ],

                    SizedBox(height: Screen.h(context) * 0.03),

                    // ── Action Buttons ──
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
                              'Close',
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.036,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF757575),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: Screen.w(context) * 0.03),
                        if (!isTerminalStatus)
                          Expanded(
                            child: ElevatedButton(
                              onPressed: !canUpdate
                                  ? null
                                  : () async {
                                try {
                                  showDialog(
                                    context: context,
                                    barrierDismissible: false,
                                    builder: (context) => Center(
                                      child: CircularProgressIndicator(
                                        color: buttonColor,
                                      ),
                                    ),
                                  );

                                  await ref
                                      .read(orderControllerProvider.notifier)
                                      .updateOrder(
                                    order.copyWith(status: statusToSend),
                                  );

                                  ref.refresh(
                                    orderByIdProvider(order.orderNumber!),
                                  );

                                  Navigator.pop(context); // close loader
                                  Navigator.pop(context); // close dialog

                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        _getSuccessMessage(statusToSend),
                                        style: TextStyle(
                                          fontSize: Screen.w(context) * 0.035,
                                        ),
                                      ),
                                      backgroundColor: buttonColor,
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  );
                                } catch (e) {
                                  Navigator.pop(context); // close loader
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed: ${e.toString()}',
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
                                backgroundColor: buttonColor,
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
                                isCancelled
                                    ? 'Cancel Order'
                                    : pendingSelection == 'REJECTED'
                                    ? 'Reject Order'
                                    : 'Update',
                                style: TextStyle(
                                  fontSize: Screen.w(context) * 0.036,
                                  fontWeight: FontWeight.w700,
                                  color: canUpdate
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

// ── Helper: Selection tile for PENDING options ──
  Widget _buildSelectionTile({
    required BuildContext context,
    required String title,
    required String value,
    required String? groupValue,
    required bool isDisabled,
    required Color activeColor,
    required Color activeBgColor,
    required VoidCallback onTap,
  }) {
    final bool isSelected = groupValue == value;

    return GestureDetector(
      onTap: isDisabled ? null : onTap,
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(
            color: isDisabled
                ? const Color(0xFFE0E0E0)
                : isSelected
                ? activeColor
                : const Color(0xFFE0E0E0),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(12),
          color: isDisabled
              ? const Color(0xFFF5F5F5)
              : isSelected
              ? activeBgColor.withValues(alpha: 0.4)
              : Colors.white,
        ),
        child: ListTile(
          leading: Container(
            width: Screen.w(context) * 0.06,
            height: Screen.w(context) * 0.06,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isDisabled
                    ? Colors.grey
                    : isSelected
                    ? activeColor
                    : const Color(0xFFBDBDBD),
                width: 2,
              ),
              color: isSelected ? activeColor : Colors.transparent,
            ),
            child: isSelected
                ? Icon(
              Icons.check,
              size: Screen.w(context) * 0.035,
              color: Colors.white,
            )
                : null,
          ),
          title: Text(
            title,
            style: TextStyle(
              fontSize: Screen.w(context) * 0.038,
              fontWeight: FontWeight.w600,
              color: isDisabled
                  ? Colors.grey
                  : isSelected
                  ? activeColor
                  : Colors.black87,
            ),
          ),
          contentPadding: EdgeInsets.symmetric(
            horizontal: Screen.w(context) * 0.03,
            vertical: Screen.h(context) * 0.005,
          ),
          dense: true,
        ),
      ),
    );
  }

// ── Helper: Success message ──
  String _getSuccessMessage(String? status) {
    switch (status) {
      case 'CONFIRMED':
        return 'Order confirmed successfully';
      case 'REJECTED':
        return 'Order rejected';
      case 'CANCELLED':
        return 'Order cancelled successfully';
      case 'INVOICE':
        return 'Invoice generated successfully';
      case 'SHIPPED':
        return 'Order marked as shipped';
      case 'DELIVERED':
        return 'Order marked as delivered';
      default:
        return 'Order status updated successfully';
    }
  }

  void _showItemStatusUpdateDialog(BuildContext context, OrderDetailsModel item, int index,OrderModel order) {
    bool? hasProduction = item.hasProduction ;
    bool? hasUnpacked = item.hasUnpacked ;
    bool productionCompleted = false;
    bool packingCompleted = false;


    bool statusChecked = false;
    String? nextStatus;

    if (item.status == 'PACKED') {
      nextStatus = 'INVOICE';
    } else if (item.status == 'INVOICE') {
      nextStatus = 'SHIPPED';
    } else if (item.status == 'SHIPPED') {
      nextStatus = 'DELIVERED';
    }


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
                      else if(hasUnpacked==false&&hasProduction==false)...[
                        if (nextStatus != null)
                          _buildCheckboxTile(
                            context: context,
                            title: 'Mark as $nextStatus',
                            subtitle: 'Update item status to ${nextStatus.toLowerCase()}',
                            value: statusChecked,
                            onChanged: (value) {
                              setState(() {
                                statusChecked = value ?? false;
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
                            onPressed: (productionCompleted || packingCompleted||statusChecked)
                                ? () {
                              // TODO: Replace with actual API call
                              _updateItemStatus(
                                item: item,
                                productionCompleted: productionCompleted,
                                packingCompleted: packingCompleted,
                                status: statusChecked ? nextStatus : null,
                              );

                              ref.invalidate(
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
                                color: (productionCompleted || packingCompleted||statusChecked)
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
    String? status,
  }) async
  {
    try {
      // Create updated item with new status flags
      final updatedItem = item.copyWith(
        orderDetailsNumber: item.orderDetailsNumber,
        hasProductionCompleted: productionCompleted == true ? true : item.hasProductionCompleted,
        hasPackedCompleted: packingCompleted == true ? true : item.hasPackedCompleted,
        newStatus:status,
      );
      print("this is the status : $status");

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
        status: null
      );
      print('📤 Sending to API:');
      print(updatedOrder.toUpdateItemJson());
      print('📝 Item update JSON:');
      print(updatedItem.toUpdateJson());
      print("✅ Status being sent: ${updatedItem.nextStatus}");
      print("✅ Full item data: ${updatedItem.toUpdateJson()}");
      // TODO: Call your API here
      // Example:
      final response = await ref.read(orderControllerProvider.notifier).updateOrderItemStatus(
      updatedOrder
      );
          print('Update data ${updatedOrder.toJson()}');
      // For now, just print the data that would be sent
      // print('Order Number: ${widget.orderNumber}');
      // print('Order Details Number: ${item.orderDetailsNumber}');
      // print('Update Data: ${updatedItem.toUpdateJson()}');

      // Refresh the order data after successful update
      ref.invalidate(orderByIdProvider(widget.orderNumber));

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
        // horizontal: Screen.w(context) * 0.04,
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

  void _showDeliveryDateUpdateDialog(
      BuildContext context,
      OrderDetailsModel item,
      int index,
      OrderModel order,
      ) {
    DateTime selectedDate = item.deliveryDate ?? DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
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
                            Icons.calendar_today_rounded,
                            color: const Color(0xFF1976D2),
                            size: Screen.w(context) * 0.06,
                          ),
                        ),
                        SizedBox(width: Screen.w(context) * 0.03),
                        Expanded(
                          child: Text(
                            'Update Delivery Date',
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

                    // Current delivery date
                    if (item.deliveryDate != null) ...[
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: Screen.w(context) * 0.04,
                            color: const Color(0xFF757575),
                          ),
                          SizedBox(width: Screen.w(context) * 0.02),
                          Text(
                            'Current Date: ',
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.034,
                              color: const Color(0xFF757575),
                            ),
                          ),
                          Text(
                            DateFormat('dd MMM yyyy').format(item.deliveryDate!),
                            style: TextStyle(
                              fontSize: Screen.w(context) * 0.034,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: Screen.h(context) * 0.02),
                    ],

                    // Date picker button
                    Container(
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Theme.of(context).primaryColor,
                          width: 1.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        color: const Color(0xFFE3F2FD).withValues(alpha: 0.3),
                      ),
                      child: ListTile(
                        leading: Container(
                          padding: EdgeInsets.all(Screen.w(context) * 0.02),
                          decoration: BoxDecoration(
                            color: Theme.of(context).primaryColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.calendar_month,
                            color: Theme.of(context).primaryColor,
                            size: Screen.w(context) * 0.05,
                          ),
                        ),
                        title: Text(
                          'New Delivery Date',
                          style: TextStyle(
                            fontSize: Screen.w(context) * 0.034,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          DateFormat('dd MMM yyyy').format(selectedDate),
                          style: TextStyle(
                            fontSize: Screen.w(context) * 0.038,
                            fontWeight: FontWeight.w700,
                            color: Theme.of(context).primaryColor,
                          ),
                        ),
                        trailing: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: Screen.w(context) * 0.04,
                          color: const Color(0xFF757575),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(const Duration(days: 365)),
                            builder: (context, child) {
                              return Theme(
                                data: Theme.of(context).copyWith(
                                  colorScheme: ColorScheme.light(
                                    primary: Theme.of(context).primaryColor,
                                    onPrimary: Colors.white,
                                    surface: Colors.white,
                                    onSurface: Colors.black,
                                  ),
                                  dialogBackgroundColor: Colors.white,
                                ),
                                child: child!,
                              );
                            },
                          );
                          if (pickedDate != null) {
                            setState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),

                    SizedBox(height: Screen.h(context) * 0.03),

                    // Action buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(context).pop(),
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
                            onPressed: () async {
                              try {
                                // Show loading
                                showDialog(
                                  context: context,
                                  barrierDismissible: false,
                                  builder: (context) => Center(
                                    child: CircularProgressIndicator(
                                      color: Theme.of(context).primaryColor,
                                    ),
                                  ),
                                );

                                // Update delivery date
                                await _updateDeliveryDate(
                                  item: item,
                                  newDate: selectedDate,
                                  order: order,
                                );

                                // Close loading dialog
                                if (mounted) Navigator.pop(context);

                                // Close date dialog
                                if (mounted) Navigator.pop(context);

                                // Show success message
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Delivery date updated successfully',
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
                                }
                              } catch (e) {
                                // Close loading dialog
                                if (mounted) Navigator.pop(context);

                                // Show error message
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Failed to update date: ${e.toString()}',
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
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF1976D2),
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
                                color: Colors.white,
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

// Update delivery date function
  Future<void> _updateDeliveryDate({
    required OrderDetailsModel item,
    required DateTime newDate,
    required OrderModel order,
  }) async
  {
    try {
      // Create updated item with new delivery date
      final updatedItem = item.copyWith(
        orderDetailsNumber: item.orderDetailsNumber,
        deliveryDate: newDate,
      );

      // Get the current order
      final currentOrder = ref.read(orderByIdProvider(widget.orderNumber)).value;

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

      // Call your API here
      await ref.read(orderControllerProvider.notifier).updateOrderItemStatus(
        updatedOrder,
      );

      print('✅ Delivery date updated successfully');
      print('Order Number: ${widget.orderNumber}');
      print('Order Details Number: ${item.orderDetailsNumber}');
      print('New Date: ${newDate.toIso8601String()}');

      // Refresh the order data after successful update
      ref.invalidate(orderByIdProvider(widget.orderNumber));
    } catch (e) {
      print('❌ Error updating delivery date: $e');
      rethrow;
    }
  }


}