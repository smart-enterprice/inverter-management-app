import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import '../../../widgets/circle_button.dart';
import '../../signup/controller/signUp_controller.dart';
import 'order_payment_history.dart';
import '../controller/order_controller.dart';
import '../../../model/order_model.dart';

// ── Design tokens (Zoho Books) ────────────────────────────────────────────────
const _kP        = Color(0xFF185FA5); // primary blue
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Colors.white;
const _kBd       = Color(0xFFE5E7EB);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
const _kT3       = Color(0xFF6B7280);
const _kT4       = Color(0xFF9CA3AF);
const _kGreen    = Color(0xFF0F6E56);
const _kGreenBg  = Color(0xFFEDFAF5);
const _kGreenBd  = Color(0xFF9FE0C5);
const _kRed      = Color(0xFFDC2626);
const _kRedBg    = Color(0xFFFEF2F2);
const _kRedBd    = Color(0xFFFECACA);
const _kAmber    = Color(0xFFB45309);
const _kAmberBg  = Color(0xFFFFFBEB);
const _kAmberBd  = Color(0xFFFCD28A);
const _kPurple   = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBd = Color(0xFFDDD6FE);

// ── Status style ──────────────────────────────────────────────────────────────
class _SS {
  final Color fg, bg, bd;
  final IconData icon;
  const _SS(this.fg, this.bg, this.bd, this.icon);
}

_SS _ss(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':    return const _SS(_kAmber,  _kAmberBg,  _kAmberBd,  Icons.pending_actions_rounded);
    case 'CONFIRMED':  return const _SS(_kP,      _kPBg,      _kPBd,      Icons.verified_rounded);
    case 'PRODUCTION': return const _SS(Color(0xFFEA580C), Color(0xFFFFF7ED), Color(0xFFFED7AA), Icons.precision_manufacturing_rounded);
    case 'PACKED':     return const _SS(_kP,      _kPBg,      _kPBd,      Icons.inventory_2_outlined);
    case 'INVOICE':    return const _SS(_kPurple, _kPurpleBg, _kPurpleBd, Icons.receipt_long_rounded);
    case 'SHIPPED':    return const _SS(Color(0xFF4338CA), Color(0xFFEEF2FF), Color(0xFFC7D2FE), Icons.local_shipping_outlined);
    case 'DELIVERED':  return const _SS(_kGreen,  _kGreenBg,  _kGreenBd,  Icons.check_circle_outline_rounded);
    case 'COMPLETED':  return const _SS(_kGreen,  _kGreenBg,  _kGreenBd,  Icons.task_alt_rounded);
    case 'CANCELLED':  return const _SS(_kRed,    _kRedBg,    _kRedBd,    Icons.cancel_outlined);
    case 'REJECTED':   return const _SS(Color(0xFFEA580C), Color(0xFFFFF7ED), Color(0xFFFED7AA), Icons.block_rounded);
    default:           return const _SS(_kT3,     _kBg,       _kBd,       Icons.info_outline_rounded);
  }
}

final _dealerExpandedProvider = StateProvider<bool>((ref) => false);

String _fmt(num? n) => n == null ? '0' : NumberFormat('#,##,###').format(n);
String _fmtDate(DateTime? d) =>
    d == null ? 'N/A' : DateFormat('dd MMM yyyy • hh:mm a').format(d);

Color _priColor(String p) {
  switch (p.toUpperCase()) {
    case 'HIGH':   return _kRed;
    case 'MEDIUM': return _kAmber;
    default:       return _kGreen;
  }
}

Color _paymentColor(String? s) {
  switch (s?.toLowerCase()) {
    case 'paid':    return _kGreen;
    case 'pending': return _kAmber;
    case 'failed':  return _kRed;
    default:        return _kT4;
  }
}

// ── Delivery note parser ──────────────────────────────────────────────────────
// API format: "Employee: X | Role: ROLE_Y | Note: Z | Date: OLD → NEW"
class _DeliveryNoteData {
  final String employee;
  final String role;
  final String note;
  final String fromDate;
  final String toDate;

  const _DeliveryNoteData({
    required this.employee,
    required this.role,
    required this.note,
    required this.fromDate,
    required this.toDate,
  });
}

_DeliveryNoteData? _parseDeliveryNote(String raw) {
  try {
    // Split by " | "
    final parts = raw.split(' | ');
    if (parts.length < 4) return null;

    final employee = parts[0].replaceFirst('Employee: ', '').trim();
    final role = parts[1].replaceFirst('Role: ', '')
        .replaceAll('ROLE_', '').replaceAll('_', ' ').trim();
    final note = parts[2].replaceFirst('Note: ', '').trim();

    // Date part: "Date: OLD → NEW"  (arrow may be → or ->)
    final datePart = parts[3].replaceFirst('Date: ', '').trim();
    final arrow = datePart.contains('→') ? '→' : '->';
    final dates = datePart.split(arrow);

    String shortDate(String raw) {
      try {
        final d = DateTime.parse(raw.trim());
        return '${d.day} ${['Jan','Feb','Mar','Apr','May','Jun',
          'Jul','Aug','Sep','Oct','Nov','Dec'][d.month - 1]} ${d.year}';
      } catch (_) {
        // Try parsing the long browser format e.g. "Fri Apr 24 2026 02:00:00 GMT+0200..."
        final match = RegExp(r'(\w+) (\w+) (\d+) (\d{4})').firstMatch(raw.trim());
        if (match != null) return '${match.group(3)} ${match.group(2)} ${match.group(4)}';
        return raw.trim().substring(0, raw.trim().length.clamp(0, 15));
      }
    }

    final from = dates.isNotEmpty ? shortDate(dates[0]) : '';
    final to   = dates.length > 1  ? shortDate(dates[1]) : '';

    return _DeliveryNoteData(
      employee: employee,
      role: role,
      note: note,
      fromDate: from,
      toDate: to,
    );
  } catch (_) {
    return null;
  }
}



// ─────────────────────────────────────────────────────────────────────────────
// OrderViewPage
// ─────────────────────────────────────────────────────────────────────────────
class OrderViewPage extends ConsumerStatefulWidget {
  final String orderNumber;
  const OrderViewPage({super.key, required this.orderNumber});
  @override
  ConsumerState<OrderViewPage> createState() => _OrderViewPageState();
}

class _OrderViewPageState extends ConsumerState<OrderViewPage> {

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final orderAsync = ref.watch(orderByIdProvider(widget.orderNumber));

