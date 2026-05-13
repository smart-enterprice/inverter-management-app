import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../model/product_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../controller/product_controller.dart';
import '../product_view.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF4F5F7);
const _kWhite    = Color(0xFFFFFFFF);
const _kBd       = Color(0xFFE5E7EB);
const _kBdLight  = Color(0xFFF0F1F3);
const _kT1       = Color(0xFF111827);
const _kT3       = Color(0xFF6B7280);
const _kT4       = Color(0xFF9CA3AF);
const _kGreen    = Color(0xFF0F6E56);
const _kGreenBg  = Color(0xFFEDFAF5);
const _kGreenBd  = Color(0xFF9FE0C5);
const _kRed      = Color(0xFFDC2626);
const _kRedBg    = Color(0xFFFEF2F2);
const _kRedBd    = Color(0xFFFECACA);
const _kOrange   = Color(0xFFEA580C);
const _kOrangeBg = Color(0xFFFFF7ED);
const _kOrangeBd = Color(0xFFFED7AA);

Color _sc(String? s) => s?.toLowerCase() == 'active' ? _kGreen : _kRed;
Color _sb(String? s) => s?.toLowerCase() == 'active' ? _kGreenBg : _kRedBg;
Color _sd(String? s) => s?.toLowerCase() == 'active' ? _kGreenBd : _kRedBd;

// ═════════════════════════════════════════════════════════════════════════════
class ProductsTabletView extends ConsumerStatefulWidget {
  const ProductsTabletView({super.key});
  @override
  ConsumerState<ProductsTabletView> createState() => _State();
}

class _State extends ConsumerState<ProductsTabletView> {
  final _ctrl       = TextEditingController();
  final _listScroll = ScrollController();
  Timer? _debounce;
  String  _q        = '';
  String? _status;      // null=All, 'active', 'inactive'
  String  _category = 'All';
  ProductModel? _sel;

  @override
  void initState() {
    super.initState();
    _listScroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _ctrl.dispose();
    _listScroll.removeListener(_onScroll);
    _listScroll.dispose();
    super.dispose();
  }

