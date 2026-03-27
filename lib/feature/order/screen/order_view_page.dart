import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import '../../../core/media_query/media_query.dart';
import '../../../screen/loadingScreen.dart';
import '../../../widgets/circle_button.dart';
import '../../signup/controller/signUp_controller.dart';
import 'order_payment_history.dart';
import '../controller/order_controller.dart';
import '../../../model/order_model.dart';


// ─── Constants ────────────────────────────────────────────────────────────────
const _kBlue        = Color(0xFF1B4FD8);
const _kBlueBg      = Color(0xFFEEF2FF);
const _kBlueBorder  = Color(0xFFC7D4FF);
const _kBg          = Color(0xFFF2F4F8);
const _kCard        = Colors.white;
const _kBorder      = Color(0xFFE5E7EB);
const _kDark        = Color(0xFF111827);
const _kMid         = Color(0xFF374151);
const _kMuted       = Color(0xFF9CA3AF);
const _kGreen       = Color(0xFF0A8A5C);
const _kGreenBg     = Color(0xFFEDFAF4);
const _kGreenBorder = Color(0xFF9FE0C5);
const _kRed         = Color(0xFFDC2626);
const _kRedBg       = Color(0xFFFEF2F2);
const _kRedBorder   = Color(0xFFFECACA);
const _kAmber       = Color(0xFFB45309);
const _kAmberBg     = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFCD28A);
const _kPurple      = Color(0xFF7C3AED);
const _kPurpleBg    = Color(0xFFF5F3FF);
const _kPurpleBorder = Color(0xFFDDD6FE);

// ─── Status helpers ───────────────────────────────────────────────────────────
_StatusStyle _statusStyle(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':
      return _StatusStyle(_kAmber, _kAmberBg, _kAmberBorder, Icons.pending_actions_rounded);
    case 'CONFIRMED':
      return _StatusStyle(_kBlue, _kBlueBg, _kBlueBorder, Icons.verified_rounded);
    case 'PRODUCTION':
      return _StatusStyle(const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFFFED7AA), Icons.precision_manufacturing_rounded);
    case 'PACKED':
      return _StatusStyle(_kBlue, _kBlueBg, _kBlueBorder, Icons.inventory_2_outlined);
    case 'INVOICE':
      return _StatusStyle(_kPurple, _kPurpleBg, _kPurpleBorder, Icons.receipt_long_rounded);
    case 'SHIPPED':
      return _StatusStyle(const Color(0xFF4338CA), const Color(0xFFEEF2FF), const Color(0xFFC7D2FE), Icons.local_shipping_outlined);
    case 'DELIVERED':
      return _StatusStyle(_kGreen, _kGreenBg, _kGreenBorder, Icons.check_circle_outline_rounded);
    case 'COMPLETED':
      return _StatusStyle(_kGreen, _kGreenBg, _kGreenBorder, Icons.task_alt_rounded);
    case 'CANCELLED':
      return _StatusStyle(_kRed, _kRedBg, _kRedBorder, Icons.cancel_outlined);
    case 'REJECTED':
      return _StatusStyle(const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFFFED7AA), Icons.block_rounded);
    default:
      return _StatusStyle(_kMuted, _kBg, _kBorder, Icons.info_outline_rounded);
  }
}

class _StatusStyle {
  final Color fg, bg, border;
  final IconData icon;
  const _StatusStyle(this.fg, this.bg, this.border, this.icon);
}

// ─── Dealer card expanded provider ───────────────────────────────────────────
final _dealerExpandedProvider = StateProvider<bool>((ref) => false);

// ─── Screen ──────────────────────────────────────────────────────────────────
class OrderViewPage extends ConsumerStatefulWidget {
  final String orderNumber;
  const OrderViewPage({super.key, required this.orderNumber});

  @override
  ConsumerState<OrderViewPage> createState() => _OrderViewPageState();
}

class _OrderViewPageState extends ConsumerState<OrderViewPage> {

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final orderAsync = ref.watch(orderByIdProvider(widget.orderNumber));

