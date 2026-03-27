import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../screen/loadingScreen.dart';
import '../controller/order_controller.dart';
import '../../../model/order_model.dart';
import 'order_view_page.dart';

// ─── Status colour map ────────────────────────────────────────────────────────
_StatusStyle _statusStyle(String? status) {
  switch (status?.toUpperCase()) {
    case 'PENDING':
      return _StatusStyle(const Color(0xFFB45309), const Color(0xFFFFFBEB), const Color(0xFFFCD28A));
    case 'CONFIRMED':
      return _StatusStyle(const Color(0xFF1B4FD8), const Color(0xFFEEF2FF), const Color(0xFFC7D2FE));
    case 'PRODUCTION':
      return _StatusStyle(const Color(0xFFEA580C), const Color(0xFFFFF7ED), const Color(0xFFFED7AA));
    case 'PACKED':
      return _StatusStyle(const Color(0xFF7C3AED), const Color(0xFFF5F3FF), const Color(0xFFDDD6FE));
    case 'INVOICE':
      return _StatusStyle(const Color(0xFF4338CA), const Color(0xFFEEF2FF), const Color(0xFFC7D2FE));
    case 'SHIPPED':
      return _StatusStyle(const Color(0xFF0369A1), const Color(0xFFE0F2FE), const Color(0xFFBAE6FD));
    case 'DELIVERED':
    case 'COMPLETED':
      return _StatusStyle(const Color(0xFF0A8A5C), const Color(0xFFEDFAF4), const Color(0xFF9FE0C5));
    case 'CANCELLED':
      return _StatusStyle(const Color(0xFFDC2626), const Color(0xFFFEF2F2), const Color(0xFFFECACA));
    default:
      return _StatusStyle(const Color(0xFF6B7280), const Color(0xFFF3F4F6), const Color(0xFFE5E7EB));
  }
}

class _StatusStyle {
  final Color fg, bg, border;
  const _StatusStyle(this.fg, this.bg, this.border);
}

// ─── Status tab data ──────────────────────────────────────────────────────────
class _StatusTab {
  final String label;
  final String? apiValue; // null = ALL
  final IconData icon;

  const _StatusTab({required this.label, this.apiValue, required this.icon});
}

const List<_StatusTab> _kTabs = [
  _StatusTab(label: 'All',        apiValue: null,          icon: Icons.grid_view_rounded),
  _StatusTab(label: 'Pending',    apiValue: 'PENDING',     icon: Icons.pending_actions_rounded),
  _StatusTab(label: 'Confirmed',  apiValue: 'CONFIRMED',   icon: Icons.verified_rounded),
  _StatusTab(label: 'Production', apiValue: 'PRODUCTION',  icon: Icons.precision_manufacturing_rounded),
  _StatusTab(label: 'Packed',     apiValue: 'PACKED',      icon: Icons.inventory_2_outlined),
  _StatusTab(label: 'Invoice',    apiValue: 'INVOICE',     icon: Icons.receipt_long_rounded),
  _StatusTab(label: 'Shipped',    apiValue: 'SHIPPED',     icon: Icons.local_shipping_outlined),
  _StatusTab(label: 'Delivered',  apiValue: 'DELIVERED',   icon: Icons.check_circle_outline_rounded),
  _StatusTab(label: 'Completed',  apiValue: 'COMPLETED',   icon: Icons.task_alt_rounded),
  _StatusTab(label: 'Cancelled',  apiValue: 'CANCELLED',   icon: Icons.cancel_outlined),
];

// ─── Page ─────────────────────────────────────────────────────────────────────
class OrdersViewPage extends ConsumerStatefulWidget {
  const OrdersViewPage({super.key});

  @override
  ConsumerState<OrdersViewPage> createState() => _OrdersViewPageState();
}

