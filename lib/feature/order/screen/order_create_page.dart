import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/const/icons.dart';
import '../../../model/brand_model.dart';
import '../../../model/dealer_discount_model.dart';
import '../../../model/order_model.dart';
import '../../../model/product_model.dart';
import '../../signup/model/user_model.dart';
import '../../../widgets/circle_button.dart';
import '../../brand/controller/brand_controller.dart';
import '../../discount/controller/discount_controller.dart';
import '../../product/controller/product_controller.dart';
import '../../signup/controller/signUp_controller.dart';
import '../../signup/repository/signUp_repository.dart';
import '../controller/order_controller.dart';

// ── Zoho Books design tokens ──────────────────────────────────────────────────
const _kP = Color(0xFF185FA5);
const _kPBg = Color(0xFFEBF4FF);
const _kPBd = Color(0xFFBFD9F5);
const _kBg = Color(0xFFF7F8FA);
const _kWhite = Colors.white;
const _kBd = Color(0xFFE5E7EB);
const _kT1 = Color(0xFF111827);
const _kT2 = Color(0xFF374151);
const _kT3 = Color(0xFF6B7280);
const _kT4 = Color(0xFF9CA3AF);
const _kGreen = Color(0xFF0F6E56);
const _kGreenBg = Color(0xFFEDFAF5);
const _kGreenBd = Color(0xFF9FE0C5);
const _kRed = Color(0xFFDC2626);
const _kRedBg = Color(0xFFFEF2F2);
const _kRedBd = Color(0xFFFECACA);
const _kAmber = Color(0xFFB45309);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBd = Color(0xFFFCD28A);
const _kPurple = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBd = Color(0xFFDDD6FE);

class OrderCreatePage extends ConsumerStatefulWidget {
  const OrderCreatePage({super.key});

  @override
  ConsumerState<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends ConsumerState<OrderCreatePage> {
  UserModel? selectedDealer;
  BrandModel? selectedBrand;
  ProductModel? selectedProduct;
  UserModel? selectedSalesman;
  String selectedPriority = 'LOW';
  final priorities = ['HIGH', 'MEDIUM', 'LOW'];
  String paymentMethod = 'CASH';
  num amountPaid = 0;
  bool isCreatingOrder = false;
  List<ProductModel> _allFetchedProducts = [];
  String? selectedModelFilter;
  List<String> _availableModels = [];
  String? currentUserRole;
  String? currentUserId;
  bool isLoadingUserInfo = true;
  List<OrderDetailsModel> selectedProducts = [];
  final TextEditingController orderNoteController = TextEditingController();
  final TextEditingController amountPaidController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadCurrentUserInfo();
  }

