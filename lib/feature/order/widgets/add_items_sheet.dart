// add_items_sheet.dart — modal bottom sheet to append items to an existing
// order. Calls POST /order-details/:orderNumber/items via OrderController.
//
// Visibility rules (enforced by the caller / and on the server):
//   - Order status not in DELIVERED / COMPLETED / CANCELLED / REJECTED.
//   - Caller is the order's creator or SUPER_ADMIN / ADMIN / MANAGER.
//
// UX: one draft row by default, "+ Add another item" to stack more, single
// submit. Brand → Product cascade is scoped to the order's dealer so the
// list of brands/products matches what the dealer can buy.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../brand/controller/brand_controller.dart';
import '../../brand/model/brand_model.dart';
import '../../discount/controller/discount_controller.dart';
import '../../discount/model/dealer_discount_model.dart';
import '../../product/controller/product_controller.dart';
import '../../product/model/product_model.dart';
import '../controller/order_controller.dart';
import '../model/order_model.dart';

// ── Tokens (kept aligned with order_create_page.dart) ────────────────────────
const _kP       = Color(0xFF185FA5);
const _kPBg     = Color(0xFFEBF4FF);
const _kPBd     = Color(0xFFBFD9F5);
const _kBg      = Color(0xFFF7F8FA);
const _kBd      = Color(0xFFE5E7EB);
const _kT1      = Color(0xFF111827);
const _kT3      = Color(0xFF6B7280);
const _kT4      = Color(0xFF9CA3AF);
const _kRed     = Color(0xFFDC2626);
const _kRedBg   = Color(0xFFFEF2F2);
const _kAmber   = Color(0xFFB45309);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBd = Color(0xFFFCD28A);
const _kGreen   = Color(0xFF0F6E56);
const _kGreenBg = Color(0xFFEDFAF5);
const _kGreenBd = Color(0xFF9FE0C5);

/// Status set that blocks "Add Items". Mirrors the backend invariant.
const _kFrozenStatuses = {
  'DELIVERED', 'COMPLETED', 'CANCELLED', 'REJECTED',
};

/// Returns true iff the current caller may add items to this order.
/// [userRole] / [userId] usually come from SharedPreferences.
bool canAddItemsToOrder({
  required OrderModel order,
  required String? userRole,
  required String? userId,
}) {
  final status = (order.status ?? '').toUpperCase();
  if (_kFrozenStatuses.contains(status)) return false;
  if (userRole == 'ROLE_SUPER_ADMIN' ||
      userRole == 'ROLE_ADMIN' ||
      userRole == 'ROLE_MANAGER') {
    return true;
  }
  // Creator can also add items.
  if (userId != null && order.createdBy != null && userId == order.createdBy) {
    return true;
  }
  return false;
}

/// Open the bottom sheet. Returns true on a successful submit so callers can
/// optimistically refresh.
Future<bool> showAddItemsSheet(BuildContext context, OrderModel order) async {
  final ok = await showModalBottomSheet<bool>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
      ),
      child: _AddItemsSheet(order: order),
    ),
  );
  return ok == true;
}

// ─────────────────────────────────────────────────────────────────────────────
// _AddItemsSheet
// ─────────────────────────────────────────────────────────────────────────────
class _AddItemsSheet extends ConsumerStatefulWidget {
  const _AddItemsSheet({required this.order});
  final OrderModel order;

  @override
  ConsumerState<_AddItemsSheet> createState() => _AddItemsSheetState();
}

class _AddItemsSheetState extends ConsumerState<_AddItemsSheet> {
  final List<_DraftItem> _drafts = [_DraftItem()];
  bool _submitting = false;
  String? _serverError;

  void _addRow() => setState(() => _drafts.add(_DraftItem()));
  void _removeRow(int i) {
    if (_drafts.length == 1) return;
    setState(() => _drafts.removeAt(i));
  }

