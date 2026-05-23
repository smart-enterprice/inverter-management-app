// FutureProvider.autoDispose.family wrappers for every endpoint. Each is
// keyed by an immutable params record so equal params hit the same cache
// entry. The screen layer composes these via ref.watch.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/analytics_models.dart';
import '../data/analytics_repository.dart';

// ─── shared param classes (== / hashCode for proper family keys) ───────────
class SummaryParams {
  final DateTime from, to;
  final String? dealerId, salesmanId;
  const SummaryParams({
    required this.from, required this.to,
    this.dealerId, this.salesmanId,
  });
  @override
  bool operator ==(Object other) =>
      other is SummaryParams &&
      from.isAtSameMomentAs(other.from) &&
      to.isAtSameMomentAs(other.to) &&
      dealerId == other.dealerId && salesmanId == other.salesmanId;
  @override
  int get hashCode => Object.hash(from, to, dealerId, salesmanId);
}

class TrendParams {
  final DateTime from, to;
  final String interval;
  final String? dealerId, salesmanId;
  const TrendParams({
    required this.from, required this.to, required this.interval,
    this.dealerId, this.salesmanId,
  });
  @override
  bool operator ==(Object other) =>
      other is TrendParams &&
      from.isAtSameMomentAs(other.from) &&
      to.isAtSameMomentAs(other.to) &&
      interval == other.interval &&
      dealerId == other.dealerId && salesmanId == other.salesmanId;
  @override
  int get hashCode => Object.hash(from, to, interval, dealerId, salesmanId);
}

class TopMetricParams {
  final DateTime from, to;
  final int limit;
  final String metric;
  final String? dealerId, salesmanId;
  const TopMetricParams({
    required this.from, required this.to,
    this.limit = 10, this.metric = 'revenue',
    this.dealerId, this.salesmanId,
  });
  @override
  bool operator ==(Object other) =>
      other is TopMetricParams &&
      from.isAtSameMomentAs(other.from) &&
      to.isAtSameMomentAs(other.to) &&
      limit == other.limit && metric == other.metric &&
      dealerId == other.dealerId && salesmanId == other.salesmanId;
  @override
  int get hashCode =>
      Object.hash(from, to, limit, metric, dealerId, salesmanId);
}

class TopDealersParams {
  final DateTime from, to;
  final int limit;
  final String? salesmanId;
  const TopDealersParams({
    required this.from, required this.to,
    this.limit = 10, this.salesmanId,
  });
  @override
  bool operator ==(Object other) =>
      other is TopDealersParams &&
      from.isAtSameMomentAs(other.from) &&
      to.isAtSameMomentAs(other.to) &&
      limit == other.limit && salesmanId == other.salesmanId;
  @override
  int get hashCode => Object.hash(from, to, limit, salesmanId);
}

class TopSalesmenParams {
  final DateTime from, to;
  final int limit;
  final String? dealerId;
  const TopSalesmenParams({
    required this.from, required this.to,
    this.limit = 10, this.dealerId,
  });
  @override
  bool operator ==(Object other) =>
      other is TopSalesmenParams &&
      from.isAtSameMomentAs(other.from) &&
      to.isAtSameMomentAs(other.to) &&
      limit == other.limit && dealerId == other.dealerId;
  @override
  int get hashCode => Object.hash(from, to, limit, dealerId);
}

class AchievementParams {
  final DateTime from, to;
  final String? dealerId;
  const AchievementParams({
    required this.from, required this.to, this.dealerId,
  });
  @override
  bool operator ==(Object other) =>
      other is AchievementParams &&
      from.isAtSameMomentAs(other.from) &&
      to.isAtSameMomentAs(other.to) &&
      dealerId == other.dealerId;
  @override
  int get hashCode => Object.hash(from, to, dealerId);
}

// ─── Providers ────────────────────────────────────────────────────────────
final summaryProvider = FutureProvider.autoDispose
    .family<AnalyticsSummary, SummaryParams>((ref, p) async {
  return ref.watch(analyticsRepositoryProvider).summary(
        from: p.from, to: p.to,
        dealerId: p.dealerId, salesmanId: p.salesmanId,
      );
});

final salesTrendProvider = FutureProvider.autoDispose
    .family<TrendSeries, TrendParams>((ref, p) async {
  return ref.watch(analyticsRepositoryProvider).salesTrend(
        from: p.from, to: p.to, interval: p.interval,
        dealerId: p.dealerId, salesmanId: p.salesmanId,
      );
});

final topProductsProvider = FutureProvider.autoDispose
    .family<List<TopProductItem>, TopMetricParams>((ref, p) async {
  return ref.watch(analyticsRepositoryProvider).topProducts(
        from: p.from, to: p.to, limit: p.limit, metric: p.metric,
        dealerId: p.dealerId, salesmanId: p.salesmanId,
      );
});

final topBrandsProvider = FutureProvider.autoDispose
    .family<List<TopBrandItem>, TopMetricParams>((ref, p) async {
  return ref.watch(analyticsRepositoryProvider).topBrands(
        from: p.from, to: p.to, limit: p.limit, metric: p.metric,
        dealerId: p.dealerId, salesmanId: p.salesmanId,
      );
});

final topDealersProvider = FutureProvider.autoDispose
    .family<List<TopDealerItem>, TopDealersParams>((ref, p) async {
  return ref.watch(analyticsRepositoryProvider).topDealers(
        from: p.from, to: p.to, limit: p.limit, salesmanId: p.salesmanId,
      );
});

final topSalesmenProvider = FutureProvider.autoDispose
    .family<List<TopSalesmanItem>, TopSalesmenParams>((ref, p) async {
  return ref.watch(analyticsRepositoryProvider).topSalesmen(
        from: p.from, to: p.to, limit: p.limit, dealerId: p.dealerId,
      );
});

final achievementProvider = FutureProvider.autoDispose
    .family<AchievementResponse, AchievementParams>((ref, p) async {
  return ref.watch(analyticsRepositoryProvider).salesmanAchievement(
        from: p.from, to: p.to, dealerId: p.dealerId,
      );
});
