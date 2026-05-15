import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/brand_model.dart';
import '../../../model/product_model.dart';
import '../../../widgets/circle_button.dart';
import '../../brand/controller/brand_controller.dart';
import '../controller/product_controller.dart';

// ── Zoho Books design tokens (mirrored from ProductDetailsScreen) ─────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Colors.white;
const _kBd       = Color(0xFFE5E7EB);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
const _kT3       = Color(0xFF6B7280);
const _kT4       = Color(0xFF9CA3AF);
const _kGreen    = Color(0xFF0F6E56);
const _kGreenBg  = Color(0xFFEDFAF5);
const _kGreenBd  = Color(0xFF9FE0C5);
const _kRed      = Color(0xFFDC2626);
const _kAmber    = Color(0xFFB45309);
const _kAmberBg  = Color(0xFFFFFBEB);
const _kPurple   = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);

// ─────────────────────────────────────────────────────────────────────────────
class ProductCreateScreen extends ConsumerStatefulWidget {
  const ProductCreateScreen({super.key});

  @override
  ConsumerState<ProductCreateScreen> createState() =>
      _ProductCreateScreenState();
}

class _ProductCreateScreenState extends ConsumerState<ProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _controllers;

  String? selectedBrand;
  String? selectedModel;
  bool _isSubmitting = false;

  // Track whether selectors have been tapped for inline error display
  bool _brandTouched = false;
  bool _modelTouched = false;
  String _selectedCategory = 'INVERTER';
  @override
  void initState() {
    super.initState();
    _controllers = {
      'name':          TextEditingController(),
      'type':          TextEditingController(),
      'price':         TextEditingController(),
      'cost':          TextEditingController(),
      'packedStock':   TextEditingController(),
      'unpackedStock': TextEditingController(),
      'packedNotes':   TextEditingController(),
      'unpackedNotes': TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── SUBMIT ────────────────────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    setState(() {
      _brandTouched = true;
      _modelTouched = true;
    });

    final formValid = _formKey.currentState!.validate();
    if (!formValid || selectedBrand == null || selectedModel == null) {
      _snack('Please fill all required fields', _kRed);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final price = double.parse(_controllers['price']!.text.trim());
      final cost  = double.tryParse(_controllers['cost']!.text.trim())??0.00;
      final product = ProductModel(
        brand:       selectedBrand,
        model:       selectedModel,
        productName: _controllers['name']!.text.trim(),
        productType: _controllers['type']!.text.trim(),
        price:       price,
        cost: cost,
        productCategory: _selectedCategory,
        stocks: [
          Stocks(
            type:       'ADD',
            stockType:  'PACKED',
            stock:      int.tryParse(_controllers['packedStock']!.text) ?? 0,
            stockNotes: _controllers['packedNotes']!.text,
          ),
          if (_selectedCategory == 'INVERTER')
            Stocks(
              type:       'ADD',
              stockType:  'UNPACKED',
              stock:      int.tryParse(_controllers['unpackedStock']!.text) ?? 0,
              stockNotes: _controllers['unpackedNotes']!.text,
            ),
        ],
      );

      await ref.read(productControllerProvider.notifier).createProduct(product);

      if (!mounted) return;
      _snack('Product created successfully', _kGreen);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) _snack('Error: ${e.toString()}', _kRed);
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─── BRAND BOTTOM SHEET ────────────────────────────────────────────────────
  void _showBrandSheet(double sw, List<BrandModel> brands) {
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular((sw * 0.05).clamp(14.0, 22.0))),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtered = brands
              .where((b) =>
              b.brandName.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            builder: (_, sc) => Padding(
              padding: EdgeInsets.fromLTRB(
                  sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Handle(),
                  Text('Select Brand',
                      style: TextStyle(
                          fontSize:   (sw * 0.045).clamp(15.0, 21.0),
                          fontWeight: FontWeight.w800,
                          color:      _kT1)),
                  SizedBox(height: sw * 0.008),
                  Text('Choose a brand for this product',
                      style: TextStyle(
                          fontSize: (sw * 0.03).clamp(10.0, 13.0),
                          color:    _kT4)),
                  SizedBox(height: sw * 0.04),
                  TextField(
                    onChanged: (v) => setS(() => query = v),
                    style: TextStyle(
                        fontSize:   (sw * 0.034).clamp(11.5, 15.0),
                        color:      _kT1,
                        fontWeight: FontWeight.w500),
                    decoration:
                    _sheetInputDeco(sw, 'Search brand…', Icons.search_rounded),
                  ),
                  SizedBox(height: sw * 0.03),
                  Expanded(
                    child: ListView.builder(
                      controller: sc,
                      itemCount:  filtered.length,
                      itemBuilder: (_, i) {
                        final b   = filtered[i];
                        final sel = selectedBrand == b.brandName;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedBrand = b.brandName;
                              selectedModel = null;
                              _brandTouched = true;
                            });
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin:   EdgeInsets.only(bottom: sw * 0.02),
                            padding:  EdgeInsets.symmetric(
                                horizontal: sw * 0.04, vertical: sw * 0.032),
                            decoration: BoxDecoration(
                              color: sel ? _kPBg : _kBg,
                              borderRadius: BorderRadius.circular(
                                  (sw * 0.028).clamp(8.0, 12.0)),
                              border: Border.all(
                                  color: sel ? _kPBd : _kBd, width: 0.5),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Text(b.brandName,
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
          );
        },
      ),
    );
  }

  // ─── MODEL BOTTOM SHEET ────────────────────────────────────────────────────
  void _showModelSheet(double sw, List<String> models) {
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
            top: Radius.circular((sw * 0.05).clamp(14.0, 22.0))),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtered = models
              .where((m) => m.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            builder: (_, sc) => Padding(
              padding: EdgeInsets.fromLTRB(
                  sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Handle(),
                  Text('Select Model',
                      style: TextStyle(
                          fontSize:   (sw * 0.045).clamp(15.0, 21.0),
                          fontWeight: FontWeight.w800,
                          color:      _kT1)),
                  SizedBox(height: sw * 0.008),
                  Text('Choose a model for $selectedBrand',
                      style: TextStyle(
                          fontSize: (sw * 0.03).clamp(10.0, 13.0),
                          color:    _kT4)),
                  SizedBox(height: sw * 0.04),
                  TextField(
                    onChanged: (v) => setS(() => query = v),
                    style: TextStyle(
                        fontSize:   (sw * 0.034).clamp(11.5, 15.0),
                        color:      _kT1,
                        fontWeight: FontWeight.w500),
                    decoration:
                    _sheetInputDeco(sw, 'Search model…', Icons.search_rounded),
                  ),
                  SizedBox(height: sw * 0.03),
                  Expanded(
                    child: ListView.builder(
                      controller: sc,
                      itemCount:  filtered.length,
                      itemBuilder: (_, i) {
                        final m   = filtered[i];
                        final sel = selectedModel == m;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedModel = m;
                              _modelTouched = true;
                            });
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin:   EdgeInsets.only(bottom: sw * 0.02),
                            padding:  EdgeInsets.symmetric(
                                horizontal: sw * 0.04, vertical: sw * 0.032),
                            decoration: BoxDecoration(
                              color: sel ? _kPBg : _kBg,
                              borderRadius: BorderRadius.circular(
                                  (sw * 0.028).clamp(8.0, 12.0)),
                              border: Border.all(
                                  color: sel ? _kPBd : _kBd, width: 0.5),
                            ),
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
          );
        },
      ),
    );
  }

  // ─── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw         = Screen.w(context);
    final sh         = Screen.h(context);
    final brandState = ref.watch(activeBrandControllerProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: brandState.when(
          loading: () => _buildLoading(context, sw, sh),
          error:   (_, __) => _buildError(context, sw, sh),
          data:    (brands) => Column(children: [

            // ── App Bar ─────────────────────────────────────────────────
            Container(
              color:   _kWhite,
              padding: EdgeInsets.fromLTRB(
                  sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
              child: Row(children: [
                CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context)),
                const Spacer(),
                Text('Create Product',
                    style: TextStyle(
                        fontSize:   (sw * 0.042).clamp(14.0, 20.0),
                        fontWeight: FontWeight.w700,
                        color:      _kT1,
                        letterSpacing: -0.2)),
                const Spacer(),
                SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
              ]),
            ),

            // ── Form Body ───────────────────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.04),
                  child: Column(children: [

                    // ── Brand & Model ──────────────────────────────────
                    _CreateSection(
                      sw:         sw,
                      icon:       Icons.category_outlined,
                      iconBg:     _kPurpleBg,
                      iconColor:  _kPurple,
                      title:      'Brand & Model',
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _SectionLabel(sw: sw, text: 'Brand'),
                          SizedBox(height: sh * 0.006),
                          _SelectorTile(
                            sw:          sw,
                            icon:        Icons.local_offer_outlined,
                            value:       selectedBrand,
                            placeholder: 'Select brand',
                            hasError:    _brandTouched && selectedBrand == null,
                            onTap:       () => _showBrandSheet(sw, brands),
                          ),
                          if (_brandTouched && selectedBrand == null)
                            _InlineError(sw: sw, message: 'Brand is required'),
                          SizedBox(height: sh * 0.015),

                          _SectionLabel(sw: sw, text: 'Model'),
                          SizedBox(height: sh * 0.006),
                          Opacity(
                            opacity: selectedBrand == null ? 0.5 : 1.0,
                            child: _SelectorTile(
                              sw:          sw,
                              icon:        Icons.devices_other_outlined,
                              value:       selectedModel,
                              placeholder: 'Select model',
                              hasError:    _modelTouched && selectedModel == null,
                              onTap: selectedBrand == null
                                  ? null
                                  : () {
                                final brand = brands.firstWhere(
                                        (b) => b.brandName == selectedBrand);
                                _showModelSheet(sw, brand.brandModels);
                              },
                            ),
                          ),
                          if (_modelTouched && selectedModel == null)
                            _InlineError(sw: sw, message: 'Model is required'),
                        ],
                      ),
                    ),
                    SizedBox(height: sh * 0.012),

                    // ── Product Info ───────────────────────────────────
// ── Product Info ───────────────────────────────────────────────────
                    _CreateSection(
                      sw:        sw,
                      icon:      Icons.inventory_2_outlined,
                      iconBg:    _kPurpleBg,
                      iconColor: _kPurple,
                      title:     'Product Info',
                      child: Column(children: [
                        _LabelledField(
                          sw:         sw, sh: sh,
                          label:      'Product Name',
                          hint:       'Enter product name',
                          controller: _controllers['name']!,
                          icon:       Icons.label_outline_rounded,
                          validator:  (v) =>
                          (v == null || v.trim().isEmpty) ? 'Product name is required' : null,
                        ),
                        SizedBox(height: sh * 0.015),
                        _LabelledField(
                          sw:         sw, sh: sh,
                          label:      'Product Type',
                          hint:       'e.g. C10 Battery, Solar Inverter',
                          controller: _controllers['type']!,
                          icon:       Icons.category_outlined,
                          validator:  (v) =>
                          (v == null || v.trim().isEmpty) ? 'Product type is required' : null,
                        ),
                        SizedBox(height: sh * 0.015),

                        // ── Category ────────────────────────────────────────────────
                        _SectionLabel(sw: sw, text: 'Category'),
                        SizedBox(height: sh * 0.008),
                        Row(children: [
                          Expanded(child: _CategoryRadioTile(
                            sw:       sw,
                            label:    'INVERTER',
                            icon:     Icons.bolt_rounded,
                            color:    _kP,
                            bg:       _kPBg,
                            bd:       _kPBd,
                            selected: _selectedCategory == 'INVERTER',
                            onTap:    () => setState(() => _selectedCategory = 'INVERTER'),
                          )),
                          SizedBox(width: sw * 0.03),
                          Expanded(child: _CategoryRadioTile(
                            sw:       sw,
                            label:    'BATTERY',
                            icon:     Icons.battery_charging_full_rounded,
                            color:    _kGreen,
                            bg:       _kGreenBg,
                            bd:       _kGreenBd,
                            selected: _selectedCategory == 'BATTERY',
                            onTap:    () => setState(() => _selectedCategory = 'BATTERY'),
                          )),
                        ]),
                      ]),
                    ),
                    SizedBox(height: sh * 0.012),

                    // ── Pricing ────────────────────────────────────────
                    // ── Pricing ────────────────────────────────────────────────────────
                    _CreateSection(
                      sw:        sw,
                      icon:      Icons.payments_outlined,
                      iconBg:    _kGreenBg,
                      iconColor: _kGreen,
                      title:     'Pricing',
                      child: Column(children: [
                        _LabelledField(
                          sw:         sw, sh: sh,
                          label:      'Price (₹)',
                          hint:       'Enter selling price',
                          controller: _controllers['price']!,
                          icon:       Icons.currency_rupee,
                          keyboard:   const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return 'Price is required';
                            final val = double.tryParse(v.trim());
                            if (val == null) return 'Enter a valid number';
                            if (val < 0) return 'Price cannot be negative';
                            return null;
                          },
                        ),
                        SizedBox(height: sh * 0.015),
                        _LabelledField(
                          sw:         sw, sh: sh,
                          label:      'Cost (₹)',
                          hint:       'Enter cost price',
                          controller: _controllers['cost']!,
                          icon:       Icons.price_change_outlined,
                          keyboard:   const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) return null; // optional
                            final val = double.tryParse(v.trim());
                            if (val == null) return 'Enter a valid number';
                            if (val < 0) return 'Cost cannot be negative';
                            return null;
                          },
                        ),
                      ]),
                    ),
                    SizedBox(height: sh * 0.012),

                    // ── Stock ──────────────────────────────────────────────────────────
                    _CreateSection(
                      sw:        sw,
                      icon:      Icons.inventory_outlined,
                      iconBg:    _kAmberBg,
                      iconColor: _kAmber,
                      title:     'Stock',
                      child: Column(children: [
                        // BATTERY → packed only | INVERTER → both
                        _selectedCategory == 'BATTERY'
                            ? _StockInputTile(
                          sw:         sw,
                          label:      'Packed',
                          icon:       Icons.check_box_outlined,
                          color:      _kP,
                          controller: _controllers['packedStock']!,
                        )
                            : Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _StockInputTile(
                              sw:         sw,
                              label:      'Packed',
                              icon:       Icons.check_box_outlined,
                              color:      _kP,
                              controller: _controllers['packedStock']!,
                            )),
                            SizedBox(width: sw * 0.03),
                            Expanded(child: _StockInputTile(
                              sw:         sw,
                              label:      'Unpacked',
                              icon:       Icons.indeterminate_check_box_outlined,
                              color:      _kAmber,
                              controller: _controllers['unpackedStock']!,
                            )),
                          ],
                        ),
                        SizedBox(height: sh * 0.015),
                        _LabelledField(
                          sw:         sw, sh: sh,
                          label:      'Packed Notes',
                          hint:       'Notes for packed stock (optional)',
                          controller: _controllers['packedNotes']!,
                          icon:       Icons.note_outlined,
                          maxLines:   3,
                        ),
                        if (_selectedCategory == 'INVERTER') ...[
                          SizedBox(height: sh * 0.015),
                          _LabelledField(
                            sw:         sw, sh: sh,
                            label:      'Unpacked Notes',
                            hint:       'Notes for unpacked stock (optional)',
                            controller: _controllers['unpackedNotes']!,
                            icon:       Icons.note_alt_outlined,
                            maxLines:   3,
                          ),
                        ],
                      ]),
                    ),
                    SizedBox(height: sh * 0.025),

                    // ── Submit ─────────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isSubmitting ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kP,
                          foregroundColor: _kWhite,
                          padding: EdgeInsets.symmetric(vertical: sh * 0.018),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                  (sw * 0.035).clamp(10.0, 16.0))),
                          elevation: 0,
                        ),
                        child: _isSubmitting
                            ? SizedBox(
                            width:  (sw * 0.05).clamp(16.0, 22.0),
                            height: (sw * 0.05).clamp(16.0, 22.0),
                            child: const CircularProgressIndicator(
                                color: _kWhite, strokeWidth: 2.5))
                            : Text('Create Product',
                            style: TextStyle(
                                fontSize:   (sw * 0.04).clamp(14.0, 17.0),
                                fontWeight: FontWeight.w700)),
                      ),
                    ),
                  ]),
                ),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  // ─── LOADING / ERROR ────────────────────────────────────────────────────────
  Widget _buildLoading(BuildContext context, double sw, double sh) =>
      Column(children: [
        _appBar(context, sw, sh),
        const Expanded(
            child: Center(
                child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5))),
      ]);

  Widget _buildError(BuildContext context, double sw, double sh) =>
      Column(children: [
        _appBar(context, sw, sh),
        Expanded(
          child: Center(
            child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
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
                onPressed: () => ref.invalidate(activeBrandControllerProvider),
                style: ElevatedButton.styleFrom(
                    backgroundColor: _kP,
                    foregroundColor: _kWhite,
                    shape:   const CircleBorder(),
                    padding: const EdgeInsets.all(14),
                    elevation: 0),
                child: const Icon(Icons.refresh_rounded),
              ),
            ]),
          ),
        ),
      ]);

  Widget _appBar(BuildContext context, double sw, double sh) => Container(
    color:   _kWhite,
    padding: EdgeInsets.fromLTRB(
        sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
    child: Row(children: [
      CircularIconButton(
          icon: Icons.arrow_back_ios_rounded,
          onTap: () => Navigator.pop(context)),
      const Spacer(),
      Text('Create Product',
          style: TextStyle(
              fontSize:   (sw * 0.042).clamp(14.0, 20.0),
              fontWeight: FontWeight.w700,
              color:      _kT1,
              letterSpacing: -0.2)),
      const Spacer(),
      SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
    ]),
  );
}
// ═════════════════════════════════════════════════════════════════════════════
// _CategoryRadioTile
// ═════════════════════════════════════════════════════════════════════════════
class _CategoryRadioTile extends StatelessWidget {
  const _CategoryRadioTile({
    required this.sw,
    required this.label,
    required this.icon,
    required this.color,
    required this.bg,
    required this.bd,
    required this.selected,
    required this.onTap,
  });
  final double   sw;
  final String   label;
  final IconData icon;
  final Color    color, bg, bd;
  final bool     selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.035, vertical: sw * 0.03),
      decoration: BoxDecoration(
        color: selected ? bg : _kBg,
        borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
        border: Border.all(
            color: selected ? color.withValues(alpha: 0.5) : _kBd,
            width: selected ? 1.5 : 0.5),
      ),
      child: Row(children: [
        Container(
          width:  (sw * 0.07).clamp(24.0, 34.0),
          height: (sw * 0.07).clamp(24.0, 34.0),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.15) : _kWhite,
            borderRadius: BorderRadius.circular((sw * 0.018).clamp(5.0, 8.0)),
            border: Border.all(
                color: selected ? color.withValues(alpha: 0.3) : _kBd,
                width: 0.5),
          ),
          child: Icon(icon,
              size:  (sw * 0.038).clamp(13.0, 18.0),
              color: selected ? color : _kT4),
        ),
        SizedBox(width: sw * 0.02),
        Expanded(child: Text(label,
            style: TextStyle(
                fontSize:   (sw * 0.03).clamp(10.5, 13.5),
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color:      selected ? color : _kT3))),
        Container(
          width:  (sw * 0.038).clamp(13.0, 18.0),
          height: (sw * 0.038).clamp(13.0, 18.0),
          decoration: BoxDecoration(
            color:  selected ? color : _kWhite,
            shape:  BoxShape.circle,
            border: Border.all(
                color: selected ? color : _kBd, width: 1.5),
          ),
          child: selected
              ? Icon(Icons.check_rounded,
              size:  (sw * 0.024).clamp(8.0, 11.0),
              color: _kWhite)
              : null,
        ),
      ]),
    ),
  );
}
// ═════════════════════════════════════════════════════════════════════════════
// Shared utilities
// ═════════════════════════════════════════════════════════════════════════════