  /// Null = valid. Otherwise a short label that doubles as the disabled
  /// button text and tells the user exactly what's still missing.
  String? _validate() {
    if (_drafts.isEmpty) return 'Add an item';
    for (var i = 0; i < _drafts.length; i++) {
      final d = _drafts[i];
      final n = _drafts.length == 1 ? '' : ' (item ${i + 1})';
      if (d.brand == null)        return 'Pick a brand$n';
      if (d.model == null)        return 'Pick a model$n';
      if (d.product == null)      return 'Pick a product$n';
      if (d.qty <= 0)             return 'Enter a quantity$n';
      if (d.deliveryDate == null) return 'Pick a delivery date$n';
    }
    return null;
  }

  Future<void> _submit() async {
    // Button is only enabled when _validate() == null, but guard regardless.
    if (_validate() != null) return;

    setState(() {
      _submitting = true;
      _serverError = null;
    });
    try {
      final items = _drafts.map((d) {
        final payload = <String, dynamic>{
          'product_id'       : d.product!.productId,
          'qty_ordered'      : d.qty,
          'delivery_date'    : DateFormat('yyyy-MM-dd').format(d.deliveryDate!),
          'is_product_scheme': false,
        };
        if (d.useDealerDiscount && d.dealerDiscount != null) {
          payload['dealer_discount_id'] = d.dealerDiscount!.dealerDiscountId;
        } else if (d.discountPrice > 0) {
          payload['discount_price'] = d.discountPrice;
        }
        return payload;
      }).toList();

      // Final guard — never call the API with an empty items array.
      if (items.isEmpty) {
        setState(() {
          _serverError = 'Add at least one item to submit';
          _submitting  = false;
        });
        return;
      }

      await ref
          .read(orderControllerProvider.notifier)
          .addItemsToOrder(widget.order.orderNumber ?? '', items);

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _serverError = e.toString();
        _submitting  = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;
    final maxH = sh * 0.92;
    final dealerId = widget.order.dealerId;
    final corner = (sw * 0.05).clamp(14.0, 22.0);
    final hPad   = sw * 0.05;
    final tPad   = sw * 0.04;

    final problem = _validate();
    final canSubmit = problem == null && !_submitting;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: maxH),
      child: Container(
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(corner)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Drag handle + title + sub (match Edit Personal Info) ─────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, tPad, hPad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kHandle(),
                  Text(
                    'Add Items',
                    style: TextStyle(
                      fontSize: (sw * 0.045).clamp(15.0, 21.0),
                      fontWeight: FontWeight.w800,
                      color: _kT1,
                    ),
                  ),
                  Text(
                    '#${widget.order.orderNumber ?? '—'}',
                    style: TextStyle(
                      fontSize: (sw * 0.032).clamp(11.0, 14.0),
                      color: _kT4,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  SizedBox(height: sw * 0.04),
                ],
              ),
            ),

            // ── Inline server-error banner (no snackbar — appears in sheet)
            if (_serverError != null)
              Padding(
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sw * 0.03),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                        color: const Color(0xFFFECACA), width: 0.5),
                  ),
                  child: Row(children: [
                    const Icon(Icons.error_outline_rounded,
                        size: 16, color: _kRed),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _serverError!,
                        style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: _kRed,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: () => setState(() => _serverError = null),
                      borderRadius: BorderRadius.circular(6),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(Icons.close_rounded,
                            size: 14, color: _kRed),
                      ),
                    ),
                  ]),
                ),
              ),

            // ── Drafts list ──────────────────────────────────────────────
            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sw * 0.04),
                itemCount: _drafts.length + 1, // +1 for "Add another"
                separatorBuilder: (_, __) => SizedBox(height: sh * 0.012),
                itemBuilder: (ctx, i) {
                  if (i == _drafts.length) {
                    return _AddRowButton(
                      sw: sw, sh: sh,
                      onTap: _submitting ? null : _addRow,
                    );
                  }
                  return _ItemRow(
                    sw: sw, sh: sh,
                    index: i,
                    canRemove: _drafts.length > 1,
                    dealerId: dealerId,
                    draft: _drafts[i],
                    onChanged: () => setState(() {}),
                    onRemove: () => _removeRow(i),
                    disabled: _submitting,
                  );
                },
              ),
            ),

            // ── Footer actions (Edit Personal Info style) ────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sw * 0.06),
              child: Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _submitting
                        ? null
                        : () => Navigator.of(context).pop(false),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      side: const BorderSide(color: _kBd, width: 0.5),
                    ),
                    child: const Text(
                      'Cancel',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _kT4,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    // Disabled when invalid OR submitting — the label tells
                    // the user exactly what's still missing.
                    onPressed: canSubmit ? _submit : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kP,
                      foregroundColor: _kWhite,
                      disabledBackgroundColor: _kBd,
                      disabledForegroundColor: _kT4,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      elevation: 0,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(
                              color: _kWhite,
                              strokeWidth: 2.4,
                            ),
                          )
                        : Text(
                            // When valid: "Add N item(s)". Otherwise the
                            // exact missing-field label.
                            problem ??
                                'Add ${_drafts.length} item${_drafts.length == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shared sheet primitives — match `dealer_view_screen.dart > _sheet/_handleW`.
// ─────────────────────────────────────────────────────────────────────────────
const _kWhite = Colors.white;

Widget _kHandle() => Center(
  child: Container(
    width: 36, height: 4,
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(
      color: _kBd,
      borderRadius: BorderRadius.circular(2),
    ),
  ),
);

InputDecoration _kSheetDeco(String hint, IconData icon, {Widget? suffix}) {
  return InputDecoration(
    hintText: hint,
    hintStyle: const TextStyle(fontSize: 14, color: _kT4),
    prefixIcon: Icon(icon, color: _kT4, size: 20),
    suffixIcon: suffix,
    filled: true,
    fillColor: _kBg,
    contentPadding: const EdgeInsets.symmetric(
        horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kBd, width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kBd, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(10),
      borderSide: const BorderSide(color: _kP, width: 1.5),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// _DraftItem — mutable form state for one row.
// Brand → Model → Product cascade. Picking a brand clears model + product;
// picking a model clears product.
// ─────────────────────────────────────────────────────────────────────────────
class _DraftItem {
  BrandModel? brand;
  String? model;
  ProductModel? product;
  int qty = 1;
  DateTime? deliveryDate;
  DealerDiscountModel? dealerDiscount;
  double discountPrice = 0;
  bool useDealerDiscount = false;
}

// ─────────────────────────────────────────────────────────────────────────────
// _ItemRow — Brand → Product cascade + qty + delivery date
// ─────────────────────────────────────────────────────────────────────────────
class _ItemRow extends ConsumerStatefulWidget {
  const _ItemRow({
    required this.sw,
    required this.sh,
    required this.index,
    required this.canRemove,
    required this.dealerId,
    required this.draft,
    required this.onChanged,
    required this.onRemove,
    required this.disabled,
  });

  final double sw, sh;
  final int index;
  final bool canRemove;
  final String dealerId;
  final _DraftItem draft;
  final VoidCallback onChanged;
  final VoidCallback onRemove;
  final bool disabled;

  @override
  ConsumerState<_ItemRow> createState() => _ItemRowState();
}

class _ItemRowState extends ConsumerState<_ItemRow> {
  late final TextEditingController _discCtrl;

  @override
  void initState() {
    super.initState();
    _discCtrl = TextEditingController(
      text: widget.draft.discountPrice > 0
          ? widget.draft.discountPrice.toString()
          : '',
    );
  }

  @override
  void dispose() {
    _discCtrl.dispose();
    super.dispose();
  }

  Future<void> _fetchDiscount(ProductModel product) async {
    try {
      final disc = await ref.read(dealerProductDiscountProvider({
        'dealerId': widget.dealerId,
        'productId': product.productId ?? '',
      }).future);
      if (!mounted) return;
      widget.draft.dealerDiscount = disc;
      widget.draft.useDealerDiscount = false;
      widget.onChanged();
    } catch (_) {}
  }

  @override
  Widget build(BuildContext context) {
    final sw = widget.sw;
    final sh = widget.sh;
    final draft = widget.draft;
    final disabled = widget.disabled;

    final brandsAsync = ref.watch(dealerBrandsProvider(widget.dealerId));
    final productsAsync = draft.brand?.brandName == null
        ? const AsyncValue<List<ProductModel>>.data([])
        : ref.watch(productByBrandProvider(draft.brand!.brandName));

    final price = double.tryParse(draft.product?.price?.toString() ?? '0') ?? 0;

    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kBd, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header — "Item N" + remove
          Row(children: [
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.022, vertical: sw * 0.012),
              decoration: BoxDecoration(
                color: _kPBg,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _kPBd, width: 0.5),
              ),
              child: Text(
                'Item ${widget.index + 1}',
                style: const TextStyle(
                  color: _kP,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                ),
              ),
            ),
            const Spacer(),
            if (widget.canRemove)
              IconButton(
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                icon: Icon(Icons.delete_outline_rounded,
                    color: _kRed, size: (sw * 0.05).clamp(18.0, 22.0)),
                onPressed: disabled ? null : widget.onRemove,
              ),
          ]),
          SizedBox(height: sh * 0.012),

          // ── Brand ──────────────────────────────────────────────────
          _FieldLabel(label: 'Brand'),
          brandsAsync.when(
            loading: () => const _LoadingRow(),
            error: (_, __) => const _ErrorRow(text: 'Brands unavailable'),
            data: (brands) => _PickerField(
              hint: brands.isEmpty ? 'No brands' : 'Select brand',
              valueLabel: draft.brand?.brandName,
              icon: Icons.local_offer_outlined,
              disabled: disabled || brands.isEmpty,
              onTap: () async {
                final pick = await _showPicker<BrandModel>(
                  context: context,
                  title: 'Choose a brand',
                  searchHint: 'Search brand…',
                  items: brands,
                  labelFor: (b) => b.brandName,
                  selected: draft.brand,
                );
                if (pick != null) {
                  draft.brand = pick;
                  draft.model = null;
                  draft.product = null;
                  draft.dealerDiscount = null;
                  draft.discountPrice = 0;
                  draft.useDealerDiscount = false;
                  _discCtrl.clear();
                  widget.onChanged();
                }
              },
            ),
          ),
          SizedBox(height: sh * 0.012),

          // ── Model ──────────────────────────────────────────────────
          _FieldLabel(label: 'Model'),
          if (draft.brand == null)
            const _HintRow(text: 'Pick a brand first')
          else
            _PickerField(
              hint: draft.brand!.brandModels.isEmpty
                  ? 'No models'
                  : 'Select model',
              valueLabel: draft.model,
              icon: Icons.tune_rounded,
              disabled: disabled || draft.brand!.brandModels.isEmpty,
              onTap: () async {
                final pick = await _showPicker<String>(
                  context: context,
                  title: 'Choose a model',
                  searchHint: 'Search model…',
                  items: draft.brand!.brandModels,
                  labelFor: (m) => m,
                  selected: draft.model,
                );
                if (pick != null) {
                  draft.model = pick;
                  draft.product = null;
                  draft.dealerDiscount = null;
                  draft.discountPrice = 0;
                  draft.useDealerDiscount = false;
                  _discCtrl.clear();
                  widget.onChanged();
                }
              },
            ),
          SizedBox(height: sh * 0.012),

          // ── Product ────────────────────────────────────────────────
          _FieldLabel(label: 'Product'),
          if (draft.brand == null)
            const _HintRow(text: 'Pick a brand first')
          else if (draft.model == null)
            const _HintRow(text: 'Pick a model first')
          else
            productsAsync.when(
              loading: () => const _LoadingRow(),
              error: (_, __) => const _ErrorRow(text: 'Products unavailable'),
              data: (products) {
                final filtered = products
                    .where((p) => p.model == draft.model)
                    .toList();
                final selectedLabel = draft.product == null
                    ? null
                    : [
                        draft.product!.productName ?? '—',
                        if ((draft.product!.productType ?? '').isNotEmpty)
                          draft.product!.productType,
                      ].whereType<String>().join(' · ');
                return _PickerField(
                  hint: filtered.isEmpty ? 'No products' : 'Select product',
                  valueLabel: selectedLabel,
                  icon: Icons.inventory_2_outlined,
                  disabled: disabled || filtered.isEmpty,
                  onTap: () async {
                    final pick = await _showPicker<ProductModel>(
                      context: context,
                      title: 'Choose a product',
                      searchHint: 'Search name, type, model…',
                      items: filtered,
                      labelFor: (p) => p.productName ?? '—',
                      subLabelFor: (p) {
                        final parts = [
                          if ((p.productType ?? '').isNotEmpty) p.productType,
                          if ((p.brand ?? '').isNotEmpty) p.brand,
                          if (p.availableStock != null)
                            'stock ${p.availableStock}',
                        ].whereType<String>().toList();
                        return parts.isEmpty ? null : parts.join(' · ');
                      },
                      selected: draft.product,
                    );
                    if (pick != null) {
                      draft.product = pick;
                      draft.dealerDiscount = null;
                      draft.discountPrice = 0;
                      draft.useDealerDiscount = false;
                      _discCtrl.clear();
                      widget.onChanged();
                      _fetchDiscount(pick);
                    }
                  },
                );
              },
            ),
          SizedBox(height: sh * 0.012),

          // Qty + Delivery in one row
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(label: 'Qty'),
                  _QtyStepper(
                    value: draft.qty,
                    disabled: disabled,
                    onChange: (v) {
                      draft.qty = v;
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
            SizedBox(width: sw * 0.03),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _FieldLabel(label: 'Delivery date'),
                  _DateField(
                    value: draft.deliveryDate,
                    disabled: disabled,
                    onPick: (d) {
                      draft.deliveryDate = d;
                      widget.onChanged();
                    },
                  ),
                ],
              ),
            ),
          ]),

          // ── Discount (only when product is selected) ───────────────
          if (draft.product != null) ...[
            SizedBox(height: sh * 0.012),
            _FieldLabel(label: 'Discount'),
            if (draft.dealerDiscount != null) ...[
              Row(children: [
                Expanded(
                  child: _DiscToggle(
                    sw: sw,
                    label: 'Manual',
                    selected: !draft.useDealerDiscount,
                    onTap: disabled ? null : () {
                      draft.useDealerDiscount = false;
                      draft.discountPrice = 0;
                      _discCtrl.clear();
                      widget.onChanged();
                    },
                  ),
                ),
                SizedBox(width: sw * 0.02),
                Expanded(
                  child: _DiscToggle(
                    sw: sw,
                    label: 'Dealer',
                    selected: draft.useDealerDiscount,
                    onTap: disabled ? null : () {
                      draft.useDealerDiscount = true;
                      draft.discountPrice = 0;
                      _discCtrl.clear();
                      widget.onChanged();
                    },
                  ),
                ),
              ]),
              SizedBox(height: sh * 0.008),
            ],
            if (!draft.useDealerDiscount) ...[
              TextField(
                controller: _discCtrl,
                enabled: !disabled,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                ],
                style: TextStyle(
                  fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1),
                decoration: InputDecoration(
                  hintText: price > 0
                      ? 'Max ₹${price.toStringAsFixed(0)}'
                      : 'Discount amount (₹)',
                  hintStyle: TextStyle(
                      fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4),
                  prefixIcon: Icon(Icons.local_offer_outlined,
                      color: _kAmber,
                      size: (sw * 0.045).clamp(15.0, 20.0)),
                  filled: true,
                  fillColor: _kBg,
                  contentPadding: EdgeInsets.all(sw * 0.035),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        (sw * 0.028).clamp(8.0, 12.0)),
                    borderSide: const BorderSide(color: _kBd, width: 0.5),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        (sw * 0.028).clamp(8.0, 12.0)),
                    borderSide: const BorderSide(color: _kBd, width: 0.5),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(
                        (sw * 0.028).clamp(8.0, 12.0)),
                    borderSide: const BorderSide(color: _kP, width: 1.5),
                  ),
                ),
                onChanged: (v) {
                  double val = double.tryParse(v) ?? 0;
                  if (price > 0 && val > price) {
                    val = price;
                    _discCtrl.text = price.toStringAsFixed(0);
                    _discCtrl.selection = TextSelection.fromPosition(
                      TextPosition(offset: _discCtrl.text.length),
                    );
                  }
                  draft.discountPrice = val;
                  widget.onChanged();
                },
              ),
              if (price > 0)
                Padding(
                  padding: EdgeInsets.only(top: sw * 0.01, left: sw * 0.01),
                  child: Text(
                    'Max discount: ₹${price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: (sw * 0.026).clamp(9.0, 11.5),
                      color: _kT4,
                    ),
                  ),
                ),
            ],
            if (draft.useDealerDiscount && draft.dealerDiscount != null) ...[
              Container(
                padding: EdgeInsets.all(sw * 0.035),
                decoration: BoxDecoration(
                  color: _kGreenBg,
                  borderRadius: BorderRadius.circular(
                      (sw * 0.028).clamp(8.0, 12.0)),
                  border: Border.all(color: _kGreenBd, width: 0.5),
                ),
                child: Row(children: [
                  Icon(Icons.discount_outlined,
                      color: _kGreen,
                      size: (sw * 0.045).clamp(15.0, 20.0)),
                  SizedBox(width: sw * 0.025),
                  Text(
                    '${draft.dealerDiscount!.isPercentage == false ? '₹' : ''}${draft.dealerDiscount!.discountValue}${draft.dealerDiscount!.isPercentage == true ? '%' : ''} off',
                    style: TextStyle(
                      fontSize: (sw * 0.036).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w700,
                      color: _kGreen,
                    ),
                  ),
                ]),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _PickerField — tappable field that shows the current selection (or hint)
// and a chevron. Opens a bottom-sheet picker on tap.
// ─────────────────────────────────────────────────────────────────────────────
class _PickerField extends StatelessWidget {
  const _PickerField({
    required this.hint,
    required this.valueLabel,
    required this.icon,
    required this.onTap,
    this.disabled = false,
  });

  final String hint;
  final String? valueLabel;
  final IconData icon;
  final VoidCallback onTap;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final filled = (valueLabel != null && valueLabel!.isNotEmpty);
    return InkWell(
      onTap: disabled ? null : onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 44,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: disabled ? _kBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBd, width: 0.5),
        ),
        child: Row(children: [
          Icon(icon,
              size: 16,
              color: filled ? _kP : _kT4),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              filled ? valueLabel! : hint,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 14,
                fontWeight: filled ? FontWeight.w600 : FontWeight.w500,
                color: filled ? _kT1 : _kT4,
              ),
            ),
          ),
          Icon(Icons.keyboard_arrow_down_rounded,
              size: 20, color: disabled ? _kT4 : _kT3),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _showPicker / _PickerSheet — generic searchable bottom-sheet picker.
// ─────────────────────────────────────────────────────────────────────────────
Future<T?> _showPicker<T>({
  required BuildContext context,
  required String title,
  required String searchHint,
  required List<T> items,
  required String Function(T) labelFor,
  String? Function(T)? subLabelFor,
  T? selected,
}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetCtx) => Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(sheetCtx).viewInsets.bottom,
      ),
      child: _PickerSheet<T>(
        title: title,
        searchHint: searchHint,
        items: items,
        labelFor: labelFor,
        subLabelFor: subLabelFor,
        selected: selected,
      ),
    ),
  );
}

