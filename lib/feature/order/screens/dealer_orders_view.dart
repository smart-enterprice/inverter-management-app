import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import '../../../feature/order/model/order_model.dart';
import '../../../widgets/circle_button.dart';
import '../controller/order_controller.dart';
import '../widgets/order_progress_bar.dart';
import 'order_view_page.dart';

// ── Zoho tokens ───────────────────────────────────────────────────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Colors.white;
const _kBd       = Color(0xFFE5E7EB);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
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
const _kIndigo   = Color(0xFF3730A3);
const _kIndigoBg = Color(0xFFEEF2FF);
const _kIndigoBd = Color(0xFFC7D2FE);
const _kTeal     = Color(0xFF0F766E);
const _kTealBg   = Color(0xFFF0FDFA);
const _kTealBd   = Color(0xFF99F6E4);
const _kOrange   = Color(0xFFC2410C);
const _kOrangeBg = Color(0xFFFFF7ED);
const _kOrangeBd = Color(0xFFFED7AA);

// ── Status helpers ────────────────────────────────────────────────────────────
({Color fg, Color bg, Color bd}) _statusTokens(String status) {
  switch (status.toUpperCase()) {
    case 'PENDING':    return (fg: _kAmber,  bg: _kAmberBg,  bd: _kAmberBd);
    case 'CONFIRMED':  return (fg: _kP,      bg: _kPBg,      bd: _kPBd);
    case 'PRODUCTION': return (fg: _kOrange, bg: _kOrangeBg, bd: _kOrangeBd);
    case 'PACKED':     return (fg: _kP,      bg: _kPBg,      bd: _kPBd);
    case 'INVOICE':    return (fg: _kPurple, bg: _kPurpleBg, bd: _kPurpleBd);
    case 'SHIPPED':    return (fg: _kIndigo, bg: _kIndigoBg, bd: _kIndigoBd);
    case 'DELIVERED':  return (fg: _kTeal,   bg: _kTealBg,   bd: _kTealBd);
    case 'COMPLETED':  return (fg: _kGreen,  bg: _kGreenBg,  bd: _kGreenBd);
    case 'CANCELLED':  return (fg: _kRed,    bg: _kRedBg,    bd: _kRedBd);
    case 'REJECTED':   return (fg: _kRed,    bg: _kRedBg,    bd: _kRedBd);
    default:           return (fg: _kT4,     bg: _kBg,       bd: _kBd);
  }
}

({Color fg, Color bg, Color bd}) _paymentTokens(String? status) {
  switch (status?.toUpperCase()) {
    case 'PAID':    return (fg: _kGreen, bg: _kGreenBg, bd: _kGreenBd);
    case 'PARTIAL': return (fg: _kAmber, bg: _kAmberBg, bd: _kAmberBd);
    case 'PENDING': return (fg: _kRed,   bg: _kRedBg,   bd: _kRedBd);
    default:        return (fg: _kT4,    bg: _kBg,      bd: _kBd);
  }
}

({Color fg, Color bg}) _priorityTokens(String priority) {
  switch (priority.toUpperCase()) {
    case 'HIGH':   return (fg: _kRed,   bg: _kRedBg);
    case 'MEDIUM': return (fg: _kAmber, bg: _kAmberBg);
    case 'LOW':    return (fg: _kGreen, bg: _kGreenBg);
    default:       return (fg: _kT4,    bg: _kBg);
  }
}

String _formatNumber(num? n) =>
    n == null ? '0' : NumberFormat('#,##,###').format(n);

// ═════════════════════════════════════════════════════════════════════════════
class DealerOrdersScreen extends ConsumerStatefulWidget {
  final String dealerId;
  final String dealerName;
  const DealerOrdersScreen({super.key, required this.dealerId, required this.dealerName});
  @override ConsumerState<DealerOrdersScreen> createState() => _DealerOrdersScreenState();
}

class _DealerOrdersScreenState extends ConsumerState<DealerOrdersScreen> {
  String _searchQuery = '';
  String? _selectedStatus;
  final _searchController = TextEditingController();

