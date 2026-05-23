import 'package:inverter_management_app/feature/product/model/product_model.dart';
import 'package:inverter_management_app/feature/discount/model/dealer_discount_model.dart';

// ─────────────────────────────────────────────
// CancellationHistoryModel
// ─────────────────────────────────────────────

class CancellationHistoryModel {
  final int cancelledQty;
  final String cancelledBy;
  final String cancelledByRole;
  final DateTime? cancelledAt;
  final String reason;
  final String id;

  CancellationHistoryModel({
    required this.cancelledQty,
    required this.cancelledBy,
    required this.cancelledByRole,
    this.cancelledAt,
    required this.reason,
    required this.id,
  });

  factory CancellationHistoryModel.fromJson(Map<String, dynamic> json) {
    return CancellationHistoryModel(
      cancelledQty: json["cancelled_qty"] != null
          ? int.tryParse(json["cancelled_qty"].toString()) ?? 0
          : 0,
      cancelledBy: json["cancelled_by"]?.toString() ?? "",
      cancelledByRole: json["cancelled_by_role"]?.toString() ?? "",
      cancelledAt: json["cancelled_at"] != null
          ? DateTime.tryParse(json["cancelled_at"].toString())
          : null,
      reason: json["reason"]?.toString() ?? "",
      id: json["_id"]?.toString() ?? "",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      "cancelled_qty": cancelledQty,
      "cancelled_by": cancelledBy,
      "cancelled_by_role": cancelledByRole,
      "cancelled_at": cancelledAt?.toIso8601String(),
      "reason": reason,
      "_id": id,
    };
  }

  CancellationHistoryModel copyWith({
    int? cancelledQty,
    String? cancelledBy,
    String? cancelledByRole,
    DateTime? cancelledAt,
    String? reason,
    String? id,
  }) {
    return CancellationHistoryModel(
      cancelledQty: cancelledQty ?? this.cancelledQty,
      cancelledBy: cancelledBy ?? this.cancelledBy,
      cancelledByRole: cancelledByRole ?? this.cancelledByRole,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      reason: reason ?? this.reason,
      id: id ?? this.id,
    );
  }

  @override
  String toString() {
    return 'CancellationHistoryModel(id: $id, cancelledQty: $cancelledQty, reason: $reason)';
  }
}

// ─────────────────────────────────────────────
// OrderModel
// ─────────────────────────────────────────────

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
  final String? reasonForCancellation;

  // Summary fields
  final num? orderTotalPrice;
  final num? orderTotalDiscount;
  final num? amountDue;
  final num? totalDealerDiscount;
  final num? totalPrice;
  final int? totalCancelledQty;
  final List<CancellationHistoryModel>? cancellationHistory;

  // Partial-fulfillment snapshot, added by backend on list/detail endpoints.
  // Nullable: older endpoints (or stale clients) may omit it.
  final OrderProgress? progress;

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
    this.reasonForCancellation,
    this.progress,
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
      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"])
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.tryParse(json["updated_at"])
          : null,
      dealer:
      json["dealer"] != null ? DealerModel.fromJson(json["dealer"]) : null,
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
      cancellationHistory: json["cancellation_history"] != null
          ? List<CancellationHistoryModel>.from(json["cancellation_history"]
          .map((x) => CancellationHistoryModel.fromJson(x)))
          : [],
      reasonForCancellation: json["reason_for_cancellation"],
      progress: json["progress"] is Map<String, dynamic>
          ? OrderProgress.fromJson(json["progress"] as Map<String, dynamic>)
          : null,
    );
  }

  /// Use for updating only status flags + order details
  Map<String, dynamic> toUpdateItemJson() {
    return {
      "order_number": orderNumber,
      "order_details": orderDetails
          .where((item) =>
      item.status != 'CANCELLED' &&
          item.status != 'COMPLETED' &&
          item.status != 'DELIVERED' &&
          (item.hasPackedCompleted != null ||
              item.hasProductionCompleted != null ||
              item.nextStatus != null ||
              item.isDeliveryDateUpdated ||
              item.isDeliveredQtyUpdated ||
              (item.cancelQty != null && item.cancelQty! > 0)))
          .map((x) => x.toUpdateJson())
          .toList(),
    };
  }

  Map<String, dynamic> toUpdateJson({bool isPaymentUpdate = false}) {
    return {
      "order_number": orderNumber,
      "status": status,
      if (reasonForCancellation != null)
        "reason_for_cancellation": reasonForCancellation,
    };
  }

  Map<String, dynamic> toUpdatePaymentJson() {
    return {
      "order_number": orderNumber,
      "amount_paid": amountPaid,
      "payment_method": paymentType,
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
      "cancellation_history":
      cancellationHistory?.map((x) => x.toJson()).toList(),
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
    List<CancellationHistoryModel>? cancellationHistory,
    String? reasonForCancellation,
    OrderProgress? progress,
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
      reasonForCancellation:
      reasonForCancellation ?? this.reasonForCancellation,
      progress: progress ?? this.progress,
    );
  }
}

