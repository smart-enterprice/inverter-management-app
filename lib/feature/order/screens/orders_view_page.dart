import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import '../../../core/const/icons.dart';
import '../controller/order_controller.dart';
import '../../../feature/order/model/order_model.dart';
import 'order_view_page.dart';

// ── Tokens ────────────────────────────────────────────────────────────────────
const _kP        = Color(0xFF185FA5); // primary blue
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Color(0xFFFFFFFF);
const _kBd       = Color(0xFFE5E7EB);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
const _kT3       = Color(0xFF6B7280);
const _kT4       = Color(0xFF9CA3AF);
const _kRed      = Color(0xFFDC2626);
const _kRedBg    = Color(0xFFFEF2F2);
const _kRedBd    = Color(0xFFFECACA);
const _kGreen    = Color(0xFF0F6E56);
const _kGreenBg  = Color(0xFFEDFAF5);

// ── Status helpers ────────────────────────────────────────────────────────────
class _S { final Color fg, bg, bd; const _S(this.fg, this.bg, this.bd); }

_S _ss(String? s) {
  switch (s?.toUpperCase()) {
    case 'PENDING':    return const _S(Color(0xFFB45309), Color(0xFFFFFBEB), Color(0xFFFCD28A));
    case 'PRODUCTION': return const _S(Color(0xFFEA580C), Color(0xFFFFF7ED), Color(0xFFFED7AA));
    case 'PACKED':     return const _S(Color(0xFF7C3AED), Color(0xFFF5F3FF), Color(0xFFDDD6FE));
    case 'INVOICE':    return const _S(Color(0xFF4338CA), Color(0xFFEEF2FF), Color(0xFFC7D2FE));
    case 'SHIPPED':    return const _S(Color(0xFF0369A1), Color(0xFFE0F2FE), Color(0xFFBAE6FD));
    case 'COMPLETED':  return const _S(_kGreen, _kGreenBg, Color(0xFF9FE0C5));
    case 'CANCELLED':  return const _S(_kRed, _kRedBg, _kRedBd);
  case 'REJECTED':  return const _S(_kP, _kPBg, _kPBd);
    default:           return const _S(_kT3, Color(0xFFF3F4F6), _kBd);
  }
}

Color _dotColor(String? v) {
  switch (v?.toUpperCase()) {
    case 'PENDING':    return const Color(0xFFB45309);
    case 'PRODUCTION': return const Color(0xFFEA580C);
    case 'PACKED':     return const Color(0xFF7C3AED);
    case 'INVOICE':    return const Color(0xFF4338CA);
    case 'SHIPPED':    return const Color(0xFF0369A1);
    case 'DELIVERED':
    case 'COMPLETED':  return _kGreen;
    case 'CANCELLED':  return _kRed;
    case 'REJECTED':  return _kP;
    default:           return _kT3;
  }
}

Color _priColor(String p) {
  switch (p.toUpperCase()) {
    case 'HIGH':   return _kRed;
    case 'MEDIUM': return const Color(0xFFB45309);
    default:       return _kGreen;
  }
}

// ── Status filter tabs ────────────────────────────────────────────────────────
class _Tab { final String label; final String? api;
const _Tab(this.label, [this.api]); }

final _tabs = <_Tab>[
  _Tab('All'), _Tab('Pending','PENDING'),
  _Tab('Production','PRODUCTION'), _Tab('Packed','PACKED'),
  _Tab('Invoice','INVOICE'), _Tab('Shipped','SHIPPED'),
  _Tab('Delivered','DELIVERED'), _Tab('Completed','COMPLETED'),
  _Tab('Cancelled','CANCELLED'),_Tab('Rejected','REJECTED'),
];

