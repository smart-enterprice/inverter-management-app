import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../model/user_model.dart';
import '../../controller/signUp_controller.dart';
import '../../../../widgets/circle_button.dart';

// ── Design tokens (mirrors your app exactly) ──────────────────────────────────
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

// ── Avatar color sets (same as DealersScreen) ─────────────────────────────────
const _avatarSets = [
  (Color(0xFFEBF4FF), Color(0xFFBFD9F5), Color(0xFF185FA5)),
  (Color(0xFFEDFAF5), Color(0xFF9FE0C5), Color(0xFF0F6E56)),
  (Color(0xFFF5F3FF), Color(0xFFDDD6FE), Color(0xFF7C3AED)),
  (Color(0xFFFFFBEB), Color(0xFFFCD28A), Color(0xFFB45309)),
  (Color(0xFFFEF2F2), Color(0xFFFECACA), Color(0xFFDC2626)),
];

(Color, Color, Color) _avatarColors(int i) =>
    _avatarSets[i % _avatarSets.length];

String _initials(String name) => name.trim().split(' ').take(2)
    .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

// ═════════════════════════════════════════════════════════════════════════════
class DealerAssignmentScreen extends ConsumerStatefulWidget {
  final UserModel salesman;
  const DealerAssignmentScreen({super.key, required this.salesman});

  @override
  ConsumerState<DealerAssignmentScreen> createState() =>
      _DealerAssignmentScreenState();
}

