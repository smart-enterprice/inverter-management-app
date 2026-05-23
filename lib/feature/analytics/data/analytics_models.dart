// Plain Dart models for the analytics endpoints.
// Hand-written fromJson — no codegen — matches the rest of this codebase.

num _asNum(dynamic v) {
  if (v == null) return 0;
  if (v is num) return v;
  return num.tryParse(v.toString()) ?? 0;
}

int _asInt(dynamic v) => _asNum(v).toInt();
double _asDouble(dynamic v) => _asNum(v).toDouble();
String _asStr(dynamic v) => v?.toString() ?? '';

// ─── /analytics/summary ──────────────────────────────────────────────────────
class AnalyticsSummary {
  final int ordersTotal;
  final int ordersDelivered;
  final int ordersCompleted;
  final int ordersCancelled;

  final double revenueBooked;
  final double revenueDelivered;
  final double revenueCancelled;
  final double revenuePending;
  final double revenuePaid;
  final double revenueDue;

  /// status -> count. Keys come back uppercase from the API.
  final Map<String, int> statusDistribution;

  const AnalyticsSummary({
    required this.ordersTotal,
    required this.ordersDelivered,
    required this.ordersCompleted,
    required this.ordersCancelled,
    required this.revenueBooked,
    required this.revenueDelivered,
    required this.revenueCancelled,
    required this.revenuePending,
    required this.revenuePaid,
    required this.revenueDue,
    required this.statusDistribution,
  });

  factory AnalyticsSummary.fromJson(Map<String, dynamic> j) {
    final dist = <String, int>{};
    final raw = j['status_distribution'];
    if (raw is Map) {
      raw.forEach((k, v) => dist[k.toString().toUpperCase()] = _asInt(v));
    }
    return AnalyticsSummary(
      ordersTotal:      _asInt(j['orders_total']),
      ordersDelivered:  _asInt(j['orders_delivered']),
      ordersCompleted:  _asInt(j['orders_completed']),
      ordersCancelled:  _asInt(j['orders_cancelled']),
      revenueBooked:    _asDouble(j['revenue_booked']),
      revenueDelivered: _asDouble(j['revenue_delivered']),
      revenueCancelled: _asDouble(j['revenue_cancelled']),
      revenuePending:   _asDouble(j['revenue_pending']),
      revenuePaid:      _asDouble(j['revenue_paid']),
      revenueDue:       _asDouble(j['revenue_due']),
      statusDistribution: dist,
    );
  }

  /// Conservation: booked = delivered + cancelled + pending. Anything else
  /// is a backend bug — surface it so we don't silently mislead the user.
  bool get isConserved {
    final sum = revenueDelivered + revenueCancelled + revenuePending;
    return (revenueBooked - sum).abs() < 1.0;
  }
}

// ─── /analytics/sales-trend ──────────────────────────────────────────────────
class TrendPoint {
  final DateTime date;
  final int orders;
  final double revenue;
  final double delivered;
  final double cancelled;
  final double paid;

  const TrendPoint({
    required this.date,
    required this.orders,
    required this.revenue,
    required this.delivered,
    required this.cancelled,
    required this.paid,
  });

  factory TrendPoint.fromJson(Map<String, dynamic> j) => TrendPoint(
        date: DateTime.tryParse(_asStr(j['date'])) ?? DateTime.now(),
        orders: _asInt(j['orders']),
        revenue: _asDouble(j['revenue']),
        delivered: _asDouble(j['delivered']),
        cancelled: _asDouble(j['cancelled']),
        paid: _asDouble(j['paid']),
      );
}

class TrendSeries {
  final List<TrendPoint> series;
  const TrendSeries(this.series);

  factory TrendSeries.fromJson(Map<String, dynamic> j) {
    final list = (j['series'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => TrendPoint.fromJson(e.cast<String, dynamic>()))
        .toList();
    return TrendSeries(list);
  }
}

// ─── /analytics/top-products ─────────────────────────────────────────────────
class TopProductItem {
  final String productId;
  final String productName;
  final String productBrand;
  final String productModel;
  final int qtySold;
  final double revenue;

  const TopProductItem({
    required this.productId,
    required this.productName,
    required this.productBrand,
    required this.productModel,
    required this.qtySold,
    required this.revenue,
  });