  void _onScroll() {
    final pos = _listScroll.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(productControllerProvider.notifier).fetchMoreProducts();
    }
  }

  Future<void> _applyFilters() async {
    final notifier = ref.read(productControllerProvider.notifier);
    notifier.setFilters(
      search:   _q.isEmpty ? null : _q,
      category: _category == 'All' ? null : _category,
      status:   _status,
      brands:   null,
    );
    await notifier.fetchProducts();
  }

  void _onSearchChanged(String v) {
    final trimmed = v.trim();
    setState(() { _q = trimmed; _sel = null; });
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _applyFilters();
    });
  }

  void _onSearchClear() {
    _debounce?.cancel();
    setState(() { _ctrl.clear(); _q = ''; _sel = null; });
    _applyFilters();
  }

  void _onStatusChange(String? v) {
    setState(() { _status = v; _sel = null; });
    _applyFilters();
  }

  void _onCategoryChange(String v) {
    setState(() { _category = v; _sel = null; });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final lw = (sw * 0.38).clamp(260.0, 420.0);

    final async$     = ref.watch(productControllerProvider);
    final pagination = ref.watch(productPaginationProvider);
    final hasMore    = pagination.hasMore;
    final isFiltering = pagination.isFiltering;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [

          // ── Top bar ──────────────────────────────────────────────────────
          _TopBar(
            sw: sw, sh: sh, ctrl: _ctrl, q: _q,
            onChanged: _onSearchChanged,
            onClear:   _onSearchClear,
          ),

          // ── Filter bar ───────────────────────────────────────────────────
          _FilterBar(
            sw: sw, sh: sh,
            status: _status, category: _category,
            onStatus:   _onStatusChange,
            onCategory: _onCategoryChange,
          ),

          // ── Split view ───────────────────────────────────────────────────
          Expanded(child: async$.when(
            loading: () => const Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2)),
            error:   (_, __) => const _ErrView(),
            data: (products) {
              // Don't auto-select while a filter is in flight — the products
              // list still holds OLD data, so picking products.first here
              // would pin a stale item until the user taps the left list.
              if (!isFiltering && _sel == null && products.isNotEmpty) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted && _sel == null) setState(() => _sel = products.first);
                });
              }
              return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

                // LEFT — product list
                SizedBox(
                  width: lw,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: _kWhite,
                      border: Border(right: BorderSide(color: _kBd, width: 0.5)),
                    ),
                    child: Stack(children: [
                      if (products.isEmpty && !isFiltering)
                        _EmptyLeft(sw: lw)
                      else
                        ListView.builder(
                          controller: _listScroll,
                          physics: const AlwaysScrollableScrollPhysics(),
                          padding: EdgeInsets.only(top: sh * 0.008),
                          itemCount: products.length + (hasMore ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == products.length) {
                              return Padding(
                                padding: EdgeInsets.symmetric(vertical: sh * 0.02),
                                child: const Center(
                                  child: SizedBox(
                                    width: 20, height: 20,
                                    child: CircularProgressIndicator(
                                        color: _kP, strokeWidth: 2),
                                  ),
                                ),
                              );
                            }
                            return _ProductRow(
                              product:  products[i],
                              selected: _sel?.productId == products[i].productId,
                              lw: lw,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() => _sel = products[i]);
                              },
                            );
                          },
                        ),
                      if (isFiltering)
                        Positioned.fill(
                          child: IgnorePointer(
                            child: Container(
                              color: _kWhite.withValues(alpha: 0.65),
                              child: const Center(
                                child: SizedBox(
                                  width: 24, height: 24,
                                  child: CircularProgressIndicator(
                                      color: _kP, strokeWidth: 2.2),
                                ),
                              ),
                            ),
                          ),
                        ),
                    ]),
                  ),
                ),

                // RIGHT — detail (refreshes with the left during filter changes)
                Expanded(
                  child: isFiltering
                      ? const Center(
                          child: SizedBox(
                            width: 24, height: 24,
                            child: CircularProgressIndicator(
                                color: _kP, strokeWidth: 2.2),
                          ),
                        )
                      : _sel == null
                          ? _EmptyRight(rw: sw - lw)
                          : _DetailCard(
                              product: _sel!,
                              rw: sw - lw, sh: sh,
                              onOpen: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) =>
                                      ProductDetailsScreen(productId: _sel!.productId ?? ''))),
                            ),
                ),
              ]);
            },
          )),
        ]),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({required this.sw, required this.sh, required this.ctrl,
    required this.q, required this.onChanged, required this.onClear});
  final double sw, sh;
  final TextEditingController ctrl;
  final String q;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Container(
    height: (sh * 0.085).clamp(52.0, 64.0),
    decoration: const BoxDecoration(
      color: _kWhite,
      border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
    ),
    padding: EdgeInsets.symmetric(horizontal: sw * 0.02),
    child: Row(children: [
      CircularIconButton(
          icon: Icons.arrow_back_ios_rounded,
          onTap: () => Navigator.pop(context)),
      SizedBox(width: sw * 0.016),
      Text('Products', style: TextStyle(
        fontSize: (sw * 0.022).clamp(16.0, 20.0),
        fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.3,
      )),
      SizedBox(width: sw * 0.02),
      Expanded(child: _SearchField(ctrl: ctrl, sw: sw, sh: sh,
          hint: 'Search products…', onChanged: onChanged, onClear: onClear)),
    ]),
  );
}

// ── Filter bar ────────────────────────────────────────────────────────────────
class _FilterBar extends StatelessWidget {
  const _FilterBar({required this.sw, required this.sh,
    required this.status, required this.category,
    required this.onStatus, required this.onCategory});
  final double sw, sh;
  final String? status;
  final String category;
  final ValueChanged<String?> onStatus;
  final ValueChanged<String>  onCategory;