class _DealerAssignmentScreenState
    extends ConsumerState<DealerAssignmentScreen>
    with SingleTickerProviderStateMixin {

  late final TabController _tabCtrl;

  final Set<String> _toAdd    = {};
  final Set<String> _toRemove = {};
  late Set<String> _assignedIds;

  bool _saving        = false;
  bool _selectionMode = false;
  final Set<String> _selectedForRemoval = {};

  // Search state — mirrors DealersScreen pattern
  bool _showAllSearch      = false;
  bool _showAssignedSearch = false;
  final _allSearchCtrl      = TextEditingController();
  final _assignedSearchCtrl = TextEditingController();
  final _allScrollCtrl      = ScrollController();
  final _assignedScrollCtrl = ScrollController();

  String get _salesmanId => widget.salesman.employeeId ?? '';

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _assignedIds = Set<String>.from(widget.salesman.dealers ?? []);
    _tabCtrl.addListener(() {
      if (_tabCtrl.index != 1 && _selectionMode) _exitSelectionMode();
      if (_tabCtrl.index != 0 && _showAllSearch) _closeAllSearch();
      if (_tabCtrl.index != 1 && _showAssignedSearch) _closeAssignedSearch();
    });
    _allScrollCtrl.addListener(_onAllScroll);
    _assignedScrollCtrl.addListener(_onAssignedScroll);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    _allSearchCtrl.dispose();
    _assignedSearchCtrl.dispose();
    _allScrollCtrl.dispose();
    _assignedScrollCtrl.dispose();
    super.dispose();
  }

  void _onAllScroll() {
    if (_allScrollCtrl.position.pixels >=
        _allScrollCtrl.position.maxScrollExtent - 200) {
      ref.read(dealerListProvider.notifier).loadMore();
    }
  }

  void _onAssignedScroll() {
    if (_assignedScrollCtrl.position.pixels >=
        _assignedScrollCtrl.position.maxScrollExtent - 200) {
      ref.read(salesmanDealersProvider(_salesmanId).notifier).loadMore();
    }
  }

  // ── Search helpers ─────────────────────────────────────────────────────────
  void _closeAllSearch() {
    setState(() { _showAllSearch = false; _allSearchCtrl.clear(); });
    ref.read(dealerListProvider.notifier).searchDealers('');
  }

  void _closeAssignedSearch() {
    setState(() { _showAssignedSearch = false; _assignedSearchCtrl.clear(); });
    ref.read(salesmanDealersProvider(_salesmanId).notifier).search('');
  }

  // ── Toggle (All tab) ───────────────────────────────────────────────────────
  void _toggle(String dealerId) {
    setState(() {
      if (_assignedIds.contains(dealerId)) {
        _assignedIds.remove(dealerId);
        _toRemove.add(dealerId);
        _toAdd.remove(dealerId);
      } else {
        _assignedIds.add(dealerId);
        _toAdd.add(dealerId);
        _toRemove.remove(dealerId);
      }
    });
  }

  // ── Selection mode (Assigned tab) ─────────────────────────────────────────
  void _enterSelectionMode(String id) {
    setState(() { _selectionMode = true; _selectedForRemoval.add(id); });
  }

  void _toggleSelection(String id) {
    if (!_selectionMode) return;
    setState(() {
      if (_selectedForRemoval.contains(id)) {
        _selectedForRemoval.remove(id);
        if (_selectedForRemoval.isEmpty) _selectionMode = false;
      } else {
        _selectedForRemoval.add(id);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() { _selectionMode = false; _selectedForRemoval.clear(); });
  }

  void _confirmRemoveSelected() {
    if (_selectedForRemoval.isEmpty) return;
    setState(() {
      for (final id in _selectedForRemoval) {
        _assignedIds.remove(id);
        _toRemove.add(id);
        _toAdd.remove(id);
      }
      _selectedForRemoval.clear();
      _selectionMode = false;
    });
  }

  bool get _hasPending => _toAdd.isNotEmpty || _toRemove.isNotEmpty;

  // ── Save ───────────────────────────────────────────────────────────────────
  Future<void> _save() async {
    if (!_hasPending || _saving) return;
    setState(() => _saving = true);
    final err = await ref.read(signupControllerProvider.notifier).updateDealers(
      employeeId: _salesmanId,
      addDealers:    _toAdd.isEmpty    ? null : _toAdd.toList(),
      removeDealers: _toRemove.isEmpty ? null : _toRemove.toList(),
    );
    if (!mounted) return;
    setState(() => _saving = false);
    if (err == null) {
      _toAdd.clear();
      _toRemove.clear();
      _snack('Changes saved', _kGreen);
      ref.read(salesmanDealersProvider(_salesmanId).notifier).refresh();
    } else {
      _snack('Failed: $err', _kRed);
    }
  }

  Future<bool> _confirmDiscard() async {
    if (!_hasPending) return true;
    final r = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final sw = MediaQuery.sizeOf(ctx).width;
        return AlertDialog(
          backgroundColor: _kWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0))),
          title: const Text('Discard changes?',
              style: TextStyle(fontWeight: FontWeight.w800, color: _kT1)),
          content: Text(
              'You have ${_toAdd.length + _toRemove.length} unsaved change${(_toAdd.length + _toRemove.length) == 1 ? '' : 's'}.',
              style: const TextStyle(color: _kT3)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Keep editing',
                    style: TextStyle(color: _kT3, fontWeight: FontWeight.w600))),
            TextButton(onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Discard',
                    style: TextStyle(color: _kRed, fontWeight: FontWeight.w700))),
          ],
        );
      },
    );
    return r ?? false;
  }

  void _snack(String msg, Color bg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(msg,
              style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: bg,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10))));

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    return PopScope(
      canPop: !_hasPending && !_selectionMode,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (_selectionMode) { _exitSelectionMode(); return; }
        if (await _confirmDiscard() && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
        backgroundColor: _kBg,
        body: SafeArea(child: Column(children: [

          // ── Header ────────────────────────────────────────────────────────
          _buildHeader(sw, sh),

          // ── Tabs ──────────────────────────────────────────────────────────
          if (!_selectionMode)
            Container(
              color: _kWhite,
              child: TabBar(
                controller: _tabCtrl,
                labelColor: _kP,
                unselectedLabelColor: _kT4,
                labelStyle: TextStyle(
                    fontSize: (sw * 0.034).clamp(11.5, 15.0),
                    fontWeight: FontWeight.w700),
                unselectedLabelStyle: TextStyle(
                    fontSize: (sw * 0.034).clamp(11.5, 15.0),
                    fontWeight: FontWeight.w500),
                indicatorColor: _kP,
                indicatorWeight: 2.5,
                indicatorSize: TabBarIndicatorSize.label,
                tabs: [
                  const Tab(text: 'All Dealers'),
                  Tab(child: Row(mainAxisSize: MainAxisSize.min, children: [
                    const Text('Assigned'),
                    if (_hasPending) ...[
                      SizedBox(width: sw * 0.015),
                      Container(width: 6, height: 6,
                          decoration: const BoxDecoration(
                              color: _kP, shape: BoxShape.circle)),
                    ],
                  ])),
                ],
              ),
            ),

          // ── Tab bodies ────────────────────────────────────────────────────
          Expanded(
            child: TabBarView(
              controller: _tabCtrl,
              physics: _selectionMode
                  ? const NeverScrollableScrollPhysics() : null,
              children: [
                _buildAllDealersTab(sw, sh),
                _buildAssignedTab(sw, sh),
              ],
            ),
          ),

          // ── Bottom bars ───────────────────────────────────────────────────
          if (_selectionMode)
            _buildSelectionBar(sw, sh)
          else if (_hasPending)
            _buildSaveBar(sw, sh),
        ])),
      ),
    );
  }

  // ── Header — mirrors DealersScreen header exactly ─────────────────────────
  Widget _buildHeader(double sw, double sh) {
    // Selection mode header
    if (_selectionMode) {
      return Container(
        color: _kP,
        padding: EdgeInsets.fromLTRB(
            sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
        child: Row(children: [
          CircularIconButton(
            icon: Icons.close_rounded,
            onTap: _exitSelectionMode,
          ),
          SizedBox(width: sw * 0.03),
          Expanded(
              child: Text('${_selectedForRemoval.length} selected',
                  style: TextStyle(
                      fontSize: (sw * 0.042).clamp(14.0, 20.0),
                      fontWeight: FontWeight.w700,
                      color: _kWhite,
                      letterSpacing: -0.2))),
        ]),
      );
    }

    // Tab 0 — All Dealers — search active
    if (_tabCtrl.index == 0 && _showAllSearch) {
      return Container(
        color: _kWhite,
        padding: EdgeInsets.fromLTRB(
            sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
        child: _searchBarRow(
          sw: sw,
          ctrl: _allSearchCtrl,
          hint: 'Search by name, phone or location',
          onChanged: (v) =>
              ref.read(dealerListProvider.notifier).searchDealers(v),
          onClose: _closeAllSearch,
        ),
      );
    }

    // Tab 1 — Assigned — search active
    if (_tabCtrl.index == 1 && _showAssignedSearch) {
      return Container(
        color: _kWhite,
        padding: EdgeInsets.fromLTRB(
            sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
        child: _searchBarRow(
          sw: sw,
          ctrl: _assignedSearchCtrl,
          hint: 'Search assigned dealers',
          onChanged: (v) => ref
              .read(salesmanDealersProvider(_salesmanId).notifier)
              .search(v),
          onClose: _closeAssignedSearch,
        ),
      );
    }

    // Normal header
    return Container(
      color: _kWhite,
      padding: EdgeInsets.fromLTRB(
          sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
      child: Row(children: [
        CircularIconButton(
          icon: Icons.arrow_back_ios_rounded,
          onTap: () async {
            final ok = await _confirmDiscard();
            if (!ok || !context.mounted) return;
            // ignore: use_build_context_synchronously
            Navigator.pop(context);
          },
        ),
        const Spacer(),
        Column(mainAxisSize: MainAxisSize.min, children: [
          Text('Manage Dealers',
              style: TextStyle(
                  fontSize: (sw * 0.042).clamp(14.0, 20.0),
                  fontWeight: FontWeight.w700,
                  color: _kT1,
                  letterSpacing: -0.2)),
          Text(widget.salesman.employeeName,
              style: TextStyle(
                  fontSize: (sw * 0.03).clamp(10.0, 13.0),
                  color: _kT4)),
        ]),
        const Spacer(),
        CircularIconButton(
          icon: Icons.search_rounded,
          onTap: () => setState(() {
            if (_tabCtrl.index == 0) {
              _showAllSearch = true;
            } else {
              _showAssignedSearch = true;
            }
          }),
        ),
      ]),
    );
  }

  // ── Search bar row (same style as DealersScreen) ───────────────────────────
  Widget _searchBarRow({
    required double sw,
    required TextEditingController ctrl,
    required String hint,
    required ValueChanged<String> onChanged,
    required VoidCallback onClose,
  }) {
    final r = (sw * 0.028).clamp(8.0, 12.0);
    return Row(children: [
      Expanded(
        child: TextField(
          controller: ctrl,
          autofocus: true,
          onChanged: onChanged,
          style: TextStyle(
              fontSize: (sw * 0.035).clamp(12.0, 15.0), color: _kT1),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: _kT4,
                fontSize: (sw * 0.033).clamp(11.0, 14.0)),
            prefixIcon: Icon(Icons.search_rounded,
                color: _kT4,
                size: (sw * 0.048).clamp(16.0, 22.0)),
            filled: true,
            fillColor: _kBg,
            contentPadding: EdgeInsets.zero,
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
        ),
      ),
      SizedBox(width: sw * 0.02),
      CircularIconButton(icon: Icons.close_rounded, onTap: onClose),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Tab 1 — All Dealers
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAllDealersTab(double sw, double sh) {
    final async       = ref.watch(dealerListProvider);
    final isFiltering = ref.watch(dealerFilteringProvider);
    final isLoadingMore = ref.watch(dealerLoadingMoreProvider);

    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5)),
      error: (_, __) => _errorView(sw, sh,
          onRetry: () => ref.read(dealerListProvider.notifier).refresh()),
      data: (dealers) {
        if (dealers.isEmpty) {
          return _emptyView(sw, sh,
              icon: Icons.search_off_rounded,
              label: 'No dealers found');
        }
        return Column(children: [
          // Count badge — same as DealersScreen
          _countBadge(sw, dealers.length,
              label: '${dealers.length} dealer${dealers.length != 1 ? 's' : ''}'),
          Expanded(child: Stack(children: [
            RefreshIndicator(
              color: _kP,
              backgroundColor: _kWhite,
              onRefresh: () => ref.read(dealerListProvider.notifier).refresh(),
              child: ListView.builder(
                controller: _allScrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                itemCount: dealers.length + 1,
                itemBuilder: (_, i) {
                  if (i == dealers.length) {
                    return _paginationFooter(sw,
                        isLoading: isLoadingMore,
                        hasMore: ref.read(dealerListProvider.notifier).hasMore);
                  }
                  final d = dealers[i];
                  final id = d.employeeId ?? '';
                  final isAssigned = _assignedIds.contains(id);
                  final pendingAdd = _toAdd.contains(id);
                  final pendingRemove = _toRemove.contains(id);
                  return _DealerCard(
                    dealer: d,
                    index: i,
                    isAssigned: isAssigned,
                    pendingAdd: pendingAdd,
                    pendingRemove: pendingRemove,
                    onTap: () => _toggle(id),
                  );
                },
              ),
            ),
            if (isFiltering)
              Positioned.fill(child: IgnorePointer(
                child: Container(
                  color: _kWhite.withValues(alpha: 0.65),
                  child: const Center(child: SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                        color: _kP, strokeWidth: 2.5),
                  )),
                ),
              )),
          ])),
        ]);
      },
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Tab 2 — Assigned Dealers
  // ══════════════════════════════════════════════════════════════════════════
  Widget _buildAssignedTab(double sw, double sh) {
    final async       = ref.watch(salesmanDealersProvider(_salesmanId));
    final isFiltering = ref.watch(salesmanDealerFilteringProvider);
    final isLoadingMore = ref.watch(salesmanDealerLoadingMoreProvider);

    return async.when(
      loading: () => const Center(
          child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5)),
      error: (_, __) => _errorView(sw, sh,
          onRetry: () => ref
              .read(salesmanDealersProvider(_salesmanId).notifier)
              .refresh()),
      data: (dealers) {
        if (dealers.isEmpty) {
          return _emptyView(sw, sh,
              icon: Icons.storefront_outlined,
              label: _assignedSearchCtrl.text.isEmpty
                  ? 'No dealers assigned'
                  : 'No matches found',
              subtitle: _assignedSearchCtrl.text.isEmpty
                  ? 'Switch to "All Dealers" to assign some'
                  : null);
        }
        return Column(children: [
          // Hint strip — only when not in selection mode
          if (!_selectionMode)
            Container(
              color: _kBg,
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.022),
              child: Row(children: [
                Icon(Icons.touch_app_outlined,
                    size: (sw * 0.038).clamp(13.0, 17.0), color: _kT4),
                SizedBox(width: sw * 0.02),
                Text('Long-press a dealer to select for removal',
                    style: TextStyle(
                        fontSize: (sw * 0.03).clamp(10.0, 13.0),
                        fontWeight: FontWeight.w500,
                        color: _kT3)),
              ]),
            ),

          _countBadge(sw, dealers.length,
              label: '${dealers.length} assigned'),

          Expanded(child: Stack(children: [
            RefreshIndicator(
              color: _kP,
              backgroundColor: _kWhite,
              onRefresh: () => ref
                  .read(salesmanDealersProvider(_salesmanId).notifier)
                  .refresh(),
              child: ListView.builder(
                controller: _assignedScrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                itemCount: dealers.length + 1,
                itemBuilder: (_, i) {
                  if (i == dealers.length) {
                    return _paginationFooter(sw,
                        isLoading: isLoadingMore,
                        hasMore: ref
                            .read(salesmanDealersProvider(_salesmanId).notifier)
                            .hasMore);
                  }
                  final d = dealers[i];
                  final id = d.employeeId ?? '';
                  final isQueuedRemove = _toRemove.contains(id);
                  final isSelected = _selectedForRemoval.contains(id);

                  return _DealerCard(
                    dealer: d,
                    index: i,
                    isAssigned: !isQueuedRemove,
                    pendingRemove: isQueuedRemove,
                    selectable: _selectionMode,
                    selected: isSelected,
                    onTap: _selectionMode ? () => _toggleSelection(id) : null,
                    onLongPress: !_selectionMode && !isQueuedRemove
                        ? () => _enterSelectionMode(id)
                        : null,
                  );
                },
              ),
            ),
            if (isFiltering)
              Positioned.fill(child: IgnorePointer(
                child: Container(
                  color: _kWhite.withValues(alpha: 0.65),
                  child: const Center(child: SizedBox(
                    width: 28, height: 28,
                    child: CircularProgressIndicator(
                        color: _kP, strokeWidth: 2.5),
                  )),
                ),
              )),
          ])),
        ]);
      },
    );
  }

  // ── Count badge — same pattern as DealersScreen ───────────────────────────
  Widget _countBadge(double sw, int count, {required String label}) {
    return Padding(
      padding: EdgeInsets.only(
          left: sw * 0.04,
          right: sw * 0.04,
          top: sw * 0.012,
          bottom: sw * 0.02),
      child: Row(children: [
        Container(
          padding: EdgeInsets.symmetric(
              horizontal: (sw * 0.03).clamp(10.0, 14.0),
              vertical: (sw * 0.01).clamp(3.0, 6.0)),
          decoration: BoxDecoration(
              color: _kPBg,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: _kPBd, width: 0.5)),
          child: Text(label,
              style: TextStyle(
                  fontSize: (sw * 0.029).clamp(9.5, 12.5),
                  fontWeight: FontWeight.w700,
                  color: _kP)),
        ),
      ]),
    );
  }

  // ── Pagination footer — mirrors DealersScreen ─────────────────────────────
  Widget _paginationFooter(double sw,
      {required bool isLoading, required bool hasMore}) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sw * 0.05),
        child: Center(child: SizedBox(
          width: (sw * 0.05).clamp(18.0, 24.0),
          height: (sw * 0.05).clamp(18.0, 24.0),
          child: const CircularProgressIndicator(
              color: _kP, strokeWidth: 2.2),
        )),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sw * 0.05),
        child: Center(child: Text("You've reached the end",
            style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0),
                color: _kT4,
                fontWeight: FontWeight.w500))),
      );
    }
    return const SizedBox.shrink();
  }

  // ── Bottom bars ────────────────────────────────────────────────────────────
  Widget _buildSelectionBar(double sw, double sh) {
    return Container(
      decoration: const BoxDecoration(
          color: _kWhite,
          border: Border(top: BorderSide(color: _kBd, width: 0.5))),
      padding: EdgeInsets.fromLTRB(
          sw * 0.04, sw * 0.03, sw * 0.04, sw * 0.03),
      child: SafeArea(top: false, child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _exitSelectionMode,
            style: OutlinedButton.styleFrom(
                padding: EdgeInsets.symmetric(
                    vertical: (sw * 0.032).clamp(10.0, 14.0)),
                side: const BorderSide(color: _kBd, width: 0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10))),
            child: Text('Cancel',
                style: TextStyle(
                    fontSize: (sw * 0.035).clamp(12.0, 15.0),
                    fontWeight: FontWeight.w700,
                    color: _kT3)),
          ),
        ),
        SizedBox(width: sw * 0.025),
        Expanded(flex: 2, child: ElevatedButton(
          onPressed: _selectedForRemoval.isEmpty
              ? null
              : _confirmRemoveSelected,
          style: ElevatedButton.styleFrom(
              backgroundColor: _kRed,
              foregroundColor: _kWhite,
              disabledBackgroundColor: _kBd,
              padding: EdgeInsets.symmetric(
                  vertical: (sw * 0.032).clamp(10.0, 14.0)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0),
          child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.remove_circle_outline_rounded,
                    size: (sw * 0.045).clamp(15.0, 20.0)),
                SizedBox(width: sw * 0.015),
                Text('Remove (${_selectedForRemoval.length})',
                    style: TextStyle(
                        fontSize: (sw * 0.035).clamp(12.0, 15.0),
                        fontWeight: FontWeight.w700)),
              ]),
        )),
      ])),
    );
  }

  Widget _buildSaveBar(double sw, double sh) {
    return Container(
      decoration: const BoxDecoration(
          color: _kWhite,
          border: Border(top: BorderSide(color: _kBd, width: 0.5))),
      padding: EdgeInsets.fromLTRB(
          sw * 0.04, sw * 0.03, sw * 0.04, sw * 0.03),
      child: SafeArea(top: false, child: Row(children: [
        Expanded(child: Wrap(
          spacing: sw * 0.02,
          runSpacing: sw * 0.01,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            if (_toAdd.isNotEmpty)
              _StatusPill(
                  label: '+${_toAdd.length}',
                  color: _kGreen,
                  bg: _kGreenBg,
                  bd: _kGreenBd),
            if (_toRemove.isNotEmpty)
              _StatusPill(
                  label: '−${_toRemove.length}',
                  color: _kRed,
                  bg: _kRedBg,
                  bd: _kRedBd),
            GestureDetector(
              onTap: () => setState(() {
                _assignedIds =
                Set<String>.from(widget.salesman.dealers ?? []);
                _toAdd.clear();
                _toRemove.clear();
              }),
              child: Text('Reset',
                  style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0),
                      fontWeight: FontWeight.w700,
                      color: _kT3,
                      decoration: TextDecoration.underline,
                      decorationColor: _kT3)),
            ),
          ],
        )),
        SizedBox(width: sw * 0.025),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
              backgroundColor: _kP,
              foregroundColor: _kWhite,
              disabledBackgroundColor: _kBd,
              padding: EdgeInsets.symmetric(
                  horizontal: (sw * 0.06).clamp(20.0, 28.0),
                  vertical: (sw * 0.032).clamp(10.0, 14.0)),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              elevation: 0),
          child: _saving
              ? const SizedBox(width: 16, height: 16,
              child: CircularProgressIndicator(
                  color: _kWhite, strokeWidth: 2.5))
              : Text('Save',
              style: TextStyle(
                  fontSize: (sw * 0.035).clamp(12.0, 15.0),
                  fontWeight: FontWeight.w700)),
        ),
      ])),
    );
  }

  // ── Shared empty / error views — same style as DealersScreen ──────────────
  Widget _emptyView(double sw, double sh,
      {required IconData icon,
        required String label,
        String? subtitle}) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: (sw * 0.18).clamp(60.0, 90.0),
              height: (sw * 0.18).clamp(60.0, 90.0),
              decoration: BoxDecoration(
                  color: _kWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBd, width: 0.5)),
              child: Icon(icon,
                  size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4)),
          SizedBox(height: sh * 0.02),
          Text(label,
              style: TextStyle(
                  fontSize: (sw * 0.036).clamp(12.0, 16.0),
                  fontWeight: FontWeight.w600,
                  color: _kT2)),
          if (subtitle != null) ...[
            SizedBox(height: sh * 0.006),
            Text(subtitle,
                style: TextStyle(
                    fontSize: (sw * 0.03).clamp(10.0, 13.0),
                    color: _kT4)),
          ],
        ]));
  }

  Widget _errorView(double sw, double sh,
      {required VoidCallback onRetry}) {
    return Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(
              width: (sw * 0.18).clamp(60.0, 90.0),
              height: (sw * 0.18).clamp(60.0, 90.0),
              decoration: BoxDecoration(
                  color: _kWhite,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kBd, width: 0.5)),
              child: Icon(Icons.wifi_off_rounded,
                  size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4)),
          SizedBox(height: sh * 0.02),
          Text('No Connection',
              style: TextStyle(
                  fontSize: (sw * 0.04).clamp(13.0, 18.0),
                  fontWeight: FontWeight.w600,
                  color: _kT2)),
          SizedBox(height: sh * 0.02),
          ElevatedButton(
              onPressed: onRetry,
              style: ElevatedButton.styleFrom(
                  backgroundColor: _kP,
                  foregroundColor: _kWhite,
                  shape: const CircleBorder(),
                  padding: const EdgeInsets.all(14),
                  elevation: 0),
              child: const Icon(Icons.refresh_rounded)),
        ]));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Dealer card — same style as DealersScreen._DealerCard
