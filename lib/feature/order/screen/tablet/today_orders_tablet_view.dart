import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/role/app_role.dart';
import '../../../../model/order_model.dart';
import '../../../order/controller/order_controller.dart';
import '../order_view_page.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF4F5F7);
const _kWhite    = Color(0xFFFFFFFF);
const _kBd       = Color(0xFFE5E7EB);
const _kBdLight  = Color(0xFFF0F1F3);
const _kT1       = Color(0xFF1A1A2E);
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
const _kOrange   = Color(0xFFEA580C);
const _kOrangeBg = Color(0xFFFFF7ED);
const _kOrangeBd = Color(0xFFFED7AA);
const _kPurple   = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBd = Color(0xFFDDD6FE);
const _kIndigo   = Color(0xFF4338CA);
const _kIndigoBg = Color(0xFFEEF2FF);
const _kIndigoBd = Color(0xFFC7D2FE);
const _kBlue     = Color(0xFF0369A1);
const _kBlueBg   = Color(0xFFE0F2FE);
const _kBlueBd   = Color(0xFFBAE6FD);

const _kLimit = 20;

String _fmt(num? n) => n == null ? '0' : NumberFormat('#,##,###').format(n);
String _toDateStr(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

class _SS { final Color fg, bg, bd; const _SS(this.fg, this.bg, this.bd); }
_SS _ss(String? s) {
  switch (s?.toUpperCase()) {
    case 'PENDING':    return const _SS(_kAmber,  _kAmberBg,  _kAmberBd);
    case 'CONFIRMED':  return const _SS(_kP,      _kPBg,      _kPBd);
    case 'PRODUCTION': return const _SS(_kOrange, _kOrangeBg, _kOrangeBd);
    case 'PACKED':     return const _SS(_kPurple, _kPurpleBg, _kPurpleBd);
    case 'INVOICE':    return const _SS(_kIndigo, _kIndigoBg, _kIndigoBd);
    case 'SHIPPED':    return const _SS(_kBlue,   _kBlueBg,   _kBlueBd);
    case 'DELIVERED':
    case 'COMPLETED':  return const _SS(_kGreen,  _kGreenBg,  _kGreenBd);
    case 'CANCELLED':  return const _SS(_kRed,    _kRedBg,    _kRedBd);
    default:           return const _SS(_kT3, Color(0xFFF3F4F6), _kBd);
  }
}

Color _pri(String p) {
  switch (p.toUpperCase()) {
    case 'HIGH':   return _kRed;
    case 'MEDIUM': return _kAmber;
    default:       return _kGreen;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// TodayOrdersTabletView
// ═════════════════════════════════════════════════════════════════════════════
class TodayOrdersTabletView extends ConsumerStatefulWidget {
  const TodayOrdersTabletView({super.key});
  @override
  ConsumerState<TodayOrdersTabletView> createState() =>
      _TodayOrdersTabletViewState();
}

class _TodayOrdersTabletViewState extends ConsumerState<TodayOrdersTabletView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final String _todayStr;

  // Orders tab state
  final List<OrderModel> _orders = [];
  int  _ordersPage        = 1;
  bool _ordersMore        = true;
  bool _ordersLoadingMore = false;

  // Deliveries tab state
  final List<OrderModel> _deliveries = [];
  int  _delivPage         = 1;
  bool _delivMore         = true;
  bool _delivLoadingMore  = false;

  OrderModel? _sel;

  @override
  void initState() {
    super.initState();
    _tabCtrl  = TabController(length: 2, vsync: this);
    _todayStr = _toDateStr(DateTime.now());
    _tabCtrl.addListener(() {
      if (!_tabCtrl.indexIsChanging) setState(() => _sel = null);
    });
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  // ── Params ────────────────────────────────────────────────────────────────
  DateFilterParams _orderParams(int page) => DateFilterParams(
      startDate: _todayStr, endDate: _todayStr, page: page, limit: _kLimit);

  DateFilterParams _delivParams(int page) => DateFilterParams(
      deliveryStartDate: _todayStr, deliveryEndDate: _todayStr,
      page: page, limit: _kLimit);

  // ── Load more ─────────────────────────────────────────────────────────────
  Future<void> _loadMoreOrders() async {
    if (_ordersLoadingMore || !_ordersMore) return;
    setState(() => _ordersLoadingMore = true);
    try {
      final next = await ref.read(
          filteredOrdersProvider(_orderParams(_ordersPage + 1)).future);
      setState(() {
        if (next.isEmpty) {
          _ordersMore = false;
        } else {
          final seen = _orders.map((o) => o.orderNumber).toSet();
          _orders.addAll(next.where((o) => !seen.contains(o.orderNumber)));
          _ordersPage++;
          if (next.length < _kLimit) _ordersMore = false;
        }
        _ordersLoadingMore = false;
      });
    } catch (e, stack) {
      debugPrint('_loadMoreOrders error: $e\n$stack');
      setState(() => _ordersLoadingMore = false);
    }
  }

  Future<void> _loadMoreDeliveries() async {
    if (_delivLoadingMore || !_delivMore) return;
    setState(() => _delivLoadingMore = true);
    try {
      final next = await ref.read(
          filteredOrdersProvider(_delivParams(_delivPage + 1)).future);
      setState(() {
        if (next.isEmpty) {
          _delivMore = false;
        } else {
          final seen = _deliveries.map((o) => o.orderNumber).toSet();
          _deliveries.addAll(
              next.where((o) => !seen.contains(o.orderNumber)));
          _delivPage++;
          if (next.length < _kLimit) _delivMore = false;
        }
        _delivLoadingMore = false;
      });
    } catch (e, stack) {
      debugPrint('_loadMoreDeliveries error: $e\n$stack');
      setState(() => _delivLoadingMore = false);
    }
  }

  // ── Refresh ───────────────────────────────────────────────────────────────
  Future<void> _refreshOrders() async {
    setState(() {
      _orders.clear(); _ordersPage = 1; _ordersMore = true; _sel = null;
    });
    ref.invalidate(filteredOrdersProvider(_orderParams(1)));
  }

  Future<void> _refreshDeliveries() async {
    setState(() {
      _deliveries.clear(); _delivPage = 1; _delivMore = true; _sel = null;
    });
    ref.invalidate(filteredOrdersProvider(_delivParams(1)));
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final lw = (sw * 0.38).clamp(260.0, 420.0);

    final isDelivery = ref.watch(roleNotifierProvider) == AppRole.delivery;

    final ordersAsync   = ref.watch(filteredOrdersProvider(_orderParams(1)));
    final deliveryAsync = ref.watch(filteredOrdersProvider(_delivParams(1)));

    // Accumulate page-1 data into local lists
    ordersAsync.whenData((data) {
      if (_orders.isEmpty && data.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _orders.clear();
            _orders.addAll(data);
            if (data.length < _kLimit) _ordersMore = false;
          });
        });
      }
    });

    deliveryAsync.whenData((data) {
      if (_deliveries.isEmpty && data.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (!mounted) return;
          setState(() {
            _deliveries.clear();
            _deliveries.addAll(data);
            if (data.length < _kLimit) _delivMore = false;
          });
        });
      }
    });

    final activeList = (isDelivery || _tabCtrl.index == 1)
        ? _deliveries
        : _orders;

    // Auto-select first item
    if (_sel == null && activeList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _sel == null) setState(() => _sel = activeList.first);
      });
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Left panel ────────────────────────────────────────────────
            SizedBox(
              width: lw,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: _kWhite,
                  border: Border(right: BorderSide(color: _kBd, width: 0.5)),
                ),
                child: Column(children: [

                  // Header + tabs
                  Container(
                    decoration: const BoxDecoration(
                      color: _kWhite,
                      border: Border(
                          bottom: BorderSide(color: _kBd, width: 0.5)),
                    ),
                    child: Column(children: [
                      Padding(
                        padding: EdgeInsets.fromLTRB(
                            lw * 0.06, sh * 0.016, lw * 0.06, sh * 0.01),
                        child: Row(children: [
                          Text(isDelivery
                              ? "Today's Deliveries"
                              : "Today's Overview",
                              style: TextStyle(
                                fontSize: (lw * 0.056).clamp(16.0, 21.0),
                                fontWeight: FontWeight.w700, color: _kT1,
                                letterSpacing: -0.3,
                              )),
                        ]),
                      ),
                      if (!isDelivery)
                        TabBar(
                          controller: _tabCtrl,
                          labelColor: _kP,
                          unselectedLabelColor: _kT4,
                          indicatorColor: _kP,
                          indicatorWeight: 2.0,
                          indicatorSize: TabBarIndicatorSize.label,
                          labelStyle: TextStyle(
                              fontSize: (lw * 0.038).clamp(11.5, 14.0),
                              fontWeight: FontWeight.w600),
                          unselectedLabelStyle: TextStyle(
                              fontSize: (lw * 0.038).clamp(11.5, 14.0),
                              fontWeight: FontWeight.w500),
                          tabs: const [
                            Tab(text: "Today's Orders"),
                            Tab(text: "Today's Deliveries"),
                          ],
                        ),
                    ]),
                  ),

                  // List body
                  Expanded(
                    child: isDelivery
                        ? deliveryAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: _kP, strokeWidth: 2)),
                      error: (e, _) => _LeftError(sw: lw, sh: sh),
                      data: (_) => _LeftList(
                        sw: lw, sh: sh,
                        orders: _deliveries,
                        sel: _sel,
                        hasMore: _delivMore,
                        loadingMore: _delivLoadingMore,
                        emptyMsg: 'No deliveries today',
                        onTap: (o) {
                          HapticFeedback.selectionClick();
                          setState(() => _sel = o);
                        },
                        onRefresh: _refreshDeliveries,
                        onLoadMore: _loadMoreDeliveries,
                      ),
                    )
                        : TabBarView(
                      controller: _tabCtrl,
                      children: [
                        // Tab 0: Today's Orders
                        ordersAsync.when(
                          loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: _kP, strokeWidth: 2)),
                          error: (_, __) => _LeftError(sw: lw, sh: sh),
                          data: (_) => _LeftList(
                            sw: lw, sh: sh,
                            orders: _orders,
                            sel: _sel,
                            hasMore: _ordersMore,
                            loadingMore: _ordersLoadingMore,
                            emptyMsg: 'No orders today',
                            onTap: (o) {
                              HapticFeedback.selectionClick();
                              setState(() => _sel = o);
                            },
                            onRefresh: _refreshOrders,
                            onLoadMore: _loadMoreOrders,
                          ),
                        ),
                        // Tab 1: Today's Deliveries
                        deliveryAsync.when(
                          loading: () => const Center(
                              child: CircularProgressIndicator(
                                  color: _kP, strokeWidth: 2)),
                          error: (_, __) => _LeftError(sw: lw, sh: sh),
                          data: (_) => _LeftList(
                            sw: lw, sh: sh,
                            orders: _deliveries,
                            sel: _sel,
                            hasMore: _delivMore,
                            loadingMore: _delivLoadingMore,
                            emptyMsg: 'No deliveries today',
                            onTap: (o) {
                              HapticFeedback.selectionClick();
                              setState(() => _sel = o);
                            },
                            onRefresh: _refreshDeliveries,
                            onLoadMore: _loadMoreDeliveries,
                          ),
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
            ),

            // ── Right panel ───────────────────────────────────────────────
            Expanded(
              child: _sel == null
                  ? _RightEmpty(sw: sw - lw, sh: sh)
                  : _DetailCard(
                order: _sel!,
                pw: sw - lw,
                sh: sh,
                onOpen: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) =>
                      OrderViewPage(orderNumber: _sel!.orderNumber ?? '')),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Left list ─────────────────────────────────────────────────────────────────