    return orderAsync.when(
      loading: () => const Scaffold(backgroundColor: _kBg,
          body: Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5))),
      error: (_, __) => _buildError(context, sw, sh),
      data: (order) {
        if (order == null) return _buildError(context, sw, sh);
        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(child: Column(children: [
            // ── App bar ──────────────────────────────────────────────────
            _AppBar(
              sw: sw, sh: sh,
              orderNumber: order.orderNumber ?? '',
              status: order.status ?? '',
              onBack: () => Navigator.pop(context),
              onStatusTap: () => _showOrderStatusDialog(context, order),
            ),
            // ── Body ─────────────────────────────────────────────────────
            Expanded(child: RefreshIndicator(
              color: _kP,
              backgroundColor: _kWhite,
              onRefresh: () async =>
                  ref.invalidate(orderByIdProvider(widget.orderNumber)),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    sw * 0.038, sh * 0.01, sw * 0.038, sh * 0.04),
                child: Column(children: [
                  _buildSummary(context, sw, sh, order),
                  SizedBox(height: sh * 0.012),
                  if (order.dealer != null)
                    RoleGuard(
                      feature: AppFeature.viewDealers,
                      child: Column(children: [
                        _buildDealer(context, sw, sh, order.dealer!),
                        SizedBox(height: sh * 0.012),
                      ]),
                    ),
                  _buildItems(context, sw, sh, order),
                  SizedBox(height: sh * 0.012),
                  RoleGuard(
                    feature: AppFeature.viewPrice,
                    child: Column(children: [
                      _buildPrice(context, sw, sh, order),
                      SizedBox(height: sh * 0.012),
                    ]),
                  ),
                  RoleGuard(
                    feature: AppFeature.paymentView,
                    child: _buildPayment(context, sw, sh, order),
                  ),
                  if (order.orderNote.isNotEmpty) ...[
                    SizedBox(height: sh * 0.012),
                    _buildNotes(sw, sh, order),
                  ],
                ]),
              ),
            )),
          ])),
        );
      },
    );
  }

  // ── Summary ───────────────────────────────────────────────────────────────
  Widget _buildSummary(BuildContext context, double sw, double sh, OrderModel o) {
    final salesmanAsync = ref.watch(employeeByIdProvider(o.salesmanId));
    return _Card(
      sw: sw, sh: sh,
      icon: Icons.receipt_long_rounded,
      iconBg: _kPBg, iconColor: _kP,
      title: 'Order Summary',
      child: Column(children: [
        _InfoRow(sw: sw, sh: sh, label: 'Salesman', icon: Icons.person_outline_rounded,
            value: salesmanAsync.when(
                data: (u) => u?.employeeName ?? 'N/A',
                loading: () => 'Loading...', error: (_, __) => 'N/A')),
        _InfoRow(sw: sw, sh: sh, label: 'Priority', icon: Icons.flag_outlined,
            value: o.priority, valueColor: _priColor(o.priority)),
        RoleGuard(
            feature: AppFeature.viewPrice,
            child: _InfoRow(sw: sw, sh: sh, label: 'Payment',
                icon: Icons.payment_rounded, value: o.paymentType)),
        _InfoRow(sw: sw, sh: sh, label: 'Created', icon: Icons.calendar_today_outlined,
            value: _fmtDate(o.createdAt),
            isLast: (o.totalCancelledQty ?? 0) <= 0),
        if ((o.totalCancelledQty ?? 0) > 0)
          _InfoRow(sw: sw, sh: sh, label: 'Cancelled',
              icon: Icons.cancel_outlined,
              value: o.totalCancelledQty.toString(),
              valueColor: _kRed, isLast: true),
      ]),
    );
  }

  // ── Dealer ────────────────────────────────────────────────────────────────
  Widget _buildDealer(BuildContext context, double sw, double sh, DealerModel dealer) {
    return Consumer(builder: (_, ref, __) {
      final expanded = ref.watch(_dealerExpandedProvider);
      return Container(
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
          border: Border.all(color: _kBd, width: 0.5),
        ),
        child: Column(children: [
          GestureDetector(
            onTap: () => ref.read(_dealerExpandedProvider.notifier).state = !expanded,
            child: Padding(
              padding: EdgeInsets.all(sw * 0.04),
              child: Row(children: [
                CircleAvatar(
                  radius: (sw * 0.055).clamp(20.0, 32.0),
                  backgroundColor: _kPBg,
                  backgroundImage: dealer.photo.isNotEmpty
                      ? NetworkImage(dealer.photo) : null,
                  child: dealer.photo.isEmpty
                      ? Text(dealer.employeeName[0].toUpperCase(),
                      style: TextStyle(
                          fontSize: (sw * 0.04).clamp(14.0, 20.0),
                          fontWeight: FontWeight.w700, color: _kP))
                      : null,
                ),
                SizedBox(width: sw * 0.03),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(dealer.employeeName, style: TextStyle(
                        fontSize: (sw * 0.036).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w700, color: _kT1)),
                    Text('Dealer Information', style: TextStyle(
                        fontSize: (sw * 0.028).clamp(9.5, 12.5),
                        color: _kT4)),
                  ],
                )),
                AnimatedRotation(
                  turns: expanded ? 0.25 : 0,
                  duration: const Duration(milliseconds: 220),
                  child: Icon(Icons.arrow_forward_ios_rounded,
                      size: (sw * 0.035).clamp(12.0, 16.0), color: _kT4),
                ),
              ]),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            child: expanded ? Column(children: [
              Divider(height: 1, color: _kBd),
              Padding(
                padding: EdgeInsets.fromLTRB(
                    sw * 0.04, sw * 0.03, sw * 0.04, sw * 0.04),
                child: Column(children: [
                  _InfoRow(sw: sw, sh: sh, label: 'Shop',
                      icon: Icons.storefront_outlined, value: dealer.shopName),
                  _InfoRow(sw: sw, sh: sh, label: 'Phone',
                      icon: Icons.phone_outlined,
                      value: dealer.employeePhone.toString()),
                  _InfoRow(sw: sw, sh: sh, label: 'Email',
                      icon: Icons.email_outlined, value: dealer.employeeEmail),
                  _InfoRow(sw: sw, sh: sh, label: 'Location',
                      icon: Icons.location_on_outlined,
                      value: '${dealer.town}, ${dealer.district}',
                      isLast: true),
                ]),
              ),
            ]) : const SizedBox.shrink(),
          ),
        ]),
      );
    });
  }

  // ── Items ─────────────────────────────────────────────────────────────────
  Widget _buildItems(BuildContext context, double sw, double sh, OrderModel o) {
    final cardR = (sw * 0.04).clamp(10.0, 18.0);
    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(cardR),
        border: Border.all(color: _kBd, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.035),
          child: Row(children: [
            _IconBox(sw: sw, icon: Icons.shopping_cart_outlined,
                bg: _kPurpleBg, color: _kPurple),
            SizedBox(width: sw * 0.025),
            Expanded(child: Text('Order Items', style: TextStyle(
                fontSize: (sw * 0.035).clamp(12.0, 16.0),
                fontWeight: FontWeight.w700, color: _kT1))),
            _Pill(sw: sw, label: '${o.orderDetails.length}',
                fg: _kPurple, bg: _kPurpleBg, bd: _kPurpleBd),
          ]),
        ),
        Divider(height: 1, color: _kBd),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: o.orderDetails.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: _kBd),
          itemBuilder: (_, i) =>
              _buildItemRow(context, sw, sh, o.orderDetails[i], i, o),
        ),
      ]),
    );
  }

  Widget _buildItemRow(BuildContext context, double sw, double sh,
      OrderDetailsModel item, int index, OrderModel order) {
    String subLabel(OrderDetailsModel item) {
      if (item.hasProduction == true) return 'In Production';
      if (item.hasUnpacked == true)   return 'Awaiting Packing';
      return 'Ready to Ship';
    }

    final isCancelled = item.status == 'CANCELLED';
    final isCompleted = item.status == 'COMPLETED' || item.status == 'DELIVERED';
    final maxCancellable = (item.qtyOrdered ?? 0) - (item.qtyDelivered ?? 0);
    final st = _ss(item.status ?? '');
    final hasCancelHistory =
        item.cancellationHistory != null && item.cancellationHistory!.isNotEmpty;

    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      color: isCancelled ? _kRedBg : Colors.transparent,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header row
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Index badge
          Container(
            width: (sw * 0.08).clamp(28.0, 40.0),
            height: (sw * 0.08).clamp(28.0, 40.0),
            decoration: BoxDecoration(
              color: isCancelled ? _kRedBg : _kPBg,
              borderRadius: BorderRadius.circular((sw * 0.022).clamp(6.0, 10.0)),
              border: Border.all(
                  color: isCancelled ? _kRedBd : _kPBd, width: 0.5),
            ),
            child: Center(child: Text('${index + 1}', style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0),
                fontWeight: FontWeight.w800,
                color: isCancelled ? _kRed : _kP))),
          ),
          SizedBox(width: sw * 0.025),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(item.productName, style: TextStyle(
                    fontSize: (sw * 0.036).clamp(12.0, 16.0),
                    fontWeight: FontWeight.w700, color: _kT1))),
                if (item.isFree == true)
                  RoleGuard(
                    feature: AppFeature.viewPrice,
                    child: _Pill(sw: sw, label: 'FREE',
                        fg: _kGreen, bg: _kGreenBg, bd: _kGreenBd),
                  ),
              ]),
              SizedBox(height: sw * 0.005),
              Text('${item.productBrand} • ${item.productModel}',
                  style: TextStyle(
                      fontSize: (sw * 0.029).clamp(10.0, 13.0), color: _kT4)),
            ],
          )),
          RoleGuard(
            feature: AppFeature.viewPrice,
            child: Text(
                item.totalProductPrice != null
                    ? '₹${_fmt(item.totalProductPrice)}'
                    : '₹${_fmt(item.productPrice)}',
                style: TextStyle(
                    fontSize: (sw * 0.036).clamp(12.0, 16.0),
                    fontWeight: FontWeight.w800, color: _kT1)),
          ),
        ]),
        SizedBox(height: sw * 0.025),

        // Status chips
        Wrap(spacing: sw * 0.02, runSpacing: sw * 0.015, children: [
          _Pill(sw: sw, label: item.status ?? 'N/A',
              fg: st.fg, bg: st.bg, bd: st.bd),
          if (item.status == 'PRODUCTION' ||
              (item.status == 'PACKED' &&
                  item.hasProduction == false &&
                  item.hasUnpacked == false))
            _Pill(sw: sw, label: subLabel(item),
                fg: _kAmber, bg: _kAmberBg, bd: _kAmberBd),
          _Pill(sw: sw, label: 'Ordered: ${item.qtyOrdered ?? 0}',
              fg: _kP, bg: _kPBg, bd: _kPBd),
          _Pill(sw: sw, label: 'Delivered: ${item.qtyDelivered ?? 0}',
              fg: _kGreen, bg: _kGreenBg, bd: _kGreenBd),
          if ((item.totalCancelledQty ?? 0) > 0)
            _Pill(sw: sw, label: 'Cancelled: ${item.totalCancelledQty}',
                fg: _kRed, bg: _kRedBg, bd: _kRedBd),
        ]),

        // Notes
        if (item.notes != null && item.notes!.isNotEmpty) ...[
          SizedBox(height: sw * 0.015),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(sw * 0.03),
            decoration: BoxDecoration(
              color: _kAmberBg,
              borderRadius: BorderRadius.circular((sw * 0.022).clamp(6.0, 10.0)),
              border: Border.all(color: _kAmberBd, width: 0.5),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline_rounded,
                  size: (sw * 0.032).clamp(11.0, 15.0), color: _kAmber),
              SizedBox(width: sw * 0.015),
              Expanded(child: Text(item.notes!, style: TextStyle(
                  fontSize: (sw * 0.029).clamp(10.0, 13.0),
                  color: _kAmber, height: 1.4))),
            ]),
          ),
        ],

        // Dealer discount
        if ((item.dealerDiscountAmount ?? 0) > 0) ...[
          SizedBox(height: sw * 0.015),
          Row(children: [
            Icon(Icons.discount_outlined,
                size: (sw * 0.035).clamp(12.0, 16.0), color: _kGreen),
            SizedBox(width: sw * 0.01),
            Text('Dealer discount: -₹${_fmt(item.dealerDiscountAmount)}',
                style: TextStyle(
                    fontSize: (sw * 0.03).clamp(10.0, 13.0),
                    color: _kGreen, fontWeight: FontWeight.w600)),
          ]),
        ],

        // Delivery date + notes
        if (item.deliveryDate != null) ...[
          SizedBox(height: sw * 0.015),
          GestureDetector(
            onTap: isCancelled || isCompleted ? null
                : () => _showDeliveryDateDialog(context, item, index, order),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Text('Delivery  ', style: TextStyle(
                  fontSize: (sw * 0.031).clamp(10.5, 14.0),
                  color: _kT4)),
              Icon(Icons.local_shipping_outlined,
                  size: (sw * 0.035).clamp(12.0, 16.0), color: _kT4),
              SizedBox(width: sw * 0.01),
              Text(DateFormat('dd MMM yyyy').format(item.deliveryDate!),
                  style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0),
                      color: _kT2, fontWeight: FontWeight.w600)),
              if (!isCancelled && !isCompleted) ...[
                SizedBox(width: sw * 0.015),
                Icon(Icons.edit_outlined,
                    size: (sw * 0.032).clamp(11.0, 14.0), color: _kP),
              ],
            ]),
          ),
          // Delivery notes history
          if (item.deliveryNotes.isNotEmpty) ...[
            SizedBox(height: sw * 0.015),
            _DeliveryNotesHistory(sw: sw, notes: item.deliveryNotes),
          ],
        ],

        // Cancellation history
        if (hasCancelHistory) ...[
          SizedBox(height: sw * 0.025),
          _buildCancelHistory(sw, sh, item.cancellationHistory!),
        ],

        // Action buttons
        if (!isCancelled && !isCompleted) ...[
          SizedBox(height: sw * 0.025),
          Divider(height: 1, color: _kBd),
          SizedBox(height: sw * 0.02),
          Row(children: [
            if ((order.status ?? '').toUpperCase() != 'PENDING') ...[
              Expanded(child: RoleGuard(
                feature: AppFeature.updateOrderStatus,
                child: _ActionBtn(sw: sw, label: 'Update',
                    icon: Icons.update_rounded, color: _kP,
                    onTap: () => _showItemStatusDialog(context, item, index, order)),
              )),
              SizedBox(width: sw * 0.02),
            ],
            if (maxCancellable > 0) ...[
              Expanded(child: RoleGuard(
                feature: AppFeature.cancelOrder,
                child: _ActionBtn(sw: sw, label: 'Cancel Qty',
                    icon: Icons.remove_circle_outline, color: _kAmber,
                    onTap: () => _showCancelQtyDialog(context, item, order, maxCancellable)),
              )),
              SizedBox(width: sw * 0.02),
            ],
            Expanded(child: RoleGuard(
              feature: AppFeature.cancelOrder,
              child: _ActionBtn(sw: sw, label: 'Cancel',
                  icon: Icons.cancel_outlined, color: _kRed,
                  onTap: () => _showCancelItemDialog(context, item, order)),
            )),
          ]),
        ],
      ]),
    );
  }

  Widget _buildCancelHistory(double sw, double sh,
      List<CancellationHistoryModel> history) {
    return Container(
      decoration: BoxDecoration(
        color: _kRedBg,
        borderRadius: BorderRadius.circular((sw * 0.03).clamp(8.0, 14.0)),
        border: Border.all(color: _kRedBd, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.035, vertical: sw * 0.025),
          child: Row(children: [
            _IconBox(sw: sw, icon: Icons.history_rounded,
                bg: _kRedBd, color: _kRed, small: true),
            SizedBox(width: sw * 0.02),
            Text('Cancellation History', style: TextStyle(
                fontSize: (sw * 0.031).clamp(10.5, 14.0),
                fontWeight: FontWeight.w700, color: _kRed)),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.02, vertical: sw * 0.006),
              decoration: BoxDecoration(
                color: _kRed.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${history.length}', style: TextStyle(
                  fontSize: (sw * 0.025).clamp(9.0, 11.0),
                  fontWeight: FontWeight.w800, color: _kRed)),
            ),
          ]),
        ),
        Divider(height: 1, color: _kRedBd),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: history.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: _kRedBd),
          itemBuilder: (_, i) => _buildCancelHistoryRow(
              sw, history[i], i, history.length),
        ),
      ]),
    );
  }

  Widget _buildCancelHistoryRow(double sw, CancellationHistoryModel entry,
      int index, int total) {
    final isLast = index == total - 1;
    return Padding(
      padding: EdgeInsets.fromLTRB(sw * 0.035, sw * 0.025, sw * 0.035,
          isLast ? sw * 0.025 : sw * 0.02),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Column(children: [
          Container(
            width: (sw * 0.055).clamp(20.0, 28.0),
            height: (sw * 0.055).clamp(20.0, 28.0),
            decoration: BoxDecoration(
                color: _kRedBg, shape: BoxShape.circle,
                border: Border.all(color: _kRedBd, width: 1.5)),
            child: Center(child: Text('${index + 1}', style: TextStyle(
                fontSize: (sw * 0.022).clamp(8.0, 10.0),
                fontWeight: FontWeight.w800, color: _kRed))),
          ),
          if (!isLast)
            Container(width: 1.5, height: sw * 0.06, color: _kRedBd),
        ]),
        SizedBox(width: sw * 0.025),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.022, vertical: sw * 0.007),
                decoration: BoxDecoration(
                    color: _kRed,
                    borderRadius: BorderRadius.circular(20)),
                child: Text('-${entry.cancelledQty} unit${entry.cancelledQty > 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: (sw * 0.026).clamp(9.0, 11.5),
                        fontWeight: FontWeight.w800, color: Colors.white)),
              ),
              SizedBox(width: sw * 0.015),
              Flexible(child: _Pill(sw: sw,
                  label: entry.cancelledByRole
                      .replaceAll('ROLE_', '').replaceAll('_', ' '),
                  fg: _kAmber, bg: _kAmberBg, bd: _kAmberBd)),
            ]),
            SizedBox(height: sw * 0.012),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.notes_rounded,
                  size: (sw * 0.03).clamp(10.0, 13.0), color: _kT4),
              SizedBox(width: sw * 0.01),
              Expanded(child: Text(
                  entry.reason.isEmpty || entry.reason == 'Not provided'
                      ? 'No reason provided' : entry.reason,
                  style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0),
                      color: entry.reason.isEmpty ? _kT4 : _kT2,
                      fontStyle: entry.reason.isEmpty
                          ? FontStyle.italic : FontStyle.normal))),
            ]),
            if (entry.cancelledAt != null) ...[
              SizedBox(height: sw * 0.008),
              Row(children: [
                Icon(Icons.access_time_rounded,
                    size: (sw * 0.028).clamp(9.0, 12.0), color: _kT4),
                SizedBox(width: sw * 0.008),
                Text(DateFormat('dd MMM yyyy • hh:mm a')
                    .format(entry.cancelledAt!),
                    style: TextStyle(
                        fontSize: (sw * 0.026).clamp(9.0, 11.5),
                        color: _kT4)),
              ]),
            ],
          ],
        )),
      ]),
    );
  }

  // ── Price ─────────────────────────────────────────────────────────────────
  Widget _buildPrice(BuildContext context, double sw, double sh, OrderModel o) {
    return _Card(
      sw: sw, sh: sh,
      icon: Icons.calculate_outlined,
      iconBg: _kGreenBg, iconColor: _kGreen,
      title: 'Price Breakdown',
      child: Column(children: [
        if (o.orderTotalPrice != null)
          _PriceRow(sw: sw, label: 'Subtotal', amount: o.orderTotalPrice!),
        if ((o.orderTotalDiscount ?? 0) > 0)
          _PriceRow(sw: sw, label: 'Discount',
              amount: o.orderTotalDiscount!, isDiscount: true),
        if ((o.totalDealerDiscount ?? 0) > 0)
          _PriceRow(sw: sw, label: 'Dealer Discount',
              amount: o.totalDealerDiscount!, isDiscount: true),
        Divider(height: 16, color: _kBd),
        _PriceRow(sw: sw, label: 'Total',
            amount: o.totalPrice ?? o.orderTotalPrice ?? 0, isTotal: true),
      ]),
    );
  }

  // ── Payment ───────────────────────────────────────────────────────────────
  Widget _buildPayment(BuildContext context, double sw, double sh, OrderModel o) {
    return _Card(
      sw: sw, sh: sh,
      icon: Icons.account_balance_wallet_outlined,
      iconBg: _kGreenBg, iconColor: _kGreen,
      title: 'Payment',
      trailing: Row(mainAxisSize: MainAxisSize.min, children: [
        if (o.paymentNotes != null && o.paymentNotes!.isNotEmpty) ...[
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
                builder: (_) => PaymentHistoryPage(order: o))),
            child: _Pill(sw: sw, label: 'History',
                fg: _kGreen, bg: _kGreenBg, bd: _kGreenBd),
          ),
          SizedBox(width: sw * 0.02),
        ],
        RoleGuard(
          feature: AppFeature.updatePayment,
          child: GestureDetector(
            onTap: () => _showPaymentUpdateSheet(context, o),
            child: _Pill(sw: sw, label: 'Update',
                fg: _kP, bg: _kPBg, bd: _kPBd),
          ),
        ),
      ]),
      child: Column(children: [
        _InfoRow(sw: sw, sh: sh, label: 'Status',
            icon: Icons.info_outline_rounded,
            value: o.paymentStatus ?? 'N/A',
            valueColor: _paymentColor(o.paymentStatus)),
        _InfoRow(sw: sw, sh: sh, label: 'Paid',
            icon: Icons.payments_outlined,
            value: '₹${_fmt(o.amountPaid)}', valueColor: _kGreen),
        if (o.amountDue != null)
          _InfoRow(sw: sw, sh: sh, label: 'Due',
              icon: Icons.money_off_rounded,
              value: '₹${_fmt(o.amountDue)}',
              valueColor: _kRed, isLast: true),
      ]),
    );
  }

  // ── Notes ─────────────────────────────────────────────────────────────────
  Widget _buildNotes(double sw, double sh, OrderModel o) {
    return _Card(
      sw: sw, sh: sh,
      icon: Icons.note_alt_outlined,
      iconBg: _kAmberBg, iconColor: _kAmber,
      title: 'Order Notes',
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.all(sw * 0.035),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular((sw * 0.025).clamp(6.0, 12.0)),
          border: Border.all(color: _kBd, width: 0.5),
        ),
        child: Text(o.orderNote, style: TextStyle(
            fontSize: (sw * 0.033).clamp(11.0, 14.5),
            color: _kT2, height: 1.5)),
      ),
    );
  }

  // ── Error ─────────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, double sw, double sh) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        _AppBar(sw: sw, sh: sh, orderNumber: '',
            status: '', onBack: () => Navigator.pop(context)),
        Expanded(child: Center(child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: (sw * 0.18).clamp(60.0, 90.0),
              height: (sw * 0.18).clamp(60.0, 90.0),
              decoration: BoxDecoration(
                  color: _kWhite, shape: BoxShape.circle,
                  border: Border.all(color: _kBd, width: 0.5)),
              child: Icon(Icons.wifi_off_rounded,
                  size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
            ),
            SizedBox(height: sh * 0.02),
            Text('No Connection', style: TextStyle(
                fontSize: (sw * 0.04).clamp(13.0, 18.0),
                fontWeight: FontWeight.w600, color: _kT2)),
            SizedBox(height: sh * 0.02),
            ElevatedButton(
              onPressed: () =>
                  ref.invalidate(orderByIdProvider(widget.orderNumber)),
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kP, foregroundColor: Colors.white,
                  shape: const CircleBorder(), padding: const EdgeInsets.all(14),
                  elevation: 0),
              child: const Icon(Icons.refresh_rounded),
            ),
          ],
        ))),
      ])),
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────
  void _showPaymentUpdateSheet(BuildContext context, OrderModel order) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => _PaymentUpdateSheet(
        order: order,
        onUpdate: (amount, type) async {
          await ref.read(orderControllerProvider.notifier).updatePaymentOrder(
              order.copyWith(amountPaid: amount, paymentType: type));
          ref.invalidate(orderByIdProvider(order.orderNumber!));
          if (mounted) _snack('Payment updated', _kGreen);
        },
      ),
    );
  }

  void _showOrderStatusDialog(BuildContext context, OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => _OrderStatusDialog(
        order: order,
        onUpdate: (status, reason) async {
          await ref.read(orderControllerProvider.notifier)
              .updateOrder(order.copyWith(
              status: status, reasonForCancellation: reason));
          ref.invalidate(orderByIdProvider(order.orderNumber!));
          if (mounted) _snack(_successMsg(status), _kGreen);
        },
      ),
    );
  }

  void _showItemStatusDialog(BuildContext context, OrderDetailsModel item,
      int index, OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => _ItemStatusDialog(
        item: item,
        onUpdate: (production, packing, status) async {
          await _updateItemStatus(item: item,
              productionCompleted: production,
              packingCompleted: packing, status: status);
          ref.invalidate(orderByIdProvider(order.orderNumber!));
          if (mounted) _snack('Status updated', _kGreen);
        },
      ),
    );
  }

  void _showCancelItemDialog(BuildContext context, OrderDetailsModel item,
      OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => _CancelItemDialog(
        item: item,
        onConfirm: (reason) async {
          await _updateItemStatus(
              item: item, status: 'CANCELLED', reasonForCancellation: reason);
          ref.invalidate(orderByIdProvider(order.orderNumber!));
          if (mounted) _snack('Item cancelled', _kRed);
        },
      ),
    );
  }

  void _showCancelQtyDialog(BuildContext context, OrderDetailsModel item,
      OrderModel order, int max) {
    showDialog(
      context: context,
      builder: (_) => _CancelQtyDialog(
        item: item, maxCancellable: max,
        onConfirm: (qty, reason) async {
          await _submitCancelQty(
              item: item, order: order, cancelQty: qty, reason: reason);
        },
      ),
    );
  }

  void _showDeliveryDateDialog(BuildContext context, OrderDetailsModel item,
      int index, OrderModel order) {
    showDialog(
      context: context,
      builder: (_) => _DeliveryDateDialog(
        item: item,
        onUpdate: (date, note) async {
          await _updateDeliveryDate(
              item: item, newDate: date, order: order, note: note);
          if (mounted) _snack('Delivery date updated', _kGreen);
        },
      ),
    );
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  String _successMsg(String? s) {
    switch (s) {
      case 'CONFIRMED': return 'Order confirmed';
      case 'REJECTED':  return 'Order rejected';
      case 'CANCELLED': return 'Order cancelled';
      case 'SHIPPED':   return 'Marked as shipped';
      case 'DELIVERED': return 'Marked as delivered';
      default:          return 'Status updated';
    }
  }

  // ── API helpers (unchanged logic) ─────────────────────────────────────────
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
      isReasonUpdated: reasonForCancellation != null,
      isDeliveryDateUpdated: false,
      clearHasPackedCompleted: packingCompleted == null,
      clearHasProductionCompleted: productionCompleted == null,
      clearNextStatus: status == null,
      clearCancelQty: true,
      clearReasonForCancellation: reasonForCancellation == null,
    );
    final current = ref.read(orderByIdProvider(widget.orderNumber)).value;
    if (current == null) throw Exception('Order not found');
    final details = current.orderDetails.map((d) {
      if (d.orderDetailsNumber == item.orderDetailsNumber) return updatedItem;
      return d.copyWith(
        clearHasPackedCompleted: true, clearHasProductionCompleted: true,
        clearNextStatus: true, clearCancelQty: true,
        clearReasonForCancellation: true,
        isDeliveryDateUpdated: false, isReasonUpdated: false,
      );
    }).toList();
    await ref.read(orderControllerProvider.notifier).updateOrderItemStatus(
        current.copyWith(orderDetails: details, status: null));
    ref.invalidate(orderByIdProvider(widget.orderNumber));
  }

  Future<void> _submitCancelQty({
    required OrderDetailsModel item, required OrderModel order,
    required int cancelQty, String? reason,
  }) async {
    final updatedItem = item.copyWith(
      cancelQty: cancelQty, reasonForCancellation: reason,
      isReasonUpdated: reason != null, isDeliveryDateUpdated: false,
      clearHasPackedCompleted: true, clearHasProductionCompleted: true,
      clearNextStatus: true,
    );
    final current = ref.read(orderByIdProvider(widget.orderNumber)).value;
    if (current == null) throw Exception('Order not found');
    final details = current.orderDetails.map((d) {
      if (d.orderDetailsNumber == item.orderDetailsNumber) return updatedItem;
      return d.copyWith(
        clearHasPackedCompleted: true, clearHasProductionCompleted: true,
        clearNextStatus: true, clearCancelQty: true,
        clearReasonForCancellation: true,
        isDeliveryDateUpdated: false, isReasonUpdated: false,
      );
    }).toList();
    await ref.read(orderControllerProvider.notifier).updateOrderItemStatus(
        current.copyWith(orderDetails: details));
    ref.invalidate(orderByIdProvider(widget.orderNumber));
    if (mounted) _snack('$cancelQty unit(s) cancelled', _kAmber);
  }

  Future<void> _updateDeliveryDate({
    required OrderDetailsModel item,
    required DateTime newDate,
    required OrderModel order,
    String? note,
  }) async {
    final updatedItem = item.copyWith(
      orderDetailsNumber: item.orderDetailsNumber,
      deliveryDate: newDate,
      deliveryNote: note,
      isDeliveryDateUpdated: true,
      isReasonUpdated: false,
      clearHasPackedCompleted: true,
      clearHasProductionCompleted: true,
      clearNextStatus: true,
      clearCancelQty: true,
      clearReasonForCancellation: true,
    );
    final current = ref.read(orderByIdProvider(widget.orderNumber)).value;
    if (current == null) throw Exception('Order not found');
    final details = current.orderDetails
        .map((d) => d.orderDetailsNumber == item.orderDetailsNumber
        ? updatedItem : d)
        .toList();
    await ref.read(orderControllerProvider.notifier).updateOrderItemStatus(
        current.copyWith(orderDetails: details));
    ref.invalidate(orderByIdProvider(widget.orderNumber));
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared small widgets
// ═══════════════════════════════════════════════════════════════════════════

// ── App bar ───────────────────────────────────────────────────────────────────
class _AppBar extends StatelessWidget {
  const _AppBar({required this.sw, required this.sh,
    required this.orderNumber, required this.status,
    required this.onBack, this.onStatusTap});
  final double sw, sh;
  final String orderNumber, status;
  final VoidCallback onBack;
  final VoidCallback? onStatusTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      padding: EdgeInsets.fromLTRB(
          sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
      child: Row(children: [
        CircularIconButton(
            icon: Icons.arrow_back_ios_rounded, onTap: onBack),
        SizedBox(width: sw * 0.025),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Order Details', style: TextStyle(
                fontSize: (sw * 0.042).clamp(14.0, 20.0),
                fontWeight: FontWeight.w700, color: _kT1,
                letterSpacing: -0.2)),
            if (orderNumber.isNotEmpty)
              Text(orderNumber, style: TextStyle(
                  fontSize: (sw * 0.028).clamp(9.5, 12.5), color: _kT4)),
          ],
        )),
        if (status.isNotEmpty && onStatusTap != null)
          GestureDetector(
            onTap: onStatusTap,
            child: _StatusChip(status: status, sw: sw),
          ),
      ]),
    );
  }
}

