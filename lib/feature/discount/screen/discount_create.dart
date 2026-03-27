import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/model/brand_model.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../model/dealer_discount_model.dart';
import '../../../model/product_model.dart';
import '../../../widgets/circle_button.dart';
import '../../brand/controller/brand_controller.dart';
import '../../product/controller/product_controller.dart';
import '../controller/discount_controller.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kBlue       = Color(0xFF1B4FD8);
const _kBlueBg     = Color(0xFFEEF2FF);
const _kBlueBorder = Color(0xFFC7D4FF);
const _kBg         = Color(0xFFF2F4F8);
const _kCard       = Colors.white;
const _kBorder     = Color(0xFFE5E7EB);
const _kDark       = Color(0xFF111827);
const _kMid        = Color(0xFF374151);
const _kMuted      = Color(0xFF9CA3AF);
const _kRed        = Color(0xFFDC2626);
const _kRedBg      = Color(0xFFFEF2F2);
const _kRedBorder  = Color(0xFFFECACA);
const _kGreen      = Color(0xFF0A8A5C);
const _kGreenBg    = Color(0xFFEDFAF4);
const _kGreenBorder = Color(0xFF9FE0C5);

// ─── Provider ─────────────────────────────────────────────────────────────────
final dealerBrandsProvider =
FutureProvider.family<List<BrandModel>, String>((ref, dealerId) async {
  return ref.read(brandControllerProvider.notifier).getBrandsByDealer(dealerId);
});

// ─── Screen ───────────────────────────────────────────────────────────────────
class DealerDiscountCreatePage extends ConsumerStatefulWidget {
  final String dealerId;
  const DealerDiscountCreatePage({super.key, required this.dealerId});

  @override
  ConsumerState<DealerDiscountCreatePage> createState() =>
      _DealerDiscountCreatePageState();
}