// ── Helpers ───────────────────────────────────────────────────────────────────
String _fmt(num? n) => n == null ? '0' : NumberFormat('#,##,###').format(n);
String _apiDate(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

/// Label shown above grouped cards: "Today", "Yesterday", or "24 Apr 2026"
String _groupLabel(DateTime d) {
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final day   = DateTime(d.year, d.month, d.day);
  if (day == today) return 'Today';
  if (day == today.subtract(const Duration(days: 1))) return 'Yesterday';
  return DateFormat('d MMM yyyy').format(d);
}

/// Parse the order's created date. Falls back to epoch on failure.
DateTime _orderDate(OrderModel o) {
  return o.createdAt?.toLocal() ?? DateTime.fromMillisecondsSinceEpoch(0);
}

// ── Group orders by date ──────────────────────────────────────────────────────
/// Returns a flat list of items: either a String (date header) or OrderModel.
List<dynamic> _groupByDate(List<OrderModel> orders) {
  final result = <dynamic>[];
  String? lastLabel;
  for (final o in orders) {
    final label = _groupLabel(_orderDate(o));
    if (label != lastLabel) {
      result.add(label); // date header
      lastLabel = label;
    }
    result.add(o);
  }
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// OrdersViewPage
// ─────────────────────────────────────────────────────────────────────────────
class OrdersViewPage extends ConsumerStatefulWidget {
  const OrdersViewPage({super.key});
  @override
  ConsumerState<OrdersViewPage> createState() => _State();
}

class _State extends ConsumerState<OrdersViewPage> {
  final _searchCtrl    = TextEditingController();
  final _tabScroll     = ScrollController();
  final _listScroll    = ScrollController();

  String _q            = '';
  bool   _searching    = false;
  int    _tab          = 0;

  DateTime? _from;
  DateTime? _to;
  bool      _dateActive = false;

  List<OrderModel> _all  = [];
  int  _page    = 1;
  bool _loading = false;
  bool _hasMore = true;
  static const _limit = 20;

  @override
  void initState() {
    super.initState();
    _listScroll.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    _tabScroll.dispose();
    _listScroll.dispose();
    super.dispose();
  }

  // ── Pagination ─────────────────────────────────────────────────────────────
  void _onScroll() {
    if (_listScroll.position.pixels >=
        _listScroll.position.maxScrollExtent - 200) {
      if (!_loading && _hasMore && !_dateActive) _loadMore();
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

  void _reset() => setState(() { _all = []; _page = 1; _hasMore = true; });

  // ── Search ─────────────────────────────────────────────────────────────────
  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) { _searchCtrl.clear(); _q = ''; }
  });

  List<OrderModel> _filter(List<OrderModel> orders) {
    if (_q.isEmpty) return orders;
    final q = _q.toLowerCase();
    return orders.where((o) =>
    (o.dealer?.employeeName.toLowerCase() ?? '').contains(q) ||
        (o.dealer?.shopName.toLowerCase() ?? '').contains(q) ||
        (o.orderNumber?.toLowerCase() ?? '').contains(q) ||
        (o.dealer?.employeePhone.toString() ?? '').contains(q)).toList();
  }

  // ── Date filter ────────────────────────────────────────────────────────────
  void _clearDate() => setState(() {
    _from = null; _to = null; _dateActive = false; _reset();
  });

  void _applyDate() {
    if (_from == null || _to == null) return;
    setState(() { _dateActive = true; _reset(); });
  }

  Future<void> _pickDate(bool isFrom) async {
    final now = DateTime.now();
    final p = await showDatePicker(
      context: context,
      initialDate: isFrom
          ? (_from ?? now.subtract(const Duration(days: 30)))
          : (_to ?? now),
      firstDate: DateTime(2023),
      lastDate: now,
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _kP, onPrimary: _kWhite,
            surface: _kWhite, onSurface: _kT1,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: _kWhite),
        ),
        child: child!,
      ),
    );
    if (p == null) return;
    setState(() {
      if (isFrom) { _from = p; if (_to != null && _to!.isBefore(p)) _to = p; }
      else { _to = p; if (_from != null && _from!.isAfter(p)) _from = p; }
    });
  }

  void _showDateSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: _kWhite,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) => StatefulBuilder(builder: (ctx, ss) {
        final sw = MediaQuery.sizeOf(context).width;
        final sh = MediaQuery.sizeOf(context).height;
        final canApply = _from != null && _to != null;

        String fmtD(DateTime? d) => d == null
            ? 'Select date'
            : DateFormat('d MMM yyyy').format(d);

        return Padding(
          padding: EdgeInsets.fromLTRB(
              sw * 0.05, sh * 0.02, sw * 0.05,
              sh * 0.04 + MediaQuery.viewInsetsOf(ctx).bottom),
          child: Column(mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(child: Container(
                width: sw * 0.1, height: 3,
                decoration: BoxDecoration(
                    color: _kBd, borderRadius: BorderRadius.circular(2)),
              )),
              SizedBox(height: sh * 0.022),

              // Title + clear
              Row(children: [
                Text('Date Filter', style: TextStyle(
                  fontSize: (sw * 0.042).clamp(14.0, 19.0),
                  fontWeight: FontWeight.w700, color: _kT1,
                )),
                const Spacer(),
                if (_dateActive)
                  GestureDetector(
                    onTap: () { _clearDate(); Navigator.pop(ctx); },
                    child: Text('Clear', style: TextStyle(
                      fontSize: (sw * 0.032).clamp(11.0, 14.0),
                      color: _kRed, fontWeight: FontWeight.w600,
                    )),
                  ),
              ]),
              SizedBox(height: sh * 0.025),

              // From / To rows
              _DateRow(
                label: 'From',
                value: fmtD(_from),
                hasValue: _from != null,
                sw: sw, sh: sh,
                onTap: () async {
                  await _pickDate(true); ss(() {});
                },
              ),
              SizedBox(height: sh * 0.012),
              _DateRow(
                label: 'To',
                value: fmtD(_to),
                hasValue: _to != null,
                sw: sw, sh: sh,
                onTap: () async {
                  await _pickDate(false); ss(() {});
                },
              ),
              SizedBox(height: sh * 0.03),

              // Apply button
              SizedBox(
                width: double.infinity,
                height: sh * 0.058,
                child: ElevatedButton(
                  onPressed: canApply ? () {
                    _applyDate(); Navigator.pop(ctx);
                  } : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kP,
                    disabledBackgroundColor: _kBd,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(
                          (sw * 0.03).clamp(8.0, 12.0)),
                    ),
                  ),
                  child: Text('Apply', style: TextStyle(
                    fontSize: (sw * 0.038).clamp(13.0, 16.0),
                    fontWeight: FontWeight.w700,
                    color: canApply ? _kWhite : _kT4,
                  )),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // ── Tab scroll ─────────────────────────────────────────────────────────────
  void _scrollTab(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tabScroll.hasClients) return;
      _tabScroll.animateTo(
        ((i * 90.0) - 60.0).clamp(0.0, _tabScroll.position.maxScrollExtent),
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut,
      );
    });
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw  = MediaQuery.sizeOf(context).width;
    final sh  = MediaQuery.sizeOf(context).height;
    final tab = _tabs[_tab.clamp(0, _tabs.length - 1)];

    final AsyncValue<List<OrderModel>> async$ = _dateActive && _from != null && _to != null
        ? ref.watch(filteredOrdersProvider(DateFilterParams(
        startDate: _apiDate(_from!), endDate: _apiDate(_to!))))
        : ref.watch(paginatedOrdersProvider(PaginatedOrderParams(
        status: tab.api, page: _page, limit: _limit)));

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [

        // ── Top bar ──────────────────────────────────────────────────────────
        Container(
          color: _kWhite,
          child: Column(children: [

            // Title row
            Padding(
              padding: EdgeInsets.fromLTRB(
                  sw * 0.045, sh * 0.018, sw * 0.04, sh * 0.014),
              child: Row(children: [
                Expanded(child: Text('Orders', style: TextStyle(
                  fontSize: (sw * 0.052).clamp(17.0, 26.0),
                  fontWeight: FontWeight.w800,
                  color: _kT1, letterSpacing: -0.4,
                ))),
                // Search toggle
                _IconBtn(
                  icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                  active: _searching,
                  activeColor: _kRed,
                  sw: sw,
                  onTap: _toggleSearch,
                ),
                SizedBox(width: sw * 0.02),
                // Date filter
                _IconBtn(
                  icon: Icons.tune_rounded,
                  active: _dateActive,
                  activeColor: _kP,
                  sw: sw,
                  onTap: _showDateSheet,
                ),
              ]),
            ),

            // Search field
            AnimatedSize(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeInOut,
              child: _searching
                  ? Padding(
                padding: EdgeInsets.fromLTRB(
                    sw * 0.045, 0, sw * 0.045, sh * 0.012),
                child: _SearchField(
                  controller: _searchCtrl,
                  sw: sw, sh: sh,
                  onChanged: (v) => setState(() => _q = v),
                  onClear: () => setState(() {
                    _searchCtrl.clear(); _q = '';
                  }),
                ),
              )
                  : const SizedBox.shrink(),
            ),

            // Date active banner
            if (_dateActive && _from != null && _to != null)
              _DateBanner(from: _from!, to: _to!, sw: sw, sh: sh,
                  onClear: _clearDate),

            // Status chips
            _StatusChips(
              tabs: _tabs,
              selected: _tab,
              disabled: _dateActive,
              scrollCtrl: _tabScroll,
              sw: sw, sh: sh,
              onSelect: (i) {
                HapticFeedback.selectionClick();
                setState(() { _tab = i; _reset(); });
                _scrollTab(i);
              },
            ),

            // Bottom border
            Container(height: 0.5, color: _kBd),
          ]),
        ),

        // ── List ─────────────────────────────────────────────────────────────
        Expanded(child: async$.when(
          loading: () => const Center(
              child: CircularProgressIndicator(color: _kP, strokeWidth: 2)),
          error: (_, __) => _ErrorView(sw: sw, sh: sh, onRetry: () {
            _reset();
            if (_dateActive) {
              ref.invalidate(filteredOrdersProvider);
            } else {
              ref.invalidate(paginatedOrdersProvider);
            }
          }),
          data: (orders) {
            // Accumulate paginated orders
            if (!_dateActive) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (!mounted) return;
                if (_page == 1) {
                  if (_all.length != orders.length ||
                      (_all.isNotEmpty && orders.isNotEmpty &&
                          _all.first.orderNumber != orders.first.orderNumber)) {
                    setState(() => _all = List.from(orders));
                  }
                } else {
                  final seen = _all.map((o) => o.orderNumber).toSet();
                  final fresh = orders.where((o) => !seen.contains(o.orderNumber)).toList();
                  if (fresh.isNotEmpty) setState(() => _all.addAll(fresh));
                }
              });
            }

            final display  = _dateActive ? orders : (_all.isEmpty ? orders : _all);
            final filtered = _filter(display);

            if (filtered.isEmpty) {
              return _EmptyView(
              sw: sw, sh: sh,
              isSearch: _searching && _q.isNotEmpty,
              isDate: _dateActive,
              query: _q,
              tabLabel: _tabs[_tab.clamp(0, _tabs.length - 1)].label,
              onClear: _clearDate,
              onAll: () => setState(() {
                _tab = 0; _reset(); _scrollTab(0);
              }),
            );
            }

            // Build grouped list items
            final items = _groupByDate(filtered);

            return RefreshIndicator(
              color: _kP,
              backgroundColor: _kWhite,
              onRefresh: () async {
                _reset();
                if (_dateActive) {
                  ref.invalidate(filteredOrdersProvider);
                } else {
                  ref.invalidate(paginatedOrdersProvider);
                }
                await Future.delayed(const Duration(milliseconds: 400));
              },
              child: ListView.builder(
                controller: _listScroll,
                padding: EdgeInsets.fromLTRB(
                    sw * 0.045, sh * 0.016, sw * 0.045, sh * 0.04),
                itemCount: items.length + (_loading ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == items.length) {
                    return Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: sh * 0.02),
                        child: const CircularProgressIndicator(
                            color: _kP, strokeWidth: 2),
                      ),
                    );
                  }
                  final item = items[i];

                  // ── Date header ──────────────────────────────────────────
                  if (item is String) {
                    return Padding(
                      padding: EdgeInsets.only(
                        top: i == 0 ? 0 : sh * 0.018,
                        bottom: sh * 0.01,
                      ),
                      child: Row(children: [
                        Text(item, style: TextStyle(
                          fontSize: (sw * 0.03).clamp(10.0, 13.0),
                          fontWeight: FontWeight.w600,
                          color: _kT3,
                          letterSpacing: 0.2,
                        )),
                        SizedBox(width: sw * 0.025),
                        Expanded(child: Container(
                            height: 0.5, color: _kBd)),
                      ]),
                    );
                  }

                  // ── Order card ───────────────────────────────────────────
                  final order = item as OrderModel;
                  return Padding(
                    padding: EdgeInsets.only(bottom: sh * 0.012),
                    child: _OrderCard(
                      order: order, sw: sw, sh: sh,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(builder: (_) => OrderViewPage(
                              orderNumber: order.orderNumber.toString()))),
                    ),
                  );
                },
              ),
            );
          },
        )),
      ])),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────────────────────────