    return orderAsync.when(
      loading: () => const Scaffold(backgroundColor: _kBg, body: Center(child: GlobalLoader())),
      error: (_, __) => _buildError(context, sw, sh),
      data: (order) {
        if (order == null) return _buildError(context, sw, sh);
        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top Nav
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
                  child: Row(
                    children: [
                      CircularIconButton(icon: Icons.arrow_back_ios_rounded, onTap: () => Navigator.pop(context)),
                      SizedBox(width: sw * 0.025),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text('Order Details', style: TextStyle(fontSize: sw * 0.042, fontWeight: FontWeight.w700, color: _kDark, letterSpacing: -0.2)),
                          Text(order.orderNumber ?? '', style: TextStyle(fontSize: sw * 0.028, color: _kMuted, fontWeight: FontWeight.w500)),
                        ]),
                      ),
                      GestureDetector(
                        onTap: () => _showOrderStatusDialog(context, order),
                        child: _StatusChip(status: order.status ?? '', sw: sw),
                      ),
                    ],
                  ),
                ),

                // ── Body
                Expanded(
                  child: RefreshIndicator(
                    color: _kBlue,
                    backgroundColor: Colors.white,
                    onRefresh: () async => ref.invalidate(orderByIdProvider(widget.orderNumber)),
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                      child: Column(
                        children: [
                          _buildSummaryCard(context, sw, sh, order),
                          SizedBox(height: sh * 0.012),
                          if (order.dealer != null) ...[
                            _buildDealerCard(context, sw, sh, order.dealer!),
                            SizedBox(height: sh * 0.012),
                          ],
                          _buildItemsCard(context, sw, sh, order),
                          SizedBox(height: sh * 0.012),
                          RoleGuard(
                              feature: AppFeature.viewPrice,
                              child: _buildPriceCard(context, sw, sh, order)),
                          SizedBox(height: sh * 0.012),
                          RoleGuard(
                              feature: AppFeature.paymentView,
                              child: _buildPaymentCard(context, sw, sh, order)),
                          if (order.orderNote.isNotEmpty) ...[
                            SizedBox(height: sh * 0.012),
                            _buildNotesCard(sw, sh, order),
                          ],
                          SizedBox(height: sh * 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Summary Card ──────────────────────────────────────────────────────────
  Widget _buildSummaryCard(BuildContext context, double sw, double sh, OrderModel order) {
    final salesmanAsync = ref.watch(employeeByIdProvider(order.salesmanId));
    return _SectionCard(
      sw: sw,
      icon: Icons.receipt_long_rounded,
      iconBg: _kBlueBg,
      iconColor: _kBlue,
      title: 'Order Summary',
      child: Column(children: [
        _InfoRow(
          sw: sw,
          label: 'Salesman',
          value: salesmanAsync.when(data: (u) => u?.employeeName ?? 'N/A', loading: () => 'Loading...', error: (_, __) => 'N/A'),
          icon: Icons.person_outline_rounded,
        ),
        _InfoRow(sw: sw, label: 'Priority', value: order.priority, icon: Icons.flag_outlined, valueColor: _priorityColor(order.priority)),
        RoleGuard(
          feature: AppFeature.viewPrice,
            child: _InfoRow(sw: sw, label: 'Payment', value: order.paymentType, icon: Icons.payment_rounded)),
        _InfoRow(sw: sw, label: 'Created', value: _formatDate(order.createdAt), icon: Icons.calendar_today_outlined, isLast: order.totalCancelledQty == null || order.totalCancelledQty! <= 0),
        if (order.totalCancelledQty != null && order.totalCancelledQty! > 0)
          _InfoRow(sw: sw, label: 'Cancelled', value: order.totalCancelledQty.toString(), icon: Icons.cancel_outlined, valueColor: _kRed, isLast: true),
      ]),
    );
  }

  // ── Dealer Card ───────────────────────────────────────────────────────────
  Widget _buildDealerCard(BuildContext context, double sw, double sh, DealerModel dealer) {
    return Consumer(builder: (context, ref, _) {
      final expanded = ref.watch(_dealerExpandedProvider);
      return Container(
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(sw * 0.04),
          border: Border.all(color: _kBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(children: [
          GestureDetector(
            onTap: () => ref.read(_dealerExpandedProvider.notifier).state = !expanded,
            child: Padding(
              padding: EdgeInsets.all(sw * 0.04),
              child: Row(children: [
                CircleAvatar(
                  radius: sw * 0.055,
                  backgroundColor: _kBlueBg,
                  backgroundImage: dealer.photo.isNotEmpty ? NetworkImage(dealer.photo) : null,
                  child: dealer.photo.isEmpty
                      ? Text(dealer.employeeName[0].toUpperCase(), style: TextStyle(fontSize: sw * 0.04, fontWeight: FontWeight.w800, color: _kBlue))
                      : null,
                ),
                SizedBox(width: sw * 0.03),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(dealer.employeeName, style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w700, color: _kDark)),
                  Text('Dealer Information', style: TextStyle(fontSize: sw * 0.028, color: _kMuted, fontWeight: FontWeight.w500)),
                ])),
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(Icons.arrow_forward_ios_rounded, size: sw * 0.035, color: _kMuted),
                ),
              ]),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: expanded
                ? Column(children: [
              const Divider(height: 1, color: _kBorder),
              Padding(
                padding: EdgeInsets.fromLTRB(sw * 0.04, sw * 0.03, sw * 0.04, sw * 0.04),
                child: Column(children: [
                  _InfoRow(sw: sw, label: 'Shop', value: dealer.shopName, icon: Icons.storefront_outlined),
                  _InfoRow(sw: sw, label: 'Phone', value: dealer.employeePhone.toString(), icon: Icons.phone_outlined),
                  _InfoRow(sw: sw, label: 'Email', value: dealer.employeeEmail, icon: Icons.email_outlined),
                  _InfoRow(sw: sw, label: 'Location', value: '${dealer.town}, ${dealer.district}', icon: Icons.location_on_outlined, isLast: true),
                ]),
              ),
            ])
                : const SizedBox.shrink(),
          ),
        ]),
      );
    });
  }

  // ── Items Card ────────────────────────────────────────────────────────────
  Widget _buildItemsCard(BuildContext context, double sw, double sh, OrderModel order) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
          child: Row(children: [
            Container(
              width: sw * 0.075, height: sw * 0.075,
              decoration: BoxDecoration(color: _kPurpleBg, borderRadius: BorderRadius.circular(sw * 0.022), border: Border.all(color: _kPurpleBorder)),
              child: Icon(Icons.shopping_cart_outlined, size: sw * 0.04, color: _kPurple),
            ),
            SizedBox(width: sw * 0.025),
            Expanded(child: Text('Order Items', style: TextStyle(fontSize: sw * 0.035, fontWeight: FontWeight.w700, color: _kDark))),
            Container(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.025, vertical: sw * 0.008),
              decoration: BoxDecoration(color: _kPurpleBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kPurpleBorder)),
              child: Text('${order.orderDetails.length}', style: TextStyle(fontSize: sw * 0.026, fontWeight: FontWeight.w700, color: _kPurple)),
            ),
          ]),
        ),
        const Divider(height: 1, color: _kBorder),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: order.orderDetails.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _kBorder),
          itemBuilder: (_, i) => _buildItemRow(context, sw, sh, order.orderDetails[i], i, order),
        ),
      ]),
    );
  }

  Widget _buildItemRow(BuildContext context, double sw, double sh,
      OrderDetailsModel item, int index, OrderModel order) {
    final isCancelled = item.status == 'CANCELLED';
    final isCompleted = item.status == 'COMPLETED' || item.status == 'DELIVERED';
    final maxCancellable = (item.qtyOrdered ?? 0) - (item.qtyDelivered ?? 0);
    final st = _statusStyle(item.status ?? '');
    final hasCancellationHistory =
        item.cancellationHistory != null && item.cancellationHistory!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      color: isCancelled ? _kRedBg : Colors.transparent,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Product header ────────────────────────────────────────────────
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Index badge
          Container(
            width: sw * 0.08, height: sw * 0.08,
            decoration: BoxDecoration(
              color: isCancelled ? _kRedBg : _kBlueBg,
              borderRadius: BorderRadius.circular(sw * 0.022),
              border: Border.all(color: isCancelled ? _kRedBorder : _kBlueBorder),
            ),
            child: Center(child: Text('${index + 1}', style: TextStyle(fontSize: sw * 0.03, fontWeight: FontWeight.w800, color: isCancelled ? _kRed : _kBlue))),
          ),
          SizedBox(width: sw * 0.025),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Expanded(child: Text(item.productName, style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w700, color: _kDark))),
              if (item.isFree == true)
                RoleGuard(
                  feature: AppFeature.viewPrice,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.02, vertical: sw * 0.007),
                    decoration: BoxDecoration(color: _kGreenBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kGreenBorder)),
                    child: Text('FREE', style: TextStyle(fontSize: sw * 0.024, fontWeight: FontWeight.w800, color: _kGreen)),
                  ),
                ),
            ]),
            SizedBox(height: sw * 0.008),
            Text('${item.productBrand} • ${item.productModel}', style: TextStyle(fontSize: sw * 0.029, color: _kMuted, fontWeight: FontWeight.w500)),
          ])),
          RoleGuard(
            feature: AppFeature.viewPrice,
            child: Text(
              item.totalProductPrice != null ? '₹${_fmt(item.totalProductPrice)}' : '₹${_fmt(item.productPrice)}',
              style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w800, color: _kDark),
            ),
          ),
        ]),

        SizedBox(height: sw * 0.025),

        // ── Info chips ────────────────────────────────────────────────────
        Wrap(spacing: sw * 0.02, runSpacing: sw * 0.015, children: [
          _Chip(sw: sw, label: item.status ?? 'N/A', fg: st.fg, bg: st.bg, border: st.border),
          _Chip(sw: sw, label: 'Ordered: ${item.qtyOrdered ?? 0}', fg: _kBlue, bg: _kBlueBg, border: _kBlueBorder),
          _Chip(sw: sw, label: 'Delivered: ${item.qtyDelivered ?? 0}', fg: _kGreen, bg: _kGreenBg, border: _kGreenBorder),
          if (item.totalCancelledQty != null && item.totalCancelledQty! > 0)
            _Chip(sw: sw, label: 'Cancelled: ${item.totalCancelledQty}', fg: _kRed, bg: _kRedBg, border: _kRedBorder),
        ]),

        // ── Dealer discount ───────────────────────────────────────────────
        if (item.dealerDiscountAmount != null && item.dealerDiscountAmount! > 0) ...[
          SizedBox(height: sw * 0.015),
          Row(children: [
            Icon(Icons.discount_outlined, size: sw * 0.035, color: _kGreen),
            SizedBox(width: sw * 0.01),
            Text('Dealer discount: -₹${_fmt(item.dealerDiscountAmount)}',
                style: TextStyle(fontSize: sw * 0.03, color: _kGreen, fontWeight: FontWeight.w600)),
          ]),
        ],

        // ── Delivery date ─────────────────────────────────────────────────
        if (item.deliveryDate != null) ...[
          SizedBox(height: sw * 0.015),
          GestureDetector(
            onTap: isCancelled || isCompleted ? null : () => _showDeliveryDateDialog(context, item, index, order),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.local_shipping_outlined, size: sw * 0.035, color: _kMuted),
              SizedBox(width: sw * 0.01),
              Text(DateFormat('dd MMM yyyy').format(item.deliveryDate!),
                  style: TextStyle(fontSize: sw * 0.03, color: _kMid, fontWeight: FontWeight.w500)),
              if (!isCancelled && !isCompleted) ...[
                SizedBox(width: sw * 0.015),
                Icon(Icons.edit_outlined, size: sw * 0.032, color: _kBlue),
              ],
            ]),
          ),
        ],

        // ── Cancellation History ──────────────────────────────────────────
        if (hasCancellationHistory) ...[
          SizedBox(height: sw * 0.025),
          _buildCancellationHistory(sw, sh, item.cancellationHistory!),
        ],

        // ── Action buttons ────────────────────────────────────────────────
        if (!isCancelled && !isCompleted) ...[
          SizedBox(height: sw * 0.025),
          const Divider(height: 1, color: _kBorder),
          SizedBox(height: sw * 0.02),
          Row(children: [
            Expanded(child: RoleGuard(
                feature: AppFeature.updateOrderStatus,
                child: _ActionBtn(sw: sw, label: 'Update', icon: Icons.update_rounded, color: _kBlue, onTap: () => _showItemStatusDialog(context, item, index, order)))),
            SizedBox(width: sw * 0.02),
            if (maxCancellable > 0) ...[
              Expanded(child: RoleGuard(
                  feature: AppFeature.cancelOrder,
                  child: _ActionBtn(sw: sw, label: 'Cancel Qty', icon: Icons.remove_circle_outline, color: _kAmber, onTap: () => _showCancelQtyDialog(context, item, order, maxCancellable)))),
              SizedBox(width: sw * 0.02),
            ],
            Expanded(child: RoleGuard(
                feature: AppFeature.cancelOrder,
                child: _ActionBtn(sw: sw, label: 'Cancel', icon: Icons.cancel_outlined, color: _kRed, onTap: () => _showCancelItemDialog(context, item, order)))),
          ]),
        ],
      ]),
    );
  }

  // ── Cancellation History Section ──────────────────────────────────────────
  Widget _buildCancellationHistory(
      double sw, double sh, List<CancellationHistoryModel> history) {
    return Container(
      decoration: BoxDecoration(
        color: _kRedBg,
        borderRadius: BorderRadius.circular(sw * 0.03),
        border: Border.all(color: _kRedBorder),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.035, vertical: sw * 0.025),
          child: Row(children: [
            Container(
              width: sw * 0.065, height: sw * 0.065,
              decoration: BoxDecoration(color: _kRedBorder, borderRadius: BorderRadius.circular(sw * 0.018)),
              child: Icon(Icons.history_rounded, size: sw * 0.035, color: _kRed),
            ),
            SizedBox(width: sw * 0.02),
            Text('Cancellation History',
                style: TextStyle(fontSize: sw * 0.031, fontWeight: FontWeight.w700, color: _kRed)),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.02, vertical: sw * 0.006),
              decoration: BoxDecoration(color: _kRed.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(20)),
              child: Text('${history.length}', style: TextStyle(fontSize: sw * 0.025, fontWeight: FontWeight.w800, color: _kRed)),
            ),
          ]),
        ),
        const Divider(height: 1, color: _kRedBorder),

        // Entries
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          separatorBuilder: (_, __) => const Divider(height: 1, color: _kRedBorder),
          itemBuilder: (_, i) => _buildCancellationHistoryRow(sw, history[i], i, history.length),
        ),
      ]),
    );
  }

  Widget _buildCancellationHistoryRow(
      double sw, CancellationHistoryModel entry, int index, int total) {
    final isLast = index == total - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(sw * 0.035, sw * 0.025, sw * 0.035, isLast ? sw * 0.025 : sw * 0.02),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Timeline dot
        Column(children: [
          Container(
            width: sw * 0.055, height: sw * 0.055,
            decoration: BoxDecoration(
              color: _kRedBg,
              shape: BoxShape.circle,
              border: Border.all(color: _kRedBorder, width: 1.5),
            ),
            child: Center(
              child: Text('${index + 1}', style: TextStyle(fontSize: sw * 0.022, fontWeight: FontWeight.w800, color: _kRed)),
            ),
          ),
          if (!isLast)
            Container(width: 1.5, height: sw * 0.06, color: _kRedBorder),
        ]),
        SizedBox(width: sw * 0.025),

        // Content
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Qty + role badge
          Row(children: [
            Container(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.022, vertical: sw * 0.007),
              decoration: BoxDecoration(color: _kRed, borderRadius: BorderRadius.circular(20)),
              child: Text('-${entry.cancelledQty} unit${entry.cancelledQty > 1 ? 's' : ''}',
                  style: TextStyle(fontSize: sw * 0.026, fontWeight: FontWeight.w800, color: Colors.white)),
            ),
            SizedBox(width: sw * 0.015),
            Flexible(
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: sw * 0.018, vertical: sw * 0.006),
                decoration: BoxDecoration(color: _kAmberBg, borderRadius: BorderRadius.circular(20), border: Border.all(color: _kAmberBorder)),
                child: Text(
                  entry.cancelledByRole.replaceAll('ROLE_', '').replaceAll('_', ' '),
                  style: TextStyle(fontSize: sw * 0.022, fontWeight: FontWeight.w700, color: _kAmber),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ]),
          SizedBox(height: sw * 0.012),

          // Reason
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Icon(Icons.notes_rounded, size: sw * 0.03, color: _kMuted),
            SizedBox(width: sw * 0.01),
            Expanded(
              child: Text(
                entry.reason.isEmpty || entry.reason == 'Not provided' ? 'No reason provided' : entry.reason,
                style: TextStyle(
                  fontSize: sw * 0.03,
                  color: entry.reason.isEmpty || entry.reason == 'Not provided' ? _kMuted : _kMid,
                  fontWeight: FontWeight.w500,
                  fontStyle: entry.reason.isEmpty || entry.reason == 'Not provided' ? FontStyle.italic : FontStyle.normal,
                ),
              ),
            ),
          ]),
          SizedBox(height: sw * 0.008),

          // Date
          if (entry.cancelledAt != null)
            Row(children: [
              Icon(Icons.access_time_rounded, size: sw * 0.028, color: _kMuted),
              SizedBox(width: sw * 0.008),
              Text(
                DateFormat('dd MMM yyyy • hh:mm a').format(entry.cancelledAt!),
                style: TextStyle(fontSize: sw * 0.026, color: _kMuted, fontWeight: FontWeight.w500),
              ),
            ]),
        ])),
      ]),
    );
  }

  // ── Price Card ────────────────────────────────────────────────────────────
  Widget _buildPriceCard(BuildContext context, double sw, double sh, OrderModel order) {
    return _SectionCard(
      sw: sw,
      icon: Icons.calculate_outlined,
      iconBg: _kGreenBg,
      iconColor: _kGreen,
      title: 'Price Breakdown',
      child: Column(children: [
        if (order.orderTotalPrice != null)
          _PriceRow(sw: sw, label: 'Subtotal', amount: order.orderTotalPrice!),
        if (order.orderTotalDiscount != null && order.orderTotalDiscount! > 0)
          _PriceRow(sw: sw, label: 'Discount', amount: order.orderTotalDiscount!, isDiscount: true),
        if (order.totalDealerDiscount != null && order.totalDealerDiscount! > 0)
          _PriceRow(sw: sw, label: 'Dealer Discount', amount: order.totalDealerDiscount!, isDiscount: true),
        const Divider(height: 16, color: _kBorder),
        _PriceRow(sw: sw, label: 'Total', amount: order.totalPrice ?? order.orderTotalPrice ?? 0, isTotal: true),
      ]),
    );
  }

  // ── Payment Card ──────────────────────────────────────────────────────────
  Widget _buildPaymentCard(BuildContext context, double sw, double sh, OrderModel order) {
    return _SectionCard(
      sw: sw,
      icon: Icons.account_balance_wallet_outlined,
      iconBg: _kGreenBg,
      iconColor: _kGreen,
      title: 'Payment',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        // History button — only when payment notes exist
        if (order.paymentNotes != null && order.paymentNotes!.isNotEmpty) ...[
          GestureDetector(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PaymentHistoryPage(order: order)),
            ),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.03, vertical: sw * 0.01),
              decoration: BoxDecoration(
                color: _kGreenBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kGreenBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.history_rounded,
                    size: sw * 0.032, color: _kGreen),
                SizedBox(width: sw * 0.01),
                Text('History',
                    style: TextStyle(
                        fontSize: sw * 0.028,
                        fontWeight: FontWeight.w700,
                        color: _kGreen)),
              ]),
            ),
          ),
          SizedBox(width: sw * 0.02),
        ],
        // Update button
        RoleGuard(
          feature: AppFeature.updatePayment,
          child: GestureDetector(
            onTap: () => _showPaymentUpdateSheet(context, order),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.03, vertical: sw * 0.01),
              decoration: BoxDecoration(
                  color: _kBlueBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kBlueBorder)),
              child: Text('Update',
                  style: TextStyle(
                      fontSize: sw * 0.028,
                      fontWeight: FontWeight.w700,
                      color: _kBlue)),
            ),
          ),
        ),
      ]),
      child: Column(children: [
        _InfoRow(sw: sw, label: 'Status', value: order.paymentStatus ?? 'N/A', icon: Icons.info_outline_rounded, valueColor: _paymentStatusColor(order.paymentStatus)),
        _InfoRow(sw: sw, label: 'Paid', value: '₹${_fmt(order.amountPaid)}', icon: Icons.payments_outlined, valueColor: _kGreen),
        if (order.amountDue != null)
          _InfoRow(sw: sw, label: 'Due', value: '₹${_fmt(order.amountDue)}', icon: Icons.money_off_rounded, valueColor: _kRed, isLast: true),
      ]),
    );
  }

  // ── Notes Card ────────────────────────────────────────────────────────────
  Widget _buildNotesCard(double sw, double sh, OrderModel order) {
    return _SectionCard(
      sw: sw,
      icon: Icons.note_alt_outlined,
      iconBg: _kAmberBg,
      iconColor: _kAmber,
      title: 'Order Notes',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(sw * 0.035),
        decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(sw * 0.025), border: Border.all(color: _kBorder)),
        child: Text(order.orderNote, style: TextStyle(fontSize: sw * 0.033, color: _kMid, fontWeight: FontWeight.w500, height: 1.5)),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Dialogs & Sheets
  // ─────────────────────────────────────────────────────────────────────────

  void _showPaymentUpdateSheet(BuildContext context, OrderModel order) {
    final ctrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _PaymentUpdateSheet(
        order: order,
        onUpdate: (amount, paymentType) async {
          await ref.read(orderControllerProvider.notifier).updatePaymentOrder(
            order.copyWith(amountPaid: amount, paymentType: paymentType),
          );
          ref.invalidate(orderByIdProvider(order.orderNumber!));
          if (mounted) _showSnack('Payment updated successfully', Colors.green);
        },
      ),
    ).whenComplete(() => ctrl.dispose());
  }

  void _showOrderStatusDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => _OrderStatusDialog(
        order: order,
        onUpdate: (status, reason) async {
          await ref.read(orderControllerProvider.notifier).updateOrder(order.copyWith(status: status, reasonForCancellation: reason));
          ref.invalidate(orderByIdProvider(order.orderNumber!));
          if (mounted) _showSnack(_successMsg(status), Colors.green);
        },
      ),
    );
  }

  void _showItemStatusDialog(BuildContext context, OrderDetailsModel item, int index, OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => _ItemStatusDialog(
        item: item,
        onUpdate: (productionCompleted, packingCompleted, status) async {
          await _updateItemStatus(item: item, productionCompleted: productionCompleted, packingCompleted: packingCompleted, status: status);
          ref.invalidate(orderByIdProvider(order.orderNumber!));
          if (mounted) _showSnack('Status updated', Colors.green);
        },
      ),
    );
  }

  void _showCancelItemDialog(BuildContext context, OrderDetailsModel item, OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => _CancelItemDialog(
        item: item,
        onConfirm: (reason) async {
          await _updateItemStatus(item: item, status: 'CANCELLED', reasonForCancellation: reason);
          ref.invalidate(orderByIdProvider(order.orderNumber!));
          if (mounted) _showSnack('Item cancelled', _kRed);
        },
      ),
    );
  }

  void _showCancelQtyDialog(BuildContext context, OrderDetailsModel item, OrderModel order, int maxCancellable) {
    showDialog(
      context: context,
      builder: (_) => _CancelQtyDialog(
        item: item,
        maxCancellable: maxCancellable,
        onConfirm: (qty, reason) async {
          await _submitCancelQty(item: item, order: order, cancelQty: qty, reason: reason);
        },
      ),
    );
  }

  void _showDeliveryDateDialog(BuildContext context, OrderDetailsModel item, int index, OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => _DeliveryDateDialog(
        item: item,
        onUpdate: (date) async {
          await _updateDeliveryDate(item: item, newDate: date, order: order);
          if (mounted) _showSnack('Delivery date updated', Colors.green);
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  API Helpers
  // ─────────────────────────────────────────────────────────────────────────

  Future<void> _updateItemStatus({
    required OrderDetailsModel item,
    bool? productionCompleted,
    bool? packingCompleted,
    String? status,
    String? reasonForCancellation,
  }) async {
    final updatedItem = item.copyWith(
      hasProductionCompleted: productionCompleted,
      hasPackedCompleted: packingCompleted,
      newStatus: status,
      reasonForCancellation: reasonForCancellation,
      isReasonUpdated: reasonForCancellation != null,   // ✅
      isDeliveryDateUpdated: false,
      clearHasPackedCompleted: packingCompleted == null,
      clearHasProductionCompleted: productionCompleted == null,
      clearNextStatus: status == null,
      clearCancelQty: true,
      clearReasonForCancellation: reasonForCancellation == null,
    );

    final currentOrder = ref.read(orderByIdProvider(widget.orderNumber)).value;
    if (currentOrder == null) throw Exception('Order not found');

    final updatedDetails = currentOrder.orderDetails.map((d) {
      if (d.orderDetailsNumber == item.orderDetailsNumber) return updatedItem;
      // ✅ Reset all other items completely
      return d.copyWith(
        clearHasPackedCompleted: true,
        clearHasProductionCompleted: true,
        clearNextStatus: true,
        clearCancelQty: true,
        clearReasonForCancellation: true,
        isDeliveryDateUpdated: false,
        isReasonUpdated: false,
      );
    }).toList();

    await ref.read(orderControllerProvider.notifier).updateOrderItemStatus(
        currentOrder.copyWith(orderDetails: updatedDetails, status: null));
    ref.invalidate(orderByIdProvider(widget.orderNumber));
  }

  Future<void> _submitCancelQty({
    required OrderDetailsModel item,
    required OrderModel order,
    required int cancelQty,
    String? reason,
  }) async {
    final updatedItem = item.copyWith(
      cancelQty: cancelQty,
      reasonForCancellation: reason,
      isReasonUpdated: reason != null,
      isDeliveryDateUpdated: false,
      clearHasPackedCompleted: true,
      clearHasProductionCompleted: true,
      clearNextStatus: true,
    );

    final currentOrder = ref.read(orderByIdProvider(widget.orderNumber)).value;
    if (currentOrder == null) throw Exception('Order not found');

    final updatedDetails = currentOrder.orderDetails.map((d) {
      if (d.orderDetailsNumber == item.orderDetailsNumber) return updatedItem;
      return d.copyWith(
        clearHasPackedCompleted: true,
        clearHasProductionCompleted: true,
        clearNextStatus: true,
        clearCancelQty: true,
        clearReasonForCancellation: true,
        isDeliveryDateUpdated: false,
        isReasonUpdated: false, // ✅ fixed
      );
    }).toList();

    await ref.read(orderControllerProvider.notifier).updateOrderItemStatus(
        currentOrder.copyWith(orderDetails: updatedDetails));
    ref.invalidate(orderByIdProvider(widget.orderNumber));
    if (mounted) _showSnack('$cancelQty unit(s) cancelled', _kAmber);
  }

  Future<void> _updateDeliveryDate({
    required OrderDetailsModel item,
    required DateTime newDate,
    required OrderModel order,
  }) async {
    final updatedItem = item.copyWith(
        orderDetailsNumber: item.orderDetailsNumber,
        deliveryDate: newDate,
      isDeliveryDateUpdated: true,       // ✅
      isReasonUpdated: false,
      clearHasPackedCompleted: true,
      clearHasProductionCompleted: true,
      clearNextStatus: true,
      clearCancelQty: true,
      clearReasonForCancellation: true,
    );
    final currentOrder = ref.read(orderByIdProvider(widget.orderNumber)).value;
    if (currentOrder == null) throw Exception('Order not found');
    final updatedDetails = currentOrder.orderDetails
        .map((d) => d.orderDetailsNumber == item.orderDetailsNumber ? updatedItem : d)
        .toList();
    await ref.read(orderControllerProvider.notifier).updateOrderItemStatus(
        currentOrder.copyWith(orderDetails: updatedDetails));
    ref.invalidate(orderByIdProvider(widget.orderNumber));
  }

  // ─────────────────────────────────────────────────────────────────────────
  //  Misc helpers
  // ─────────────────────────────────────────────────────────────────────────

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _buildError(BuildContext context, double sw, double sh) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
          child: Row(children: [
            CircularIconButton(icon: Icons.arrow_back_ios_rounded, onTap: () => Navigator.pop(context)),
            const Spacer(),
            Text('Order Details', style: TextStyle(fontSize: sw * 0.042, fontWeight: FontWeight.w700, color: _kDark)),
            const Spacer(),
            SizedBox(width: sw * 0.095),
          ]),
        ),
        Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
            width: sw * 0.18, height: sw * 0.18,
            decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: _kBorder)),
            child: Icon(Icons.wifi_off_rounded, size: sw * 0.09, color: _kMuted),
          ),
          SizedBox(height: sh * 0.02),
          Text('No Internet Connection', style: TextStyle(fontSize: sw * 0.04, fontWeight: FontWeight.w600, color: _kMid)),
          SizedBox(height: sh * 0.025),
          ElevatedButton(
            onPressed: () => ref.invalidate(orderByIdProvider(widget.orderNumber)),
            style: ElevatedButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white, shape: const CircleBorder(), padding: const EdgeInsets.all(16), elevation: 0),
            child: const Icon(Icons.refresh_rounded),
          ),
        ]))),
      ])),
    );
  }

  String _formatDate(DateTime? d) {
    if (d == null) return 'N/A';
    return DateFormat('dd MMM yyyy • hh:mm a').format(d);
  }

  String _fmt(num? n) {
    if (n == null) return '0';
    return NumberFormat('#,##,###').format(n);
  }

  Color _priorityColor(String p) {
    switch (p.toUpperCase()) {
      case 'HIGH': return _kRed;
      case 'MEDIUM': return _kAmber;
      default: return _kGreen;
    }
  }

  Color _paymentStatusColor(String? s) {
    switch (s?.toLowerCase()) {
      case 'paid': return _kGreen;
      case 'pending': return _kAmber;
      case 'failed': return _kRed;
      default: return _kMuted;
    }
  }

  String _successMsg(String? s) {
    switch (s) {
      case 'CONFIRMED': return 'Order confirmed';
      case 'REJECTED': return 'Order rejected';
      case 'CANCELLED': return 'Order cancelled';
      case 'SHIPPED': return 'Marked as shipped';
      case 'DELIVERED': return 'Marked as delivered';
      default: return 'Status updated';
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
//  Sub-widgets
// ═══════════════════════════════════════════════════════════════════════════

class _StatusChip extends StatelessWidget {
  final String status;
  final double sw;
  const _StatusChip({required this.status, required this.sw});

  @override
  Widget build(BuildContext context) {
    final s = _statusStyle(status);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sw * 0.015),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: s.border, width: 1.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icon, size: sw * 0.04, color: s.fg),
        SizedBox(width: sw * 0.015),
        Text(status, style: TextStyle(fontSize: sw * 0.028, fontWeight: FontWeight.w700, color: s.fg)),
      ]),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final double sw;
  final IconData icon;
  final Color iconBg, iconColor;
  final String title;
  final Widget? trailing;
  final Widget child;

  const _SectionCard({
    required this.sw,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    this.trailing,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
          child: Row(children: [
            Container(
              width: sw * 0.075, height: sw * 0.075,
              decoration: BoxDecoration(
                color: iconBg,
                borderRadius: BorderRadius.circular(sw * 0.022),
                border: Border.all(color: iconBg == _kGreenBg ? _kGreenBorder : _kBlueBorder),
              ),
              child: Icon(icon, size: sw * 0.04, color: iconColor),
            ),
            SizedBox(width: sw * 0.025),
            Expanded(child: Text(title, style: TextStyle(fontSize: sw * 0.035, fontWeight: FontWeight.w700, color: _kDark))),
            if (trailing != null) trailing!,
          ]),
        ),
        const Divider(height: 1, thickness: 1, color: _kBorder),
        Padding(padding: EdgeInsets.all(sw * 0.04), child: child),
      ]),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final double sw;
  final String label, value;
  final IconData icon;
  final Color? valueColor;
  final bool isLast;

  const _InfoRow({
    required this.sw,
    required this.label,
    required this.value,
    required this.icon,
    this.valueColor,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: sw * 0.02),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: sw * 0.072, height: sw * 0.072,
            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(sw * 0.02), border: Border.all(color: _kBorder)),
            child: Icon(icon, size: sw * 0.036, color: _kMuted),
          ),
          SizedBox(width: sw * 0.025),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: sw * 0.028, color: _kMuted, fontWeight: FontWeight.w500)),
            SizedBox(height: sw * 0.005),
            Text(value, style: TextStyle(fontSize: sw * 0.034, fontWeight: FontWeight.w600, color: valueColor ?? _kDark)),
          ])),
        ]),
      ),
      if (!isLast) const Divider(height: 1, color: _kBorder),
    ]);
  }
}