class _DealerDiscountCreatePageState
    extends ConsumerState<DealerDiscountCreatePage> {
  final _formKey           = GlobalKey<FormState>();
  final _descriptionCtrl   = TextEditingController();
  final List<BrandDiscount> _brandDiscounts = [];

  @override
  void initState() {
    super.initState();
    // ✅ Force fresh fetch every time screen opens — prevents stale cached brands
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(dealerBrandsProvider(widget.dealerId));
    });
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw           = Screen.w(context);
    final sh           = Screen.h(context);
    final brandsAsync  = ref.watch(dealerBrandsProvider(widget.dealerId));
    final discountState = ref.watch(dealerDiscountControllerProvider);

    return brandsAsync.when(
      loading: () => const Scaffold(
          backgroundColor: _kBg, body: Center(child: GlobalLoader())),
      error: (e, _) => _buildError(context, e, sw, sh),
      data: (_) => Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(
          child: Column(
            children: [
              // ── Top Nav ────────────────────────────
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
                    Text('Create Discount',
                        style: TextStyle(
                            fontSize: sw * 0.042,
                            fontWeight: FontWeight.w700,
                            color: _kDark,
                            letterSpacing: -0.2)),
                    const Spacer(),
                    // Add brand button
                    CircularIconButton(
                      icon: Icons.add,
                      onTap: () {
                        if (brandsAsync.hasValue) _showBrandSelectionSheet();
                      },
                    ),
                  ],
                ),
              ),

              // ── Body ───────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: ListView(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                    children: [
                      // empty state
                      if (_brandDiscounts.isEmpty)
                        _buildEmptyState(sw, sh)
                      else
                        ..._brandDiscounts.asMap().entries.map(
                              (e) => _BrandDiscountCard(
                            key: ValueKey(e.value.brand.brandId),
                            brandDiscount: e.value,
                            index: e.key,
                            onRemoveBrand: () => setState(
                                    () => _brandDiscounts.removeAt(e.key)),
                            onAddModel: () =>
                                _showModelDiscountSheet(e.key),
                            onEditModel: (mi) =>
                                _showModelDiscountSheet(e.key,
                                    editIndex: mi),
                            onRemoveModel: (mi) => setState(() =>
                                e.value.modelDiscounts.removeAt(mi)),
                          ),
                        ),

                      SizedBox(height: sh * 0.02),

                      // Description field
                      _buildSectionCard(
                        sw: sw,
                        icon: Icons.description_outlined,
                        title: 'Description',
                        child: TextFormField(
                          controller: _descriptionCtrl,
                          maxLines: 3,
                          style: TextStyle(
                              fontSize: sw * 0.035,
                              color: _kDark,
                              fontWeight: FontWeight.w500),
                          decoration: InputDecoration(
                            hintText: 'Optional notes about this discount',
                            hintStyle: TextStyle(
                                fontSize: sw * 0.034,
                                color: _kMuted,
                                fontWeight: FontWeight.w400),
                            filled: true,
                            fillColor: _kBg,
                            contentPadding: EdgeInsets.all(sw * 0.04),
                            border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(sw * 0.028),
                              borderSide: const BorderSide(color: _kBorder),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(sw * 0.028),
                              borderSide: const BorderSide(color: _kBorder),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(sw * 0.028),
                              borderSide: const BorderSide(
                                  color: _kBlue, width: 1.5),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: sh * 0.025),

                      // Submit button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _brandDiscounts.isNotEmpty
                              ? _createDiscounts
                              : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kBlue,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor:
                            const Color(0xFFE0E0E0),
                            padding: EdgeInsets.symmetric(
                                vertical: sh * 0.018),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(sw * 0.035),
                            ),
                            elevation: 0,
                          ),
                          child: discountState.isLoading
                              ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2))
                              : Text('Create Discounts',
                              style: TextStyle(
                                  fontSize: sw * 0.04,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),

                      SizedBox(height: sh * 0.04),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _buildEmptyState(double sw, double sh) {
    return Container(
      margin: EdgeInsets.only(bottom: sh * 0.02),
      padding: EdgeInsets.symmetric(
          vertical: sh * 0.05, horizontal: sw * 0.06),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
      ),
      child: Column(
        children: [
          Container(
            width: sw * 0.18,
            height: sw * 0.18,
            decoration: BoxDecoration(
              color: _kBg,
              shape: BoxShape.circle,
              border: Border.all(color: _kBorder),
            ),
            child: Icon(Icons.local_offer_outlined,
                size: sw * 0.09, color: _kMuted),
          ),
          SizedBox(height: sh * 0.02),
          Text('No brands added yet',
              style: TextStyle(
                  fontSize: sw * 0.038,
                  fontWeight: FontWeight.w700,
                  color: _kDark)),
          SizedBox(height: sh * 0.008),
          Text(
            'Tap the + button above to add a brand and set model discounts.',
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: sw * 0.032,
                color: _kMuted,
                fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  // ── Section card wrapper ───────────────────────────────────────────────────
  Widget _buildSectionCard({
    required double sw,
    required IconData icon,
    required String title,
    required Widget child,
  }) {
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
                    color: _kBg,
                    borderRadius: BorderRadius.circular(sw * 0.022),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Icon(icon, size: sw * 0.04, color: _kDark),
                ),
                SizedBox(width: sw * 0.025),
                Text(title,
                    style: TextStyle(
                        fontSize: sw * 0.035,
                        fontWeight: FontWeight.w700,
                        color: _kDark)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          Padding(padding: EdgeInsets.all(sw * 0.04), child: child),
        ],
      ),
    );
  }

  // ── Brand selection bottom sheet ───────────────────────────────────────────
  void _showBrandSelectionSheet() {
    final brands = ref
        .read(dealerBrandsProvider(widget.dealerId))
        .valueOrNull ??
        [];
    final available = brands
        .where((b) =>
    !_brandDiscounts.any((bd) => bd.brand.brandName == b.brandName))
        .toList();

    if (available.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('All brands have been added'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }

    final sw = Screen.w(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,          // ✅ allows sheet to size properly
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Column(            // ✅ Column, not Padding — no overflow
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(2)),
                  ),
                ),
                Text('Select Brand',
                    style: TextStyle(
                        fontSize: sw * 0.045,
                        fontWeight: FontWeight.w800,
                        color: _kDark)),
                const SizedBox(height: 14),
              ],
            ),
          ),
          Flexible(                    // ✅ Flexible prevents overflow
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
              child: Column(
                children: available.map((brand) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _brandDiscounts.add(BrandDiscount(
                            brand: brand, modelDiscounts: []));
                      });
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 13),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: sw * 0.09,
                            height: sw * 0.09,
                            decoration: BoxDecoration(
                              color: _kBlueBg,
                              borderRadius:
                              BorderRadius.circular(sw * 0.025),
                              border:
                              Border.all(color: _kBlueBorder),
                            ),
                            child: Icon(Icons.storefront_outlined,
                                size: sw * 0.045, color: _kBlue),
                          ),
                          SizedBox(width: sw * 0.03),
                          Expanded(
                            child: Text(brand.brandName,
                                style: TextStyle(
                                    fontSize: sw * 0.036,
                                    fontWeight: FontWeight.w600,
                                    color: _kDark)),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: _kMuted, size: sw * 0.05),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Model discount bottom sheet ────────────────────────────────────────────
  void _showModelDiscountSheet(int brandIndex, {int? editIndex}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ModelDiscountSheet(
        brand: _brandDiscounts[brandIndex].brand,
        existingModelDiscounts: _brandDiscounts[brandIndex].modelDiscounts,
        editIndex: editIndex,
        onSave: (modelDiscount) {
          setState(() {
            if (editIndex != null) {
              _brandDiscounts[brandIndex].modelDiscounts[editIndex] =
                  modelDiscount;
            } else {
              _brandDiscounts[brandIndex].modelDiscounts.add(modelDiscount);
            }
          });
        },
        fetchProducts: (brandName) async {
          return ref
              .read(productControllerProvider.notifier)
              .fetchProductsByBrand([brandName]);
        },
      ),
    );
  }

  // ── Create discounts ───────────────────────────────────────────────────────
  Future<void> _createDiscounts() async {
    try {
      final discounts = <DealerDiscountModel>[];
      for (final bd in _brandDiscounts) {
        for (final md in bd.modelDiscounts) {
          discounts.add(DealerDiscountModel.fromJson({
            'dealer_id': widget.dealerId,
            'brand_name': bd.brand.brandName,
            'model_name': md.modelName,
            'discount_value': md.discountValue,
            'is_percentage': md.isPercentage,
            'description': _descriptionCtrl.text.trim(),
            'product_ids': [md.productId],
          }));
        }
      }

      await ref
          .read(dealerDiscountControllerProvider.notifier)
          .createDealerDiscounts(discounts);

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${discounts.length} discount(s) created!',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString(),
                style: const TextStyle(fontWeight: FontWeight.w600)),
            backgroundColor: _kRed,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10)),
          ),
        );
      }
    }
  }

  // ── Error state ────────────────────────────────────────────────────────────
  Widget _buildError(
      BuildContext context, Object error, double sw, double sh) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.03),
              child: Row(
                children: [
                  CircularIconButton(
                      icon: Icons.arrow_back_ios_rounded,
                      onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  Text('Create Discount',
                      style: TextStyle(
                          fontSize: sw * 0.042,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                  const Spacer(),
                  SizedBox(width: sw * 0.095),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: sw * 0.18,
                      height: sw * 0.18,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _kBorder)),
                      child: Icon(Icons.wifi_off_rounded,
                          size: sw * 0.09, color: _kMuted),
                    ),
                    SizedBox(height: sh * 0.02),
                    Text('No Internet Connection',
                        style: TextStyle(
                            fontSize: sw * 0.04,
                            fontWeight: FontWeight.w600,
                            color: _kMid)),
                    SizedBox(height: sh * 0.025),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(dealerBrandsProvider(widget.dealerId)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        shape: const CircleBorder(),
                        padding: const EdgeInsets.all(16),
                        elevation: 0,
                      ),
                      child: const Icon(Icons.refresh_rounded),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Brand Discount Card ──────────────────────────────────────────────────────
class _BrandDiscountCard extends StatelessWidget {
  final BrandDiscount brandDiscount;
  final int index;
  final VoidCallback onRemoveBrand;
  final VoidCallback onAddModel;
  final void Function(int) onEditModel;
  final void Function(int) onRemoveModel;

  const _BrandDiscountCard({
    super.key,
    required this.brandDiscount,
    required this.index,
    required this.onRemoveBrand,
    required this.onAddModel,
    required this.onEditModel,
    required this.onRemoveModel,
  });

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Container(
      margin: EdgeInsets.only(bottom: sh * 0.014),
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
          // ── Brand header ─────────────────────────
          Padding(
            padding: EdgeInsets.fromLTRB(
                sw * 0.04, sw * 0.035, sw * 0.025, sw * 0.035),
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
                  child: Icon(Icons.storefront_outlined,
                      size: sw * 0.04, color: _kBlue),
                ),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Text(
                    brandDiscount.brand.brandName,
                    style: TextStyle(
                        fontSize: sw * 0.038,
                        fontWeight: FontWeight.w700,
                        color: _kDark),
                  ),
                ),
                // Add model button
                GestureDetector(
                  onTap: onAddModel,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.03, vertical: sw * 0.015),
                    decoration: BoxDecoration(
                      color: _kBlueBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBlueBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.add, size: sw * 0.035, color: _kBlue),
                        SizedBox(width: sw * 0.01),
                        Text('Model',
                            style: TextStyle(
                                fontSize: sw * 0.028,
                                fontWeight: FontWeight.w700,
                                color: _kBlue)),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: sw * 0.02),
                // Remove brand button
                GestureDetector(
                  onTap: onRemoveBrand,
                  child: Container(
                    width: sw * 0.08,
                    height: sw * 0.08,
                    decoration: BoxDecoration(
                      color: _kRedBg,
                      borderRadius: BorderRadius.circular(sw * 0.022),
                      border: Border.all(color: _kRedBorder),
                    ),
                    child: Icon(Icons.delete_outline_rounded,
                        size: sw * 0.04, color: _kRed),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 1, thickness: 1, color: _kBorder),

          // ── Models list ───────────────────────────
          if (brandDiscount.modelDiscounts.isEmpty)
            Padding(
              padding: EdgeInsets.all(sw * 0.04),
              child: Text(
                'No models added — tap "+ Model" to add one',
                style: TextStyle(
                    fontSize: sw * 0.031,
                    color: _kMuted,
                    fontWeight: FontWeight.w500),
              ),
            )
          else
            ...brandDiscount.modelDiscounts.asMap().entries.map((e) {
              final mi = e.key;
              final md = e.value;
              final isLast = mi == brandDiscount.modelDiscounts.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.04, vertical: sw * 0.025),
                    child: Row(
                      children: [
                        Container(
                          width: sw * 0.06,
                          height: sw * 0.06,
                          decoration: BoxDecoration(
                            color: _kGreenBg,
                            borderRadius:
                            BorderRadius.circular(sw * 0.018),
                            border: Border.all(color: _kGreenBorder),
                          ),
                          child: Icon(Icons.local_offer_outlined,
                              size: sw * 0.032, color: _kGreen),
                        ),
                        SizedBox(width: sw * 0.025),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(md.modelName,
                                  style: TextStyle(
                                      fontSize: sw * 0.034,
                                      fontWeight: FontWeight.w700,
                                      color: _kDark)),
                              SizedBox(height: sw * 0.005),
                              Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: sw * 0.02,
                                    vertical: sw * 0.006),
                                decoration: BoxDecoration(
                                  color: _kGreenBg,
                                  borderRadius: BorderRadius.circular(20),
                                  border:
                                  Border.all(color: _kGreenBorder),
                                ),
                                child: Text(
                                  md.isPercentage
                                      ? '${md.discountValue}% off'
                                      : '₹${md.discountValue} off',
                                  style: TextStyle(
                                      fontSize: sw * 0.026,
                                      fontWeight: FontWeight.w700,
                                      color: _kGreen),
                                ),
                              ),
                            ],
                          ),
                        ),
                        // Edit
                        GestureDetector(
                          onTap: () => onEditModel(mi),
                          child: Container(
                            width: sw * 0.075,
                            height: sw * 0.075,
                            decoration: BoxDecoration(
                              color: _kBlueBg,
                              borderRadius:
                              BorderRadius.circular(sw * 0.02),
                              border: Border.all(color: _kBlueBorder),
                            ),
                            child: Icon(Icons.edit_outlined,
                                size: sw * 0.038, color: _kBlue),
                          ),
                        ),
                        SizedBox(width: sw * 0.02),
                        // Delete
                        GestureDetector(
                          onTap: () => onRemoveModel(mi),
                          child: Container(
                            width: sw * 0.075,
                            height: sw * 0.075,
                            decoration: BoxDecoration(
                              color: _kRedBg,
                              borderRadius:
                              BorderRadius.circular(sw * 0.02),
                              border: Border.all(color: _kRedBorder),
                            ),
                            child: Icon(Icons.delete_outline_rounded,
                                size: sw * 0.038, color: _kRed),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                        height: 1, thickness: 1, color: _kBorder),
                ],
              );
            }),
        ],
      ),
    );
  }
}