// ── Icon button ───────────────────────────────────────────────────────────────
class _IconBtn extends StatelessWidget {
  const _IconBtn({required this.icon, required this.active,
    required this.activeColor, required this.sw, required this.onTap});
  final IconData icon; final bool active;
  final Color activeColor; final double sw; final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sz = (sw * 0.088).clamp(32.0, 42.0);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: sz, height: sz,
        decoration: BoxDecoration(
          color: active
              ? activeColor.withValues(alpha: 0.08)
              : const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(sz / 2),
          border: Border.all(
            color: active
                ? activeColor.withValues(alpha: 0.35)
                : Colors.transparent,
            width: 0.5,
          ),
        ),
        child: Icon(icon,
            size: (sw * 0.048).clamp(16.0, 22.0),
            color: active ? activeColor : _kT3),
      ),
    );
  }
}

// ── Search field ──────────────────────────────────────────────────────────────
class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.sw,
    required this.sh, required this.onChanged, required this.onClear});
  final TextEditingController controller;
  final double sw, sh;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final r = (sw * 0.025).clamp(8.0, 12.0);
    return TextField(
      controller: controller,
      autofocus: true,
      onChanged: onChanged,
      style: TextStyle(
          fontSize: (sw * 0.035).clamp(12.0, 15.0), color: _kT1),
      decoration: InputDecoration(
        hintText: 'Search orders, dealers...',
        hintStyle: TextStyle(
            fontSize: (sw * 0.033).clamp(11.0, 14.0), color: _kT4),
        prefixIcon: Icon(Icons.search_rounded,
            color: _kP, size: (sw * 0.045).clamp(16.0, 20.0)),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
            icon: Icon(Icons.close_rounded,
                size: (sw * 0.04).clamp(14.0, 18.0), color: _kT3),
            onPressed: onClear)
            : null,
        filled: true,
        fillColor: const Color(0xFFF9FAFB),
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

// ── Date active banner ────────────────────────────────────────────────────────
class _DateBanner extends StatelessWidget {
  const _DateBanner({required this.from, required this.to,
    required this.sw, required this.sh, required this.onClear});
  final DateTime from, to;
  final double sw, sh;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('d MMM yyyy');
    return Container(
      margin: EdgeInsets.fromLTRB(sw * 0.045, 0, sw * 0.045, sh * 0.01),
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.035, vertical: sh * 0.008),
      decoration: BoxDecoration(
        color: _kPBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _kPBd, width: 0.5),
      ),
      child: Row(children: [
        Icon(Icons.date_range_rounded,
            size: (sw * 0.038).clamp(13.0, 16.0), color: _kP),
        SizedBox(width: sw * 0.02),
        Expanded(child: Text(
          '${fmt.format(from)} → ${fmt.format(to)}',
          style: TextStyle(
            fontSize: (sw * 0.03).clamp(10.0, 13.0),
            color: _kP, fontWeight: FontWeight.w600,
          ),
        )),
        GestureDetector(
          onTap: onClear,
          child: Icon(Icons.close_rounded,
              size: (sw * 0.038).clamp(13.0, 16.0), color: _kP),
        ),
      ]),
    );
  }
}