class _LeftList extends StatefulWidget {
  const _LeftList({
    required this.sw, required this.sh,
    required this.orders, required this.sel,
    required this.hasMore, required this.loadingMore,
    required this.emptyMsg,
    required this.onTap, required this.onRefresh, required this.onLoadMore,
  });
  final double sw, sh;
  final List<OrderModel> orders;
  final OrderModel? sel;
  final bool hasMore, loadingMore;
  final String emptyMsg;
  final ValueChanged<OrderModel> onTap;
  final Future<void> Function() onRefresh;
  final Future<void> Function() onLoadMore;

  @override
  State<_LeftList> createState() => _LeftListState();
}

class _LeftListState extends State<_LeftList> {
  final _scroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.pixels >=
          _scroll.position.maxScrollExtent - 200) {
        if (!widget.loadingMore && widget.hasMore) widget.onLoadMore();
      }
    });
  }

  @override
  void dispose() { _scroll.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    if (widget.orders.isEmpty) {
      return _EmptyLeft(sw: widget.sw, sh: widget.sh, message: widget.emptyMsg);
    }

    return RefreshIndicator(
      color: _kP, backgroundColor: _kWhite,
      onRefresh: widget.onRefresh,
      child: ListView.builder(
        controller: _scroll,
        padding: EdgeInsets.symmetric(vertical: widget.sh * 0.01),
        itemCount: widget.orders.length + (widget.hasMore ? 1 : 0),
        itemBuilder: (_, i) {
          if (i == widget.orders.length) {
            return Center(child: Padding(
              padding: EdgeInsets.symmetric(vertical: widget.sh * 0.02),
              child: const CircularProgressIndicator(
                  color: _kP, strokeWidth: 2),
            ));
          }
          final o   = widget.orders[i];
          final sel = widget.sel?.orderNumber == o.orderNumber;
          return _OrderRow(
            order: o, selected: sel,
            lw: widget.sw, sh: widget.sh,
            onTap: () => widget.onTap(o),
          );
        },
      ),
    );
  }
}

