import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/feature/brand/model/brand_model.dart';
import '../../../feature/discount/model/dealer_discount_model.dart';
import '../../../feature/product/model/product_model.dart';
import '../../../widgets/circle_button.dart';
import '../../brand/controller/brand_controller.dart';
import '../../product/controller/product_controller.dart';
import '../controller/discount_controller.dart';

// ── Zoho Books design tokens (unified with the rest of the app) ───────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Colors.white;
const _kBd       = Color(0xFFE5E7EB);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
const _kT4       = Color(0xFF9CA3AF);
const _kGreen    = Color(0xFF0F6E56);
const _kGreenBg  = Color(0xFFEDFAF5);
const _kGreenBd  = Color(0xFF9FE0C5);
const _kRed      = Color(0xFFDC2626);
const _kRedBg    = Color(0xFFFEF2F2);
const _kRedBd    = Color(0xFFFECACA);
const _kAmber    = Color(0xFFB45309);
const _kAmberBg  = Color(0xFFFFFBEB);
const _kAmberBd  = Color(0xFFFCD28A);
const _kPurple   = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBd = Color(0xFFDDD6FE);

// ── Shared input decoration helper ────────────────────────────────────────────
InputDecoration _inputDeco(double sw, String hint,
    {Widget? prefix, Widget? suffix, int maxLines = 1}) {
  final r = (sw * 0.028).clamp(8.0, 12.0);
  return InputDecoration(
    hintText:   hint,
    hintStyle:  TextStyle(
        fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT4),
    prefixIcon:  prefix,
    suffixIcon:  suffix,
    filled:      true,
    fillColor:   _kBg,
    contentPadding: EdgeInsets.symmetric(
        horizontal: sw * 0.04,
        vertical:   maxLines > 1 ? sw * 0.035 : 0),
    border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide:   const BorderSide(color: _kBd, width: 0.5)),
    enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide:   const BorderSide(color: _kBd, width: 0.5)),
    focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: const BorderSide(color: _kP, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide:   const BorderSide(color: _kRed)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide: const BorderSide(color: _kRed, width: 1.5)),
  );
}

// ── Sheet handle ──────────────────────────────────────────────────────────────
Widget _handle() => Center(
  child: Container(
    width: 36, height: 4,
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(
        color: _kBd, borderRadius: BorderRadius.circular(2)),
  ),
);

// ═════════════════════════════════════════════════════════════════════════════
class DealerDiscountCreatePage extends ConsumerStatefulWidget {
  final String dealerId;
  const DealerDiscountCreatePage({super.key, required this.dealerId});

  @override
  ConsumerState<DealerDiscountCreatePage> createState() =>
      _DealerDiscountCreatePageState();
}

