// lib/feature/order/screen/tablet/orders_tablet_view.dart
//
// Zoho Books–style tablet orders screen.
//
// ┌────────────────────────────────────────────────────────────────────┐
// │  White header: title · search bar · filter button                  │
// │  Status chip row                                                    │
// ├──────────────────────────┬─────────────────────────────────────────┤
// │  Left panel (38%)        │  Right panel (62%)                      │
// │  Compact order rows      │  ┌─────────────────────────────────┐   │
// │  ─ date group headers ─  │  │  Order detail card              │   │
// │  Selected row highlighted│  │  • Header: order# + status      │   │
// │                          │  │  • Dealer · Shop · Phone        │   │
// │                          │  │  • Date · Items count · Amount  │   │
// │                          │  │  • "Open full details" link     │   │
// │                          │  └─────────────────────────────────┘   │
// └──────────────────────────┴─────────────────────────────────────────┘

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../core/const/icons.dart';
import '../../../../model/order_model.dart';
import '../../controller/order_controller.dart';
import '../order_view_page.dart';

// ── Design tokens — Zoho Books palette ───────────────────────────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF4F5F7); // Zoho: slightly grey canvas
const _kWhite    = Color(0xFFFFFFFF);
const _kBd       = Color(0xFFE5E7EB);
const _kBdLight  = Color(0xFFF0F1F3); // lighter row divider
const _kT1       = Color(0xFF1A1A2E);
const _kT2       = Color(0xFF374151);
const _kT3       = Color(0xFF6B7280);
const _kT4       = Color(0xFF9CA3AF);
const _kGreen    = Color(0xFF0F6E56);
const _kGreenBg  = Color(0xFFEDFAF5);
const _kGreenBd  = Color(0xFF9FE0C5);
const _kRed      = Color(0xFFDC2626);
const _kRedBg    = Color(0xFFFEF2F2);
const _kRedBd    = Color(0xFFFECACA);

// ── Status style ──────────────────────────────────────────────────────────────
class _SS { final Color fg, bg, bd; const _SS(this.fg, this.bg, this.bd); }

_SS _ss(String? s) {
  switch (s?.toUpperCase()) {
    case 'PENDING':    return const _SS(Color(0xFFB45309), Color(0xFFFFFBEB), Color(0xFFFCD28A));
    case 'CONFIRMED':  return const _SS(_kP, _kPBg, _kPBd);
    case 'PRODUCTION': return const _SS(Color(0xFFEA580C), Color(0xFFFFF7ED), Color(0xFFFED7AA));
    case 'PACKED':     return const _SS(Color(0xFF7C3AED), Color(0xFFF5F3FF), Color(0xFFDDD6FE));
    case 'INVOICE':    return const _SS(Color(0xFF4338CA), Color(0xFFEEF2FF), Color(0xFFC7D2FE));
    case 'SHIPPED':    return const _SS(Color(0xFF0369A1), Color(0xFFE0F2FE), Color(0xFFBAE6FD));
    case 'DELIVERED':
    case 'COMPLETED':  return const _SS(_kGreen, _kGreenBg, _kGreenBd);
    case 'CANCELLED':  return const _SS(_kRed, _kRedBg, _kRedBd);
    default:           return const _SS(_kT3, Color(0xFFF3F4F6), _kBd);
  }
}

Color _dot(String? v) {
  switch (v?.toUpperCase()) {
    case 'PENDING':    return const Color(0xFFB45309);
    case 'CONFIRMED':  return _kP;
    case 'PRODUCTION': return const Color(0xFFEA580C);
    case 'PACKED':     return const Color(0xFF7C3AED);
    case 'INVOICE':    return const Color(0xFF4338CA);
    case 'SHIPPED':    return const Color(0xFF0369A1);
    case 'DELIVERED':
    case 'COMPLETED':  return _kGreen;
    case 'CANCELLED':  return _kRed;
    default:           return _kT3;
  }
}

Color _pri(String p) {
  switch (p.toUpperCase()) {
    case 'HIGH':   return _kRed;
    case 'MEDIUM': return const Color(0xFFB45309);
    default:       return _kGreen;
  }
}

// ── Status tabs ───────────────────────────────────────────────────────────────
class _Tab { final String label; final String? api;
const _Tab(this.label, [this.api]); }

final _tabs = <_Tab>[
  _Tab('All'),           _Tab('Pending',   'PENDING'),
  _Tab('Confirmed',  'CONFIRMED'),  _Tab('Production','PRODUCTION'),
  _Tab('Packed',     'PACKED'),     _Tab('Invoice',   'INVOICE'),
  _Tab('Shipped',    'SHIPPED'),    _Tab('Delivered', 'DELIVERED'),
  _Tab('Completed',  'COMPLETED'),  _Tab('Cancelled', 'CANCELLED'),
];