class _PickerSheet<T> extends StatefulWidget {
  const _PickerSheet({
    required this.title,
    required this.searchHint,
    required this.items,
    required this.labelFor,
    required this.selected,
    this.subLabelFor,
  });

  final String title;
  final String searchHint;
  final List<T> items;
  final String Function(T) labelFor;
  final String? Function(T)? subLabelFor;
  final T? selected;

  @override
  State<_PickerSheet<T>> createState() => _PickerSheetState<T>();
}

class _PickerSheetState<T> extends State<_PickerSheet<T>> {
  final _ctrl = TextEditingController();
  String _q = '';

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  bool _matches(T item) {
    if (_q.isEmpty) return true;
    final q = _q.toLowerCase();
    final label = widget.labelFor(item).toLowerCase();
    if (label.contains(q)) return true;
    final sub = widget.subLabelFor?.call(item)?.toLowerCase();
    if (sub != null && sub.contains(q)) return true;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final sw = mq.size.width;
    final sh = mq.size.height;
    final filtered = widget.items.where(_matches).toList();
    final corner = (sw * 0.05).clamp(14.0, 22.0);
    final hPad   = sw * 0.05;
    final tPad   = sw * 0.04;

    return ConstrainedBox(
      constraints: BoxConstraints(maxHeight: sh * 0.85),
      child: Container(
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.vertical(top: Radius.circular(corner)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle + title + subtitle (Edit Personal Info pattern) ──
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, tPad, hPad, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _kHandle(),
                  Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: (sw * 0.045).clamp(15.0, 21.0),
                      fontWeight: FontWeight.w800,
                      color: _kT1,
                    ),
                  ),
                  Text(
                    '${widget.items.length} option'
                    '${widget.items.length == 1 ? '' : 's'}',
                    style: TextStyle(
                      fontSize: (sw * 0.032).clamp(11.0, 14.0),
                      color: _kT4,
                    ),
                  ),
                  SizedBox(height: sw * 0.04),
                ],
              ),
            ),

            // ── Search field (filled grey, same as _sheetDeco) ───────────
            Padding(
              padding: EdgeInsets.fromLTRB(hPad, 0, hPad, sw * 0.035),
              child: TextField(
                controller: _ctrl,
                onChanged: (v) => setState(() => _q = v.trim()),
                style: const TextStyle(fontSize: 14, color: _kT1),
                decoration: _kSheetDeco(
                  widget.searchHint,
                  Icons.search_rounded,
                  suffix: _q.isEmpty
                      ? null
                      : IconButton(
                          padding: EdgeInsets.zero,
                          icon: const Icon(Icons.close_rounded,
                              size: 18, color: _kT4),
                          onPressed: () {
                            _ctrl.clear();
                            setState(() => _q = '');
                          },
                        ),
                ),
              ),
            ),

            // ── Results list ─────────────────────────────────────────────
            Flexible(
              child: filtered.isEmpty
                  ? Padding(
                      padding: EdgeInsets.symmetric(vertical: sh * 0.05),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inbox_outlined,
                                size: 36,
                                color: _kT4.withValues(alpha: 0.6)),
                            const SizedBox(height: 10),
                            Text(
                              _q.isEmpty
                                  ? 'Nothing here'
                                  : 'No matches for "$_q"',
                              style: const TextStyle(
                                color: _kT3,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: EdgeInsets.fromLTRB(
                          hPad, 0, hPad, sw * 0.06),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(height: 6),
                      itemBuilder: (_, i) {
                        final item = filtered[i];
                        final isSelected = widget.selected == item;
                        final label = widget.labelFor(item);
                        final sub = widget.subLabelFor?.call(item);
                        return InkWell(
                          borderRadius: BorderRadius.circular(10),
                          onTap: () => Navigator.of(context).pop(item),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 12),
                            decoration: BoxDecoration(
                              color: isSelected ? _kPBg : _kBg,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected ? _kPBd : _kBd,
                                width: 0.5,
                              ),
                            ),
                            child: Row(children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      label,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: isSelected ? _kP : _kT1,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    if (sub != null && sub.isNotEmpty) ...[
                                      const SizedBox(height: 3),
                                      Text(
                                        sub,
                                        style: const TextStyle(
                                          fontSize: 11.5,
                                          color: _kT3,
                                          fontWeight: FontWeight.w500,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle_rounded,
                                    color: _kP, size: 18),
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
  }
}

// ── Sub-widgets ──────────────────────────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  // Matches `_sheetLabel` in dealer_view_screen.dart for visual parity with
  // the Edit Personal Info sheet.
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: _kT4,
        letterSpacing: 0.5,
      ),
    ),
  );
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({
    required this.value,
    required this.onChange,
    required this.disabled,
  });

  final int value;
  final ValueChanged<int> onChange;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kBd, width: 0.5),
      ),
      child: Row(children: [
        _StepBtn(
          icon: Icons.remove_rounded,
          enabled: !disabled && value > 1,
          onTap: () => onChange(value - 1),
        ),
        Expanded(
          child: Center(
            child: Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _kT1,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
        ),
        _StepBtn(
          icon: Icons.add_rounded,
          enabled: !disabled,
          onTap: () => onChange(value + 1),
        ),
      ]),
    );
  }
}

