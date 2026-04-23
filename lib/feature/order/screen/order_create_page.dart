import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/brand_model.dart';
import '../../../model/dealer_discount_model.dart';
import '../../../model/order_model.dart';
import '../../../model/product_model.dart';
import '../../../model/user_model.dart';
import '../../../widgets/circle_button.dart';
import '../../brand/controller/brand_controller.dart';
import '../../discount/controller/discount_controller.dart';
import '../../product/controller/product_controller.dart';
import '../../signup/controller/signUp_controller.dart';
import '../controller/order_controller.dart';

// ─── THEME CONSTANTS ──────────────────────────────────────────────────────────
const _kBlue = Color(0xFF1B4FD8);
const _kBlueBg = Color(0xFFEEF2FF);
const _kBlueBorder = Color(0xFFC7D4FF);
const _kBg = Color(0xFFF2F4F8);
const _kCard = Colors.white;
const _kBorder = Color(0xFFE5E7EB);
const _kDark = Color(0xFF111827);
const _kMid = Color(0xFF374151);
const _kMuted = Color(0xFF9CA3AF);
const _kGreen = Color(0xFF0A8A5C);
const _kGreenBg = Color(0xFFEDFAF4);
const _kGreenBorder = Color(0xFF9FE0C5);
const _kRed = Color(0xFFDC2626);
const _kRedBg = Color(0xFFFEF2F2);
const _kRedBorder = Color(0xFFFECACA);
const _kAmber = Color(0xFFB45309);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFCD28A);
const _kPurple = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBorder = Color(0xFFDDD6FE);

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
  List<ProductModel> _allFetchedProducts = []; // ← add this
  String? selectedModelFilter; // ← add with other state variables
  List<String> _availableModels = []; // ← models extracted from products

  // ✅ NEW: Track current user role and ID
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

  // ✅ NEW: Load current user info from SharedPreferences
  Future<void> _loadCurrentUserInfo() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final role = prefs.getString('user_role');
      print('Loaded user role from SharedPreferences: $role');
      final userId = prefs.getString('user_id');
      print('Loaded user ID from SharedPreferences: $userId');

      setState(() {
        currentUserRole = role;
        currentUserId = userId;
        isLoadingUserInfo = false;
      });

      // ✅ If user is SALESMAN, auto-load their info
      if (role == 'ROLE_SALESMAN' && userId != null) {
        _loadSalesmanInfo(userId);
      }
    } catch (e) {
      debugPrint('Error loading user info: $e');
      setState(() => isLoadingUserInfo = false);
    }
  }

  // ✅ NEW: Load salesman info by ID
  Future<void> _loadSalesmanInfo(String salesmanId) async {
    try {
      final allSalesmen = await ref.read(usersByRoleProvider('ROLE_SALESMAN').future);
      final salesman = allSalesmen.firstWhere(
            (s) => s.employeeId == salesmanId,
        orElse: () => throw Exception('Salesman not found'),
      );

      if (mounted) {
        setState(() => selectedSalesman = salesman);
      }
    } catch (e) {
      debugPrint('Error loading salesman info: $e');
    }
  }

  // ✅ NEW: Check if current user is salesman
  bool get isSalesman => currentUserRole == 'ROLE_SALESMAN';

  @override
  void dispose() {
    orderNoteController.dispose();
    amountPaidController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    // ✅ Show loader while loading user info
    if (isLoadingUserInfo) {
      return const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: GlobalLoader()),
      );
    }

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Nav ──────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.03),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('Create Order',
                      style: TextStyle(
                          fontSize: sw * 0.042,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                          letterSpacing: -0.2)),
                  const Spacer(),
                  SizedBox(width: sw * 0.095),
                ],
              ),
            ),

            // ── Scrollable Content ───────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                child: Column(
                  children: [
                    _buildSelectionCard(sw, sh),
                    SizedBox(height: sh * 0.012),
                    if (selectedProducts.isNotEmpty) ...[
                      _buildProductsCard(sw, sh),
                      SizedBox(height: sh * 0.012),
                    ],
                    _buildOrderDetailsCard(sw, sh),
                    SizedBox(height: sh * 0.02),
                  ],
                ),
              ),
            ),

            // ── Bottom Create Button ─────────────────
            _buildBottomButton(sw, sh),
          ],
        ),
      ),
    );
  }

  // ── Selection Card ────────────────────────────────────────────────────────────
  Widget _buildSelectionCard(double sw, double sh) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(
              children: [
                Container(
                  width: sw * 0.075,
                  height: sw * 0.075,
                  decoration: BoxDecoration(
                    color: _kBlueBg,
                    borderRadius: BorderRadius.circular(sw * 0.022),
                    border: Border.all(color: _kBlueBorder),
                  ),
                  child: Icon(Icons.shopping_cart_outlined,
                      size: sw * 0.04, color: _kBlue),
                ),
                SizedBox(width: sw * 0.025),
                Text('Order Selection',
                    style: TextStyle(
                        fontSize: sw * 0.035,
                        fontWeight: FontWeight.w700,
                        color: _kDark)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          Padding(
            padding: EdgeInsets.all(sw * 0.04),
            child: Column(
              children: [
                // ✅ MODIFIED: Only show salesman selector if NOT a salesman
                if (!isSalesman) ...[
                  _buildSelectorButton(
                    sw: sw,
                    label: 'Salesman',
                    value: selectedSalesman?.employeeName,
                    icon: Icons.person_outline_rounded,
                    color: _kPurple,
                    onTap: () => _showSalesmanDialog(context),
                  ),
                  SizedBox(height: sh * 0.012),
                ],
                _buildSelectorButton(
                  sw: sw,
                  label: 'Dealer',
                  value: selectedDealer != null
                      ? '${selectedDealer!.employeeName}${selectedDealer!.shopName != null ? ' (${selectedDealer!.shopName})' : ''}'
                      : null,
                  icon: Icons.store_outlined,
                  color: _kBlue,
                  onTap: () => _showDealerDialog(context),
                ),
                SizedBox(height: sh * 0.012),
                _buildSelectorButton(
                  sw: sw,
                  label: 'Brand',
                  value: selectedBrand?.brandName,
                  icon: Icons.local_offer_outlined,
                  color: _kAmber,
                  enabled: selectedDealer != null,
                  onTap: selectedDealer == null
                      ? null
                      : () => _showBrandDialog(
                      context, selectedDealer!.employeeId!),
                ),
                SizedBox(height: sh * 0.012),
                _buildSelectorButton(
                  sw: sw,
                  label: 'Model',
                  value: selectedModelFilter, // null shows "All Models"
                  icon: Icons.tag_rounded,
                  color: _kBlue,
                  enabled: selectedBrand != null,
                  optionalLabel: 'All Models', // shows when no model selected
                  onTap: selectedBrand == null
                      ? null
                      : () => _showModelDialog(context),
                ),
                SizedBox(height: sh * 0.012),
                _buildSelectorButton(
                  sw: sw,
                  label: 'Product',
                  value: selectedProduct?.productName,
                  icon: Icons.inventory_2_outlined,
                  color: _kGreen,
                  enabled: selectedBrand != null,
                  onTap: selectedBrand == null
                      ? null
                      : () => _showProductDialog(
                      context, [selectedBrand!.brandName]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  Future<void> _showModelDialog(BuildContext context) async {
    final searchController = TextEditingController();

    // ── Fetch products if not loaded ──
    if (_allFetchedProducts.isEmpty) {
      _allFetchedProducts = await ref
          .read(productControllerProvider.notifier)
          .fetchProductsByBrand([selectedBrand!.brandName]);
    }

    // ── Extract unique models ──
    _availableModels = [
      ...<String>{}..addAll(
        _allFetchedProducts
            .map((p) => p.model ?? '')
            .where((m) => m.isNotEmpty),
      )
    ]..sort();

    final query = ValueNotifier('');
    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(Screen.w(context) * 0.04)),
        title: Text('Select Model',
            style: TextStyle(
                fontSize: Screen.w(context) * 0.042,
                fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _dialogSearchField(context, searchController,
                  'Search model', query),
              SizedBox(height: Screen.h(context) * 0.015),
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: query,
                  builder: (_, q, __) {
                    final filtered = _availableModels
                        .where((m) => m.toLowerCase().contains(q))
                        .toList();

                    return ListView.builder(
                      itemCount: filtered.length + 1, // +1 for "All Models"
                      itemBuilder: (_, i) {
                        // ── All Models option ──
                        if (i == 0) {
                          final isSelected = selectedModelFilter == null;
                          return Container(
                            margin: EdgeInsets.only(
                                bottom: Screen.w(context) * 0.02),
                            decoration: BoxDecoration(
                              color: isSelected ? _kBlueBg : _kBg,
                              borderRadius: BorderRadius.circular(
                                  Screen.w(context) * 0.028),
                              border: Border.all(
                                  color: isSelected
                                      ? _kBlueBorder
                                      : _kBorder,
                                  width: isSelected ? 1.5 : 1),
                            ),
                            child: ListTile(
                              leading: Icon(Icons.all_inclusive_rounded,
                                  color: isSelected ? _kBlue : _kMuted),
                              title: Text('All Models',
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? _kBlue
                                          : _kDark)),
                              trailing: isSelected
                                  ? const Icon(Icons.check_circle,
                                  color: _kBlue)
                                  : null,
                              onTap: () {
                                setState(() {
                                  selectedModelFilter = null;
                                  selectedProduct = null;
                                });
                                Navigator.pop(context);
                              },
                            ),
                          );
                        }

                        // ── Model items ──
                        final model = filtered[i - 1];
                        final isSelected = selectedModelFilter == model;
                        return Container(
                          margin: EdgeInsets.only(
                              bottom: Screen.w(context) * 0.02),
                          decoration: BoxDecoration(
                            color: isSelected ? _kBlueBg : _kBg,
                            borderRadius: BorderRadius.circular(
                                Screen.w(context) * 0.028),
                            border: Border.all(
                                color: isSelected
                                    ? _kBlueBorder
                                    : _kBorder,
                                width: isSelected ? 1.5 : 1),
                          ),
                          child: ListTile(
                            leading: Icon(Icons.tag_rounded,
                                color: isSelected ? _kBlue : _kMuted),
                            title: Text(model,
                                style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isSelected
                                        ? _kBlue
                                        : _kDark)),
                            trailing: isSelected
                                ? const Icon(Icons.check_circle,
                                color: _kBlue)
                                : null,
                            onTap: () {
                              setState(() {
                                selectedModelFilter = model;
                                selectedProduct = null;
                              });
                              Navigator.pop(context);
                            },
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorButton({
    required double sw,
    required String label,
    String? value,
    required IconData icon,
    required Color color,
    VoidCallback? onTap,
    bool enabled = true,
    String? optionalLabel, // ← add this
  }) {
    final displayText = value ?? optionalLabel ?? 'Select $label';
    final hasValue = value != null;

    return Opacity(
      opacity: enabled ? 1.0 : 0.5,
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.035),
          decoration: BoxDecoration(
            color: _kBg,
            borderRadius: BorderRadius.circular(sw * 0.028),
            border: Border.all(color: _kBorder),
          ),
          child: Row(
            children: [
              Container(
                width: sw * 0.1,
                height: sw * 0.1,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.3)),
                ),
                child: Icon(icon, color: color, size: sw * 0.045),
              ),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            fontSize: sw * 0.028,
                            color: _kMuted,
                            fontWeight: FontWeight.w600)),
                    SizedBox(height: sw * 0.005),
                    Text(
                      displayText,
                      style: TextStyle(
                          fontSize: sw * 0.034,
                          fontWeight: hasValue
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: hasValue ? _kDark : _kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Icon(Icons.keyboard_arrow_down_rounded,
                  color: _kMuted, size: sw * 0.05),
            ],
          ),
        ),
      ),
    );
  }

  // ── Products Card ─────────────────────────────────────────────────────────────
  Widget _buildProductsCard(double sw, double sh) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(
              children: [
                Container(
                  width: sw * 0.075,
                  height: sw * 0.075,
                  decoration: BoxDecoration(
                    color: _kGreenBg,
                    borderRadius: BorderRadius.circular(sw * 0.022),
                    border: Border.all(color: _kGreenBorder),
                  ),
                  child: Icon(Icons.inventory_outlined,
                      size: sw * 0.04, color: _kGreen),
                ),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Text('Selected Products',
                      style: TextStyle(
                          fontSize: sw * 0.035,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.025, vertical: sw * 0.008),
                  decoration: BoxDecoration(
                    color: _kGreenBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kGreenBorder),
                  ),
                  child: Text('${selectedProducts.length}',
                      style: TextStyle(
                          fontSize: sw * 0.026,
                          fontWeight: FontWeight.w700,
                          color: _kGreen)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: selectedProducts.length,
            separatorBuilder: (_, __) =>
            const Divider(height: 1, color: _kBorder),
            itemBuilder: (context, index) =>
                _buildProductItem(selectedProducts[index], index, sw, sh),
          ),
          // Order Total
          Container(
            padding: EdgeInsets.all(sw * 0.04),
            decoration: BoxDecoration(
              color: _kGreenBg,
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(sw * 0.04),
                bottomRight: Radius.circular(sw * 0.04),
              ),
              border: const Border(
                  top: BorderSide(color: _kGreenBorder, width: 1.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Order Total',
                    style: TextStyle(
                        fontSize: sw * 0.038,
                        fontWeight: FontWeight.w800,
                        color: _kGreen)),
                Text(
                    '₹${_calculateOrderTotal().toStringAsFixed(2)}',
                    style: TextStyle(
                        fontSize: sw * 0.045,
                        fontWeight: FontWeight.w900,
                        color: _kGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductItem(
      OrderDetailsModel product, int index, double sw, double sh) {
    double price =
        double.tryParse(product.product?.price?.toString() ?? '0') ?? 0;
    int qty = product.quantity;
    double unitDiscount = 0;
    final discount = product.dealerDiscount;

    if (product.useDealerDiscount && discount != null) {
      if (discount.isPercentage == true) {
        unitDiscount = price * (discount.discountValue / 100);
      } else {
        unitDiscount = discount.discountValue.toDouble();
      }
    } else if (!product.useDealerDiscount &&
        product.discountAmount != null) {
      unitDiscount = product.discountAmount!.toDouble();
    }

    double subtotal = price * qty;
    double discountTotal = unitDiscount * qty;
    double total = subtotal - discountTotal;

    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Product header ─────────────────────
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.product?.productName ?? product.productName,
                      style: TextStyle(
                          fontSize: sw * 0.036,
                          fontWeight: FontWeight.w700,
                          color: _kDark),
                    ),
                    SizedBox(height: sw * 0.008),
                    Row(
                      children: [
                        _buildInfoChip(
                            sw,
                            product.product?.brand ?? product.productBrand,
                            Icons.local_offer_outlined,
                            _kAmber),
                        SizedBox(width: sw * 0.015),
                        _buildInfoChip(
                            sw,
                            product.product?.model ?? product.productModel,
                            Icons.tag_rounded,
                            _kBlue),
                      ],
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded,
                    color: _kRed, size: sw * 0.055),
                onPressed: () =>
                    setState(() => selectedProducts.removeAt(index)),
              ),
            ],
          ),

          SizedBox(height: sh * 0.015),

          // ── Quantity controls ──────────────────
          Row(
            children: [
              Text('Quantity',
                  style: TextStyle(
                      fontSize: sw * 0.03,
                      fontWeight: FontWeight.w600,
                      color: _kMuted)),
              SizedBox(width: sw * 0.025),
              GestureDetector(
                onTap: product.quantity > 1
                    ? () => setState(() {
                  selectedProducts[index] = product.copyWith(
                      qtyOrdered: product.quantity - 1);
                })
                    : null,
                child: Container(
                  padding: EdgeInsets.all(sw * 0.015),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(sw * 0.02),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Icon(Icons.remove,
                      size: sw * 0.04, color: _kMid),
                ),
              ),
              SizedBox(width: sw * 0.02),
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.035, vertical: sw * 0.015),
                decoration: BoxDecoration(
                  color: _kBlueBg,
                  borderRadius: BorderRadius.circular(sw * 0.02),
                  border: Border.all(color: _kBlueBorder),
                ),
                child: Text('${product.quantity}',
                    style: TextStyle(
                        fontSize: sw * 0.036,
                        fontWeight: FontWeight.w700,
                        color: _kBlue)),
              ),
              SizedBox(width: sw * 0.02),
              GestureDetector(
                onTap: () => setState(() {
                  selectedProducts[index] = product.copyWith(
                      qtyOrdered: product.quantity + 1);
                }),
                child: Container(
                  padding: EdgeInsets.all(sw * 0.015),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(sw * 0.02),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Icon(Icons.add,
                      size: sw * 0.04, color: _kMid),
                ),
              ),
              const Spacer(),
              Text('₹$price',
                  style: TextStyle(
                      fontSize: sw * 0.034,
                      fontWeight: FontWeight.w600,
                      color: _kMid)),
            ],
          ),

          SizedBox(height: sh * 0.015),

          // ── Scheme toggle ──────────────────────
          Row(
            children: [
              Icon(Icons.card_giftcard_outlined,
                  size: sw * 0.045, color: _kPurple),
              SizedBox(width: sw * 0.02),
              Text('Scheme Product',
                  style: TextStyle(
                      fontSize: sw * 0.032,
                      fontWeight: FontWeight.w600,
                      color: _kDark)),
              const Spacer(),
              Switch(
                value: product.isScheme,
                activeColor: _kPurple,
                activeTrackColor: _kPurpleBg,
                onChanged: (value) => setState(() {
                  selectedProducts[index] =
                      product.copyWith(isProductScheme: value);
                }),
              ),
            ],
          ),

          // ── Discount options ───────────────────
          if (selectedDealer != null)
            _buildDiscountOptions(product, index, sw, sh),

          SizedBox(height: sh * 0.015),

          // ── Delivery date ──────────────────────
          GestureDetector(
            onTap: () =>
                _selectDeliveryDate(context, product, index),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.03),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(sw * 0.028),
                border: Border.all(
                  color: product.deliveryDate == null
                      ? _kRed
                      : _kBorder,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: sw * 0.04,
                    color: product.deliveryDate != null
                        ? _kBlue
                        : _kMuted,
                  ),
                  SizedBox(width: sw * 0.025),
                  Text(
                    product.deliveryDate != null
                        ? '${product.deliveryDate!.day}/${product.deliveryDate!.month}/${product.deliveryDate!.year}'
                        : 'Select Delivery Date',
                    style: TextStyle(
                        fontSize: sw * 0.032,
                        fontWeight: FontWeight.w500,
                        color: product.deliveryDate != null
                            ? _kDark
                            : _kMuted),
                  ),
                ],
              ),
            ),
          ),

          if (product.deliveryDate == null)
            Padding(
              padding: EdgeInsets.only(
                  top: sw * 0.015, left: sw * 0.01),
              child: Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      size: sw * 0.035, color: _kRed),
                  SizedBox(width: sw * 0.01),
                  Text('Delivery date required',
                      style: TextStyle(
                          fontSize: sw * 0.028, color: _kRed)),
                ],
              ),
            ),

          // ── Price breakdown (non-scheme only) ──
          if (!product.isProductScheme) ...[
            SizedBox(height: sh * 0.015),
            Container(
              padding: EdgeInsets.all(sw * 0.03),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(sw * 0.025),
              ),
              child: Column(
                children: [
                  _buildPriceRow('Subtotal', subtotal, sw, false),
                  SizedBox(height: sw * 0.01),
                  _buildPriceRow(
                      'Discount', -discountTotal, sw, false),
                  SizedBox(height: sw * 0.01),
                  const Divider(height: 1, color: _kBorder),
                  SizedBox(height: sw * 0.01),
                  _buildPriceRow('Total', total, sw, true),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildInfoChip(
      double sw, String text, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.02, vertical: sw * 0.008),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: sw * 0.03, color: color),
          SizedBox(width: sw * 0.01),
          Text(text,
              style: TextStyle(
                  fontSize: sw * 0.026,
                  fontWeight: FontWeight.w600,
                  color: color)),
        ],
      ),
    );
  }

  Widget _buildPriceRow(
      String label, double amount, double sw, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: TextStyle(
                fontSize: sw * 0.032,
                fontWeight:
                isBold ? FontWeight.w700 : FontWeight.w500,
                color: isBold ? _kDark : _kMid)),
        Text('₹${amount.toStringAsFixed(2)}',
            style: TextStyle(
                fontSize: sw * 0.032,
                fontWeight:
                isBold ? FontWeight.w700 : FontWeight.w500,
                color: isBold ? _kGreen : _kMid)),
      ],
    );
  }

  // ── Order Details Card ────────────────────────────────────────────────────────
  Widget _buildOrderDetailsCard(double sw, double sh) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(
              children: [
                Container(
                  width: sw * 0.075,
                  height: sw * 0.075,
                  decoration: BoxDecoration(
                    color: _kPurpleBg,
                    borderRadius: BorderRadius.circular(sw * 0.022),
                    border: Border.all(color: _kPurpleBorder),
                  ),
                  child: Icon(Icons.description_outlined,
                      size: sw * 0.04, color: _kPurple),
                ),
                SizedBox(width: sw * 0.025),
                Text('Order Details',
                    style: TextStyle(
                        fontSize: sw * 0.035,
                        fontWeight: FontWeight.w700,
                        color: _kDark)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          Padding(
            padding: EdgeInsets.all(sw * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order Notes
                Text('Order Notes',
                    style: TextStyle(
                        fontSize: sw * 0.032,
                        fontWeight: FontWeight.w600,
                        color: _kDark)),
                SizedBox(height: sh * 0.008),
                TextFormField(
                  controller: orderNoteController,
                  minLines: 3,
                  maxLines: 5,
                  style:
                  TextStyle(fontSize: sw * 0.034, color: _kDark),
                  decoration: InputDecoration(
                    hintText:
                    'Add special instructions or notes (optional)',
                    hintStyle: TextStyle(
                        fontSize: sw * 0.032, color: _kMuted),
                    filled: true,
                    fillColor: _kBg,
                    contentPadding: EdgeInsets.all(sw * 0.035),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(sw * 0.028),
                      borderSide:
                      const BorderSide(color: _kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(sw * 0.028),
                      borderSide:
                      const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(sw * 0.028),
                      borderSide: const BorderSide(
                          color: _kBlue, width: 1.5),
                    ),
                  ),
                ),

                SizedBox(height: sh * 0.02),

                // Priority
                Text('Priority',
                    style: TextStyle(
                        fontSize: sw * 0.032,
                        fontWeight: FontWeight.w600,
                        color: _kDark)),
                SizedBox(height: sh * 0.012),
                Row(
                  children: priorities.map((p) {
                    final isSelected = selectedPriority == p;
                    final color = p == 'HIGH'
                        ? _kRed
                        : p == 'MEDIUM'
                        ? _kAmber
                        : _kGreen;
                    return Expanded(
                      child: GestureDetector(
                        onTap: () =>
                            setState(() => selectedPriority = p),
                        child: Container(
                          margin:
                          EdgeInsets.only(right: sw * 0.015),
                          padding: EdgeInsets.symmetric(
                              vertical: sw * 0.025),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withValues(alpha: 0.1)
                                : _kBg,
                            borderRadius: BorderRadius.circular(
                                sw * 0.025),
                            border: Border.all(
                                color:
                                isSelected ? color : _kBorder,
                                width: isSelected ? 1.5 : 1),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                isSelected
                                    ? Icons.radio_button_checked
                                    : Icons
                                    .radio_button_unchecked,
                                color: color,
                                size: sw * 0.045,
                              ),
                              SizedBox(width: sw * 0.015),
                              Text(p,
                                  style: TextStyle(
                                      fontSize: sw * 0.03,
                                      fontWeight: FontWeight.w700,
                                      color: color)),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),

                SizedBox(height: sh * 0.02),

                // Amount Paid
                Text('Amount Paid',
                    style: TextStyle(
                        fontSize: sw * 0.032,
                        fontWeight: FontWeight.w600,
                        color: _kDark)),
                SizedBox(height: sh * 0.008),
                TextFormField(
                  controller: amountPaidController,
                  keyboardType: TextInputType.number,
                  style:
                  TextStyle(fontSize: sw * 0.036, color: _kDark),
                  decoration: InputDecoration(
                    hintText: 'Enter amount',
                    hintStyle: TextStyle(
                        fontSize: sw * 0.034, color: _kMuted),
                    prefixIcon: Icon(Icons.currency_rupee,
                        color: _kGreen, size: sw * 0.05),
                    filled: true,
                    fillColor: _kBg,
                    contentPadding: EdgeInsets.symmetric(
                        horizontal: sw * 0.04),
                    border: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(sw * 0.028),
                      borderSide:
                      const BorderSide(color: _kBorder),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(sw * 0.028),
                      borderSide:
                      const BorderSide(color: _kBorder),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius:
                      BorderRadius.circular(sw * 0.028),
                      borderSide: const BorderSide(
                          color: _kBlue, width: 1.5),
                    ),
                  ),
                  onChanged: (v) => setState(
                          () => amountPaid = num.tryParse(v) ?? 0),
                ),

                SizedBox(height: sh * 0.02),

                // Payment Method
                Text('Payment Method',
                    style: TextStyle(
                        fontSize: sw * 0.032,
                        fontWeight: FontWeight.w600,
                        color: _kDark)),
                SizedBox(height: sh * 0.012),
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                                () => paymentMethod = 'CASH'),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: sw * 0.03),
                          decoration: BoxDecoration(
                            color: paymentMethod == 'CASH'
                                ? _kGreenBg
                                : _kBg,
                            borderRadius: BorderRadius.circular(
                                sw * 0.025),
                            border: Border.all(
                                color: paymentMethod == 'CASH'
                                    ? _kGreenBorder
                                    : _kBorder,
                                width:
                                paymentMethod == 'CASH' ? 1.5 : 1),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                paymentMethod == 'CASH'
                                    ? Icons.radio_button_checked
                                    : Icons
                                    .radio_button_unchecked,
                                color: _kGreen,
                                size: sw * 0.05,
                              ),
                              SizedBox(width: sw * 0.02),
                              Text('Cash',
                                  style: TextStyle(
                                      fontSize: sw * 0.034,
                                      fontWeight: FontWeight.w700,
                                      color: _kGreen)),
                            ],
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: sw * 0.02),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => setState(
                                () => paymentMethod = 'BANK'),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              vertical: sw * 0.03),
                          decoration: BoxDecoration(
                            color: paymentMethod == 'BANK'
                                ? _kBlueBg
                                : _kBg,
                            borderRadius: BorderRadius.circular(
                                sw * 0.025),
                            border: Border.all(
                                color: paymentMethod == 'BANK'
                                    ? _kBlueBorder
                                    : _kBorder,
                                width:
                                paymentMethod == 'BANK' ? 1.5 : 1),
                          ),
                          child: Row(
                            mainAxisAlignment:
                            MainAxisAlignment.center,
                            children: [
                              Icon(
                                paymentMethod == 'BANK'
                                    ? Icons.radio_button_checked
                                    : Icons
                                    .radio_button_unchecked,
                                color: _kBlue,
                                size: sw * 0.05,
                              ),
                              SizedBox(width: sw * 0.02),
                              Text('Bank',
                                  style: TextStyle(
                                      fontSize: sw * 0.034,
                                      fontWeight: FontWeight.w700,
                                      color: _kBlue)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom Button ─────────────────────────────────────────────────────────────
  Widget _buildBottomButton(double sw, double sh) {
    final canCreate = _canCreateOrder();
    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: _kBorder)),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -2))
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed:
            canCreate && !isCreatingOrder ? _createOrder : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _kBorder,
              disabledForegroundColor: _kMuted,
              padding:
              EdgeInsets.symmetric(vertical: sh * 0.018),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(sw * 0.035),
              ),
              elevation: 0,
            ),
            child: isCreatingOrder
                ? SizedBox(
              height: sw * 0.05,
              width: sw * 0.05,
              child: const CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2.5),
            )
                : Text('Create Order',
                style: TextStyle(
                    fontSize: sw * 0.04,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ),
    );
  }

  // ── Discount Options ──────────────────────────────────────────────────────────
  Widget _buildDiscountOptions(
      OrderDetailsModel product, int index, double sw, double sh) {
    final discount = product.dealerDiscount;

    if (discount == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(height: sh * 0.015),
          Text('Manual Discount',
              style: TextStyle(
                  fontSize: sw * 0.03,
                  fontWeight: FontWeight.w600,
                  color: _kDark)),
          SizedBox(height: sh * 0.008),
          TextFormField(
            initialValue: product.discountAmount?.toString() ?? '',
            keyboardType: TextInputType.number,
            style:
            TextStyle(fontSize: sw * 0.034, color: _kDark),
            decoration: InputDecoration(
              hintText: 'Enter discount amount',
              hintStyle: TextStyle(
                  fontSize: sw * 0.032, color: _kMuted),
              prefixIcon: Icon(Icons.local_offer_outlined,
                  color: _kAmber, size: sw * 0.045),
              filled: true,
              fillColor: _kBg,
              contentPadding:
              EdgeInsets.symmetric(horizontal: sw * 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(
                    color: _kBlue, width: 1.5),
              ),
            ),
            onChanged: (value) => setState(() {
              selectedProducts[index] = product.copyWith(
                discountAmount: num.tryParse(value),
                useDealerDiscount: false,
              );
            }),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(height: sh * 0.015),
        Text('Discount',
            style: TextStyle(
                fontSize: sw * 0.03,
                fontWeight: FontWeight.w600,
                color: _kDark)),
        SizedBox(height: sh * 0.01),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  selectedProducts[index] = product.copyWith(
                      useDealerDiscount: false,
                      dealerDiscountId: null,
                      discountAmount: 0);
                }),
                child: Container(
                  padding:
                  EdgeInsets.symmetric(vertical: sw * 0.025),
                  decoration: BoxDecoration(
                    color: !product.useDealerDiscount
                        ? _kAmberBg
                        : _kBg,
                    borderRadius:
                    BorderRadius.circular(sw * 0.025),
                    border: Border.all(
                        color: !product.useDealerDiscount
                            ? _kAmberBorder
                            : _kBorder,
                        width: !product.useDealerDiscount ? 1.5 : 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        !product.useDealerDiscount
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _kAmber,
                        size: sw * 0.045,
                      ),
                      SizedBox(width: sw * 0.015),
                      Text('Manual',
                          style: TextStyle(
                              fontSize: sw * 0.03,
                              fontWeight: FontWeight.w700,
                              color: _kAmber)),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: sw * 0.02),
            Expanded(
              child: GestureDetector(
                onTap: () => setState(() {
                  selectedProducts[index] = product.copyWith(
                    useDealerDiscount: true,
                    discountAmount: null,
                    dealerDiscountId: discount.dealerDiscountId,
                  );
                }),
                child: Container(
                  padding:
                  EdgeInsets.symmetric(vertical: sw * 0.025),
                  decoration: BoxDecoration(
                    color: product.useDealerDiscount
                        ? _kGreenBg
                        : _kBg,
                    borderRadius:
                    BorderRadius.circular(sw * 0.025),
                    border: Border.all(
                        color: product.useDealerDiscount
                            ? _kGreenBorder
                            : _kBorder,
                        width:
                        product.useDealerDiscount ? 1.5 : 1),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        product.useDealerDiscount
                            ? Icons.radio_button_checked
                            : Icons.radio_button_unchecked,
                        color: _kGreen,
                        size: sw * 0.045,
                      ),
                      SizedBox(width: sw * 0.015),
                      Text('Dealer',
                          style: TextStyle(
                              fontSize: sw * 0.03,
                              fontWeight: FontWeight.w700,
                              color: _kGreen)),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
        if (!product.useDealerDiscount) ...[
          SizedBox(height: sh * 0.01),
          TextFormField(
            initialValue: product.discountAmount?.toString() ?? '',
            keyboardType: TextInputType.number,
            style:
            TextStyle(fontSize: sw * 0.034, color: _kDark),
            decoration: InputDecoration(
              hintText: 'Enter amount',
              hintStyle: TextStyle(
                  fontSize: sw * 0.032, color: _kMuted),
              filled: true,
              fillColor: _kBg,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.03),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(
                    color: _kBlue, width: 1.5),
              ),
            ),
            onChanged: (value) => setState(() {
              selectedProducts[index] = product.copyWith(
                  discountAmount: num.tryParse(value) ?? 0);
            }),
          ),
        ],
        if (product.useDealerDiscount) ...[
          SizedBox(height: sh * 0.01),
          Container(
            padding: EdgeInsets.all(sw * 0.035),
            decoration: BoxDecoration(
              color: _kGreenBg,
              borderRadius: BorderRadius.circular(sw * 0.028),
              border: Border.all(color: _kGreenBorder),
            ),
            child: Row(
              children: [
                Icon(Icons.discount_outlined,
                    color: _kGreen, size: sw * 0.045),
                SizedBox(width: sw * 0.025),
                Text(
                  '${discount.isPercentage == false ? '₹' : ''}${discount.discountValue}${discount.isPercentage ? '%' : ''}',
                  style: TextStyle(
                      fontSize: sw * 0.036,
                      fontWeight: FontWeight.w700,
                      color: _kGreen),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  // ── Dialogs ───────────────────────────────────────────────────────────────────
  Future<void> _showDealerDialog(BuildContext context) async {
    final searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(Screen.w(context) * 0.04)),
        title: Text('Select Dealer',
            style: TextStyle(
                fontSize: Screen.w(context) * 0.042,
                fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: Consumer(builder: (context, ref, _) {
            final dealerAsync = ref.watch(dealerListProvider);
            return dealerAsync.when(
              data: (dealers) {
                final query = ValueNotifier('');
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _dialogSearchField(context, searchController,
                        'Search by name or shop', query),
                    SizedBox(height: Screen.h(context) * 0.02),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: query,
                        builder: (_, q, __) {
                          final filtered = dealers.where((d) {
                            final name =
                            d.employeeName.toLowerCase();
                            final shop =
                            (d.shopName ?? '').toLowerCase();
                            return name.contains(q) ||
                                shop.contains(q);
                          }).toList();
                          if (filtered.isEmpty) {
                            return const Center(
                                child: Text('No dealers found'));
                          }
                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final d = filtered[i];
                              return _dialogListItem(
                                context,
                                title: d.employeeName,
                                subtitle:
                                d.shopName ?? 'No shop name',
                                onTap: () {
                                  setState(() {
                                    selectedDealer = d;
                                    selectedBrand = null;
                                    selectedModelFilter = null; // ← reset model
                                    selectedProduct = null;
                                    selectedProducts.clear();
                                    _allFetchedProducts.clear();
                                    _availableModels.clear();
                                  });
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () =>
              const Center(child: GlobalLoader()),
              error: (e, _) =>
                  Center(child: Text(e.toString())),
            );
          }),
        ),
      ),
    );
  }

  Future<void> _showBrandDialog(
      BuildContext context, String dealerId) async {
    final searchController = TextEditingController();
    final brandFuture = ref
        .watch(brandControllerProvider.notifier)
        .getBrandsByDealer(dealerId);
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<BrandModel>>(
        future: brandFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
                backgroundColor: Colors.white,
                content: GlobalLoader());
          }
          if (snapshot.hasError) {
            return AlertDialog(
                title: const Text('Brands'),
                content: Text(snapshot.error.toString()));
          }
          final brands = snapshot.data ?? [];
          final query = ValueNotifier('');
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Screen.w(context) * 0.04)),
            title: Text('Select Brand',
                style: TextStyle(
                    fontSize: Screen.w(context) * 0.042,
                    fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogSearchField(context, searchController,
                      'Search brand name', query),
                  SizedBox(height: Screen.h(context) * 0.02),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: query,
                      builder: (_, q, __) {
                        final filtered = brands
                            .where((b) => b.brandName
                            .toLowerCase()
                            .contains(q))
                            .toList();
                        if (filtered.isEmpty) {
                          return const Center(
                              child: Text('No brands found'));
                        }
                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final b = filtered[i];
                            return _dialogListItem(
                              context,
                              title: b.brandName,
                              leading: SvgPicture.asset(
                                  AppIcons.brand,
                                  width:
                                  Screen.w(context) * 0.06),
                              onTap: () {
                                setState(() {
                                  selectedBrand = b;
                                  selectedModelFilter = null; // ← reset model
                                  selectedProduct = null;
                                  _allFetchedProducts.clear();
                                  _availableModels.clear();
                                });
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showSalesmanDialog(BuildContext context) async {
    final searchController = TextEditingController();
    final future = ref
        .read(usersByRoleProvider('ROLE_SALESMAN').future);
    showDialog(
      context: context,
      builder: (context) => FutureBuilder<List<UserModel>>(
        future: future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const AlertDialog(
                backgroundColor: Colors.white,
                content: GlobalLoader());
          }
          if (snapshot.hasError) {
            return AlertDialog(
                title: const Text('Salesmen'),
                content: Text(snapshot.error.toString()));
          }
          final salesmen = snapshot.data ?? [];
          final query = ValueNotifier('');
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(
                    Screen.w(context) * 0.04)),
            title: Text('Select Salesman',
                style: TextStyle(
                    fontSize: Screen.w(context) * 0.042,
                    fontWeight: FontWeight.w700)),
            content: SizedBox(
              width: double.maxFinite,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _dialogSearchField(context, searchController,
                      'Search by name or phone', query),
                  SizedBox(height: Screen.h(context) * 0.02),
                  Expanded(
                    child: ValueListenableBuilder<String>(
                      valueListenable: query,
                      builder: (_, q, __) {
                        final filtered = salesmen.where((s) {
                          final name =
                          s.employeeName.toLowerCase();
                          final phone =
                          s.employeePhone.toLowerCase();
                          return name.contains(q) ||
                              phone.contains(q);
                        }).toList();
                        if (filtered.isEmpty) {
                          return const Center(
                              child:
                              Text('No salesmen found'));
                        }
                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final s = filtered[i];
                            return _dialogListItem(
                              context,
                              title: s.employeeName,
                              subtitle: s.employeePhone,
                              onTap: () {
                                setState(() =>
                                selectedSalesman = s);
                                Navigator.pop(context);
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Future<void> _showProductDialog(
      BuildContext context, List<String> brands) async {
    final searchController = TextEditingController();

    // ── Fetch only if not already loaded ──
    if (_allFetchedProducts.isEmpty) {
      _allFetchedProducts = await ref
          .read(productControllerProvider.notifier)
          .fetchProductsByBrand(brands);
    }
    // ── Filter by brand and model ──
    final localFiltered = _allFetchedProducts.where((p) {
      final matchBrand = brands.any(
              (b) => b.toLowerCase() == (p.brand ?? '').toLowerCase());
      final matchModel = selectedModelFilter == null ||
          (p.model ?? '') == selectedModelFilter;
      return matchBrand && matchModel;
    }).toList();

    // ── Extract unique models from products ──
    final models = ['All', ...{...localFiltered.map((p) => p.model ?? '')}
        .where((m) => m.isNotEmpty)
        .toList()..sort()];

    final query = ValueNotifier('');
    final selectedModel = ValueNotifier<String>('All'); // ← model filter

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius:
            BorderRadius.circular(Screen.w(context) * 0.04)),
        title: Text('Select Product',
            style: TextStyle(
                fontSize: Screen.w(context) * 0.042,
                fontWeight: FontWeight.w700)),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Search field ──
              _dialogSearchField(context, searchController,
                  'Search product name or model', query),
              SizedBox(height: Screen.h(context) * 0.015),

              // ── Model filter chips ──
              SizedBox(
                height: Screen.w(context) * 0.09,
                child: ValueListenableBuilder<String>(
                  valueListenable: selectedModel,
                  builder: (_, currentModel, __) {
                    return ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: models.length,
                      itemBuilder: (_, i) {
                        final model = models[i];
                        final isSelected = currentModel == model;
                        return GestureDetector(
                          onTap: () => selectedModel.value = model,
                          child: Container(
                            margin: EdgeInsets.only(
                                right: Screen.w(context) * 0.02),
                            padding: EdgeInsets.symmetric(
                                horizontal: Screen.w(context) * 0.03,
                                vertical: Screen.w(context) * 0.015),
                            decoration: BoxDecoration(
                              color: isSelected ? _kBlueBg : _kBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected
                                    ? _kBlueBorder
                                    : _kBorder,
                                width: isSelected ? 1.5 : 1,
                              ),
                            ),
                            child: Text(
                              model,
                              style: TextStyle(
                                fontSize: Screen.w(context) * 0.028,
                                fontWeight: FontWeight.w600,
                                color: isSelected ? _kBlue : _kMuted,
                              ),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),

              SizedBox(height: Screen.h(context) * 0.015),

              // ── Product list ──
              Expanded(
                child: ValueListenableBuilder<String>(
                  valueListenable: query,
                  builder: (_, q, __) {
                    return ValueListenableBuilder<String>(
                      valueListenable: selectedModel,
                      builder: (_, currentModel, __) {
                        final filtered = localFiltered.where((p) {
                          final name =
                              p.productName?.toLowerCase() ?? '';
                          final model =
                              p.model?.toLowerCase() ?? '';
                          final matchSearch = name.contains(q) ||
                              model.contains(q);
                          final matchModel = currentModel == 'All' ||
                              (p.model ?? '') == currentModel;
                          return matchSearch && matchModel;
                        }).toList();

                        if (filtered.isEmpty) {
                          return const Center(
                              child: Text('No products found'));
                        }

                        return ListView.builder(
                          itemCount: filtered.length,
                          itemBuilder: (_, i) {
                            final p = filtered[i];
                            final added = _isProductAlreadyAdded(p);
                            return Container(
                              margin: EdgeInsets.only(
                                  bottom:
                                  Screen.w(context) * 0.02),
                              decoration: BoxDecoration(
                                color: added ? _kGreenBg : _kBg,
                                borderRadius: BorderRadius.circular(
                                    Screen.w(context) * 0.028),
                                border: Border.all(
                                    color: added
                                        ? _kGreenBorder
                                        : _kBorder),
                              ),
                              child: ListTile(
                                leading: SvgPicture.asset(
                                  AppIcons.product,
                                  width: Screen.w(context) * 0.06,
                                  colorFilter: ColorFilter.mode(
                                      added ? _kGreen : _kBlue,
                                      BlendMode.srcIn),
                                ),
                                title: Text(
                                    p.productName.toString(),
                                    style: const TextStyle(
                                        fontWeight:
                                        FontWeight.w600)),
                                subtitle: Text(p.model.toString()),
                                trailing: added
                                    ? const Icon(
                                    Icons.check_circle,
                                    color: _kGreen)
                                    : null,
                                onTap: () async {
                                  DealerDiscountModel? discount;
                                  try {
                                    discount = await ref.read(
                                      dealerProductDiscountProvider({
                                        'dealerId': selectedDealer!
                                            .employeeId!,
                                        'productId': p.productId!,
                                      }).future,
                                    );
                                  } catch (e) {
                                    debugPrint(
                                        'Discount fetch: $e');
                                  }
                                  setState(() {
                                    selectedProducts.add(
                                      OrderDetailsModel.fromProduct(
                                          p,
                                          dealerDiscount: discount),
                                    );
                                  });
                                  if (!context.mounted) return;
                                  Navigator.pop(context);
                                },
                              ),
                            );
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Dialog helpers ─────────────────────────────────────────────────────────
  Widget _dialogSearchField(
      BuildContext context,
      TextEditingController ctrl,
      String hint,
      ValueNotifier<String> query) {
    return TextField(
      controller: ctrl,
      style: TextStyle(
          fontSize: Screen.w(context) * 0.034),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
            fontSize: Screen.w(context) * 0.032),
        prefixIcon: Icon(Icons.search_rounded,
            size: Screen.w(context) * 0.05),
        filled: true,
        fillColor: _kBg,
        border: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(Screen.w(context) * 0.028),
          borderSide: const BorderSide(color: _kBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(Screen.w(context) * 0.028),
          borderSide: const BorderSide(color: _kBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius:
          BorderRadius.circular(Screen.w(context) * 0.028),
          borderSide:
          const BorderSide(color: _kBlue, width: 1.5),
        ),
      ),
      onChanged: (v) => query.value = v.toLowerCase(),
    );
  }

  Widget _dialogListItem(
      BuildContext context, {
        required String title,
        String? subtitle,
        Widget? leading,
        required VoidCallback onTap,
      }) {
    return Container(
      margin: EdgeInsets.only(bottom: Screen.w(context) * 0.02),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius:
        BorderRadius.circular(Screen.w(context) * 0.028),
        border: Border.all(color: _kBorder),
      ),
      child: ListTile(
        leading: leading,
        title: Text(title,
            style: const TextStyle(fontWeight: FontWeight.w600)),
        subtitle: subtitle != null ? Text(subtitle) : null,
        onTap: onTap,
      ),
    );
  }

  // ── Date picker ──────────────────────────────────────────────────────────────
  Future<void> _selectDeliveryDate(BuildContext context,
      OrderDetailsModel product, int index) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: product.deliveryDate ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kBlue,
            onPrimary: Colors.white,
            surface: Colors.white,
            onSurface: _kDark,
          ),
          dialogTheme:
          const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() {
        selectedProducts[index] =
            product.copyWith(deliveryDate: picked);
      });
    }
  }

  // ── Validation & Create ───────────────────────────────────────────────────────
  bool _isProductAlreadyAdded(ProductModel product) {
    return selectedProducts
        .any((sp) => sp.product?.productId == product.productId);
  }

  bool _canCreateOrder() {
    // ✅ MODIFIED: Check selectedSalesman even if auto-filled for salesman role
    if (selectedDealer == null ||
        selectedSalesman == null ||
        selectedProducts.isEmpty ||
        amountPaid < 0) return false;

    return !selectedProducts.any((p) => p.deliveryDate == null);
  }

  void _createOrder() async {
    final missingDate =
    selectedProducts.any((p) => p.deliveryDate == null);

    if (missingDate) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: Colors.white),
            const SizedBox(width: 12),
            const Expanded(
                child: Text(
                    'Please select delivery date for all products')),
          ],
        ),
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
      ));
      return;
    }

    setState(() => isCreatingOrder = true);

    try {
      final processedProducts = selectedProducts.map((p) {
        if (p.isProductScheme == true) {
          return p.copyWith(discountAmount: 0);
        }
        double unitPrice =
            double.tryParse(p.product?.price?.toString() ?? '0') ??
                0;
        double calculatedDiscount = 0;
        if (p.useDealerDiscount && p.dealerDiscount != null) {
          final d = p.dealerDiscount!;
          calculatedDiscount = d.isPercentage == true
              ? unitPrice * (d.discountValue / 100)
              : d.discountValue.toDouble();
        } else if (!p.useDealerDiscount &&
            p.discountAmount != null) {
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
        orderDetails: processedProducts,
      );

      await ref
          .read(orderControllerProvider.notifier)
          .createOrder(order);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle,
                color: Colors.white, size: 20),
            const SizedBox(width: 12),
            const Expanded(
                child: Text('Order created successfully!',
                    style: TextStyle(fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: _kGreen,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ));

      await ref
          .read(orderControllerProvider.notifier)
          .getAllOrders();
      if (mounted) Navigator.pop(context);
    } catch (e, s) {
      debugPrint('❌ Error creating order: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('Failed to create order: $e')),
            ],
          ),
          backgroundColor: _kRed,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8)),
        ));
      }
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