// ── Helpers ───────────────────────────────────────────────────────────────────
String _fmt(num? n) => n == null ? '0' : NumberFormat('#,##,###').format(n);

String _apiDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

String _groupLabel(DateTime d) {
  final now   = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day   = DateTime(d.year, d.month, d.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat('d MMM yyyy').format(d);
}

List<dynamic> _grouped(List<OrderModel> orders) {
  final out = <dynamic>[];
  String? last;
  for (final o in orders) {
    final lbl = _groupLabel(
        o.createdAt?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0));
    if (lbl != last) { out.add(lbl); last = lbl; }
    out.add(o);
  }
  return out;
}

// ═════════════════════════════════════════════════════════════════════════════
// OrdersTabletView
// ═════════════════════════════════════════════════════════════════════════════
class OrdersTabletView extends ConsumerStatefulWidget {
  const OrdersTabletView({super.key});
  @override
  ConsumerState<OrdersTabletView> createState() => _State();
}

class _State extends ConsumerState<OrdersTabletView> {
  final _searchCtrl = TextEditingController();
  final _chipScroll = ScrollController();
  final _listScroll = ScrollController();

  String _q      = '';
  int    _tab    = 0;
  DateTime? _from, _to;
  bool   _dateOn = false;

  List<OrderModel> _all  = [];
  int  _page    = 1;
  bool _loading = false;
  bool _hasMore = true;
  static const _limit = 20;

  OrderModel? _sel;