// ─────────────────────────────────────────────
// OrderProgress
// ─────────────────────────────────────────────
class OrderProgress {
  final int qtyOrderedTotal;
  final int qtyDeliveredTotal;
  final int qtyCancelledTotal;
  final int qtyInProductionTotal;
  final int qtyPackedTotal;
  final int qtyInvoicedTotal;
  final int qtyShippedTotal;
  final int qtyRemainingTotal;
  final int itemsTotal;
  final int itemsDelivered;
  final int deliveredPercent;

  const OrderProgress({
    required this.qtyOrderedTotal,
    required this.qtyDeliveredTotal,
    required this.qtyCancelledTotal,
    required this.qtyInProductionTotal,
    required this.qtyPackedTotal,
    required this.qtyInvoicedTotal,
    required this.qtyShippedTotal,
    required this.qtyRemainingTotal,
    required this.itemsTotal,
    required this.itemsDelivered,
    required this.deliveredPercent,
  });

  factory OrderProgress.fromJson(Map<String, dynamic> json) {
    int asInt(dynamic v) =>
        v == null ? 0 : (v is int ? v : int.tryParse(v.toString()) ?? 0);
    return OrderProgress(
      qtyOrderedTotal:      asInt(json['qty_ordered_total']),
      qtyDeliveredTotal:    asInt(json['qty_delivered_total']),
      qtyCancelledTotal:    asInt(json['qty_cancelled_total']),
      qtyInProductionTotal: asInt(json['qty_in_production_total']),
      qtyPackedTotal:       asInt(json['qty_packed_total']),
      qtyInvoicedTotal:     asInt(json['qty_invoiced_total']),
      qtyShippedTotal:      asInt(json['qty_shipped_total']),
      qtyRemainingTotal:    asInt(json['qty_remaining_total']),
      itemsTotal:           asInt(json['items_total']),
      itemsDelivered:       asInt(json['items_delivered']),
      deliveredPercent:     asInt(json['delivered_percent']),
    );
  }
}