// ═════════════════════════════════════════════════════════════════════════════
class _DealerCard extends StatelessWidget {
  final UserModel dealer;
  final int index;
  final bool isAssigned;
  final bool pendingAdd;
  final bool pendingRemove;
  final bool selectable;
  final bool selected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _DealerCard({
    required this.dealer,
    required this.index,
    required this.isAssigned,
    this.pendingAdd    = false,
    this.pendingRemove = false,
    this.selectable    = false,
    this.selected      = false,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final c  = _avatarColors(index);

    // Subtle tint for state — same approach as your app
    Color cardBg = _kWhite;
    Color cardBd = _kBd;
    if (selected)      { cardBg = _kPBg;    cardBd = _kPBd; }
    else if (pendingAdd)    { cardBg = _kGreenBg; cardBd = _kGreenBd; }
    else if (pendingRemove) { cardBg = _kRedBg;   cardBd = _kRedBd; }

    final hasPhoto = dealer.photo != null && dealer.photo!.isNotEmpty;
    final radius   = (sw * 0.04).clamp(10.0, 18.0);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: EdgeInsets.only(bottom: sw * 0.025),
        decoration: BoxDecoration(
            color: cardBg,
            borderRadius: BorderRadius.circular(radius),
            border: Border.all(
                color: cardBd, width: selected ? 1.5 : 0.5)),
        padding: EdgeInsets.all(sw * 0.038),
        child: Row(children: [

          // Avatar (same as DealersScreen)
          Container(
            width: (sw * 0.12).clamp(42.0, 56.0),
            height: (sw * 0.12).clamp(42.0, 56.0),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: c.$1,
                border: Border.all(color: c.$2, width: 1.0)),
            child: ClipOval(child: hasPhoto
                ? CachedNetworkImage(
              imageUrl: dealer.photo!,
              fit: BoxFit.cover,
              placeholder: (_, __) => _initView(sw, c),
              errorWidget: (_, __, ___) => _initView(sw, c),
            )
                : _initView(sw, c)),
          ),
          SizedBox(width: sw * 0.035),

          // Info
          Expanded(child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Name + status badge inline
                Row(children: [
                  Flexible(
                    child: Text(
                        dealer.employeeName.replaceAll('_', ' '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontSize: (sw * 0.036).clamp(12.0, 16.0),
                            fontWeight: FontWeight.w700,
                            color: _kT1,
                            letterSpacing: -0.2)),
                  ),
                  if (pendingAdd) ...[
                    SizedBox(width: sw * 0.02),
                    _StatusPill(
                        label: 'Adding',
                        color: _kGreen,
                        bg: _kGreenBg,
                        bd: _kGreenBd),
                  ],
                  if (pendingRemove) ...[
                    SizedBox(width: sw * 0.02),
                    _StatusPill(
                        label: 'Removing',
                        color: _kRed,
                        bg: _kRedBg,
                        bd: _kRedBd),
                  ],
                ]),
                SizedBox(height: sw * 0.012),
                if ((dealer.shopName ?? '').isNotEmpty)
                  _MetaRow(
                      icon: Icons.storefront_outlined,
                      value: dealer.shopName!,
                      sw: sw),
                if ((dealer.town ?? '').isNotEmpty)
                  _MetaRow(
                      icon: Icons.location_on_outlined,
                      value: dealer.town!,
                      sw: sw),
                if (dealer.employeePhone.isNotEmpty)
                  _MetaRow(
                      icon: Icons.phone_outlined,
                      value: dealer.employeePhone,
                      sw: sw),
              ])),

          SizedBox(width: sw * 0.02),

          // Trailing — checkbox in selection, status icon otherwise
          selectable
              ? _Checkbox(selected: selected, sw: sw)
              : Container(
              width: (sw * 0.07).clamp(26.0, 34.0),
              height: (sw * 0.07).clamp(26.0, 34.0),
              decoration: BoxDecoration(
                  color: isAssigned && !pendingRemove
                      ? _kPBg
                      : _kBg,
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isAssigned && !pendingRemove
                          ? _kPBd : _kBd,
                      width: 0.5)),
              child: Icon(
                isAssigned && !pendingRemove
                    ? Icons.check_rounded
                    : Icons.add_rounded,
                size: (sw * 0.04).clamp(14.0, 18.0),
                color: isAssigned && !pendingRemove ? _kP : _kT4,
              )),
        ]),
      ),
    );
  }

  Widget _initView(double sw, (Color, Color, Color) c) => Container(
      color: c.$1,
      child: Center(child: Text(_initials(dealer.employeeName),
          style: TextStyle(
              fontSize: (sw * 0.036).clamp(12.0, 18.0),
              fontWeight: FontWeight.w800,
              color: c.$3))));
}