// ── Status chip ───────────────────────────────────────────────────────────────
class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status, required this.sw});
  final String status; final double sw;

  @override
  Widget build(BuildContext context) {
    final s = _ss(status);
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.03, vertical: sw * 0.013),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular((sw * 0.05).clamp(12.0, 20.0)),
        border: Border.all(color: s.bd, width: 0.5),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(s.icon, size: (sw * 0.038).clamp(13.0, 17.0), color: s.fg),
        SizedBox(width: sw * 0.012),
        Text(status, style: TextStyle(
            fontSize: (sw * 0.028).clamp(9.5, 12.5),
            fontWeight: FontWeight.w700, color: s.fg, height: 1.0)),
      ]),
    );
  }
}

// ── Section card ──────────────────────────────────────────────────────────────
class _Card extends StatelessWidget {
  const _Card({required this.sw, required this.sh,
    required this.icon, required this.iconBg, required this.iconColor,
    required this.title, this.trailing, required this.child});
  final double sw, sh;
  final IconData icon; final Color iconBg, iconColor;
  final String title; final Widget? trailing; final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
        border: Border.all(color: _kBd, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.035),
          child: Row(children: [
            _IconBox(sw: sw, icon: icon, bg: iconBg, color: iconColor),
            SizedBox(width: sw * 0.025),
            Expanded(child: Text(title, style: TextStyle(
                fontSize: (sw * 0.035).clamp(12.0, 16.0),
                fontWeight: FontWeight.w700, color: _kT1))),
            if (trailing != null) trailing!,
          ]),
        ),
        Divider(height: 1, color: _kBd),
        Padding(padding: EdgeInsets.all(sw * 0.04), child: child),
      ]),
    );
  }
}

