// Dio wrapper for the 7 analytics endpoints. Lives one layer above
// dio_client.dart so the route paths stay in one place. Unwraps the standard
// {success, data, message} envelope.

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/app_exception.dart';
import '../../../core/network/dio_client.dart';
import '../util/format.dart';
import 'analytics_models.dart';

final analyticsApiProvider = Provider<AnalyticsApi>((ref) {
  return AnalyticsApi(ref.watch(dioClientProvider));
});

class AnalyticsApi {
  AnalyticsApi(this._dio);
  final Dio _dio;

  // ── envelope unwrap ────────────────────────────────────────────────────────
  Map<String, dynamic> _unwrap(Response<dynamic> res, {required String fallback}) {
    final body = res.data;
    if (body is! Map<String, dynamic>) {
      throw AppException('Unexpected analytics response shape',
          statusCode: res.statusCode);
    }
    if (body['success'] == false) {
      throw AppException(
          body['message']?.toString() ?? fallback,
          statusCode: res.statusCode);
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return <String, dynamic>{};
  }

  Map<String, dynamic> _baseParams({
    required DateTime from,
    required DateTime to,
    String? dealerId,
    String? salesmanId,
    Map<String, dynamic>? extra,
  }) {
    final p = <String, dynamic>{
      'from': localYmd(from),
      'to': localYmd(to),
    };
    if (dealerId != null && dealerId.isNotEmpty) p['dealer_id'] = dealerId;
    if (salesmanId != null && salesmanId.isNotEmpty) p['salesman_id'] = salesmanId;
    if (extra != null) p.addAll(extra);
    return p;
  }

  // ── 1. summary ────────────────────────────────────────────────────────────
  Future<AnalyticsSummary> getSummary({
    required DateTime from,
    required DateTime to,
    String? dealerId,
    String? salesmanId,
  }) =>
      guardDio(() async {
        final res = await _dio.get('/analytics/summary',
            queryParameters: _baseParams(
                from: from, to: to,
                dealerId: dealerId, salesmanId: salesmanId));
        return AnalyticsSummary.fromJson(
            _unwrap(res, fallback: 'Failed to load summary'));
      });

  // ── 2. sales trend ────────────────────────────────────────────────────────
  Future<TrendSeries> getSalesTrend({
    required DateTime from,
    required DateTime to,
    required String interval, // day | week | month
    String? dealerId,
    String? salesmanId,
  }) =>
      guardDio(() async {
        final res = await _dio.get('/analytics/sales-trend',
            queryParameters: _baseParams(
                from: from, to: to,
                dealerId: dealerId, salesmanId: salesmanId,
                extra: {'interval': interval}));
        return TrendSeries.fromJson(
            _unwrap(res, fallback: 'Failed to load sales trend'));
      });

  // ── 3. top products ───────────────────────────────────────────────────────
  Future<List<TopProductItem>> getTopProducts({
    required DateTime from,
    required DateTime to,
    int limit = 10,
    String metric = 'revenue',
    String? dealerId,
    String? salesmanId,
  }) =>
      guardDio(() async {
        final res = await _dio.get('/analytics/top-products',
            queryParameters: _baseParams(
                from: from, to: to,
                dealerId: dealerId, salesmanId: salesmanId,
                extra: {'limit': limit, 'metric': metric}));
        final data = _unwrap(res, fallback: 'Failed to load top products');
        final items = (data['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => TopProductItem.fromJson(e.cast<String, dynamic>()))
            .toList();
        return items;
      });

  // ── 4. top brands ─────────────────────────────────────────────────────────
  Future<List<TopBrandItem>> getTopBrands({
    required DateTime from,
    required DateTime to,
    int limit = 10,
    String metric = 'revenue',
    String? dealerId,
    String? salesmanId,
  }) =>
      guardDio(() async {
        final res = await _dio.get('/analytics/top-brands',
            queryParameters: _baseParams(
                from: from, to: to,
                dealerId: dealerId, salesmanId: salesmanId,
                extra: {'limit': limit, 'metric': metric}));
        final data = _unwrap(res, fallback: 'Failed to load top brands');
        final items = (data['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => TopBrandItem.fromJson(e.cast<String, dynamic>()))
            .toList();
        return items;
      });

  // ── 5. top dealers ────────────────────────────────────────────────────────
  Future<List<TopDealerItem>> getTopDealers({
    required DateTime from,
    required DateTime to,
    int limit = 10,
    String? salesmanId,
  }) =>
      guardDio(() async {
        final res = await _dio.get('/analytics/top-dealers',
            queryParameters: _baseParams(
                from: from, to: to,
                salesmanId: salesmanId,
                extra: {'limit': limit}));
        final data = _unwrap(res, fallback: 'Failed to load top dealers');
        final items = (data['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => TopDealerItem.fromJson(e.cast<String, dynamic>()))
            .toList();
        return items;
      });

  // ── 6. top salesmen ───────────────────────────────────────────────────────
  Future<List<TopSalesmanItem>> getTopSalesmen({
    required DateTime from,
    required DateTime to,
    int limit = 10,
    String? dealerId,
  }) =>
      guardDio(() async {
        final res = await _dio.get('/analytics/top-salesmen',
            queryParameters: _baseParams(
                from: from, to: to,
                dealerId: dealerId,
                extra: {'limit': limit}));
        final data = _unwrap(res, fallback: 'Failed to load top salesmen');
        final items = (data['items'] as List? ?? const [])
            .whereType<Map>()
            .map((e) => TopSalesmanItem.fromJson(e.cast<String, dynamic>()))
            .toList();
        return items;
      });

  // ── 7. salesman achievement ───────────────────────────────────────────────
  Future<AchievementResponse> getSalesmanAchievement({
    required DateTime from,
    required DateTime to,
    String? dealerId,
  }) =>
      guardDio(() async {
        final res = await _dio.get('/analytics/salesman-achievement',
            queryParameters: _baseParams(
                from: from, to: to,
                dealerId: dealerId));
        return AchievementResponse.fromJson(
            _unwrap(res, fallback: 'Failed to load achievement'));
      });
}
