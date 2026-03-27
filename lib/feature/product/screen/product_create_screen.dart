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

// ─── THEME (consistent with dealer) ─────────────────────────────
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

// ─── SCREEN ─────────────────────────────────────────────────────
class ProductCreateScreen extends ConsumerStatefulWidget {
  const ProductCreateScreen({super.key});

  @override
  ConsumerState<ProductCreateScreen> createState() => _ProductCreateScreenState();
}

class _ProductCreateScreenState extends ConsumerState<ProductCreateScreen> {
  final _formKey = GlobalKey<FormState>();

  late final Map<String, TextEditingController> _controllers;

  String? selectedBrand;
  String? selectedModel;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _controllers = {
      'name': TextEditingController(),
      'type': TextEditingController(),
      'price': TextEditingController(),
      'packedStock': TextEditingController(),
      'unpackedStock': TextEditingController(),
      'packedNotes': TextEditingController(),
      'unpackedNotes': TextEditingController(),
    };
  }

  @override
  void dispose() {
    for (var c in _controllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ─── SUBMIT ───────────────────────────────────────────────────
// ─── SUBMIT ───────────────────────────────────────────────────
  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    if (selectedBrand == null || selectedModel == null) {
      _showSnack("Select brand & model", _kRed);
      return;
    }

    final price = double.tryParse(_controllers['price']!.text);
    if (price == null || price <= 0) {
      _showSnack("Invalid price", _kRed);
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final product = ProductModel(
        brand: selectedBrand,
        model: selectedModel,
        productName: _controllers['name']!.text.trim(),
        productType: _controllers['type']!.text.trim(),
        price: price,
        stocks: [
          Stocks(
            type: 'ADD',
            stockType: 'PACKED',
            stock: int.tryParse(_controllers['packedStock']!.text),
            stockNotes: _controllers['packedNotes']!.text,
          ),
          Stocks(
            type: 'ADD',
            stockType: 'UNPACKED',
            stock: int.tryParse(_controllers['unpackedStock']!.text),
            stockNotes: _controllers['unpackedNotes']!.text,
          ),
        ],
      );

      // Make the API call
      await ref.read(productControllerProvider.notifier).createProduct(product);

      if (!mounted) return;

      _showSnack("Product created successfully", Colors.green);
      // Remove this line if productListProvider doesn't exist in your codebase
      // ref.invalidate(productListProvider);
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        _showSnack('Error: ${e.toString()}', _kRed);
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ─── BRAND SHEET ──────────────────────────────────────────────
  void _showBrandSheet(List<BrandModel> brands) {
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtered = brands
              .where((b) => b.brandName.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            builder: (_, sc) => Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Select Brand',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _kDark)),
                  const SizedBox(height: 2),
                  const Text('Choose a brand',
                      style: TextStyle(
                          fontSize: 12,
                          color: _kMuted,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                  // search
                  TextField(
                    onChanged: (v) => setS(() => query = v),
                    style: const TextStyle(
                        fontSize: 13,
                        color: _kDark,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search brand...',
                      hintStyle: const TextStyle(
                          fontSize: 13,
                          color: _kMuted,
                          fontWeight: FontWeight.w400),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _kMuted, size: 20),
                      filled: true,
                      fillColor: _kBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _kBlue, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: sc,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final b = filtered[i];
                        final selected = selectedBrand == b.brandName;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedBrand = b.brandName;
                              selectedModel = null;
                            });
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: selected ? _kBlueBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? _kBlueBorder
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(b.brandName,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: selected ? _kBlue : _kMid)),
                                ),
                                if (selected)
                                  const Icon(Icons.check_rounded,
                                      color: _kBlue, size: 18),
                              ],
                            ),
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

  // ─── MODEL SHEET ───────────────────────────────────────────────
  void _showModelSheet(List<String> models) {
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Select Model',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _kDark)),
                  const SizedBox(height: 2),
                  const Text('Choose a model',
                      style: TextStyle(
                          fontSize: 12,
                          color: _kMuted,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                  // search
                  TextField(
                    onChanged: (v) => setS(() => query = v),
                    style: const TextStyle(
                        fontSize: 13,
                        color: _kDark,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search model...',
                      hintStyle: const TextStyle(
                          fontSize: 13,
                          color: _kMuted,
                          fontWeight: FontWeight.w400),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _kMuted, size: 20),
                      filled: true,
                      fillColor: _kBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _kBlue, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: sc,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final m = filtered[i];
                        final selected = selectedModel == m;
                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedModel = m);
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: selected ? _kBlueBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? _kBlueBorder
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(m,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: selected ? _kBlue : _kMid)),
                                ),
                                if (selected)
                                  const Icon(Icons.check_rounded,
                                      color: _kBlue, size: 18),
                              ],
                            ),
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

  // ─── UI ───────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    final brandState = ref.watch(activeBrandControllerProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: brandState.when(
          loading: () => _buildLoading(context, sw, sh),
          error: (e, _) => _buildError(context, sw, sh),
          data: (brands) => Column(
            children: [
              // ── Top Nav ────────────────────────────────
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
                    Text('Create Product',
                        style: TextStyle(
                            fontSize: sw * 0.042,
                            fontWeight: FontWeight.w700,
                            color: _kDark,
                            letterSpacing: -0.2)),
                    const Spacer(),
                    // balance space
                    SizedBox(width: sw * 0.095),
                  ],
                ),
              ),

              // ── Form ───────────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                    child: Column(
                      children: [
                        // Brand & Model
                        _SectionCard(
                          icon: Icons.category_outlined,
                          title: 'Brand & Model',
                          children: [
                            _buildFieldLabel(sw, 'Brand'),
                            SizedBox(height: sh * 0.006),
                            GestureDetector(
                              onTap: () => _showBrandSheet(brands),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: sw * 0.04,
                                    vertical: sw * 0.035),
                                decoration: BoxDecoration(
                                  color: _kBg,
                                  borderRadius:
                                  BorderRadius.circular(sw * 0.028),
                                  border: Border.all(color: _kBorder),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.local_offer_outlined,
                                        size: sw * 0.045,
                                        color: selectedBrand != null
                                            ? _kBlue
                                            : _kMuted),
                                    SizedBox(width: sw * 0.025),
                                    Expanded(
                                      child: Text(
                                        selectedBrand ?? 'Select brand',
                                        style: TextStyle(
                                            fontSize: sw * 0.036,
                                            fontWeight: selectedBrand !=
                                                null
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: selectedBrand != null
                                                ? _kDark
                                                : _kMuted),
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_down_rounded,
                                        color: _kMuted, size: sw * 0.05),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: sh * 0.015),
                            _buildFieldLabel(sw, 'Model'),
                            SizedBox(height: sh * 0.006),
                            Opacity(
                              opacity: selectedBrand == null ? 0.5 : 1,
                              child: GestureDetector(
                                onTap: selectedBrand == null
                                    ? null
                                    : () {
                                  final brand = brands.firstWhere(
                                          (b) => b.brandName == selectedBrand);
                                  _showModelSheet(brand.brandModels);
                                },
                                child: Container(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: sw * 0.04,
                                      vertical: sw * 0.035),
                                  decoration: BoxDecoration(
                                    color: _kBg,
                                    borderRadius:
                                    BorderRadius.circular(sw * 0.028),
                                    border: Border.all(color: _kBorder),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(Icons.devices_other_outlined,
                                          size: sw * 0.045,
                                          color: selectedModel != null
                                              ? _kBlue
                                              : _kMuted),
                                      SizedBox(width: sw * 0.025),
                                      Expanded(
                                        child: Text(
                                          selectedModel ?? 'Select model',
                                          style: TextStyle(
                                              fontSize: sw * 0.036,
                                              fontWeight: selectedModel !=
                                                  null
                                                  ? FontWeight.w600
                                                  : FontWeight.w400,
                                              color: selectedModel != null
                                                  ? _kDark
                                                  : _kMuted),
                                        ),
                                      ),
                                      Icon(Icons.keyboard_arrow_down_rounded,
                                          color: _kMuted, size: sw * 0.05),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: sh * 0.012),

                        // Product Info
                        _SectionCard(
                          icon: Icons.inventory_2_outlined,
                          title: 'Product Info',
                          children: [
                            _buildField(
                              sw: sw, sh: sh,
                              label: 'Product Name',
                              hint: 'Enter product name',
                              controller: _controllers['name']!,
                              icon: Icons.label_outline,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Product name is required'
                                  : null,
                            ),
                            _buildField(
                              sw: sw, sh: sh,
                              label: 'Product Type',
                              hint: 'Enter product type',
                              controller: _controllers['type']!,
                              icon: Icons.category_outlined,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Product type is required'
                                  : null,
                            ),
                            _buildField(
                              sw: sw, sh: sh,
                              label: 'Price',
                              hint: 'Enter price in ₹',
                              controller: _controllers['price']!,
                              icon: Icons.currency_rupee,
                              keyboard: TextInputType.number,
                              digitsOnly: true,
                              isLast: true,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Price is required';
                                }
                                if (double.tryParse(v) == null) {
                                  return 'Enter a valid price';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: sh * 0.012),

                        // Stock
                        _SectionCard(
                          icon: Icons.inventory_outlined,
                          title: 'Stock',
                          children: [
                            _buildField(
                              sw: sw, sh: sh,
                              label: 'Packed Stock',
                              hint: 'Quantity',
                              controller: _controllers['packedStock']!,
                              icon: Icons.inventory,
                              keyboard: TextInputType.number,
                              digitsOnly: true,
                            ),
                            _buildField(
                              sw: sw, sh: sh,
                              label: 'Packed Notes',
                              hint: 'Add notes',
                              controller: _controllers['packedNotes']!,
                              icon: Icons.note_outlined,
                              maxLines: 3,
                            ),
                            _buildField(
                              sw: sw, sh: sh,
                              label: 'Unpacked Stock',
                              hint: 'Quantity',
                              controller: _controllers['unpackedStock']!,
                              icon: Icons.inventory_2,
                              keyboard: TextInputType.number,
                              digitsOnly: true,
                            ),
                            _buildField(
                              sw: sw, sh: sh,
                              label: 'Unpacked Notes',
                              hint: 'Add notes',
                              controller: _controllers['unpackedNotes']!,
                              icon: Icons.note_alt_outlined,
                              maxLines: 3,
                              isLast: true,
                            ),
                          ],
                        ),

                        SizedBox(height: sh * 0.025),

                        // Submit Button
                        // Submit Button
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _handleSubmit,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _kBlue,
                              foregroundColor: Colors.white,
                              padding: EdgeInsets.symmetric(vertical: sh * 0.018),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(sw * 0.035),
                              ),
                              elevation: 0,
                            ),
                            child: _isSubmitting
                                ? SizedBox(
                              height: sw * 0.05,  // Changed from sh * 0.025
                              width: sw * 0.05,   // Added width
                              child: const CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.5,  // Slightly thicker for better visibility
                              ),
                            )
                                : Text(
                              'Create Product',
                              style: TextStyle(
                                  fontSize: sw * 0.04,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                        ),

                        SizedBox(height: sh * 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Field helpers ──────────────────────────────────────────────
  Widget _buildFieldLabel(double sw, String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
          fontSize: sw * 0.028,
          fontWeight: FontWeight.w700,
          color: _kMuted,
          letterSpacing: 0.5),
    );
  }

  Widget _buildField({
    required double sw,
    required double sh,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool digitsOnly = false,
    int maxLines = 1,
    bool isLast = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : sh * 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(sw, label),
          SizedBox(height: sh * 0.006),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            inputFormatters:
            digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
                fontSize: sw * 0.036,
                color: _kDark,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontSize: sw * 0.034,
                  color: _kMuted,
                  fontWeight: FontWeight.w400),
              prefixIcon:
              Icon(icon, color: _kMuted, size: sw * 0.045),
              filled: true,
              fillColor: _kBg,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04,
                  vertical: maxLines > 1 ? sw * 0.035 : 0),
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
                borderSide:
                const BorderSide(color: _kBlue, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kRed),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide:
                const BorderSide(color: _kRed, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Loading State ──────────────────────────────────────────────
  Widget _buildLoading(BuildContext context, double sw, double sh) {
    return Column(
      children: [
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
              Text('Create Product',
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
            child: CircularProgressIndicator(color: _kBlue),
          ),
        ),
      ],
    );
  }

  // ── Error State ────────────────────────────────────────────────
  Widget _buildError(BuildContext context, double sw, double sh) {
    return Column(
      children: [
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
              Text('Create Product',
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
                  width: sw * 0.18, height: sw * 0.18,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    border: Border.all(color: _kBorder),
                  ),
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
                      ref.invalidate(activeBrandControllerProvider),
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
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
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
                        fontSize: sw * 0.036,
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
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}