  @override
  void initState() {
    super.initState();
    _listScroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _chipScroll.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  void _onScroll() {
    if (_listScroll.position.pixels >=
        _listScroll.position.maxScrollExtent - 200) {
      if (!_loading && _hasMore && !_dateOn) _loadMore();
    }
  }

  Future<void> _loadMore() async {
    if (_loading || !_hasMore) return;
    setState(() => _loading = true);
    try {
      final more = await ref.read(paginatedOrdersProvider(PaginatedOrderParams(
        status: _tabs[_tab].api, page: _page + 1, limit: _limit,
      )).future);
      setState(() {
        if (more.isEmpty) { _hasMore = false; }
        else {
          final seen = _all.map((o) => o.orderNumber).toSet();
          _all.addAll(more.where((o) => !seen.contains(o.orderNumber)));
          _page++;
        }
        _loading = false;
      });
    } catch (e, stack) {
      debugPrint('_loadMore error: $e\n$stack');
      setState(() => _loading = false);
    }
  }

  void _reset() => setState(() { _all = []; _page = 1; _hasMore = true; _sel = null; });

  List<OrderModel> _filter(List<OrderModel> src) {
    if (_q.isEmpty) return src;
    final q = _q.toLowerCase();
    return src.where((o) =>
    (o.dealer?.employeeName.toLowerCase() ?? '').contains(q) ||
        (o.dealer?.shopName.toLowerCase() ?? '').contains(q) ||
        (o.orderNumber?.toLowerCase() ?? '').contains(q) ||
        (o.dealer?.employeePhone.toString() ?? '').contains(q),
    ).toList();
  }

  void _clearDate() => setState(() { _from = _to = null; _dateOn = false; _reset(); });

  void _applyDate() {
    if (_from == null || _to == null) return;
    setState(() { _dateOn = true; _reset(); });
  }

  Future<void> _pickDate(bool isFrom, StateSetter ss) async {
    final now = DateTime.now();
    final p = await showDatePicker(
      context: context,
      initialDate: isFrom ? (_from ?? now.subtract(const Duration(days: 30))) : (_to ?? now),
      firstDate: DateTime(2023), lastDate: now,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
              primary: _kP, onPrimary: _kWhite, surface: _kWhite, onSurface: _kT1),
          dialogTheme: const DialogThemeData(backgroundColor: _kWhite),
        ),
        child: child!,
      ),
    );
    if (p == null) return;
    setState(() {
      if (isFrom) { _from = p; if (_to != null && _to!.isBefore(p)) _to = p; }
      else        { _to   = p; if (_from != null && _from!.isAfter(p)) _from = p; }
    });
    ss(() {});
  }

  void _showDateDialog() {
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final sw = MediaQuery.sizeOf(context).width;
        final sh = MediaQuery.sizeOf(context).height;
        final ok = _from != null && _to != null;
        String fmt(DateTime? d) =>
            d == null ? 'Select date' : DateFormat('d MMM yyyy').format(d);

        return Dialog(
          backgroundColor: _kWhite,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: SizedBox(
            width: (sw * 0.36).clamp(300.0, 400.0),
            child: Padding(
              padding: EdgeInsets.all(sw * 0.022),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Row(children: [
                  Text('Filter by Date', style: TextStyle(
                    fontSize: (sw * 0.02).clamp(14.0, 17.0),
                    fontWeight: FontWeight.w700, color: _kT1,
                  )),
                  const Spacer(),
                  if (_dateOn) GestureDetector(
                    onTap: () { _clearDate(); Navigator.pop(ctx); },
                    child: Text('Clear', style: TextStyle(
                        fontSize: (sw * 0.015).clamp(11.0, 13.0),
                        color: _kRed, fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(width: sw * 0.01),
                  GestureDetector(
                      onTap: () => Navigator.pop(ctx),
                      child: Icon(Icons.close_rounded,
                          size: (sw * 0.018).clamp(14.0, 18.0), color: _kT4)),
                ]),
                SizedBox(height: sh * 0.024),
                _DatePickRow(label: 'From', value: fmt(_from),
                    hasValue: _from != null, sw: sw, sh: sh,
                    onTap: () => _pickDate(true, ss)),
                SizedBox(height: sh * 0.012),
                _DatePickRow(label: 'To',   value: fmt(_to),
                    hasValue: _to   != null, sw: sw, sh: sh,
                    onTap: () => _pickDate(false, ss)),
                SizedBox(height: sh * 0.026),
                SizedBox(
                  width: double.infinity,
                  height: (sh * 0.055).clamp(40.0, 50.0),
                  child: ElevatedButton(
                    onPressed: ok ? () { _applyDate(); Navigator.pop(ctx); } : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kP,
                      disabledBackgroundColor: _kBd,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    child: Text('Apply', style: TextStyle(
                      fontSize: (sw * 0.016).clamp(12.0, 14.0),
                      fontWeight: FontWeight.w700,
                      color: ok ? _kWhite : _kT4,
                    )),
                  ),
                ),
              ]),
            ),
          ),
        );
      }),
    );
  }

  void _scrollChip(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chipScroll.hasClients) return;
      _chipScroll.animateTo(
        ((i * 100.0) - 60).clamp(0.0, _chipScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 220), curve: Curves.easeOut,
      );
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final mq   = MediaQuery.of(context);
    final sw   = mq.size.width;
    final sh   = mq.size.height;
    final tab  = _tabs[_tab.clamp(0, _tabs.length - 1)];
    final lw   = (sw * 0.38).clamp(260.0, 420.0); // left panel width

    final async$ = _dateOn && _from != null && _to != null
        ? ref.watch(filteredOrdersProvider(DateFilterParams(
        startDate: _apiDate(_from!), endDate: _apiDate(_to!))))
        : ref.watch(paginatedOrdersProvider(PaginatedOrderParams(
        status: tab.api, page: _page, limit: _limit)));

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [

          // ── Top bar ───────────────────────────────────────────────────────
          _TopBar(
            sw: sw, sh: sh,
            q: _q, ctrl: _searchCtrl,
            dateOn: _dateOn, from: _from, to: _to,
            onChanged:  (v) => setState(() => _q = v),
            onClear:    ()  => setState(() { _searchCtrl.clear(); _q = ''; }),
            onDateTap:  _showDateDialog,
            onDateClear: _clearDate,
          ),

          // ── Status chips ──────────────────────────────────────────────────
          _ChipBar(
            tabs: _tabs, selected: _tab, disabled: _dateOn,
            ctrl: _chipScroll, sw: sw, sh: sh,
            onSelect: (i) {
              HapticFeedback.selectionClick();
              setState(() { _tab = i; _reset(); });
              _scrollChip(i);
            },
          ),

          // ── Two-column body ───────────────────────────────────────────────
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [

                // LEFT panel
                SizedBox(
                  width: lw,
                  child: DecoratedBox(
                    decoration: const BoxDecoration(
                      color: _kWhite,
                      border: Border(right: BorderSide(color: _kBd, width: 0.5)),
                    ),
                    child: async$.when(
                      loading: () => const Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2)),
                      error:   (_, __) => _ErrView(sw: lw, sh: sh, onRetry: () {
                        _reset();
                        if (_dateOn) ref.invalidate(filteredOrdersProvider);
                        else         ref.invalidate(paginatedOrdersProvider);
                      }),
                      data: (raw) {
                        // accumulate pages
                        if (!_dateOn) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (!mounted) return;
                            if (_page == 1) {
                              if (_all.length != raw.length ||
                                  (_all.isNotEmpty && raw.isNotEmpty &&
                                      _all.first.orderNumber != raw.first.orderNumber)) {
                                setState(() => _all = List.from(raw));
                              }
                            } else {
                              final seen  = _all.map((o) => o.orderNumber).toSet();
                              final fresh = raw.where((o) => !seen.contains(o.orderNumber)).toList();
                              if (fresh.isNotEmpty) setState(() => _all.addAll(fresh));
                            }
                          });
                        }

                        final src      = _dateOn ? raw : (_all.isEmpty ? raw : _all);
                        final filtered = _filter(src);

                        // auto-select first
                        if (_sel == null && filtered.isNotEmpty) {
                          WidgetsBinding.instance.addPostFrameCallback((_) {
                            if (mounted && _sel == null) setState(() => _sel = filtered.first);
                          });
                        }

                        if (filtered.isEmpty) return _EmptyLeft(
                          sw: lw, sh: sh, isDate: _dateOn,
                          tabLabel: tab.label,
                          onClear: _clearDate,
                          onAll:   () => setState(() { _tab = 0; _reset(); _scrollChip(0); }),
                        );

                        final items = _grouped(filtered);

                        return RefreshIndicator(
                          color: _kP, backgroundColor: _kWhite,
                          onRefresh: () async {
                            _reset();
                            if (_dateOn) ref.invalidate(filteredOrdersProvider);
                            else         ref.invalidate(paginatedOrdersProvider);
                            await Future.delayed(const Duration(milliseconds: 300));
                          },
                          child: ListView.builder(
                            controller: _listScroll,
                            padding: EdgeInsets.symmetric(vertical: sh * 0.01),
                            itemCount: items.length + (_loading ? 1 : 0),
                            itemBuilder: (_, i) {
                              if (i == items.length) {
                                return Center(child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: sh * 0.02),
                                  child: const CircularProgressIndicator(color: _kP, strokeWidth: 2),
                                ));
                              }
                              final item = items[i];

                              // Date group header
                              if (item is String) {
                                return Padding(
                                  padding: EdgeInsets.fromLTRB(lw * 0.06, i == 0 ? sh * 0.008 : sh * 0.014, lw * 0.06, sh * 0.005),
                                  child: Text(item, style: TextStyle(
                                    fontSize: (lw * 0.028).clamp(9.5, 11.5),
                                    fontWeight: FontWeight.w600,
                                    color: _kT4, letterSpacing: 0.4,
                                  )),
                                );
                              }

                              // Order row
                              final o   = item as OrderModel;
                              final sel = _sel?.orderNumber == o.orderNumber;
                              return _OrderRow(
                                order: o, selected: sel,
                                lw: lw, sh: sh,
                                onTap: () => setState(() => _sel = o),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ),
                ),

                // RIGHT panel
                Expanded(
                  child: _sel == null
                      ? _RightEmpty(sw: sw - lw, sh: sh)
                      : _DetailCard(
                    order: _sel!,
                    pw: sw - lw, sh: sh,
                    onOpen: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) =>
                            OrderViewPage(orderNumber: _sel!.orderNumber ?? ''))),
                  ),
                ),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _TopBar