  factory TopProductItem.fromJson(Map<String, dynamic> j) => TopProductItem(
        productId: _asStr(j['product_id']),
        productName: _asStr(j['product_name']),
        productBrand: _asStr(j['product_brand']),
        productModel: _asStr(j['product_model']),
        qtySold: _asInt(j['qty_sold']),
        revenue: _asDouble(j['revenue']),
      );
}

// ─── /analytics/top-brands ───────────────────────────────────────────────────
class TopBrandItem {
  final String productBrand;
  final int qtySold;
  final double revenue;
  final int ordersCount;

  const TopBrandItem({
    required this.productBrand,
    required this.qtySold,
    required this.revenue,
    required this.ordersCount,
  });

  factory TopBrandItem.fromJson(Map<String, dynamic> j) => TopBrandItem(
        productBrand: _asStr(j['product_brand']),
        qtySold: _asInt(j['qty_sold']),
        revenue: _asDouble(j['revenue']),
        ordersCount: _asInt(j['orders_count']),
      );
}

// ─── /analytics/top-dealers ──────────────────────────────────────────────────
class TopDealerItem {
  final String dealerId;
  final String dealerName;
  final String shopName;
  final String district;
  final int ordersCount;
  final double revenue;
  final double paid;
  final double due;

  const TopDealerItem({
    required this.dealerId,
    required this.dealerName,
    required this.shopName,
    required this.district,
    required this.ordersCount,
    required this.revenue,
    required this.paid,
    required this.due,
  });

  factory TopDealerItem.fromJson(Map<String, dynamic> j) => TopDealerItem(
        dealerId: _asStr(j['dealer_id']),
        dealerName: _asStr(j['dealer_name']),
        shopName: _asStr(j['shop_name']),
        district: _asStr(j['district']),
        ordersCount: _asInt(j['orders_count']),
        revenue: _asDouble(j['revenue']),
        paid: _asDouble(j['paid']),
        due: _asDouble(j['due']),
      );
}

// ─── /analytics/top-salesmen ─────────────────────────────────────────────────
class TopSalesmanItem {
  final String salesmanId;
  final String salesmanName;
  final String district;
  final int ordersCount;
  final double revenue;
  final double paid;
  final double due;

  const TopSalesmanItem({
    required this.salesmanId,
    required this.salesmanName,
    required this.district,
    required this.ordersCount,
    required this.revenue,
    required this.paid,
    required this.due,
  });

  factory TopSalesmanItem.fromJson(Map<String, dynamic> j) => TopSalesmanItem(
        salesmanId: _asStr(j['salesman_id']),
        salesmanName: _asStr(j['salesman_name']),
        district: _asStr(j['district']),
        ordersCount: _asInt(j['orders_count']),
        revenue: _asDouble(j['revenue']),
        paid: _asDouble(j['paid']),
        due: _asDouble(j['due']),
      );
}

// ─── /analytics/salesman-achievement ────────────────────────────────────────
class AchievementItem {
  final String salesmanId;
  final String salesmanName;
  final int targetQty;
  final int achievedQty;
  final double achievementPct;
  final int ordersCount;
  final double revenue;

  const AchievementItem({
    required this.salesmanId,
    required this.salesmanName,
    required this.targetQty,
    required this.achievedQty,
    required this.achievementPct,
    required this.ordersCount,
    required this.revenue,
  });

  factory AchievementItem.fromJson(Map<String, dynamic> j) => AchievementItem(
        salesmanId: _asStr(j['salesman_id']),
        salesmanName: _asStr(j['salesman_name']),
        targetQty: _asInt(j['target_qty']),
        achievedQty: _asInt(j['achieved_qty']),
        achievementPct: _asDouble(j['achievement_pct']),
        ordersCount: _asInt(j['orders_count']),
        revenue: _asDouble(j['revenue']),
      );
}

class AchievementResponse {
  final int defaultTargetQty;
  final List<AchievementItem> items;
  const AchievementResponse({
    required this.defaultTargetQty,
    required this.items,
  });

  factory AchievementResponse.fromJson(Map<String, dynamic> j) {
    final list = (j['items'] as List? ?? const [])
        .whereType<Map>()
        .map((e) => AchievementItem.fromJson(e.cast<String, dynamic>()))
        .toList();
    return AchievementResponse(
      defaultTargetQty: _asInt(j['default_target_qty']),
      items: list,
    );
  }
}
