import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../feature/order/controller/order_controller.dart';
import '../../feature/order/screen/order_view_page.dart';
import '../../feature/signup/controller/signUp_controller.dart';
import '../../main.dart';
import '../../model/order_model.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Color(0xFFFFFFFF);
const _kBd       = Color(0xFFE5E7EB);
const _kT1       = Color(0xFF111827);
const _kT3       = Color(0xFF6B7280);
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

String _fmt(num? n) => n == null ? '0' : NumberFormat('#,##,###').format(n);

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

// ── Stat model ────────────────────────────────────────────────────────────────
class _Stat {
  final String label;
  final int count;
  final Color fg, bg, bd;
  const _Stat({required this.label, required this.count,
    required this.fg, required this.bg, required this.bd});
}

List<_Stat> _buildStats(List<OrderModel> orders) {
  final c = <String, int>{};
  for (final o in orders) {
    final s = (o.status ?? '').toUpperCase();
    c[s] = (c[s] ?? 0) + 1;
  }
  return [
    _Stat(label: 'Pending',    count: c['PENDING']    ?? 0, fg: _kAmber,  bg: _kAmberBg,  bd: _kAmberBd),
    _Stat(label: 'Confirmed',  count: c['CONFIRMED']  ?? 0, fg: _kP,      bg: _kPBg,      bd: _kPBd),
    _Stat(label: 'Production', count: c['PRODUCTION'] ?? 0, fg: _kOrange, bg: _kOrangeBg, bd: _kOrangeBd),
    _Stat(label: 'Packed',     count: c['PACKED']     ?? 0, fg: _kPurple, bg: _kPurpleBg, bd: _kPurpleBd),
    _Stat(label: 'Delivered',  count: (c['DELIVERED'] ?? 0) + (c['COMPLETED'] ?? 0),
        fg: _kGreen, bg: _kGreenBg, bd: _kGreenBd),
    _Stat(label: 'Cancelled',  count: c['CANCELLED']  ?? 0, fg: _kRed, bg: _kRedBg, bd: _kRedBd),
  ];
}

// ═════════════════════════════════════════════════════════════════════════════
// DashboardTabletView
// ═════════════════════════════════════════════════════════════════════════════
class DashboardTabletView extends ConsumerStatefulWidget {
  const DashboardTabletView({super.key});
  @override
  ConsumerState<DashboardTabletView> createState() => _DashboardTabletViewState();
}

class _DashboardTabletViewState extends ConsumerState<DashboardTabletView> {
  @override
  void initState() {
    super.initState();
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      final notification = message.notification;
      final android = message.notification?.android;
      if (notification != null && android != null) {
        flutterLocalNotificationsPlugin.show(
          notification.hashCode,
          notification.title,
          notification.body,
          NotificationDetails(
            android: AndroidNotificationDetails(
              channel.id, channel.name,
              channelDescription: channel.description,
              icon: '@mipmap/ic_launcher',
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final lw = (sw * 0.38).clamp(260.0, 420.0);

    final ordersAsync = ref.watch(recentOrdersProvider);
    final user  = ref.watch(currentUserProvider).asData?.value;
    final name  = (user?.employeeName ?? '...').replaceAll('_', ' ');
    final role  = (user?.role ?? '...').replaceAll('ROLE_', '').replaceAll('_', ' ');

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Left panel: order summary stats ───────────────────────────
            SizedBox(
              width: lw,
              child: DecoratedBox(
                decoration: const BoxDecoration(
                  color: _kWhite,
                  border: Border(right: BorderSide(color: _kBd, width: 0.5)),
                ),
                child: ordersAsync.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: _kP, strokeWidth: 2)),
                  error: (_, __) => _LeftError(sw: lw, sh: sh),
                  data: (orders) => _LeftPanel(
                    sw: lw, sh: sh, name: name, role: role, orders: orders,
                  ),
                ),
              ),
            ),

            // ── Right panel: recent orders list ───────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Panel header
                  Container(
                    height: (sh * 0.07).clamp(48.0, 60.0),
                    decoration: const BoxDecoration(
                      color: _kWhite,
                      border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.02),
                    child: Row(children: [
                      Text('Recent Orders', style: TextStyle(
                        fontSize: (sw * 0.02).clamp(15.0, 19.0),
                        fontWeight: FontWeight.w700,
                        color: _kT1, letterSpacing: -0.3,
                      )),
                      const Spacer(),
                      GestureDetector(
                        onTap: () => ref.invalidate(recentOrdersProvider),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.015, vertical: sw * 0.006),
                          decoration: BoxDecoration(
                            color: _kPBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                                color: _kP.withValues(alpha: 0.3), width: 0.5),
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.refresh_rounded,
                                size: (sw * 0.018).clamp(12.0, 16.0), color: _kP),
                            SizedBox(width: sw * 0.008),
                            Text('Refresh', style: TextStyle(
                                fontSize: (sw * 0.015).clamp(10.0, 12.5),
                                fontWeight: FontWeight.w600, color: _kP)),
                          ]),
                        ),
                      ),
                    ]),
                  ),

                  Expanded(
                    child: ordersAsync.when(
                      loading: () => const Center(
                          child: CircularProgressIndicator(
                              color: _kP, strokeWidth: 2)),
                      error: (_, __) => const SizedBox.shrink(),
                      data: (orders) => orders.isEmpty
                          ? _RightEmpty(sw: sw - lw, sh: sh)
                          : ListView.separated(
                        padding: EdgeInsets.all((sw - lw) * 0.03),
                        itemCount: orders.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: sh * 0.010),
                        itemBuilder: (ctx, i) => _RecentOrderRow(
                          order: orders[i],
                          sw: sw - lw,
                          sh: sh,
                          onTap: () => Navigator.push(ctx,
                              MaterialPageRoute(builder: (_) =>
                                  OrderViewPage(
                                      orderNumber:
                                      orders[i].orderNumber ?? ''))),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Left panel ────────────────────────────────────────────────────────────────
class _LeftPanel extends StatelessWidget {
  const _LeftPanel({required this.sw, required this.sh,
    required this.name, required this.role, required this.orders});
  final double sw, sh;
  final String name, role;
  final List<OrderModel> orders;

  @override
  Widget build(BuildContext context) {
    final stats = _buildStats(orders);
    return SingleChildScrollView(
      padding: EdgeInsets.all(sw * 0.07),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        Text(name, style: TextStyle(
          fontSize: (sw * 0.056).clamp(18.0, 26.0),
          fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.3,
        )),
        SizedBox(height: sh * 0.007),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.045, vertical: sh * 0.004),
          decoration: BoxDecoration(
            color: _kPBg, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kPBd, width: 0.5),
          ),
          child: Text(role, style: TextStyle(
              fontSize: (sw * 0.032).clamp(10.0, 13.0),
              fontWeight: FontWeight.w600, color: _kP)),
        ),
        SizedBox(height: sh * 0.04),

        _SectionLabel(text: 'Order Summary', sw: sw, sh: sh),
        SizedBox(height: sh * 0.018),

        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10,
            childAspectRatio: 1.6,
          ),
          itemCount: stats.length,
          itemBuilder: (_, i) => _StatCard(stat: stats[i], sw: sw, sh: sh),
        ),

        SizedBox(height: sh * 0.03),
        _SectionLabel(
            text: 'Total: ${orders.length} order${orders.length != 1 ? 's' : ''}',
            sw: sw, sh: sh),
      ]),
    );
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────
class _StatCard extends StatelessWidget {
  const _StatCard({required this.stat, required this.sw, required this.sh});
  final _Stat stat; final double sw, sh;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
        horizontal: sw * 0.06, vertical: sh * 0.018),
    decoration: BoxDecoration(
      color: stat.bg,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: stat.bd, width: 0.5),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('${stat.count}', style: TextStyle(
          fontSize: (sw * 0.1).clamp(24.0, 34.0),
          fontWeight: FontWeight.w800, color: stat.fg, height: 1.0,
        )),
        SizedBox(height: sh * 0.005),
        Text(stat.label, style: TextStyle(
          fontSize: (sw * 0.034).clamp(10.5, 13.0),
          fontWeight: FontWeight.w600, color: stat.fg,
        )),
      ],
    ),
  );
}