class _OrdersViewPageState extends ConsumerState<OrdersViewPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _tabScrollController = ScrollController();
  String _searchQuery = '';
  bool _isSearching = false;
  int _selectedTabIndex = 0; // index into _kTabs

  DateTimeRange? _selectedDateRange;
  bool _isDateFilterActive = false;

  @override
  void dispose() {
    _searchController.dispose();
    _tabScrollController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  void _clearDateFilter() => setState(() {
    _selectedDateRange = null;
    _isDateFilterActive = false;
  });

  String _formatSheetDate(DateTime d) {
    const m = ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'];
    return '${d.day} ${m[d.month - 1]} ${d.year}';
  }

  String _toApiDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';

  String _fmt(num? n) => n == null ? '0' : NumberFormat('#,##,###').format(n);

  // Dot colour per status for Option C chips
  Color _tabDotColor(String? apiValue) {
    switch (apiValue?.toUpperCase()) {
      case 'PENDING':    return const Color(0xFFB45309);
      case 'CONFIRMED':  return const Color(0xFF1B4FD8);
      case 'PRODUCTION': return const Color(0xFFEA580C);
      case 'PACKED':     return const Color(0xFF7C3AED);
      case 'INVOICE':    return const Color(0xFF4338CA);
      case 'SHIPPED':    return const Color(0xFF0369A1);
      case 'DELIVERED':  return const Color(0xFF0A8A5C);
      case 'COMPLETED':  return const Color(0xFF0A8A5C);
      case 'CANCELLED':  return const Color(0xFFDC2626);
      default:           return const Color(0xFF6B7280);
    }
  }

  // Scroll tab into view when selected
  void _scrollTabIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_tabScrollController.hasClients) return;
      const itemW = 95.0;
      final target = (index * itemW) - 80.0;
      _tabScrollController.animateTo(
        target.clamp(0.0, _tabScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    });
  }

  // ── Option Y: open separate date pickers for From and To ─────────────────
  Future<void> _pickFromDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateRange?.start ?? DateTime.now().subtract(const Duration(days: 30)),
      firstDate: DateTime(2023),
      lastDate: _selectedDateRange?.end ?? DateTime.now(),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1B4FD8), onPrimary: Colors.white,
            surface: Colors.white, onSurface: Color(0xFF111827),
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      final end = _selectedDateRange?.end ?? DateTime.now();
      _selectedDateRange = DateTimeRange(
        start: picked,
        end: picked.isAfter(end) ? picked : end,
      );
      _isDateFilterActive = true;
    });
  }

  Future<void> _pickToDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDateRange?.end ?? DateTime.now(),
      firstDate: _selectedDateRange?.start ?? DateTime(2023),
      lastDate: DateTime.now(),
      builder: (c, child) => Theme(
        data: Theme.of(c).copyWith(
          colorScheme: const ColorScheme.light(
            primary: Color(0xFF1B4FD8), onPrimary: Colors.white,
            surface: Colors.white, onSurface: Color(0xFF111827),
          ),
          dialogTheme: const DialogThemeData(backgroundColor: Colors.white),
        ),
        child: child!,
      ),
    );
    if (picked == null) return;
    setState(() {
      final start = _selectedDateRange?.start ?? DateTime(2023);
      _selectedDateRange = DateTimeRange(
        start: picked.isBefore(start) ? picked : start,
        end: picked,
      );
      _isDateFilterActive = true;
    });
  }

  List<OrderModel> _applySearchFilter(List<OrderModel> orders) {
    if (_searchQuery.isEmpty) return orders;
    final q = _searchQuery.toLowerCase();
    return orders.where((o) =>
    (o.dealer?.employeeName.toLowerCase() ?? '').contains(q) ||
        (o.dealer?.shopName.toLowerCase() ?? '').contains(q) ||
        (o.orderNumber?.toLowerCase() ?? '').contains(q) ||
        (o.dealer?.employeePhone.toString() ?? '').contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final selectedTab = _kTabs[_selectedTabIndex];

    final AsyncValue<List<OrderModel>> ordersAsync;
    if (_isDateFilterActive && _selectedDateRange != null) {
      ordersAsync = ref.watch(filteredOrdersProvider(DateFilterParams(
        startDate: _toApiDate(_selectedDateRange!.start),
        endDate: _toApiDate(_selectedDateRange!.end),
      )));
    } else {
      ordersAsync = ref.watch(ordersProvider(OrderStatusParams(
        status: selectedTab.apiValue,
      )));
    }

    return ordersAsync.when(
      loading: () => const GlobalLoader(),
      error: (err, _) => _buildError(context, sw, sh),
      data: (orders) {
        final filtered = _applySearchFilter(orders);
        return Column(children: [

          // ── Header ───────────────────────────────────────────────────────
          Container(
            color: Colors.white,
            child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(sw * 0.045, sh * 0.018, sw * 0.04, sh * 0.012),
                child: Row(children: [
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('Orders',
                          style: TextStyle(fontSize: sw * 0.055, fontWeight: FontWeight.w800,
                              color: const Color(0xFF0F1C3F), letterSpacing: -0.5)),
                      if (orders.isNotEmpty)
                        Text('${filtered.length} order${filtered.length != 1 ? 's' : ''}',
                            style: TextStyle(fontSize: sw * 0.03, color: const Color(0xFF9CA3AF),
                                fontWeight: FontWeight.w500)),
                    ]),
                  ),
                  // Search button
                  _HeaderBtn(
                    active: _isSearching,
                    icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
                    activeColor: const Color(0xFFDC2626),
                    onTap: _toggleSearch,
                  ),
                ]),
              ),

              // ── Option Y: From / To date pill pair ───────────────────────
              Padding(
                padding: EdgeInsets.fromLTRB(sw * 0.045, 0, sw * 0.045, sh * 0.012),
                child: Row(children: [
                  // From pill
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickFromDate,
                      child: _DatePill(
                        sw: sw,
                        label: 'From',
                        value: _selectedDateRange != null
                            ? _formatSheetDate(_selectedDateRange!.start)
                            : null,
                        active: _isDateFilterActive,
                      ),
                    ),
                  ),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.025),
                    child: Icon(Icons.arrow_forward_rounded,
                        size: sw * 0.04, color: const Color(0xFF9CA3AF)),
                  ),
                  // To pill
                  Expanded(
                    child: GestureDetector(
                      onTap: _pickToDate,
                      child: _DatePill(
                        sw: sw,
                        label: 'To',
                        value: _selectedDateRange != null
                            ? _formatSheetDate(_selectedDateRange!.end)
                            : null,
                        active: _isDateFilterActive,
                      ),
                    ),
                  ),
                  // Clear button — only when active
                  if (_isDateFilterActive) ...[
                    SizedBox(width: sw * 0.025),
                    GestureDetector(
                      onTap: _clearDateFilter,
                      child: Container(
                        width: sw * 0.085,
                        height: sw * 0.085,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFEF2F2),
                          borderRadius: BorderRadius.circular(sw * 0.022),
                          border: Border.all(color: const Color(0xFFFECACA)),
                        ),
                        child: const Icon(Icons.close_rounded,
                            size: 16, color: Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ]),
              ),

              // ── Search bar ───────────────────────────────────────────────
              AnimatedSize(
                duration: const Duration(milliseconds: 280),
                curve: Curves.easeInOut,
                child: _isSearching
                    ? Padding(
                  padding: EdgeInsets.fromLTRB(sw * 0.045, 0, sw * 0.045, sh * 0.012),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (v) => setState(() => _searchQuery = v),
                    style: TextStyle(fontSize: sw * 0.035, color: const Color(0xFF111827)),
                    decoration: InputDecoration(
                      hintText: 'Search orders, dealers, phone...',
                      hintStyle: TextStyle(color: const Color(0xFF9CA3AF), fontSize: sw * 0.033),
                      prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFF1B4FD8), size: 20),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18, color: Color(0xFF6B7280)),
                        onPressed: () => setState(() { _searchController.clear(); _searchQuery = ''; }),
                      )
                          : null,
                      filled: true,
                      fillColor: const Color(0xFFF9FAFB),
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFFE5E7EB))),
                      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Color(0xFF1B4FD8), width: 1.5)),
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),

              // ── Option C: colour dot chips ───────────────────────────────
              SizedBox(
                height: sh * 0.055,
                child: ListView.builder(
                  controller: _tabScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(sw * 0.045, 0, sw * 0.045, sh * 0.008),
                  itemCount: _kTabs.length,
                  itemBuilder: (_, i) {
                    final tab = _kTabs[i];
                    final isSelected = _selectedTabIndex == i;
                    final isDisabled = _isDateFilterActive;
                    final dotColor = _tabDotColor(tab.apiValue);

                    return GestureDetector(
                      onTap: isDisabled ? null : () {
                        setState(() => _selectedTabIndex = i);
                        _scrollTabIntoView(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        margin: EdgeInsets.only(right: sw * 0.022),
                        padding: EdgeInsets.symmetric(
                            horizontal: sw * 0.032, vertical: sw * 0.016),
                        decoration: BoxDecoration(
                          color: isDisabled
                              ? const Color(0xFFF9FAFB)
                              : isSelected
                              ? Colors.white
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDisabled
                                ? const Color(0xFFE5E7EB)
                                : isSelected
                                ? dotColor
                                : const Color(0xFFE5E7EB),
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected && !isDisabled
                              ? [BoxShadow(
                              color: dotColor.withValues(alpha: 0.18),
                              blurRadius: 8, offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          // Colour dot
                          Container(
                            width: sw * 0.018,
                            height: sw * 0.018,
                            decoration: BoxDecoration(
                              color: isDisabled
                                  ? const Color(0xFFD1D5DB)
                                  : dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: sw * 0.018),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: sw * 0.03,
                              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                              color: isDisabled
                                  ? const Color(0xFFD1D5DB)
                                  : isSelected
                                  ? const Color(0xFF111827)
                                  : const Color(0xFF6B7280),
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),

              // Bottom border
              Container(height: 1, color: const Color(0xFFF3F4F6)),
            ]),
          ),

          // ── Orders list ───────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmptyState(context, sw, sh)
                : RefreshIndicator(
              color: const Color(0xFF1B4FD8),
              backgroundColor: Colors.white,
              onRefresh: () async {
                if (_isDateFilterActive && _selectedDateRange != null) {
                  ref.invalidate(filteredOrdersProvider);
                } else {
                  ref.invalidate(ordersProvider);
                }
              },
              child: ListView.builder(
                padding: EdgeInsets.fromLTRB(sw * 0.045, sh * 0.018, sw * 0.045, sh * 0.04),
                itemCount: filtered.length,
                itemBuilder: (_, i) => _OrderCard(
                  order: filtered[i],
                  sw: sw,
                  sh: sh,
                  onTap: () => Navigator.push(context, MaterialPageRoute(
                    builder: (_) => OrderViewPage(orderNumber: filtered[i].orderNumber.toString()),
                  )),
                ),
              ),
            ),
          ),
        ]);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context, double sw, double sh) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: sw * 0.22, height: sw * 0.22,
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Icon(
            _isDateFilterActive ? Icons.date_range_outlined : Icons.inbox_outlined,
            size: sw * 0.1, color: const Color(0xFFD1D5DB),
          ),
        ),
        SizedBox(height: sh * 0.025),
        Text(
          _isSearching && _searchQuery.isNotEmpty
              ? 'No results for "$_searchQuery"'
              : _isDateFilterActive
              ? 'No orders in this date range'
              : 'No ${_kTabs[_selectedTabIndex].label} orders',
          style: TextStyle(fontSize: sw * 0.038, color: const Color(0xFF6B7280),
              fontWeight: FontWeight.w600),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: sh * 0.008),
        Text(
          _isDateFilterActive
              ? 'Try a different date range'
              : 'Orders will appear here',
          style: TextStyle(fontSize: sw * 0.03, color: const Color(0xFF9CA3AF)),
        ),
        SizedBox(height: sh * 0.025),
        if (_isDateFilterActive)
          _ActionButton(label: 'Clear Date Filter', icon: Icons.close_rounded,
              onTap: _clearDateFilter)
        else if (_selectedTabIndex != 0)
          _ActionButton(label: 'View All Orders', icon: Icons.arrow_back_rounded,
              onTap: () => setState(() { _selectedTabIndex = 0; _scrollTabIntoView(0); })),
      ]),
    );
  }

  Widget _buildError(BuildContext context, double sw, double sh) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: sw * 0.2, height: sw * 0.2,
          decoration: BoxDecoration(
            color: const Color(0xFFFEF2F2), shape: BoxShape.circle,
            border: Border.all(color: const Color(0xFFFECACA)),
          ),
          child: const Icon(Icons.wifi_off_rounded, size: 40, color: Color(0xFFDC2626)),
        ),
        SizedBox(height: sh * 0.02),
        Text('No Internet Connection',
            style: TextStyle(fontSize: sw * 0.04, fontWeight: FontWeight.w600, color: const Color(0xFF374151))),
        SizedBox(height: sh * 0.008),
        Text('Check your connection and try again',
            style: TextStyle(fontSize: sw * 0.03, color: const Color(0xFF9CA3AF))),
        SizedBox(height: sh * 0.025),
        _ActionButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          onTap: () {
            if (_isDateFilterActive && _selectedDateRange != null) {
              ref.invalidate(filteredOrdersProvider);
            } else {
              ref.invalidate(ordersProvider);
            }
          },
        ),
      ]),
    );
  }
}