// ─────────────────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.sw, required this.sh,
    required this.q, required this.ctrl,
    required this.dateOn, required this.from, required this.to,
    required this.onChanged, required this.onClear,
    required this.onDateTap, required this.onDateClear,
  });
  final double sw, sh;
  final String q;
  final TextEditingController ctrl;
  final bool dateOn;
  final DateTime? from, to;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear, onDateTap, onDateClear;

  @override
  Widget build(BuildContext context) {
    final h    = (sh * 0.085).clamp(54.0, 68.0);
    final hPad = sw * 0.022;
    return Container(
      height: h,
      decoration: const BoxDecoration(
        color: _kWhite,
        border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
      ),
      padding: EdgeInsets.symmetric(horizontal: hPad),
      child: Row(children: [

        // Title
        Text('Orders', style: TextStyle(
          fontSize:      (sw * 0.024).clamp(17.0, 22.0),
          fontWeight:    FontWeight.w800,
          color:         _kT1,
          letterSpacing: -0.4,
        )),
        SizedBox(width: hPad * 1.2),

        // Search bar — always visible inline (Zoho style)
        Expanded(
          child: _SearchBar(ctrl: ctrl, sw: sw, sh: sh,
              onChanged: onChanged, onClear: onClear),
        ),
        SizedBox(width: hPad),

        // Date filter pill
        _FilterBtn(
          dateOn: dateOn, from: from, to: to,
          sw: sw, sh: sh,
          onTap:   onDateTap,
          onClear: onDateClear,
        ),
      ]),
    );
  }
}

