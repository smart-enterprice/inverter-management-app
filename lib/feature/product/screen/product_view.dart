import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import '../../../core/const/icons.dart';
import '../../../model/product_model.dart';
import '../../../model/user_model.dart';
import '../../../widgets/circle_button.dart';
import '../../signup/controller/signUp_controller.dart';
import '../controller/product_controller.dart';
import 'product_price_history.dart';

// ── Zoho Books design tokens ──────────────────────────────────────────────────
const _kP       = Color(0xFF185FA5);
const _kPBg     = Color(0xFFEBF4FF);
const _kPBd     = Color(0xFFBFD9F5);
const _kBg      = Color(0xFFF7F8FA);
const _kWhite   = Colors.white;
const _kBd      = Color(0xFFE5E7EB);
const _kT1      = Color(0xFF111827);
const _kT2      = Color(0xFF374151);
const _kT3      = Color(0xFF6B7280);
const _kT4      = Color(0xFF9CA3AF);
const _kGreen   = Color(0xFF0F6E56);
const _kGreenBg = Color(0xFFEDFAF5);
const _kGreenBd = Color(0xFF9FE0C5);
const _kRed     = Color(0xFFDC2626);
const _kRedBg   = Color(0xFFFEF2F2);
const _kRedBd   = Color(0xFFFECACA);
const _kAmber   = Color(0xFFB45309);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBd = Color(0xFFFCD28A);
const _kPurple  = Color(0xFF7C3AED);
const _kPurpleBg= Color(0xFFF5F3FF);
const _kPurpleBd= Color(0xFFDDD6FE);

// ═════════════════════════════════════════════════════════════════════════════
class ProductDetailsScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final productAsync = ref.watch(productByIdProvider(productId));
    return productAsync.when(
        loading: () => const Scaffold(backgroundColor: _kBg,
            body: Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5))),
        error: (_, __) => _ErrorScreen(productId: productId),
        data: (product) => _DetailView(product: product!, productId: productId));
  }
}

// ── Detail view ─────────────────────────────────────────────────────────────
class _DetailView extends ConsumerStatefulWidget {
  final ProductModel product;
  final String productId;
  const _DetailView({required this.product, required this.productId});
  @override ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
        backgroundColor: bg, behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final p = widget.product;
    final active = p.status?.toLowerCase() == 'active';