class _StepBtn extends StatelessWidget {
  const _StepBtn({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: enabled ? onTap : null,
    borderRadius: BorderRadius.circular(8),
    child: SizedBox(
      width: 38, height: 40,
      child: Icon(icon,
          size: 18, color: enabled ? _kP : _kT4),
    ),
  );
}

class _DateField extends StatelessWidget {
  const _DateField({
    required this.value,
    required this.onPick,
    required this.disabled,
  });

  final DateTime? value;
  final ValueChanged<DateTime> onPick;
  final bool disabled;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy');
    final label = value == null ? 'Pick a date' : fmt.format(value!);

    return InkWell(
      onTap: disabled
          ? null
          : () async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: context,
                initialDate: value ?? now,
                firstDate: now,
                lastDate: now.add(const Duration(days: 365)),
                builder: (ctx, child) {
                  // White calendar surface, brand-blue (_kP) selection.
                  return Theme(
                    data: Theme.of(ctx).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary  : _kP,       // header bg + selected day fill
                        onPrimary: Colors.white, // selected day text
                        surface  : Colors.white, // calendar background
                        onSurface: _kT1,         // unselected day text
                      ),
                      dialogTheme: const DialogThemeData(
                        backgroundColor: Colors.white,
                      ),
                      textButtonTheme: TextButtonThemeData(
                        style: TextButton.styleFrom(foregroundColor: _kP),
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) onPick(picked);
            },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        height: 40,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          color: disabled ? _kBg : Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _kBd, width: 0.5),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_rounded,
              size: 15, color: value == null ? _kT4 : _kP),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: value == null ? _kT4 : _kT1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ]),
      ),
    );
  }
}

