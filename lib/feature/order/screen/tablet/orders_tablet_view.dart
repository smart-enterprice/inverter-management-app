// lib/feature/order/screen/tablet/orders_tablet_view.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../../model/order_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../controller/order_controller.dart';
import '../order_view_page.dart';

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
    default:           return const _SS(_kT4, Color(0xFFF3F4F6), _kBd);
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
  _Tab('All'),          _Tab('Pending',   'PENDING'),
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
  int         _selIdx = 0;

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
    } catch (_) { setState(() => _loading = false); }
  }

  void _reset() => setState(() { _all = []; _page = 1; _hasMore = true; _sel = null; _selIdx = 0; });

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

  @override
  Widget build(BuildContext context) {
    final mq   = MediaQuery.of(context);
    final sw   = mq.size.width;
    final sh   = mq.size.height;
    final tab  = _tabs[_tab.clamp(0, _tabs.length - 1)];
    final lw   = (sw * 0.38).clamp(260.0, 420.0);

    final async$ = _dateOn && _from != null && _to != null
        ? ref.watch(filteredOrdersProvider(DateFilterParams(
        startDate: _apiDate(_from!), endDate: _apiDate(_to!))))
        : ref.watch(paginatedOrdersProvider(PaginatedOrderParams(
        status: tab.api, page: 1, limit: _limit)));

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [

          // ── Top bar ─────────────────────────────────────────────────────────
          _TopBar(
            sw: sw, sh: sh,
            q: _q, ctrl: _searchCtrl,
            dateOn: _dateOn, from: _from, to: _to,
            onChanged:  (v) => setState(() => _q = v),
            onClear:    ()  => setState(() { _searchCtrl.clear(); _q = ''; }),
            onDateTap:  _showDateDialog,
            onDateClear: _clearDate,
            onRefresh: () {
              _reset();
              if (_dateOn) ref.invalidate(filteredOrdersProvider);
              else         ref.invalidate(paginatedOrdersProvider);
            },
          ),

          // ── Status chips ─────────────────────────────────────────────────
          _ChipBar(
            tabs: _tabs, selected: _tab, disabled: _dateOn,
            ctrl: _chipScroll, sw: sw, sh: sh,
            onSelect: (i) {
              HapticFeedback.selectionClick();
              setState(() { _tab = i; _reset(); });
              _scrollChip(i);
            },
          ),

          // ── Split view ───────────────────────────────────────────────────
          Expanded(
            child: Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [

              // LEFT — order list
              SizedBox(
                width: lw,
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    color: _kWhite,
                    border: Border(right: BorderSide(color: _kBd, width: 0.5)),
                  ),
                  child: async$.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(color: _kP, strokeWidth: 2)),
                    error: (_, __) => _ErrView(onRetry: () {
                      _reset();
                      if (_dateOn) ref.invalidate(filteredOrdersProvider);
                      else         ref.invalidate(paginatedOrdersProvider);
                    }),
                    data: (raw) {
                      if (!_dateOn && _all.isEmpty && raw.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _all.isEmpty) {
                            setState(() => _all = List.from(raw));
                          }
                        });
                      }

                      final src      = _dateOn ? raw : (_all.isEmpty ? raw : _all);
                      final filtered = _filter(src);

                      if (_sel == null && filtered.isNotEmpty) {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted && _sel == null) {
                            setState(() { _sel = filtered.first; _selIdx = 0; });
                          }
                        });
                      }

                      if (filtered.isEmpty) {
                        return _EmptyLeft(
                          lw: lw, isDate: _dateOn,
                          tabLabel: tab.label,
                          onClear: _clearDate,
                          onAll: () => setState(() { _tab = 0; _reset(); _scrollChip(0); }),
                        );
                      }

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
                          padding: EdgeInsets.only(top: sh * 0.008),
                          itemCount: items.length + (_loading ? 1 : 0),
                          itemBuilder: (_, i) {
                            if (i == items.length) {
                              return Center(child: Padding(
                                padding: EdgeInsets.symmetric(vertical: sh * 0.02),
                                child: const SizedBox(
                                  width: 20, height: 20,
                                  child: CircularProgressIndicator(
                                      color: _kP, strokeWidth: 2)),
                              ));
                            }
                            final item = items[i];
                            if (item is String) {
                              return Padding(
                                padding: EdgeInsets.fromLTRB(lw * 0.06,
                                    i == 0 ? sh * 0.008 : sh * 0.014,
                                    lw * 0.06, sh * 0.005),
                                child: Text(item, style: TextStyle(
                                  fontSize: (lw * 0.028).clamp(9.5, 11.5),
                                  fontWeight: FontWeight.w600,
                                  color: _kT4, letterSpacing: 0.4,
                                )),
                              );
                            }
                            final o   = item as OrderModel;
                            final idx = filtered.indexOf(o);
                            return _OrderRow(
                              order: o,
                              index: idx,
                              selected: _sel?.orderNumber == o.orderNumber,
                              lw: lw,
                              onTap: () {
                                HapticFeedback.selectionClick();
                                setState(() { _sel = o; _selIdx = idx; });
                              },
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ),

              // RIGHT — detail (always rendered, independent of left panel load state)
              Expanded(
                child: _sel == null
                    ? _EmptyRight(rw: sw - lw)
                    : _DetailCard(
                  order: _sel!,
                  index: _selIdx,
                  rw: sw - lw, sh: sh,
                  onOpen: () => Navigator.push(context,
                      MaterialPageRoute(builder: (_) =>
                          OrderViewPage(orderNumber: _sel!.orderNumber ?? ''))),
                ),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ── Top bar ───────────────────────────────────────────────────────────────────
class _TopBar extends StatelessWidget {
  const _TopBar({
    required this.sw, required this.sh,
    required this.q, required this.ctrl,
    required this.dateOn, required this.from, required this.to,
    required this.onChanged, required this.onClear,
    required this.onDateTap, required this.onDateClear, required this.onRefresh,
  });
  final double sw, sh;
  final String q;
  final TextEditingController ctrl;
  final bool dateOn;
  final DateTime? from, to;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear, onDateTap, onDateClear, onRefresh;

  @override
  Widget build(BuildContext context) {
    return Container(
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
        Text('Orders', style: TextStyle(
          fontSize: (sw * 0.022).clamp(16.0, 20.0),
          fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.3,
        )),
        SizedBox(width: sw * 0.02),
        Expanded(child: _SearchField(ctrl: ctrl, sw: sw, sh: sh,
            hint: 'Search by order, dealer, shop…',
            onChanged: onChanged, onClear: onClear)),
        SizedBox(width: sw * 0.012),
        _FilterBtn(
          dateOn: dateOn, from: from, to: to,
          sw: sw, sh: sh,
          onTap: onDateTap, onClear: onDateClear,
        ),
        SizedBox(width: sw * 0.008),
        GestureDetector(
          onTap: onRefresh,
          child: Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: _kPBg, borderRadius: BorderRadius.circular(8),
              border: Border.all(color: _kPBd, width: 0.5),
            ),
            child: const Icon(Icons.refresh_rounded, size: 16, color: _kP),
          ),
        ),
      ]),
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────
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

// ── Date filter button ────────────────────────────────────────────────────────
class _FilterBtn extends StatelessWidget {
  const _FilterBtn({required this.dateOn, required this.from, required this.to,
    required this.sw, required this.sh, required this.onTap, required this.onClear});
  final bool dateOn; final DateTime? from, to;
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
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: dateOn ? _kPBd : _kBd, width: 0.5),
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

// ── Status chip bar ───────────────────────────────────────────────────────────
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
          final st  = _ss(t.api);
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
                          color: disabled ? _kBd : st.fg,
                          shape: BoxShape.circle)),
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