class _PriceRow extends StatelessWidget {
  final double sw;
  final String label;
  final num amount;
  final bool isDiscount, isTotal;

  const _PriceRow({
    required this.sw,
    required this.label,
    required this.amount,
    this.isDiscount = false,
    this.isTotal = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.015),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label, style: TextStyle(fontSize: isTotal ? sw * 0.036 : sw * 0.032, fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500, color: isTotal ? _kDark : _kMid)),
        Text(
          '${isDiscount ? '-' : ''}₹${NumberFormat('#,##,###').format(amount.abs())}',
          style: TextStyle(fontSize: isTotal ? sw * 0.04 : sw * 0.032, fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600, color: isDiscount ? _kGreen : isTotal ? _kBlue : _kDark),
        ),
      ]),
    );
  }
}

class _Chip extends StatelessWidget {
  final double sw;
  final String label;
  final Color fg, bg, border;

  const _Chip({required this.sw, required this.label, required this.fg, required this.bg, required this.border});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: sw * 0.025, vertical: sw * 0.01),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20), border: Border.all(color: border)),
    child: Text(label, style: TextStyle(fontSize: sw * 0.026, fontWeight: FontWeight.w700, color: fg)),
  );
}

class _ActionBtn extends StatelessWidget {
  final double sw;
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _ActionBtn({required this.sw, required this.label, required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: sw * 0.038),
    label: Text(label, style: TextStyle(fontSize: sw * 0.028)),
    style: OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: sw * 0.025),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      side: BorderSide(color: color),
      foregroundColor: color,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
//  Dialog Widgets
// ═══════════════════════════════════════════════════════════════════════════

class _PaymentUpdateSheet extends StatefulWidget {
  final OrderModel order;
  final Future<void> Function(double amount, String paymentType) onUpdate;
  const _PaymentUpdateSheet({required this.order, required this.onUpdate});

