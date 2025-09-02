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

  ProductModel(
      {this.productId,
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
        this.stocks});

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
    if (json['stocks'] != null) {
      stocks = <Stocks>[];
      json['stocks'].forEach((v) {
        stocks!.add(new Stocks.fromJson(v));
      });
    }
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['product_id'] = this.productId;
    data['product_name'] = this.productName;
    data['model'] = this.model;
    data['product_type'] = this.productType;
    data['available_stock'] = this.availableStock;
    data['product_price'] = this.price;
    data['status'] = this.status;
    data['created_by'] = this.createdBy;
    data['brand'] = this.brand;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    if (this.stocks != null) {
      data['stocks'] = stocks!.map((v) => v.toJson()).toList();
    }
    return data;
  }

  /// ✅ Get total packed stock
  int get packedStock {
    return stocks
        ?.where((s) => s.stockType?.toUpperCase() == 'PACKED')
        .fold(0, (sum, s) => sum! + (s.stock ?? 0)) ??
        0;
  }

  /// ✅ Get total unpacked stock
  int get unpackedStock {
    return stocks
        ?.where((s) => s.stockType?.toUpperCase() == 'UNPACKED')
        .fold(0, (sum, s) => sum! + (s.stock ?? 0)) ??
        0;
  }
}

class Stocks {
  String? stockId;
  String? productId;
  int? stock;
  int? addStock;
  int? returnStock;
  String? stockType;
  String? stockNotes;
  String? createdBy;
  String? createdAt;
  String? updatedAt;
  String? type;

  Stocks(
      {this.stockId,
        this.productId,
        this.stock,
        this.addStock,
        this.returnStock,
        this.stockType,
        this.stockNotes,
        this.createdBy,
        this.createdAt,
        this.updatedAt,
      this.type});

  Stocks.fromJson(Map<String, dynamic> json) {
    stockId = json['stock_id'];
    productId = json['product_id'];
    stock = json['stock'];
    addStock = json['add_stock'];
    returnStock = json['return_stock'];
    stockType = json['stock_type'];
    stockNotes = json['stock_notes'];
    createdBy = json['created_by'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = new Map<String, dynamic>();
    data['stock_id'] = this.stockId;
    data['product_id'] = this.productId;
    data['stock'] = this.stock;
    data['add_stock'] = this.addStock;
    data['return_stock'] = this.returnStock;
    data['stock_type'] = this.stockType;
    data['stock_notes'] = this.stockNotes;
    data['created_by'] = this.createdBy;
    data['created_at'] = this.createdAt;
    data['updated_at'] = this.updatedAt;
    data['type'] = this.type;
    return data;
  }
}
