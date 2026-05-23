import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/network/app_exception.dart';
import '../../../widgets/circle_button.dart';
import '../controller/order_controller.dart';
import '../model/production_summary_model.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Color(0xFFFFFFFF);
const _kBd       = Color(0xFFE5E7EB);
const _kBdLite   = Color(0xFFF3F4F6);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
const _kT3       = Color(0xFF6B7280);
const _kT4       = Color(0xFF9CA3AF);
const _kRed      = Color(0xFFDC2626);
const _kRedBg    = Color(0xFFFEF2F2);

// Status colors — match OrdersViewPage so users see the same hues
const _kProdFg = Color(0xFFEA580C);
const _kPackFg = Color(0xFF7C3AED);
const _kInvFg  = Color(0xFF4338CA);
const _kShipFg = Color(0xFF0369A1);

String _fmt(num n) => NumberFormat('#,##,###').format(n);

class ProductionSummaryScreen extends ConsumerStatefulWidget {
  const ProductionSummaryScreen({super.key});
  @override
  ConsumerState<ProductionSummaryScreen> createState() =>
      _ProductionSummaryScreenState();
}

class _ProductionSummaryScreenState
    extends ConsumerState<ProductionSummaryScreen> {
  final _searchCtrl = TextEditingController();
  String _q = '';
  final Set<String> _expanded = <String>{};
  bool _forbiddenHandled = false;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  List<ProductionSummaryRow> _filter(List<ProductionSummaryRow> rows) {
    if (_q.isEmpty) return rows;
    final q = _q.toLowerCase();
    return rows.where((r) =>
        r.productName.toLowerCase().contains(q) ||
        r.productBrand.toLowerCase().contains(q) ||
        r.productModel.toLowerCase().contains(q)).toList();
  }

  void _toggle(String productId) => setState(() {
    if (!_expanded.add(productId)) _expanded.remove(productId);
  });

  /// If the backend rejects this role (403), surface the message once and pop.
  void _handleForbidden(Object error) {
    if (_forbiddenHandled) return;
    if (error is! AppException || error.statusCode != 403) return;
    _forbiddenHandled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        backgroundColor: _kRed,
        behavior: SnackBarBehavior.floating,
        content: Text(error.message,
            style: const TextStyle(color: Colors.white)),
      ));
      Navigator.of(context).maybePop();
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final async$ = ref.watch(productionSummaryProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        // ── Top bar ────────────────────────────────────────────────────────
        Container(
          color: _kWhite,
          padding: EdgeInsets.fromLTRB(
              sw * 0.04, sh * 0.012, sw * 0.04, sh * 0.012),
          child: Row(children: [
            CircularIconButton(
              icon: Icons.arrow_back_ios_rounded,
              onTap: () => Navigator.pop(context),
            ),
            SizedBox(width: sw * 0.03),
            Expanded(child: Text('Production Summary', style: TextStyle(
              fontSize: (sw * 0.052).clamp(17.0, 26.0),
              fontWeight: FontWeight.w800, color: _kT1,
              letterSpacing: -0.4,
            ))),
            CircularIconButton(
              icon: Icons.refresh_rounded,
              size: 38,
              onTap: () => ref.invalidate(productionSummaryProvider),
            ),
          ]),
        ),
        Container(height: 0.5, color: _kBd),

        // ── Body ───────────────────────────────────────────────────────────
        Expanded(child: async$.when(
          loading: () => const Center(child: CircularProgressIndicator(
              color: _kP, strokeWidth: 2)),
          error: (e, _) {
            _handleForbidden(e);
            return _ErrorView(sw: sw, sh: sh,
                onRetry: () => ref.invalidate(productionSummaryProvider));
          },
          data: (allRows) {
            final rows = _filter(allRows);

            return RefreshIndicator(
              color: _kP, backgroundColor: _kWhite,
              onRefresh: () async {
                ref.invalidate(productionSummaryProvider);
                await Future.delayed(const Duration(milliseconds: 350));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  // Hero card
                  SliverToBoxAdapter(
                    child: _PipelineHero(
                      rows: rows,
                      totalProducts: allRows.length,
                      sw: sw, sh: sh,
                    ),
                  ),

                  // Search field
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: EdgeInsets.fromLTRB(
                          sw * 0.04, sh * 0.004, sw * 0.04, sh * 0.014),
                      child: _SearchField(
                        controller: _searchCtrl,
                        sw: sw, sh: sh,
                        onChanged: (v) => setState(() => _q = v.trim()),
                        onClear: () => setState(() {
                          _searchCtrl.clear();
                          _q = '';
                        }),
                      ),
                    ),
                  ),

                  if (rows.isNotEmpty)
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.fromLTRB(
                            sw * 0.045, sh * 0.004, sw * 0.04, sh * 0.008),
                        child: Row(children: [
                          Text('PRODUCTS', style: TextStyle(
                            fontSize: (sw * 0.026).clamp(9.0, 11.0),
                            color: _kT4, fontWeight: FontWeight.w600,
                            letterSpacing: 0.6,
                          )),
                          SizedBox(width: sw * 0.02),
                          Expanded(child: Container(
                              height: 0.5, color: _kBd)),
                          SizedBox(width: sw * 0.02),
                          Text(
                            _q.isEmpty
                                ? _fmt(rows.length)
                                : '${_fmt(rows.length)} / ${_fmt(allRows.length)}',
                            style: TextStyle(
                              fontSize: (sw * 0.028).clamp(9.5, 12.0),
                              color: _kT3, fontWeight: FontWeight.w600,
                            ),
                          ),
                        ]),
                      ),
                    ),

                  if (rows.isEmpty)
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: _EmptyView(
                          sw: sw, sh: sh,
                          isSearch: _q.isNotEmpty, query: _q),
                    )
                  else
                    SliverPadding(
                      padding: EdgeInsets.fromLTRB(
                          sw * 0.04, 0, sw * 0.04, sh * 0.04),
                      sliver: SliverList.separated(
                        itemCount: rows.length,
                        separatorBuilder: (_, __) =>
                            SizedBox(height: sh * 0.012),
                        itemBuilder: (_, i) {
                          final row = rows[i];
                          return _ProductCard(
                            row: row,
                            expanded: _expanded.contains(row.productId),
                            onTap: row.dealers.isEmpty
                                ? null
                                : () => _toggle(row.productId),
                            sw: sw, sh: sh,
                          );
                        },
                      ),
                    ),
                ],
              ),
            );
          },
        )),
      ])),
    );
  }
}