// ── Inline search bar ─────────────────────────────────────────────────────────
class _SearchBar extends StatefulWidget {
  const _SearchBar({required this.ctrl, required this.sw, required this.sh,
    required this.onChanged, required this.onClear});
  final TextEditingController ctrl;
  final double sw, sh;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;
  @override State<_SearchBar> createState() => _SearchBarState();
}
class _SearchBarState extends State<_SearchBar> {
  bool _focus = false;
  final _fn = FocusNode();
  @override void initState() {
    super.initState();
    _fn.addListener(() => setState(() => _focus = _fn.hasFocus));
  }
  @override void dispose() { _fn.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final h  = (widget.sh * 0.052).clamp(34.0, 42.0);
    final fs = (widget.sw * 0.015).clamp(11.0, 13.5);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: h,
      decoration: BoxDecoration(
        color:        const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _focus ? _kP : _kBd,
            width: _focus ? 1.5 : 0.5),
      ),
      child: Row(children: [
        SizedBox(width: h * 0.32),
        Icon(Icons.search_rounded,
            size: h * 0.44, color: _focus ? _kP : _kT4),
        SizedBox(width: h * 0.22),
        Expanded(child: TextField(
          controller: widget.ctrl,
          focusNode:  _fn,
          onChanged:  widget.onChanged,
          style: TextStyle(fontSize: fs, color: _kT1),
          decoration: InputDecoration(
            hintText:       'Search by order, dealer, shop...',
            hintStyle:      TextStyle(fontSize: fs, color: _kT4),
            border:         InputBorder.none,
            isDense:        true,
            contentPadding: EdgeInsets.zero,
          ),
        )),
        if (widget.ctrl.text.isNotEmpty)
          GestureDetector(
            onTap: widget.onClear,
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: h * 0.2),
              child: Icon(Icons.close_rounded, size: h * 0.38, color: _kT4),
            ),
          )
        else
          SizedBox(width: h * 0.3),
      ]),
    );
  }
}

// ── Date filter button ────────────────────────────────────────────────────────
class _FilterBtn extends StatelessWidget {
  const _FilterBtn({required this.dateOn, required this.from, required this.to,
    required this.sw, required this.sh,
    required this.onTap, required this.onClear});
  final bool dateOn;
  final DateTime? from, to;
  final double sw, sh;
  final VoidCallback onTap, onClear;

  @override
  Widget build(BuildContext context) {
    final h = (sh * 0.052).clamp(34.0, 42.0);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        height: h,
        padding: EdgeInsets.symmetric(horizontal: sw * 0.014),
        decoration: BoxDecoration(
          color:        dateOn ? _kPBg : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: dateOn ? _kPBd : Colors.transparent, width: 0.5),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.tune_rounded,
              size: (sw * 0.017).clamp(13.0, 17.0),
              color: dateOn ? _kP : _kT3),
          SizedBox(width: sw * 0.007),
          Text(
            dateOn && from != null && to != null
                ? '${DateFormat('d MMM').format(from!)} – ${DateFormat('d MMM').format(to!)}'
                : 'Filter',
            style: TextStyle(
              fontSize:   (sw * 0.014).clamp(10.5, 12.5),
              fontWeight: FontWeight.w600,
              color:      dateOn ? _kP : _kT3,
            ),
          ),
          if (dateOn) ...[
            SizedBox(width: sw * 0.006),
            GestureDetector(
              onTap: onClear,
              child: Icon(Icons.close_rounded,
                  size: (sw * 0.014).clamp(10.0, 13.0), color: _kP),
            ),
          ],
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ChipBar — status filter row
// ─────────────────────────────────────────────────────────────────────────────
class _ChipBar extends StatelessWidget {
  const _ChipBar({required this.tabs, required this.selected,
    required this.disabled, required this.ctrl,
    required this.sw, required this.sh, required this.onSelect});
  final List<_Tab> tabs;
  final int selected; final bool disabled;
  final ScrollController ctrl;
  final double sw, sh;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: (sh * 0.054).clamp(34.0, 46.0),
      decoration: const BoxDecoration(
        color: _kWhite,
        border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
      ),
      child: ListView.builder(
        controller:      ctrl,
        scrollDirection: Axis.horizontal,
        physics:         const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(sw * 0.022, sh * 0.006, sw * 0.022, sh * 0.007),
        itemCount: tabs.length,
        itemBuilder: (_, i) {
          final t   = tabs[i];
          final sel = selected == i && !disabled;
          final d   = _dot(t.api);
          return GestureDetector(
            onTap: disabled ? null : () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 140),
              margin: EdgeInsets.only(right: sw * 0.01),
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.016, vertical: sh * 0.004),
              decoration: BoxDecoration(
                color:        sel ? _kPBg : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                    color: sel ? _kPBd : Colors.transparent, width: 0.5),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (t.api != null) ...[
                  Container(width: 6, height: 6,
                      decoration: BoxDecoration(
                          color: disabled ? _kBd : d, shape: BoxShape.circle)),
                  SizedBox(width: sw * 0.007),
                ],
                Text(t.label, style: TextStyle(
                  fontSize:   (sw * 0.015).clamp(10.0, 12.0),
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color:      disabled ? _kT4 : sel ? _kP : _kT3,
                  height: 1.0,
                )),
              ]),
            ),
          );
        },
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _OrderRow — compact left-panel row (Zoho Books list style)
// ─────────────────────────────────────────────────────────────────────────────
class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.selected,
    required this.lw, required this.sh, required this.onTap});
  final OrderModel order;
  final bool       selected;
  final double     lw, sh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st  = _ss(order.status);
    final p   = _pri(order.priority);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 130),
        decoration: BoxDecoration(
          color: selected ? _kPBg : _kWhite,
          border: Border(
            left: BorderSide(
                color: selected ? _kP : Colors.transparent, width: 3),
            bottom: const BorderSide(color: _kBdLight, width: 0.5),
          ),
        ),
        padding: EdgeInsets.symmetric(
            horizontal: lw * 0.07, vertical: sh * 0.014),
        child: Row(children: [

          // Priority dot
          Container(width: 7, height: 7,
              decoration: BoxDecoration(color: p, shape: BoxShape.circle)),
          SizedBox(width: lw * 0.04),

          // Order info
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.orderNumber ?? 'N/A', style: TextStyle(
                fontSize:   (lw * 0.042).clamp(12.0, 14.0),
                fontWeight: FontWeight.w700,
                color:      selected ? _kP : _kT1,
                letterSpacing: -0.1,
              )),
              SizedBox(height: sh * 0.003),
              Text(order.dealer?.employeeName ?? 'N/A', style: TextStyle(
                fontSize: (lw * 0.034).clamp(10.0, 12.0),
                color: _kT3, fontWeight: FontWeight.w500,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
              if ((order.dealer?.shopName ?? '').isNotEmpty) ...[
                SizedBox(height: sh * 0.001),
                Text(order.dealer!.shopName, style: TextStyle(
                  fontSize: (lw * 0.03).clamp(9.0, 11.0), color: _kT4,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ],
          )),
          SizedBox(width: lw * 0.03),

          // Right: amount + status
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            if (order.totalPrice != null)
              Text('₹${_fmt(order.totalPrice)}', style: TextStyle(
                fontSize:   (lw * 0.036).clamp(10.5, 13.0),
                fontWeight: FontWeight.w700,
                color:      _kT1,
              )),
            SizedBox(height: sh * 0.004),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: lw * 0.04, vertical: sh * 0.003),
              decoration: BoxDecoration(
                color:        st.bg,
                borderRadius: BorderRadius.circular(3),
                border:       Border.all(color: st.bd, width: 0.5),
              ),
              child: Text(order.status ?? '', style: TextStyle(
                fontSize:   (lw * 0.028).clamp(8.0, 10.0),
                fontWeight: FontWeight.w700,
                color:      st.fg, height: 1.0,
              )),
            ),
          ]),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _DetailCard — right panel: single Zoho-style order card
