import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/const/icons.dart';
import '../controller/order_controller.dart';
import '../../../model/order_model.dart';
import 'order_view_page.dart';
import '../../../core/role/app_role.dart';

// ── Zoho tokens ───────────────────────────────────────────────────────────────
const _kP       = Color(0xFF185FA5);
const _kPBg     = Color(0xFFEBF4FF);
const _kPBd     = Color(0xFFBFD9F5);
const _kBg      = Color(0xFFF7F8FA);
const _kWhite   = Colors.white;
const _kBd      = Color(0xFFE5E7EB);
const _kT1      = Color(0xFF111827);
const _kT2      = Color(0xFF374151);
const _kT3      = Color(0xFF6B7280);
const _kT4      = Color(0xFF9CA3AF);
const _kGreen   = Color(0xFF0F6E56);
const _kGreenBg = Color(0xFFEDFAF5);
const _kGreenBd = Color(0xFF9FE0C5);
const _kRed     = Color(0xFFDC2626);
const _kRedBg   = Color(0xFFFEF2F2);
const _kRedBd   = Color(0xFFFECACA);
const _kAmber   = Color(0xFFB45309);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBd = Color(0xFFFCD28A);
const _kPurple  = Color(0xFF7C3AED);
const _kPurpleBg= Color(0xFFF5F3FF);
const _kPurpleBd= Color(0xFFDDD6FE);

class _SS { final Color fg, bg, bd; const _SS(this.fg, this.bg, this.bd); }
const _kStatusMap = <String, _SS>{
  'PENDING':    _SS(_kAmber, _kAmberBg, _kAmberBd),
  'CONFIRMED':  _SS(_kP, _kPBg, _kPBd),
  'PRODUCTION': _SS(Color(0xFFEA580C), Color(0xFFFFF7ED), Color(0xFFFED7AA)),
  'PACKED':     _SS(_kPurple, _kPurpleBg, _kPurpleBd),
  'INVOICE':    _SS(Color(0xFF4338CA), Color(0xFFEEF2FF), Color(0xFFC7D2FE)),
  'SHIPPED':    _SS(Color(0xFF0369A1), Color(0xFFE0F2FE), Color(0xFFBAE6FD)),
  'DELIVERED':  _SS(_kGreen, _kGreenBg, _kGreenBd),
  'COMPLETED':  _SS(_kGreen, _kGreenBg, _kGreenBd),
  'CANCELLED':  _SS(_kRed, _kRedBg, _kRedBd),
};
_SS _ss(String? s) => _kStatusMap[s?.toUpperCase()] ?? const _SS(_kT3, _kBg, _kBd);
Color _priColor(String p) { switch (p.toUpperCase()) {
  case 'HIGH': return _kRed; case 'MEDIUM': return _kAmber; default: return _kGreen; } }

bool _isToday(DateTime d, DateTime r) => d.year == r.year && d.month == r.month && d.day == r.day;
String _toDateStr(DateTime d) => '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
final _numFmt = NumberFormat('#,##,###');
String _fmt(num? n) => n == null ? '0' : _numFmt.format(n);

// ═════════════════════════════════════════════════════════════════════════════
class TodayOrdersScreen extends ConsumerStatefulWidget {
  const TodayOrdersScreen({super.key});
  @override ConsumerState<TodayOrdersScreen> createState() => _TodayOrdersScreenState();
}