// ── Hero pipeline (top card) ──────────────────────────────────────────────────
class _PipelineHero extends StatelessWidget {
  const _PipelineHero({
    required this.rows,
    required this.totalProducts,
    required this.sw,
    required this.sh,
  });
  final List<ProductionSummaryRow> rows;
  final int totalProducts;
  final double sw, sh;

  @override
  Widget build(BuildContext context) {
    int prod = 0, pack = 0, inv = 0, ship = 0, total = 0;
    for (final r in rows) {
      prod  += r.production;
      pack  += r.packed;
      inv   += r.invoice;
      ship  += r.shipped;
      total += r.totalQty;
    }

    final shown = rows.length;
    final productsLine = shown == totalProducts
        ? '$totalProducts ${totalProducts == 1 ? "product" : "products"} in pipeline'
        : '$shown of $totalProducts products';

    return Padding(
      padding: EdgeInsets.fromLTRB(
          sw * 0.04, sh * 0.016, sw * 0.04, sh * 0.008),
      child: Container(
        padding: EdgeInsets.fromLTRB(
            sw * 0.045, sh * 0.02, sw * 0.045, sh * 0.018),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.04).clamp(12.0, 18.0)),
          border: Border.all(color: _kBd, width: 0.5),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text(_fmt(total), style: TextStyle(
              fontSize: (sw * 0.064).clamp(22.0, 32.0),
              fontWeight: FontWeight.w700, color: _kT1,
              letterSpacing: -0.5, height: 1.0,
            )),
            SizedBox(width: sw * 0.02),
            Padding(
              padding: EdgeInsets.only(bottom: sh * 0.005),
              child: Text('units', style: TextStyle(
                fontSize: (sw * 0.034).clamp(11.0, 14.5),
                color: _kT4, fontWeight: FontWeight.w600,
              )),
            ),
          ]),
          SizedBox(height: sh * 0.002),
          Text('active in pipeline · $productsLine', style: TextStyle(
            fontSize: (sw * 0.03).clamp(10.0, 13.0),
            color: _kT3, fontWeight: FontWeight.w500,
          )),

          SizedBox(height: sh * 0.016),

          Wrap(
            spacing: sw * 0.04,
            runSpacing: sh * 0.006,
            children: [
              _LegendItem(label: 'PROD', count: prod, color: _kProdFg, sw: sw),
              _LegendItem(label: 'PACK', count: pack, color: _kPackFg, sw: sw),
              _LegendItem(label: 'INV',  count: inv,  color: _kInvFg,  sw: sw),
              _LegendItem(label: 'SHIP', count: ship, color: _kShipFg, sw: sw),
            ],
          ),
        ]),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.label,
    required this.count,
    required this.color,
    required this.sw,
  });
  final String label;
  final int count;
  final Color color;
  final double sw;

  @override
  Widget build(BuildContext context) {
    final dim = count == 0;
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: (sw * 0.02).clamp(7.0, 9.0),
        height: (sw * 0.02).clamp(7.0, 9.0),
        decoration: BoxDecoration(
            color: dim ? _kT4 : color, shape: BoxShape.circle),
      ),
      SizedBox(width: sw * 0.018),
      Text(_fmt(count), style: TextStyle(
        fontSize: (sw * 0.034).clamp(11.0, 14.5),
        color: dim ? _kT4 : _kT1, fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
      )),
      SizedBox(width: sw * 0.012),
      Text(label, style: TextStyle(
        fontSize: (sw * 0.026).clamp(9.0, 11.5),
        color: dim ? _kT4 : _kT3, fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      )),
    ]);
  }
}