// ─────────────────────────────────────────────────────────────────────────────
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.order, required this.pw,
    required this.sh, required this.onOpen});
  final OrderModel order;
  final double pw, sh;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final st  = _ss(order.status);
    final p   = _pri(order.priority);
    final pad = (pw * 0.06).clamp(20.0, 40.0);

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Card ──────────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color:        _kWhite,
            borderRadius: BorderRadius.circular(8),
            border:       Border.all(color: _kBd, width: 0.5),
            boxShadow: [
              BoxShadow(
                color:   const Color(0xFF000000).withValues(alpha: 0.04),
                blurRadius: 8, offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Card header ────────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: pw * 0.06, vertical: sh * 0.022),
              decoration: const BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.only(
                  topLeft:  Radius.circular(8),
                  topRight: Radius.circular(8),
                ),
                border: Border(bottom: BorderSide(color: _kBd, width: 0.5)),
              ),
              child: Row(children: [
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber ?? 'N/A', style: TextStyle(
                      fontSize:   (pw * 0.038).clamp(16.0, 22.0),
                      fontWeight: FontWeight.w800,
                      color:      _kT1, letterSpacing: -0.3,
                    )),
                    SizedBox(height: sh * 0.005),
                    if (order.createdAt != null)
                      Text(
                        DateFormat('d MMM yyyy, h:mm a')
                            .format(order.createdAt!.toLocal()),
                        style: TextStyle(
                          fontSize: (pw * 0.024).clamp(10.0, 13.0),
                          color: _kT3,
                        ),
                      ),
                  ],
                )),

                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: pw * 0.04, vertical: sh * 0.008),
                  decoration: BoxDecoration(
                    color:        st.bg,
                    borderRadius: BorderRadius.circular(4),
                    border:       Border.all(color: st.bd, width: 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(
                            color: st.fg, shape: BoxShape.circle)),
                    SizedBox(width: pw * 0.018),
                    Text(order.status ?? '', style: TextStyle(
                      fontSize:   (pw * 0.022).clamp(10.0, 13.0),
                      fontWeight: FontWeight.w700,
                      color:      st.fg, height: 1.0,
                    )),
                  ]),
                ),
              ]),
            ),

            // ── Card body ─────────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: pw * 0.06, vertical: sh * 0.02),
              child: Column(children: [

                // Dealer row
                _Row(icon: Icons.person_outline_rounded,
                    label: 'Dealer',
                    value: order.dealer?.employeeName ?? 'N/A',
                    pw: pw, sh: sh),
                _divider(),

                // Shop row
                _Row(icon: Icons.store_outlined,
                    label: 'Shop',
                    value: order.dealer?.shopName ?? 'N/A',
                    pw: pw, sh: sh),
                _divider(),

                // Phone row
                _Row(icon: Icons.phone_outlined,
                    label: 'Phone',
                    value: order.dealer?.employeePhone?.toString() ?? 'N/A',
                    pw: pw, sh: sh),
                _divider(),

                // Items row
                _Row(icon: Icons.inventory_2_outlined,
                    label: 'Items',
                    value: '${order.orderDetails.length} item${order.orderDetails.length != 1 ? 's' : ''}',
                    pw: pw, sh: sh),
                _divider(),

                // Amount row
                if (order.totalPrice != null) ...[
                  _Row(icon: Icons.currency_rupee_rounded,
                      label: 'Amount',
                      value: '₹${_fmt(order.totalPrice)}',
                      valueColor: _kGreen,
                      pw: pw, sh: sh),
                  _divider(),
                ],

                // Priority row
                _PriorityRow(priority: order.priority, pw: pw, sh: sh),
              ]),
            ),

            // ── Card footer ───────────────────────────────────────────────
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: pw * 0.06, vertical: sh * 0.018),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: _kBd, width: 0.5)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  GestureDetector(
                    onTap: onOpen,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: pw * 0.048, vertical: sh * 0.013),
                      decoration: BoxDecoration(
                        color:        _kP,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.open_in_new_rounded,
                            size: (pw * 0.024).clamp(12.0, 15.0),
                            color: _kWhite),
                        SizedBox(width: pw * 0.016),
                        Text('View Full Details', style: TextStyle(
                          fontSize:   (pw * 0.022).clamp(11.0, 13.0),
                          fontWeight: FontWeight.w700,
                          color:      _kWhite,
                        )),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
          ]),
        ),
      ]),
    );
  }

  Widget _divider() => const Divider(height: 1, thickness: 0.5, color: _kBdLight);
}