class _LoadingRow extends StatelessWidget {
  const _LoadingRow();
  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    decoration: BoxDecoration(
      color: _kBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: const Center(
      child: SizedBox(
        height: 16, width: 16,
        child: CircularProgressIndicator(color: _kP, strokeWidth: 2),
      ),
    ),
  );
}

class _HintRow extends StatelessWidget {
  const _HintRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: _kBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      Icon(Icons.info_outline_rounded, size: 15, color: _kT4),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              fontSize: 13, color: _kT3, fontWeight: FontWeight.w500)),
    ]),
  );
}

class _ErrorRow extends StatelessWidget {
  const _ErrorRow({required this.text});
  final String text;

  @override
  Widget build(BuildContext context) => Container(
    height: 40,
    padding: const EdgeInsets.symmetric(horizontal: 12),
    decoration: BoxDecoration(
      color: _kRedBg,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(children: [
      const Icon(Icons.error_outline_rounded, size: 15, color: _kRed),
      const SizedBox(width: 10),
      Text(text,
          style: const TextStyle(
              fontSize: 13,
              color: _kRed,
              fontWeight: FontWeight.w600)),
    ]),
  );
}

class _AddRowButton extends StatelessWidget {
  const _AddRowButton({required this.sw, required this.sh, this.onTap});
  final double sw, sh;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: DottedBox(
        height: sh * 0.062,
        color: _kPBd,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(Icons.add_rounded, color: _kP, size: 18),
            SizedBox(width: 8),
            Text(
              'Add another item',
              style: TextStyle(
                color: _kP,
                fontSize: 13,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DiscToggle extends StatelessWidget {
  const _DiscToggle({
    required this.sw,
    required this.label,
    required this.selected,
    this.onTap,
  });
  final double sw;
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(vertical: sw * 0.025),
      decoration: BoxDecoration(
        color: selected ? _kAmberBg : _kBg,
        borderRadius: BorderRadius.circular((sw * 0.025).clamp(8.0, 12.0)),
        border: Border.all(
          color: selected ? _kAmberBd : _kBd,
          width: selected ? 1.0 : 0.5,
        ),
      ),
      child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(
          selected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
          color: _kAmber,
          size: (sw * 0.045).clamp(15.0, 20.0),
        ),
        SizedBox(width: sw * 0.015),
        Text(
          label,
          style: TextStyle(
            fontSize: (sw * 0.03).clamp(10.0, 13.0),
            fontWeight: FontWeight.w700,
            color: _kAmber,
          ),
        ),
      ]),
    ),
  );
}

/// Cheap dashed-looking container — solid border with reduced opacity is
/// indistinguishable on this background without bringing in a custom painter.
class DottedBox extends StatelessWidget {
  const DottedBox({
    super.key,
    required this.height,
    required this.color,
    required this.child,
  });
  final double height;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
    height: height,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: color, width: 1.2),
    ),
    child: child,
  );
}