// ─── Model Discount Sheet ─────────────────────────────────────────────────────
class _ModelDiscountSheet extends StatefulWidget {
  final BrandModel brand;
  final List<ModelDiscount> existingModelDiscounts;
  final int? editIndex;
  final void Function(ModelDiscount) onSave;
  final Future<List<ProductModel>> Function(String brandName) fetchProducts;

  const _ModelDiscountSheet({
    required this.brand,
    required this.existingModelDiscounts,
    required this.editIndex,
    required this.onSave,
    required this.fetchProducts,
  });

  @override
  State<_ModelDiscountSheet> createState() => _ModelDiscountSheetState();
}

class _ModelDiscountSheetState extends State<_ModelDiscountSheet> {
  final _discountCtrl = TextEditingController();
  String? _selectedModel;
  String? _selectedProductId;
  String? _selectedProductName;
  bool   _isPercentage = true;
  List<ProductModel> _products = [];
  bool   _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    if (widget.editIndex != null) {
      final existing =
      widget.existingModelDiscounts[widget.editIndex!];
      _selectedModel      = existing.modelName;
      _selectedProductId  = existing.productId;
      _discountCtrl.text  = existing.discountValue.toString();
      _isPercentage       = existing.isPercentage;
      // fetch products for existing model
      _loadProducts(existing.modelName);
    }
  }

  @override
  void dispose() {
    _discountCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProducts(String model) async {
    setState(() => _loadingProducts = true);
    try {
      final all = await widget.fetchProducts(widget.brand.brandName);
      if (mounted) {
        setState(() {
          _products = all.where((p) => p.model == model).toList();
          _loadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  List<String> get _availableModels {
    final models = widget.brand.brandModels ?? [];
    return models.where((m) {
      final taken = widget.existingModelDiscounts.any((md) => md.modelName == m);
      if (widget.editIndex != null) {
        final current = widget.existingModelDiscounts[widget.editIndex!].modelName;
        return m == current || !taken;
      }
      return !taken;
    }).toList();
  }

  void _showModelPicker() {
    final sw = Screen.w(context);
    final models = _availableModels;
    if (models.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('No more models available'),
            behavior: SnackBarBehavior.floating),
      );
      return;
    }
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Select Model',
                style: TextStyle(
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w800,
                    color: _kDark)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(
                child: Column(
                  children: models.map((m) {
                    final isSel = _selectedModel == m;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        setState(() {
                          _selectedModel     = m;
                          _selectedProductId = null;
                          _selectedProductName = null;
                          _products          = [];
                        });
                        await _loadProducts(m);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSel ? _kBlueBg : _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSel ? _kBlueBorder : _kBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(m,
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSel ? _kBlue : _kMid)),
                            ),
                            if (isSel)
                              const Icon(Icons.check_rounded,
                                  color: _kBlue, size: 18),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showProductPicker() {
    final sw = Screen.w(context);
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text('Select Product',
                style: TextStyle(
                    fontSize: sw * 0.045,
                    fontWeight: FontWeight.w800,
                    color: _kDark)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(
                child: Column(
                  children: _products.map((p) {
                    final isSel = _selectedProductId == p.productId;
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedProductId   = p.productId;
                          _selectedProductName = p.productName;
                        });
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSel ? _kBlueBg : _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSel ? _kBlueBorder : _kBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(p.productName ?? '',
                                  style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: isSel
                                          ? FontWeight.w700
                                          : FontWeight.w500,
                                      color: isSel ? _kBlue : _kMid)),
                            ),
                            if (isSel)
                              const Icon(Icons.check_rounded,
                                  color: _kBlue, size: 18),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool get _canSave =>
      _selectedModel != null &&
          _selectedProductId != null &&
          _discountCtrl.text.isNotEmpty &&
          (double.tryParse(_discountCtrl.text) ?? 0) > 0;

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // handle
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 18),
                decoration: BoxDecoration(
                    color: _kBorder, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Text(
              widget.editIndex != null
                  ? 'Edit Model Discount'
                  : 'Add Model Discount',
              style: TextStyle(
                  fontSize: sw * 0.045,
                  fontWeight: FontWeight.w800,
                  color: _kDark),
            ),
            Text(widget.brand.brandName,
                style: const TextStyle(
                    fontSize: 12,
                    color: _kMuted,
                    fontWeight: FontWeight.w500)),
            SizedBox(height: sw * 0.05),

            // ── Step 1: Model ──────────────────────
            _FieldLabel(sw: sw, label: 'Model'),
            SizedBox(height: sh * 0.006),
            GestureDetector(
              onTap: _showModelPicker,
              child: _PickerField(
                sw: sw,
                icon: Icons.category_outlined,
                value: _selectedModel,
                placeholder: 'Select model',
              ),
            ),
            SizedBox(height: sh * 0.015),

            // ── Step 2: Product ────────────────────
            if (_selectedModel != null) ...[
              _FieldLabel(sw: sw, label: 'Product'),
              SizedBox(height: sh * 0.006),
              if (_loadingProducts)
                Container(
                  height: sh * 0.065,
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(sw * 0.028),
                    border: Border.all(color: _kBorder),
                  ),
                  child: const Center(
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: _kBlue),
                    ),
                  ),
                )
              else if (_products.isEmpty)
                Container(
                  padding: EdgeInsets.all(sw * 0.035),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(sw * 0.028),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Text(
                    'No products found for $_selectedModel',
                    style: TextStyle(
                        fontSize: sw * 0.032,
                        color: _kMuted),
                  ),
                )
              else
                GestureDetector(
                  onTap: _showProductPicker,
                  child: _PickerField(
                    sw: sw,
                    icon: Icons.inventory_2_outlined,
                    value: _selectedProductName,
                    placeholder: 'Select product',
                  ),
                ),
              SizedBox(height: sh * 0.015),
            ],

            // ── Step 3: Discount value ─────────────
            _FieldLabel(sw: sw, label: 'Discount Value'),
            SizedBox(height: sh * 0.006),
            TextField(
              controller: _discountCtrl,
              keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              style: TextStyle(
                  fontSize: sw * 0.036,
                  color: _kDark,
                  fontWeight: FontWeight.w500),
              decoration: InputDecoration(
                hintText: _isPercentage ? 'e.g. 10' : 'e.g. 500',
                hintStyle: TextStyle(
                    fontSize: sw * 0.034,
                    color: _kMuted,
                    fontWeight: FontWeight.w400),
                prefixIcon: Icon(Icons.percent,
                    color: _kMuted, size: sw * 0.045),
                suffixText: _isPercentage ? '%' : '₹',
                suffixStyle: TextStyle(
                    fontSize: sw * 0.036,
                    fontWeight: FontWeight.w700,
                    color: _kBlue),
                filled: true,
                fillColor: _kBg,
                contentPadding:
                EdgeInsets.symmetric(horizontal: sw * 0.04),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw * 0.028),
                    borderSide: const BorderSide(color: _kBorder)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw * 0.028),
                    borderSide: const BorderSide(color: _kBorder)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(sw * 0.028),
                    borderSide:
                    const BorderSide(color: _kBlue, width: 1.5)),
              ),
            ),
            SizedBox(height: sh * 0.015),

            // ── Step 4: Is Percentage ──────────────
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.03),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(sw * 0.028),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Is Percentage?',
                      style: TextStyle(
                          fontSize: sw * 0.036,
                          fontWeight: FontWeight.w600,
                          color: _kDark)),
                  Switch(
                    value: _isPercentage,
                    onChanged: (v) => setState(() => _isPercentage = v),
                    activeColor: _kBlue,
                  ),
                ],
              ),
            ),

            SizedBox(height: sh * 0.025),

            // ── Actions ────────────────────────────
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding:
                      EdgeInsets.symmetric(vertical: sh * 0.016),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: _kBorder),
                    ),
                    child: Text('Cancel',
                        style: TextStyle(
                            fontSize: sw * 0.036,
                            fontWeight: FontWeight.w700,
                            color: _kMuted)),
                  ),
                ),
                SizedBox(width: sw * 0.03),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _canSave
                        ? () {
                      final value =
                      double.parse(_discountCtrl.text);
                      widget.onSave(ModelDiscount(
                        modelName: _selectedModel!,
                        discountValue: value,
                        isPercentage: _isPercentage,
                        productId: _selectedProductId!,
                      ));
                      Navigator.pop(context);
                    }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kBlue,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: const Color(0xFFE0E0E0),
                      padding:
                      EdgeInsets.symmetric(vertical: sh * 0.016),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 0,
                    ),
                    child: Text(
                      widget.editIndex != null ? 'Update' : 'Add',
                      style: TextStyle(
                          fontSize: sw * 0.036,
                          fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Small reusable widgets ───────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final double sw;
  final String label;
  const _FieldLabel({required this.sw, required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(
        fontSize: sw * 0.028,
        fontWeight: FontWeight.w700,
        color: _kMuted,
        letterSpacing: 0.5),
  );
}

class _PickerField extends StatelessWidget {
  final double sw;
  final IconData icon;
  final String? value;
  final String placeholder;

  const _PickerField({
    required this.sw,
    required this.icon,
    required this.value,
    required this.placeholder,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: sw * 0.035),
      decoration: BoxDecoration(
        color: _kBg,
        borderRadius: BorderRadius.circular(sw * 0.028),
        border: Border.all(
            color: value != null ? _kBlueBorder : _kBorder),
      ),
      child: Row(
        children: [
          Icon(icon,
              size: sw * 0.045,
              color: value != null ? _kBlue : _kMuted),
          SizedBox(width: sw * 0.025),
          Expanded(
            child: Text(
              value ?? placeholder,
              style: TextStyle(
                  fontSize: sw * 0.036,
                  fontWeight:
                  value != null ? FontWeight.w600 : FontWeight.w400,
                  color: value != null ? _kDark : _kMuted),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              color: _kMuted, size: sw * 0.05),
        ],
      ),
    );
  }
}

// ─── Data Models (unchanged) ──────────────────────────────────────────────────
class BrandDiscount {
  final BrandModel brand;
  final List<ModelDiscount> modelDiscounts;
  BrandDiscount({required this.brand, required this.modelDiscounts});
}

class ModelDiscount {
  final String modelName;
  final double discountValue;
  final bool isPercentage;
  final String productId;
  ModelDiscount({
    required this.modelName,
    required this.discountValue,
    required this.isPercentage,
    required this.productId,
  });
}