class ProductModel {
  String? productId;
  String? productName;
  String? model;
  String? productType;
  int? availableStock;
  num? price;
  String? status;
  String? createdBy;
  String? brand;
  String? createdAt;
  String? updatedAt;
  List<Stocks>? stocks;
  String? logNote;
  List<PriceHistory>? priceHistory;

  ProductModel({
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
    // ❌ no priceHistory in constructor — never sent to backend
  });

  ProductModel.fromJson(Map<String, dynamic> json) {
    productId = json['product_id'];
    productName = json['product_name'];
    model = json['model'];
    productType = json['product_type'];
    availableStock = json['available_stock'];
    price = json['price'];
    status = json['status'];
    createdBy = json['created_by'];
    brand = json['brand'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    logNote = json['log_note'];
    if (json['stocks'] != null) {
      stocks = <Stocks>[];
      json['stocks'].forEach((v) {
        stocks!.add(Stocks.fromJson(v));
      });
    }
    if (json['price_history'] != null) {
      priceHistory = <PriceHistory>[];
      json['price_history'].forEach((v) {
        priceHistory!.add(PriceHistory.fromJson(v));
      });
    }
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
    );
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {};
    data['brand'] = brand;
    data['product_name'] = productName;
    data['model'] = model;
    data['product_type'] = productType;
    data['product_price'] = price;
    data['status'] = status;
    if (stocks != null) {
      data['stocks'] = stocks!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  int get packedStock =>
      stocks?.fold(0, (sum, s) => sum! + (s.packedStock ?? 0)) ?? 0;

  int get unpackedStock =>
      stocks?.fold(0, (sum, s) => sum! + (s.unpackedStock ?? 0)) ?? 0;
}

class Stocks {
  String? stockId;
  String? productId;
  int? stock;
  int? packedStock;
  int? unpackedStock;
  int? addStock;
  int? returnStock;
  String? stockNotes;
  String? createdBy;
  String? createdAt;
  String? updatedAt;
  String? type;
  String? stockType;

  Stocks({
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

  Stocks.fromJson(Map<String, dynamic> json) {
    stockId = json['stock_id'];
    productId = json['product_id'];
    stock = json['stock'];
    packedStock = json['packed_stock'];
    unpackedStock = json['unpacked_stock'];
    addStock = json['add_stock'];
    returnStock = json['return_stock'];
    stockNotes = json['stock_notes'];
    createdBy = json['created_by'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    type = json['type'];
    stockType = json['stock_type'];

  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['stock_id'] = stockId;
    data['product_id'] = productId;
    data['stock'] = stock;
    data['add_stock'] = addStock;
    data['return_stock'] = returnStock;
    data['stock_type'] = stockType;
    data['stock_notes'] = stockNotes;
    data['created_by'] = createdBy;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['type'] = type;
    return data;
  }
}

class StockUpdate {
  Map<String, List<StockItem>> stockMap;

  StockUpdate({required this.stockMap});

  Map<String, dynamic> toJson() {
    return {
      'stock_map': stockMap.map(
            (key, value) => MapEntry(
          key,
          value.map((item) => item.toJson()).toList(),
        ),
      ),
    };
  }
}

class StockItem {
  int stock;
  String stockType;
  String type;
  String? stockNotes;

  StockItem({
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
class PriceHistory {
  final String? priceHistoryId;
  final String? productId;
  final num? oldPrice;
  final num? newPrice;
  final String? changedBy;
  final String? changeReason;
  final String? changedAt;
  final String? createdAt;

  PriceHistory({
    this.priceHistoryId,
    this.productId,
    this.oldPrice,
    this.newPrice,
    this.changedBy,
    this.changeReason,
    this.changedAt,
    this.createdAt,
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
    );
  }
}