// ── Info row ──────────────────────────────────────────────────────────────────
class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label,
    required this.value, required this.pw, required this.sh,
    this.valueColor});
  final IconData icon;
  final String   label, value;
  final double   pw, sh;
  final Color?   valueColor;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.symmetric(vertical: sh * 0.013),
    child: Row(children: [
      Icon(icon, size: (pw * 0.026).clamp(13.0, 16.0), color: _kT4),
      SizedBox(width: pw * 0.028),
      SizedBox(
        width: pw * 0.22,
        child: Text(label, style: TextStyle(
          fontSize: (pw * 0.022).clamp(10.5, 13.0),
          color: _kT3, fontWeight: FontWeight.w500,
        )),
      ),
      Expanded(child: Text(value,
        style: TextStyle(
          fontSize:   (pw * 0.023).clamp(11.0, 13.5),
          fontWeight: FontWeight.w600,
          color:      valueColor ?? _kT1,
        ),
        textAlign: TextAlign.end,
        maxLines: 1, overflow: TextOverflow.ellipsis,
      )),
    ]),
  );
}

// ── Priority row ──────────────────────────────────────────────────────────────
class _PriorityRow extends StatelessWidget {
  const _PriorityRow({required this.priority, required this.pw, required this.sh});
  final String priority;
  final double pw, sh;

  @override
  Widget build(BuildContext context) {
    final c = _pri(priority);
    return Padding(
      padding: EdgeInsets.symmetric(vertical: sh * 0.013),
      child: Row(children: [
        Icon(Icons.flag_outlined,
            size: (pw * 0.026).clamp(13.0, 16.0), color: _kT4),
        SizedBox(width: pw * 0.028),
        SizedBox(
          width: pw * 0.22,
          child: Text('Priority', style: TextStyle(
            fontSize: (pw * 0.022).clamp(10.5, 13.0),
            color: _kT3, fontWeight: FontWeight.w500,
          )),
        ),
        const Spacer(),
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: pw * 0.032, vertical: sh * 0.004),
          decoration: BoxDecoration(
            color:        c.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(3),
            border: Border.all(color: c.withValues(alpha: 0.3), width: 0.5),
          ),
          child: Text(priority, style: TextStyle(
            fontSize:   (pw * 0.022).clamp(10.0, 12.5),
            fontWeight: FontWeight.w700,
            color:      c, height: 1.0,
          )),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Empty / Error states
// ─────────────────────────────────────────────────────────────────────────────
class _RightEmpty extends StatelessWidget {
  const _RightEmpty({required this.sw, required this.sh});
  final double sw, sh;

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width:  (sw * 0.1).clamp(52.0, 72.0),
        height: (sw * 0.1).clamp(52.0, 72.0),
        decoration: const BoxDecoration(
            color: Color(0xFFF3F4F6), shape: BoxShape.circle),
        child: Icon(Icons.receipt_long_outlined,
            size: (sw * 0.045).clamp(22.0, 32.0), color: _kBd),
      ),
      SizedBox(height: sh * 0.016),
      Text('No order selected', style: TextStyle(
        fontSize:   (sw * 0.02).clamp(13.0, 15.0),
        fontWeight: FontWeight.w600, color: _kT3,
      )),
      SizedBox(height: sh * 0.005),
      Text('Select an order from the list', style: TextStyle(
        fontSize: (sw * 0.015).clamp(10.0, 12.0), color: _kT4,
      )),
    ]),
  );
}