class _TodayOrdersScreenState extends ConsumerState<TodayOrdersScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabCtrl;
  late final DateTime _now;
  late final String _todayStr;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _now = DateTime.now();
    _todayStr = _toDateStr(_now);
  }

  @override void dispose() { _tabCtrl.dispose(); super.dispose(); }

  List<OrderModel> _filterDelivery(List<OrderModel> all) => all
      .where((o) => o.orderDetails.any(
          (d) => d.deliveryDate != null && _isToday(d.deliveryDate!, _now)))
      .toList();

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final isDelivery = ref.watch(roleNotifierProvider) == AppRole.delivery;
    final dateParams = DateFilterParams(startDate: _todayStr, endDate: _todayStr);

    return Scaffold(backgroundColor: _kBg,
        body: SafeArea(child: Column(children: [
          // ── App bar ──────────────────────────────────────────────────────
          Container(color: _kWhite, child: Column(children: [
            Padding(
                padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.012),
                child: Row(children: [
                  Text(isDelivery ? "Today's Deliveries" : "Today's Overview",
                      style: TextStyle(fontSize: (sw * 0.048).clamp(16.0, 22.0),
                          fontWeight: FontWeight.w700, color: _kT1, letterSpacing: -0.3)),
                ])),
            if (!isDelivery) ...[
              TabBar(controller: _tabCtrl, labelColor: _kP, unselectedLabelColor: _kT4,
                  indicatorColor: _kP, indicatorWeight: 2.0, indicatorSize: TabBarIndicatorSize.label,
                  labelStyle: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), fontWeight: FontWeight.w600),
                  unselectedLabelStyle: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), fontWeight: FontWeight.w500),
                  tabs: const [Tab(text: "Today's Orders"), Tab(text: "Today's Deliveries")]),
            ],
            const Divider(height: 1, color: _kBd),
          ])),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(child: isDelivery
              ? _DeliveryBody(sw: sw, sh: sh, now: _now, todayStr: _todayStr,
              filterDelivery: _filterDelivery)
              : _AdminBody(sw: sw, sh: sh, now: _now, todayStr: _todayStr,
              tabCtrl: _tabCtrl, dateParams: dateParams,
              filterDelivery: _filterDelivery)),
        ])));
  }
}

// ── Delivery only ───────────────────────────────────────────────────────────
class _DeliveryBody extends ConsumerWidget {
  const _DeliveryBody({required this.sw, required this.sh,
    required this.now, required this.todayStr, required this.filterDelivery});
  final double sw, sh; final DateTime now; final String todayStr;
  final List<OrderModel> Function(List<OrderModel>) filterDelivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(orderControllerProvider).when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5)),
        error: (err, _) => _ErrorView(sw: sw, sh: sh, message: 'Error: $err'),
        data: (all) => _OrderList(orders: filterDelivery(all),
            emptyMsg: 'No deliveries scheduled today', sw: sw, sh: sh, todayStr: todayStr));
  }
}

// ── Everyone else (admin, manager, production, packing, salesman, accounts) ─
class _AdminBody extends ConsumerWidget {
  const _AdminBody({required this.sw, required this.sh,
    required this.now, required this.todayStr, required this.tabCtrl,
    required this.dateParams, required this.filterDelivery});
  final double sw, sh; final DateTime now; final String todayStr;
  final TabController tabCtrl; final DateFilterParams dateParams;
  final List<OrderModel> Function(List<OrderModel>) filterDelivery;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ordersAsync = ref.watch(filteredOrdersProvider(dateParams));
    final allState = ref.watch(orderControllerProvider);

    return ordersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5)),
        error: (err, _) => _ErrorView(sw: sw, sh: sh, message: 'Error loading orders: $err'),
        data: (orders) {
          final deliveryOrders = allState.valueOrNull != null
              ? filterDelivery(allState.value!) : <OrderModel>[];
          return TabBarView(controller: tabCtrl, children: [
            _OrderList(orders: orders, emptyMsg: 'No orders placed today',
                sw: sw, sh: sh, todayStr: todayStr),
            allState.isLoading
                ? const Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5))
                : _OrderList(orders: deliveryOrders, emptyMsg: 'No deliveries scheduled today',
                sw: sw, sh: sh, todayStr: todayStr),
          ]);
        });
  }
}