    return Scaffold(backgroundColor: _kBg,
        body: SafeArea(child: Column(children: [
          // ── App bar ──────────────────────────────────────────────────────
          Container(color: _kWhite,
              padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
              child: Row(children: [
                CircularIconButton(icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context)),
                const Spacer(),
                Text('Product Details', style: TextStyle(
                    fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w700,
                    color: _kT1, letterSpacing: -0.2)),
                const Spacer(),
                SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
              ])),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(child: RefreshIndicator(color: _kP, backgroundColor: _kWhite,
              onRefresh: () async => ref.invalidate(productByIdProvider(widget.productId)),
              child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.04),
                  child: Column(children: [
                    _headerCard(sw, sh, p),
                    SizedBox(height: sh * 0.012),
                    _statusCard(sw, p, active),
                    SizedBox(height: sh * 0.012),
                    RoleGuard(feature: AppFeature.viewStock,
                        child: Column(children: [
                          _stockCard(sw, sh, p, active),
                          SizedBox(height: sh * 0.012),
                        ])),
                    RoleGuard(feature: AppFeature.viewPrice,
                        child: Column(children: [
                          _priceCard(sw, sh, p),
                          SizedBox(height: sh * 0.012),
                        ])),
                    ref.watch(employeeByIdProvider(p.createdBy ?? '')).when(
                        data: (user) => _creatorCard(sw, sh, user),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => _creatorCard(sw, sh, null)),
                    SizedBox(height: sh * 0.012),
                    RoleGuard(feature: AppFeature.viewTimestamps,
                        child: _dateRow(sw, sh, p)),
                  ])))),
        ])));
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _headerCard(double sw, double sh, ProductModel p) {
    return _Card(sw: sw, child: Padding(
        padding: EdgeInsets.all(sw * 0.04),
        child: Row(children: [
          Container(
              width: (sw * 0.13).clamp(44.0, 60.0), height: (sw * 0.13).clamp(44.0, 60.0),
              decoration: BoxDecoration(color: _kPurpleBg,
                  borderRadius: BorderRadius.circular((sw * 0.035).clamp(10.0, 16.0)),
                  border: Border.all(color: _kPurpleBd, width: 0.5)),
              child: Icon(Icons.inventory_2_outlined, color: _kPurple,
                  size: (sw * 0.06).clamp(22.0, 30.0))),
          SizedBox(width: sw * 0.035),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(p.productName ?? 'Unnamed', style: TextStyle(
                fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w800,
                color: _kT1, letterSpacing: -0.3)),
            SizedBox(height: sw * 0.008),
            Text('${p.brand} • ${p.model}', maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
            SizedBox(height: sw * 0.012),
            _Pill(sw: sw, label: p.productType ?? 'N/A', fg: _kPurple, bg: _kPurpleBg, bd: _kPurpleBd),
            // After the productType pill,
            SizedBox(height: sw * 0.006),
            _Pill(sw: sw, label: p.productCategory ?? 'N/A', fg: _kGreen, bg: _kGreenBg, bd: _kGreenBd),
          ])),
          RoleGuard(feature: AppFeature.updateProduct,
              child: GestureDetector(
                  onTap: () => _showEditSheet(context, sw, p),
                  child: Container(
                      padding: EdgeInsets.all((sw * 0.022).clamp(7.0, 12.0)),
                      decoration: BoxDecoration(color: _kPBg,
                          borderRadius: BorderRadius.circular((sw * 0.025).clamp(8.0, 12.0)),
                          border: Border.all(color: _kPBd, width: 0.5)),
                      child: Icon(Icons.edit_outlined, size: (sw * 0.045).clamp(15.0, 20.0), color: _kP)))),
        ])));
  }

  // ── Status ──────────────────────────────────────────────────────────────
  Widget _statusCard(double sw, ProductModel p, bool active) {
    final c = active ? _kGreen : _kRed;
    final bg = active ? _kGreenBg : _kRedBg;
    final bd = active ? _kGreenBd : _kRedBd;
    return Container(
        decoration: BoxDecoration(color: bg,
            borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: bd, width: 0.5)),
        padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
        child: Row(children: [
          Container(width: (sw * 0.09).clamp(32.0, 42.0), height: (sw * 0.09).clamp(32.0, 42.0),
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              child: Icon(active ? Icons.check_rounded : Icons.pause_rounded,
                  color: _kWhite, size: (sw * 0.045).clamp(15.0, 20.0))),
          SizedBox(width: sw * 0.03),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Product Status', style: TextStyle(
                fontSize: (sw * 0.028).clamp(9.5, 12.5), color: c, fontWeight: FontWeight.w600)),
            Text(active ? 'Active' : 'Inactive', style: TextStyle(
                fontSize: (sw * 0.038).clamp(13.0, 17.0), fontWeight: FontWeight.w800, color: c)),
          ])),
          RoleGuard(feature: AppFeature.updateStatus,
              child: Switch(value: active, activeColor: _kGreen, activeTrackColor: _kGreenBd,
                  inactiveThumbColor: _kRed, inactiveTrackColor: _kRedBd,
                  onChanged: (v) async {
                    try {
                      final u = p.copyWith(status: v ? 'active' : 'inactive');
                      await ref.read(productControllerProvider.notifier).updateProduct(widget.productId, u);
                      ref.invalidate(productByIdProvider(widget.productId));
                      _snack('Status updated to ${v ? 'Active' : 'Inactive'}', _kGreen);
                    } catch (e) { _snack('Failed: $e', _kRed); }
                  })),
        ]));
  }

  // ── Stock ───────────────────────────────────────────────────────────────
  Widget _stockCard(double sw, double sh, ProductModel p, bool active) {
    final isBattery = (p.productCategory ?? '').toUpperCase() == 'BATTERY';

    return _Section(sw: sw, icon: Icons.inventory_outlined, iconBg: _kAmberBg,
        iconColor: _kAmber, title: 'Stock Information',
        trailing: active ? RoleGuard(feature: AppFeature.updateStock,
            child: _ActionPill(sw: sw, label: 'Update', color: _kP, bg: _kPBg, bd: _kPBd,
                onTap: () => _showStockSheet(context, sw, sh, p))) : null,
        child: Row(children: [
          Expanded(child: _StockTile(sw: sw, label: 'Packed', value: p.packedStock ?? 0,
              icon: Icons.check_box_outlined, color: _kP)),
          if (!isBattery) ...[
            SizedBox(width: sw * 0.03),
            Expanded(child: _StockTile(sw: sw, label: 'Unpacked', value: p.unpackedStock ?? 0,
                icon: Icons.indeterminate_check_box_outlined, color: _kAmber)),
          ],
          SizedBox(width: sw * 0.03),
          Expanded(child: _StockTile(sw: sw, label: 'Total', value: p.availableStock ?? 0,
              icon: Icons.all_inbox_rounded, color: _kGreen)),
        ]));
  }

  // ── Pricing ─────────────────────────────────────────────────────────────
  Widget _priceCard(double sw, double sh, ProductModel p) {
    return _Section(
      sw: sw, icon: Icons.payments_outlined, iconBg: _kGreenBg,
      iconColor: _kGreen, title: 'Pricing',
      trailing: RoleGuard(
        feature: AppFeature.updatePrice,
        child: GestureDetector(
          onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => ProductPriceHistory(history: p.priceHistory ?? []))),
          child: Container(
              padding: EdgeInsets.all((sw * 0.02).clamp(6.0, 10.0)),
              decoration: BoxDecoration(color: _kBg,
                  borderRadius: BorderRadius.circular((sw * 0.02).clamp(6.0, 10.0)),
                  border: Border.all(color: _kBd, width: 0.5)),
              child: Icon(Icons.history_rounded, size: (sw * 0.038).clamp(13.0, 17.0), color: _kT4)),
        ),
      ),
      child: _PricingTiles(
        key: ValueKey('${p.productId}_${p.updatedAt}'),
        sw: sw, p: p,
        onEditPrice: () => _showPriceSheet(context, sw, p),
        onEditCost: () => _showCostSheet(context, sw, p),
      ),
    );
  }

  void _showCostSheet(BuildContext ctx, double sw, ProductModel p) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => _EditCostSheet(
        product: p,
        onSave: (cost) async {
          try {
            await ref.read(productControllerProvider.notifier)
                .updateProduct(widget.productId, p.copyWith(cost: cost));
            ref.invalidate(productByIdProvider(widget.productId));
            _snack('Cost updated', _kGreen);
          } catch (e) { _snack('Failed: $e', _kRed); }
        },
      ),
    );
  }

  // ── Creator ─────────────────────────────────────────────────────────────
  Widget _creatorCard(double sw, double sh, UserModel? user) {
    final init = user != null ? (user.employeeName ?? 'U')[0].toUpperCase() : '?';
    return _Section(sw: sw, icon: Icons.person_outline_rounded, iconBg: _kBg,
        iconColor: _kT1, title: 'Created By',
        child: user == null
            ? Text('Creator info not available', style: TextStyle(
            fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4))
            : Row(children: [
          CircleAvatar(radius: (sw * 0.06).clamp(22.0, 30.0), backgroundColor: _kPBg,
              child: Text(init, style: TextStyle(
                  fontSize: (sw * 0.04).clamp(14.0, 20.0), fontWeight: FontWeight.w800, color: _kP))),
          SizedBox(width: sw * 0.035),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.employeeName ?? 'Unknown', style: TextStyle(
                fontSize: (sw * 0.036).clamp(12.0, 16.0), fontWeight: FontWeight.w700, color: _kT1)),
            SizedBox(height: sw * 0.006),
            Text(user.employeeEmail ?? '', style: TextStyle(
                fontSize: (sw * 0.029).clamp(10.0, 13.0), color: _kP, fontWeight: FontWeight.w500)),
            SizedBox(height: sw * 0.006),
            _Pill(sw: sw,
                label: (user.role ?? '').replaceAll('ROLE_', '').replaceAll('_', ' ').toLowerCase(),
                fg: _kP, bg: _kPBg, bd: _kPBd),
          ])),
        ]));
  }

  // ── Date row ────────────────────────────────────────────────────────────
  Widget _dateRow(double sw, double sh, ProductModel p) {
    return Row(children: [
      Expanded(child: _DateTile(sw: sw, label: 'Created', icon: Icons.calendar_today_outlined, date: p.createdAt)),
      SizedBox(width: sw * 0.025),
      Expanded(child: _DateTile(sw: sw, label: 'Updated', icon: Icons.update_rounded, date: p.updatedAt)),
    ]);
  }

  // ── Sheets ──────────────────────────────────────────────────────────────
  void _showEditSheet(BuildContext ctx, double sw, ProductModel p) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => _EditProductSheet(
        product: p,
        onSave: (name, category) async {  // ← now receives category too
          try {
            await ref.read(productControllerProvider.notifier)
                .updateProduct(widget.productId, p.copyWith(productName: name, productCategory: category));
            ref.invalidate(productByIdProvider(widget.productId));
            _snack('Product updated', _kGreen);
          } catch (e) { _snack('Failed: $e', _kRed); }
        },
      ),
    );
  }

  void _showPriceSheet(BuildContext ctx, double sw, ProductModel p) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: _kWhite,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
        builder: (_) => _EditPriceSheet(product: p, onSave: (price) async {
          try {
            await ref.read(productControllerProvider.notifier)
                .updateProduct(widget.productId, p.copyWith(price: price));
            ref.invalidate(productByIdProvider(widget.productId));
            _snack('Price updated', _kGreen);
          } catch (e) { _snack('Failed: $e', _kRed); }
        }));
  }

  void _showStockSheet(BuildContext ctx, double sw, double sh, ProductModel p) {
    showModalBottomSheet(
      context: ctx, isScrollControlled: true, backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => _UpdateStockSheet(
        product: p,
        onSave: (packed, unpacked, notes) async {
          try {
            List<StockItem> items = [];
            if (unpacked > 0) {
              items.add(StockItem(stock: unpacked, stockType: "UNPACKED",
                type: "ADD", stockNotes: notes.isEmpty ? null : notes));
            }
            if (packed > 0) {
              items.add(StockItem(stock: packed, stockType: "PACKED",
                type: "ADD", stockNotes: notes.isEmpty ? null : notes));
            }
            await ref.read(productControllerProvider.notifier)
                .updateStock(StockUpdate(stockMap: {widget.productId: items}));
            ref.invalidate(productByIdProvider(widget.productId));
            _snack('Stock updated', _kGreen);
          } catch (e) { _snack('Failed: $e', _kRed); }
        },
      ),
    );
  }
}
class _PricingTiles extends StatefulWidget {
  final double sw;
  final ProductModel p;
  final VoidCallback onEditPrice;
  final VoidCallback onEditCost;