// ── Status chips row ──────────────────────────────────────────────────────────
class _StatusChips extends StatelessWidget {
  const _StatusChips({required this.tabs, required this.selected,
    required this.disabled, required this.scrollCtrl,
    required this.sw, required this.sh, required this.onSelect});
  final List<_Tab> tabs;
  final int selected;
  final bool disabled;
  final ScrollController scrollCtrl;
  final double sw, sh;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: sh * 0.052,
      child: ListView.builder(
        controller: scrollCtrl,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.fromLTRB(
            sw * 0.045, sh * 0.006, sw * 0.045, sh * 0.008),
        itemCount: tabs.length,
        itemBuilder: (_, i) {
          final t   = tabs[i];
          final sel = selected == i && !disabled;
          final dot = _dotColor(t.api);

          return GestureDetector(
            onTap: disabled ? null : () => onSelect(i),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: EdgeInsets.only(right: sw * 0.02),
              padding: EdgeInsets.symmetric(
                horizontal: sw * 0.03,
                vertical: sh * 0.004,
              ),
              decoration: BoxDecoration(
                color: sel ? _kWhite : Colors.transparent,
                borderRadius: BorderRadius.circular(
                    (sh * 0.018).clamp(10.0, 20.0)),
                border: Border.all(
                  color: sel ? dot : _kBd,
                  width: sel ? 1.0 : 0.5,
                ),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                if (t.api != null) ...[
                  Container(
                    width: (sw * 0.016).clamp(5.0, 7.0),
                    height: (sw * 0.016).clamp(5.0, 7.0),
                    decoration: BoxDecoration(
                      color: disabled ? _kBd : dot,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: sw * 0.015),
                ],
                Text(t.label, style: TextStyle(
                  fontSize: (sw * 0.029).clamp(10.0, 12.5),
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: disabled ? _kT4
                      : sel ? _kT1 : _kT3,
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

// ── Date row in bottom sheet ──────────────────────────────────────────────────
class _DateRow extends StatelessWidget {
  const _DateRow({required this.label, required this.value,
    required this.hasValue, required this.sw, required this.sh,
    required this.onTap});
  final String label, value;
  final bool hasValue;
  final double sw, sh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: sw * 0.04, vertical: sh * 0.016),
        decoration: BoxDecoration(
          color: hasValue ? _kPBg : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular((sw * 0.025).clamp(8.0, 12.0)),
          border: Border.all(
              color: hasValue ? _kPBd : _kBd, width: 0.5),
        ),
        child: Row(children: [
          Icon(Icons.calendar_today_outlined,
            size: (sw * 0.04).clamp(14.0, 18.0),
            color: hasValue ? _kP : _kT4,
          ),
          SizedBox(width: sw * 0.03),
          Expanded(child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(
                fontSize: (sw * 0.026).clamp(9.0, 11.0),
                color: _kT4, fontWeight: FontWeight.w500,
              )),
              SizedBox(height: sh * 0.002),
              Text(value, style: TextStyle(
                fontSize: (sw * 0.032).clamp(11.0, 14.0),
                color: hasValue ? _kP : _kT3,
                fontWeight: hasValue ? FontWeight.w600 : FontWeight.w400,
              )),
            ],
          )),
          Icon(Icons.chevron_right_rounded,
            size: (sw * 0.045).clamp(16.0, 20.0),
            color: _kT4,
          ),
        ]),
      ),
    );
  }
}

// ── Order card ────────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  const _OrderCard({required this.order, required this.sw,
    required this.sh, required this.onTap});
  final OrderModel order;
  final double sw, sh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final st  = _ss(order.status);
    final pri = _priColor(order.priority);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.035).clamp(10.0, 16.0)),
          border: Border.all(color: _kBd, width: 0.5),
        ),
        child: Column(children: [
          // ── Main row ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(sw * 0.038),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Icon box
              Container(
                width: (sw * 0.105).clamp(36.0, 52.0),
                height: (sw * 0.105).clamp(36.0, 52.0),
                decoration: BoxDecoration(
                  color: _kPBg,
                  borderRadius: BorderRadius.circular(
                      (sw * 0.025).clamp(8.0, 12.0)),
                  border: Border.all(color: _kPBd, width: 0.5),
                ),
                child: Center(child: SvgPicture.asset(
                  AppIcons.box,
                  width: (sw * 0.048).clamp(16.0, 24.0),
                  height: (sw * 0.048).clamp(16.0, 24.0),
                  colorFilter: const ColorFilter.mode(_kP, BlendMode.srcIn),
                )),
              ),
              SizedBox(width: sw * 0.03),

              // Info
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(order.orderNumber ?? 'N/A', style: TextStyle(
                    fontSize: (sw * 0.036).clamp(12.0, 16.0),
                    fontWeight: FontWeight.w700, color: _kT1,
                    letterSpacing: -0.2,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: sh * 0.004),
                  Text(order.dealer?.employeeName ?? 'N/A', style: TextStyle(
                    fontSize: (sw * 0.03).clamp(10.0, 13.0),
                    color: _kT3, fontWeight: FontWeight.w500,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  SizedBox(height: sh * 0.002),
                  Text(order.dealer?.shopName ?? '', style: TextStyle(
                    fontSize: (sw * 0.028).clamp(9.5, 12.0),
                    color: _kT4,
                  ), maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              )),

              SizedBox(width: sw * 0.02),
              // Status pill
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.022,
                  vertical: sh * 0.005,
                ),
                decoration: BoxDecoration(
                  color: st.bg,
                  borderRadius: BorderRadius.circular(
                      (sw * 0.04).clamp(10.0, 20.0)),
                  border: Border.all(color: st.bd, width: 0.5),
                ),
                child: Text(order.status ?? '', style: TextStyle(
                  fontSize: (sw * 0.024).clamp(8.5, 11.0),
                  fontWeight: FontWeight.w700, color: st.fg,
                  height: 1.0,
                )),
              ),
            ]),
          ),

          // ── Divider ───────────────────────────────────────────────────
          Container(height: 0.5, color: const Color(0xFFF3F4F6)),

          // ── Footer row ────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.038, vertical: sw * 0.028),
            child: Row(children: [
              // Items
              _Chip(
                icon: Icons.inventory_2_outlined,
                label: '${order.orderDetails.length} item${order.orderDetails.length != 1 ? 's' : ''}',
                color: _kT3,
                bg: const Color(0xFFF3F4F6),
                sw: sw,
              ),
              SizedBox(width: sw * 0.02),
              // Amount
              if (order.totalPrice != null)
                _Chip(
                  icon: Icons.currency_rupee_rounded,
                  label: _fmt(order.totalPrice),
                  color: _kGreen,
                  bg: _kGreenBg,
                  sw: sw,
                ),
              const Spacer(),
              // Priority
              Row(children: [
                Container(
                  width: (sw * 0.016).clamp(5.0, 7.0),
                  height: (sw * 0.016).clamp(5.0, 7.0),
                  decoration: BoxDecoration(color: pri, shape: BoxShape.circle),
                ),
                SizedBox(width: sw * 0.012),
                Text(order.priority, style: TextStyle(
                  fontSize: (sw * 0.028).clamp(9.5, 12.0),
                  fontWeight: FontWeight.w700, color: pri,
                  height: 1.0,
                )),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({required this.icon, required this.label,
    required this.color, required this.bg, required this.sw});
  final IconData icon; final String label;
  final Color color, bg; final double sw;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
        horizontal: sw * 0.022, vertical: sw * 0.01),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: (sw * 0.03).clamp(10.0, 14.0), color: color),
      SizedBox(width: sw * 0.01),
      Text(label, style: TextStyle(
        fontSize: (sw * 0.027).clamp(9.0, 12.0),
        color: color, fontWeight: FontWeight.w600, height: 1.0,
      )),
    ]),
  );
}