class _EmptyLeft extends StatelessWidget {
  const _EmptyLeft({required this.sw, required this.sh,
    required this.isDate, required this.tabLabel,
    required this.onClear, required this.onAll});
  final double sw, sh;
  final bool isDate;
  final String tabLabel;
  final VoidCallback onClear, onAll;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(isDate ? Icons.date_range_outlined : Icons.inbox_outlined,
          size: (sw * 0.06).clamp(28.0, 40.0), color: _kBd),
      SizedBox(height: sh * 0.014),
      Text(isDate ? 'No orders in range' : 'No $tabLabel orders',
        style: TextStyle(fontSize: (sw * 0.02).clamp(11.0, 13.0),
            fontWeight: FontWeight.w600, color: _kT3),
        textAlign: TextAlign.center,
      ),
      SizedBox(height: sh * 0.016),
      if (isDate)
        _TxtBtn(label: 'Clear Filter', onTap: onClear, sw: sw, sh: sh)
      else if (tabLabel != 'All')
        _TxtBtn(label: 'View All', onTap: onAll, sw: sw, sh: sh),
    ],
  ));
}

class _ErrView extends StatelessWidget {
  const _ErrView({required this.sw, required this.sh, required this.onRetry});
  final double sw, sh; final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(Icons.wifi_off_rounded,
          size: (sw * 0.06).clamp(28.0, 40.0), color: _kRed),
      SizedBox(height: sh * 0.014),
      Text('No connection', style: TextStyle(
          fontSize: (sw * 0.02).clamp(11.0, 13.0),
          fontWeight: FontWeight.w600, color: _kT2)),
      SizedBox(height: sh * 0.016),
      _TxtBtn(label: 'Retry', onTap: onRetry, sw: sw, sh: sh),
    ],
  ));
}

class _TxtBtn extends StatelessWidget {
  const _TxtBtn({required this.label, required this.onTap,
    required this.sw, required this.sh});
  final String label; final VoidCallback onTap;
  final double sw, sh;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.03, vertical: sh * 0.01),
      decoration: BoxDecoration(
        color: _kPBg, borderRadius: BorderRadius.circular(6),
        border: Border.all(color: _kPBd, width: 0.5),
      ),
      child: Text(label, style: TextStyle(
        fontSize: (sw * 0.016).clamp(10.0, 12.0),
        fontWeight: FontWeight.w600, color: _kP,
      )),
    ),
  );
}

// ── Date picker row (dialog) ──────────────────────────────────────────────────
class _DatePickRow extends StatelessWidget {
  const _DatePickRow({required this.label, required this.value,
    required this.hasValue, required this.sw, required this.sh,
    required this.onTap});
  final String label, value;
  final bool hasValue;
  final double sw, sh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.022, vertical: sh * 0.014),
      decoration: BoxDecoration(
        color:        hasValue ? _kPBg : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: hasValue ? _kPBd : _kBd, width: 0.5),
      ),
      child: Row(children: [
        Icon(Icons.calendar_today_outlined,
            size: (sw * 0.02).clamp(13.0, 16.0),
            color: hasValue ? _kP : _kT4),
        SizedBox(width: sw * 0.018),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: TextStyle(
                fontSize: (sw * 0.014).clamp(9.0, 11.0),
                color: _kT4, fontWeight: FontWeight.w500)),
            SizedBox(height: sh * 0.002),
            Text(value, style: TextStyle(
              fontSize:   (sw * 0.016).clamp(11.0, 13.0),
              color:      hasValue ? _kP : _kT3,
              fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
            )),
          ],
        )),
        Icon(Icons.chevron_right_rounded,
            size: (sw * 0.02).clamp(13.0, 16.0), color: _kT4),
      ]),
    ),
  );
}