class _Handle extends StatelessWidget {
  const _Handle();
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36, height: 4,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
          color: _kBd, borderRadius: BorderRadius.circular(2)),
    ),
  );
}

InputDecoration _sheetInputDeco(double sw, String hint, IconData icon,
    {int maxLines = 1}) {
  final r = (sw * 0.028).clamp(8.0, 12.0);
  return InputDecoration(
    hintText:   hint,
    hintStyle:  TextStyle(
        fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT4),
    prefixIcon: Icon(icon, color: _kT4, size: (sw * 0.045).clamp(15.0, 20.0)),
    filled:     true,
    fillColor:  _kBg,
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
        borderSide:   const BorderSide(color: _kP, width: 1.5)),
    errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide:   const BorderSide(color: _kRed)),
    focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(r),
        borderSide:   const BorderSide(color: _kRed, width: 1.5)),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// _CreateSection — mirrors _Section from ProductDetailsScreen
// ═════════════════════════════════════════════════════════════════════════════
class _CreateSection extends StatelessWidget {
  const _CreateSection({
    required this.sw,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.title,
    required this.child,
  });
  final double  sw;
  final IconData icon;
  final Color   iconBg, iconColor;
  final String  title;
  final Widget  child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color:        _kWhite,
        borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
        border:       Border.all(color: _kBd, width: 0.5)),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
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
      Padding(padding: EdgeInsets.all(sw * 0.04), child: child),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// _SectionLabel