  const _PricingTiles({
    super.key,
    required this.sw, required this.p,
    required this.onEditPrice, required this.onEditCost,
  });

  @override State<_PricingTiles> createState() => _PricingTilesState();
}

class _PricingTilesState extends State<_PricingTiles> {
  bool _costVisible = false;

  @override Widget build(BuildContext context) {
    final sw = widget.sw;
    final p = widget.p;

    return Column(children: [
      // ── Selling Price ────────────────────────────────────────────────
      Container(
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(color: _kGreenBg,
            borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
            border: Border.all(color: _kGreenBd, width: 0.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Selling Price', style: TextStyle(
                fontSize: (sw * 0.028).clamp(9.5, 12.5), fontWeight: FontWeight.w600, color: _kGreen)),
            Text('₹${p.price ?? '0.00'}', style: TextStyle(
                fontSize: (sw * 0.048).clamp(16.0, 22.0), fontWeight: FontWeight.w900, color: _kGreen)),
          ]),
          RoleGuard(
            feature: AppFeature.updatePrice,
            child: GestureDetector(
              onTap: widget.onEditPrice,
              child: Container(
                padding: EdgeInsets.all((sw * 0.022).clamp(7.0, 11.0)),
                decoration: BoxDecoration(
                    color: _kGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular((sw * 0.022).clamp(6.0, 10.0))),
                child: Icon(Icons.edit_outlined, color: _kGreen,
                    size: (sw * 0.045).clamp(15.0, 20.0)),
              ),
            ),
          ),
        ]),
      ),
      SizedBox(height: sw * 0.03),

      // ── Cost Price ───────────────────────────────────────────────────
      Container(
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(color: _kAmberBg,
            borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
            border: Border.all(color: _kAmberBd, width: 0.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Cost Price', style: TextStyle(
                fontSize: (sw * 0.028).clamp(9.5, 12.5), fontWeight: FontWeight.w600, color: _kAmber)),
            // ── Masked or real value ──────────────────────────────────
            _costVisible
                ? Text('₹${p.cost ?? '0.00'}', style: TextStyle(
                fontSize: (sw * 0.048).clamp(16.0, 22.0), fontWeight: FontWeight.w900, color: _kAmber))
                : Text('₹ ••••••', style: TextStyle(
                fontSize: (sw * 0.048).clamp(16.0, 22.0), fontWeight: FontWeight.w900, color: _kAmber,
                letterSpacing: 2)),
          ]),
          Row(mainAxisSize: MainAxisSize.min, children: [
            // ── Eye toggle ────────────────────────────────────────────
            GestureDetector(
              onTap: () => setState(() => _costVisible = !_costVisible),
              child: Container(
                padding: EdgeInsets.all((sw * 0.022).clamp(7.0, 11.0)),
                decoration: BoxDecoration(
                    color: _kAmber.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular((sw * 0.022).clamp(6.0, 10.0))),
                child: Icon(
                    _costVisible ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                    color: _kAmber, size: (sw * 0.045).clamp(15.0, 20.0)),
              ),
            ),
            SizedBox(width: sw * 0.02),
            // ── Edit ──────────────────────────────────────────────────
            RoleGuard(
              feature: AppFeature.updatePrice,
              child: GestureDetector(
                onTap: widget.onEditCost,
                child: Container(
                  padding: EdgeInsets.all((sw * 0.022).clamp(7.0, 11.0)),
                  decoration: BoxDecoration(
                      color: _kAmber.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular((sw * 0.022).clamp(6.0, 10.0))),
                  child: Icon(Icons.edit_outlined, color: _kAmber,
                      size: (sw * 0.045).clamp(15.0, 20.0)),
                ),
              ),
            ),
          ]),
        ]),
      ),
    ]);
  }
}
// ═════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═════════════════════════════════════════════════════════════════════════════
class _EditCostSheet extends StatefulWidget {
  final ProductModel product;
  final Future<void> Function(double cost) onSave;
  const _EditCostSheet({required this.product, required this.onSave});
  @override State<_EditCostSheet> createState() => _EditCostSheetState();
}