// ── Icon box ──────────────────────────────────────────────────────────────────
class _IconBox extends StatelessWidget {
  const _IconBox({required this.sw, required this.icon,
    required this.bg, required this.color, this.small = false});
  final double sw; final IconData icon;
  final Color bg, color; final bool small;

  @override
  Widget build(BuildContext context) {
    final sz = small
        ? (sw * 0.065).clamp(22.0, 30.0)
        : (sw * 0.075).clamp(26.0, 36.0);
    return Container(
      width: sz, height: sz,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(sz * 0.3),
      ),
      child: Icon(icon, size: sz * 0.55, color: color),
    );
  }
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.sw, required this.sh,
    required this.label, required this.value, required this.icon,
    this.valueColor, this.isLast = false});
  final double sw, sh; final String label, value;
  final IconData icon; final Color? valueColor; final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Column(children: [
      Padding(
        padding: EdgeInsets.symmetric(vertical: sw * 0.02),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            width: (sw * 0.072).clamp(26.0, 36.0),
            height: (sw * 0.072).clamp(26.0, 36.0),
            decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular((sw * 0.02).clamp(6.0, 10.0)),
                border: Border.all(color: _kBd, width: 0.5)),
            child: Icon(icon,
                size: (sw * 0.036).clamp(12.0, 16.0), color: _kT4),
          ),
          SizedBox(width: sw * 0.025),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(
                  fontSize: (sw * 0.028).clamp(9.5, 12.5),
                  color: _kT4, fontWeight: FontWeight.w500)),
              SizedBox(height: sw * 0.004),
              Text(value, style: TextStyle(
                  fontSize: (sw * 0.034).clamp(11.5, 15.0),
                  fontWeight: FontWeight.w600,
                  color: valueColor ?? _kT1)),
            ],
          )),
        ]),
      ),
      if (!isLast) Divider(height: 1, color: _kBd),
    ]);
  }
}

