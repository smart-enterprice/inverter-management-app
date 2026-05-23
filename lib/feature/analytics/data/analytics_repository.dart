// Thin pass-through repository so future caching/logging/aggregation has a
// single place to hook in. Mirrors the OrderRepository pattern.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'analytics_api.dart';
import 'analytics_models.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  return AnalyticsRepository(ref.watch(analyticsApiProvider));
});

class AnalyticsRepository {
  AnalyticsRepository(this._api);
  final AnalyticsApi _api;

  Future<AnalyticsSummary> summary({
    required DateTime from,
    required DateTime to,
    String? dealerId,
    String? salesmanId,
  }) =>
      _api.getSummary(
          from: from, to: to, dealerId: dealerId, salesmanId: salesmanId);

  Future<TrendSeries> salesTrend({
    required DateTime from,
    required DateTime to,
    required String interval,
    String? dealerId,
    String? salesmanId,
  }) =>
      _api.getSalesTrend(
          from: from, to: to, interval: interval,
          dealerId: dealerId, salesmanId: salesmanId);

  Future<List<TopProductItem>> topProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
    String metric = 'revenue',
    String? dealerId,
    String? salesmanId,
  }) =>
      _api.getTopProducts(
          from: from, to: to, limit: limit, metric: metric,
          dealerId: dealerId, salesmanId: salesmanId);

  Future<List<TopBrandItem>> topBrands({
    required DateTime from,
    required DateTime to,
    int limit = 10,
    String metric = 'revenue',
    String? dealerId,
    String? salesmanId,
  }) =>
      _api.getTopBrands(
          from: from, to: to, limit: limit, metric: metric,
          dealerId: dealerId, salesmanId: salesmanId);

  Future<List<TopDealerItem>> topDealers({
    required DateTime from,
    required DateTime to,
    int limit = 10,
    String? salesmanId,
  }) =>
      _api.getTopDealers(
          from: from, to: to, limit: limit, salesmanId: salesmanId);

  Future<List<TopSalesmanItem>> topSalesmen({
    required DateTime from,
    required DateTime to,
    int limit = 10,
    String? dealerId,
  }) =>
      _api.getTopSalesmen(
          from: from, to: to, limit: limit, dealerId: dealerId);

  Future<AchievementResponse> salesmanAchievement({
    required DateTime from,
    required DateTime to,
    String? dealerId,
  }) =>
      _api.getSalesmanAchievement(
          from: from, to: to, dealerId: dealerId);
}
