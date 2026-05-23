// Single analytics screen. Composes the KPI strip, charts, leaderboards and
// achievement card. Hard role-guard: anyone without viewAnalytics sees the
// AccessDeniedScreen (which is also reachable through deep links / nav bugs).
//
// Cached-list pattern is enforced inside every card widget — this file just
// orchestrates them inside a single scrollable column.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/role/app_role.dart';
import '../../application/analytics_providers.dart';
import '../../application/date_range_provider.dart';
import '../../data/analytics_models.dart';
import '../../util/format.dart';
import '../widgets/_tokens.dart';
import '../widgets/achievement_chart.dart';
import '../widgets/dealer_filter.dart';
import '../widgets/kpi_card.dart';
import '../widgets/pipeline_chart.dart';
import '../widgets/range_chips.dart';
import '../widgets/sales_trend_chart.dart';
import '../widgets/top_brands_chart.dart';
import '../widgets/top_dealers_table.dart';
import '../widgets/top_products_chart.dart';
import '../widgets/top_salesmen_table.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final role = ref.watch(roleNotifierProvider);
    if (!AppPermissions.canAccess(role, AppFeature.viewAnalytics)) {
      return const AccessDeniedScreen(
          message: "Analytics is restricted to managers and admins.");
    }
    return const _AnalyticsBody();
  }
}

class _AnalyticsBody extends ConsumerWidget {
  const _AnalyticsBody();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.sizeOf(context).width;
    final filter = ref.watch(analyticsFilterProvider);

    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(child: Column(children: [
        // ── Header ─────────────────────────────────────────────────────────
        Container(color: kSurface, child: Column(children: [
          Padding(
            padding: EdgeInsets.fromLTRB(sw * 0.04,
                MediaQuery.sizeOf(context).height * 0.015,
                sw * 0.04,
                MediaQuery.sizeOf(context).height * 0.012),
            child: Row(children: [
              _CircleIcon(
                icon: Icons.arrow_back_ios_rounded,
                onTap: () => Navigator.pop(context),
              ),
              SizedBox(width: sw * 0.03),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Analytics', style: TextStyle(
                    fontSize: (sw * 0.046).clamp(15.0, 22.0),
                    fontWeight: FontWeight.w800,
                    color: kT1, letterSpacing: -0.3,
                  )),
                  Text('Sales, pipeline & performance',
                      style: TextStyle(
                          fontSize: (sw * 0.028).clamp(9.5, 12.0),
                          color: kT4, fontWeight: FontWeight.w500)),
                ],
              )),
              _CircleIcon(
                icon: Icons.refresh_rounded,
                onTap: () => _refreshAll(ref),
              ),
            ]),
          ),
          RangeChipsRow(onFilterTap: () => showAnalyticsFilterSheet(context)),
          if (filter.range == AnalyticsRange.custom || filter.dealerId != null)
            _ActiveFilterBanner(filter: filter, ref: ref),
          Container(height: 0.5, color: kBd),
        ])),

        // ── Body ───────────────────────────────────────────────────────────
        Expanded(child: RefreshIndicator(
          color: kP, backgroundColor: kSurface,
          onRefresh: () async => _refreshAll(ref),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                sw * 0.04, sw * 0.025, sw * 0.04, sw * 0.05),
            child: Column(children: [
              _KpiStrip(),
              SizedBox(height: sw * 0.03),
              SalesTrendCard(),
              SizedBox(height: sw * 0.03),
              PipelineCard(),
              SizedBox(height: sw * 0.03),
              TopProductsCard(),
              SizedBox(height: sw * 0.03),
              TopBrandsCard(),
              SizedBox(height: sw * 0.03),
              TopDealersCard(),
              if (filter.dealerId == null) SizedBox(height: sw * 0.03),
              TopSalesmenCard(),
              SizedBox(height: sw * 0.03),
              AchievementCard(),
            ]),
          ),
        )),
      ])),
    );
  }

  // Invalidate every analytics provider so a single tap refreshes the page.
  void _refreshAll(WidgetRef ref) {
    ref.invalidate(summaryProvider);
    ref.invalidate(salesTrendProvider);
    ref.invalidate(topProductsProvider);
    ref.invalidate(topBrandsProvider);
    ref.invalidate(topDealersProvider);
    ref.invalidate(topSalesmenProvider);
    ref.invalidate(achievementProvider);
  }
}