// ── Order list row ────────────────────────────────────────────────────────────
const _badgeSets = [
  (_kPBg,                   _kPBd,                   _kP),
  (_kGreenBg,               _kGreenBd,               _kGreen),
  (Color(0xFFF5F3FF),       Color(0xFFDDD6FE),       Color(0xFF7C3AED)),
  (Color(0xFFFFFBEB),       Color(0xFFFCD28A),       Color(0xFFB45309)),
  (_kRedBg,                 _kRedBd,                 _kRed),
];

(Color, Color, Color) _badgeColors(int i) => _badgeSets[i % _badgeSets.length];

class _OrderRow extends StatelessWidget {
  const _OrderRow({required this.order, required this.index,
    required this.selected, required this.lw, required this.onTap});
  final OrderModel order;
  final int        index;
  final bool       selected;
  final double     lw;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = _badgeColors(index);

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
        padding: EdgeInsets.symmetric(horizontal: lw * 0.06, vertical: 11),
        child: Row(children: [
          // Status-colored badge
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: c.$1,
              border: Border.all(color: c.$2, width: 1.0),
            ),
            child: Center(child: Text(
              (order.orderNumber ?? '?').replaceAll(RegExp(r'[^0-9]'), '').characters.take(2).toString(),
              style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w800, color: c.$3),
            )),
          ),
          SizedBox(width: lw * 0.04),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(order.orderNumber ?? 'N/A', style: TextStyle(
                fontSize:   (lw * 0.042).clamp(12.0, 14.0),
                fontWeight: FontWeight.w700,
                color:      selected ? _kP : _kT1,
                letterSpacing: -0.1,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 2),
              Text(order.dealer?.employeeName ?? 'N/A', style: TextStyle(
                fontSize: (lw * 0.034).clamp(10.0, 12.0),
                color: _kT3, fontWeight: FontWeight.w500,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
              if ((order.dealer?.shopName ?? '').isNotEmpty) ...[
                const SizedBox(height: 1),
                Text(order.dealer!.shopName, style: TextStyle(
                  fontSize: (lw * 0.03).clamp(9.0, 11.0), color: _kT4,
                ), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ],
          )),
        ]),
      ),
    );
  }
}