// ── Order row (left panel) ────────────────────────────────────────────────────
class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.selected,
    required this.lw, required this.sh, required this.onTap});
  final OrderModel order;
  final bool selected;
  final double lw, sh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st = _ss(order.status);
    final p  = _pri(order.priority);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        decoration: BoxDecoration(
          color: selected ? _kPBg : _kWhite,
          border: Border(
            left: BorderSide(
                color: selected ? _kP : Colors.transparent, width: 3),
            bottom: const BorderSide(color: _kBdLight, width: 0.5),
          ),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: lw * 0.07, vertical: sh * 0.014),
        child: Row(children: [
          Container(width: 7, height: 7,
              decoration: BoxDecoration(color: p, shape: BoxShape.circle)),
          SizedBox(width: lw * 0.04),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.orderNumber ?? 'N/A', style: TextStyle(
                fontSize: (lw * 0.042).clamp(12.0, 14.0),
                fontWeight: FontWeight.w700,
                color: selected ? _kP : _kT1, letterSpacing: -0.1,
              )),
              SizedBox(height: sh * 0.003),
              Text(order.dealer?.employeeName ?? 'N/A', style: TextStyle(
                fontSize: (lw * 0.034).clamp(10.0, 12.0),
                color: _kT3, fontWeight: FontWeight.w500,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          SizedBox(width: lw * 0.03),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (order.totalPrice != null)
              Text('₹${_fmt(order.totalPrice)}', style: TextStyle(
                fontSize: (lw * 0.036).clamp(10.5, 13.0),
                fontWeight: FontWeight.w700, color: _kT1,
              )),
            SizedBox(height: sh * 0.004),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: lw * 0.04, vertical: sh * 0.003),
              decoration: BoxDecoration(
                color: st.bg,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: st.bd, width: 0.5),
              ),
              child: Text(order.status ?? '', style: TextStyle(
                fontSize: (lw * 0.028).clamp(8.0, 10.0),
                fontWeight: FontWeight.w700,
                color: st.fg, height: 1.0,
              )),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ── Detail card (right panel) ─────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.order, required this.pw,
    required this.sh, required this.onOpen});
  final OrderModel order;
  final double pw, sh;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final st  = _ss(order.status);
    final p   = _pri(order.priority);
    final pad = (pw * 0.06).clamp(20.0, 40.0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: _kBd, width: 0.5),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Header
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: pw * 0.06, vertical: sh * 0.022),
              decoration: const BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(8),
                    topRight: Radius.circular(8)),
                border: Border(
                    bottom: BorderSide(color: _kBd, width: 0.5)),
              ),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber ?? 'N/A', style: TextStyle(
                      fontSize: (pw * 0.038).clamp(16.0, 22.0),
                      fontWeight: FontWeight.w800,
                      color: _kT1, letterSpacing: -0.3,
                    )),
                    if (order.createdAt != null) ...[
                      SizedBox(height: sh * 0.005),
                      Text(
                        DateFormat('d MMM yyyy, h:mm a')
                            .format(order.createdAt!.toLocal()),
                        style: TextStyle(
                            fontSize: (pw * 0.024).clamp(10.0, 13.0),
                            color: _kT3),
                      ),
                    ],
                  ],
                )),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: pw * 0.04, vertical: sh * 0.008),
                  decoration: BoxDecoration(
                    color: st.bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: st.bd, width: 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(
                            color: st.fg, shape: BoxShape.circle)),
                    SizedBox(width: pw * 0.018),
                    Text(order.status ?? '', style: TextStyle(
                      fontSize: (pw * 0.022).clamp(10.0, 13.0),
                      fontWeight: FontWeight.w700,
                      color: st.fg, height: 1.0,
                    )),
                  ]),
                ),
              ]),
            ),

            // Body rows
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: pw * 0.06, vertical: sh * 0.02),
              child: Column(children: [
                _InfoRow(icon: Icons.person_outline_rounded, label: 'Dealer',
                    value: order.dealer?.employeeName ?? 'N/A',
                    pw: pw, sh: sh),
                _divider(),
                _InfoRow(icon: Icons.store_outlined, label: 'Shop',
                    value: order.dealer?.shopName ?? 'N/A',
                    pw: pw, sh: sh),
                _divider(),
                _InfoRow(icon: Icons.phone_outlined, label: 'Phone',
                    value: order.dealer?.employeePhone.toString() ?? 'N/A',
                    pw: pw, sh: sh),
                _divider(),
                _InfoRow(icon: Icons.inventory_2_outlined, label: 'Items',
                    value: '${order.orderDetails.length} '
                        'item${order.orderDetails.length != 1 ? 's' : ''}',
                    pw: pw, sh: sh),
                _divider(),
                if (order.totalPrice != null) ...[
                  _InfoRow(icon: Icons.currency_rupee_rounded, label: 'Amount',
                      value: '₹${_fmt(order.totalPrice)}',
                      valueColor: _kGreen,
                      pw: pw, sh: sh),
                  _divider(),
                ],
                _PriorityRow(p: p, priority: order.priority, pw: pw, sh: sh),
              ]),
            ),

            // Footer
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: pw * 0.06, vertical: sh * 0.018),
              decoration: const BoxDecoration(
                  border: Border(
                      top: BorderSide(color: _kBd, width: 0.5))),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onOpen,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: pw * 0.048,
                          vertical: sh * 0.013),
                      decoration: BoxDecoration(
                          color: _kP,
                          borderRadius: BorderRadius.circular(6)),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.open_in_new_rounded,
                            size: (pw * 0.024).clamp(12.0, 15.0),
                            color: _kWhite),
                        SizedBox(width: pw * 0.016),
                        Text('View Full Details', style: TextStyle(
                          fontSize: (pw * 0.022).clamp(11.0, 13.0),
                          fontWeight: FontWeight.w700, color: _kWhite,
                        )),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _divider() =>
      const Divider(height: 1, thickness: 0.5, color: _kBdLight);
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label,
    required this.value, required this.pw, required this.sh,
    this.valueColor});
  final IconData icon;
  final String label, value;
  final double pw, sh;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: sh * 0.013),
    child: Row(children: [
      Icon(icon, size: (pw * 0.026).clamp(13.0, 16.0), color: _kT4),
      SizedBox(width: pw * 0.028),
      SizedBox(
        width: pw * 0.22,
        child: Text(label, style: TextStyle(
          fontSize: (pw * 0.022).clamp(10.5, 13.0),
          color: _kT3, fontWeight: FontWeight.w500,
        )),
      ),
      const Spacer(),
      Text(value, style: TextStyle(
        fontSize: (pw * 0.023).clamp(11.0, 13.5),
        fontWeight: FontWeight.w600,
        color: valueColor ?? _kT1,
      ), textAlign: TextAlign.end, maxLines: 1,
          overflow: TextOverflow.ellipsis),
    ]),
  );
}