class _EditCostSheetState extends State<_EditCostSheet> {
  late final TextEditingController _ctrl;
  final _key = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.product.cost?.toString() ?? '');
  }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
        child: Form(key: _key, child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Handle(),
            Text('Edit Cost Price', style: TextStyle(
                fontSize: (sw * 0.045).clamp(15.0, 21.0), fontWeight: FontWeight.w800, color: _kT1)),
            Text(widget.product.productName ?? '', style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
            SizedBox(height: sw * 0.05),
            _sheetLabel(sw, 'Cost Price (₹)'),
            SizedBox(height: sh * 0.006),
            TextFormField(
              controller: _ctrl,
              keyboardType: TextInputType.number,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                if (double.tryParse(v) == null) return 'Enter valid number';
                if (double.parse(v) < 0) return 'Cannot be negative';
                return null;
              },
              decoration: _sheetDeco(sw, 'Enter cost price', Icons.currency_rupee),
            ),
            SizedBox(height: sh * 0.025),
            _sheetActions(sw, sh, saving: _saving,
              onCancel: () => Navigator.pop(context),
              onSave: () async {
                if (!_key.currentState!.validate()) return;
                setState(() => _saving = true);
                Navigator.pop(context);
                await widget.onSave(double.parse(_ctrl.text.trim()));
              },
            ),
          ],
        )),
      ),
    );
  }
}
class _Card extends StatelessWidget {
  const _Card({required this.sw, required this.child});
  final double sw; final Widget child;
  @override Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(color: _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
          border: Border.all(color: _kBd, width: 0.5)),
      child: child);
}