// ── Empty & Error ─────────────────────────────────────────────────────────────
class _EmptyView extends StatelessWidget {
  const _EmptyView({required this.sw, required this.sh,
    required this.isSearch, required this.isDate,
    required this.query, required this.tabLabel,
    required this.onClear, required this.onAll});
  final double sw, sh;
  final bool isSearch, isDate;
  final String query, tabLabel;
  final VoidCallback onClear, onAll;

  @override
  Widget build(BuildContext context) {
    final circSz = (sw * 0.2).clamp(64.0, 96.0);
    return Center(child: Padding(
      padding: EdgeInsets.symmetric(horizontal: sw * 0.1),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: circSz, height: circSz,
          decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6), shape: BoxShape.circle),
          child: Icon(
              isDate ? Icons.date_range_outlined : Icons.inbox_outlined,
              size: (sw * 0.09).clamp(30.0, 44.0), color: _kBd),
        ),
        SizedBox(height: sh * 0.02),
        Text(
          isSearch ? 'No results for "$query"'
              : isDate ? 'No orders in range'
              : 'No $tabLabel orders',
          style: TextStyle(fontSize: (sw * 0.038).clamp(13.0, 17.0),
              fontWeight: FontWeight.w600, color: _kT2),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: sh * 0.008),
        Text(
          isDate ? 'Try a different date range'
              : 'Orders will appear here',
          style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0),
              color: _kT4),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: sh * 0.025),
        if (isDate)
          _TextBtn(label: 'Clear Filter', onTap: onClear, sw: sw, sh: sh)
        else if (tabLabel != 'All')
          _TextBtn(label: 'View All Orders', onTap: onAll, sw: sw, sh: sh),
      ]),
    ));
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.sw, required this.sh, required this.onRetry});
  final double sw, sh; final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final circSz = (sw * 0.2).clamp(64.0, 96.0);
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: circSz, height: circSz,
        decoration: const BoxDecoration(color: _kRedBg, shape: BoxShape.circle),
        child: Icon(Icons.wifi_off_rounded,
            size: (sw * 0.08).clamp(28.0, 42.0), color: _kRed),
      ),
      SizedBox(height: sh * 0.02),
      Text('No Connection', style: TextStyle(
          fontSize: (sw * 0.04).clamp(13.0, 18.0),
          fontWeight: FontWeight.w600, color: _kT2)),
      SizedBox(height: sh * 0.025),
      _TextBtn(label: 'Retry', onTap: onRetry, sw: sw, sh: sh),
    ]));
  }
}

class _TextBtn extends StatelessWidget {
  const _TextBtn({required this.label, required this.onTap,
    required this.sw, required this.sh});
  final String label; final VoidCallback onTap;
  final double sw, sh;

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.05, vertical: sh * 0.012),
      decoration: BoxDecoration(
        color: _kPBg,
        borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
        border: Border.all(color: _kPBd, width: 0.5),
      ),
      child: Text(label, style: TextStyle(
        fontSize: (sw * 0.033).clamp(11.0, 14.0),
        fontWeight: FontWeight.w600, color: _kP,
      )),
    ),
  );
}