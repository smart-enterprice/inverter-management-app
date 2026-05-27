/// Aggregated per-product status counts returned by
/// `GET /order-details/production-summary`. Each row counts the *active* units
/// still in the factory pipeline (PRODUCTION → PACKED → INVOICE → SHIPPED) —
/// delivered, completed, cancelled and rejected units are excluded server-side.
///
/// Each product also carries a per-dealer breakdown (sorted by total_qty desc
/// on the backend; clients must not re-sort).
class ProductionSummaryRow {
  final String productId;
  final String productName;
  final String productBrand;
  final String productModel;
  final String productType;
  final String productCategory;
  final int production;
  final int packed;
  final int invoice;
  final int shipped;
  final int totalQty;
  final int dealerCount;
  final List<DealerProductionSummary> dealers;

  const ProductionSummaryRow({
    required this.productId,
    required this.productName,
    required this.productBrand,
    required this.productModel,
    required this.productType,
    required this.productCategory,
    required this.production,
    required this.packed,
    required this.invoice,
    required this.shipped,
    required this.totalQty,
    required this.dealerCount,
    required this.dealers,
  });

  factory ProductionSummaryRow.fromJson(Map<String, dynamic> json) {
    final counts = (json['counts'] as Map?) ?? const {};
    final rawDealers = (json['dealers'] as List?) ?? const [];
    return ProductionSummaryRow(
      productId: json['product_id']?.toString() ?? '',
      productName: json['product_name']?.toString() ?? '',
      productBrand: json['product_brand']?.toString() ?? '',
      productModel: json['product_model']?.toString() ?? '',
      productType: json['product_type']?.toString() ?? '',
      productCategory: json['product_category']?.toString() ?? '',
      production: _asInt(counts['PRODUCTION']),
      packed: _asInt(counts['PACKED']),
      invoice: _asInt(counts['INVOICE']),
      shipped: _asInt(counts['SHIPPED']),
      totalQty: _asInt(json['total_qty']),
      dealerCount: _asInt(json['dealer_count']),
      dealers: rawDealers
          .whereType<Map<String, dynamic>>()
          .map(DealerProductionSummary.fromJson)
          .toList(),
    );
  }
}

/// Per-dealer slice of the production pipeline for one product.
class DealerProductionSummary {
  final String dealerId;
  final String dealerName;
  final String shopName;
  final String town;
  final String employeePhone;
  final int production;
  final int packed;
  final int invoice;
  final int shipped;
  final int totalQty;

  /// Order-level remaining qty for this product × dealer, sorted by qty desc
  /// on the backend. Clients must not re-sort.
  final List<DealerOrderRef> orders;

  const DealerProductionSummary({
    required this.dealerId,
    required this.dealerName,
    required this.shopName,
    required this.town,
    required this.employeePhone,
    required this.production,
    required this.packed,
    required this.invoice,
    required this.shipped,
    required this.totalQty,
    this.orders = const [],
  });

  factory DealerProductionSummary.fromJson(Map<String, dynamic> json) {
    final counts = (json['counts'] as Map?) ?? const {};
    final rawOrders = (json['orders'] as List?) ?? const [];
    return DealerProductionSummary(
      dealerId: json['dealer_id']?.toString() ?? '',
      dealerName: json['dealer_name']?.toString() ?? '',
      shopName: json['shop_name']?.toString() ?? '',
      town: json['town']?.toString() ?? '',
      employeePhone: json['employee_phone']?.toString() ?? '',
      production: _asInt(counts['PRODUCTION']),
      packed: _asInt(counts['PACKED']),
      invoice: _asInt(counts['INVOICE']),
      shipped: _asInt(counts['SHIPPED']),
      totalQty: _asInt(json['total_qty']),
      orders: rawOrders
          .whereType<Map<String, dynamic>>()
          .map(DealerOrderRef.fromJson)
          .toList(),
    );
  }
}

/// One order's remaining qty for a given product × dealer slot.
class DealerOrderRef {
  final String orderNumber;
  final int qty;

  const DealerOrderRef({required this.orderNumber, required this.qty});

  factory DealerOrderRef.fromJson(Map<String, dynamic> json) =>
      DealerOrderRef(
        orderNumber: json['order_number']?.toString() ?? '',
        qty: _asInt(json['qty']),
      );
}

int _asInt(dynamic v) =>
    v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