  static const _statuses = [
    'ALL', 'PENDING', 'CONFIRMED', 'PRODUCTION', 'PACKED',
    'INVOICE', 'SHIPPED', 'DELIVERED', 'COMPLETED', 'CANCELLED', 'REJECTED',
  ];

  @override void dispose() { _searchController.dispose(); super.dispose(); }

  List<OrderModel> _filtered(List<OrderModel> orders) {
    return orders.where((o) {
      final statusMatch = _selectedStatus == null || _selectedStatus == 'ALL' ||
          o.status?.toUpperCase() == _selectedStatus;
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
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final ordersAsync = ref.watch(ordersByDealerProvider(widget.dealerId));

    return Scaffold(backgroundColor: _kBg,
        body: SafeArea(child: Column(children: [

          // ── App bar ───────────────────────────────────────────────────────
          Container(color: _kWhite,
              padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
              child: Row(children: [
                CircularIconButton(icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context)),
                SizedBox(width: sw * 0.03),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(widget.dealerName, overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: (sw * 0.042).clamp(14.0, 20.0),
                          fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.3)),
                  Text('Orders', style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4, fontWeight: FontWeight.w500)),
                ])),
                ordersAsync.whenOrNull(data: (orders) => Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: (sw * 0.03).clamp(10.0, 14.0),
                        vertical: (sw * 0.012).clamp(4.0, 7.0)),
                    decoration: BoxDecoration(color: _kPBg, borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kPBd, width: 0.5)),
                    child: Text('${orders.length} orders', style: TextStyle(
                        fontSize: (sw * 0.028).clamp(9.5, 12.5), fontWeight: FontWeight.w700, color: _kP)))) ??
                    const SizedBox.shrink(),
              ])),

          SizedBox(height: sh * 0.012),

          // ── Search bar ────────────────────────────────────────────────────
          Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
              child: TextField(controller: _searchController,
                  onChanged: (v) => setState(() => _searchQuery = v),
                  style: TextStyle(fontSize: (sw * 0.035).clamp(12.0, 16.0), color: _kT1),
                  decoration: InputDecoration(
                      hintText: 'Search by order number or status…',
                      hintStyle: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT4),
                      prefixIcon: Icon(Icons.search_rounded, color: _kT4, size: (sw * 0.05).clamp(16.0, 22.0)),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? GestureDetector(
                          onTap: () { _searchController.clear(); setState(() => _searchQuery = ''); },
                          child: Icon(Icons.clear_rounded, color: _kT4, size: (sw * 0.045).clamp(14.0, 20.0)))
                          : null,
                      filled: true, fillColor: _kWhite,
                      contentPadding: EdgeInsets.symmetric(
                          horizontal: sw * 0.04, vertical: (sh * 0.015).clamp(10.0, 16.0)),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular((sw * 0.03).clamp(8.0, 14.0)),
                          borderSide: const BorderSide(color: _kBd, width: 0.5)),
                      enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular((sw * 0.03).clamp(8.0, 14.0)),
                          borderSide: const BorderSide(color: _kBd, width: 0.5)),
                      focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular((sw * 0.03).clamp(8.0, 14.0)),
                          borderSide: const BorderSide(color: _kP, width: 1.5))))),

          SizedBox(height: sh * 0.012),

          // ── Status filter chips — Zoho style ──────────────────────────────
          SizedBox(height: (sh * 0.048).clamp(36.0, 48.0),
              child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                  itemCount: _statuses.length,
                  separatorBuilder: (_, __) => SizedBox(width: sw * 0.02),
                  itemBuilder: (_, i) {
                    final status = _statuses[i];
                    final isAll = status == 'ALL';
                    final sel = (_selectedStatus == null && isAll) || _selectedStatus == status;
                    final t = isAll
                        ? (fg: _kP, bg: _kPBg, bd: _kPBd)
                        : _statusTokens(status);

                    return GestureDetector(
                        onTap: () => setState(() => _selectedStatus = isAll ? null : status),
                        child: Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: (sw * 0.032).clamp(10.0, 16.0),
                                vertical: (sw * 0.012).clamp(4.0, 7.0)),
                            decoration: BoxDecoration(
                                color: sel ? t.bg : _kWhite,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: sel ? t.fg : _kBd, width: sel ? 1.0 : 0.5)),
                            child: Row(mainAxisSize: MainAxisSize.min, children: [
                              Container(
                                  width: (sw * 0.016).clamp(5.0, 8.0),
                                  height: (sw * 0.016).clamp(5.0, 8.0),
                                  decoration: BoxDecoration(color: sel ? t.fg : _kT4, shape: BoxShape.circle)),
                              SizedBox(width: sw * 0.015),
                              Text(status, style: TextStyle(
                                  fontSize: (sw * 0.03).clamp(10.0, 13.0),
                                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                                  color: sel ? t.fg : _kT4)),
                            ])));
                  })),

          SizedBox(height: sh * 0.012),

          // ── Orders list ───────────────────────────────────────────────────
          // Keep the list visible during refetch — only show the centered
          // spinner when there's no cached data yet.
          Expanded(child: Builder(builder: (_) {
            final cached = ordersAsync.value;
            if (cached == null) {
              if (ordersAsync.hasError) return _errorState(context, sw, sh);
              return const Center(
                  child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5));
            }
            final filtered = _filtered(cached);
            if (filtered.isEmpty) return _emptyState(sw, sh);
            return RefreshIndicator(color: _kP, backgroundColor: _kWhite,
                onRefresh: () async => ref.invalidate(ordersByDealerProvider(widget.dealerId)),
                child: ListView.separated(
                    padding: EdgeInsets.fromLTRB(sw * 0.038, 0, sw * 0.038, sh * 0.04),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => SizedBox(height: sh * 0.012),
                    itemBuilder: (_, i) => _OrderCard(order: filtered[i])));
          })),
        ])));
  }

  Widget _errorState(BuildContext ctx, double sw, double sh) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: (sw * 0.18).clamp(60.0, 90.0), height: (sw * 0.18).clamp(60.0, 90.0),
          decoration: BoxDecoration(color: _kWhite, shape: BoxShape.circle,
              border: Border.all(color: _kBd, width: 0.5)),
          child: Icon(Icons.wifi_off_rounded, size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4)),
      SizedBox(height: sh * 0.02),
      Text('Failed to load orders', style: TextStyle(
          fontSize: (sw * 0.038).clamp(13.0, 18.0), fontWeight: FontWeight.w600, color: _kT2)),
      SizedBox(height: sh * 0.02),
      ElevatedButton(
          onPressed: () => ref.invalidate(ordersByDealerProvider(widget.dealerId)),
          style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
              shape: const CircleBorder(), padding: const EdgeInsets.all(14), elevation: 0),
          child: const Icon(Icons.refresh_rounded)),
    ]));
  }

  Widget _emptyState(double sw, double sh) {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: (sw * 0.18).clamp(60.0, 90.0), height: (sw * 0.18).clamp(60.0, 90.0),
          decoration: BoxDecoration(color: _kWhite, shape: BoxShape.circle,
              border: Border.all(color: _kBd, width: 0.5)),
          child: Icon(Icons.receipt_long_outlined, size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4)),
      SizedBox(height: sh * 0.02),
      Text(_searchQuery.isNotEmpty || _selectedStatus != null
          ? 'No orders match your filter' : 'No orders yet',
          style: TextStyle(fontSize: (sw * 0.038).clamp(13.0, 18.0),
              fontWeight: FontWeight.w600, color: _kT2)),
    ]));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Order card