class _Section extends StatelessWidget {
  const _Section({required this.sw, required this.icon, required this.iconBg,
    required this.iconColor, required this.title, required this.child, this.trailing});
  final double sw; final IconData icon; final Color iconBg, iconColor;
  final String title; final Widget child; final Widget? trailing;

  @override Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(color: _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
          border: Border.all(color: _kBd, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(children: [
              Container(width: (sw * 0.075).clamp(26.0, 36.0), height: (sw * 0.075).clamp(26.0, 36.0),
                  decoration: BoxDecoration(color: iconBg,
                      borderRadius: BorderRadius.circular((sw * 0.022).clamp(6.0, 10.0))),
                  child: Icon(icon, size: (sw * 0.04).clamp(14.0, 20.0), color: iconColor)),
              SizedBox(width: sw * 0.025),
              Expanded(child: Text(title, style: TextStyle(
                  fontSize: (sw * 0.035).clamp(12.0, 16.0), fontWeight: FontWeight.w700, color: _kT1))),
              if (trailing != null) trailing!,
            ])),
        Divider(height: 1, color: _kBd),
        Padding(padding: EdgeInsets.all(sw * 0.04), child: child),
      ]));
}

class _Pill extends StatelessWidget {
  const _Pill({required this.sw, required this.label, required this.fg,
    required this.bg, required this.bd});
  final double sw; final String label; final Color fg, bg, bd;
  @override Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.025).clamp(8.0, 12.0),
          vertical: (sw * 0.008).clamp(3.0, 5.0)),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: bd, width: 0.5)),
      child: Text(label, style: TextStyle(
          fontSize: (sw * 0.026).clamp(9.0, 11.5), fontWeight: FontWeight.w700, color: fg)));
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.sw, required this.label, required this.color,
    required this.bg, required this.bd, required this.onTap});
  final double sw; final String label; final Color color, bg, bd;
  final VoidCallback onTap;
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
      child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: (sw * 0.03).clamp(10.0, 14.0),
              vertical: (sw * 0.01).clamp(3.0, 6.0)),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bd, width: 0.5)),
          child: Text(label, style: TextStyle(
              fontSize: (sw * 0.03).clamp(10.0, 13.0), fontWeight: FontWeight.w700, color: color))));
}

class _StockTile extends StatelessWidget {
  const _StockTile({required this.sw, required this.label,
    required this.value, required this.icon, required this.color});
  final double sw; final String label; final int value;
  final IconData icon; final Color color;