// ── Priority row ──────────────────────────────────────────────────────────────
class _PriorityRow extends StatelessWidget {
  const _PriorityRow({required this.p, required this.priority,
    required this.pw, required this.sh});
  final Color p;
  final String priority;
  final double pw, sh;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: sh * 0.013),
    child: Row(children: [
      Icon(Icons.flag_outlined,
          size: (pw * 0.026).clamp(13.0, 16.0), color: _kT4),
      SizedBox(width: pw * 0.028),
      SizedBox(
        width: pw * 0.22,
        child: Text('Priority', style: TextStyle(
          fontSize: (pw * 0.022).clamp(10.5, 13.0),
          color: _kT3, fontWeight: FontWeight.w500,
        )),
      ),
      const Spacer(),
      Container(
        padding: EdgeInsets.symmetric(
            horizontal: pw * 0.032, vertical: sh * 0.004),
        decoration: BoxDecoration(
          color: p.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(3),
          border: Border.all(color: p.withValues(alpha: 0.3), width: 0.5),
        ),
        child: Text(priority, style: TextStyle(
          fontSize: (pw * 0.022).clamp(10.0, 12.5),
          fontWeight: FontWeight.w700, color: p, height: 1.0,
        )),
      ),
    ]),
  );
}

// ── Right empty state ─────────────────────────────────────────────────────────
class _RightEmpty extends StatelessWidget {
  const _RightEmpty({required this.sw, required this.sh});
  final double sw, sh;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.touch_app_outlined,
          size: (sw * 0.06).clamp(40.0, 56.0),
          color: const Color(0xFFD1D5DB)),
      SizedBox(height: sh * 0.015),
      Text('Select an order to view details', style: TextStyle(
        fontSize: (sw * 0.024).clamp(13.0, 16.0),
        color: _kT4, fontWeight: FontWeight.w500,
      )),
    ],
  ));
}