// ── Price row ─────────────────────────────────────────────────────────────────
class _PriceRow extends StatelessWidget {
  const _PriceRow({required this.sw, required this.label,
    required this.amount, this.isDiscount = false, this.isTotal = false});
  final double sw; final String label; final num amount;
  final bool isDiscount, isTotal;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sw * 0.015),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(
              fontSize: isTotal
                  ? (sw * 0.036).clamp(12.0, 16.0)
                  : (sw * 0.032).clamp(11.0, 14.0),
              fontWeight: isTotal ? FontWeight.w700 : FontWeight.w500,
              color: isTotal ? _kT1 : _kT2)),
          Text(
              '${isDiscount ? '-' : ''}₹${NumberFormat('#,##,###').format(amount.abs())}',
              style: TextStyle(
                  fontSize: isTotal
                      ? (sw * 0.04).clamp(13.0, 18.0)
                      : (sw * 0.032).clamp(11.0, 14.0),
                  fontWeight: isTotal ? FontWeight.w800 : FontWeight.w600,
                  color: isDiscount ? _kGreen : isTotal ? _kP : _kT1)),
        ],
      ),
    );
  }
}

// ── Pill ──────────────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  const _Pill({required this.sw, required this.label,
    required this.fg, required this.bg, required this.bd});
  final double sw; final String label;
  final Color fg, bg, bd;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
        horizontal: sw * 0.025, vertical: sw * 0.009),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
      border: Border.all(color: bd, width: 0.5),
    ),
    child: Text(label, style: TextStyle(
        fontSize: (sw * 0.026).clamp(9.0, 11.5),
        fontWeight: FontWeight.w700, color: fg, height: 1.0)),
  );
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionBtn extends StatelessWidget {
  const _ActionBtn({required this.sw, required this.label,
    required this.icon, required this.color, required this.onTap});
  final double sw; final String label;
  final IconData icon; final Color color; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => OutlinedButton.icon(
    onPressed: onTap,
    icon: Icon(icon, size: (sw * 0.038).clamp(13.0, 17.0)),
    label: Text(label, style: TextStyle(
        fontSize: (sw * 0.028).clamp(9.5, 12.5))),
    style: OutlinedButton.styleFrom(
      padding: EdgeInsets.symmetric(vertical: sw * 0.025),
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: color, width: 0.5),
      foregroundColor: color,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// Dialogs — all logic unchanged, colours updated to Zoho tokens
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
  late String _payType;
  static const _opts = ['CASH', 'BANK'];

  @override
  void initState() {
    super.initState();
    _payType = _opts.contains(widget.order.paymentType)
        ? widget.order.paymentType : 'CASH';
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Padding(
        padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(child: Container(
                  width: sw * 0.1, height: 3, margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(color: _kBd, borderRadius: BorderRadius.circular(2)))),
              Text('Update Payment', style: TextStyle(
                  fontSize: (sw * 0.045).clamp(15.0, 21.0),
                  fontWeight: FontWeight.w800, color: _kT1)),
              Text('Current: ₹${NumberFormat('#,##,###').format(widget.order.amountPaid)} · ${widget.order.paymentType}',
                  style: TextStyle(fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4)),
              SizedBox(height: sw * 0.04),
              Text('Payment Method', style: TextStyle(
                  fontSize: (sw * 0.03).clamp(10.0, 13.0),
                  color: _kT3, fontWeight: FontWeight.w600)),
              SizedBox(height: sw * 0.02),
              Row(children: _opts.map((t) {
                final sel = _payType == t;
                return Expanded(child: GestureDetector(
                  onTap: () => setState(() => _payType = t),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 140),
                    margin: EdgeInsets.only(right: t != _opts.last ? sw * 0.02 : 0),
                    padding: EdgeInsets.symmetric(vertical: sw * 0.025),
                    decoration: BoxDecoration(
                        color: sel ? _kP : _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                            color: sel ? _kP : _kBd, width: sel ? 1.5 : 0.5)),
                    child: Column(mainAxisSize: MainAxisSize.min, children: [
                      Icon(_payIcon(t), size: (sw * 0.05).clamp(16.0, 22.0),
                          color: sel ? Colors.white : _kT4),
                      SizedBox(height: sw * 0.008),
                      Text(t, style: TextStyle(
                          fontSize: (sw * 0.026).clamp(9.0, 11.5),
                          fontWeight: FontWeight.w700,
                          color: sel ? Colors.white : _kT2)),
                    ]),
                  ),
                ));
              }).toList()),
              SizedBox(height: sw * 0.04),
              Text('Amount', style: TextStyle(
                  fontSize: (sw * 0.03).clamp(10.0, 13.0),
                  color: _kT3, fontWeight: FontWeight.w600)),
              SizedBox(height: sw * 0.02),
              TextField(
                controller: _ctrl,
                keyboardType: TextInputType.number,
                style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
                decoration: InputDecoration(
                  hintText: 'Enter amount',
                  hintStyle: TextStyle(color: _kT4),
                  prefixIcon: Icon(Icons.currency_rupee, color: _kGreen,
                      size: (sw * 0.045).clamp(15.0, 20.0)),
                  filled: true, fillColor: _kBg,
                  contentPadding: EdgeInsets.symmetric(horizontal: sw * 0.04),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                      borderSide: const BorderSide(color: _kBd, width: 0.5)),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                      borderSide: const BorderSide(color: _kBd, width: 0.5)),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                      borderSide: const BorderSide(color: _kP, width: 1.5)),
                ),
              ),
              SizedBox(height: sh * 0.025),
              Row(children: [
                Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: sh * 0.016),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: _kBd, width: 0.5)),
                    child: Text('Cancel', style: TextStyle(
                        fontSize: (sw * 0.036).clamp(12.0, 15.0),
                        fontWeight: FontWeight.w700, color: _kT4)))),
                SizedBox(width: sw * 0.03),
                Expanded(flex: 2, child: ElevatedButton(
                    onPressed: _loading ? null : () async {
                      final v = double.tryParse(_ctrl.text);
                      if (v == null) {
                        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                            content: Text('Enter a valid amount'),
                            backgroundColor: _kRed));
                        return;
                      }
                      setState(() => _loading = true);
                      try {
                        await widget.onUpdate(v, _payType);
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e'), backgroundColor: _kRed));
                        }
                      } finally { if (mounted) setState(() => _loading = false); }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kP, foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: sh * 0.016),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0),
                    child: _loading
                        ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Update', style: TextStyle(
                        fontSize: (sw * 0.036).clamp(12.0, 15.0),
                        fontWeight: FontWeight.w700)))),
              ]),
            ]),
      ),
    );
  }

  IconData _payIcon(String t) {
    switch (t) {
      case 'CASH': return Icons.payments_outlined;
      case 'BANK': return Icons.account_balance_outlined;
      default: return Icons.payment_rounded;
    }
  }
}

class _OrderStatusDialog extends ConsumerStatefulWidget {
  final OrderModel order;
  final Future<void> Function(String? status, String? reason) onUpdate;
  const _OrderStatusDialog({required this.order, required this.onUpdate});
  @override
  ConsumerState<_OrderStatusDialog> createState() => _OrderStatusDialogState();
}