  @override
  State<_PaymentUpdateSheet> createState() => _PaymentUpdateSheetState();
}

class _PaymentUpdateSheetState extends State<_PaymentUpdateSheet> {
  final _ctrl = TextEditingController();
  bool _loading = false;
  late String _selectedPaymentType;

  static const _paymentOptions = ['CASH', 'BANK'];

  @override
  void initState() {
    super.initState();
    // Pre-select current payment type if it matches, else default to CASH
    _selectedPaymentType = _paymentOptions.contains(widget.order.paymentType)
        ? widget.order.paymentType
        : 'CASH';
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Padding(
        padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Center(child: Container(width: 36, height: 4, margin: const EdgeInsets.only(bottom: 18), decoration: BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)))),
          Text('Update Payment', style: TextStyle(fontSize: sw * 0.045, fontWeight: FontWeight.w800, color: _kDark)),
          Text('Current: ₹${NumberFormat('#,##,###').format(widget.order.amountPaid)} · ${widget.order.paymentType}',
              style: TextStyle(fontSize: sw * 0.032, color: _kMuted, fontWeight: FontWeight.w500)),
          SizedBox(height: sw * 0.045),

          // ── Payment method selector ───────────────────────────────────
          Text('Payment Method *',
              style: TextStyle(fontSize: sw * 0.03, color: _kMuted, fontWeight: FontWeight.w600)),
          SizedBox(height: sw * 0.02),
          Row(
            children: _paymentOptions.map((type) {
              final isSelected = _selectedPaymentType == type;
              return Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _selectedPaymentType = type),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: EdgeInsets.only(
                        right: type != _paymentOptions.last ? sw * 0.02 : 0),
                    padding: EdgeInsets.symmetric(vertical: sw * 0.025),
                    decoration: BoxDecoration(
                      color: isSelected ? _kBlue : _kBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                          color: isSelected ? _kBlue : _kBorder,
                          width: isSelected ? 1.5 : 1),
                    ),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                        _paymentIcon(type),
                        size: sw * 0.05,
                        color: isSelected ? Colors.white : _kMuted,
                      ),
                      SizedBox(height: sw * 0.008),
                      Text(type,
                          style: TextStyle(
                              fontSize: sw * 0.026,
                              fontWeight: FontWeight.w700,
                              color: isSelected ? Colors.white : _kMid)),
                    ]),
                  ),
                ),
              );
            }).toList(),
          ),

          SizedBox(height: sw * 0.04),

          // ── Amount field ──────────────────────────────────────────────
          Text('Amount *',
              style: TextStyle(fontSize: sw * 0.03, color: _kMuted, fontWeight: FontWeight.w600)),
          SizedBox(height: sw * 0.02),
          TextField(
            controller: _ctrl,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: sw * 0.036, color: _kDark, fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(fontSize: sw * 0.034, color: _kMuted),
              prefixIcon: Icon(Icons.currency_rupee, color: _kGreen, size: sw * 0.045),
              filled: true, fillColor: _kBg,
              contentPadding: EdgeInsets.symmetric(horizontal: sw * 0.04),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBorder)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
            ),
          ),

          SizedBox(height: sh * 0.025),
          Row(children: [
            Expanded(child: OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: sh * 0.016), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: _kBorder)),
              child: Text('Cancel', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w700, color: _kMuted)),
            )),
            SizedBox(width: sw * 0.03),
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: _loading ? null : () async {
                final val = double.tryParse(_ctrl.text);
                if (val == null) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Enter a valid amount'), backgroundColor: _kRed));
                  return;
                }
                setState(() => _loading = true);
                try {
                  await widget.onUpdate(val, _selectedPaymentType);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _kRed));
                } finally {
                  if (mounted) setState(() => _loading = false);
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: sh * 0.016), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: _loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text('Update', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
  }

  IconData _paymentIcon(String type) {
    switch (type) {
      case 'CASH':   return Icons.payments_outlined;
      case 'BANK':   return Icons.account_balance_outlined;
      case 'CHEQUE': return Icons.edit_note_rounded;
      case 'UPI':    return Icons.phone_android_outlined;
      default:       return Icons.payment_rounded;
    }
  }
}