  Future<void> _loadCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      final userId = prefs.getString('user_id');
      setState(() {
        currentUserRole = role;
        currentUserId = userId;
        isLoadingUserInfo = false;
      });
      if (role == 'ROLE_SALESMAN' && userId != null) _loadSalesmanInfo(userId);
    } catch (e) {
      debugPrint('Error loading user info: $e');
      setState(() => isLoadingUserInfo = false);
    }
  }

  Future<void> _loadSalesmanInfo(String salesmanId) async {
    try {
      final allSalesmen =
          await ref.read(usersByRoleProvider('ROLE_SALESMAN').future);
      final salesman = allSalesmen.firstWhere((s) => s.employeeId == salesmanId,
          orElse: () => throw Exception('Salesman not found'));
      if (mounted) setState(() => selectedSalesman = salesman);
    } catch (e) {
      debugPrint('Error loading salesman info: $e');
    }
  }

  bool get isSalesman => currentUserRole == 'ROLE_SALESMAN';

  @override
  void dispose() {
    orderNoteController.dispose();
    amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    if (isLoadingUserInfo) {
      return const Scaffold(
          backgroundColor: _kBg,
          body: Center(
              child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5)));
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
          child: Column(children: [
        // ── App bar ──────────────────────────────────────────────────────
        Container(
            color: _kWhite,
            padding: EdgeInsets.fromLTRB(
                sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
            child: Row(children: [
              CircularIconButton(
                  icon: Icons.arrow_back_ios_rounded,
                  onTap: () => Navigator.pop(context)),
              const Spacer(),
              Text('Create Order',
                  style: TextStyle(
                      fontSize: (sw * 0.042).clamp(14.0, 20.0),
                      fontWeight: FontWeight.w700,
                      color: _kT1,
                      letterSpacing: -0.2)),
              const Spacer(),
              SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
            ])),

        // ── Body ─────────────────────────────────────────────────────────
        Expanded(
            child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.02),
                child: Column(children: [
                  _buildSelectionCard(sw, sh),
                  SizedBox(height: sh * 0.012),
                  if (selectedProducts.isNotEmpty) ...[
                    _buildProductsCard(sw, sh),
                    SizedBox(height: sh * 0.012),
                  ],
                  _buildOrderDetailsCard(sw, sh),
                  SizedBox(height: sh * 0.02),
                ]))),

        // ── Bottom button ────────────────────────────────────────────────
        _buildBottomButton(sw, sh),
      ])),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Selection Card
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildSelectionCard(double sw, double sh) {
    return _Section(
        sw: sw,
        icon: Icons.shopping_cart_outlined,
        iconBg: _kPBg,
        iconColor: _kP,
        title: 'Order Selection',
        child: Column(children: [
          if (!isSalesman) ...[
            _SelectorTile(
                sw: sw,
                label: 'Salesman',
                value: selectedSalesman?.employeeName,
                icon: Icons.person_outline_rounded,
                color: _kPurple,
                onTap: () => _showSalesmanDialog(context)),
            SizedBox(height: sh * 0.01),
          ],
          _SelectorTile(
              enabled: isSalesman || selectedSalesman != null,
              sw: sw,
              label: 'Dealer',
              value: selectedDealer != null
                  ? '${selectedDealer!.employeeName}${selectedDealer!.shopName != null ? ' (${selectedDealer!.shopName})' : ''}'
                  : null,
              icon: Icons.store_outlined,
              color: _kP,
              onTap: () => _showDealerDialog(context)),
          SizedBox(height: sh * 0.01),
          _SelectorTile(
              sw: sw,
              label: 'Brand',
              value: selectedBrand?.brandName,
              icon: Icons.local_offer_outlined,
              color: _kAmber,
              enabled: selectedDealer != null,
              onTap: selectedDealer == null
                  ? null
                  : () =>
                      _showBrandDialog(context, selectedDealer!.employeeId!)),
          SizedBox(height: sh * 0.01),
          _SelectorTile(
              sw: sw,
              label: 'Model',
              value: selectedModelFilter,
              fallback: 'All Models',
              icon: Icons.tag_rounded,
              color: _kP,
              enabled: selectedBrand != null,
              onTap: selectedBrand == null
                  ? null
                  : () => _showModelDialog(context)),
          SizedBox(height: sh * 0.01),
          _SelectorTile(
              sw: sw,
              label: 'Product',
              value: selectedProduct?.productName,
              subtitle: selectedProduct?.productType,
              icon: Icons.inventory_2_outlined,
              color: _kGreen,
              enabled: selectedBrand != null,
              onTap: selectedBrand == null
                  ? null
                  : () =>
                      _showProductDialog(context, [selectedBrand!.brandName])),
        ]));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Products Card
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildProductsCard(double sw, double sh) {
    return _Section(
        sw: sw,
        icon: Icons.inventory_outlined,
        iconBg: _kGreenBg,
        iconColor: _kGreen,
        title: 'Selected Products',
        trailing: _CountBadge(
            count: selectedProducts.length,
            color: _kGreen,
            bg: _kGreenBg,
            bd: _kGreenBd),
        bottomChild: Container(
            padding: EdgeInsets.all(sw * 0.04),
            decoration: BoxDecoration(
                color: _kGreenBg,
                borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular((sw * 0.04).clamp(10.0, 18.0)),
                    bottomRight:
                        Radius.circular((sw * 0.04).clamp(10.0, 18.0))),
                border: const Border(
                    top: BorderSide(color: _kGreenBd, width: 0.5))),
            child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Order Total',
                      style: TextStyle(
                          fontSize: (sw * 0.036).clamp(12.0, 16.0),
                          fontWeight: FontWeight.w800,
                          color: _kGreen)),
                  Text('₹${_calculateOrderTotal().toStringAsFixed(2)}',
                      style: TextStyle(
                          fontSize: (sw * 0.042).clamp(14.0, 20.0),
                          fontWeight: FontWeight.w900,
                          color: _kGreen)),
                ])),
        child: Column(children: [
          ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedProducts.length,
              separatorBuilder: (_, __) => Divider(height: 1, color: _kBd),
              itemBuilder: (_, i) =>
                  _buildProductItem(selectedProducts[i], i, sw, sh)),
        ]));
  }

  Widget _buildProductItem(
      OrderDetailsModel product, int index, double sw, double sh) {
    double price =
        double.tryParse(product.product?.price?.toString() ?? '0') ?? 0;
    int qty = product.quantity;
    double unitDiscount = 0;
    final discount = product.dealerDiscount;
    if (product.useDealerDiscount && discount != null) {
      unitDiscount = discount.isPercentage == true
          ? price * (discount.discountValue / 100)
          : discount.discountValue.toDouble();
    } else if (!product.useDealerDiscount && product.discountAmount != null) {
      unitDiscount = product.discountAmount!.toDouble();
    }
    double subtotal = price * qty;
    double discountTotal = unitDiscount * qty;
    double total = subtotal - discountTotal;

    return Padding(
        padding: EdgeInsets.all(sw * 0.04),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Header
          Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(product.product?.productName ?? product.productName,
                      style: TextStyle(
                          fontSize: (sw * 0.036).clamp(12.0, 16.0),
                          fontWeight: FontWeight.w700,
                          color: _kT1)),
                  SizedBox(height: sw * 0.008),
                      Wrap(
                        spacing: sw * 0.015,
                        runSpacing: sw * 0.008,
                        children: [
                          _Chip(
                              sw: sw,
                              text: product.product?.brand ?? product.productBrand,
                              icon: Icons.local_offer_outlined,
                              color: _kAmber),
                          _Chip(
                              sw: sw,
                              text: product.product?.model ?? product.productModel,
                              icon: Icons.tag_rounded,
                              color: _kP),
                          if ((product.product?.productType ?? '').isNotEmpty)
                            _Chip(
                                sw: sw,
                                text: product.product!.productType!,
                                icon: Icons.category_outlined,
                                color: _kPurple),
                        ],
                      ),
                ])),
            IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: _kRed, size: (sw * 0.055).clamp(20.0, 26.0)),
                onPressed: () =>
                    setState(() => selectedProducts.removeAt(index))),
          ]),
          SizedBox(height: sh * 0.015),

          // Quantity
          Row(children: [
            Text('Quantity',
                style: TextStyle(
                    fontSize: (sw * 0.03).clamp(10.0, 13.0),
                    fontWeight: FontWeight.w600,
                    color: _kT4)),
            SizedBox(width: sw * 0.025),
            _QtyBtn(
                sw: sw,
                icon: Icons.remove,
                onTap: product.quantity > 1
                    ? () => setState(() {
                          selectedProducts[index] = product.copyWith(
                              qtyOrdered: product.quantity - 1);
                        })
                    : null),
            SizedBox(width: sw * 0.02),
            Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.035, vertical: sw * 0.015),
                decoration: BoxDecoration(
                    color: _kPBg,
                    borderRadius:
                        BorderRadius.circular((sw * 0.02).clamp(6.0, 10.0)),
                    border: Border.all(color: _kPBd, width: 0.5)),
                child: Text('${product.quantity}',
                    style: TextStyle(
                        fontSize: (sw * 0.036).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w700,
                        color: _kP))),
            SizedBox(width: sw * 0.02),
            _QtyBtn(
                sw: sw,
                icon: Icons.add,
                onTap: () => setState(() {
                      selectedProducts[index] =
                          product.copyWith(qtyOrdered: product.quantity + 1);
                    })),
            const Spacer(),
            Text('₹$price',
                style: TextStyle(
                    fontSize: (sw * 0.034).clamp(11.5, 15.0),
                    fontWeight: FontWeight.w600,
                    color: _kT2)),
          ]),
          SizedBox(height: sh * 0.015),

          // Scheme toggle
          Row(children: [
            Icon(Icons.card_giftcard_outlined,
                size: (sw * 0.045).clamp(15.0, 20.0), color: _kPurple),
            SizedBox(width: sw * 0.02),
            Text('Scheme Product',
                style: TextStyle(
                    fontSize: (sw * 0.032).clamp(11.0, 14.0),
                    fontWeight: FontWeight.w600,
                    color: _kT1)),
            const Spacer(),
            Switch(
                value: product.isScheme,
                activeColor: _kPurple,
                activeTrackColor: _kPurpleBg,
                onChanged: (v) => setState(() {
                      selectedProducts[index] =
                          product.copyWith(isProductScheme: v);
                    })),
          ]),

          // Discount
          if (selectedDealer != null)
            _buildDiscountOptions(product, index, sw, sh),
          SizedBox(height: sh * 0.015),

          // Delivery date
          GestureDetector(
              onTap: () => _selectDeliveryDate(context, product, index),
              child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.04, vertical: sw * 0.03),
                  decoration: BoxDecoration(
                      color: _kBg,
                      borderRadius:
                          BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                      border: Border.all(
                          color: product.deliveryDate == null ? _kRed : _kBd,
                          width: 0.5)),
                  child: Row(children: [
                    Icon(Icons.calendar_today_outlined,
                        size: (sw * 0.04).clamp(13.0, 18.0),
                        color: product.deliveryDate != null ? _kP : _kT4),
                    SizedBox(width: sw * 0.025),
                    Text(
                        product.deliveryDate != null
                            ? '${product.deliveryDate!.day}/${product.deliveryDate!.month}/${product.deliveryDate!.year}'
                            : 'Select Delivery Date',
                        style: TextStyle(
                            fontSize: (sw * 0.032).clamp(11.0, 14.0),
                            fontWeight: FontWeight.w500,
                            color: product.deliveryDate != null ? _kT1 : _kT4)),
                  ]))),
          if (product.deliveryDate == null)
            Padding(
                padding: EdgeInsets.only(top: sw * 0.015, left: sw * 0.01),
                child: Row(children: [
                  Icon(Icons.warning_amber_rounded,
                      size: (sw * 0.035).clamp(12.0, 16.0), color: _kRed),
                  SizedBox(width: sw * 0.01),
                  Text('Delivery date required',
                      style: TextStyle(
                          fontSize: (sw * 0.028).clamp(9.5, 12.5),
                          color: _kRed)),
                ])),

          // Price breakdown
          if (!product.isProductScheme) ...[
            SizedBox(height: sh * 0.015),
            Container(
                padding: EdgeInsets.all(sw * 0.03),
                decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius:
                        BorderRadius.circular((sw * 0.025).clamp(6.0, 12.0))),
                child: Column(children: [
                  _PriceRow(sw: sw, label: 'Subtotal', amount: subtotal),
                  SizedBox(height: sw * 0.01),
                  _PriceRow(sw: sw, label: 'Discount', amount: -discountTotal),
                  SizedBox(height: sw * 0.01),
                  Divider(height: 1, color: _kBd),
                  SizedBox(height: sw * 0.01),
                  _PriceRow(
                      sw: sw, label: 'Total', amount: total, isBold: true),
                ])),
          ],
        ]));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Order Details Card
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildOrderDetailsCard(double sw, double sh) {
    return _Section(
        sw: sw,
        icon: Icons.description_outlined,
        iconBg: _kPurpleBg,
        iconColor: _kPurple,
        title: 'Order Details',
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Notes
          Text('Order Notes',
              style: TextStyle(
                  fontSize: (sw * 0.032).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w600,
                  color: _kT1)),
          SizedBox(height: sh * 0.008),
          TextFormField(
              controller: orderNoteController,
              minLines: 3,
              maxLines: 5,
              style: TextStyle(
                  fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1),
              decoration: _inputDeco(
                  sw, 'Add special instructions or notes (optional)')),
          SizedBox(height: sh * 0.02),

          // Priority
          Text('Priority',
              style: TextStyle(
                  fontSize: (sw * 0.032).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w600,
                  color: _kT1)),
          SizedBox(height: sh * 0.012),
          Row(
              children: priorities.map((p) {
            final sel = selectedPriority == p;
            final c = p == 'HIGH'
                ? _kRed
                : p == 'MEDIUM'
                    ? _kAmber
                    : _kGreen;
            return Expanded(
                child: GestureDetector(
                    onTap: () => setState(() => selectedPriority = p),
                    child: Container(
                        margin: EdgeInsets.only(right: sw * 0.015),
                        padding: EdgeInsets.symmetric(vertical: sw * 0.025),
                        decoration: BoxDecoration(
                            color: sel ? c.withValues(alpha: 0.1) : _kBg,
                            borderRadius: BorderRadius.circular(
                                (sw * 0.025).clamp(8.0, 12.0)),
                            border: Border.all(
                                color: sel ? c : _kBd, width: sel ? 1.0 : 0.5)),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                  sel
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: c,
                                  size: (sw * 0.045).clamp(15.0, 20.0)),
                              SizedBox(width: sw * 0.015),
                              Text(p,
                                  style: TextStyle(
                                      fontSize: (sw * 0.03).clamp(10.0, 13.0),
                                      fontWeight: FontWeight.w700,
                                      color: c)),
                            ]))));
          }).toList()),
          SizedBox(height: sh * 0.02),

          // Amount paid
          Text('Amount Paid',
              style: TextStyle(
                  fontSize: (sw * 0.032).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w600,
                  color: _kT1)),
          SizedBox(height: sh * 0.008),
          TextFormField(
              controller: amountPaidController,
              keyboardType: TextInputType.number,
              style: TextStyle(
                  fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
              decoration: _inputDeco(sw, 'Enter amount',
                  prefix: Icon(Icons.currency_rupee,
                      color: _kGreen, size: (sw * 0.045).clamp(15.0, 20.0))),
              onChanged: (v) =>
                  setState(() => amountPaid = num.tryParse(v) ?? 0)),
          SizedBox(height: sh * 0.02),

          // Payment method
          Text('Payment Method',
              style: TextStyle(
                  fontSize: (sw * 0.032).clamp(11.0, 14.0),
                  fontWeight: FontWeight.w600,
                  color: _kT1)),
          SizedBox(height: sh * 0.012),
          Row(children: [
            _PayMethodBtn(
                sw: sw,
                label: 'Cash',
                icon: Icons.payments_outlined,
                color: _kGreen,
                bg: _kGreenBg,
                bd: _kGreenBd,
                selected: paymentMethod == 'CASH',
                onTap: () => setState(() => paymentMethod = 'CASH')),
            SizedBox(width: sw * 0.02),
            _PayMethodBtn(
                sw: sw,
                label: 'Bank',
                icon: Icons.account_balance_outlined,
                color: _kP,
                bg: _kPBg,
                bd: _kPBd,
                selected: paymentMethod == 'BANK',
                onTap: () => setState(() => paymentMethod = 'BANK')),
          ]),
        ]));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Bottom Button
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildBottomButton(double sw, double sh) {
    final canCreate = _canCreateOrder();
    return Container(
        padding: EdgeInsets.all(sw * 0.04),
        decoration: const BoxDecoration(
            color: _kWhite,
            border: Border(top: BorderSide(color: _kBd, width: 0.5))),
        child: SafeArea(
            top: false,
            child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                    onPressed:
                        canCreate && !isCreatingOrder ? _createOrder : null,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kP,
                        foregroundColor: _kWhite,
                        disabledBackgroundColor: _kBd,
                        disabledForegroundColor: _kT4,
                        padding: EdgeInsets.symmetric(vertical: sh * 0.018),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                (sw * 0.035).clamp(10.0, 16.0))),
                        elevation: 0),
                    child: isCreatingOrder
                        ? SizedBox(
                            height: (sw * 0.05).clamp(16.0, 22.0),
                            width: (sw * 0.05).clamp(16.0, 22.0),
                            child: const CircularProgressIndicator(
                                color: _kWhite, strokeWidth: 2.5))
                        : Text('Create Order',
                            style: TextStyle(
                                fontSize: (sw * 0.04).clamp(13.0, 18.0),
                                fontWeight: FontWeight.w700))))));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Discount Options
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildDiscountOptions(
      OrderDetailsModel product, int index, double sw, double sh) {
    final discount = product.dealerDiscount;

    if (discount == null) {
      return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(height: sh * 0.015),
        Text('Manual Discount',
            style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0),
                fontWeight: FontWeight.w600,
                color: _kT1)),
        SizedBox(height: sh * 0.008),
        TextFormField(
            initialValue: product.discountAmount?.toString() ?? '',
            keyboardType: TextInputType.number,
            style: TextStyle(
                fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1),
            decoration: _inputDeco(sw, 'Enter discount amount',
                prefix: Icon(Icons.local_offer_outlined,
                    color: _kAmber, size: (sw * 0.045).clamp(15.0, 20.0))),
            onChanged: (v) => setState(() {
                  selectedProducts[index] = product.copyWith(
                      discountAmount: num.tryParse(v),
                      useDealerDiscount: false);
                })),
      ]);
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SizedBox(height: sh * 0.015),
      Text('Discount',
          style: TextStyle(
              fontSize: (sw * 0.03).clamp(10.0, 13.0),
              fontWeight: FontWeight.w600,
              color: _kT1)),
      SizedBox(height: sh * 0.01),
      Row(children: [
        Expanded(
            child: _ToggleBtn(
                sw: sw,
                label: 'Manual',
                color: _kAmber,
                bg: _kAmberBg,
                bd: _kAmberBd,
                selected: !product.useDealerDiscount,
                onTap: () => setState(() {
                      selectedProducts[index] = product.copyWith(
                          useDealerDiscount: false,
                          dealerDiscountId: null,
                          discountAmount: 0);
                    }))),
        SizedBox(width: sw * 0.02),
        Expanded(
            child: _ToggleBtn(
                sw: sw,
                label: 'Dealer',
                color: _kGreen,
                bg: _kGreenBg,
                bd: _kGreenBd,
                selected: product.useDealerDiscount,
                onTap: () => setState(() {
                      selectedProducts[index] = product.copyWith(
                          useDealerDiscount: true,
                          discountAmount: null,
                          dealerDiscountId: discount.dealerDiscountId);
                    }))),
      ]),
      if (!product.useDealerDiscount) ...[
        SizedBox(height: sh * 0.01),
        TextFormField(
            initialValue: product.discountAmount?.toString() ?? '',
            keyboardType: TextInputType.number,
            style: TextStyle(
                fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1),
            decoration: _inputDeco(sw, 'Enter amount'),
            onChanged: (v) => setState(() {
                  selectedProducts[index] =
                      product.copyWith(discountAmount: num.tryParse(v) ?? 0);
                })),
      ],
      if (product.useDealerDiscount) ...[
        SizedBox(height: sh * 0.01),
        Container(
            padding: EdgeInsets.all(sw * 0.035),
            decoration: BoxDecoration(
                color: _kGreenBg,
                borderRadius:
                    BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                border: Border.all(color: _kGreenBd, width: 0.5)),
            child: Row(children: [
              Icon(Icons.discount_outlined,
                  color: _kGreen, size: (sw * 0.045).clamp(15.0, 20.0)),
              SizedBox(width: sw * 0.025),
              Text(
                  '${discount.isPercentage == false ? '₹' : ''}${discount.discountValue}${discount.isPercentage ? '%' : ''}',
                  style: TextStyle(
                      fontSize: (sw * 0.036).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w700,
                      color: _kGreen)),
            ])),
      ],
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Shared input decoration
  // ══════════════════════════════════════════════════════════════════════════
  InputDecoration _inputDeco(double sw, String hint, {Widget? prefix}) {
    final r = (sw * 0.028).clamp(8.0, 12.0);
    return InputDecoration(
        hintText: hint,
        hintStyle:
            TextStyle(fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4),
        prefixIcon: prefix,
        filled: true,
        fillColor: _kBg,
        contentPadding: EdgeInsets.all(sw * 0.035),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kP, width: 1.5)));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Dialogs — logic unchanged, UI Zoho tokens
  // ══════════════════════════════════════════════════════════════════════════
  Future<void> _showDealerDialog(BuildContext context) async {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    showDialog(
      context: context,
      builder: (_) => _DealerSearchDialog(
        sw: sw,
        sh: sh,
        salesmanId: selectedSalesman?.employeeId,
        salesmanName: selectedSalesman?.employeeName, // ← name for display
        onSelected: (dealer) {
          setState(() {
            selectedDealer = dealer;
            selectedBrand = null;
            selectedModelFilter = null;
            selectedProduct = null;
            selectedProducts.clear();
            _allFetchedProducts.clear();
            _availableModels.clear();
          });
        },
      ),
    );
  }

  Future<void> _showBrandDialog(BuildContext context, String dealerId) async {
    final searchController = TextEditingController();
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    showDialog(
      context: context,
      builder: (ctx) => Consumer(
        // ← Consumer here, not inside content
        builder: (_, ref, __) {
          final brandAsync = ref.watch(dealerBrandsProvider(dealerId));
          return brandAsync.when(
            loading: () => const AlertDialog(
              backgroundColor: _kWhite,
              content: SizedBox(
                height: 100,
                child: Center(
                  child:
                      CircularProgressIndicator(color: _kP, strokeWidth: 2.5),
                ),
              ),
            ),
            error: (e, _) => AlertDialog(
              title: const Text('Brands'),
              content: Text(e.toString()),
            ),
            data: (brands) {
              final query = ValueNotifier('');
              return AlertDialog(
                backgroundColor: _kWhite,
                shape: RoundedRectangleBorder(
                  borderRadius:
                      BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
                ),
                title: Text('Select Brand',
                    style: TextStyle(
                        fontSize: (sw * 0.042).clamp(14.0, 20.0),
                        fontWeight: FontWeight.w700,
                        color: _kT1)),
                content: SizedBox(
                  width: double.maxFinite,
                  child: Column(mainAxisSize: MainAxisSize.min, children: [
                    _dialogSearchField(
                        ctx, searchController, 'Search brand name', query),
                    SizedBox(height: sh * 0.02),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: query,
                        builder: (_, q, __) {
                          final filtered = brands
                              .where(
                                  (b) => b.brandName.toLowerCase().contains(q))
                              .toList();
                          if (filtered.isEmpty) {
                            return Center(
                              child: Text('No brands found',
                                  style: TextStyle(
                                      color: _kT4,
                                      fontSize:
                                          (sw * 0.034).clamp(11.5, 15.0))),
                            );
                          }
                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final b = filtered[i];
                              return _dialogListItem(ctx,
                                  title: b.brandName,
                                  leading: SvgPicture.asset(AppIcons.brand,
                                      width: sw * 0.06), onTap: () {
                                setState(() {
                                  selectedBrand = b;
                                  selectedModelFilter = null;
                                  selectedProduct = null;
                                  _allFetchedProducts.clear();
                                  _availableModels.clear();
                                });
                                Navigator.pop(ctx);
                              });
                            },
                          );
                        },
                      ),
                    ),
                  ]),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showSalesmanDialog(BuildContext context) async {
    final searchController = TextEditingController();
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final future = ref.read(usersByRoleProvider('ROLE_SALESMAN').future);
    showDialog(
        context: context,
        builder: (ctx) => FutureBuilder<List<UserModel>>(
            future: future,
            builder: (_, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const AlertDialog(
                    backgroundColor: _kWhite,
                    content: Center(
                        child: CircularProgressIndicator(
                            color: _kP, strokeWidth: 2.5)));
              }
              if (snap.hasError)
                return AlertDialog(
                    title: const Text('Salesmen'),
                    content: Text(snap.error.toString()));
              final salesmen = snap.data ?? [];
              final query = ValueNotifier('');
              return AlertDialog(
                  backgroundColor: _kWhite,
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0))),
                  title: Text('Select Salesman',
                      style: TextStyle(
                          fontSize: (sw * 0.042).clamp(14.0, 20.0),
                          fontWeight: FontWeight.w700,
                          color: _kT1)),
                  content: SizedBox(
                      width: double.maxFinite,
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        _dialogSearchField(ctx, searchController,
                            'Search by name or phone', query),
                        SizedBox(height: sh * 0.02),
                        Expanded(
                            child: ValueListenableBuilder<String>(
                                valueListenable: query,
                                builder: (_, q, __) {
                                  final filtered = salesmen.where((s) {
                                    return s.employeeName
                                            .toLowerCase()
                                            .contains(q) ||
                                        s.employeePhone
                                            .toLowerCase()
                                            .contains(q);
                                  }).toList();
                                  if (filtered.isEmpty)
                                    return Center(
                                        child: Text('No salesmen found',
                                            style: TextStyle(
                                                color: _kT4,
                                                fontSize: (sw * 0.034)
                                                    .clamp(11.5, 15.0))));
                                  return ListView.builder(
                                      itemCount: filtered.length,
                                      itemBuilder: (_, i) {
                                        final s = filtered[i];
                                        return _dialogListItem(ctx,
                                            title: s.employeeName,
                                            subtitle: s.employeePhone,
                                          onTap: () {
                                            setState(() {
                                              selectedSalesman = s;
                                              // ── reset dealer & downstream when salesman changes
                                              selectedDealer = null;
                                              selectedBrand = null;
                                              selectedModelFilter = null;
                                              selectedProduct = null;
                                              selectedProducts.clear();
                                              _allFetchedProducts.clear();
                                              _availableModels.clear();
                                            });
                                            Navigator.pop(ctx);
                                          },
                                        );
                                      });
                                })),
                      ])));
            }));
  }

  Future<void> _showModelDialog(BuildContext context) async {
    final searchController = TextEditingController();
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    if (_allFetchedProducts.isEmpty) {
      _allFetchedProducts = await ref
          .read(productControllerProvider.notifier)
          .fetchProductsByBrand([selectedBrand!.brandName]);
    }
    _availableModels = [
      ...<String>{}..addAll(_allFetchedProducts
          .map((p) => p.model ?? '')
          .where((m) => m.isNotEmpty))
    ]..sort();
    final query = ValueNotifier('');
    if (!context.mounted) return;
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            backgroundColor: _kWhite,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0))),
            title: Text('Select Model',
                style: TextStyle(
                    fontSize: (sw * 0.042).clamp(14.0, 20.0),
                    fontWeight: FontWeight.w700,
                    color: _kT1)),
            content: SizedBox(
                width: double.maxFinite,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _dialogSearchField(
                      ctx, searchController, 'Search model', query),
                  SizedBox(height: sh * 0.015),
                  Expanded(
                      child: ValueListenableBuilder<String>(
                          valueListenable: query,
                          builder: (_, q, __) {
                            final filtered = _availableModels
                                .where((m) => m.toLowerCase().contains(q))
                                .toList();
                            return ListView.builder(
                                itemCount: filtered.length + 1,
                                itemBuilder: (_, i) {
                                  if (i == 0) {
                                    final sel = selectedModelFilter == null;
                                    return _dialogSelectItem(ctx, sw,
                                        title: 'All Models',
                                        icon: Icons.all_inclusive_rounded,
                                        selected: sel, onTap: () {
                                      setState(() {
                                        selectedModelFilter = null;
                                        selectedProduct = null;
                                      });
                                      Navigator.pop(ctx);
                                    });
                                  }
                                  final model = filtered[i - 1];
                                  final sel = selectedModelFilter == model;
                                  return _dialogSelectItem(ctx, sw,
                                      title: model,
                                      icon: Icons.tag_rounded,
                                      selected: sel, onTap: () {
                                    setState(() {
                                      selectedModelFilter = model;
                                      selectedProduct = null;
                                    });
                                    Navigator.pop(ctx);
                                  });
                                });
                          })),
                ]))));
  }

  Future<void> _showProductDialog(
      BuildContext context, List<String> brands) async {
    final searchController = TextEditingController();
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    if (_allFetchedProducts.isEmpty) {
      _allFetchedProducts = await ref
          .read(productControllerProvider.notifier)
          .fetchProductsByBrand(brands);
    }
    final localFiltered = _allFetchedProducts.where((p) {
      final matchBrand =
          brands.any((b) => b.toLowerCase() == (p.brand ?? '').toLowerCase());
      final matchModel =
          selectedModelFilter == null || (p.model ?? '') == selectedModelFilter;
      return matchBrand && matchModel;
    }).toList();
    final models = [
      'All',
      ...{...localFiltered.map((p) => p.model ?? '')}
          .where((m) => m.isNotEmpty)
          .toList()
        ..sort()
    ];
    final query = ValueNotifier('');
    final selectedModel = ValueNotifier<String>('All');
    if (!context.mounted) return;
    showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
            backgroundColor: _kWhite,
            shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0))),
            title: Text('Select Product',
                style: TextStyle(
                    fontSize: (sw * 0.042).clamp(14.0, 20.0),
                    fontWeight: FontWeight.w700,
                    color: _kT1)),
            content: SizedBox(
                width: double.maxFinite,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  _dialogSearchField(ctx, searchController,
                      'Search product name or model', query),
                  SizedBox(height: sh * 0.015),
                  // Model chips
                  SizedBox(
                      height: sw * 0.09,
                      child: ValueListenableBuilder<String>(
                          valueListenable: selectedModel,
                          builder: (_, cur, __) {
                            return ListView.builder(
                                scrollDirection: Axis.horizontal,
                                itemCount: models.length,
                                itemBuilder: (_, i) {
                                  final m = models[i];
                                  final sel = cur == m;
                                  return GestureDetector(
                                      onTap: () => selectedModel.value = m,
                                      child: Container(
                                          margin:
                                              EdgeInsets.only(right: sw * 0.02),
                                          padding: EdgeInsets.symmetric(
                                              horizontal: sw * 0.03,
                                              vertical: sw * 0.015),
                                          decoration: BoxDecoration(
                                              color: sel ? _kPBg : _kBg,
                                              borderRadius:
                                                  BorderRadius.circular(20),
                                              border: Border.all(
                                                  color: sel ? _kPBd : _kBd,
                                                  width: sel ? 1.0 : 0.5)),
                                          child: Text(m,
                                              style: TextStyle(
                                                  fontSize: (sw * 0.028)
                                                      .clamp(9.5, 12.5),
                                                  fontWeight: FontWeight.w600,
                                                  color: sel ? _kP : _kT4))));
                                });
                          })),
                  SizedBox(height: sh * 0.015),
                  // Product list
                  Expanded(
                      child: ValueListenableBuilder<String>(
                          valueListenable: query,
                          builder: (_, q, __) {
                            return ValueListenableBuilder<String>(
                                valueListenable: selectedModel,
                                builder: (_, cur, __) {
                                  final filtered = localFiltered.where((p) {
                                    final name =
                                        p.productName?.toLowerCase() ?? '';
                                    final model = p.model?.toLowerCase() ?? '';
                                    final matchSearch =
                                        name.contains(q) || model.contains(q);
                                    final matchModel =
                                        cur == 'All' || (p.model ?? '') == cur;
                                    return matchSearch && matchModel;
                                  }).toList();
                                  if (filtered.isEmpty)
                                    return Center(
                                        child: Text('No products found',
                                            style: TextStyle(
                                                color: _kT4,
                                                fontSize: (sw * 0.034)
                                                    .clamp(11.5, 15.0))));
                                  return ListView.builder(
                                      itemCount: filtered.length,
                                      itemBuilder: (_, i) {
                                        final p = filtered[i];
                                        final added = _isProductAlreadyAdded(p);
                                        return Container(
                                            margin: EdgeInsets.only(
                                                bottom: sw * 0.02),
                                            decoration: BoxDecoration(
                                                color: added ? _kGreenBg : _kBg,
                                                borderRadius: BorderRadius.circular((sw * 0.028)
                                                    .clamp(8.0, 12.0)),
                                                border: Border.all(
                                                    color: added
                                                        ? _kGreenBd
                                                        : _kBd,
                                                    width: 0.5)),
                                            child: ListTile(
                                                leading: SvgPicture.asset(AppIcons.product,
                                                    width: sw * 0.06,
                                                    colorFilter: ColorFilter.mode(
                                                        added ? _kGreen : _kP,
                                                        BlendMode.srcIn)),
                                                title: Text(p.productName.toString(),
                                                    style: TextStyle(
                                                        fontWeight: FontWeight.w600,
                                                        color: _kT1,
                                                        fontSize: (sw * 0.034).clamp(11.5, 15.0))),
                                                subtitle: Wrap(
                                                    spacing: sw * 0.015,
                                                    children: [
                                                      if ((p.model ?? '').isNotEmpty)
                                                        _Chip(sw: sw, text: p.model!, icon: Icons.tag_rounded, color: _kP),
                                                      if ((p.productType ?? '').isNotEmpty)
                                                        _Chip(sw: sw, text: p.productType!, icon: Icons.category_outlined, color: _kPurple),
                                                    ],),
                                                trailing: added ? const Icon(Icons.check_circle, color: _kGreen) : null,
                                                onTap: () async {
                                                  DealerDiscountModel? discount;
                                                  try {
                                                    discount = await ref.read(
                                                        dealerProductDiscountProvider({
                                                      'dealerId':
                                                          selectedDealer!
                                                              .employeeId!,
                                                      'productId': p.productId!,
                                                    }).future);
                                                  } catch (e) {
                                                    debugPrint(
                                                        'Discount fetch: $e');
                                                  }
                                                  setState(() {
                                                    selectedProducts.add(
                                                        OrderDetailsModel
                                                            .fromProduct(p,
                                                                dealerDiscount:
                                                                    discount));
                                                  });
                                                  if (!ctx.mounted) return;
                                                  Navigator.pop(ctx);
                                                }));
                                      });
                                });
                          })),
                ]))));
  }

  // ── Dialog helpers ────────────────────────────────────────────────────────
  Widget _dialogSearchField(BuildContext ctx, TextEditingController ctrl,
      String hint, ValueNotifier<String> query) {
    final sw = MediaQuery.sizeOf(ctx).width;
    return TextField(
        controller: ctrl,
        style: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1),
        decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4),
            prefixIcon: Icon(Icons.search_rounded,
                size: (sw * 0.05).clamp(16.0, 22.0), color: _kT4),
            filled: true,
            fillColor: _kBg,
            border: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                borderSide: const BorderSide(color: _kBd, width: 0.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                borderSide: const BorderSide(color: _kBd, width: 0.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius:
                    BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                borderSide: const BorderSide(color: _kP, width: 1.5))),
        onChanged: (v) => query.value = v.toLowerCase());
  }

  Widget _dialogListItem(BuildContext ctx,
      {required String title,
      String? subtitle,
      Widget? leading,
      required VoidCallback onTap}) {
    final sw = MediaQuery.sizeOf(ctx).width;
    return Container(
        margin: EdgeInsets.only(bottom: sw * 0.02),
        decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        child: ListTile(
            leading: leading,
            title: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: _kT1,
                    fontSize: (sw * 0.034).clamp(11.5, 15.0))),
            subtitle: subtitle != null
                ? Text(subtitle,
                    style: TextStyle(
                        color: _kT4, fontSize: (sw * 0.028).clamp(9.5, 12.5)))
                : null,
            onTap: onTap));
  }

  Widget _dialogSelectItem(BuildContext ctx, double sw,
      {required String title,
      required IconData icon,
      required bool selected,
      required VoidCallback onTap}) {
    return Container(
        margin: EdgeInsets.only(bottom: sw * 0.02),
        decoration: BoxDecoration(
            color: selected ? _kPBg : _kBg,
            borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
            border: Border.all(
                color: selected ? _kPBd : _kBd, width: selected ? 1.0 : 0.5)),
        child: ListTile(
            leading: Icon(icon, color: selected ? _kP : _kT4),
            title: Text(title,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: selected ? _kP : _kT1,
                    fontSize: (sw * 0.034).clamp(11.5, 15.0))),
            trailing:
                selected ? const Icon(Icons.check_circle, color: _kP) : null,
            onTap: onTap));
  }

  // ── Date picker ──────────────────────────────────────────────────────────
  Future<void> _selectDeliveryDate(
      BuildContext context, OrderDetailsModel product, int index) async {
    final picked = await showDatePicker(
        context: context,
        initialDate: product.deliveryDate ?? DateTime.now(),
        firstDate: DateTime.now(),
        lastDate: DateTime.now().add(const Duration(days: 365)),
        builder: (ctx, child) => Theme(
            data: Theme.of(ctx).copyWith(
                colorScheme: const ColorScheme.light(
                    primary: _kP,
                    onPrimary: _kWhite,
                    surface: _kWhite,
                    onSurface: _kT1),
                dialogTheme: const DialogThemeData(backgroundColor: _kWhite)),
            child: child!));
    if (picked != null)
      setState(() {
        selectedProducts[index] = product.copyWith(deliveryDate: picked);
      });
  }

  // ── Logic — unchanged ────────────────────────────────────────────────────
  bool _isProductAlreadyAdded(ProductModel product) =>
      selectedProducts.any((sp) => sp.product?.productId == product.productId);

  bool _canCreateOrder() {
    if (selectedDealer == null ||
        selectedSalesman == null ||
        selectedProducts.isEmpty ||
        amountPaid < 0) return false;
    return !selectedProducts.any((p) => p.deliveryDate == null);
  }

  void _createOrder() async {
    final missingDate = selectedProducts.any((p) => p.deliveryDate == null);
    if (missingDate) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.warning_amber_rounded, color: _kWhite),
            SizedBox(width: 12),
            Expanded(
                child: Text('Please select delivery date for all products')),
          ]),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
      return;
    }
    setState(() => isCreatingOrder = true);
    try {
      final processedProducts = selectedProducts.map((p) {
        if (p.isProductScheme == true) return p.copyWith(discountAmount: 0);
        double unitPrice =
            double.tryParse(p.product?.price?.toString() ?? '0') ?? 0;
        double calculatedDiscount = 0;
        if (p.useDealerDiscount && p.dealerDiscount != null) {
          final d = p.dealerDiscount!;
          calculatedDiscount = d.isPercentage == true
              ? unitPrice * (d.discountValue / 100)
              : d.discountValue.toDouble();
        } else if (!p.useDealerDiscount && p.discountAmount != null) {
          calculatedDiscount = p.discountAmount!.toDouble();
        }
        return p.copyWith(discountAmount: calculatedDiscount);
      }).toList();

      final order = OrderModel(
          dealerId: selectedDealer!.employeeId!,
          priority: selectedPriority,
          orderNote: orderNoteController.text,
          salesmanId: selectedSalesman!.employeeId!,
          paymentType: paymentMethod,
          amountPaid: amountPaid,
          orderDetails: processedProducts);
      await ref.read(orderControllerProvider.notifier).createOrder(order);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: const Row(children: [
            Icon(Icons.check_circle, color: _kWhite, size: 20),
            SizedBox(width: 12),
            Expanded(
                child: Text('Order created successfully!',
                    style: TextStyle(fontWeight: FontWeight.w500))),
          ]),
          backgroundColor: _kGreen,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16)));
      await ref.read(orderControllerProvider.notifier).getAllOrders();
      if (mounted) Navigator.pop(context);
    } catch (e, s) {
      debugPrint('❌ Error creating order: $e\n$s');
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Row(children: [
              const Icon(Icons.error_outline, color: _kWhite),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to create order: $e')),
            ]),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10))));
    } finally {
      if (mounted) setState(() => isCreatingOrder = false);
    }
  }

  double _calculateOrderTotal() {
    double total = 0;
    for (final p in selectedProducts) {
      if (p.isProductScheme == true) continue;
      double unitPrice =
          double.tryParse(p.product?.price?.toString() ?? '0') ?? 0;
      int qty = p.quantity;
      double unitDiscount = 0;
      final discount = p.dealerDiscount;
      if (p.useDealerDiscount && discount != null) {
        unitDiscount = discount.isPercentage == true
            ? unitPrice * (discount.discountValue / 100)
            : discount.discountValue.toDouble();
      } else if (!p.useDealerDiscount && p.discountAmount != null) {
        unitDiscount = p.discountAmount!.toDouble();
      }
      total += (unitPrice - unitDiscount) * qty;
    }
    return total;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared Widgets — Zoho Books style
// ═════════════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  const _Section(
      {required this.sw,
      required this.icon,
      required this.iconBg,
      required this.iconColor,
      required this.title,
      required this.child,
      this.trailing,
      this.bottomChild});

  final double sw;
  final IconData icon;
  final Color iconBg, iconColor;
  final String title;
  final Widget child;
  final Widget? trailing;
  final Widget? bottomChild;

  @override
  Widget build(BuildContext context) {
    final r = (sw * 0.04).clamp(10.0, 18.0);
    return Container(
        decoration: BoxDecoration(
            color: _kWhite,
            borderRadius: BorderRadius.circular(r),
            border: Border.all(color: _kBd, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.035),
              child: Row(children: [
                Container(
                    width: (sw * 0.075).clamp(26.0, 36.0),
                    height: (sw * 0.075).clamp(26.0, 36.0),
                    decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(
                            (sw * 0.022).clamp(6.0, 10.0))),
                    child: Icon(icon,
                        size: (sw * 0.04).clamp(14.0, 20.0), color: iconColor)),
                SizedBox(width: sw * 0.025),
                Expanded(
                    child: Text(title,
                        style: TextStyle(
                            fontSize: (sw * 0.035).clamp(12.0, 16.0),
                            fontWeight: FontWeight.w700,
                            color: _kT1))),
                if (trailing != null) trailing!,
              ])),
          Divider(height: 1, color: _kBd),
          Padding(padding: EdgeInsets.all(sw * 0.04), child: child),
          if (bottomChild != null) bottomChild!,
        ]));
  }
}