class _OrderStatusDialogState extends ConsumerState<_OrderStatusDialog> {
  bool _statusChecked = false, _isCancelled = false, _triedSubmit = false, _loading = false;
  String? _pendingSelection;
  String _cancelReason = '';

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
  bool get _isPending  => (widget.order.status ?? '').toUpperCase() == 'PENDING';
  bool get _isTerminal => ['CANCELLED','REJECTED','DELIVERED','COMPLETED']
      .contains((widget.order.status ?? '').toUpperCase());
  String? get _statusToSend {
    if (_isCancelled) return 'CANCELLED';
    if (_isPending) return _pendingSelection;
    if (_statusChecked) return _nextStatus;
    return null;
  }
  bool get _canUpdate {
    if (_isCancelled) return _cancelReason.trim().isNotEmpty;
    if (_isPending) return _pendingSelection != null;
    return _statusChecked;
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final role = ref.watch(roleNotifierProvider);
    final canCancel   = AppPermissions.canAccess(role, AppFeature.cancelOrder);
    final canConfirm  = AppPermissions.canAccess(role, AppFeature.orderConfirmed);
    final canReject   = AppPermissions.canAccess(role, AppFeature.orderRejected);
    final canNext     = AppPermissions.canAccess(role, _nextStatus ?? '');
    final btnColor    = _isCancelled ? _kRed
        : _pendingSelection == 'REJECTED' ? _kAmber : _kP;

    return Dialog(
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((sw * 0.05).clamp(14.0, 22.0))),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sh * 0.8),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.05),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _IconBox(sw: sw, icon: Icons.update_rounded,
                      bg: _kPBg, color: _kP),
                  SizedBox(width: sw * 0.025),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Update Status', style: TextStyle(
                        fontSize: (sw * 0.042).clamp(14.0, 19.0),
                        fontWeight: FontWeight.w800, color: _kT1)),
                    Text('Current: ${widget.order.status ?? ''}',
                        style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
                  ])),
                ]),
                SizedBox(height: sh * 0.02),
                Flexible(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  // Order info
                  Container(
                    padding: EdgeInsets.all(sw * 0.035),
                    decoration: BoxDecoration(color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBd, width: 0.5)),
                    child: Row(children: [
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(widget.order.orderNumber ?? '', style: TextStyle(
                            fontSize: (sw * 0.034).clamp(11.5, 15.0),
                            fontWeight: FontWeight.w700, color: _kT1)),
                        if (widget.order.dealer != null)
                          Text(widget.order.dealer!.employeeName, style: TextStyle(
                              fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
                      ])),
                    ]),
                  ),
                  SizedBox(height: sh * 0.02),
                  if (_isTerminal)
                    Container(
                      padding: EdgeInsets.all(sw * 0.035),
                      decoration: BoxDecoration(color: _kAmberBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _kAmberBd, width: 0.5)),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded, color: _kAmber,
                            size: (sw * 0.045).clamp(15.0, 20.0)),
                        SizedBox(width: sw * 0.02),
                        Expanded(child: Text(
                            'No further updates for ${widget.order.status} orders.',
                            style: TextStyle(
                                fontSize: (sw * 0.032).clamp(11.0, 14.0),
                                color: _kAmber))),
                      ]),
                    )
                  else if (_isPending) ...[
                    if (canConfirm)
                      _SelectionTile(sw: sw, title: 'Confirm Order',
                          value: 'CONFIRMED', groupValue: _isCancelled ? null : _pendingSelection,
                          activeColor: _kP, activeBg: _kPBg,
                          onTap: () => setState(() => _pendingSelection =
                          _pendingSelection == 'CONFIRMED' ? null : 'CONFIRMED')),
                    if (canConfirm && canReject) SizedBox(height: sh * 0.01),
                    if (canReject)
                      _SelectionTile(sw: sw, title: 'Reject Order',
                          value: 'REJECTED', groupValue: _isCancelled ? null : _pendingSelection,
                          activeColor: _kAmber, activeBg: _kAmberBg,
                          onTap: () => setState(() => _pendingSelection =
                          _pendingSelection == 'REJECTED' ? null : 'REJECTED')),
                  ]
                  else if (_nextStatus != null && canNext)
                      _CheckboxTile(sw: sw, title: _nextLabel!,
                          value: _statusChecked, disabled: _isCancelled,
                          onChanged: (v) => setState(() => _statusChecked = v ?? false)),
                  if (!_isTerminal && !_isPending && canCancel) ...[
                    SizedBox(height: sh * 0.015),
                    _CheckboxTile(sw: sw, title: 'Cancel Order',
                        value: _isCancelled, isCancel: true,
                        onChanged: (v) => setState(() {
                          _isCancelled = v ?? false;
                          if (_isCancelled) { _statusChecked = false; _pendingSelection = null; }
                        })),
                  ],
                  if (_isCancelled) ...[
                    SizedBox(height: sh * 0.015),
                    TextField(
                      onChanged: (v) => setState(() => _cancelReason = v),
                      maxLines: 2,
                      style: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1),
                      decoration: InputDecoration(
                          hintText: 'Reason for cancellation *',
                          hintStyle: TextStyle(color: _kT4),
                          filled: true, fillColor: _kBg,
                          contentPadding: EdgeInsets.all(sw * 0.035),
                          border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                              borderSide: const BorderSide(color: _kBd, width: 0.5)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                              borderSide: BorderSide(
                                  color: _triedSubmit && _cancelReason.trim().isEmpty ? _kRed : _kBd,
                                  width: _triedSubmit && _cancelReason.trim().isEmpty ? 1.5 : 0.5)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                              borderSide: const BorderSide(color: _kP, width: 1.5)),
                          errorText: _triedSubmit && _cancelReason.trim().isEmpty
                              ? 'Reason is required' : null),
                    ),
                  ],
                ]))),
                SizedBox(height: sh * 0.025),
                Row(children: [
                  Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: sh * 0.015),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: _kBd, width: 0.5)),
                      child: Text('Close', style: TextStyle(
                          fontSize: (sw * 0.036).clamp(12.0, 15.0),
                          fontWeight: FontWeight.w600, color: _kT4)))),
                  if (!_isTerminal) ...[
                    SizedBox(width: sw * 0.03),
                    Expanded(flex: 2, child: ElevatedButton(
                        onPressed: _loading ? null : () async {
                          if (_isCancelled && _cancelReason.trim().isEmpty) {
                            setState(() => _triedSubmit = true); return;
                          }
                          if (!_canUpdate) return;
                          setState(() => _loading = true);
                          try {
                            await widget.onUpdate(_statusToSend,
                                _isCancelled ? _cancelReason.trim() : null);
                            if (context.mounted) Navigator.pop(context);
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('$e'), backgroundColor: _kRed));
                            }
                          } finally { if (mounted) setState(() => _loading = false); }
                        },
                        style: ElevatedButton.styleFrom(
                            backgroundColor: _canUpdate ? btnColor : _kBd,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: _kBd,
                            padding: EdgeInsets.symmetric(vertical: sh * 0.015),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0),
                        child: _loading
                            ? const SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                            : Text(
                            _isCancelled ? 'Cancel Order'
                                : _pendingSelection == 'REJECTED' ? 'Reject' : 'Update',
                            style: TextStyle(
                                fontSize: (sw * 0.036).clamp(12.0, 15.0),
                                fontWeight: FontWeight.w700)))),
                  ],
                ]),
              ]),
        ),
      ),
    );
  }
}

class _ItemStatusDialog extends ConsumerStatefulWidget {
  final OrderDetailsModel item;
  final Future<void> Function(bool? prod, bool? pack, String? status) onUpdate;
  const _ItemStatusDialog({required this.item, required this.onUpdate});
  @override
  ConsumerState<_ItemStatusDialog> createState() => _ItemStatusDialogState();
}

class _ItemStatusDialogState extends ConsumerState<_ItemStatusDialog> {
  bool _prod = false, _pack = false, _status = false, _loading = false;

  String? get _next {
    switch (widget.item.status) {
      case 'PACKED':  return 'INVOICE';
      case 'INVOICE': return 'SHIPPED';
      case 'SHIPPED': return 'DELIVERED';
      default: return null;
    }
  }
  bool get _isProd => widget.item.hasProduction == true;
  bool get _isPack => widget.item.hasProduction == false && widget.item.hasUnpacked == true;
  bool get _isDone => widget.item.hasProduction == false && widget.item.hasUnpacked == false;
  bool get _can    => _prod || _pack || _status;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final role = ref.watch(roleNotifierProvider);
    final canProd = AppPermissions.canAccess(role, AppFeature.productionCompleted);
    final canPack = AppPermissions.canAccess(role, AppFeature.packedCompleted);
    final canNext = AppPermissions.canAccess(role, _next ?? '');

    return Dialog(
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((sw * 0.05).clamp(14.0, 22.0))),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: sh * 0.75),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.05),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _IconBox(sw: sw, icon: Icons.assignment_turned_in_rounded,
                      bg: _kPBg, color: _kP),
                  SizedBox(width: sw * 0.025),
                  Text('Update Status', style: TextStyle(
                      fontSize: (sw * 0.042).clamp(14.0, 19.0),
                      fontWeight: FontWeight.w800, color: _kT1)),
                ]),
                SizedBox(height: sh * 0.02),
                Flexible(child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    padding: EdgeInsets.all(sw * 0.035),
                    decoration: BoxDecoration(color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBd, width: 0.5)),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(widget.item.productName, style: TextStyle(
                          fontSize: (sw * 0.036).clamp(12.0, 16.0),
                          fontWeight: FontWeight.w700, color: _kT1)),
                      Text('${widget.item.productBrand} • ${widget.item.productModel}',
                          style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
                    ]),
                  ),
                  SizedBox(height: sh * 0.02),
                  if (_isProd && canProd)
                    _CheckboxTile(sw: sw, title: 'Production Completed',
                        subtitle: 'Mark production as done',
                        value: _prod, onChanged: (v) => setState(() => _prod = v ?? false))
                  else if (_isPack && canPack)
                    _CheckboxTile(sw: sw, title: 'Packing Completed',
                        subtitle: 'Mark packing as done',
                        value: _pack, onChanged: (v) => setState(() => _pack = v ?? false))
                  else if (_isDone && _next != null && canNext)
                      _CheckboxTile(sw: sw, title: 'Mark as $_next',
                          subtitle: 'Update to ${_next!.toLowerCase()}',
                          value: _status, onChanged: (v) => setState(() => _status = v ?? false))
                    else
                      Container(
                          padding: EdgeInsets.all(sw * 0.035),
                          decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(10)),
                          child: Text('No updates available for your role',
                              style: TextStyle(color: _kT4,
                                  fontSize: (sw * 0.032).clamp(11.0, 14.0)))),
                ]))),
                SizedBox(height: sh * 0.02),
                Row(children: [
                  Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: sh * 0.015),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: _kBd, width: 0.5)),
                      child: Text('Cancel', style: TextStyle(
                          fontSize: (sw * 0.036).clamp(12.0, 15.0),
                          fontWeight: FontWeight.w600, color: _kT4)))),
                  SizedBox(width: sw * 0.03),
                  Expanded(flex: 2, child: ElevatedButton(
                      onPressed: !_can || _loading ? null : () async {
                        setState(() => _loading = true);
                        try {
                          await widget.onUpdate(
                              _prod ? true : null, _pack ? true : null,
                              _status ? _next : null);
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$e'), backgroundColor: _kRed));
                          }
                        } finally { if (mounted) setState(() => _loading = false); }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kP, foregroundColor: Colors.white,
                          disabledBackgroundColor: _kBd,
                          padding: EdgeInsets.symmetric(vertical: sh * 0.015),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0),
                      child: _loading
                          ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Update', style: TextStyle(
                          fontSize: (sw * 0.036).clamp(12.0, 15.0),
                          fontWeight: FontWeight.w700)))),
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
  @override State<_CancelItemDialog> createState() => _CancelItemDialogState();
}