class _DealerDiscountCreatePageState
    extends ConsumerState<DealerDiscountCreatePage> {
  final _formKey          = GlobalKey<FormState>();
  final _descriptionCtrl  = TextEditingController();
  final List<BrandDiscount> _brandDiscounts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.invalidate(dealerBrandsProvider(widget.dealerId));
    });
  }

  @override
  void dispose() {
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sw            = Screen.w(context);
    final sh            = Screen.h(context);
    final brandsAsync   = ref.watch(dealerBrandsProvider(widget.dealerId));
    final discountState = ref.watch(dealerDiscountControllerProvider);

    return brandsAsync.when(
      loading: () => const Scaffold(
          backgroundColor: _kBg,
          body: Center(
              child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5))),
      error: (e, _) => _errorScaffold(context, sw, sh),
      data: (_) => Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(child: Column(children: [

          // ── App Bar ──────────────────────────────────────────────────
          Container(
            color:   _kWhite,
            padding: EdgeInsets.fromLTRB(
                sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
            child: Row(children: [
              CircularIconButton(
                  icon: Icons.arrow_back_ios_rounded,
                  onTap: () => Navigator.pop(context)),
              const Spacer(),
              Text('Create Discount',
                  style: TextStyle(
                      fontSize:     (sw * 0.042).clamp(14.0, 20.0),
                      fontWeight:   FontWeight.w700,
                      color:        _kT1,
                      letterSpacing: -0.2)),
              const Spacer(),
              // Add brand button
              GestureDetector(
                onTap: () {
                  if (brandsAsync.hasValue) _showBrandSelectionSheet(sw);
                },
                child: Container(
                  padding: EdgeInsets.all((sw * 0.022).clamp(7.0, 12.0)),
                  decoration: BoxDecoration(
                      color:        _kPBg,
                      borderRadius: BorderRadius.circular(
                          (sw * 0.025).clamp(8.0, 12.0)),
                      border: Border.all(color: _kPBd, width: 0.5)),
                  child: Icon(Icons.add,
                      size:  (sw * 0.045).clamp(15.0, 20.0), color: _kP),
                ),
              ),
            ]),
          ),

          // ── Form body ────────────────────────────────────────────────
          Expanded(
            child: Form(
              key: _formKey,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.04),
                children: [

                  // Brand discount cards or empty state
                  if (_brandDiscounts.isEmpty)
                    _emptyState(sw, sh)
                  else
                    ..._brandDiscounts.asMap().entries.map((e) =>
                        _BrandDiscountCard(
                          key:            ValueKey(e.value.brand.brandId),
                          brandDiscount:  e.value,
                          index:          e.key,
                          sw:             sw,
                          sh:             sh,
                          onRemoveBrand: () => setState(
                                  () => _brandDiscounts.removeAt(e.key)),
                          onAddModel: () =>
                              _showModelDiscountSheet(e.key),
                          onEditModel: (mi) =>
                              _showModelDiscountSheet(e.key, editIndex: mi),
                          onRemoveModel: (mi) => setState(
                                  () => e.value.modelDiscounts.removeAt(mi)),
                        )),

                  SizedBox(height: sh * 0.012),

                  // Description section
                  _Sec(
                    sw: sw,
                    icon:      Icons.description_outlined,
                    iconBg:    _kBg,
                    iconColor: _kT1,
                    title:     'Notes (Optional)',
                    child: TextFormField(
                      controller: _descriptionCtrl,
                      maxLines:   3,
                      style: TextStyle(
                          fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                          color:      _kT1,
                          fontWeight: FontWeight.w500),
                      decoration: _inputDeco(
                          sw, 'Optional notes about this discount',
                          maxLines: 3),
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
                          backgroundColor:         _kP,
                          foregroundColor:         _kWhite,
                          disabledBackgroundColor: _kBd,
                          padding: EdgeInsets.symmetric(
                              vertical: sh * 0.018),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  (sw * 0.035).clamp(10.0, 16.0))),
                          elevation: 0),
                      child: discountState.isLoading
                          ? SizedBox(
                          width:  (sw * 0.05).clamp(16.0, 22.0),
                          height: (sw * 0.05).clamp(16.0, 22.0),
                          child: const CircularProgressIndicator(
                              color: _kWhite, strokeWidth: 2.5))
                          : Text('Create Discounts',
                          style: TextStyle(
                              fontSize:   (sw * 0.04).clamp(13.0, 18.0),
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ])),
      ),
    );
  }

  // ── Empty state ──────────────────────────────────────────────────────────
  Widget _emptyState(double sw, double sh) => Container(
    margin: EdgeInsets.only(bottom: sh * 0.012),
    padding: EdgeInsets.symmetric(
        vertical: sh * 0.05, horizontal: sw * 0.06),
    decoration: BoxDecoration(
        color:        _kWhite,
        borderRadius: BorderRadius.circular(
            (sw * 0.04).clamp(10.0, 18.0)),
        border: Border.all(color: _kBd, width: 0.5)),
    child: Column(children: [
      Container(
        width:  (sw * 0.18).clamp(60.0, 90.0),
        height: (sw * 0.18).clamp(60.0, 90.0),
        decoration: BoxDecoration(
            color:  _kBg,
            shape:  BoxShape.circle,
            border: Border.all(color: _kBd, width: 0.5)),
        child: Icon(Icons.local_offer_outlined,
            size:  (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
      ),
      SizedBox(height: sh * 0.02),
      Text('No brands added yet',
          style: TextStyle(
              fontSize:   (sw * 0.038).clamp(13.0, 17.0),
              fontWeight: FontWeight.w700,
              color:      _kT1)),
      SizedBox(height: sh * 0.008),
      Text(
          'Tap the + button above to add a brand\nand set model discounts.',
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize:   (sw * 0.032).clamp(11.0, 14.0),
              color:      _kT4,
              height:     1.5)),
    ]),
  );

  // ── Brand selection sheet ─────────────────────────────────────────────────
  void _showBrandSelectionSheet(double sw) {
    final brands =
        ref.read(dealerBrandsProvider(widget.dealerId)).valueOrNull ?? [];
    final available = brands
        .where((b) => !_brandDiscounts
        .any((bd) => bd.brand.brandName == b.brandName))
        .toList();

    if (available.isEmpty) {
      _snack('All brands have been added', _kAmber);
      return;
    }

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.5,
        maxChildSize:     0.85,
        builder: (_, sc) => Padding(
          padding: EdgeInsets.fromLTRB(
              sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              Text('Select Brand',
                  style: TextStyle(
                      fontSize:   (sw * 0.045).clamp(15.0, 21.0),
                      fontWeight: FontWeight.w800,
                      color:      _kT1)),
              SizedBox(height: sw * 0.008),
              Text('Choose a brand to add discounts for',
                  style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0),
                      color:    _kT4)),
              SizedBox(height: sw * 0.035),
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  itemCount:  available.length,
                  itemBuilder: (_, i) {
                    final brand = available[i];
                    return GestureDetector(
                      onTap: () {
                        setState(() => _brandDiscounts.add(
                            BrandDiscount(
                                brand: brand, modelDiscounts: [])));
                        Navigator.pop(context);
                      },
                      child: Container(
                        margin: EdgeInsets.only(bottom: sw * 0.02),
                        padding: EdgeInsets.symmetric(
                            horizontal: sw * 0.04,
                            vertical:   sw * 0.032),
                        decoration: BoxDecoration(
                            color:        _kBg,
                            borderRadius: BorderRadius.circular(
                                (sw * 0.028).clamp(8.0, 12.0)),
                            border:
                            Border.all(color: _kBd, width: 0.5)),
                        child: Row(children: [
                          Container(
                            width:  (sw * 0.09).clamp(32.0, 44.0),
                            height: (sw * 0.09).clamp(32.0, 44.0),
                            decoration: BoxDecoration(
                                color:        _kPurpleBg,
                                borderRadius: BorderRadius.circular(
                                    (sw * 0.025).clamp(8.0, 12.0)),
                                border: Border.all(
                                    color: _kPurpleBd, width: 0.5)),
                            child: Icon(Icons.storefront_outlined,
                                size:  (sw * 0.045).clamp(15.0, 20.0),
                                color: _kPurple),
                          ),
                          SizedBox(width: sw * 0.03),
                          Expanded(
                            child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text(brand.brandName,
                                      style: TextStyle(
                                          fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                                          fontWeight: FontWeight.w700,
                                          color:      _kT1)),
                                  if (brand.brandModels.isNotEmpty)
                                    Text(
                                        '${brand.brandModels.length} model${brand.brandModels.length != 1 ? 's' : ''}',
                                        style: TextStyle(
                                            fontSize:   (sw * 0.028).clamp(9.5, 12.5),
                                            color:      _kT4,
                                            fontWeight: FontWeight.w500)),
                                ]),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              color: _kT4,
                              size: (sw * 0.05).clamp(16.0, 22.0)),
                        ]),
                      ),
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

  // ── Model discount sheet ──────────────────────────────────────────────────
  void _showModelDiscountSheet(int brandIndex, {int? editIndex}) {
    final sw = MediaQuery.sizeOf(context).width;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => _ModelDiscountSheet(
        brand:                  _brandDiscounts[brandIndex].brand,
        existingModelDiscounts: _brandDiscounts[brandIndex].modelDiscounts,
        editIndex:              editIndex,
        onSave: (md) => setState(() {
          if (editIndex != null) {
            _brandDiscounts[brandIndex].modelDiscounts[editIndex] = md;
          } else {
            _brandDiscounts[brandIndex].modelDiscounts.add(md);
          }
        }),
        fetchProducts: (brandName) async => ref
            .read(productControllerProvider.notifier)
            .fetchProductsByBrand([brandName]),
      ),
    );
  }

  // ── Create discounts ──────────────────────────────────────────────────────
  Future<void> _createDiscounts() async {
    try {
      final discounts = <DealerDiscountModel>[];
      for (final bd in _brandDiscounts) {
        for (final md in bd.modelDiscounts) {
          discounts.add(DealerDiscountModel.fromJson({
            'dealer_id':      widget.dealerId,
            'brand_name':     bd.brand.brandName,
            'model_name':     md.modelName,
            'discount_value': md.discountValue,
            'is_percentage':  md.isPercentage,
            'description':    _descriptionCtrl.text.trim(),
            'product_ids':    [md.productId],
          }));
        }
      }

      await ref
          .read(dealerDiscountControllerProvider.notifier)
          .createDealerDiscounts(discounts);

      if (mounted) {
        Navigator.pop(context);
        _snack(
            '${discounts.length} discount${discounts.length != 1 ? 's' : ''} created!',
            _kGreen);
      }
    } catch (e) {
      if (mounted) _snack(e.toString(), _kRed);
    }
  }

  // ── Error scaffold ────────────────────────────────────────────────────────
  Widget _errorScaffold(BuildContext ctx, double sw, double sh) => Scaffold(
    backgroundColor: _kBg,
    body: SafeArea(child: Column(children: [
      Container(
        color:   _kWhite,
        padding: EdgeInsets.fromLTRB(
            sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
        child: Row(children: [
          CircularIconButton(
              icon: Icons.arrow_back_ios_rounded,
              onTap: () => Navigator.pop(ctx)),
          const Spacer(),
          Text('Create Discount',
              style: TextStyle(
                  fontSize:   (sw * 0.042).clamp(14.0, 20.0),
                  fontWeight: FontWeight.w700,
                  color:      _kT1,
                  letterSpacing: -0.2)),
          const Spacer(),
          SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
        ]),
      ),
      Expanded(
        child: Center(
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(
              width:  (sw * 0.18).clamp(60.0, 90.0),
              height: (sw * 0.18).clamp(60.0, 90.0),
              decoration: BoxDecoration(
                  color:  _kWhite,
                  shape:  BoxShape.circle,
                  border: Border.all(color: _kBd, width: 0.5)),
              child: Icon(Icons.wifi_off_rounded,
                  size:  (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
            ),
            SizedBox(height: sh * 0.02),
            Text('No Connection',
                style: TextStyle(
                    fontSize:   (sw * 0.04).clamp(13.0, 18.0),
                    fontWeight: FontWeight.w600,
                    color:      _kT2)),
            SizedBox(height: sh * 0.02),
            ElevatedButton(
                onPressed: () => ref
                    .invalidate(dealerBrandsProvider(widget.dealerId)),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kP,
                    foregroundColor: _kWhite,
                    shape:   const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                    elevation: 0),
                child: const Icon(Icons.refresh_rounded)),
          ]),
        ),
      ),
    ])),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// _BrandDiscountCard
// ═════════════════════════════════════════════════════════════════════════════
class _BrandDiscountCard extends StatelessWidget {
  const _BrandDiscountCard({
    super.key,
    required this.brandDiscount,
    required this.index,
    required this.sw,
    required this.sh,
    required this.onRemoveBrand,
    required this.onAddModel,
    required this.onEditModel,
    required this.onRemoveModel,
  });

  final BrandDiscount brandDiscount;
  final int           index;
  final double        sw, sh;
  final VoidCallback  onRemoveBrand, onAddModel;
  final void Function(int) onEditModel, onRemoveModel;

  @override
  Widget build(BuildContext context) => Container(
    margin: EdgeInsets.only(bottom: sh * 0.012),
    decoration: BoxDecoration(
        color:        _kWhite,
        borderRadius: BorderRadius.circular(
            (sw * 0.04).clamp(10.0, 18.0)),
        border: Border.all(color: _kBd, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

      // ── Brand header row ─────────────────────────────────────────
      Padding(
        padding: EdgeInsets.fromLTRB(
            sw * 0.04, sw * 0.035, sw * 0.025, sw * 0.035),
        child: Row(children: [
          Container(
            width:  (sw * 0.075).clamp(26.0, 36.0),
            height: (sw * 0.075).clamp(26.0, 36.0),
            decoration: BoxDecoration(
                color:        _kPurpleBg,
                borderRadius: BorderRadius.circular(
                    (sw * 0.022).clamp(6.0, 10.0)),
                border: Border.all(color: _kPurpleBd, width: 0.5)),
            child: Icon(Icons.storefront_outlined,
                size:  (sw * 0.04).clamp(14.0, 20.0), color: _kPurple),
          ),
          SizedBox(width: sw * 0.025),
          Expanded(
            child: Text(brandDiscount.brand.brandName,
                style: TextStyle(
                    fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                    fontWeight: FontWeight.w700,
                    color:      _kT1)),
          ),
          // + Model pill
          GestureDetector(
            onTap: onAddModel,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: (sw * 0.03).clamp(10.0, 14.0),
                  vertical:   (sw * 0.015).clamp(4.0, 7.0)),
              decoration: BoxDecoration(
                  color:        _kPBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _kPBd, width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.add,
                    size:  (sw * 0.032).clamp(11.0, 14.0), color: _kP),
                SizedBox(width: sw * 0.008),
                Text('Model',
                    style: TextStyle(
                        fontSize:   (sw * 0.028).clamp(9.5, 12.5),
                        fontWeight: FontWeight.w700,
                        color:      _kP)),
              ]),
            ),
          ),
          SizedBox(width: sw * 0.02),
          // Delete brand
          GestureDetector(
            onTap: onRemoveBrand,
            child: Container(
              width:  (sw * 0.075).clamp(26.0, 36.0),
              height: (sw * 0.075).clamp(26.0, 36.0),
              decoration: BoxDecoration(
                  color:        _kRedBg,
                  borderRadius: BorderRadius.circular(
                      (sw * 0.022).clamp(6.0, 10.0)),
                  border: Border.all(color: _kRedBd, width: 0.5)),
              child: Icon(Icons.delete_outline_rounded,
                  size:  (sw * 0.038).clamp(13.0, 17.0), color: _kRed),
            ),
          ),
        ]),
      ),

      Divider(height: 1, color: _kBd),

      // ── Model rows ───────────────────────────────────────────────
      if (brandDiscount.modelDiscounts.isEmpty)
        Padding(
          padding: EdgeInsets.all(sw * 0.04),
          child: Row(children: [
            Icon(Icons.info_outline_rounded,
                size:  (sw * 0.032).clamp(11.0, 14.0), color: _kT4),
            SizedBox(width: sw * 0.015),
            Text('No models added — tap "+ Model" to add one',
                style: TextStyle(
                    fontSize:   (sw * 0.031).clamp(10.5, 14.0),
                    color:      _kT4,
                    fontWeight: FontWeight.w500)),
          ]),
        )
      else
        ...brandDiscount.modelDiscounts.asMap().entries.map((e) {
          final mi     = e.key;
          final md     = e.value;
          final isLast =
              mi == brandDiscount.modelDiscounts.length - 1;
          return Column(children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.025),
              child: Row(children: [
                // Model icon
                Container(
                  width:  (sw * 0.065).clamp(22.0, 32.0),
                  height: (sw * 0.065).clamp(22.0, 32.0),
                  decoration: BoxDecoration(
                      color:        _kGreenBg,
                      borderRadius: BorderRadius.circular(
                          (sw * 0.018).clamp(5.0, 8.0)),
                      border: Border.all(color: _kGreenBd, width: 0.5)),
                  child: Icon(Icons.local_offer_outlined,
                      size:  (sw * 0.032).clamp(11.0, 14.0),
                      color: _kGreen),
                ),
                SizedBox(width: sw * 0.025),
                // Model info
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(md.modelName,
                            style: TextStyle(
                                fontSize:   (sw * 0.034).clamp(11.5, 15.0),
                                fontWeight: FontWeight.w700,
                                color:      _kT1)),
                        SizedBox(height: sw * 0.006),
                        Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: (sw * 0.02).clamp(6.0, 10.0),
                              vertical:   (sw * 0.006).clamp(2.0, 4.5)),
                          decoration: BoxDecoration(
                              color:        _kGreenBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _kGreenBd, width: 0.5)),
                          child: Text(
                              md.isPercentage
                                  ? '${md.discountValue}% off'
                                  : '₹${md.discountValue} off',
                              style: TextStyle(
                                  fontSize:   (sw * 0.026).clamp(9.0, 11.5),
                                  fontWeight: FontWeight.w700,
                                  color:      _kGreen)),
                        ),
                      ]),
                ),
                // Edit
                GestureDetector(
                  onTap: () => onEditModel(mi),
                  child: Container(
                    width:  (sw * 0.075).clamp(26.0, 36.0),
                    height: (sw * 0.075).clamp(26.0, 36.0),
                    decoration: BoxDecoration(
                        color:        _kPBg,
                        borderRadius: BorderRadius.circular(
                            (sw * 0.02).clamp(6.0, 10.0)),
                        border: Border.all(color: _kPBd, width: 0.5)),
                    child: Icon(Icons.edit_outlined,
                        size:  (sw * 0.036).clamp(12.0, 16.0),
                        color: _kP),
                  ),
                ),
                SizedBox(width: sw * 0.018),
                // Delete model
                GestureDetector(
                  onTap: () => onRemoveModel(mi),
                  child: Container(
                    width:  (sw * 0.075).clamp(26.0, 36.0),
                    height: (sw * 0.075).clamp(26.0, 36.0),
                    decoration: BoxDecoration(
                        color:        _kRedBg,
                        borderRadius: BorderRadius.circular(
                            (sw * 0.02).clamp(6.0, 10.0)),
                        border: Border.all(color: _kRedBd, width: 0.5)),
                    child: Icon(Icons.delete_outline_rounded,
                        size:  (sw * 0.036).clamp(12.0, 16.0),
                        color: _kRed),
                  ),
                ),
              ]),
            ),
            if (!isLast) Divider(height: 1, color: _kBd),
          ]);
        }),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// _ModelDiscountSheet
