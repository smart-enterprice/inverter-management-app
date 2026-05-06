class ProductModel {
  final String? productId;
  final String? productName;
  final String? model;
  final String? productType;
  final int? availableStock;
  final num? price;
  final String? status;
  final String? createdBy;
  final String? brand;
  final String? createdAt;
  final String? updatedAt;
  final List<Stocks>? stocks;
  final String? logNote;
  final List<PriceHistory>? priceHistory;
  final num? cost;
  final String? productCategory;

  const ProductModel({
    this.productId,
    this.productName,
    this.model,
    this.productType,
    this.availableStock,
    this.price,
    this.status,
    this.createdBy,
    this.brand,
    this.createdAt,
    this.updatedAt,
    this.stocks,
    this.logNote,
    this.priceHistory,
    this.cost,
    this.productCategory,
  });

  factory ProductModel.fromJson(Map<String, dynamic> json) {
    return ProductModel(
      productId: json['product_id'],
      productName: json['product_name'],
      model: json['model'],
      productType: json['product_type'],
      availableStock: json['available_stock'],
      price: json['price'],
      status: json['status'],
      createdBy: json['created_by'],
      brand: json['brand'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      logNote: json['log_note'],
      stocks: json['stocks'] != null
          ? List<Stocks>.from(
          (json['stocks'] as List).map((v) => Stocks.fromJson(v)))
          : null,
      priceHistory: json['price_history'] != null
          ? List<PriceHistory>.from(
          (json['price_history'] as List).map((v) => PriceHistory.fromJson(v)))
          : null,
      cost: json['cost'],
      productCategory: json['product_category'],
    );
  }

  ProductModel copyWith({
    String? productId,
    String? productName,
    String? model,
    String? productType,
    int? availableStock,
    num? price,
    String? status,
    String? createdBy,
    String? brand,
    String? createdAt,
    String? updatedAt,
    List<Stocks>? stocks,
    String? logNote,
    List<PriceHistory>? priceHistory,
    num? cost,
    String? productCategory,
  }) {
    return ProductModel(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      model: model ?? this.model,
      productType: productType ?? this.productType,
      availableStock: availableStock ?? this.availableStock,
      price: price ?? this.price,
      status: status ?? this.status,
      createdBy: createdBy ?? this.createdBy,
      brand: brand ?? this.brand,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      stocks: stocks ?? this.stocks,
      logNote: logNote ?? this.logNote,
      priceHistory: priceHistory ?? this.priceHistory,
      cost: cost ?? this.cost,
      productCategory: productCategory ?? this.productCategory,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'brand': brand,
      'product_name': productName,
      'model': model,
      'product_type': productType,
      'product_price': price,
      'product_cost': cost,
      'product_category': productCategory,
      'status': status,
      if (stocks != null)
        'stocks': stocks!.map((v) => v.toJson()).toList(),
    };
  }

  int get packedStock =>
      stocks?.fold(0, (sum, s) => sum! + (s.packedStock ?? 0)) ?? 0;

  int get unpackedStock =>
      stocks?.fold(0, (sum, s) => sum! + (s.unpackedStock ?? 0)) ?? 0;
}

// ─────────────────────────────────────────────
// Stocks — immutable
// ─────────────────────────────────────────────

class Stocks {
  final String? stockId;
  final String? productId;
  final int? stock;
  final int? packedStock;
  final int? unpackedStock;
  final int? addStock;
  final int? returnStock;
  final String? stockNotes;
  final String? createdBy;
  final String? createdAt;
  final String? updatedAt;
  final String? type;
  final String? stockType;

  const Stocks({
    this.stockId,
    this.productId,
    this.stock,
    this.packedStock,
    this.unpackedStock,
    this.addStock,
    this.returnStock,
    this.stockNotes,
    this.createdBy,
    this.createdAt,
    this.updatedAt,
    this.type,
    this.stockType,
  });

  factory Stocks.fromJson(Map<String, dynamic> json) {
    return Stocks(
      stockId: json['stock_id'],
      productId: json['product_id'],
      stock: json['stock'],
      packedStock: json['packed_stock'],
      unpackedStock: json['unpacked_stock'],
      addStock: json['add_stock'],
      returnStock: json['return_stock'],
      stockNotes: json['stock_notes'],
      createdBy: json['created_by'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
      type: json['type'],
      stockType: json['stock_type'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'stock_id': stockId,
      'product_id': productId,
      'stock': stock,
      'add_stock': addStock,
      'return_stock': returnStock,
      'stock_type': stockType,
      'stock_notes': stockNotes,
      'created_by': createdBy,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'type': type,
    };
  }
}

// ─────────────────────────────────────────────
// StockUpdate — unchanged, mutable is fine here
// since it's a one-shot request object
// ─────────────────────────────────────────────

class StockUpdate {
  final Map<String, List<StockItem>> stockMap;

  const StockUpdate({required this.stockMap});

  Map<String, dynamic> toJson() {
    return {
      'stock_map': stockMap.map(
            (key, value) =>
            MapEntry(key, value.map((item) => item.toJson()).toList()),
      ),
    };
  }
}

class StockItem {
  final int stock;
  final String stockType;
  final String type;
  final String? stockNotes;

  const StockItem({
    required this.stock,
    required this.stockType,
    required this.type,
    this.stockNotes,
  });

  Map<String, dynamic> toJson() {
    return {
      'stock': stock,
      'stock_type': stockType,
      'type': type,
      if (stockNotes != null) 'stock_notes': stockNotes,
    };
  }
}

// ─────────────────────────────────────────────
// PriceHistory — unchanged, already immutable
// ─────────────────────────────────────────────

class PriceHistory {
  final String? priceHistoryId;
  final String? productId;
  final num? oldPrice;
  final num? newPrice;
  final String? changedBy;
  final String? changeReason;
  final String? changedAt;
  final String? createdAt;
  final bool? isCostUpdate;
  const PriceHistory({
    this.priceHistoryId,
    this.productId,
    this.oldPrice,
    this.newPrice,
    this.changedBy,
    this.changeReason,
    this.changedAt,
    this.createdAt,
    this.isCostUpdate,
  });

  factory PriceHistory.fromJson(Map<String, dynamic> json) {
    return PriceHistory(
      priceHistoryId: json['price_history_id'],
      productId: json['product_id'],
      oldPrice: json['old_price'],
      newPrice: json['new_price'],
      changedBy: json['changed_by'],
      changeReason: json['change_reason'],
      changedAt: json['changed_at'],
      createdAt: json['created_at'],
      isCostUpdate: json['is_cost_update'],
    );
  }
}