class _CancelItemDialogState extends State<_CancelItemDialog> {
  final _ctrl = TextEditingController();
  bool _tried = false, _loading = false;
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final empty = _ctrl.text.trim().isEmpty;
    return Dialog(
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((sw * 0.05).clamp(14.0, 22.0))),
      child: Padding(
        padding: EdgeInsets.all(sw * 0.05),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
              padding: EdgeInsets.all(sw * 0.04),
              decoration: const BoxDecoration(color: _kRedBg, shape: BoxShape.circle),
              child: Icon(Icons.cancel_outlined, color: _kRed,
                  size: (sw * 0.1).clamp(32.0, 48.0))),
          SizedBox(height: sh * 0.02),
          Text('Cancel Item?', style: TextStyle(
              fontSize: (sw * 0.048).clamp(15.0, 22.0),
              fontWeight: FontWeight.w800, color: _kT1)),
          SizedBox(height: sh * 0.006),
          Text(widget.item.productName, style: TextStyle(
              fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT2),
              textAlign: TextAlign.center),
          SizedBox(height: sh * 0.02),
          TextField(
            controller: _ctrl,
            maxLines: 2,
            onChanged: (_) => setState(() {}),
            style: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1),
            decoration: InputDecoration(
                hintText: 'Reason for cancellation *',
                hintStyle: TextStyle(color: _kT4),
                filled: true, fillColor: _kBg,
                contentPadding: EdgeInsets.all(sw * 0.035),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                    borderSide: const BorderSide(color: _kBd, width: 0.5)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                    borderSide: BorderSide(
                        color: _tried && empty ? _kRed : _kBd,
                        width: _tried && empty ? 1.5 : 0.5)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                    borderSide: const BorderSide(color: _kP, width: 1.5)),
                errorText: _tried && empty ? 'Reason is required' : null),
          ),
          SizedBox(height: sh * 0.025),
          Row(children: [
            Expanded(child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.symmetric(vertical: sh * 0.015),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    side: const BorderSide(color: _kBd, width: 0.5)),
                child: Text('Keep', style: TextStyle(
                    fontSize: (sw * 0.036).clamp(12.0, 15.0),
                    fontWeight: FontWeight.w600, color: _kT4)))),
            SizedBox(width: sw * 0.03),
            Expanded(child: ElevatedButton(
                onPressed: _loading ? null : () async {
                  setState(() => _tried = true);
                  if (empty) return;
                  setState(() => _loading = true);
                  try {
                    await widget.onConfirm(_ctrl.text.trim());
                    if (context.mounted) Navigator.pop(context);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('$e'), backgroundColor: _kRed));
                    }
                  } finally { if (mounted) setState(() => _loading = false); }
                },
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kRed, foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(vertical: sh * 0.015),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    elevation: 0),
                child: _loading
                    ? const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Yes, Cancel', style: TextStyle(
                    fontSize: (sw * 0.034).clamp(11.5, 15.0),
                    fontWeight: FontWeight.w700)))),
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
  const _CancelQtyDialog({required this.item, required this.maxCancellable,
    required this.onConfirm});
  @override State<_CancelQtyDialog> createState() => _CancelQtyDialogState();
}

class _CancelQtyDialogState extends State<_CancelQtyDialog> {
  final _qtyCtrl = TextEditingController();
  final _reasonCtrl = TextEditingController();
  int? _qty; bool _loading = false, _tried = false;
  @override void dispose() { _qtyCtrl.dispose(); _reasonCtrl.dispose(); super.dispose(); }
  bool get _validQty    => _qty != null && _qty! > 0 && _qty! <= widget.maxCancellable;
  bool get _validReason => _reasonCtrl.text.trim().isNotEmpty;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Dialog(
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((sw * 0.05).clamp(14.0, 22.0))),
      child: SingleChildScrollView(child: Padding(
        padding: EdgeInsets.all(sw * 0.05),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                _IconBox(sw: sw, icon: Icons.remove_circle_outline,
                    bg: _kAmberBg, color: _kAmber),
                SizedBox(width: sw * 0.025),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Cancel Quantity', style: TextStyle(
                      fontSize: (sw * 0.042).clamp(14.0, 19.0),
                      fontWeight: FontWeight.w800, color: _kT1)),
                  Text(widget.item.productName, style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4),
                      overflow: TextOverflow.ellipsis),
                ])),
              ]),
              SizedBox(height: sh * 0.02),
              Row(children: [
                Expanded(child: _QtyCard(sw: sw, label: 'Ordered',
                    value: '${widget.item.qtyOrdered ?? 0}',
                    color: _kP, bg: _kPBg, bd: _kPBd)),
                SizedBox(width: sw * 0.02),
                Expanded(child: _QtyCard(sw: sw, label: 'Delivered',
                    value: '${widget.item.qtyDelivered ?? 0}',
                    color: _kGreen, bg: _kGreenBg, bd: _kGreenBd)),
                SizedBox(width: sw * 0.02),
                Expanded(child: _QtyCard(sw: sw, label: 'Max Cancel',
                    value: '${widget.maxCancellable}',
                    color: _kAmber, bg: _kAmberBg, bd: _kAmberBd)),
              ]),
              SizedBox(height: sh * 0.02),
              TextField(
                controller: _qtyCtrl,
                keyboardType: TextInputType.number,
                onChanged: (v) => setState(() => _qty = int.tryParse(v)),
                style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
                decoration: InputDecoration(
                    hintText: 'Qty (Max: ${widget.maxCancellable})',
                    hintStyle: TextStyle(color: _kT4),
                    filled: true, fillColor: _kBg,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: sw * 0.04, vertical: sw * 0.035),
                    suffixIcon: _qty != null
                        ? Icon(_validQty ? Icons.check_circle_outline : Icons.error_outline,
                        color: _validQty ? _kGreen : _kRed)
                        : null,
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                        borderSide: const BorderSide(color: _kBd, width: 0.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                        borderSide: BorderSide(
                            color: _qty != null && !_validQty ? _kRed : _kBd, width: 0.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                        borderSide: const BorderSide(color: _kP, width: 1.5)),
                    errorText: _qty != null && _qty! > widget.maxCancellable
                        ? 'Cannot exceed ${widget.maxCancellable}'
                        : _qty != null && _qty! <= 0 ? 'Must be > 0' : null),
              ),
              SizedBox(height: sh * 0.015),
              TextField(
                controller: _reasonCtrl,
                maxLines: 2,
                onChanged: (_) => setState(() {}),
                style: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1),
                decoration: InputDecoration(
                    hintText: 'Reason for cancellation *',
                    hintStyle: TextStyle(color: _kT4),
                    filled: true, fillColor: _kBg,
                    contentPadding: EdgeInsets.all(sw * 0.035),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                        borderSide: const BorderSide(color: _kBd, width: 0.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                        borderSide: BorderSide(
                            color: _tried && !_validReason ? _kRed : _kBd,
                            width: _tried && !_validReason ? 1.5 : 0.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                        borderSide: const BorderSide(color: _kP, width: 1.5)),
                    errorText: _tried && !_validReason ? 'Reason is required' : null),
              ),
              SizedBox(height: sh * 0.025),
              Row(children: [
                Expanded(child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: sh * 0.015),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        side: const BorderSide(color: _kBd, width: 0.5)),
                    child: Text('Close', style: TextStyle(
                        fontSize: (sw * 0.036).clamp(12.0, 15.0),
                        fontWeight: FontWeight.w600, color: _kT4)))),
                SizedBox(width: sw * 0.03),
                Expanded(child: ElevatedButton(
                    onPressed: !_validQty || _loading ? null : () async {
                      setState(() => _tried = true);
                      if (!_validReason) return;
                      setState(() => _loading = true);
                      try {
                        await widget.onConfirm(_qty!, _reasonCtrl.text.trim());
                        if (context.mounted) Navigator.pop(context);
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$e'), backgroundColor: _kRed));
                        }
                      } finally { if (mounted) setState(() => _loading = false); }
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kAmber, foregroundColor: Colors.white,
                        disabledBackgroundColor: _kBd,
                        padding: EdgeInsets.symmetric(vertical: sh * 0.015),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        elevation: 0),
                    child: _loading
                        ? const SizedBox(width: 18, height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : Text('Confirm', style: TextStyle(
                        fontSize: (sw * 0.036).clamp(12.0, 15.0),
                        fontWeight: FontWeight.w700)))),
              ]),
            ]),
      )),
    );
  }
}

class _DeliveryDateDialog extends StatefulWidget {
  final OrderDetailsModel item;
  final Future<void> Function(DateTime date, String? note) onUpdate; // ✅ note added
  const _DeliveryDateDialog({required this.item, required this.onUpdate});
  @override State<_DeliveryDateDialog> createState() => _DeliveryDateDialogState();
}

class _DeliveryDateDialogState extends State<_DeliveryDateDialog> {
  late DateTime _date;
  final _noteCtrl = TextEditingController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _date = DateTime.now(); // always start fresh with today
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Dialog(
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular((sw * 0.05).clamp(14.0, 22.0))),
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.all(sw * 0.05),
          child: Column(mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  _IconBox(sw: sw, icon: Icons.calendar_today_rounded,
                      bg: _kPBg, color: _kP),
                  SizedBox(width: sw * 0.025),
                  Text('Delivery Date', style: TextStyle(
                      fontSize: (sw * 0.042).clamp(14.0, 19.0),
                      fontWeight: FontWeight.w800, color: _kT1)),
                ]),
                SizedBox(height: sh * 0.02),
                // Product info
                Container(
                  padding: EdgeInsets.all(sw * 0.035),
                  decoration: BoxDecoration(color: _kBg,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: _kBd, width: 0.5)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(widget.item.productName, style: TextStyle(
                        fontSize: (sw * 0.034).clamp(11.5, 15.0),
                        fontWeight: FontWeight.w700, color: _kT1)),
                    Text('${widget.item.productBrand} • ${widget.item.productModel}',
                        style: TextStyle(fontSize: (sw * 0.028).clamp(9.5, 12.5), color: _kT4)),
                  ]),
                ),
                SizedBox(height: sh * 0.02),
                // Date picker
                GestureDetector(
                  onTap: () async {
                    final p = await showDatePicker(
                        context: context,
                        initialDate: _date,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2030),
                        builder: (ctx, child) => Theme(
                            data: Theme.of(ctx).copyWith(
                                colorScheme: const ColorScheme.light(
                                    primary: _kP, onPrimary: Colors.white,
                                    surface: Colors.white, onSurface: _kT1),
                                dialogTheme: const DialogThemeData(backgroundColor: Colors.white)),
                            child: child!));
                    if (p != null) setState(() => _date = p);
                  },
                  child: Container(
                    padding: EdgeInsets.all(sw * 0.04),
                    decoration: BoxDecoration(
                        color: _kPBg,
                        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                        border: Border.all(color: _kPBd, width: 0.5)),
                    child: Row(children: [
                      Icon(Icons.calendar_month_outlined, color: _kP,
                          size: (sw * 0.05).clamp(16.0, 22.0)),
                      SizedBox(width: sw * 0.025),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text('Selected Date', style: TextStyle(
                            fontSize: (sw * 0.028).clamp(9.5, 12.5), color: _kT4)),
                        Text(DateFormat('dd MMM yyyy').format(_date), style: TextStyle(
                            fontSize: (sw * 0.038).clamp(13.0, 17.0),
                            fontWeight: FontWeight.w800, color: _kP)),
                      ])),
                      Icon(Icons.arrow_forward_ios_rounded,
                          size: (sw * 0.035).clamp(12.0, 16.0), color: _kT4),
                    ]),
                  ),
                ),
                SizedBox(height: sh * 0.018),
                // ✅ Delivery note field
                Text('Delivery Note (optional)', style: TextStyle(
                    fontSize: (sw * 0.03).clamp(10.0, 13.0),
                    color: _kT3, fontWeight: FontWeight.w600)),
                SizedBox(height: sh * 0.008),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 3,
                  style: TextStyle(
                      fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1),
                  decoration: InputDecoration(
                    hintText: 'Add a note about this delivery...',
                    hintStyle: TextStyle(color: _kT4,
                        fontSize: (sw * 0.032).clamp(11.0, 14.0)),
                    filled: true, fillColor: _kBg,
                    contentPadding: EdgeInsets.all(sw * 0.035),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                        borderSide: const BorderSide(color: _kBd, width: 0.5)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                        borderSide: const BorderSide(color: _kBd, width: 0.5)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                        borderSide: const BorderSide(color: _kP, width: 1.5)),
                  ),
                ),
                SizedBox(height: sh * 0.025),
                // Buttons
                Row(children: [
                  Expanded(child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: sh * 0.015),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: _kBd, width: 0.5)),
                      child: Text('Cancel', style: TextStyle(
                          fontSize: (sw * 0.036).clamp(12.0, 15.0),
                          fontWeight: FontWeight.w600, color: _kT4)))),
                  SizedBox(width: sw * 0.03),
                  Expanded(flex: 2, child: ElevatedButton(
                      onPressed: _loading ? null : () async {
                        setState(() => _loading = true);
                        try {
                          final note = _noteCtrl.text.trim().isEmpty
                              ? null : _noteCtrl.text.trim();
                          await widget.onUpdate(_date, note); // ✅ pass note
                          if (context.mounted) Navigator.pop(context);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text('$e'), backgroundColor: _kRed));
                          }
                        } finally { if (mounted) setState(() => _loading = false); }
                      },
                      style: ElevatedButton.styleFrom(
                          backgroundColor: _kP, foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: sh * 0.015),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          elevation: 0),
                      child: _loading
                          ? const SizedBox(width: 18, height: 18,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Update', style: TextStyle(
                          fontSize: (sw * 0.036).clamp(12.0, 15.0),
                          fontWeight: FontWeight.w700)))),
                ]),
              ]),
        ),
      ),
    );
  }
}