class _SelectorTile extends StatelessWidget {
  const _SelectorTile({
    required this.sw,
    required this.label,
    this.value,
    this.subtitle,  // ← comma was missing
    required this.icon,
    required this.color,
    this.onTap,
    this.enabled = true,
    this.fallback,
  });

  final double sw;
  final String label;
  final String? value;
  final String? subtitle;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool enabled;
  final String? fallback;

  @override
  Widget build(BuildContext context) {
    final display = value ?? fallback ?? 'Select $label';
    final hasVal = value != null;
    return Opacity(
        opacity: enabled ? 1.0 : 0.5,
        child: GestureDetector(
            onTap: enabled ? onTap : null,
            child: Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.04, vertical: sw * 0.03),
                decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius:
                    BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                    border: Border.all(color: _kBd, width: 0.5)),
                child: Row(children: [
                  Container(
                      width: (sw * 0.09).clamp(32.0, 42.0),
                      height: (sw * 0.09).clamp(32.0, 42.0),
                      decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: color.withValues(alpha: 0.25), width: 0.5)),
                      child: Icon(icon,
                          color: color, size: (sw * 0.04).clamp(14.0, 20.0))),
                  SizedBox(width: sw * 0.03),
                  Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(label,
                                style: TextStyle(
                                    fontSize: (sw * 0.028).clamp(9.5, 12.5),
                                    color: _kT4,
                                    fontWeight: FontWeight.w600)),
                            SizedBox(height: sw * 0.004),
                            Text(display,
                                style: TextStyle(
                                    fontSize: (sw * 0.034).clamp(11.5, 15.0),
                                    fontWeight:
                                    hasVal ? FontWeight.w600 : FontWeight.w400,
                                    color: hasVal ? _kT1 : _kT4),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                            // ── Subtitle ──────────────────────────────────
                            if (subtitle != null) ...[
                              SizedBox(height: sw * 0.004),
                              Text(subtitle!,
                                  style: TextStyle(
                                      fontSize: (sw * 0.026).clamp(9.0, 11.5),
                                      color: color,
                                      fontWeight: FontWeight.w500),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            ],
                          ])),
                  Icon(Icons.keyboard_arrow_down_rounded,
                      color: _kT4, size: (sw * 0.05).clamp(16.0, 22.0)),
                ]))));
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge(
      {required this.count,
      required this.color,
      required this.bg,
      required this.bd});

  final int count;
  final Color color, bg, bd;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Container(
        padding:
            EdgeInsets.symmetric(horizontal: sw * 0.025, vertical: sw * 0.008),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: bd, width: 0.5)),
        child: Text('$count',
            style: TextStyle(
                fontSize: (sw * 0.026).clamp(9.0, 11.5),
                fontWeight: FontWeight.w700,
                color: color)));
  }
}

