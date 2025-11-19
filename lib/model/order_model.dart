import 'package:inverter_management_app/model/product_model.dart';

import 'dealer_discount_model.dart';

class OrderModel {
  final String? orderNumber;
  final String dealerId;
  final String priority;
  final String orderNote;
  final List<dynamic>? paymentNotes;
  final String? status;
  final String salesmanId;
  final String? createdBy;
  final String? paymentStatus;
  final String paymentType;
  final num amountPaid;
  final bool? salesTargetUpdated;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DealerModel? dealer;
  final List<OrderDetailsModel> orderDetails;

  OrderModel({
    this.orderNumber,
    required this.dealerId,
    required this.priority,
    required this.orderNote,
    this.paymentNotes,
    this.status,
    required this.salesmanId,
     this.createdBy,
     this.paymentStatus,
    required this.paymentType,
    required this.amountPaid,
    this.salesTargetUpdated,
    this.createdAt,
    this.updatedAt,
    this.dealer,
    required this.orderDetails,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) {
    return OrderModel(
      orderNumber: json["order_number"] ?? "",
      dealerId: json["dealer_id"] ?? "",
      priority: json["priority"] ?? "",
      orderNote: json["order_note"] ?? "",
      paymentNotes: json["payment_notes"] ?? [],
      status: json["status"] ?? "",
      salesmanId: json["salesman_id"] ?? "",
      createdBy: json["created_by"] ?? "",
      paymentStatus: json["payment_status"] ?? "",
      paymentType: json["payment_type"] ?? "",
      amountPaid: json["amount_paid"] ?? 0,
      salesTargetUpdated: json["sales_target_updated"] ?? false,
      createdAt: json["created_at"] != null ? DateTime.tryParse(json["created_at"]) : null,
      updatedAt: json["updated_at"] != null ? DateTime.tryParse(json["updated_at"]) : null,
      dealer: json["dealer"] != null ? DealerModel.fromJson(json["dealer"]) : null,
      orderDetails: json["order_details"] != null
          ? List<OrderDetailsModel>.from(
          json["order_details"].map((x) => OrderDetailsModel.fromJson(x)))
          : [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "order_number": orderNumber,
      "dealer_id": dealerId,
      "priority": priority,
      "order_note": orderNote,
      "payment_notes": paymentNotes,
      "status": status,
      "salesman_id": salesmanId,
      "created_by": createdBy,
      "payment_status": paymentStatus,
      "payment_type": paymentType,
      "amount_paid": amountPaid,
      "sales_target_updated": salesTargetUpdated,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
      "dealer": dealer?.toJson(),
      "order_details": orderDetails.map((x) => x.toJson()).toList(),
    };
  }

  OrderModel copyWith({
    String? orderNumber,
    String? dealerId,
    String? priority,
    String? orderNote,
    List<dynamic>? paymentNotes,
    String? status,
    String? salesmanId,
    String? createdBy,
    String? paymentStatus,
    String? paymentType,
    num? amountPaid,
    bool? salesTargetUpdated,
    DateTime? createdAt,
    DateTime? updatedAt,
    DealerModel? dealer,
    List<OrderDetailsModel>? orderDetails,
  }) {
    return OrderModel(
      orderNumber: orderNumber ?? this.orderNumber,
      dealerId: dealerId ?? this.dealerId,
      priority: priority ?? this.priority,
      orderNote: orderNote ?? this.orderNote,
      paymentNotes: paymentNotes ?? this.paymentNotes,
      status: status ?? this.status,
      salesmanId: salesmanId ?? this.salesmanId,
      createdBy: createdBy ?? this.createdBy,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentType: paymentType ?? this.paymentType,
      amountPaid: amountPaid ?? this.amountPaid,
      salesTargetUpdated: salesTargetUpdated ?? this.salesTargetUpdated,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      dealer: dealer ?? this.dealer,
      orderDetails: orderDetails ?? this.orderDetails,
    );
  }
}

class DealerModel {
  final String employeeId;
  final String employeeName;
  final String employeeEmail;
  final num employeePhone;
  final String role;
  final String status;
  final String createdBy;
  final String shopName;
  final String photo;
  final String district;
  final String town;
  final List<String> brand;
  final String address;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  DealerModel({
    required this.employeeId,
    required this.employeeName,
    required this.employeeEmail,
    required this.employeePhone,
    required this.role,
    required this.status,
    required this.createdBy,
    required this.shopName,
    required this.photo,
    required this.district,
    required this.town,
    required this.brand,
    required this.address,
    this.createdAt,
    this.updatedAt,
  });

  factory DealerModel.fromJson(Map<String, dynamic> json) {
    return DealerModel(
      employeeId: json["employee_id"] ?? "",
      employeeName: json["employee_name"] ?? "",
      employeeEmail: json["employee_email"] ?? "",
      employeePhone: json["employee_phone"] ?? 0,
      role: json["role"] ?? "",
      status: json["status"] ?? "",
      createdBy: json["created_by"] ?? "",
      shopName: json["shop_name"] ?? "",
      photo: json["photo"] ?? "",
      district: json["district"] ?? "",
      town: json["town"] ?? "",
      brand: json["brand"] != null ? List<String>.from(json["brand"]) : [],
      address: json["address"] ?? "",
      createdAt: json["created_at"] != null ? DateTime.tryParse(json["created_at"]) : null,
      updatedAt: json["updated_at"] != null ? DateTime.tryParse(json["updated_at"]) : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "employee_id": employeeId,
      "employee_name": employeeName,
      "employee_email": employeeEmail,
      "employee_phone": employeePhone,
      "role": role,
      "status": status,
      "created_by": createdBy,
      "shop_name": shopName,
      "photo": photo,
      "district": district,
      "town": town,
      "brand": brand,
      "address": address,
      "created_at": createdAt?.toIso8601String(),
      "updated_at": updatedAt?.toIso8601String(),
    };
  }
}

class OrderDetailsModel {
  final String productId;
  final String productBrand;
  final String productName;
  final String productModel;
  final String productType;
  final int? productPrice;
  final int? discountPrice;
  final int? qtyOrdered;
  final DateTime? deliveryDate;
  final String? dealerDiscountId;
  final bool isProductScheme;
  final int? deliveredQty;
  final String? status;

  // Additional fields for UI state (not sent to backend)
  final ProductModel? product;
  final bool useDealerDiscount;
  final num? discountAmount;
  final DealerDiscountModel? dealerDiscount;

  OrderDetailsModel({
    required this.productId,
    required this.productBrand,
    required this.productName,
    required this.productModel,
    required this.productType,
    this.productPrice,
    this.discountPrice,
    this.qtyOrdered,
    this.deliveryDate,
    this.dealerDiscountId,
    this.isProductScheme = false,
    this.deliveredQty,
    this.status,
    this.product,
    this.useDealerDiscount = false,
    this.discountAmount,
    this.dealerDiscount,
  });

  // Convenience getter for quantity (since UI uses it)
  int get quantity => qtyOrdered ?? 1;

  // Convenience getter for isScheme (since UI uses it)
  bool get isScheme => isProductScheme;

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    return OrderDetailsModel(
      productId: json["product_id"]?.toString() ?? "",
      productBrand: json["product_brand"]?.toString() ?? "",
      productName: json["product_name"]?.toString() ?? "",
      productModel: json["product_model"]?.toString() ?? "",
      productType: json["product_type"]?.toString() ?? "",
      productPrice: json["product_price"] != null
          ? int.tryParse(json["product_price"].toString())
          : null,
      discountPrice: json["discount_price"] != null
          ? int.tryParse(json["discount_price"].toString())
          : null,
      qtyOrdered: json["qty_ordered"] != null
          ? int.tryParse(json["qty_ordered"].toString())
          : null,
      deliveryDate: json["delivery_date"] != null
          ? DateTime.tryParse(json["delivery_date"].toString())
          : null,
      dealerDiscountId: json["dealer_discount_id"]?.toString(),
      isProductScheme: json["is_product_scheme"] == true ||
          json["is_product_scheme"]?.toString().toLowerCase() == 'true',
      deliveredQty: json["delivered_qty"] != null
          ? int.tryParse(json["delivered_qty"].toString())
          : null,
      status: json["status"]?.toString(),
    );
  }

  // Factory to create from ProductModel (for UI)
  factory OrderDetailsModel.fromProduct(
      ProductModel product, {
        DealerDiscountModel? dealerDiscount,
      }) {
    return OrderDetailsModel(
      productId: product.productId!,
      productBrand: product.brand!,
      productName: product.productName.toString(),
      productModel: product.model.toString(),
      productType: product.productType!,
      productPrice: product.price?.toInt(),
      qtyOrdered: 1,
      isProductScheme: false,
      product: product,
      dealerDiscount: dealerDiscount,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "product_id": productId,
      "product_brand": productBrand,
      "product_name": productName,
      "product_model": productModel,
      "product_type": productType,
      "product_price": productPrice,
      "discount_price": discountPrice,
      "qty_ordered": qtyOrdered,
      "delivery_date": deliveryDate?.toIso8601String().split('T').first,
      "dealer_discount_id": dealerDiscountId,
      "is_product_scheme": isProductScheme,
      "delivered_qty": deliveredQty,
      "status": status,
    };
  }

  OrderDetailsModel copyWith({
    String? productId,
    String? productBrand,
    String? productName,
    String? productModel,
    String? productType,
    int? productPrice,
    int? discountPrice,
    int? qtyOrdered,
    DateTime? deliveryDate,
    String? dealerDiscountId,
    bool? isProductScheme,
    int? deliveredQty,
    String? status,
    ProductModel? product,
    bool? useDealerDiscount,
    num? discountAmount,
    DealerDiscountModel? dealerDiscount,
  }) {
    return OrderDetailsModel(
      productId: productId ?? this.productId,
      productBrand: productBrand ?? this.productBrand,
      productName: productName ?? this.productName,
      productModel: productModel ?? this.productModel,
      productType: productType ?? this.productType,
      productPrice: productPrice ?? this.productPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      qtyOrdered: qtyOrdered ?? this.qtyOrdered,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      dealerDiscountId: dealerDiscountId ?? this.dealerDiscountId,
      isProductScheme: isProductScheme ?? this.isProductScheme,
      deliveredQty: deliveredQty ?? this.deliveredQty,
      status: status ?? this.status,
      product: product ?? this.product,
      useDealerDiscount: useDealerDiscount ?? this.useDealerDiscount,
      discountAmount: discountAmount ?? this.discountAmount,
      dealerDiscount: dealerDiscount ?? this.dealerDiscount,
    );
  }

  @override
  String toString() {
    return 'OrderDetailsModel(productId: $productId, productName: $productName, qtyOrdered: $qtyOrdered)';
  }
}