// ─── Order Card ───────────────────────────────────────────────────────────────
class _OrderCard extends StatelessWidget {
  final OrderModel order;
  final double sw, sh;
  final VoidCallback onTap;

  const _OrderCard({required this.order, required this.sw, required this.sh, required this.onTap});

  String _fmt(num? n) => n == null ? '0' : NumberFormat('#,##,###').format(n);

  Color _priorityColor(String p) {
    switch (p.toUpperCase()) {
      case 'HIGH':   return const Color(0xFFDC2626);
      case 'MEDIUM': return const Color(0xFFB45309);
      default:       return const Color(0xFF0A8A5C);
    }
  }

  @override
  Widget build(BuildContext context) {
    final st = _statusStyle(order.status);
    final priColor = _priorityColor(order.priority);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: sh * 0.015),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sw * 0.04),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12, offset: const Offset(0, 3))],
        ),
        child: Column(children: [
          // ── Top ────────────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.all(sw * 0.04),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Icon badge
              Container(
                width: sw * 0.115, height: sw * 0.115,
                decoration: BoxDecoration(
                  color: const Color(0xFFEEF2FF),
                  borderRadius: BorderRadius.circular(sw * 0.03),
                  border: Border.all(color: const Color(0xFFC7D2FE)),
                ),
                child: Center(
                  child: SvgPicture.asset(AppIcons.box,
                      width: sw * 0.052, height: sw * 0.052,
                      colorFilter: const ColorFilter.mode(Color(0xFF1B4FD8), BlendMode.srcIn)),
                ),
              ),
              SizedBox(width: sw * 0.035),

              // Order info
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(order.orderNumber ?? 'N/A',
                    style: TextStyle(fontSize: sw * 0.036, fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827), letterSpacing: -0.2),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: sh * 0.004),
                Row(children: [
                  SvgPicture.asset(AppIcons.dealers, width: sw * 0.03, height: sw * 0.03,
                      colorFilter: const ColorFilter.mode(Color(0xFF6B7280), BlendMode.srcIn)),
                  SizedBox(width: sw * 0.015),
                  Expanded(child: Text(order.dealer?.employeeName ?? 'N/A',
                      style: TextStyle(fontSize: sw * 0.03, color: const Color(0xFF6B7280),
                          fontWeight: FontWeight.w500),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
                SizedBox(height: sh * 0.003),
                Row(children: [
                  Icon(Icons.storefront_outlined, size: sw * 0.03, color: const Color(0xFF9CA3AF)),
                  SizedBox(width: sw * 0.015),
                  Expanded(child: Text(order.dealer?.shopName ?? 'N/A',
                      style: TextStyle(fontSize: sw * 0.028, color: const Color(0xFF9CA3AF),
                          fontWeight: FontWeight.w400),
                      maxLines: 1, overflow: TextOverflow.ellipsis)),
                ]),
              ])),

              // Status chip
              Container(
                padding: EdgeInsets.symmetric(horizontal: sw * 0.022, vertical: sw * 0.01),
                decoration: BoxDecoration(
                  color: st.bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: st.border),
                ),
                child: Text(order.status ?? '',
                    style: TextStyle(fontSize: sw * 0.024, fontWeight: FontWeight.w700, color: st.fg)),
              ),
            ]),
          ),

          // ── Divider ────────────────────────────────────────────────────
          Container(height: 1, color: const Color(0xFFF3F4F6)),

          // ── Bottom row ─────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
            child: Row(children: [
              // Items count
              _MiniChip(
                icon: Icons.inventory_2_outlined,
                label: '${order.orderDetails.length} item${order.orderDetails.length > 1 ? 's' : ''}',
                color: const Color(0xFF6B7280),
                bg: const Color(0xFFF9FAFB),
                sw: sw,
              ),
              SizedBox(width: sw * 0.02),
              // Total price
              if (order.totalPrice != null)
                _MiniChip(
                  icon: Icons.currency_rupee_rounded,
                  label: _fmt(order.totalPrice),
                  color: const Color(0xFF0A8A5C),
                  bg: const Color(0xFFEDFAF4),
                  sw: sw,
                ),
              const Spacer(),
              // Priority dot + label
              Row(children: [
                Container(width: sw * 0.018, height: sw * 0.018,
                    decoration: BoxDecoration(color: priColor, shape: BoxShape.circle)),
                SizedBox(width: sw * 0.015),
                Text(order.priority,
                    style: TextStyle(fontSize: sw * 0.028, fontWeight: FontWeight.w700, color: priColor)),
              ]),
            ]),
          ),
        ]),
      ),
    );
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _HeaderBtn extends StatelessWidget {
  final bool active;
  final IconData icon;
  final Color activeColor;
  final VoidCallback onTap;

  const _HeaderBtn({required this.active, required this.icon,
    required this.activeColor, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: active ? activeColor.withValues(alpha: 0.1) : const Color(0xFFF3F4F6),
        shape: BoxShape.circle,
        border: Border.all(
            color: active ? activeColor.withValues(alpha: 0.4) : Colors.transparent),
      ),
      child: Icon(icon, size: 22,
          color: active ? activeColor : const Color(0xFF6B7280)),
    ),
  );
}