class _Chip extends StatelessWidget {
  const _Chip(
      {required this.sw,
      required this.text,
      required this.icon,
      required this.color});

  final double sw;
  final String text;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
      padding:
          EdgeInsets.symmetric(horizontal: sw * 0.02, vertical: sw * 0.006),
      decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.25), width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: (sw * 0.03).clamp(10.0, 13.0), color: color),
        SizedBox(width: sw * 0.01),
        Text(text,
            style: TextStyle(
                fontSize: (sw * 0.026).clamp(9.0, 11.5),
                fontWeight: FontWeight.w600,
                color: color)),
      ]));
}

class _QtyBtn extends StatelessWidget {
  const _QtyBtn({required this.sw, required this.icon, this.onTap});

  final double sw;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: EdgeInsets.all(sw * 0.015),
          decoration: BoxDecoration(
              color: _kBg,
              borderRadius: BorderRadius.circular((sw * 0.02).clamp(6.0, 10.0)),
              border: Border.all(color: _kBd, width: 0.5)),
          child: Icon(icon, size: (sw * 0.04).clamp(14.0, 18.0), color: _kT2)));
}

class _PriceRow extends StatelessWidget {
  const _PriceRow(
      {required this.sw,
      required this.label,
      required this.amount,
      this.isBold = false});