// ── Left empty state ──────────────────────────────────────────────────────────
class _EmptyLeft extends StatelessWidget {
  const _EmptyLeft({required this.sw, required this.sh, required this.message});
  final double sw, sh; final String message;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.inbox_outlined,
          size: (sw * 0.12).clamp(36.0, 56.0), color: _kT4),
      SizedBox(height: sh * 0.015),
      Text(message, style: TextStyle(
        fontSize: (sw * 0.036).clamp(12.0, 15.0),
        color: _kT3, fontWeight: FontWeight.w500,
      )),
    ],
  ));
}

// ── Left error state ──────────────────────────────────────────────────────────
class _LeftError extends StatelessWidget {
  const _LeftError({required this.sw, required this.sh});
  final double sw, sh;

  @override
  Widget build(BuildContext context) => Center(child: Padding(
    padding: EdgeInsets.all(sw * 0.06),
    child: Row(children: [
      Icon(Icons.wifi_off_rounded, color: _kRed,
          size: (sw * 0.07).clamp(18.0, 26.0)),
      SizedBox(width: sw * 0.03),
      Expanded(child: Text('Could not load data', style: TextStyle(
        fontSize: (sw * 0.034).clamp(11.0, 14.0),
        color: _kRed, fontWeight: FontWeight.w500,
      ))),
    ]),
  ));
}