// ── Product card ──────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.row,
    required this.expanded,
    required this.onTap,
    required this.sw,
    required this.sh,
  });
  final ProductionSummaryRow row;
  final bool expanded;
  final VoidCallback? onTap;
  final double sw, sh;

  @override
  Widget build(BuildContext context) {
    final meta = _metaLine(row);
    final entries = _entries(row);
    final hasDealers = row.dealerCount > 0 && row.dealers.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _kWhite,
        borderRadius: BorderRadius.circular((sw * 0.035).clamp(10.0, 16.0)),
        border: Border.all(color: _kBd, width: 0.5),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // ── Header / tap area ─────────────────────────────────────────────
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular((sw * 0.035).clamp(10.0, 16.0)),
          child: Padding(
            padding: EdgeInsets.fromLTRB(
                sw * 0.038, sw * 0.038, sw * 0.038, sw * 0.03),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Expanded(child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(row.productName.isEmpty ? '—' : row.productName,
                          style: TextStyle(
                            fontSize: (sw * 0.038).clamp(13.0, 16.5),
                            fontWeight: FontWeight.w700, color: _kT1,
                            letterSpacing: -0.2,
                          ),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      if (meta.isNotEmpty) ...[
                        SizedBox(height: sh * 0.003),
                        Text(meta, style: TextStyle(
                          fontSize: (sw * 0.028).clamp(9.5, 12.0),
                          color: _kT4, fontWeight: FontWeight.w500,
                        ), maxLines: 1, overflow: TextOverflow.ellipsis),
                      ],
                    ],
                  )),
                  SizedBox(width: sw * 0.025),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(_fmt(row.totalQty), style: TextStyle(
                        fontSize: (sw * 0.038).clamp(12.5, 16.5),
                        fontWeight: FontWeight.w700, color: _kT2,
                        letterSpacing: -0.2,
                      )),
                      SizedBox(height: sh * 0.002),
                      Text('qty', style: TextStyle(
                        fontSize: (sw * 0.024).clamp(8.5, 10.5),
                        color: _kT4, fontWeight: FontWeight.w600,
                        letterSpacing: 0.4,
                      )),
                    ],
                  ),
                ]),
                if (entries.isNotEmpty) ...[
                  SizedBox(height: sh * 0.01),
                  Wrap(
                    spacing: sw * 0.04,
                    runSpacing: sh * 0.004,
                    children: entries
                        .map((e) => _CountInline(e: e, sw: sw))
                        .toList(),
                  ),
                ],
                if (hasDealers) ...[
                  SizedBox(height: sh * 0.012),
                  Row(children: [
                    Icon(Icons.storefront_outlined,
                        size: (sw * 0.034).clamp(12.0, 15.0), color: _kT4),
                    SizedBox(width: sw * 0.012),
                    Text(
                      '${row.dealerCount} ${row.dealerCount == 1 ? "dealer" : "dealers"}',
                      style: TextStyle(
                        fontSize: (sw * 0.028).clamp(9.5, 12.0),
                        color: _kT3, fontWeight: FontWeight.w600,
                      ),
                    ),
                    const Spacer(),
                    Icon(
                      expanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      size: (sw * 0.05).clamp(18.0, 22.0),
                      color: _kT3,
                    ),
                  ]),
                ],
              ],
            ),
          ),
        ),

        // ── Expanded dealer list ──────────────────────────────────────────
        if (expanded && hasDealers) ...[
          Container(height: 0.5, color: _kBdLite),
          for (var i = 0; i < row.dealers.length; i++) ...[
            if (i > 0) Container(height: 0.5, color: _kBdLite),
            _DealerRow(d: row.dealers[i], sw: sw, sh: sh),
          ],
        ],
      ]),
    );
  }

  String _metaLine(ProductionSummaryRow r) {
    final parts = [
      if (r.productBrand.isNotEmpty) r.productBrand,
      if (r.productModel.isNotEmpty) r.productModel,
    ];
    return parts.join(' · ');
  }

  List<_CountEntry> _entries(ProductionSummaryRow r) => [
    if (r.production > 0) _CountEntry('PROD', r.production, _kProdFg),
    if (r.packed     > 0) _CountEntry('PACK', r.packed,     _kPackFg),
    if (r.invoice    > 0) _CountEntry('INV',  r.invoice,    _kInvFg),
    if (r.shipped    > 0) _CountEntry('SHIP', r.shipped,    _kShipFg),
  ];
}