class _MiniChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color, bg;
  final double sw;

  const _MiniChip({required this.icon, required this.label,
    required this.color, required this.bg, required this.sw});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: sw * 0.025, vertical: sw * 0.012),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: sw * 0.032, color: color),
      SizedBox(width: sw * 0.01),
      Text(label, style: TextStyle(fontSize: sw * 0.028, color: color, fontWeight: FontWeight.w600)),
    ]),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _ActionButton({required this.label, required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF2FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFC7D2FE)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 16, color: const Color(0xFF1B4FD8)),
        const SizedBox(width: 8),
        Text(label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
            color: Color(0xFF1B4FD8))),
      ]),
    ),
  );
}

// ─── Date Pill (Option Y) ─────────────────────────────────────────────────────
class _DatePill extends StatelessWidget {
  final double sw;
  final String label;
  final String? value; // null = not set yet
  final bool active;

  const _DatePill({
    required this.sw,
    required this.label,
    required this.value,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final hasValue = value != null;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.032, vertical: sw * 0.022),
      decoration: BoxDecoration(
        color: hasValue && active
            ? const Color(0xFFEEF2FF)
            : const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(sw * 0.028),
        border: Border.all(
          color: hasValue && active
              ? const Color(0xFF1B4FD8)
              : const Color(0xFFE5E7EB),
          width: hasValue && active ? 1.5 : 1,
        ),
      ),
      child: Row(children: [
        Icon(
          Icons.calendar_today_rounded,
          size: sw * 0.034,
          color: hasValue && active
              ? const Color(0xFF1B4FD8)
              : const Color(0xFF9CA3AF),
        ),
        SizedBox(width: sw * 0.018),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: sw * 0.024,
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                hasValue ? value! : 'Select',
                style: TextStyle(
                  fontSize: sw * 0.03,
                  fontWeight: FontWeight.w600,
                  color: hasValue && active
                      ? const Color(0xFF1B4FD8)
                      : hasValue
                      ? const Color(0xFF374151)
                      : const Color(0xFF9CA3AF),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}