class _OrderStatusDialog extends StatefulWidget {
  final OrderModel order;
  final Future<void> Function(String? status, String? reason) onUpdate;
  const _OrderStatusDialog({required this.order, required this.onUpdate});

  @override
  State<_OrderStatusDialog> createState() => _OrderStatusDialogState();
}

class _OrderStatusDialogState extends State<_OrderStatusDialog> {
  bool _isStatusChecked = false;
  bool _isCancelled = false;
  String? _pendingSelection;
  String _cancelReason = '';
  bool _triedSubmit = false;
  bool _loading = false;

  String? get _nextStatus {
    switch ((widget.order.status ?? '').toUpperCase()) {
      case 'CONFIRMED': return 'PACKED';
      case 'PACKED':    return 'INVOICE';
      case 'INVOICE':   return 'SHIPPED';
      case 'SHIPPED':   return 'DELIVERED';
      default: return null;
    }
  }

  String? get _nextLabel {
    switch ((widget.order.status ?? '').toUpperCase()) {
      case 'CONFIRMED': return 'Order Packed';
      case 'PACKED':    return 'Invoice Generated';
      case 'INVOICE':   return 'Products Shipped';
      case 'SHIPPED':   return 'Products Delivered';
      default: return null;
    }
  }

  bool get _isPending   => (widget.order.status ?? '').toUpperCase() == 'PENDING';
  bool get _isTerminal  => ['CANCELLED', 'REJECTED', 'DELIVERED', 'COMPLETED'].contains((widget.order.status ?? '').toUpperCase());
  String? get _statusToSend {
    if (_isCancelled) return 'CANCELLED';
    if (_isPending) return _pendingSelection;
    if (_isStatusChecked) return _nextStatus;
    return null;
  }
  bool get _canUpdate {
    if (_isCancelled) return _cancelReason.trim().isNotEmpty;
    if (_isPending) return _pendingSelection != null;
    return _isStatusChecked;
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final btnColor = _isCancelled ? _kRed : _pendingSelection == 'REJECTED' ? _kAmber : _kBlue;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw * 0.05)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: Screen.h(context) * 0.8),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.05),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: EdgeInsets.all(sw * 0.022), decoration: BoxDecoration(color: _kBlueBg, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.update_rounded, color: _kBlue, size: sw * 0.055)),
              SizedBox(width: sw * 0.025),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Update Order Status', style: TextStyle(fontSize: sw * 0.042, fontWeight: FontWeight.w800, color: _kDark)),
                Text('Current: ${widget.order.status ?? ''}', style: TextStyle(fontSize: sw * 0.03, color: _kMuted)),
              ])),
            ]),
            SizedBox(height: sh * 0.02),
            Flexible(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: EdgeInsets.all(sw * 0.035),
                decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                child: Row(children: [
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.order.orderNumber ?? '', style: TextStyle(fontSize: sw * 0.034, fontWeight: FontWeight.w700, color: _kDark)),
                    if (widget.order.dealer != null)
                      Text(widget.order.dealer!.employeeName, style: TextStyle(fontSize: sw * 0.03, color: _kMuted)),
                  ])),
                ]),
              ),
              SizedBox(height: sh * 0.02),
              if (_isTerminal)
                Container(
                  padding: EdgeInsets.all(sw * 0.035),
                  decoration: BoxDecoration(color: _kAmberBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kAmberBorder)),
                  child: Row(children: [
                    Icon(Icons.info_outline_rounded, color: _kAmber, size: sw * 0.045),
                    SizedBox(width: sw * 0.02),
                    Expanded(child: Text('No further updates for ${widget.order.status} orders.', style: TextStyle(fontSize: sw * 0.032, color: _kAmber, fontWeight: FontWeight.w500))),
                  ]),
                )
              else if (_isPending) ...[
                _SelectionTile(sw: sw, title: 'Confirm Order', value: 'CONFIRMED', groupValue: _isCancelled ? null : _pendingSelection, activeColor: _kBlue, activeBg: _kBlueBg, onTap: () => setState(() => _pendingSelection = _pendingSelection == 'CONFIRMED' ? null : 'CONFIRMED')),
                SizedBox(height: sh * 0.01),
                _SelectionTile(sw: sw, title: 'Reject Order', value: 'REJECTED', groupValue: _isCancelled ? null : _pendingSelection, activeColor: _kAmber, activeBg: _kAmberBg, onTap: () => setState(() => _pendingSelection = _pendingSelection == 'REJECTED' ? null : 'REJECTED')),
              ]
              else if (_nextStatus != null)
                  _CheckboxTile(sw: sw, title: _nextLabel!, value: _isStatusChecked, disabled: _isCancelled, onChanged: (v) => setState(() => _isStatusChecked = v ?? false)),
              if (!_isTerminal && !_isPending) ...[
                SizedBox(height: sh * 0.015),
                _CheckboxTile(sw: sw, title: 'Cancel Order', value: _isCancelled, isCancel: true, onChanged: (v) => setState(() {
                  _isCancelled = v ?? false;
                  if (_isCancelled) { _isStatusChecked = false; _pendingSelection = null; }
                })),
              ],
              if (_isCancelled) ...[
                SizedBox(height: sh * 0.015),
                TextField(
                  onChanged: (v) => setState(() => _cancelReason = v),
                  maxLines: 2,
                  style: TextStyle(fontSize: sw * 0.034, color: _kDark),
                  decoration: InputDecoration(
                    hintText: 'Reason for cancellation *',
                    hintStyle: TextStyle(fontSize: sw * 0.032, color: _kMuted),
                    filled: true, fillColor: _kBg,
                    contentPadding: EdgeInsets.all(sw * 0.035),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBorder)),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(sw * 0.028),
                      borderSide: BorderSide(color: _triedSubmit && _cancelReason.trim().isEmpty ? _kRed : _kBorder, width: _triedSubmit && _cancelReason.trim().isEmpty ? 1.5 : 1),
                    ),
                    focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
                    errorText: _triedSubmit && _cancelReason.trim().isEmpty ? 'Reason is required' : null,
                  ),
                ),
              ],
            ]))),
            SizedBox(height: sh * 0.025),
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: sh * 0.015), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: _kBorder)),
                child: Text('Close', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w600, color: _kMuted)),
              )),
              if (!_isTerminal) ...[
                SizedBox(width: sw * 0.03),
                Expanded(flex: 2, child: ElevatedButton(
                  onPressed: _loading ? null : () async {
                    if (_isCancelled && _cancelReason.trim().isEmpty) { setState(() => _triedSubmit = true); return; }
                    if (!_canUpdate) return;
                    setState(() => _loading = true);
                    try {
                      await widget.onUpdate(_statusToSend, _isCancelled ? _cancelReason.trim() : null);
                      if (mounted) Navigator.pop(context);
                    } catch (e) {
                      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _kRed));
                    } finally { if (mounted) setState(() => _loading = false); }
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: _canUpdate ? btnColor : _kBorder, foregroundColor: Colors.white, disabledBackgroundColor: _kBorder, padding: EdgeInsets.symmetric(vertical: sh * 0.015), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                  child: _loading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(_isCancelled ? 'Cancel Order' : _pendingSelection == 'REJECTED' ? 'Reject' : 'Update', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w700)),
                )),
              ],
            ]),
          ]),
        ),
      ),
    );
  }
}