  @override
  Widget build(BuildContext context) => Container(
    height: (sh * 0.058).clamp(38.0, 48.0),
    decoration: const BoxDecoration(
      color: _kWhite,
      border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
    ),
    padding: EdgeInsets.symmetric(horizontal: sw * 0.02),
    child: Row(children: [
      // Status chips
      _Chip(label: 'All',      active: status == null,       onTap: () => onStatus(null)),
      const SizedBox(width: 6),
      _Chip(label: 'Active',   active: status == 'active',   onTap: () => onStatus('active')),
      const SizedBox(width: 6),
      _Chip(label: 'Inactive', active: status == 'inactive', onTap: () => onStatus('inactive')),
      Container(width: 1, height: 20, color: _kBd, margin: const EdgeInsets.symmetric(horizontal: 12)),
      // Category chips
      _Chip(label: 'All',      active: category == 'All',      onTap: () => onCategory('All')),
      const SizedBox(width: 6),
      _Chip(label: 'Battery',  active: category == 'BATTERY',  onTap: () => onCategory('BATTERY')),
      const SizedBox(width: 6),
      _Chip(label: 'Inverter', active: category == 'INVERTER', onTap: () => onCategory('INVERTER')),
    ]),
  );
}

// ── Product list row ──────────────────────────────────────────────────────────
class _ProductRow extends StatelessWidget {
  const _ProductRow({required this.product, required this.selected,
    required this.lw, required this.onTap});
  final ProductModel product;
  final bool selected;
  final double lw;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cat = (product.productCategory ?? '').toUpperCase();
    final Color catBg, catBd, catFg;
    final IconData? catIcon;
    if (cat == 'INVERTER') {
      catBg = _kOrangeBg; catBd = _kOrangeBd; catFg = _kOrange;
      catIcon = Icons.bolt_rounded;
    } else if (cat == 'BATTERY') {
      catBg = _kPBg; catBd = _kPBd; catFg = _kP;
      catIcon = Icons.battery_charging_full_rounded;
    } else {
      catBg = _kRedBg; catBd = _kRedBd; catFg = _kRed;
      catIcon = null;
    }
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        decoration: BoxDecoration(
          color: selected ? _kPBg : _kWhite,
          border: Border(
            left:   BorderSide(color: selected ? _kP : Colors.transparent, width: 3),
            bottom: const BorderSide(color: _kBdLight, width: 0.5),
          ),
        ),
        padding: EdgeInsets.symmetric(horizontal: lw * 0.06, vertical: 11),
        child: Row(children: [
          // Category icon box
          Container(
            width: 34, height: 34,
            decoration: BoxDecoration(
              color: catBg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: catBd, width: 0.5),
            ),
            child: catIcon == null
                ? null
                : Icon(catIcon, size: 16, color: catFg),
          ),
          SizedBox(width: lw * 0.04),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(product.productName ?? 'N/A', style: TextStyle(
              fontSize: (lw * 0.042).clamp(12.0, 14.0),
              fontWeight: FontWeight.w700,
              color: selected ? _kP : _kT1,
            ), maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Text('${product.brand ?? '—'}  ·  ${product.model ?? '—'}',
                style: TextStyle(
                  fontSize: (lw * 0.032).clamp(9.5, 11.0),
                  color: _kT4, fontWeight: FontWeight.w500,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
          ])),
          const SizedBox(width: 8),
          _StatusBadge(status: product.status),
        ]),
      ),
    );
  }
}