// ── Order list ──────────────────────────────────────────────────────────────
class _OrderList extends ConsumerWidget {
  const _OrderList({required this.orders, required this.emptyMsg,
    required this.sw, required this.sh, required this.todayStr});
  final List<OrderModel> orders; final String emptyMsg;
  final double sw, sh; final String todayStr;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return RefreshIndicator(color: _kP, backgroundColor: _kWhite,
        onRefresh: () async {
          ref.invalidate(filteredOrdersProvider(
              DateFilterParams(startDate: todayStr, endDate: todayStr)));
          ref.read(orderControllerProvider.notifier).getAllOrders();
        },
        child: orders.isEmpty
            ? _EmptyView(sw: sw, sh: sh, message: emptyMsg)
            : ListView.builder(
            padding: EdgeInsets.fromLTRB(sw * 0.038, sh * 0.015, sw * 0.038, sh * 0.04),
            itemCount: orders.length,
            itemBuilder: (_, i) => _OrderCard(order: orders[i], sw: sw, sh: sh,
                onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => OrderViewPage(orderNumber: orders[i].orderNumber.toString()))))));
  }
}

// ── Empty ────────────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.sw, required this.sh, required this.message});
  final double sw, sh; final String message;

  @override Widget build(BuildContext context) {
    return SingleChildScrollView(physics: const AlwaysScrollableScrollPhysics(),
        child: SizedBox(height: sh * 0.7,
            child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(width: (sw * 0.18).clamp(60.0, 90.0), height: (sw * 0.18).clamp(60.0, 90.0),
                  decoration: BoxDecoration(color: _kWhite, shape: BoxShape.circle,
                      border: Border.all(color: _kBd, width: 0.5)),
                  child: Icon(Icons.inbox_outlined, size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4)),
              SizedBox(height: sh * 0.02),
              Text(message, style: TextStyle(
                  fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT3, fontWeight: FontWeight.w500)),
            ]))));
  }
}

// ── Error ────────────────────────────────────────────────────────────────────
class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.sw, required this.sh, required this.message});
  final double sw, sh; final String message;

  @override Widget build(BuildContext context) {
    return Center(child: Container(
        margin: EdgeInsets.all(sw * 0.04), padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(color: _kRedBg,
            borderRadius: BorderRadius.circular((sw * 0.03).clamp(8.0, 14.0)),
            border: Border.all(color: _kRedBd, width: 0.5)),
        child: Row(children: [
          Icon(Icons.error_outline_rounded, color: _kRed, size: (sw * 0.055).clamp(18.0, 26.0)),
          SizedBox(width: sw * 0.03),
          Expanded(child: Text(message, style: TextStyle(
              fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kRed, fontWeight: FontWeight.w500, height: 1.4))),
        ])));
  }
}