class _ItemStatusDialog extends StatefulWidget {
  final OrderDetailsModel item;
  final Future<void> Function(bool? production, bool? packing, String? status) onUpdate;
  const _ItemStatusDialog({required this.item, required this.onUpdate});

  @override
  State<_ItemStatusDialog> createState() => _ItemStatusDialogState();
}

class _ItemStatusDialogState extends State<_ItemStatusDialog> {
  bool _productionCompleted = false;
  bool _packingCompleted = false;
  bool _statusChecked = false;
  bool _loading = false;

  String? get _nextStatus {
    switch (widget.item.status) {
      case 'PACKED':  return 'INVOICE';
      case 'INVOICE': return 'SHIPPED';
      case 'SHIPPED': return 'DELIVERED';
      default: return null;
    }
  }

  bool get _canUpdate => _productionCompleted || _packingCompleted || _statusChecked;

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final item = widget.item;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw * 0.05)),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: Screen.h(context) * 0.75),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.05),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(padding: EdgeInsets.all(sw * 0.022), decoration: BoxDecoration(color: _kBlueBg, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.assignment_turned_in_rounded, color: _kBlue, size: sw * 0.055)),
              SizedBox(width: sw * 0.025),
              Text('Update Status', style: TextStyle(fontSize: sw * 0.042, fontWeight: FontWeight.w800, color: _kDark)),
            ]),
            SizedBox(height: sh * 0.02),
            Flexible(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: EdgeInsets.all(sw * 0.035),
                decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(item.productName, style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w700, color: _kDark)),
                  SizedBox(height: sw * 0.005),
                  Text('${item.productBrand} • ${item.productModel}', style: TextStyle(fontSize: sw * 0.03, color: _kMuted)),
                ]),
              ),
              SizedBox(height: sh * 0.02),
              if (item.hasProduction == true)
                _CheckboxTile(sw: sw, title: 'Production Completed', subtitle: 'Mark as production completed', value: _productionCompleted, onChanged: (v) => setState(() => _productionCompleted = v ?? false))
              else if (item.hasUnpacked != false)
                _CheckboxTile(sw: sw, title: 'Packing Completed', subtitle: 'Mark as packing completed', value: _packingCompleted, onChanged: (v) => setState(() => _packingCompleted = v ?? false))
              else if (item.hasUnpacked == false && item.hasProduction == false && _nextStatus != null)
                  _CheckboxTile(sw: sw, title: 'Mark as $_nextStatus', subtitle: 'Update to ${_nextStatus!.toLowerCase()}', value: _statusChecked, onChanged: (v) => setState(() => _statusChecked = v ?? false))
                else
                  Container(padding: EdgeInsets.all(sw * 0.035), decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12)), child: Text('No updates available', style: TextStyle(color: _kMuted, fontSize: sw * 0.032))),
            ]))),
            SizedBox(height: sh * 0.02),
            Row(children: [
              Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: sh * 0.015), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: _kBorder)), child: Text('Cancel', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w600, color: _kMuted)))),
              SizedBox(width: sw * 0.03),
              Expanded(flex: 2, child: ElevatedButton(
                onPressed: !_canUpdate || _loading ? null : () async {
                  setState(() => _loading = true);
                  try {
                    await widget.onUpdate(_productionCompleted ? true : null, _packingCompleted ? true : null, _statusChecked ? _nextStatus : null);
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _kRed));
                  } finally { if (mounted) setState(() => _loading = false); }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white, disabledBackgroundColor: _kBorder, padding: EdgeInsets.symmetric(vertical: sh * 0.015), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Update', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w700)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _CancelItemDialog extends StatefulWidget {
  final OrderDetailsModel item;
  final Future<void> Function(String reason) onConfirm;
  const _CancelItemDialog({required this.item, required this.onConfirm});

  @override
  State<_CancelItemDialog> createState() => _CancelItemDialogState();
}