// ─── KPI strip ────────────────────────────────────────────────────────────
class _KpiStrip extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(analyticsFilterProvider);
    final current = ref.watch(summaryProvider(SummaryParams(
      from: filter.from, to: filter.to,
      dealerId: filter.dealerId, salesmanId: filter.salesmanId,
    )));

    final prev = previousPeriod(filter.from, filter.to);
    final previous = ref.watch(summaryProvider(SummaryParams(
      from: prev.from, to: prev.to,
      dealerId: filter.dealerId, salesmanId: filter.salesmanId,
    )));

    // valueOrNull (NOT .value) — Riverpod's AsyncValue.value rethrows when
    // the state is AsyncError, which would explode the build before our
    // null-check below could swap in the error card.
    final c = current.valueOrNull;
    final p = previous.valueOrNull;

    // Initial load — show a single placeholder so the strip doesn't appear
    // empty. Individual cards keep their own caches.
    if (c == null) {
      if (current.hasError) {
        return const AnalyticsCard(child: ErrorCardBody(
            message: 'Couldn\'t load KPIs'));
      }
      return const AnalyticsCard(child: LoadingCardBody(height: 220));
    }

    final tiles = <Widget>[
      KpiCard(
        label: 'Orders',
        value: formatCount(c.ordersTotal),
        icon: Icons.shopping_bag_outlined,
        delta: c.ordersTotal,
        previousValue: p?.ordersTotal,
        deltaIsCount: true,
      ),
      KpiCard(
        label: 'Bookings',
        value: formatINR(c.revenueBooked),
        icon: Icons.currency_rupee_rounded,
        iconColor: kGreen, iconBg: kGreenBg,
        delta: c.revenueBooked,
        previousValue: p?.revenueBooked,
      ),
      KpiCard(
        label: 'Delivered',
        value: formatINR(c.revenueDelivered),
        icon: Icons.local_shipping_outlined,
        iconColor: kViolet, iconBg: const Color(0xFFF5F3FF),
        delta: c.revenueDelivered,
        previousValue: p?.revenueDelivered,
      ),
      KpiCard(
        label: 'Cancelled',
        value: formatINR(c.revenueCancelled),
        icon: Icons.cancel_outlined,
        iconColor: kRose, iconBg: const Color(0xFFFFF1F2),
        delta: c.revenueCancelled,
        previousValue: p?.revenueCancelled,
      ),
      KpiCard(
        label: 'Pending',
        value: formatINR(c.revenuePending),
        icon: Icons.hourglass_bottom_rounded,
        iconColor: kAmber, iconBg: kAmberBg,
        delta: c.revenuePending,
        previousValue: p?.revenuePending,
      ),
      KpiCard(
        label: 'Paid',
        value: formatINR(c.revenuePaid),
        icon: Icons.payments_outlined,
        iconColor: kP, iconBg: kPBg,
        delta: c.revenuePaid,
        previousValue: p?.revenuePaid,
      ),
      KpiCard(
        label: 'Due',
        value: formatINR(c.revenueDue),
        icon: Icons.error_outline,
        iconColor: kRed, iconBg: kRedBg,
        delta: c.revenueDue,
        previousValue: p?.revenueDue,
      ),
      KpiCard(
        label: 'Avg Order',
        value: formatINR(c.ordersTotal == 0
            ? 0 : c.revenueBooked / c.ordersTotal),
        icon: Icons.straighten_rounded,
        iconColor: kIndigo, iconBg: const Color(0xFFEEF2FF),
      ),
    ];

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (!c.isConserved)
        Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.sizeOf(context).width * 0.022),
          child: _ConservationWarning(summary: c),
        ),
      KpiGrid(tiles: tiles),
    ]);
  }
}

class _ConservationWarning extends StatelessWidget {
  const _ConservationWarning({required this.summary});
  final AnalyticsSummary summary;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.035, vertical: sw * 0.025),
      decoration: BoxDecoration(
        color: kAmberBg, borderRadius: BorderRadius.circular(10),
        border: Border.all(color: kAmberBd, width: 0.5),
      ),
      child: Row(children: [
        Icon(Icons.info_outline_rounded,
            size: (sw * 0.04).clamp(14.0, 18.0), color: kAmber),
        SizedBox(width: sw * 0.022),
        Expanded(child: Text(
          'Numbers don\'t balance — bookings ≠ delivered + cancelled + pending. '
          'Reach out to support if this persists.',
          style: TextStyle(
              fontSize: (sw * 0.028).clamp(9.5, 11.5),
              color: kAmber, fontWeight: FontWeight.w600, height: 1.3))),
      ]),
    );
  }
}

// ─── Filter banner ────────────────────────────────────────────────────────
class _ActiveFilterBanner extends StatelessWidget {
  const _ActiveFilterBanner({required this.filter, required this.ref});
  final AnalyticsFilter filter;
  final WidgetRef ref;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final df = DateFormat('d MMM');
    final parts = <String>[];
    if (filter.range == AnalyticsRange.custom) {
      parts.add('${df.format(filter.from)} → ${df.format(filter.to)}');
    }
    if (filter.dealerLabel != null && filter.dealerLabel!.isNotEmpty) {
      parts.add('Dealer: ${filter.dealerLabel}');
    }
    return Container(
      width: double.infinity,
      color: kPBg,
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: sw * 0.022),
      child: Row(children: [
        Icon(Icons.tune_rounded,
            size: (sw * 0.04).clamp(14.0, 17.0), color: kP),
        SizedBox(width: sw * 0.022),
        Expanded(child: Text(parts.join(' · '),
            maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0),
                color: kP, fontWeight: FontWeight.w700))),
        GestureDetector(
          onTap: () => ref.read(analyticsFilterProvider.notifier).clearAll(),
          child: Text('Clear', style: TextStyle(
              fontSize: (sw * 0.03).clamp(10.0, 13.0),
              color: kRed, fontWeight: FontWeight.w700)),
        ),
      ]),
    );
  }
}

// ─── Header circle icon ────────────────────────────────────────────────────
class _CircleIcon extends StatelessWidget {
  const _CircleIcon({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final s = (sw * 0.1).clamp(34.0, 44.0);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: s, height: s,
        decoration: BoxDecoration(
            color: kBg, shape: BoxShape.circle,
            border: Border.all(color: kBd, width: 0.5)),
        child: Icon(icon,
            size: (sw * 0.045).clamp(15.0, 20.0), color: kT2),
      ),
    );
  }
}