// ═════════════════════════════════════════════════════════════════════════════
class _ModelDiscountSheet extends StatefulWidget {
  const _ModelDiscountSheet({
    required this.brand,
    required this.existingModelDiscounts,
    required this.editIndex,
    required this.onSave,
    required this.fetchProducts,
  });

  final BrandModel               brand;
  final List<ModelDiscount>      existingModelDiscounts;
  final int?                     editIndex;
  final void Function(ModelDiscount) onSave;
  final Future<List<ProductModel>> Function(String) fetchProducts;

  @override
  State<_ModelDiscountSheet> createState() => _ModelDiscountSheetState();
}

class _ModelDiscountSheetState extends State<_ModelDiscountSheet> {
  final _discountCtrl = TextEditingController();
  String? _selectedModel;
  String? _selectedProductId;
  String? _selectedProductName;
  bool    _isPercentage    = true;
  List<ProductModel> _products = [];
  bool    _loadingProducts = false;

  @override
  void initState() {
    super.initState();
    if (widget.editIndex != null) {
      final ex            = widget.existingModelDiscounts[widget.editIndex!];
      _selectedModel      = ex.modelName;
      _selectedProductId  = ex.productId;
      _discountCtrl.text  = ex.discountValue.toString();
      _isPercentage       = ex.isPercentage;
      _loadProducts(ex.modelName);
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
          _products        = all.where((p) => p.model == model).toList();
          _loadingProducts = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingProducts = false);
    }
  }

  List<String> get _availableModels {
    final models = widget.brand.brandModels;
    return models.where((m) {
      final taken = widget.existingModelDiscounts.any((md) => md.modelName == m);
      if (widget.editIndex != null) {
        final current = widget.existingModelDiscounts[widget.editIndex!].modelName;
        return m == current || !taken;
      }
      return !taken;
    }).toList();
  }

  bool get _canSave =>
      _selectedModel != null &&
          _selectedProductId != null &&
          _discountCtrl.text.isNotEmpty &&
          (double.tryParse(_discountCtrl.text) ?? 0) > 0;

  void _showModelPicker(double sw) {
    final models = _availableModels;
    showModalBottomSheet(
      context:           context,
      isScrollControlled: true,
      backgroundColor:   _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => DraggableScrollableSheet(
        expand:           false,
        initialChildSize: 0.5,
        minChildSize:     0.3,
        maxChildSize:     0.85,
        builder: (_, sc) => Padding(
          padding: EdgeInsets.fromLTRB(
              sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              Text('Select Model',
                  style: TextStyle(
                      fontSize:   (sw * 0.045).clamp(15.0, 21.0),
                      fontWeight: FontWeight.w800,
                      color:      _kT1)),
              SizedBox(height: sw * 0.008),
              Text(widget.brand.brandName,
                  style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
              SizedBox(height: sw * 0.035),
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  itemCount:  models.length,
                  itemBuilder: (_, i) {
                    final m   = models[i];
                    final sel = _selectedModel == m;
                    return GestureDetector(
                      onTap: () async {
                        Navigator.pop(context);
                        setState(() {
                          _selectedModel       = m;
                          _selectedProductId   = null;
                          _selectedProductName = null;
                          _products            = [];
                        });
                        await _loadProducts(m);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin:   EdgeInsets.only(bottom: sw * 0.02),
                        padding:  EdgeInsets.symmetric(
                            horizontal: sw * 0.04, vertical: sw * 0.032),
                        decoration: BoxDecoration(
                            color:        sel ? _kPBg : _kBg,
                            borderRadius: BorderRadius.circular(
                                (sw * 0.028).clamp(8.0, 12.0)),
                            border: Border.all(
                                color: sel ? _kPBd : _kBd,
                                width: sel ? 1.0 : 0.5)),
                        child: Row(children: [
                          Expanded(
                            child: Text(m,
                                style: TextStyle(
                                    fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: sel ? _kP : _kT2)),
                          ),
                          if (sel)
                            Icon(Icons.check_circle_rounded,
                                color: _kP,
                                size: (sw * 0.045).clamp(15.0, 20.0)),
                        ]),
                      ),
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

  void _showProductPicker(double sw) {
    showModalBottomSheet(
      context:            context,
      isScrollControlled: true,
      backgroundColor:    _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => DraggableScrollableSheet(
        expand:           false,
        initialChildSize: 0.5,
        minChildSize:     0.3,
        maxChildSize:     0.85,
        builder: (_, sc) => Padding(
          padding: EdgeInsets.fromLTRB(
              sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _handle(),
              Text('Select Product',
                  style: TextStyle(
                      fontSize:   (sw * 0.045).clamp(15.0, 21.0),
                      fontWeight: FontWeight.w800,
                      color:      _kT1)),
              SizedBox(height: sw * 0.008),
              Text(_selectedModel ?? '',
                  style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
              SizedBox(height: sw * 0.035),
              Expanded(
                child: ListView.builder(
                  controller: sc,
                  itemCount:  _products.length,
                  itemBuilder: (_, i) {
                    final p   = _products[i];
                    final sel = _selectedProductId == p.productId;
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
                        margin:   EdgeInsets.only(bottom: sw * 0.02),
                        padding:  EdgeInsets.symmetric(
                            horizontal: sw * 0.04, vertical: sw * 0.032),
                        decoration: BoxDecoration(
                            color:        sel ? _kPBg : _kBg,
                            borderRadius: BorderRadius.circular(
                                (sw * 0.028).clamp(8.0, 12.0)),
                            border: Border.all(
                                color: sel ? _kPBd : _kBd,
                                width: sel ? 1.0 : 0.5)),
                        child: Row(children: [
                          Expanded(
                            child: Text(p.productName ?? '',
                                style: TextStyle(
                                    fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: sel ? _kP : _kT2)),
                          ),
                          if (sel)
                            Icon(Icons.check_circle_rounded,
                                color: _kP,
                                size: (sw * 0.045).clamp(15.0, 20.0)),
                        ]),
                      ),
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

  @override
  Widget build(BuildContext context) {
    final sw      = MediaQuery.sizeOf(context).width;
    final sh      = MediaQuery.sizeOf(context).height;
    final bottom  = MediaQuery.viewInsetsOf(context).bottom;

    return AnimatedPadding(
        duration: const Duration(milliseconds: 150),
        curve:    Curves.easeOut,
        padding:  EdgeInsets.only(bottom: bottom),
        child: ConstrainedBox(
          // Cap the sheet at 90% screen height so it never overflows
          constraints: BoxConstraints(maxHeight: sh * 0.90),
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            padding: EdgeInsets.fromLTRB(
                sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
            child: Column(
              mainAxisSize:       MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _handle(),
                Text(
                  widget.editIndex != null
                      ? 'Edit Model Discount'
                      : 'Add Model Discount',
                  style: TextStyle(
                      fontSize:   (sw * 0.045).clamp(15.0, 21.0),
                      fontWeight: FontWeight.w800,
                      color:      _kT1),
                ),
                SizedBox(height: sw * 0.005),
                Text(widget.brand.brandName,
                    style: TextStyle(
                        fontSize:   (sw * 0.03).clamp(10.0, 13.0),
                        color:      _kT4,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: sw * 0.05),

                // Model selector
                _FieldLabel(sw: sw, label: 'Model'),
                SizedBox(height: sh * 0.006),
                GestureDetector(
                  onTap: () => _showModelPicker(sw),
                  child: _PickerTile(
                      sw:          sw,
                      icon:        Icons.category_outlined,
                      value:       _selectedModel,
                      placeholder: 'Select model'),
                ),
                SizedBox(height: sh * 0.015),

                // Product selector
                if (_selectedModel != null) ...[
                  _FieldLabel(sw: sw, label: 'Product'),
                  SizedBox(height: sh * 0.006),
                  if (_loadingProducts)
                    Container(
                      height: sh * 0.065,
                      decoration: BoxDecoration(
                          color:        _kBg,
                          borderRadius: BorderRadius.circular(
                              (sw * 0.028).clamp(8.0, 12.0)),
                          border: Border.all(color: _kBd, width: 0.5)),
                      child: const Center(
                        child: SizedBox(
                          width: 18, height: 18,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: _kP),
                        ),
                      ),
                    )
                  else if (_products.isEmpty)
                    Container(
                      padding: EdgeInsets.all(sw * 0.04),
                      decoration: BoxDecoration(
                          color:        _kAmberBg,
                          borderRadius: BorderRadius.circular(
                              (sw * 0.028).clamp(8.0, 12.0)),
                          border: Border.all(color: _kAmberBd, width: 0.5)),
                      child: Row(children: [
                        Icon(Icons.info_outline_rounded,
                            size:  (sw * 0.04).clamp(14.0, 18.0),
                            color: _kAmber),
                        SizedBox(width: sw * 0.02),
                        Text('No products for $_selectedModel',
                            style: TextStyle(
                                fontSize:   (sw * 0.032).clamp(11.0, 14.0),
                                color:      _kAmber,
                                fontWeight: FontWeight.w500)),
                      ]),
                    )
                  else
                    GestureDetector(
                      onTap: () => _showProductPicker(sw),
                      child: _PickerTile(
                          sw:          sw,
                          icon:        Icons.inventory_2_outlined,
                          value:       _selectedProductName,
                          placeholder: 'Select product'),
                    ),
                  SizedBox(height: sh * 0.015),
                ],

                // Discount value
                _FieldLabel(sw: sw, label: 'Discount Value'),
                SizedBox(height: sh * 0.006),
                TextField(
                  controller:  _discountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  onChanged:   (_) => setState(() {}),
                  style: TextStyle(
                      fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                      color:      _kT1,
                      fontWeight: FontWeight.w500),
                  decoration: _inputDeco(sw,
                      _isPercentage ? 'e.g. 10' : 'e.g. 500',
                      prefix: Icon(Icons.discount_outlined,
                          color: _kT4,
                          size: (sw * 0.045).clamp(15.0, 20.0))),
                ),
                SizedBox(height: sh * 0.015),

                // Percentage toggle
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.04, vertical: sw * 0.025),
                  decoration: BoxDecoration(
                      color:        _kBg,
                      borderRadius: BorderRadius.circular(
                          (sw * 0.028).clamp(8.0, 12.0)),
                      border: Border.all(color: _kBd, width: 0.5)),
                  child: Row(children: [
                    Container(
                      padding: EdgeInsets.all(
                          (sw * 0.018).clamp(5.0, 8.0)),
                      decoration: BoxDecoration(
                          color:        _isPercentage ? _kGreenBg : _kPBg,
                          borderRadius: BorderRadius.circular(
                              (sw * 0.018).clamp(5.0, 8.0))),
                      child: Icon(
                          _isPercentage
                              ? Icons.percent_rounded
                              : Icons.currency_rupee_rounded,
                          size:  (sw * 0.038).clamp(13.0, 17.0),
                          color: _isPercentage ? _kGreen : _kP),
                    ),
                    SizedBox(width: sw * 0.025),
                    Expanded(
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Discount Type',
                                style: TextStyle(
                                    fontSize:   (sw * 0.032).clamp(11.0, 14.0),
                                    fontWeight: FontWeight.w700,
                                    color:      _kT1)),
                            Text(
                                _isPercentage
                                    ? 'Percentage (%)'
                                    : 'Fixed amount (₹)',
                                style: TextStyle(
                                    fontSize: (sw * 0.028).clamp(9.5, 12.5),
                                    color:    _kT4)),
                          ]),
                    ),
                    Switch(
                      value:            _isPercentage,
                      onChanged:        (v) => setState(() => _isPercentage = v),
                      activeThumbColor: _kGreen,
                      activeTrackColor: _kGreenBd,
                      inactiveThumbColor: _kP,
                      inactiveTrackColor: _kPBd,
                    ),
                  ]),
                ),

                SizedBox(height: sh * 0.025),

                // Action buttons
                Row(children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: sh * 0.016),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          side: const BorderSide(color: _kBd, width: 0.5)),
                      child: Text('Cancel',
                          style: TextStyle(
                              fontSize:   (sw * 0.036).clamp(12.0, 15.0),
                              fontWeight: FontWeight.w700,
                              color:      _kT4)),
                    ),
                  ),
                  SizedBox(width: sw * 0.03),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _canSave
                          ? () {
                        widget.onSave(ModelDiscount(
                          modelName:     _selectedModel!,
                          discountValue:
                          double.parse(_discountCtrl.text),
                          isPercentage:  _isPercentage,
                          productId:     _selectedProductId!,
                        ));
                        Navigator.pop(context);
                      }
                          : null,
                      style: ElevatedButton.styleFrom(
                          backgroundColor:         _kP,
                          foregroundColor:         _kWhite,
                          disabledBackgroundColor: _kBd,
                          padding: EdgeInsets.symmetric(
                              vertical: sh * 0.016),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                          elevation: 0),
                      child: Text(
                          widget.editIndex != null ? 'Update' : 'Add',
                          style: TextStyle(
                              fontSize:   (sw * 0.036).clamp(12.0, 15.0),
                              fontWeight: FontWeight.w700)),
                    ),
                  ),
                ]),
              ],
            ),
          ),
        ));
    }
}

// ═════════════════════════════════════════════════════════════════════════════
// _Sec — section card matching AddDealerScreen/_ProductDetailsScreen pattern
// ═════════════════════════════════════════════════════════════════════════════
class _Sec extends StatelessWidget {
  const _Sec({
    required this.sw,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.child,
  });
  final double   sw;
  final IconData icon;
  final Color    iconBg, iconColor;
  final String   title;
  final Widget   child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color:        _kWhite,
        borderRadius: BorderRadius.circular(
            (sw * 0.04).clamp(10.0, 18.0)),
        border: Border.all(color: _kBd, width: 0.5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.035),
          child: Row(children: [
            Container(
              width:  (sw * 0.075).clamp(26.0, 36.0),
              height: (sw * 0.075).clamp(26.0, 36.0),
              decoration: BoxDecoration(
                  color:        iconBg,
                  borderRadius: BorderRadius.circular(
                      (sw * 0.022).clamp(6.0, 10.0))),
              child: Icon(icon,
                  size:  (sw * 0.04).clamp(14.0, 20.0),
                  color: iconColor),
            ),
            SizedBox(width: sw * 0.025),
            Text(title,
                style: TextStyle(
                    fontSize:   (sw * 0.035).clamp(12.0, 16.0),
                    fontWeight: FontWeight.w700,
                    color:      _kT1)),
          ]),
        ),
        Divider(height: 1, color: _kBd),
        Padding(
            padding: EdgeInsets.all(sw * 0.04), child: child),
      ],
    ),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// Small reusable widgets
