// Shared filter state for the analytics screen: date range + dealer +
// salesman + sales-trend interval + chart-type toggles. Held by one
// StateNotifier so any widget can read/write without prop-drilling.

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../util/format.dart';

enum AnalyticsRange { today, last7, last30, mtd, lastMonth, custom }

enum TrendInterval { day, week, month }

extension TrendIntervalApi on TrendInterval {
  String get api {
    switch (this) {
      case TrendInterval.day: return 'day';
      case TrendInterval.week: return 'week';
      case TrendInterval.month: return 'month';
    }
  }
  String get label {
    switch (this) {
      case TrendInterval.day: return 'Day';
      case TrendInterval.week: return 'Week';
      case TrendInterval.month: return 'Month';
    }
  }
}

enum TrendChartType { mixed, area, bar, line }

@immutable
class AnalyticsFilter {
  final AnalyticsRange range;
  final DateTime from;
  final DateTime to;
  final String? dealerId;
  final String? dealerLabel;
  final String? salesmanId;
  final String? salesmanLabel;
  final TrendInterval interval;
  final TrendChartType chartType;

  const AnalyticsFilter({
    required this.range,
    required this.from,
    required this.to,
    this.dealerId,
    this.dealerLabel,
    this.salesmanId,
    this.salesmanLabel,
    this.interval = TrendInterval.day,
    this.chartType = TrendChartType.mixed,
  });

  AnalyticsFilter copyWith({
    AnalyticsRange? range,
    DateTime? from,
    DateTime? to,
    String? dealerId,
    String? dealerLabel,
    bool clearDealer = false,
    String? salesmanId,
    String? salesmanLabel,
    bool clearSalesman = false,
    TrendInterval? interval,
    TrendChartType? chartType,
  }) {
    return AnalyticsFilter(
      range: range ?? this.range,
      from: from ?? this.from,
      to: to ?? this.to,
      dealerId: clearDealer ? null : (dealerId ?? this.dealerId),
      dealerLabel: clearDealer ? null : (dealerLabel ?? this.dealerLabel),
      salesmanId: clearSalesman ? null : (salesmanId ?? this.salesmanId),
      salesmanLabel: clearSalesman ? null : (salesmanLabel ?? this.salesmanLabel),
      interval: interval ?? this.interval,
      chartType: chartType ?? this.chartType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AnalyticsFilter &&
          range == other.range &&
          from.isAtSameMomentAs(other.from) &&
          to.isAtSameMomentAs(other.to) &&
          dealerId == other.dealerId &&
          salesmanId == other.salesmanId &&
          interval == other.interval &&
          chartType == other.chartType;

  @override
  int get hashCode => Object.hash(
      range, from, to, dealerId, salesmanId, interval, chartType);
}

({DateTime from, DateTime to}) rangeBounds(AnalyticsRange r, DateTime now) {
  final today = DateTime(now.year, now.month, now.day);
  switch (r) {
    case AnalyticsRange.today:
      return (from: today, to: today);
    case AnalyticsRange.last7:
      return (from: today.subtract(const Duration(days: 6)), to: today);
    case AnalyticsRange.last30:
      return (from: today.subtract(const Duration(days: 29)), to: today);
    case AnalyticsRange.mtd:
      return (from: monthStart(today), to: today);
    case AnalyticsRange.lastMonth:
      final firstThis = monthStart(today);
      final lastPrev = firstThis.subtract(const Duration(days: 1));
      return (from: monthStart(lastPrev), to: lastPrev);
    case AnalyticsRange.custom:
      return (from: today, to: today);
  }
}

class AnalyticsFilterNotifier extends StateNotifier<AnalyticsFilter> {
  AnalyticsFilterNotifier() : super(_initial());

  static AnalyticsFilter _initial() {
    final r = rangeBounds(AnalyticsRange.last7, DateTime.now());
    return AnalyticsFilter(
      range: AnalyticsRange.last7,
      from: r.from,
      to: r.to,
    );
  }

  void setRange(AnalyticsRange r) {
    if (r == AnalyticsRange.custom) {
      state = state.copyWith(range: r); // keep current from/to
      return;
    }
    final b = rangeBounds(r, DateTime.now());
    state = state.copyWith(range: r, from: b.from, to: b.to);
  }

  void setCustom(DateTime from, DateTime to) {
    state = state.copyWith(
        range: AnalyticsRange.custom, from: from, to: to);
  }

  void setDealer({required String? id, required String? label}) {
    if (id == null || id.isEmpty) {
      state = state.copyWith(clearDealer: true);
    } else {
      state = state.copyWith(dealerId: id, dealerLabel: label);
    }
  }

  void setSalesman({required String? id, required String? label}) {
    if (id == null || id.isEmpty) {
      state = state.copyWith(clearSalesman: true);
    } else {
      state = state.copyWith(salesmanId: id, salesmanLabel: label);
    }
  }

  void setInterval(TrendInterval i) =>
      state = state.copyWith(interval: i);

  void setChartType(TrendChartType t) =>
      state = state.copyWith(chartType: t);

  void clearAll() {
    state = _initial();
  }
}

final analyticsFilterProvider =
    StateNotifierProvider<AnalyticsFilterNotifier, AnalyticsFilter>(
        (ref) => AnalyticsFilterNotifier());

// ─── Independent month selector for the achievement chart ─────────────────
class AchievementMonthNotifier extends StateNotifier<DateTime> {
  AchievementMonthNotifier()
      : super(DateTime(DateTime.now().year, DateTime.now().month, 1));

  void prev() {
    state = DateTime(state.year, state.month - 1, 1);
  }

  /// Don't allow going beyond the current month.
  void next() {
    final now = DateTime.now();
    final cap = DateTime(now.year, now.month, 1);
    final next = DateTime(state.year, state.month + 1, 1);
    if (!next.isAfter(cap)) state = next;
  }

  bool get isCurrentMonth {
    final now = DateTime.now();
    return state.year == now.year && state.month == now.month;
  }
}

final achievementMonthProvider =
    StateNotifierProvider<AchievementMonthNotifier, DateTime>(
        (ref) => AchievementMonthNotifier());