// ── Order Card ──────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.sw,
    required this.sh, required this.onTap});
  final OrderModel order; final double sw, sh; final VoidCallback onTap;

  @override Widget build(BuildContext context) {
    final st = _ss(order.status);
    final pri = _priColor(order.priority);
    return GestureDetector(onTap: onTap,
        child: Container(
            margin: EdgeInsets.only(bottom: sh * 0.012),
            decoration: BoxDecoration(color: _kWhite,
                borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
                border: Border.all(color: _kBd, width: 0.5)),
            child: Column(children: [
              Padding(padding: EdgeInsets.all(sw * 0.04),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Container(
                        width: (sw * 0.105).clamp(36.0, 50.0), height: (sw * 0.105).clamp(36.0, 50.0),
                        decoration: BoxDecoration(color: _kPBg,
                            borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 14.0)),
                            border: Border.all(color: _kPBd, width: 0.5)),
                        child: Center(child: SvgPicture.asset(AppIcons.box,
                            width: (sw * 0.048).clamp(16.0, 24.0), height: (sw * 0.048).clamp(16.0, 24.0),
                            colorFilter: const ColorFilter.mode(_kP, BlendMode.srcIn)))),
                    SizedBox(width: sw * 0.03),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(order.orderNumber ?? 'N/A', style: TextStyle(
                          fontSize: (sw * 0.036).clamp(12.0, 16.0), fontWeight: FontWeight.w700,
                          color: _kT1, letterSpacing: -0.2), maxLines: 1, overflow: TextOverflow.ellipsis),
                      SizedBox(height: sh * 0.004),
                      _IconRow(svgAsset: AppIcons.dealers, text: order.dealer?.employeeName ?? 'N/A',
                          sw: sw, color: _kT3),
                      SizedBox(height: sh * 0.003),
                      _IconRow(icon: Icons.storefront_outlined, text: order.dealer?.shopName ?? 'N/A',
                          sw: sw, color: _kT4, small: true),
                    ])),
                    Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: (sw * 0.022).clamp(7.0, 12.0),
                            vertical: (sw * 0.008).clamp(3.0, 6.0)),
                        decoration: BoxDecoration(color: st.bg, borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: st.bd, width: 0.5)),
                        child: Text(order.status ?? '', style: TextStyle(
                            fontSize: (sw * 0.024).clamp(8.5, 11.0), fontWeight: FontWeight.w700, color: st.fg))),
                  ])),
              Divider(height: 1, color: _kBd),
              Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.028),
                  child: Row(children: [
                    _MiniPill(sw: sw, icon: Icons.inventory_2_outlined,
                        label: '${order.orderDetails.length} item${order.orderDetails.length > 1 ? 's' : ''}',
                        color: _kT3, bg: _kBg),
                    if (order.totalPrice != null) ...[
                      SizedBox(width: sw * 0.02),
                      _MiniPill(sw: sw, icon: Icons.currency_rupee_rounded,
                          label: _fmt(order.totalPrice), color: _kGreen, bg: _kGreenBg),
                    ],
                    const Spacer(),
                    Container(width: (sw * 0.016).clamp(5.0, 8.0), height: (sw * 0.016).clamp(5.0, 8.0),
                        decoration: BoxDecoration(color: pri, shape: BoxShape.circle)),
                    SizedBox(width: sw * 0.012),
                    Text(order.priority, style: TextStyle(
                        fontSize: (sw * 0.028).clamp(9.5, 12.5), fontWeight: FontWeight.w700, color: pri)),
                  ])),
            ])));
  }
}

class _IconRow extends StatelessWidget {
  const _IconRow({this.svgAsset, this.icon, required this.text,
    required this.sw, required this.color, this.small = false});
  final String? svgAsset; final IconData? icon;
  final String text; final double sw; final Color color; final bool small;

  @override Widget build(BuildContext context) {
    final sz = (sw * (small ? 0.028 : 0.03)).clamp(9.0, 14.0);
    return Row(children: [
      if (svgAsset != null) SvgPicture.asset(svgAsset!, width: sz, height: sz,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn))
      else Icon(icon, size: sz, color: color),
      SizedBox(width: sw * 0.015),
      Expanded(child: Text(text, style: TextStyle(fontSize: (sw * (small ? 0.028 : 0.03)).clamp(9.5, 13.0),
          color: color, fontWeight: small ? FontWeight.w400 : FontWeight.w500),
          maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }
}

class _MiniPill extends StatelessWidget {
  const _MiniPill({required this.sw, required this.icon,
    required this.label, required this.color, required this.bg});
  final double sw; final IconData icon; final String label; final Color color, bg;

  @override Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.02).clamp(6.0, 10.0), vertical: (sw * 0.012).clamp(4.0, 7.0)),
      decoration: BoxDecoration(color: bg,
          borderRadius: BorderRadius.circular((sw * 0.02).clamp(6.0, 10.0)),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: (sw * 0.032).clamp(11.0, 15.0), color: color),
        SizedBox(width: sw * 0.01),
        Text(label, style: TextStyle(fontSize: (sw * 0.028).clamp(9.5, 12.5),
            fontWeight: FontWeight.w600, color: color)),
      ]));
}