// ── Dealer row (inside expanded card) ─────────────────────────────────────────
class _DealerRow extends StatelessWidget {
  const _DealerRow({required this.d, required this.sw, required this.sh});
  final DealerProductionSummary d;
  final double sw, sh;

  @override
  Widget build(BuildContext context) {
    final entries = <_CountEntry>[
      if (d.production > 0) _CountEntry('PROD', d.production, _kProdFg),
      if (d.packed     > 0) _CountEntry('PACK', d.packed,     _kPackFg),
      if (d.invoice    > 0) _CountEntry('INV',  d.invoice,    _kInvFg),
      if (d.shipped    > 0) _CountEntry('SHIP', d.shipped,    _kShipFg),
    ];
    final shop = d.shopName.isEmpty ? null : d.shopName;
    final subParts = [
      if (d.town.isNotEmpty) d.town,
      if (d.employeePhone.isNotEmpty) d.employeePhone,
    ];

    return Padding(
      padding: EdgeInsets.fromLTRB(
          sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.012),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(d.dealerName.isEmpty ? '—' : d.dealerName,
                    style: TextStyle(
                      fontSize: (sw * 0.034).clamp(12.0, 14.5),
                      fontWeight: FontWeight.w600, color: _kT2,
                    ),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (shop != null) ...[
                  SizedBox(height: sh * 0.002),
                  Text(shop, style: TextStyle(
                    fontSize: (sw * 0.028).clamp(9.5, 12.0),
                    color: _kT3, fontWeight: FontWeight.w500,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
                if (subParts.isNotEmpty) ...[
                  SizedBox(height: sh * 0.002),
                  Text(subParts.join(' · '), style: TextStyle(
                    fontSize: (sw * 0.026).clamp(9.0, 11.0),
                    color: _kT4, fontWeight: FontWeight.w500,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            )),
            SizedBox(width: sw * 0.025),
            Text(_fmt(d.totalQty), style: TextStyle(
              fontSize: (sw * 0.034).clamp(11.5, 15.0),
              fontWeight: FontWeight.w700, color: _kT2,
              letterSpacing: -0.1,
            )),
          ]),
          if (entries.isNotEmpty) ...[
            SizedBox(height: sh * 0.008),
            Wrap(
              spacing: sw * 0.035,
              runSpacing: sh * 0.003,
              children: entries
                  .map((e) => _CountInline(e: e, sw: sw, small: true))
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Shared inline count chip ──────────────────────────────────────────────────
class _CountEntry {
  final String label;
  final int count;
  final Color color;
  const _CountEntry(this.label, this.count, this.color);
}

class _CountInline extends StatelessWidget {
  const _CountInline({required this.e, required this.sw, this.small = false});
  final _CountEntry e;
  final double sw;
  final bool small;

  @override
  Widget build(BuildContext context) {
    final dotSz = (sw * (small ? 0.014 : 0.016)).clamp(4.0, 7.0);
    final valSz = (sw * (small ? 0.026 : 0.028)).clamp(9.0, 12.0);
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: dotSz, height: dotSz,
        decoration: BoxDecoration(color: e.color, shape: BoxShape.circle),
      ),
      SizedBox(width: sw * 0.012),
      Text('${e.label} ${_fmt(e.count)}', style: TextStyle(
        fontSize: valSz,
        color: _kT2, fontWeight: FontWeight.w600,
        letterSpacing: 0.2, height: 1.1,
      )),
    ]);
  }
}

// ── Search field ──────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  const _SearchField({
    required this.controller,
    required this.sw,
    required this.sh,
    required this.onChanged,
    required this.onClear,
  });
  final TextEditingController controller;
  final double sw, sh;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final r = (sw * 0.025).clamp(8.0, 12.0);
    return TextField(
      controller: controller,
      onChanged: onChanged,
      style: TextStyle(
          fontSize: (sw * 0.035).clamp(12.0, 15.0), color: _kT1),
      decoration: InputDecoration(
        hintText: 'Search product, brand or model…',
        hintStyle: TextStyle(
            fontSize: (sw * 0.033).clamp(11.0, 14.0), color: _kT4),
        prefixIcon: Icon(Icons.search_rounded,
            color: _kP, size: (sw * 0.045).clamp(16.0, 20.0)),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                icon: Icon(Icons.close_rounded,
                    size: (sw * 0.04).clamp(14.0, 18.0), color: _kT3),
                onPressed: onClear,
              )
            : null,
        filled: true,
        fillColor: _kWhite,
        contentPadding: EdgeInsets.symmetric(vertical: sh * 0.012),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kP, width: 1.5)),
      ),
    );
  }
}