  @override Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(vertical: sw * 0.03),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
          border: Border.all(color: color.withValues(alpha: 0.15), width: 0.5)),
      child: Column(children: [
        Icon(icon, color: color, size: (sw * 0.05).clamp(16.0, 22.0)),
        SizedBox(height: sw * 0.012),
        Text(value.toString(), style: TextStyle(
            fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w800, color: color)),
        Text(label, style: TextStyle(
            fontSize: (sw * 0.026).clamp(9.0, 11.5), color: _kT4, fontWeight: FontWeight.w500)),
      ]));
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.sw, required this.label,
    required this.icon, required this.date});
  final double sw; final String label; final IconData icon; final dynamic date;

  String _fmt(dynamic d) {
    if (d == null) return '—';
    try {
      final dt = d is String ? DateTime.parse(d) : d as DateTime;
      return DateFormat('MMM dd, yyyy\nHH:mm').format(dt);
    } catch (_) { return 'Invalid'; }
  }

  @override Widget build(BuildContext context) => Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(color: _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
          border: Border.all(color: _kBd, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: (sw * 0.035).clamp(12.0, 16.0), color: _kT4),
          SizedBox(width: sw * 0.015),
          Text(label, style: TextStyle(
              fontSize: (sw * 0.028).clamp(9.5, 12.5), color: _kT4, fontWeight: FontWeight.w600)),
        ]),
        SizedBox(height: sw * 0.015),
        Text(_fmt(date), style: TextStyle(
            fontSize: (sw * 0.03).clamp(10.0, 13.0), fontWeight: FontWeight.w600, color: _kT1)),
      ]));
}

// ═════════════════════════════════════════════════════════════════════════════
// Bottom sheets — logic unchanged, Zoho tokens
// ═════════════════════════════════════════════════════════════════════════════

class _Handle extends StatelessWidget {
  const _Handle();
  @override Widget build(BuildContext context) => Center(child: Container(
      width: 36, height: 4, margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(color: _kBd, borderRadius: BorderRadius.circular(2))));
}

InputDecoration _sheetDeco(double sw, String hint, IconData icon, {int maxLines = 1}) {
  final r = (sw * 0.028).clamp(8.0, 12.0);
  return InputDecoration(hintText: hint,
      hintStyle: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT4),
      prefixIcon: Icon(icon, color: _kT4, size: (sw * 0.045).clamp(15.0, 20.0)),
      filled: true, fillColor: _kBg,
      contentPadding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: maxLines > 1 ? sw * 0.035 : 0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kBd, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kBd, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kP, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kRed)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kRed, width: 1.5)));
}

Widget _sheetLabel(double sw, String text) => Text(text.toUpperCase(),
    style: TextStyle(fontSize: (sw * 0.028).clamp(9.5, 12.5),
        fontWeight: FontWeight.w700, color: _kT4, letterSpacing: 0.5));

Widget _sheetActions(double sw, double sh, {required bool saving,
  required VoidCallback onCancel, required VoidCallback onSave}) {
  return Row(children: [
    Expanded(child: OutlinedButton(onPressed: saving ? null : onCancel,
        style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: sh * 0.016),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: _kBd, width: 0.5)),
        child: Text('Cancel', style: TextStyle(
            fontSize: (sw * 0.036).clamp(12.0, 15.0), fontWeight: FontWeight.w700, color: _kT4)))),
    SizedBox(width: sw * 0.03),
    Expanded(flex: 2, child: ElevatedButton(onPressed: saving ? null : onSave,
        style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
            padding: EdgeInsets.symmetric(vertical: sh * 0.016),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
        child: saving
            ? SizedBox(width: (sw * 0.05).clamp(16.0, 22.0), height: (sw * 0.05).clamp(16.0, 22.0),
            child: const CircularProgressIndicator(color: _kWhite, strokeWidth: 2.5))
            : Text('Save Changes', style: TextStyle(
            fontSize: (sw * 0.036).clamp(12.0, 15.0), fontWeight: FontWeight.w700)))),
  ]);
}