// ── Detail card (right panel) — matches dealers style ────────────────────────
class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.order, required this.index,
    required this.rw, required this.sh, required this.onOpen});
  final OrderModel order;
  final int        index;
  final double     rw, sh;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final pad = (rw * 0.06).clamp(18.0, 32.0);
    final st  = _ss(order.status);
    final c   = _badgeColors(index);

    return SingleChildScrollView(
      padding: EdgeInsets.all(pad),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // ── Main card ─────────────────────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: _kWhite, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _kBd, width: 0.5),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Gray header — order number + date + status
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
                  width: 52, height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle, color: c.$1,
                    border: Border.all(color: c.$2, width: 1.5),
                  ),
                  child: Center(child: Text(
                    (order.orderNumber ?? '?').replaceAll(RegExp(r'[^0-9]'), '').characters.take(2).toString(),
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: c.$3),
                  )),
                ),
                SizedBox(width: pad * 0.6),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.orderNumber ?? 'N/A', style: TextStyle(
                      fontSize: (rw * 0.032).clamp(15.0, 20.0),
                      fontWeight: FontWeight.w800, color: _kT1, letterSpacing: -0.2,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                    if (order.createdAt != null) ...[
                      const SizedBox(height: 3),
                      Text(DateFormat('d MMM yyyy, h:mm a')
                          .format(order.createdAt!.toLocal()),
                          style: const TextStyle(fontSize: 12, color: _kT3,
                              fontWeight: FontWeight.w500)),
                    ],
                  ],
                )),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: st.bg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: st.bd, width: 0.5),
                  ),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(width: 6, height: 6,
                        decoration: BoxDecoration(color: st.fg, shape: BoxShape.circle)),
                    const SizedBox(width: 6),
                    Text(order.status ?? '', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w700,
                      color: st.fg, height: 1.0,
                    )),
                  ]),
                ),
              ]),
            ),

            // ── Dealer section ────────────────────────────────────────────
            if (order.dealer != null) ...[
              Padding(
                padding: EdgeInsets.fromLTRB(pad, pad * 0.7, pad, pad * 0.5),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _SectionLabel('DEALER INFORMATION'),
                  const SizedBox(height: 8),
                  _InfoRow(icon: Icons.person_outline_rounded,
                      label: 'Dealer', value: order.dealer!.employeeName),
                  const _Divider(),
                  _InfoRow(icon: Icons.storefront_outlined,
                      label: 'Shop', value: order.dealer!.shopName),
                  const _Divider(),
                  _InfoRow(icon: Icons.phone_outlined,
                      label: 'Phone',
                      value: order.dealer!.employeePhone.toString()),
                ]),
              ),
              const _Divider(),
            ],

            // ── Order section ─────────────────────────────────────────────
            Padding(
              padding: EdgeInsets.fromLTRB(pad, pad * 0.7, pad, pad * 0.7),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const _SectionLabel('ORDER DETAILS'),
                const SizedBox(height: 8),
                _InfoRow(
                  icon: Icons.inventory_2_outlined,
                  label: 'Items',
                  value: '${order.orderDetails.length} item${order.orderDetails.length != 1 ? 's' : ''}',
                ),
                if (order.totalPrice != null) ...[
                  const _Divider(),
                  _InfoRow(
                    icon: Icons.currency_rupee_rounded,
                    label: 'Amount',
                    value: '₹${_fmt(order.totalPrice)}',
                    valueColor: _kGreen,
                  ),
                ],
                const _Divider(),
                _InfoRow(
                  icon: Icons.flag_outlined,
                  label: 'Priority',
                  value: order.priority,
                  valueColor: _pri(order.priority),
                ),
              ]),
            ),
          ]),
        ),

        SizedBox(height: pad * 0.7),

        // ── Full-width action button ───────────────────────────────────────
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
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
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
      SizedBox(width: 72, child: Text(label, style: const TextStyle(
        fontSize: 12, color: _kT3, fontWeight: FontWeight.w500))),
      Expanded(child: Text(value, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w600,
        color: valueColor ?? _kT1,
      ), textAlign: TextAlign.end, maxLines: 2, overflow: TextOverflow.ellipsis)),
    ]),
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
  const _EmptyLeft({required this.lw, required this.isDate,
    required this.tabLabel, required this.onClear, required this.onAll});
  final double lw; final bool isDate;
  final String tabLabel;
  final VoidCallback onClear, onAll;

  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(isDate ? Icons.date_range_outlined : Icons.receipt_long_outlined,
          size: (lw * 0.12).clamp(32.0, 48.0), color: _kT4),
      const SizedBox(height: 10),
      Text(isDate ? 'No orders in range' : 'No $tabLabel orders',
          style: TextStyle(fontSize: (lw * 0.036).clamp(12.0, 14.0),
              color: _kT3, fontWeight: FontWeight.w500),
          textAlign: TextAlign.center),
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
        child: const Icon(Icons.receipt_long_outlined, size: 26, color: _kP),
      ),
      const SizedBox(height: 12),
      Text('Select an order', style: TextStyle(
          fontSize: (rw * 0.022).clamp(12.0, 15.0),
          color: _kT3, fontWeight: FontWeight.w600)),
      const SizedBox(height: 4),
      const Text('Tap an order on the left to see its details',
          style: TextStyle(fontSize: 11.5, color: _kT4)),
    ],
  ));
}

class _ErrView extends StatelessWidget {
  const _ErrView({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(child: Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.wifi_off_rounded, size: 32, color: _kRed),
      const SizedBox(height: 10),
      const Text('Could not load orders',
          style: TextStyle(color: _kRed, fontWeight: FontWeight.w500)),
      const SizedBox(height: 14),
      ElevatedButton(
        onPressed: onRetry,
        style: ElevatedButton.styleFrom(
          backgroundColor: _kP, foregroundColor: _kWhite,
          shape: const CircleBorder(), padding: const EdgeInsets.all(14), elevation: 0),
        child: const Icon(Icons.refresh_rounded),
      ),
    ],
  ));
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
