import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../feature/order/controller/order_controller.dart';
import '../../feature/order/screen/order_view_page.dart';
import '../../main.dart';
import '../../model/order_model.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF4F5F8);
const _kWhite    = Color(0xFFFFFFFF);
const _kBd       = Color(0xFFEEF0F4);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
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

const _kCardShadow = BoxShadow(
  color: Color(0x0F0F172A), offset: Offset(0, 6), blurRadius: 20,
);

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
// DashboardTabletView — Flowdesk-inspired soft card UI
// ═════════════════════════════════════════════════════════════════════════════
class DashboardTabletView extends ConsumerStatefulWidget {
  const DashboardTabletView({
    super.key,
    this.statsPanel,
    this.quickAccessPanel = const SizedBox.shrink(),
  });

  final Widget? statsPanel;
  final Widget  quickAccessPanel;

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
    final ordersAsync = ref.watch(recentOrdersProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: LayoutBuilder(builder: (ctx, c) {
          final w = c.maxWidth;
          final h = c.maxHeight;
          final isWide = w >= 900;
          final pad = (w * 0.022).clamp(12.0, 24.0);
          final gap = (w * 0.018).clamp(10.0, 20.0);

          // Bottom panel height — recent orders gets internal scroll
          final bottomMinH = isWide ? 360.0 : 320.0;
          final bottomMaxH = isWide ? 620.0 : 540.0;
          final bottomH = (h * 0.58).clamp(bottomMinH, bottomMaxH);

          final summary = _OrderSummaryCard(ordersAsync: ordersAsync, w: w);
          final recent = _RecentOrdersCard(
            ordersAsync: ordersAsync,
            w: w,
            onRefresh: () => ref.invalidate(recentOrdersProvider),
            onOpen: (o) => Navigator.push(
              ctx,
              MaterialPageRoute(builder: (_) =>
                OrderViewPage(orderNumber: o.orderNumber ?? '')),
            ),
          );

          return Scrollbar(
            child: SingleChildScrollView(
              physics: const ClampingScrollPhysics(),
              padding: EdgeInsets.all(pad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.statsPanel != null) ...[
                    _SectionCard(
                      title: 'Overview',
                      subtitle: 'Today at a glance',
                      w: w,
                      child: widget.statsPanel!,
                    ),
                    SizedBox(height: gap),
                  ],
                  _SectionCard(
                    title: 'Quick Access',
                    subtitle: 'Jump straight into a task',
                    w: w,
                    child: widget.quickAccessPanel,
                  ),
                  SizedBox(height: gap),
                  isWide
                    ? SizedBox(
                        height: bottomH,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(flex: 4, child: summary),
                            SizedBox(width: gap),
                            Expanded(flex: 6, child: recent),
                          ],
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          summary,
                          SizedBox(height: gap),
                          SizedBox(height: bottomH, child: recent),
                        ],
                      ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ── Generic section card ──────────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.title,
    this.subtitle,
    required this.child,
    required this.w,
  });

  final String  title;
  final String? subtitle;
  final Widget  child;
  final double  w;

  @override
  Widget build(BuildContext context) {
    final pad     = (w * 0.025).clamp(14.0, 22.0);
    final radius  = (w * 0.022).clamp(14.0, 20.0);
    final titleFs = (w * 0.018).clamp(14.0, 17.0);
    final subFs   = (w * 0.013).clamp(10.5, 12.5);

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [_kCardShadow],
      ),
      child: Padding(
        padding: EdgeInsets.all(pad),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: TextStyle(
              fontSize: titleFs, color: _kT1,
              fontWeight: FontWeight.w800, letterSpacing: -0.3,
            )),
            if (subtitle != null) ...[
              const SizedBox(height: 2),
              Text(subtitle!, style: TextStyle(
                fontSize: subFs, color: _kT3, fontWeight: FontWeight.w500,
              )),
            ],
            SizedBox(height: pad * 0.7),
            child,
          ],
        ),
      ),
    );
  }
}

// ── Order Summary card ────────────────────────────────────────────────────────
class _OrderSummaryCard extends StatelessWidget {
  const _OrderSummaryCard({required this.ordersAsync, required this.w});
  final AsyncValue<List<OrderModel>> ordersAsync;
  final double w;