// ── Compact recent order row ──────────────────────────────────────────────────
class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({required this.order, required this.sw,
    required this.sh, required this.onTap});
  final OrderModel order; final double sw, sh; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st = _ss(order.status);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: sw * 0.045, vertical: sh * 0.014),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBd, width: 0.5),
        ),
        child: Row(children: [
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.orderNumber ?? 'N/A', style: TextStyle(
                fontSize: (sw * 0.036).clamp(12.0, 15.0),
                fontWeight: FontWeight.w700, color: _kT1,
              )),
              SizedBox(height: sh * 0.003),
              Text(order.dealer?.employeeName ?? 'N/A', style: TextStyle(
                fontSize: (sw * 0.028).clamp(10.0, 12.0), color: _kT3,
                fontWeight: FontWeight.w500,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          )),
          if (order.totalPrice != null) ...[
            Text('₹${_fmt(order.totalPrice)}', style: TextStyle(
              fontSize: (sw * 0.03).clamp(11.0, 13.5),
              fontWeight: FontWeight.w700, color: _kT1,
            )),
            SizedBox(width: sw * 0.03),
          ],
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.028, vertical: sh * 0.004),
            decoration: BoxDecoration(
              color: st.bg, borderRadius: BorderRadius.circular(4),
              border: Border.all(color: st.bd, width: 0.5),
            ),
            child: Text(order.status ?? '', style: TextStyle(
              fontSize: (sw * 0.024).clamp(9.0, 11.0),
              fontWeight: FontWeight.w700, color: st.fg, height: 1.0,
            )),
          ),
        ]),
      ),
    );
  }
}

// ── Section label ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.text, required this.sw, required this.sh});
  final String text; final double sw, sh;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.center,
    children: [
      Container(
        width: (sw * 0.009).clamp(3.0, 5.0),
        height: (sh * 0.022).clamp(14.0, 20.0),
        decoration: BoxDecoration(
          color: _kP,
          borderRadius: BorderRadius.circular((sw * 0.004).clamp(1.5, 2.5)),
        ),
      ),
      SizedBox(width: sw * 0.028),
      Text(text, style: TextStyle(
        fontSize: (sw * 0.038).clamp(12.0, 15.5),
        fontWeight: FontWeight.w700, color: _kT1, letterSpacing: 0.1,
      )),
    ],
  );
}

// ── Empty state (right panel) ─────────────────────────────────────────────────
class _RightEmpty extends StatelessWidget {
  const _RightEmpty({required this.sw, required this.sh});
  final double sw, sh;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.inbox_outlined,
          size: (sw * 0.08).clamp(40.0, 56.0),
          color: const Color(0xFFD1D5DB)),
      SizedBox(height: sh * 0.015),
      Text('No recent orders', style: TextStyle(
        fontSize: (sw * 0.028).clamp(13.0, 16.0),
        color: _kT3, fontWeight: FontWeight.w500,
      )),
    ],
  ));
}

// ── Error state (left panel) ──────────────────────────────────────────────────
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