// ── Empty / Error ─────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView({
    required this.sw, required this.sh,
    required this.isSearch, required this.query,
  });
  final double sw, sh;
  final bool isSearch;
  final String query;

  @override
  Widget build(BuildContext context) {
    final circSz = (sw * 0.2).clamp(64.0, 96.0);
    return Center(child: Padding(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: circSz, height: circSz,
          decoration: const BoxDecoration(
              color: Color(0xFFF3F4F6), shape: BoxShape.circle),
          child: Icon(
              isSearch ? Icons.search_off_rounded : Icons.factory_outlined,
              size: (sw * 0.09).clamp(30.0, 44.0), color: _kBd),
        ),
        SizedBox(height: sh * 0.02),
        Text(isSearch ? 'No results for "$query"' : 'Nothing in production',
            style: TextStyle(
              fontSize: (sw * 0.038).clamp(13.0, 17.0),
              fontWeight: FontWeight.w600, color: _kT1,
            ),
            textAlign: TextAlign.center),
        SizedBox(height: sh * 0.008),
        Text(isSearch
                ? 'Try a different search term'
                : 'Units in PRODUCTION, PACKED, INVOICE or SHIPPED will appear here',
            style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4),
            textAlign: TextAlign.center),
      ]),
    ));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.sw, required this.sh, required this.onRetry,
  });
  final double sw, sh;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final circSz = (sw * 0.2).clamp(64.0, 96.0);
    return Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: circSz, height: circSz,
          decoration: const BoxDecoration(
              color: _kRedBg, shape: BoxShape.circle),
          child: Icon(Icons.wifi_off_rounded,
              size: (sw * 0.08).clamp(28.0, 42.0), color: _kRed),
        ),
        SizedBox(height: sh * 0.02),
        Text('No Connection', style: TextStyle(
          fontSize: (sw * 0.04).clamp(13.0, 18.0),
          fontWeight: FontWeight.w600, color: _kT1,
        )),
        SizedBox(height: sh * 0.025),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.05, vertical: sh * 0.012),
            decoration: BoxDecoration(
              color: _kPBg,
              borderRadius:
                  BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
              border: Border.all(color: _kPBd, width: 0.5),
            ),
            child: Text('Retry', style: TextStyle(
              fontSize: (sw * 0.033).clamp(11.0, 14.0),
              fontWeight: FontWeight.w600, color: _kP,
            )),
          ),
        ),
      ],
    ));
  }
}