class _CancelItemDialogState extends State<_CancelItemDialog> {
  final _reasonCtrl = TextEditingController();
  bool _triedSubmit = false;
  bool _loading = false;

  @override
  void dispose() { _reasonCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final isEmpty = _reasonCtrl.text.trim().isEmpty;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw * 0.05)),
      child: Padding(
        padding: EdgeInsets.all(sw * 0.05),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(padding: EdgeInsets.all(sw * 0.04), decoration: BoxDecoration(color: _kRedBg, shape: BoxShape.circle), child: Icon(Icons.cancel_outlined, color: _kRed, size: sw * 0.1)),
          SizedBox(height: sh * 0.02),
          Text('Cancel Item?', style: TextStyle(fontSize: sw * 0.048, fontWeight: FontWeight.w800, color: _kDark)),
          SizedBox(height: sh * 0.008),
          Text(widget.item.productName, style: TextStyle(fontSize: sw * 0.036, color: _kMid), textAlign: TextAlign.center),
          SizedBox(height: sh * 0.02),
          TextField(
            controller: _reasonCtrl,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: sw * 0.034, color: _kDark),
            decoration: InputDecoration(
              hintText: 'Reason for cancellation *',
              hintStyle: TextStyle(fontSize: sw * 0.032, color: _kMuted),
              filled: true, fillColor: _kBg,
              contentPadding: EdgeInsets.all(sw * 0.035),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBorder)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: BorderSide(color: _triedSubmit && isEmpty ? _kRed : _kBorder, width: _triedSubmit && isEmpty ? 1.5 : 1)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
              errorText: _triedSubmit && isEmpty ? 'Reason is required' : null,
            ),
          ),
          SizedBox(height: sh * 0.025),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: sh * 0.015), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: _kBorder)), child: Text('Keep', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w600, color: _kMuted)))),
            SizedBox(width: sw * 0.03),
            Expanded(child: ElevatedButton(
              onPressed: _loading ? null : () async {
                setState(() => _triedSubmit = true);
                if (isEmpty) return;
                setState(() => _loading = true);
                try {
                  await widget.onConfirm(_reasonCtrl.text.trim());
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _kRed));
                } finally { if (mounted) setState(() => _loading = false); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _kRed, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: sh * 0.015), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Yes, Cancel', style: TextStyle(fontSize: sw * 0.034, fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _CancelQtyDialog extends StatefulWidget {
  final OrderDetailsModel item;
  final int maxCancellable;
  final Future<void> Function(int qty, String? reason) onConfirm;
  const _CancelQtyDialog({required this.item, required this.maxCancellable, required this.onConfirm});

  @override
  State<_CancelQtyDialog> createState() => _CancelQtyDialogState();
}

class _CancelQtyDialogState extends State<_CancelQtyDialog> {
  final _qtyCtrl    = TextEditingController();
  final _reasonCtrl = TextEditingController();
  int? _qty;
  bool _loading = false;
  bool _triedSubmit = false;

  @override
  void dispose() { _qtyCtrl.dispose(); _reasonCtrl.dispose(); super.dispose(); }

