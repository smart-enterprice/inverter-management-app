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

  // New fields
  final num? orderTotalPrice;
  final num? orderTotalDiscount;
  final num? amountDue;
  final num? totalDealerDiscount;
  final num? totalPrice;
  final int? totalCancelledQty;
  final List<dynamic>? cancellationHistory;

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
    this.orderTotalPrice,
    this.orderTotalDiscount,
    this.amountDue,
    this.totalDealerDiscount,
    this.totalPrice,
    this.totalCancelledQty,
    this.cancellationHistory,
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
      orderTotalPrice: json["order_total_price"],
      orderTotalDiscount: json["order_total_discount"],
      amountDue: json["amount_due"],
      totalDealerDiscount: json["total_dealer_discount"],
      totalPrice: json["total_price"],
      totalCancelledQty: json["total_cancelled_qty"],
      cancellationHistory: json["cancellation_history"] ?? [],
    );
  }
  /// 🔹 Use for updating only status flags + order details
  Map<String, dynamic> toUpdateItemJson() {
    return {
      "order_number": orderNumber,
      // Only send items that have actual updates
      "order_details": orderDetails
          .where((item) =>
      item.hasPackedCompleted != null ||
          item.hasProductionCompleted != null ||
          item.nextStatus != null
      )
          .map((x) => x.toUpdateJson())
          .toList(),
    };
  }

  Map<String, dynamic> toUpdateJson({bool isPaymentUpdate = false}) {
    return {
      "order_number": orderNumber,
       "status": status,
    };
  }
  Map<String, dynamic> toUpdatePaymentJson({bool isPaymentUpdate = false}) {
    return {
      "order_number": orderNumber,
      "amount_paid": amountPaid,
    };
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
    num? orderTotalPrice,
    num? orderTotalDiscount,
    num? amountDue,
    num? totalDealerDiscount,
    num? totalPrice,
    int? totalCancelledQty,
    List<dynamic>? cancellationHistory,
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
      orderTotalPrice: orderTotalPrice ?? this.orderTotalPrice,
      orderTotalDiscount: orderTotalDiscount ?? this.orderTotalDiscount,
      amountDue: amountDue ?? this.amountDue,
      totalDealerDiscount: totalDealerDiscount ?? this.totalDealerDiscount,
      totalPrice: totalPrice ?? this.totalPrice,
      totalCancelledQty: totalCancelledQty ?? this.totalCancelledQty,
      cancellationHistory: cancellationHistory ?? this.cancellationHistory,
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
  final DateTime? deliveredDate;
  final String? dealerDiscountId;
  final bool isProductScheme;
  final int? deliveredQty;
  final String? status;

  // Additional fields for UI state (not sent to backend)
  final ProductModel? product;
  final bool useDealerDiscount;
  final num? discountAmount;
  final DealerDiscountModel? dealerDiscount;

  // New fields
  final num? unitProductPrice;
  final num? totalProductPrice;
  final bool? isFree;
  final num? dealerDiscountAmount;
  final String? stockUsage;
  final Map<String, dynamic>? stockFlags;
  final int? qtyDelivered;

  /// 🔹 New Fields Required for Order Update
  final String? orderDetailsNumber;
  final bool? hasUnpacked;
  final bool? hasProduction;
  final bool? hasPackedCompleted;
  final bool? hasProductionCompleted;
  final String? nextStatus;
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
    this.deliveredDate,
    this.dealerDiscountId,
    this.isProductScheme = false,
    this.deliveredQty,
    this.status,
    this.product,
    this.useDealerDiscount = false,
    this.discountAmount,
    this.dealerDiscount,
    this.unitProductPrice,
    this.totalProductPrice,
    this.isFree,
    this.dealerDiscountAmount,
    this.stockUsage,
    this.stockFlags,
    this.qtyDelivered,
    this.orderDetailsNumber,
    this.hasUnpacked,
    this.hasProduction,
    this.hasPackedCompleted,
    this.hasProductionCompleted,
    this.nextStatus
  });

  // Convenience getter for quantity (since UI uses it)
  int get quantity => qtyOrdered ?? 1;

  // Convenience getter for isScheme (since UI uses it)
  bool get isScheme => isProductScheme;

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    final stockUsageData = json["stock_usage"];
    final stockFlagsData = json["stock_flags"];
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
      unitProductPrice: json["unit_product_price"],
      totalProductPrice: json["total_product_price"],
      isFree: json["is_free"],
      dealerDiscountAmount: json["dealer_discount"],
      stockUsage: json["stock_usage"]?.toString(),
      qtyDelivered: json["qty_delivered"] != null
          ? int.tryParse(json["qty_delivered"].toString())
          : null,
      orderDetailsNumber: json["order_details_number"]?.toString(),
      stockFlags: stockFlagsData != null
          ? Map<String, dynamic>.from(stockFlagsData)
          : null,

      hasUnpacked: stockFlagsData?["hasUnpacked"] as bool?,
      hasProduction: stockFlagsData?["hasProduction"] as bool?,
    );
  }
  /// 🔹 Used only when updating order
  Map<String, dynamic> toUpdateJson() {
    return {
      "order_details_number": orderDetailsNumber,

      if (hasPackedCompleted != null)
        "has_unPacked_completed": hasPackedCompleted,

      if (hasProductionCompleted != null)
        "has_production_completed": hasProductionCompleted,
         if(nextStatus != null)
        "status": nextStatus,
    };
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
      "discount_price": discountAmount??0,
      "qty_ordered": qtyOrdered,
      "delivery_date": deliveryDate?.toIso8601String().split('T').first,
      "dealer_discount_id": dealerDiscountId,
      "is_product_scheme": isProductScheme,
      "delivered_qty": deliveredQty,
      'delivered_date': deliveredDate?.toIso8601String().split('T').first,
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
    num? unitProductPrice,
    num? totalProductPrice,
    bool? isFree,
    num? dealerDiscountAmount,
    String? stockUsage,
    Map<String, dynamic>? stockFlags,
    int? qtyDelivered,
    bool? hasProductionCompleted,
    bool? hasPackedCompleted, String? orderDetailsNumber,
    String? newStatus,
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
      unitProductPrice: unitProductPrice ?? this.unitProductPrice,
      totalProductPrice: totalProductPrice ?? this.totalProductPrice,
      isFree: isFree ?? this.isFree,
      dealerDiscountAmount: dealerDiscountAmount ?? this.dealerDiscountAmount,
      stockUsage: stockUsage ?? this.stockUsage,
      stockFlags: stockFlags ?? this.stockFlags,
      qtyDelivered: qtyDelivered ?? this.qtyDelivered,
      orderDetailsNumber:orderDetailsNumber??this.orderDetailsNumber,
      hasPackedCompleted: hasPackedCompleted ?? this.hasPackedCompleted,
      hasProductionCompleted: hasProductionCompleted ?? this.hasProductionCompleted,
      nextStatus: newStatus ?? nextStatus,
    );
  }

  @override
  String toString() {
    return 'OrderDetailsModel(productId: $productId, productName: $productName, qtyOrdered: $qtyOrdered)';
  }
}