  @override
  Widget build(BuildContext context) => ordersAsync.when(
    loading: () => _SectionCard(
      title: 'Order Summary',
      subtitle: 'Loading…',
      w: w,
      child: const SizedBox(
        height: 180,
        child: Center(
          child: CircularProgressIndicator(color: _kP, strokeWidth: 2)),
      ),
    ),
    error: (_, __) => _SectionCard(
      title: 'Order Summary',
      subtitle: 'Connection error',
      w: w,
      child: _ErrorBlock(w: w),
    ),
    data: (orders) {
      final stats = _buildStats(orders);
      return _SectionCard(
        title: 'Order Summary',
        subtitle: '${orders.length} order${orders.length != 1 ? 's' : ''} tracked',
        w: w,
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1.3,
          ),
          itemCount: stats.length,
          itemBuilder: (_, i) => _StatusTile(stat: stats[i], w: w),
        ),
      );
    },
  );
}

// ── Status tile (Order Summary grid) ──────────────────────────────────────────
class _StatusTile extends StatelessWidget {
  const _StatusTile({required this.stat, required this.w});
  final _Stat stat; final double w;

  @override
  Widget build(BuildContext context) {
    final radius  = (w * 0.012).clamp(8.0, 12.0);
    final countFs = (w * 0.022).clamp(16.0, 22.0);
    final labelFs = (w * 0.011).clamp(9.5, 11.5);
    final dotSz   = (w * 0.010).clamp(7.0, 9.0);

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 9, 10, 9),
      decoration: BoxDecoration(
        color: stat.bg,
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(children: [
            Container(
              width: dotSz, height: dotSz,
              decoration: BoxDecoration(
                color: stat.fg, shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text('${stat.count}', style: TextStyle(
              fontSize: countFs,
              fontWeight: FontWeight.w800,
              color: stat.fg,
              height: 1.0,
              letterSpacing: -0.3,
            )),
          ]),
          Text(stat.label, style: TextStyle(
            fontSize: labelFs,
            fontWeight: FontWeight.w600,
            color: stat.fg,
            letterSpacing: 0.1,
            height: 1.1,
          ), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
}

// ── Recent Orders card ────────────────────────────────────────────────────────
class _RecentOrdersCard extends StatelessWidget {
  const _RecentOrdersCard({
    required this.ordersAsync,
    required this.w,
    required this.onRefresh,
    required this.onOpen,
  });
  final AsyncValue<List<OrderModel>> ordersAsync;
  final double w;
  final VoidCallback onRefresh;
  final void Function(OrderModel) onOpen;

  @override
  Widget build(BuildContext context) {
    final pad     = (w * 0.025).clamp(14.0, 22.0);
    final radius  = (w * 0.022).clamp(14.0, 20.0);
    final titleFs = (w * 0.018).clamp(14.0, 17.0);
    final subFs   = (w * 0.013).clamp(10.5, 12.5);
    final count   = ordersAsync.asData?.value.length ?? 0;

    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular(radius),
        boxShadow: const [_kCardShadow],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: EdgeInsets.fromLTRB(pad, pad, pad, pad * 0.55),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Recent Orders', style: TextStyle(
                      fontSize: titleFs, color: _kT1,
                      fontWeight: FontWeight.w800, letterSpacing: -0.3,
                    )),
                    const SizedBox(height: 2),
                    Text('Latest activity · $count', style: TextStyle(
                      fontSize: subFs, color: _kT3,
                      fontWeight: FontWeight.w500,
                    )),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRefresh,
                behavior: HitTestBehavior.opaque,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: _kPBg,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.refresh_rounded,
                        size: subFs + 3, color: _kP),
                    const SizedBox(width: 4),
                    Text('Refresh', style: TextStyle(
                      fontSize: subFs,
                      fontWeight: FontWeight.w700,
                      color: _kP,
                    )),
                  ]),
                ),
              ),
            ]),
          ),
          const Divider(height: 1, color: _kBd),
          Expanded(
            child: ordersAsync.when(
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: _kP, strokeWidth: 2)),
              error: (_, __) => Padding(
                padding: EdgeInsets.all(pad),
                child: _ErrorBlock(w: w),
              ),
              data: (orders) => orders.isEmpty
                ? _EmptyState(w: w)
                : ListView.separated(
                    padding: EdgeInsets.fromLTRB(
                        pad, pad * 0.6, pad, pad),
                    itemCount: orders.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: 8),
                    itemBuilder: (_, i) => _RecentOrderRow(
                      order: orders[i],
                      w: w,
                      onTap: () => onOpen(orders[i]),
                    ),
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Recent order row — Flowdesk-style with colored accent stripe ──────────────
class _RecentOrderRow extends StatelessWidget {
  const _RecentOrderRow({
    required this.order, required this.w, required this.onTap,
  });
  final OrderModel order; final double w; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st       = _ss(order.status);
    final radius   = (w * 0.012).clamp(10.0, 14.0);
    final orderFs  = (w * 0.016).clamp(13.0, 15.5);
    final dealerFs = (w * 0.013).clamp(11.0, 12.5);
    final priceFs  = (w * 0.016).clamp(12.5, 15.0);
    final chipFs   = (w * 0.011).clamp(9.5, 11.0);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 4, color: st.fg),
              Expanded(
                child: Container(
                  color: st.bg,
                  padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
                  child: Row(children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(order.orderNumber ?? 'N/A', style: TextStyle(
                            fontSize: orderFs,
                            fontWeight: FontWeight.w800,
                            color: _kT1,
                            letterSpacing: -0.2,
                          ), maxLines: 1, overflow: TextOverflow.ellipsis),
                          const SizedBox(height: 2),
                          Text(order.dealer?.employeeName ?? 'N/A',
                            style: TextStyle(
                              fontSize: dealerFs,
                              color: _kT3,
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (order.totalPrice != null)
                          Text('₹${_fmt(order.totalPrice)}', style: TextStyle(
                            fontSize: priceFs,
                            fontWeight: FontWeight.w800,
                            color: _kT1,
                            letterSpacing: -0.2,
                          )),
                        const SizedBox(height: 5),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: _kWhite,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: st.bd, width: 0.7),
                          ),
                          child: Text(order.status ?? '', style: TextStyle(
                            fontSize: chipFs,
                            fontWeight: FontWeight.w700,
                            color: st.fg,
                            height: 1.0,
                            letterSpacing: 0.2,
                          )),
                        ),
                      ],
                    ),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Empty state ───────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    final iconSz = (w * 0.05).clamp(36.0, 52.0);
    final fs     = (w * 0.014).clamp(12.0, 14.0);
    final subFs  = (w * 0.012).clamp(10.0, 12.0);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: iconSz * 1.7, height: iconSz * 1.7,
            decoration: const BoxDecoration(
              color: _kBg, shape: BoxShape.circle,
            ),
            child: Icon(Icons.inbox_rounded,
                size: iconSz, color: const Color(0xFFCBD5E1)),
          ),
          const SizedBox(height: 14),
          Text('No recent orders', style: TextStyle(
            fontSize: fs, color: _kT2, fontWeight: FontWeight.w700,
          )),
          const SizedBox(height: 4),
          Text('Orders will appear here as they come in',
            style: TextStyle(
              fontSize: subFs, color: _kT3, fontWeight: FontWeight.w500,
            )),
        ],
      ),
    );
  }
}

// ── Error block ───────────────────────────────────────────────────────────────
class _ErrorBlock extends StatelessWidget {
  const _ErrorBlock({required this.w});
  final double w;

  @override
  Widget build(BuildContext context) {
    final iconSz = (w * 0.025).clamp(18.0, 24.0);
    final fs     = (w * 0.014).clamp(12.0, 14.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _kRedBg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.wifi_off_rounded, color: _kRed, size: iconSz),
        const SizedBox(width: 10),
        Expanded(child: Text('Could not load data', style: TextStyle(
          fontSize: fs, color: _kRed, fontWeight: FontWeight.w600,
        ))),
      ]),
    );
  }
}