  bool get _valid => _qty != null && _qty! > 0 && _qty! <= widget.maxCancellable;
  bool get _reasonValid => _reasonCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw * 0.05)),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(sw * 0.05),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // ── Header
            Row(children: [
              Container(padding: EdgeInsets.all(sw * 0.022), decoration: BoxDecoration(color: _kAmberBg, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.remove_circle_outline, color: _kAmber, size: sw * 0.055)),
              SizedBox(width: sw * 0.025),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Cancel Quantity', style: TextStyle(fontSize: sw * 0.042, fontWeight: FontWeight.w800, color: _kDark)),
                Text(widget.item.productName, style: TextStyle(fontSize: sw * 0.03, color: _kMuted), overflow: TextOverflow.ellipsis),
              ])),
            ]),
            SizedBox(height: sh * 0.02),

            // ── Qty summary cards
            Row(children: [
              Expanded(child: _QtyCard(sw: sw, label: 'Ordered', value: '${widget.item.qtyOrdered ?? 0}', color: _kBlue, bg: _kBlueBg, border: _kBlueBorder)),
              SizedBox(width: sw * 0.02),
              Expanded(child: _QtyCard(sw: sw, label: 'Delivered', value: '${widget.item.qtyDelivered ?? 0}', color: _kGreen, bg: _kGreenBg, border: _kGreenBorder)),
              SizedBox(width: sw * 0.02),
              Expanded(child: _QtyCard(sw: sw, label: 'Max Cancel', value: '${widget.maxCancellable}', color: _kAmber, bg: _kAmberBg, border: _kAmberBorder)),
            ]),
            SizedBox(height: sh * 0.02),

            // ── Qty input
            TextField(
              controller: _qtyCtrl,
              keyboardType: TextInputType.number,
              onChanged: (v) => setState(() => _qty = int.tryParse(v)),
              style: TextStyle(fontSize: sw * 0.036, color: _kDark),
              decoration: InputDecoration(
                hintText: 'Enter qty (Max: ${widget.maxCancellable})',
                hintStyle: TextStyle(fontSize: sw * 0.034, color: _kMuted),
                filled: true, fillColor: _kBg,
                contentPadding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
                suffixIcon: _qty != null ? Icon(_valid ? Icons.check_circle_outline : Icons.error_outline, color: _valid ? _kGreen : _kRed) : null,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: BorderSide(color: _qty != null && !_valid ? _kRed : _kBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
                errorText: _qty != null && _qty! > widget.maxCancellable
                    ? 'Cannot exceed ${widget.maxCancellable}'
                    : _qty != null && _qty! <= 0
                    ? 'Must be > 0'
                    : null,
              ),
            ),
            SizedBox(height: sh * 0.015),

            // ── Reason input (required)
            TextField(
              controller: _reasonCtrl,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
              style: TextStyle(fontSize: sw * 0.034, color: _kDark),
              decoration: InputDecoration(
                hintText: 'Reason for cancellation *',
                hintStyle: TextStyle(fontSize: sw * 0.032, color: _kMuted),
                filled: true, fillColor: _kBg,
                contentPadding: EdgeInsets.all(sw * 0.035),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(sw * 0.028),
                  borderSide: BorderSide(
                    color: _triedSubmit && !_reasonValid ? _kRed : _kBorder,
                    width: _triedSubmit && !_reasonValid ? 1.5 : 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(sw * 0.028), borderSide: const BorderSide(color: _kBlue, width: 1.5)),
                errorText: _triedSubmit && !_reasonValid ? 'Reason is required' : null,
              ),
            ),
            SizedBox(height: sh * 0.025),

            // ── Buttons
            Row(children: [
              Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: sh * 0.015), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: _kBorder)),
                child: Text('Close', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w600, color: _kMuted)),
              )),
              SizedBox(width: sw * 0.03),
              Expanded(child: ElevatedButton(
                onPressed: !_valid || _loading ? null : () async {
                  setState(() => _triedSubmit = true);
                  if (!_reasonValid) return;
                  setState(() => _loading = true);
                  try {
                    await widget.onConfirm(_qty!, _reasonCtrl.text.trim());
                    if (mounted) Navigator.pop(context);
                  } catch (e) {
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _kRed));
                  } finally { if (mounted) setState(() => _loading = false); }
                },
                style: ElevatedButton.styleFrom(backgroundColor: _kAmber, foregroundColor: Colors.white, disabledBackgroundColor: _kBorder, padding: EdgeInsets.symmetric(vertical: sh * 0.015), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
                child: _loading
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Confirm', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w700)),
              )),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _DeliveryDateDialog extends StatefulWidget {
  final OrderDetailsModel item;
  final Future<void> Function(DateTime date) onUpdate;
  const _DeliveryDateDialog({required this.item, required this.onUpdate});

  @override
  State<_DeliveryDateDialog> createState() => _DeliveryDateDialogState();
}

class _DeliveryDateDialogState extends State<_DeliveryDateDialog> {
  late DateTime _selectedDate;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.item.deliveryDate ?? DateTime.now();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(sw * 0.05)),
      child: Padding(
        padding: EdgeInsets.all(sw * 0.05),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(padding: EdgeInsets.all(sw * 0.022), decoration: BoxDecoration(color: _kBlueBg, borderRadius: BorderRadius.circular(10)), child: Icon(Icons.calendar_today_rounded, color: _kBlue, size: sw * 0.055)),
            SizedBox(width: sw * 0.025),
            Text('Update Delivery Date', style: TextStyle(fontSize: sw * 0.042, fontWeight: FontWeight.w800, color: _kDark)),
          ]),
          SizedBox(height: sh * 0.02),
          Container(
            padding: EdgeInsets.all(sw * 0.035),
            decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12), border: Border.all(color: _kBorder)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(widget.item.productName, style: TextStyle(fontSize: sw * 0.034, fontWeight: FontWeight.w700, color: _kDark)),
              Text('${widget.item.productBrand} • ${widget.item.productModel}', style: TextStyle(fontSize: sw * 0.028, color: _kMuted)),
            ]),
          ),
          SizedBox(height: sh * 0.02),
          GestureDetector(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime.now(),
                lastDate: DateTime.now().add(const Duration(days: 365)),
                builder: (ctx, child) => Theme(
                  data: Theme.of(ctx).copyWith(colorScheme: const ColorScheme.light(primary: _kBlue, onPrimary: Colors.white, surface: Colors.white, onSurface: _kDark), dialogTheme: const DialogThemeData(backgroundColor: Colors.white)),
                  child: child!,
                ),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
            child: Container(
              padding: EdgeInsets.all(sw * 0.04),
              decoration: BoxDecoration(color: _kBlueBg, borderRadius: BorderRadius.circular(sw * 0.028), border: Border.all(color: _kBlueBorder)),
              child: Row(children: [
                Icon(Icons.calendar_month_outlined, color: _kBlue, size: sw * 0.05),
                SizedBox(width: sw * 0.025),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Selected Date', style: TextStyle(fontSize: sw * 0.028, color: _kMuted, fontWeight: FontWeight.w500)),
                  Text(DateFormat('dd MMM yyyy').format(_selectedDate), style: TextStyle(fontSize: sw * 0.038, fontWeight: FontWeight.w800, color: _kBlue)),
                ])),
                Icon(Icons.arrow_forward_ios_rounded, size: sw * 0.035, color: _kMuted),
              ]),
            ),
          ),
          SizedBox(height: sh * 0.025),
          Row(children: [
            Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: EdgeInsets.symmetric(vertical: sh * 0.015), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), side: const BorderSide(color: _kBorder)), child: Text('Cancel', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w600, color: _kMuted)))),
            SizedBox(width: sw * 0.03),
            Expanded(flex: 2, child: ElevatedButton(
              onPressed: _loading ? null : () async {
                setState(() => _loading = true);
                try {
                  await widget.onUpdate(_selectedDate);
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e'), backgroundColor: _kRed));
                } finally { if (mounted) setState(() => _loading = false); }
              },
              style: ElevatedButton.styleFrom(backgroundColor: _kBlue, foregroundColor: Colors.white, padding: EdgeInsets.symmetric(vertical: sh * 0.015), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: _loading ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Update', style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w700)),
            )),
          ]),
        ]),
      ),
    );
  }
}

class _QtyCard extends StatelessWidget {
  final double sw;
  final String label, value;
  final Color color, bg, border;
  const _QtyCard({required this.sw, required this.label, required this.value, required this.color, required this.bg, required this.border});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: sw * 0.025),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10), border: Border.all(color: border)),
    child: Column(children: [
      Text(value, style: TextStyle(fontSize: sw * 0.042, fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(fontSize: sw * 0.026, color: color, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _CheckboxTile extends StatelessWidget {
  final double sw;
  final String title;
  final String? subtitle;
  final bool value, disabled, isCancel;
  final ValueChanged<bool?> onChanged;

  const _CheckboxTile({
    required this.sw,
    required this.title,
    this.subtitle,
    required this.value,
    this.disabled = false,
    this.isCancel = false,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final activeColor  = isCancel ? _kRed : _kBlue;
    final activeBg     = isCancel ? _kRedBg : _kBlueBg;
    final activeBorder = isCancel ? _kRedBorder : _kBlueBorder;
    return Container(
      decoration: BoxDecoration(
        color: value ? activeBg : _kBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: value ? activeBorder : _kBorder, width: value ? 1.5 : 1),
      ),
      child: CheckboxListTile(
        value: value,
        onChanged: disabled ? null : onChanged,
        title: Text(title, style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w600, color: disabled ? _kMuted : (isCancel && value ? _kRed : _kDark))),
        subtitle: subtitle != null ? Text(subtitle!, style: TextStyle(fontSize: sw * 0.028, color: _kMuted)) : null,
        activeColor: activeColor,
        checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sw * 0.005),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final double sw;
  final String title, value;
  final String? groupValue;
  final Color activeColor, activeBg;
  final VoidCallback onTap;

  const _SelectionTile({
    required this.sw,
    required this.title,
    required this.value,
    required this.groupValue,
    required this.activeColor,
    required this.activeBg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = groupValue == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        decoration: BoxDecoration(
          color: isSelected ? activeBg.withValues(alpha: 0.5) : _kBg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? activeColor : _kBorder, width: isSelected ? 1.5 : 1),
        ),
        child: ListTile(
          leading: Container(
            width: sw * 0.06, height: sw * 0.06,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? activeColor : _kMuted, width: 2), color: isSelected ? activeColor : Colors.transparent),
            child: isSelected ? Icon(Icons.check, size: sw * 0.035, color: Colors.white) : null,
          ),
          title: Text(title, style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w600, color: isSelected ? activeColor : _kDark)),
          contentPadding: EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sw * 0.005),
          dense: true,
        ),
      ),
    );
  }
}