// ── Detail card ───────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.product, required this.rw,
    required this.sh, required this.onOpen});
  final ProductModel product;
  final double rw, sh;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final pad = (rw * 0.06).clamp(18.0, 32.0);
    final cat = (product.productCategory ?? '').toUpperCase();
    final Color catBg, catBd, catFg;
    final IconData? catIcon;
    if (cat == 'INVERTER') {
      catBg = _kOrangeBg; catBd = _kOrangeBd; catFg = _kOrange;
      catIcon = Icons.bolt_rounded;
    } else if (cat == 'BATTERY') {
      catBg = _kPBg; catBd = _kPBd; catFg = _kP;
      catIcon = Icons.battery_charging_full_rounded;
    } else {
      catBg = _kRedBg; catBd = _kRedBd; catFg = _kRed;
      catIcon = null;
    }
    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Header card ───────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: _kWhite, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBd, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: EdgeInsets.all(pad),
              decoration: const BoxDecoration(
                color: Color(0xFFF8F9FB),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(10), topRight: Radius.circular(10)),
                border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
              ),
              child: Row(children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: catBg, borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: catBd, width: 0.5),
                  ),
                  child: catIcon == null
                      ? null
                      : Icon(catIcon, size: 20, color: catFg),
                ),
                SizedBox(width: pad * 0.6),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(product.productName ?? 'N/A', style: TextStyle(
                    fontSize: (rw * 0.032).clamp(15.0, 20.0),
                    fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.2,
                  ), maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  if ((product.brand ?? '').isNotEmpty)
                    Text(product.brand!, style: const TextStyle(
                        fontSize: 12, color: _kT3, fontWeight: FontWeight.w500)),
                ])),
                _StatusBadge(status: product.status),
              ]),
            ),

            // ── Product details section ────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad * 0.6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('PRODUCT INFORMATION'),
                const SizedBox(height: 8),
                if ((product.brand ?? '').isNotEmpty) ...[
                  _InfoRow(icon: Icons.business_outlined, label: 'Brand', value: product.brand!),
                  const _Divider(),
                ],
                if ((product.model ?? '').isNotEmpty) ...[
                  _InfoRow(icon: Icons.tag_outlined, label: 'Model', value: product.model!),
                  const _Divider(),
                ],
                if ((product.productCategory ?? '').isNotEmpty) ...[
                  _InfoRow(icon: Icons.category_outlined, label: 'Category', value: product.productCategory!),
                  const _Divider(),
                ],
                if ((product.productType ?? '').isNotEmpty)
                  _InfoRow(icon: Icons.settings_outlined, label: 'Type', value: product.productType!),
              ]),
            ),

            const _Divider(),

            // ── Pricing & stock section ────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: pad, vertical: pad * 0.6),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                _SectionLabel('PRICING & INVENTORY'),
                const SizedBox(height: 8),
                if (product.price != null) ...[
                  _InfoRow(icon: Icons.currency_rupee_rounded,
                      label: 'Price', value: '₹${product.price}',
                      valueColor: _kGreen),
                  const _Divider(),
                ],
                _InfoRow(icon: Icons.inventory_2_outlined,
                    label: 'Stock', value: '${product.availableStock ?? 0} units',
                    valueColor: (product.availableStock ?? 0) > 0 ? null : _kRed),
              ]),
            ),
          ]),
        ),

        SizedBox(height: pad * 0.7),

        // ── Action button ─────────────────────────────────────────────────
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.open_in_new_rounded, size: 15),
            label: const Text('View Full Details',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kP, foregroundColor: _kWhite,
              padding: const EdgeInsets.symmetric(vertical: 13),
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
          ),
        ),
      ]),
    );
  }
}