// ── Delivery notes history ────────────────────────────────────────────────────
class _DeliveryNotesHistory extends StatelessWidget {
  const _DeliveryNotesHistory({required this.sw, required this.notes});
  final double sw;
  final List<String> notes;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _kPBg,
        borderRadius: BorderRadius.circular((sw * 0.03).clamp(8.0, 14.0)),
        border: Border.all(color: _kPBd, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Header
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.035, vertical: sw * 0.022),
          child: Row(children: [
            Icon(Icons.history_rounded,
                size: (sw * 0.038).clamp(13.0, 16.0), color: _kP),
            SizedBox(width: sw * 0.015),
            Text('Delivery History', style: TextStyle(
              fontSize: (sw * 0.03).clamp(10.0, 13.0),
              fontWeight: FontWeight.w700, color: _kP,
            )),
            const Spacer(),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.018, vertical: sw * 0.005),
              decoration: BoxDecoration(
                color: _kP.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text('${notes.length}', style: TextStyle(
                fontSize: (sw * 0.024).clamp(8.5, 11.0),
                fontWeight: FontWeight.w800, color: _kP,
              )),
            ),
          ]),
        ),
        Divider(height: 1, color: _kPBd),

        // Each note
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: notes.length,
          separatorBuilder: (_, __) => Divider(height: 1, color: _kPBd),
          itemBuilder: (_, i) {
            final parsed = _parseDeliveryNote(notes[i]);
            if (parsed == null) {
              // Fallback — show raw
              return Padding(
                padding: EdgeInsets.all(sw * 0.03),
                child: Text(notes[i], style: TextStyle(
                  fontSize: (sw * 0.028).clamp(9.5, 12.5),
                  color: _kT3, height: 1.4,
                )),
              );
            }
            return Padding(
              padding: EdgeInsets.fromLTRB(
                  sw * 0.035, sw * 0.025, sw * 0.035, sw * 0.025),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Employee + role row
                  Row(children: [
                    Icon(Icons.person_outline_rounded,
                        size: (sw * 0.032).clamp(11.0, 14.0), color: _kP),
                    SizedBox(width: sw * 0.012),
                    Expanded(child: Text(
                      parsed.employee.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: (sw * 0.03).clamp(10.0, 13.0),
                        fontWeight: FontWeight.w600, color: _kT1,
                      ),
                      overflow: TextOverflow.ellipsis,
                    )),
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: sw * 0.02, vertical: sw * 0.006),
                      decoration: BoxDecoration(
                        color: _kPBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kPBd, width: 0.5),
                      ),
                      child: Text(parsed.role, style: TextStyle(
                        fontSize: (sw * 0.024).clamp(8.0, 10.5),
                        fontWeight: FontWeight.w600, color: _kP,
                      )),
                    ),
                  ]),
                  SizedBox(height: sw * 0.012),

                  // Date range: old → new
                  Row(children: [
                    Icon(Icons.calendar_today_outlined,
                        size: (sw * 0.03).clamp(10.0, 13.0), color: _kT4),
                    SizedBox(width: sw * 0.012),
                    Flexible(child: Text(parsed.fromDate,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (sw * 0.028).clamp(9.5, 12.0),
                          color: _kT3, fontWeight: FontWeight.w500,
                        ))),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: sw * 0.015),
                      child: Icon(Icons.arrow_forward_rounded,
                          size: (sw * 0.028).clamp(9.0, 12.0), color: _kP),
                    ),
                    Flexible(child: Text(parsed.toDate,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: (sw * 0.028).clamp(9.5, 12.0),
                          color: _kP, fontWeight: FontWeight.w700,
                        ))),
                  ]),

                  // Note (only if not empty)
                  if (parsed.note.isNotEmpty) ...[
                    SizedBox(height: sw * 0.01),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Icon(Icons.notes_rounded,
                          size: (sw * 0.03).clamp(10.0, 13.0), color: _kT4),
                      SizedBox(width: sw * 0.012),
                      Expanded(child: Text(parsed.note, style: TextStyle(
                        fontSize: (sw * 0.028).clamp(9.5, 12.0),
                        color: _kT2, height: 1.4,
                      ))),
                    ]),
                  ],
                ],
              ),
            );
          },
        ),
      ]),
    );
  }
}

// ── Qty card ──────────────────────────────────────────────────────────────────
class _QtyCard extends StatelessWidget {
  const _QtyCard({required this.sw, required this.label, required this.value,
    required this.color, required this.bg, required this.bd});
  final double sw; final String label, value;
  final Color color, bg, bd;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(vertical: sw * 0.025),
    decoration: BoxDecoration(
        color: bg, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: bd, width: 0.5)),
    child: Column(children: [
      Text(value, style: TextStyle(
          fontSize: (sw * 0.042).clamp(14.0, 20.0),
          fontWeight: FontWeight.w800, color: color)),
      Text(label, style: TextStyle(
          fontSize: (sw * 0.026).clamp(9.0, 11.5),
          color: color, fontWeight: FontWeight.w500)),
    ]),
  );
}

// ── Checkbox tile ─────────────────────────────────────────────────────────────
class _CheckboxTile extends StatelessWidget {
  const _CheckboxTile({required this.sw, required this.title, this.subtitle,
    required this.value, this.disabled = false, this.isCancel = false,
    required this.onChanged});
  final double sw; final String title; final String? subtitle;
  final bool value, disabled, isCancel; final ValueChanged<bool?> onChanged;

  @override
  Widget build(BuildContext context) {
    final ac = isCancel ? _kRed : _kP;
    final ab = isCancel ? _kRedBg : _kPBg;
    final ad = isCancel ? _kRedBd : _kPBd;
    return Container(
      decoration: BoxDecoration(
          color: value ? ab : _kBg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: value ? ad : _kBd,
              width: value ? 1.0 : 0.5)),
      child: CheckboxListTile(
        value: value, onChanged: disabled ? null : onChanged,
        title: Text(title, style: TextStyle(
            fontSize: (sw * 0.036).clamp(12.0, 16.0),
            fontWeight: FontWeight.w600,
            color: disabled ? _kT4 : (isCancel && value ? _kRed : _kT1))),
        subtitle: subtitle != null
            ? Text(subtitle!, style: TextStyle(
            fontSize: (sw * 0.028).clamp(9.5, 12.5), color: _kT4))
            : null,
        activeColor: ac, checkColor: Colors.white,
        controlAffinity: ListTileControlAffinity.leading,
        contentPadding: EdgeInsets.symmetric(
            horizontal: sw * 0.03, vertical: sw * 0.005),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}

// ── Selection tile ────────────────────────────────────────────────────────────
class _SelectionTile extends StatelessWidget {
  const _SelectionTile({required this.sw, required this.title,
    required this.value, required this.groupValue,
    required this.activeColor, required this.activeBg,
    required this.onTap});
  final double sw; final String title, value;
  final String? groupValue; final Color activeColor, activeBg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sel = groupValue == value;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        decoration: BoxDecoration(
            color: sel ? activeBg.withValues(alpha: 0.5) : _kBg,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: sel ? activeColor : _kBd,
                width: sel ? 1.0 : 0.5)),
        child: ListTile(
          leading: Container(
            width: (sw * 0.06).clamp(20.0, 28.0),
            height: (sw * 0.06).clamp(20.0, 28.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: sel ? activeColor : _kT4, width: 1.5),
                color: sel ? activeColor : Colors.transparent),
            child: sel
                ? Icon(Icons.check,
                size: (sw * 0.035).clamp(12.0, 16.0),
                color: Colors.white)
                : null,
          ),
          title: Text(title, style: TextStyle(
              fontSize: (sw * 0.036).clamp(12.0, 16.0),
              fontWeight: FontWeight.w600,
              color: sel ? activeColor : _kT1)),
          contentPadding: EdgeInsets.symmetric(
              horizontal: sw * 0.03, vertical: sw * 0.005),
          dense: true,
        ),
      ),
    );
  }
}