// ═════════════════════════════════════════════════════════════════════════════
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final status = order.status?.toUpperCase() ?? '';
    final st = _statusTokens(status);
    final pt = _priorityTokens(order.priority);
    final progressBar = OrderProgressBar.maybeFor(
      progress: order.progress,
      status: order.status,
      sw: sw, sh: sh,
    );

    return GestureDetector(
        onTap: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => OrderViewPage(orderNumber: order.orderNumber!))),
        child: Container(
            padding: EdgeInsets.all((sw * 0.04).clamp(12.0, 20.0)),
            decoration: BoxDecoration(color: _kWhite,
                borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
                border: Border.all(color: _kBd, width: 0.5)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Top: order number + status
              Row(children: [
                Expanded(child: Text(order.orderNumber ?? 'N/A', style: TextStyle(
                    fontSize: (sw * 0.038).clamp(13.0, 18.0), fontWeight: FontWeight.w800,
                    color: _kT1, letterSpacing: -0.3))),
                _Pill(label: status, fg: st.fg, bg: st.bg, bd: st.bd, sw: sw),
              ]),
              SizedBox(height: sh * 0.012),
              Divider(height: 1, color: _kBd),
              SizedBox(height: sh * 0.012),

              // Amounts + payment
              RoleGuard(feature: AppFeature.paymentView,
                  child: Column(children: [
                    Row(children: [
                      Expanded(child: _AmountCol(sw: sw, sh: sh, label: 'Total Amount',
                          value: '₹${_formatNumber(order.orderTotalPrice ?? 0)}',
                          valueColor: _kT1, valueFontSize: (sw * 0.04).clamp(13.0, 19.0))),
                      if (order.amountDue != null && order.amountDue! > 0)
                        Expanded(child: _AmountCol(sw: sw, sh: sh, label: 'Amount Due',
                            value: '₹${_formatNumber(order.amountDue)}',
                            valueColor: _kRed, valueFontSize: (sw * 0.038).clamp(12.0, 18.0))),
                          () { final p = _paymentTokens(order.paymentStatus);
                      return _Pill(label: order.paymentStatus ?? 'N/A',
                          fg: p.fg, bg: p.bg, bd: p.bd, sw: sw); }(),
                    ]),
                    SizedBox(height: sh * 0.012),
                  ])),

              if (progressBar != null) ...[
                progressBar,
                SizedBox(height: sh * 0.012),
              ],

              // Bottom: priority + date + chevron
              Row(children: [
                Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: (sw * 0.025).clamp(8.0, 12.0),
                        vertical: (sw * 0.01).clamp(3.0, 6.0)),
                    decoration: BoxDecoration(color: pt.bg,
                        borderRadius: BorderRadius.circular((sw * 0.02).clamp(6.0, 10.0))),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.flag_rounded, size: (sw * 0.032).clamp(10.0, 14.0), color: pt.fg),
                      SizedBox(width: sw * 0.01),
                      Text(order.priority, style: TextStyle(
                          fontSize: (sw * 0.028).clamp(9.5, 12.5), fontWeight: FontWeight.w700, color: pt.fg)),
                    ])),
                const Spacer(),
                Icon(Icons.calendar_today_outlined, size: (sw * 0.032).clamp(10.0, 14.0), color: _kT4),
                SizedBox(width: sw * 0.015),
                Text(order.createdAt != null
                    ? DateFormat('dd MMM yyyy').format(order.createdAt!) : 'N/A',
                    style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0),
                        color: _kT4, fontWeight: FontWeight.w500)),
                SizedBox(width: sw * 0.02),
                Icon(Icons.arrow_forward_ios_rounded, size: (sw * 0.03).clamp(10.0, 13.0), color: _kT4),
              ]),
            ])));
  }
}

// ── Shared widgets ────────────────────────────────────────────────────────────
class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.fg, required this.bg,
    required this.bd, required this.sw});
  final String label; final Color fg, bg, bd; final double sw;

  @override Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.025).clamp(8.0, 12.0),
          vertical: (sw * 0.01).clamp(3.0, 6.0)),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: bd, width: 0.5)),
      child: Text(label, style: TextStyle(
          fontSize: (sw * 0.028).clamp(9.5, 12.5), fontWeight: FontWeight.w700, color: fg)));
}

class _AmountCol extends StatelessWidget {
  const _AmountCol({required this.sw, required this.sh, required this.label,
    required this.value, required this.valueColor, required this.valueFontSize});
  final double sw, sh, valueFontSize; final String label, value; final Color valueColor;

  @override Widget build(BuildContext context) => Column(
      crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: TextStyle(fontSize: (sw * 0.028).clamp(9.5, 12.5),
        color: _kT4, fontWeight: FontWeight.w500)),
    SizedBox(height: sh * 0.003),
    Text(value, style: TextStyle(fontSize: valueFontSize,
        fontWeight: FontWeight.w800, color: valueColor)),
  ]);
}