// ── Shared small widgets ──────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(text, style: const TextStyle(
    fontSize: 10.5, fontWeight: FontWeight.w700, color: _kT4, letterSpacing: 0.8,
  ));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label,
    required this.value, this.valueColor});
  final IconData icon; final String label, value; final Color? valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 10),
    child: Row(children: [
      Icon(icon, size: 14, color: _kT4),
      const SizedBox(width: 10),
      SizedBox(
        width: 90,
        child: Text(label, style: const TextStyle(
          fontSize: 12, color: _kT3, fontWeight: FontWeight.w500)),
      ),
      Expanded(child: Text(value, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: valueColor ?? _kT1,
      ), textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String? status;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
    decoration: BoxDecoration(
      color: _sb(status), borderRadius: BorderRadius.circular(4),
      border: Border.all(color: _sd(status), width: 0.5),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Container(width: 5, height: 5,
          decoration: BoxDecoration(color: _sc(status), shape: BoxShape.circle)),
      const SizedBox(width: 5),
      Text(status ?? '', style: TextStyle(
        fontSize: 10.5, fontWeight: FontWeight.w700, color: _sc(status), height: 1.0,
      )),
    ]),
  );
}

class _Chip extends StatelessWidget {
  const _Chip({required this.label, required this.active, required this.onTap});
  final String label; final bool active; final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 120),
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 5),
      decoration: BoxDecoration(
        color: active ? _kPBg : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(color: active ? _kPBd : Colors.transparent, width: 0.5),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 11.5, fontWeight: active ? FontWeight.w700 : FontWeight.w500,
        color: active ? _kP : _kT3,
      )),
    ),
  );
}

class _SearchField extends StatelessWidget {
  const _SearchField({required this.ctrl, required this.sw, required this.sh,
    required this.hint, required this.onChanged, required this.onClear});
  final TextEditingController ctrl;
  final double sw, sh;
  final String hint;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: (sh * 0.052).clamp(34.0, 42.0),
    child: TextField(
      controller: ctrl,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 13, color: _kT1),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12.5, color: _kT4),
        prefixIcon: const Icon(Icons.search_rounded, size: 18, color: _kT4),
        suffixIcon: ctrl.text.isNotEmpty
            ? IconButton(icon: const Icon(Icons.close_rounded, size: 16, color: _kT4),
            onPressed: onClear) : null,
        filled: true, fillColor: const Color(0xFFF9FAFB),
        contentPadding: EdgeInsets.zero,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(7),
            borderSide: const BorderSide(color: _kP, width: 1.5)),
      ),
    ),
  );
}

class _Divider extends StatelessWidget {
  const _Divider();
  @override
  Widget build(BuildContext context) =>
      const Divider(height: 1, thickness: 0.5, color: _kBdLight);
}

// ── Empty / error states ──────────────────────────────────────────────────────
class _EmptyLeft extends StatelessWidget {
  const _EmptyLeft({required this.sw});
  final double sw;
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.search_off_rounded, size: (sw * 0.12).clamp(32.0, 48.0), color: _kT4),
      const SizedBox(height: 10),
      Text('No products found', style: TextStyle(
        fontSize: (sw * 0.036).clamp(12.0, 14.0), color: _kT3, fontWeight: FontWeight.w500)),
    ],
  ));
}

class _EmptyRight extends StatelessWidget {
  const _EmptyRight({required this.rw});
  final double rw;
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Container(
        width: 56, height: 56,
        decoration: BoxDecoration(
          color: _kPBg, shape: BoxShape.circle,
          border: Border.all(color: _kPBd, width: 0.5),
        ),
        child: const Icon(Icons.inventory_2_outlined, size: 26, color: _kP),
      ),
      const SizedBox(height: 12),
      Text('Select a product', style: TextStyle(
        fontSize: (rw * 0.022).clamp(12.0, 15.0), color: _kT3, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      const Text('Tap a product on the left to see its details',
          style: TextStyle(fontSize: 11.5, color: _kT4)),
    ],
  ));
}

class _ErrView extends StatelessWidget {
  const _ErrView();
  @override
  Widget build(BuildContext context) => const Center(child: Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626), size: 20),
      SizedBox(width: 8),
      Text('Could not load products',
          style: TextStyle(color: Color(0xFFDC2626), fontWeight: FontWeight.w500)),
    ],
  ));
}