// ── Edit product sheet ────────────────────────────────────────────────────
class _EditProductSheet extends StatefulWidget {
  final ProductModel product;
  final Future<void> Function(String name, String category) onSave; // ← updated signature
  const _EditProductSheet({required this.product, required this.onSave});
  @override State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  late final TextEditingController _ctrl;
  late String _selectedCategory;
  final _key = GlobalKey<FormState>();
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.product.productName);
    // Default to existing category, fallback to INVERTER
    _selectedCategory = widget.product.productCategory ?? 'INVERTER';
  }

  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
        child: Form(key: _key, child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _Handle(),
            Text('Edit Product', style: TextStyle(
                fontSize: (sw * 0.045).clamp(15.0, 21.0), fontWeight: FontWeight.w800, color: _kT1)),
            Text(widget.product.productName ?? '', style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
            SizedBox(height: sw * 0.05),

            // ── Product Name ────────────────────────────────────────────
            _sheetLabel(sw, 'Product Name'),
            SizedBox(height: sh * 0.006),
            TextFormField(
              controller: _ctrl,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              decoration: _sheetDeco(sw, 'Enter product name', Icons.label_outline_rounded),
            ),
            SizedBox(height: sh * 0.022),

            // ── Category Radio ──────────────────────────────────────────
            _sheetLabel(sw, 'Product Category'),
            SizedBox(height: sh * 0.008),
            Container(
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                border: Border.all(color: _kBd, width: 0.5),
              ),
              child: Row(children: [
                _CategoryRadioOption(
                  sw: sw,
                  label: 'INVERTER',
                  icon: Icons.bolt_outlined,
                  selected: _selectedCategory == 'INVERTER',
                  onTap: () => setState(() => _selectedCategory = 'INVERTER'),
                ),
                Container(width: 0.5, height: 52, color: _kBd),
                _CategoryRadioOption(
                  sw: sw,
                  label: 'BATTERY',
                  icon: Icons.battery_charging_full_outlined,
                  selected: _selectedCategory == 'BATTERY',
                  onTap: () => setState(() => _selectedCategory = 'BATTERY'),
                ),
              ]),
            ),
            SizedBox(height: sh * 0.025),

            _sheetActions(sw, sh, saving: _saving,
              onCancel: () => Navigator.pop(context),
              onSave: () async {
                if (!_key.currentState!.validate()) return;
                setState(() => _saving = true);
                Navigator.pop(context);
                await widget.onSave(_ctrl.text.trim(), _selectedCategory);
              },
            ),
          ],
        )),
      ),
    );
  }
}

// ── Radio option tile ─────────────────────────────────────────────────────
class _CategoryRadioOption extends StatelessWidget {
  final double sw;
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _CategoryRadioOption({
    required this.sw, required this.label, required this.icon,
    required this.selected, required this.onTap,
  });

  @override Widget build(BuildContext context) {
    return Expanded(child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: EdgeInsets.symmetric(vertical: (sw * 0.032).clamp(10.0, 14.0)),
        decoration: BoxDecoration(
          color: selected ? _kPBg : Colors.transparent,
          borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
          border: Border.all(color: selected ? _kP : Colors.transparent, width: 1.5),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(icon, size: (sw * 0.042).clamp(14.0, 18.0), color: selected ? _kP : _kT4),
          SizedBox(width: sw * 0.02),
          Text(label, style: TextStyle(
            fontSize: (sw * 0.032).clamp(11.0, 14.0),
            fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            color: selected ? _kP : _kT4,
          )),
          SizedBox(width: sw * 0.015),
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: (sw * 0.038).clamp(13.0, 17.0),
            height: (sw * 0.038).clamp(13.0, 17.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? _kP : Colors.transparent,
              border: Border.all(color: selected ? _kP : _kT4, width: 1.5),
            ),
            child: selected
                ? Icon(Icons.check_rounded, size: (sw * 0.024).clamp(8.0, 11.0), color: _kWhite)
                : null,
          ),
        ]),
      ),
    ));
  }
}

// ── Edit price sheet ──────────────────────────────────────────────────────
class _EditPriceSheet extends StatefulWidget {
  final ProductModel product;
  final Future<void> Function(double price) onSave;
  const _EditPriceSheet({required this.product, required this.onSave});
  @override State<_EditPriceSheet> createState() => _EditPriceSheetState();
}

class _EditPriceSheetState extends State<_EditPriceSheet> {
  late final TextEditingController _ctrl;
  final _key = GlobalKey<FormState>();
  bool _saving = false;

  @override void initState() { super.initState(); _ctrl = TextEditingController(text: widget.product.price?.toString() ?? ''); }
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
            child: Form(key: _key, child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Handle(),
                  Text('Edit Price', style: TextStyle(
                      fontSize: (sw * 0.045).clamp(15.0, 21.0), fontWeight: FontWeight.w800, color: _kT1)),
                  Text(widget.product.productName ?? '', style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
                  SizedBox(height: sw * 0.05),
                  _sheetLabel(sw, 'Price (₹)'),
                  SizedBox(height: sh * 0.006),
                  TextFormField(controller: _ctrl, keyboardType: TextInputType.number,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) return 'Required';
                        if (double.tryParse(v) == null) return 'Enter valid number';
                        if (double.parse(v) < 0) return 'Cannot be negative';
                        return null;
                      },
                      decoration: _sheetDeco(sw, 'Enter price', Icons.currency_rupee)),
                  SizedBox(height: sh * 0.025),
                  _sheetActions(sw, sh, saving: _saving,
                      onCancel: () => Navigator.pop(context),
                      onSave: () async {
                        if (!_key.currentState!.validate()) return;
                        setState(() => _saving = true);
                        Navigator.pop(context);
                        await widget.onSave(double.parse(_ctrl.text.trim()));
                      }),
                ]))));
  }
}