// ═════════════════════════════════════════════════════════════════════════════
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.sw, required this.text});
  final double sw;
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
        fontSize:   (sw * 0.028).clamp(9.5, 12.5),
        fontWeight: FontWeight.w700,
        color:      _kT4,
        letterSpacing: 0.5),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// _InlineError
// ═════════════════════════════════════════════════════════════════════════════
class _InlineError extends StatelessWidget {
  const _InlineError({required this.sw, required this.message});
  final double sw;
  final String message;
  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(top: sw * 0.012, left: sw * 0.02),
    child: Row(children: [
      Icon(Icons.error_outline_rounded,
          size:  (sw * 0.032).clamp(11.0, 14.0), color: _kRed),
      SizedBox(width: sw * 0.012),
      Text(message,
          style: TextStyle(
              fontSize:   (sw * 0.028).clamp(9.5, 12.0),
              color:      _kRed,
              fontWeight: FontWeight.w500)),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// _SelectorTile — styled dropdown trigger
// ═════════════════════════════════════════════════════════════════════════════
class _SelectorTile extends StatelessWidget {
  const _SelectorTile({
    required this.sw,
    required this.icon,
    required this.value,
    required this.placeholder,
    required this.hasError,
    this.onTap,
  });
  final double       sw;
  final IconData     icon;
  final String?      value;
  final String       placeholder;
  final bool         hasError;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final selected = value != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: sw * 0.04, vertical: sw * 0.035),
        decoration: BoxDecoration(
          color: _kBg,
          borderRadius:
          BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
          border: Border.all(
              color: hasError ? _kRed : (selected ? _kPBd : _kBd),
              width: hasError || selected ? 1.0 : 0.5),
        ),
        child: Row(children: [
          Icon(icon,
              size:  (sw * 0.045).clamp(15.0, 20.0),
              color: hasError ? _kRed : (selected ? _kP : _kT4)),
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
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _StockInputTile — coloured tile with inline number input
//
// Validation rules:
//   ✅  Zero (0) is allowed — user can add 0 stock on create
//   ❌  Negative values are blocked by inputFormatters + validator
//   ✅  Empty field defaults to 0 on submit (handled in _handleSubmit)
// ═════════════════════════════════════════════════════════════════════════════
class _StockInputTile extends StatelessWidget {
  const _StockInputTile({
    required this.sw,
    required this.label,
    required this.icon,
    required this.color,
    required this.controller,
  });
  final double              sw;
  final String              label;
  final IconData            icon;
  final Color               color;
  final TextEditingController controller;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.all(sw * 0.03),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.06),
      borderRadius:
      BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
      border:
      Border.all(color: color.withValues(alpha: 0.15), width: 0.5),
    ),
    child: Column(children: [
      Icon(icon, color: color, size: (sw * 0.05).clamp(16.0, 22.0)),
      SizedBox(height: sw * 0.01),
      Text(label,
          style: TextStyle(
              fontSize:   (sw * 0.026).clamp(9.0, 11.5),
              color:      _kT4,
              fontWeight: FontWeight.w500)),
      SizedBox(height: sw * 0.012),
      TextFormField(
        controller:   controller,
        keyboardType: TextInputType.number,
        textAlign:    TextAlign.center,
        style: TextStyle(
            fontSize:   (sw * 0.038).clamp(13.0, 17.0),
            fontWeight: FontWeight.w800,
            color:      color),
        // digits-only input formatter prevents any negative sign from
        // being typed — a second line of defence on top of the validator
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        autovalidateMode: AutovalidateMode.onUserInteraction,
        validator: (v) {
          if (v == null || v.trim().isEmpty) return null; // empty = 0, OK
          final val = int.tryParse(v.trim());
          if (val == null) return 'Invalid';
          if (val < 0) return 'Cannot be negative'; // unreachable via UI, safety net
          return null; // 0 is explicitly allowed
        },
        decoration: InputDecoration(
          hintText:  '0',
          hintStyle: TextStyle(
              fontSize:   (sw * 0.038).clamp(13.0, 17.0),
              fontWeight: FontWeight.w800,
              color:      color.withValues(alpha: 0.3)),
          filled:     true,
          fillColor:  _kWhite,
          contentPadding:
          EdgeInsets.symmetric(vertical: sw * 0.02),
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  (sw * 0.022).clamp(6.0, 10.0)),
              borderSide:
              BorderSide(color: color.withValues(alpha: 0.2), width: 0.5)),
          enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  (sw * 0.022).clamp(6.0, 10.0)),
              borderSide:
              BorderSide(color: color.withValues(alpha: 0.2), width: 0.5)),
          focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  (sw * 0.022).clamp(6.0, 10.0)),
              borderSide: BorderSide(color: color, width: 1.5)),
          errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  (sw * 0.022).clamp(6.0, 10.0)),
              borderSide: const BorderSide(color: _kRed)),
          focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(
                  (sw * 0.022).clamp(6.0, 10.0)),
              borderSide: const BorderSide(color: _kRed, width: 1.5)),
        ),
      ),
    ]),
  );
}

// ═════════════════════════════════════════════════════════════════════════════
// _LabelledField — standard labelled text field
// ═════════════════════════════════════════════════════════════════════════════
class _LabelledField extends StatelessWidget {
  const _LabelledField({
    required this.sw,
    required this.sh,
    required this.label,
    required this.hint,
    required this.controller,
    required this.icon,
    this.keyboard        = TextInputType.text,
    this.inputFormatters,
    this.maxLines        = 1,
    this.validator,
  });

  final double              sw, sh;
  final String              label, hint;
  final TextEditingController controller;
  final IconData            icon;
  final TextInputType       keyboard;
  final List<TextInputFormatter>? inputFormatters;
  final int                 maxLines;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _SectionLabel(sw: sw, text: label),
      SizedBox(height: sh * 0.006),
      TextFormField(
        controller:       controller,
        keyboardType:     keyboard,
        maxLines:         maxLines,
        inputFormatters:  inputFormatters,
        validator:        validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        style: TextStyle(
            fontSize:   (sw * 0.036).clamp(12.0, 16.0),
            color:      _kT1,
            fontWeight: FontWeight.w500),
        decoration:
        _sheetInputDeco(sw, hint, icon, maxLines: maxLines),
      ),
    ],
  );
}