// ═════════════════════════════════════════════════════════════════════════════
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.sw, required this.label});
  final double sw;
  final String label;
  @override
  Widget build(BuildContext context) => Text(label.toUpperCase(),
      style: TextStyle(
          fontSize:   (sw * 0.028).clamp(9.5, 12.5),
          fontWeight: FontWeight.w700,
          color:      _kT4,
          letterSpacing: 0.5));
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.sw,
    required this.icon,
    required this.value,
    required this.placeholder,
  });
  final double   sw;
  final IconData icon;
  final String?  value;
  final String   placeholder;

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: sw * 0.035),
      decoration: BoxDecoration(
          color:        _kBg,
          borderRadius: BorderRadius.circular(
              (sw * 0.028).clamp(8.0, 12.0)),
          border: Border.all(
              color: selected ? _kPBd : _kBd,
              width: selected ? 1.0 : 0.5)),
      child: Row(children: [
        Icon(icon,
            size:  (sw * 0.045).clamp(15.0, 20.0),
            color: selected ? _kP : _kT4),
        SizedBox(width: sw * 0.025),
        Expanded(
          child: Text(value ?? placeholder,
              style: TextStyle(
                  fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                  color:      selected ? _kT1 : _kT4)),
        ),
        Icon(Icons.keyboard_arrow_down_rounded,
            color: _kT4, size: (sw * 0.05).clamp(16.0, 22.0)),
      ]),
    );
  }
}

// ── Data models ───────────────────────────────────────────────────────────────
class BrandDiscount {
  final BrandModel          brand;
  final List<ModelDiscount> modelDiscounts;
  BrandDiscount({required this.brand, required this.modelDiscounts});
}

class ModelDiscount {
  final String modelName;
  final double discountValue;
  final bool   isPercentage;
  final String productId;
  ModelDiscount({
    required this.modelName,
    required this.discountValue,
    required this.isPercentage,
    required this.productId,
  });
}