  final double sw;
  final String label;
  final double amount;
  final bool isBold;

  @override
  Widget build(BuildContext context) =>
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Text(label,
            style: TextStyle(
                fontSize: (sw * 0.032).clamp(11.0, 14.0),
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isBold ? _kT1 : _kT2)),
        Text('₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: (sw * 0.032).clamp(11.0, 14.0),
                fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
                color: isBold ? _kGreen : _kT2)),
      ]);
}

class _ToggleBtn extends StatelessWidget {
  const _ToggleBtn(
      {required this.sw,
      required this.label,
      required this.color,
      required this.bg,
      required this.bd,
      required this.selected,
      required this.onTap});

  final double sw;
  final String label;
  final Color color, bg, bd;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
      onTap: onTap,
      child: Container(
          padding: EdgeInsets.symmetric(vertical: sw * 0.025),
          decoration: BoxDecoration(
              color: selected ? bg : _kBg,
              borderRadius:
                  BorderRadius.circular((sw * 0.025).clamp(8.0, 12.0)),
              border: Border.all(
                  color: selected ? bd : _kBd, width: selected ? 1.0 : 0.5)),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(
                selected
                    ? Icons.radio_button_checked
                    : Icons.radio_button_unchecked,
                color: color,
                size: (sw * 0.045).clamp(15.0, 20.0)),
            SizedBox(width: sw * 0.015),
            Text(label,
                style: TextStyle(
                    fontSize: (sw * 0.03).clamp(10.0, 13.0),
                    fontWeight: FontWeight.w700,
                    color: color)),
          ])));
}