// ─────────────────────────────────────────────
// DealerModel
// ─────────────────────────────────────────────

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
      createdAt: json["created_at"] != null
          ? DateTime.tryParse(json["created_at"])
          : null,
      updatedAt: json["updated_at"] != null
          ? DateTime.tryParse(json["updated_at"])
          : null,
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
  final int? cancelQty;
  final int? totalCancelledQty;
  final String? reasonForCancellation;
  final List<CancellationHistoryModel>? cancellationHistory;
  final String? notes;

  // ✅ NEW — delivery notes fetched from API (list of strings)
  final List<String> deliveryNotes;

  // ✅ NEW — delivery note to send when updating delivery date (UI-only)
  final String? deliveryNote;

  // UI-only flag fields
  final bool isDeliveryDateUpdated;
  final bool isReasonUpdated;
  final bool isDeliveredQtyUpdated;

  // UI-only fields (not sent to backend)
  final ProductModel? product;
  final bool useDealerDiscount;
  final num? discountAmount;
  final DealerDiscountModel? dealerDiscount;

  // Pricing / stock fields
  final num? unitProductPrice;
  final num? totalProductPrice;
  final bool? isFree;
  final num? dealerDiscountAmount;
  final String? stockUsage;
  final Map<String, dynamic>? stockFlags;
  final int? qtyDelivered;

  // Order update fields
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
    this.nextStatus,
    this.cancelQty,
    this.totalCancelledQty,
    this.reasonForCancellation,
    this.cancellationHistory,
    this.isDeliveryDateUpdated = false,
    this.isReasonUpdated = false,
    this.isDeliveredQtyUpdated = false,
    this.notes,
    this.deliveryNotes = const [],   // ✅ NEW
    this.deliveryNote,               // ✅ NEW
  });

  int get quantity => qtyOrdered ?? 1;
  bool get isScheme => isProductScheme;

  factory OrderDetailsModel.fromJson(Map<String, dynamic> json) {
    final stockFlagsData = json["stock_flags"];

    return OrderDetailsModel(
      notes: json["notes"]?.toString(),

      // ✅ NEW — parse delivery_notes array from API
      deliveryNotes: json["delivery_notes"] != null
          ? List<String>.from(
          (json["delivery_notes"] as List).map((e) => e.toString()))
          : [],

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
      deliveredDate: json["delivered_date"] != null
          ? DateTime.tryParse(json["delivered_date"].toString())
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
      totalCancelledQty: json["total_cancelled_qty"] != null
          ? int.tryParse(json["total_cancelled_qty"].toString())
          : null,
      cancellationHistory: json["cancellation_history"] != null
          ? List<CancellationHistoryModel>.from(json["cancellation_history"]
          .map((x) => CancellationHistoryModel.fromJson(x)))
          : [],
      reasonForCancellation: json["reason_for_cancellation"]?.toString(),

      // UI-only fields — always reset when loading from API
      hasPackedCompleted: null,
      hasProductionCompleted: null,
      nextStatus: null,
      cancelQty: null,
      isDeliveryDateUpdated: false,
      isReasonUpdated: false,
      isDeliveredQtyUpdated: false,
      deliveryNote: null,   // ✅ always null on fresh fetch
    );
  }

  /// Used only when updating an order item
  Map<String, dynamic> toUpdateJson() {
    return {
      "order_details_number": orderDetailsNumber,
      if (hasPackedCompleted != null)
        "has_unPacked_completed": hasPackedCompleted,
      if (hasProductionCompleted != null)
        "has_production_completed": hasProductionCompleted,
      if (nextStatus != null) "status": nextStatus,

      // ✅ Send delivery_date AND delivery_note together
      if (isDeliveryDateUpdated && deliveryDate != null) ...{
        "delivered_date": deliveryDate!.toIso8601String().split('T').first,
        if (deliveryNote != null && deliveryNote!.trim().isNotEmpty)
          "delivery_note": deliveryNote!.trim(),
      },

      // ✅ Send delivered_qty + delivered_date (from existing deliveryDate) together
      if (isDeliveredQtyUpdated && deliveredQty != null) ...{
        "delivered_qty": deliveredQty,
        if (deliveryDate != null)
          "delivered_date": deliveryDate!.toIso8601String().split('T').first,
      },

      if (cancelQty != null && cancelQty! > 0) "cancel_qty": cancelQty,
      if (isReasonUpdated &&
          reasonForCancellation != null &&
          reasonForCancellation!.isNotEmpty)
        "reason_for_cancellation": reasonForCancellation,
    };
  }

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
      "discount_price": discountAmount ?? 0,
      "qty_ordered": qtyOrdered,
      "delivery_date": deliveryDate?.toIso8601String().split('T').first,
      "dealer_discount_id": dealerDiscountId,
      "is_product_scheme": isProductScheme,
      "delivered_qty": deliveredQty,
      "delivered_date": deliveredDate?.toIso8601String().split('T').first,
      "status": status,
      "cancellation_history":
      cancellationHistory?.map((x) => x.toJson()).toList(),
    };
  }

  OrderDetailsModel copyWith({
    String? notes,
    List<String>? deliveryNotes,    // ✅ NEW
    String? deliveryNote,           // ✅ NEW
    String? productId,
    String? productBrand,
    String? productName,
    String? productModel,
    String? productType,
    int? productPrice,
    int? discountPrice,
    int? qtyOrdered,
    DateTime? deliveryDate,
    DateTime? deliveredDate,
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
    String? orderDetailsNumber,
    bool? hasUnpacked,
    bool? hasProduction,
    bool? hasPackedCompleted,
    bool? hasProductionCompleted,
    String? newStatus,
    int? cancelQty,
    int? totalCancelledQty,
    String? reasonForCancellation,
    List<CancellationHistoryModel>? cancellationHistory,
    bool? isDeliveryDateUpdated,
    bool? isReasonUpdated,
    bool? isDeliveredQtyUpdated,

    // Sentinel flags to force-clear nullable fields
    bool clearHasPackedCompleted = false,
    bool clearHasProductionCompleted = false,
    bool clearNextStatus = false,
    bool clearCancelQty = false,
    bool clearReasonForCancellation = false,
    bool clearDeliveryNote = false,   // ✅ NEW
  }) {
    return OrderDetailsModel(
      notes: notes ?? this.notes,
      deliveryNotes: deliveryNotes ?? this.deliveryNotes,   // ✅ NEW
      deliveryNote: clearDeliveryNote                        // ✅ NEW
          ? null
          : (deliveryNote ?? this.deliveryNote),
      productId: productId ?? this.productId,
      productBrand: productBrand ?? this.productBrand,
      productName: productName ?? this.productName,
      productModel: productModel ?? this.productModel,
      productType: productType ?? this.productType,
      productPrice: productPrice ?? this.productPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      qtyOrdered: qtyOrdered ?? this.qtyOrdered,
      deliveryDate: deliveryDate ?? this.deliveryDate,
      deliveredDate: deliveredDate ?? this.deliveredDate,
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
      orderDetailsNumber: orderDetailsNumber ?? this.orderDetailsNumber,
      hasUnpacked: hasUnpacked ?? this.hasUnpacked,
      hasProduction: hasProduction ?? this.hasProduction,
      totalCancelledQty: totalCancelledQty ?? this.totalCancelledQty,
      cancellationHistory: cancellationHistory ?? this.cancellationHistory,
      isDeliveryDateUpdated:
      isDeliveryDateUpdated ?? this.isDeliveryDateUpdated,
      isReasonUpdated: isReasonUpdated ?? this.isReasonUpdated,
      isDeliveredQtyUpdated:
      isDeliveredQtyUpdated ?? this.isDeliveredQtyUpdated,
      // Sentinel-controlled fields
      hasPackedCompleted: clearHasPackedCompleted
          ? null
          : (hasPackedCompleted ?? this.hasPackedCompleted),
      hasProductionCompleted: clearHasProductionCompleted
          ? null
          : (hasProductionCompleted ?? this.hasProductionCompleted),
      nextStatus: clearNextStatus ? null : (newStatus ?? nextStatus),
      cancelQty: clearCancelQty ? null : (cancelQty ?? this.cancelQty),
      reasonForCancellation: clearReasonForCancellation
          ? null
          : (reasonForCancellation ?? this.reasonForCancellation),
    );
  }

  @override
  String toString() =>
      'OrderDetailsModel(productId: $productId, productName: $productName, qtyOrdered: $qtyOrdered)';
}