// ═════════════════════════════════════════════════════════════════════════════
// Small shared widgets
// ═════════════════════════════════════════════════════════════════════════════
class _MetaRow extends StatelessWidget {
  const _MetaRow(
      {required this.icon, required this.value, required this.sw});
  final IconData icon;
  final String value;
  final double sw;

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: sw * 0.005),
    child: Row(children: [
      Icon(icon,
          size: (sw * 0.035).clamp(12.0, 16.0), color: _kP),
      SizedBox(width: sw * 0.015),
      Expanded(child: Text(value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: (sw * 0.032).clamp(11.0, 14.0),
              color: _kT2,
              fontWeight: FontWeight.w500))),
    ]),
  );
}

class _StatusPill extends StatelessWidget {
  const _StatusPill(
      {required this.label,
        required this.color,
        required this.bg,
        required this.bd});
  final String label;
  final Color color, bg, bd;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: (sw * 0.02).clamp(6.0, 10.0),
            vertical: (sw * 0.006).clamp(2.0, 4.0)),
        decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: bd, width: 0.5)),
        child: Text(label,
            style: TextStyle(
                fontSize: (sw * 0.026).clamp(9.0, 11.5),
                fontWeight: FontWeight.w700,
                color: color)));
  }
}

class _Checkbox extends StatelessWidget {
  const _Checkbox({required this.selected, required this.sw});
  final bool selected;
  final double sw;

  @override
  Widget build(BuildContext context) {
    final size = (sw * 0.065).clamp(24.0, 30.0);
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      width: size, height: size,
      decoration: BoxDecoration(
          color: selected ? _kP : _kWhite,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
              color: selected ? _kP : _kBd, width: 1.5)),
      child: selected
          ? Icon(Icons.check_rounded, color: _kWhite, size: size * 0.6)
          : null,
    );
  }
}