class _PayMethodBtn extends StatelessWidget {
  const _PayMethodBtn(
      {required this.sw,
      required this.label,
      required this.icon,
      required this.color,
      required this.bg,
      required this.bd,
      required this.selected,
      required this.onTap});

  final double sw;
  final String label;
  final IconData icon;
  final Color color, bg, bd;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Expanded(
      child: GestureDetector(
          onTap: onTap,
          child: Container(
              padding: EdgeInsets.symmetric(vertical: sw * 0.03),
              decoration: BoxDecoration(
                  color: selected ? bg : _kBg,
                  borderRadius:
                      BorderRadius.circular((sw * 0.025).clamp(8.0, 12.0)),
                  border: Border.all(
                      color: selected ? bd : _kBd,
                      width: selected ? 1.0 : 0.5)),
              child:
                  Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(
                    selected
                        ? Icons.radio_button_checked
                        : Icons.radio_button_unchecked,
                    color: color,
                    size: (sw * 0.05).clamp(16.0, 22.0)),
                SizedBox(width: sw * 0.02),
                Text(label,
                    style: TextStyle(
                        fontSize: (sw * 0.034).clamp(11.5, 15.0),
                        fontWeight: FontWeight.w700,
                        color: color)),
              ]))));
}

class _DealerSearchDialog extends ConsumerStatefulWidget {
  const _DealerSearchDialog({
    required this.sw,
    required this.sh,
    required this.onSelected,
    this.salesmanId,
    this.salesmanName, // ← for display only
  });