// ── Update stock sheet ────────────────────────────────────────────────────
class _UpdateStockSheet extends StatefulWidget {
  final ProductModel product;
  final Future<void> Function(int packed, int unpacked, String notes) onSave;
  const _UpdateStockSheet({required this.product, required this.onSave});
  @override State<_UpdateStockSheet> createState() => _UpdateStockSheetState();
}

class _UpdateStockSheetState extends State<_UpdateStockSheet> {
  final _packedCtrl   = TextEditingController();
  final _unpackedCtrl = TextEditingController();
  final _notesCtrl    = TextEditingController();
  bool _saving = false;

  // ← Derive from product category
  bool get _isBattery =>
      (widget.product.productCategory ?? '').toUpperCase() == 'BATTERY';

  @override void dispose() {
    _packedCtrl.dispose(); _unpackedCtrl.dispose(); _notesCtrl.dispose();
    super.dispose();
  }

  @override Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
        child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start, children: [
              const _Handle(),
              Text('Update Stock', style: TextStyle(
                  fontSize: (sw * 0.045).clamp(15.0, 21.0), fontWeight: FontWeight.w800, color: _kT1)),
              Text(widget.product.productName ?? '', style: TextStyle(
                  fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
              SizedBox(height: sw * 0.05),

              // ── Packed stock (always shown) ─────────────────────────────
              _sheetLabel(sw, 'Packed Stock to Add'),
              SizedBox(height: sh * 0.006),
              RoleGuard(feature: AppFeature.updatePackedStock,
                  child: TextFormField(controller: _packedCtrl, keyboardType: TextInputType.number,
                      style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
                      decoration: _sheetDeco(sw, 'Enter quantity', Icons.check_box_outlined))),

              // ── Unpacked stock (hidden for BATTERY) ─────────────────────
              if (!_isBattery) ...[
                SizedBox(height: sh * 0.015),
                _sheetLabel(sw, 'Unpacked Stock to Add'),
                SizedBox(height: sh * 0.006),
                RoleGuard(feature: AppFeature.updateUnpackedStock,
                    child: TextFormField(controller: _unpackedCtrl, keyboardType: TextInputType.number,
                        style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
                        decoration: _sheetDeco(sw, 'Enter quantity', Icons.indeterminate_check_box_outlined))),
              ],

              SizedBox(height: sh * 0.015),
              _sheetLabel(sw, 'Notes (Optional)'),
              SizedBox(height: sh * 0.006),
              TextFormField(controller: _notesCtrl, maxLines: 3,
                  style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
                  decoration: _sheetDeco(sw, 'Add notes', Icons.note_outlined, maxLines: 3)),
              SizedBox(height: sh * 0.025),

              _sheetActions(sw, sh, saving: _saving,
                onCancel: () => Navigator.pop(context),
                onSave: () async {
                  final packed   = int.tryParse(_packedCtrl.text) ?? 0;
                  // If BATTERY, unpacked is always 0
                  final unpacked = _isBattery ? 0 : (int.tryParse(_unpackedCtrl.text) ?? 0);
                  if (packed == 0 && unpacked == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                        content: Text('Enter at least one stock value'), backgroundColor: _kRed));
                    return;
                  }
                  setState(() => _saving = true);
                  Navigator.pop(context);
                  await widget.onSave(packed, unpacked, _notesCtrl.text.trim());
                },
              ),
            ]),
      ),
    );
  }
}

// ── Error screen ──────────────────────────────────────────────────────────
class _ErrorScreen extends ConsumerWidget {
  final String productId;
  const _ErrorScreen({required this.productId});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Scaffold(backgroundColor: _kBg,
        body: SafeArea(child: Column(children: [
          Container(color: _kWhite,
              padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
              child: Row(children: [
                CircularIconButton(icon: Icons.arrow_back_ios_rounded, onTap: () => Navigator.pop(context)),
                const Spacer(),
                Text('Product Details', style: TextStyle(
                    fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w700, color: _kT1)),
                const Spacer(),
                SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
              ])),
          Expanded(child: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Container(width: (sw * 0.18).clamp(60.0, 90.0), height: (sw * 0.18).clamp(60.0, 90.0),
                decoration: BoxDecoration(color: _kWhite, shape: BoxShape.circle,
                    border: Border.all(color: _kBd, width: 0.5)),
                child: Icon(Icons.wifi_off_rounded, size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4)),
            SizedBox(height: sh * 0.02),
            Text('No Connection', style: TextStyle(
                fontSize: (sw * 0.04).clamp(13.0, 18.0), fontWeight: FontWeight.w600, color: _kT2)),
            SizedBox(height: sh * 0.02),
            ElevatedButton(
                onPressed: () => ref.invalidate(productByIdProvider(productId)),
                style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
                    shape: const CircleBorder(), padding: const EdgeInsets.all(14), elevation: 0),
                child: const Icon(Icons.refresh_rounded)),
          ]))),
        ])));
  }
}