  final double sw;
  final double sh;
  final String? salesmanId;
  final String? salesmanName;
  final void Function(UserModel dealer) onSelected;

  @override
  ConsumerState<_DealerSearchDialog> createState() =>
      _DealerSearchDialogState();
}

class _DealerSearchDialogState extends ConsumerState<_DealerSearchDialog> {
  final TextEditingController _searchCtrl = TextEditingController();
  Timer? _debounce;
  int _requestId = 0;
  List<UserModel> _results = [];
  bool _isLoading = true;
  String? _error;
  String _query = '';

  bool get _isSalesmanMode => widget.salesmanId != null;

  @override
  void initState() {
    super.initState();
    _fetchDealers(query: '', requestId: ++_requestId);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDealers({
    required String query,
    required int requestId,
  }) async {
    try {
      final repo = ref.read(signupRepositoryProvider);
      List<UserModel> dealers;

      if (_isSalesmanMode) {
        dealers = await repo.getSalesmanDealers(
          salesmanId: widget.salesmanId!,
          page: 1,
          limit: 50,
          search: query.isEmpty ? null : query,
        );
      } else {
        dealers = await repo.getDealers(
          page: 1,
          limit: 20,
          search: query.isEmpty ? null : query,
        );
      }

      if (!mounted || requestId != _requestId) return;
      setState(() {
        _results = dealers;
        _isLoading = false;
        _error = null;
      });
    } catch (e) {
      if (!mounted || requestId != _requestId) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    final trimmed = value.trim();
    final myRequestId = ++_requestId;
    setState(() {
      _query = trimmed;
      _results = [];
      _isLoading = true;
      _error = null;
    });
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted || myRequestId != _requestId) return;
      _fetchDealers(query: trimmed, requestId: myRequestId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final sh = widget.sh;

    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
      ),
      title: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('Select Dealer',
              style: TextStyle(
                  fontSize: (sw * 0.042).clamp(14.0, 20.0),
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF111827))),
          // ── Show salesman name, not ID ─────────────────────────────
          if (_isSalesmanMode && widget.salesmanName != null)
            Text(
              'Dealers assigned to ${widget.salesmanName}',
              style: TextStyle(
                  fontSize: (sw * 0.028).clamp(9.5, 12.5),
                  color: const Color(0xFF9CA3AF)),
            ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          // ── Search field ────────────────────────────────────────────
          TextField(
            controller: _searchCtrl,
            autofocus: false,
            style: TextStyle(
                fontSize: (sw * 0.034).clamp(11.5, 15.0),
                color: const Color(0xFF111827)),
            decoration: InputDecoration(
              hintText: 'Search by name or shop',
              hintStyle: TextStyle(
                  fontSize: (sw * 0.032).clamp(11.0, 14.0),
                  color: const Color(0xFF9CA3AF)),
              prefixIcon: Icon(Icons.search_rounded,
                  size: (sw * 0.05).clamp(16.0, 22.0),
                  color: const Color(0xFF9CA3AF)),
              suffixIcon: _isLoading
                  ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          color: Color(0xFF185FA5), strokeWidth: 2)))
                  : (_query.isNotEmpty
                  ? IconButton(
                  icon: Icon(Icons.clear_rounded,
                      size: (sw * 0.045).clamp(15.0, 20.0),
                      color: const Color(0xFF9CA3AF)),
                  onPressed: () {
                    _searchCtrl.clear();
                    _onSearchChanged('');
                  })
                  : null),
              filled: true,
              fillColor: const Color(0xFFF7F8FA),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      (sw * 0.028).clamp(8.0, 12.0)),
                  borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB), width: 0.5)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      (sw * 0.028).clamp(8.0, 12.0)),
                  borderSide: const BorderSide(
                      color: Color(0xFFE5E7EB), width: 0.5)),
              focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(
                      (sw * 0.028).clamp(8.0, 12.0)),
                  borderSide: const BorderSide(
                      color: Color(0xFF185FA5), width: 1.5)),
            ),
            onChanged: _onSearchChanged,
          ),
          SizedBox(height: sh * 0.02),
          Expanded(child: _buildResults(sw)),
        ]),
      ),
    );
  }

  Widget _buildResults(double sw) {
    if (_isLoading) {
      return const Center(
          child: CircularProgressIndicator(
              color: Color(0xFF185FA5), strokeWidth: 2.5));
    }

    if (_error != null) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.wifi_off_rounded,
              size: (sw * 0.12).clamp(40.0, 56.0),
              color: const Color(0xFF9CA3AF)),
          SizedBox(height: sw * 0.03),
          Text('Failed to load dealers',
              style: TextStyle(
                  color: const Color(0xFFDC2626),
                  fontSize: (sw * 0.034).clamp(11.5, 15.0))),
          SizedBox(height: sw * 0.03),
          ElevatedButton(
              onPressed: () =>
                  _fetchDealers(query: _query, requestId: ++_requestId),
              style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF185FA5),
                  foregroundColor: Colors.white,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(12),
                  elevation: 0),
              child: const Icon(Icons.refresh_rounded)),
        ]),
      );
    }

    if (_results.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.search_off_rounded,
              size: (sw * 0.12).clamp(40.0, 56.0),
              color: const Color(0xFF9CA3AF)),
          SizedBox(height: sw * 0.03),
          Text(
              _query.isEmpty
                  ? (_isSalesmanMode
                  ? 'No dealers assigned to ${widget.salesmanName ?? 'this salesman'}'
                  : 'No dealers found')
                  : 'No results for "$_query"',
              textAlign: TextAlign.center,
              style: TextStyle(
                  color: const Color(0xFF9CA3AF),
                  fontSize: (sw * 0.034).clamp(11.5, 15.0))),
        ]),
      );
    }

    return ListView.builder(
      itemCount: _results.length,
      itemBuilder: (_, i) {
        final d = _results[i];
        return Container(
          margin: EdgeInsets.only(bottom: sw * 0.02),
          decoration: BoxDecoration(
              color: const Color(0xFFF7F8FA),
              borderRadius:
              BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
              border: Border.all(
                  color: const Color(0xFFE5E7EB), width: 0.5)),
          child: ListTile(
            title: Text(d.employeeName,
                style: TextStyle(
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF111827),
                    fontSize: (sw * 0.034).clamp(11.5, 15.0))),
            subtitle: Text(
                d.shopName ?? d.town ?? 'No shop name',
                style: TextStyle(
                    color: const Color(0xFF9CA3AF),
                    fontSize: (sw * 0.028).clamp(9.5, 12.5))),
            onTap: () {
              widget.onSelected(d);
              Navigator.pop(context);
            },
          ),
        );
      },
    );
  }
}


