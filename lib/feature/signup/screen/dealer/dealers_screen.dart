import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/feature/signup/controller/signUp_controller.dart';
import 'package:inverter_management_app/feature/signup/screen/dealer/dealer_view_screen.dart';
import 'package:inverter_management_app/feature/signup/screen/dealer/dealers_sign_up_screen.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../../model/user_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../repository/signUp_repository.dart';

// ─── Pagination Notifier (unchanged) ───────────────────────────────────────
class DealerListNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final SignupRepository _repo;
  int _page = 1;
  final int _limit = 1000;
  final int _totalPages = 1;
  bool _isLoadingMore = false;

  DealerListNotifier(this._repo) : super(const AsyncLoading()) {
    loadDealers(reset: true);
  }

  Future<void> loadDealers({bool reset = false}) async {
    if (reset) {
      _page = 1;
      state = const AsyncLoading();
    }
    try {
      final newData = await _repo.getDealers(page: _page, limit: _limit);
      if (reset) {
        state = AsyncData(newData);
      } else {
        final current = state.value ?? [];
        state = AsyncData([...current, ...newData]);
      }
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore) return;
    if (_page >= _totalPages) return;
    _isLoadingMore = true;
    _page++;
    await loadDealers();
    _isLoadingMore = false;
  }
}

// ─── Avatar colour sets (cycles by index) ──────────────────────────────────
const _avatarSets = [
  (Color(0xFFEEF2FF), Color(0xFFC7D4FF), Color(0xFF1B4FD8)), // blue
  (Color(0xFFEDFAF4), Color(0xFF9FE0C5), Color(0xFF0A8A5C)), // green
  (Color(0xFFF3EEFF), Color(0xFFC4A8FF), Color(0xFF7C3AED)), // purple
  (Color(0xFFFFF5EA), Color(0xFFFFCF96), Color(0xFFB05800)), // amber
  (Color(0xFFFEF2F2), Color(0xFFFECACA), Color(0xFFDC2626)), // red
];

(Color, Color, Color) _avatarColors(int i) =>
    _avatarSets[i % _avatarSets.length];

String _initials(String name) => name
    .trim()
    .split(' ')
    .take(2)
    .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
    .join();

// ─── Main Screen ────────────────────────────────────────────────────────────
class DealersScreen extends ConsumerStatefulWidget {
  const DealersScreen({super.key});

  @override
  ConsumerState<DealersScreen> createState() => _DealersScreenState();
}

class _DealersScreenState extends ConsumerState<DealersScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        ref.read(dealerListProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
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

  List<UserModel> _filterDealers(List<UserModel> dealers) {
    if (_searchQuery.isEmpty) return dealers;
    final q = _searchQuery.toLowerCase();
    return dealers.where((d) {
      return d.employeeName.toLowerCase().contains(q) ||
          d.employeePhone.toLowerCase().contains(q) ||
          (d.town ?? '').toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final dealersAsync = ref.watch(dealerListProvider);

    return dealersAsync.when(
      loading: () => const GlobalLoader(),
      error: (e, _) => _buildErrorState(context, sw, sh),
      data: (dealers) {
        final filtered = _filterDealers(dealers);
        return Scaffold(
          backgroundColor: const Color(0xFFF2F4F8),
          body: SafeArea(
            child: Column(
              children: [
                // ── Top Nav ──────────────────────────────────
                _buildTopNav(context, sw, sh),

                // ── Search Bar ───────────────────────────────
                if (_isSearching) _buildSearchBar(context, sw, sh),

                // ── Count row ────────────────────────────────
                if (!(_isSearching && _searchQuery.isEmpty))
                  _buildCountRow(
                    context,
                    sw,
                    _isSearching ? filtered.length : dealers.length,
                    _isSearching,
                  ),

                // ── List ─────────────────────────────────────
                Expanded(
                  child: _buildList(
                      context, sw, sh, filtered, dealers),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Top Nav ────────────────────────────────────────────────────────────────
  Widget _buildTopNav(
      BuildContext context, double sw, double sh) {
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: sw * 0.03),
      child: Row(
        children: [
          CircularIconButton(
            icon: Icons.arrow_back_ios_rounded,
            onTap: () => Navigator.pop(context),
          ),
          const Spacer(),
          Text(
            'Dealers',
            style: TextStyle(
              fontSize: sw * 0.042,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF111827),
              letterSpacing: -0.2,
            ),
          ),
          const Spacer(),
          CircularIconButton(
            icon: _isSearching ? Icons.close_rounded : Icons.search_rounded,
            onTap: _toggleSearch,
          ),
          SizedBox(width: sw * 0.025),
          RoleGuard(
            feature: AppFeature.createDealer,
            child: CircularIconButton(
              icon: Icons.add,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddDealerScreen()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Search Bar ───────────────────────────────────────────────────────────── //
  Widget _buildSearchBar(
      BuildContext context, double sw, double sh) {
    return Padding(
      padding:
      EdgeInsets.fromLTRB(sw * 0.04, 0, sw * 0.04, sw * 0.03),
      child: TextField(
        controller: _searchController,
        autofocus: true,
        onChanged: (v) => setState(() => _searchQuery = v),
        style: TextStyle(
            fontSize: sw * 0.036,
            color: const Color(0xFF111827),
            fontWeight: FontWeight.w500),
        decoration: InputDecoration(
          hintText: 'Search by name, phone or location',
          hintStyle: TextStyle(
              fontSize: sw * 0.034,
              color: const Color(0xFF9CA3AF),
              fontWeight: FontWeight.w400),
          prefixIcon: Icon(Icons.search_rounded,
              color: const Color(0xFF1B4FD8), size: sw * 0.05),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
            icon: Icon(Icons.clear_rounded,
                size: sw * 0.045,
                color: const Color(0xFF9CA3AF)),
            onPressed: () =>
                setState(() {
                  _searchController.clear();
                  _searchQuery = '';
                }),
          )
              : null,
          filled: true,
          fillColor: Colors.white,
          contentPadding: EdgeInsets.symmetric(
              vertical: sw * 0.035, horizontal: sw * 0.04),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.03),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.03),
            borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.03),
            borderSide: const BorderSide(
                color: Color(0xFF1B4FD8), width: 1.5),
          ),
        ),
      ),
    );
  }

  // ── Count Row ──────────────────────────────────────────────────────────────
  Widget _buildCountRow(BuildContext context, double sw, int count,
      bool isSearching) {
    return Padding(
      padding: EdgeInsets.only(
          left: sw * 0.04, right: sw * 0.04, bottom: sw * 0.025),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.03, vertical: sw * 0.01),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: const Color(0xFFC7D4FF)),
            ),
            child: Text(
              isSearching
                  ? '$count result${count != 1 ? 's' : ''} found'
                  : '$count dealers',
              style: TextStyle(
                  fontSize: sw * 0.029,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1B4FD8)),
            ),
          ),
        ],
      ),
    );
  }

  // ── List ───────────────────────────────────────────────────────────────────
  Widget _buildList(BuildContext context, double sw, double sh,
      List<UserModel> filtered, List<UserModel> all) {
    // empty search
    if (_isSearching && filtered.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: sw * 0.18,
              height: sw * 0.18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Icon(Icons.search_off_rounded,
                  size: sw * 0.09, color: const Color(0xFF9CA3AF)),
            ),
            SizedBox(height: sh * 0.02),
            Text(
              _searchQuery.isEmpty
                  ? 'Start typing to search'
                  : 'No results for "$_searchQuery"',
              style: TextStyle(
                  fontSize: sw * 0.038,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF374151)),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: sh * 0.008),
            Text(
              'Try a different name, phone or location',
              style: TextStyle(
                  fontSize: sw * 0.032,
                  color: const Color(0xFF9CA3AF)),
            ),
          ],
        ),
      );
    }

    // empty all dealers
    if (all.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: sw * 0.18,
              height: sw * 0.18,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: const Color(0xFFE5E7EB)),
              ),
              child: Icon(Icons.people_outline_rounded,
                  size: sw * 0.09, color: const Color(0xFF9CA3AF)),
            ),
            SizedBox(height: sh * 0.02),
            Text('No dealers yet',
                style: TextStyle(
                    fontSize: sw * 0.038,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF374151))),
          ],
        ),
      );
    }

    return RefreshIndicator(
      color: const Color(0xFF1B4FD8),
      backgroundColor: Colors.white,
      onRefresh: () async {
        await Future.delayed(const Duration(seconds: 1));
        ref.invalidate(dealerListProvider);
      },
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
        itemCount: filtered.length,
        itemBuilder: (context, index) {
          final dealer = filtered[index];
          final colors = _avatarColors(index);
          return _DealerCard(
            dealer: dealer,
            index: index,
            avatarBg: colors.$1,
            avatarBorder: colors.$2,
            avatarFg: colors.$3,
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => DealerView(
                    dealerId: dealer.employeeId.toString()),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Error State ────────────────────────────────────────────────────────────
  Widget _buildErrorState(
      BuildContext context, double sw, double sh) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F4F8),
      body: SafeArea(
        child: Column(
          children: [
            _buildTopNav(context, sw, sh),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: sw * 0.18,
                      height: sw * 0.18,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border:
                        Border.all(color: const Color(0xFFE5E7EB)),
                      ),
                      child: Icon(Icons.wifi_off_rounded,
                          size: sw * 0.09,
                          color: const Color(0xFF9CA3AF)),
                    ),
                    SizedBox(height: sh * 0.02),
                    Text(
                      'No Internet Connection',
                      style: TextStyle(
                          fontSize: sw * 0.04,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF374151)),
                    ),
                    SizedBox(height: sh * 0.025),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(dealerListProvider),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1B4FD8),
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
        ),
      ),
    );
  }
}

// ─── Dealer Card Widget ──────────────────────────────────────────────────────
class _DealerCard extends StatelessWidget {
  final UserModel dealer;
  final int index;
  final Color avatarBg, avatarBorder, avatarFg;
  final VoidCallback onTap;

  const _DealerCard({
    required this.dealer,
    required this.index,
    required this.avatarBg,
    required this.avatarBorder,
    required this.avatarFg,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final hasPhoto =
        dealer.photo != null && dealer.photo!.isNotEmpty;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: sw * 0.028),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(sw * 0.04),
          border: Border.all(color: const Color(0xFFE5E7EB)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.038),
          child: Row(
            children: [
              // ── Avatar ──────────────────────────────
              Container(
                width: sw * 0.13,
                height: sw * 0.13,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: avatarBg,
                  border: Border.all(color: avatarBorder, width: 1.5),
                ),
                child: ClipOval(
                  child: hasPhoto
                      ? CachedNetworkImage(
                    imageUrl: dealer.photo!,
                    fit: BoxFit.cover,
                    placeholder: (_, __) => _avatarInitials(
                        sw, dealer.employeeName),
                    errorWidget: (_, __, ___) =>
                        _avatarInitials(sw, dealer.employeeName),
                  )
                      : _avatarInitials(sw, dealer.employeeName),
                ),
              ),

              SizedBox(width: sw * 0.035),

              // ── Info ─────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dealer.employeeName.replaceAll('_', ' '),
                      style: TextStyle(
                        fontSize: sw * 0.038,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827),
                        letterSpacing: -0.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: sw * 0.015),
                    _MetaRow(
                      icon: Icons.location_on_outlined,
                      value: dealer.town ?? 'N/A',
                      sw: sw,
                    ),
                    SizedBox(height: sw * 0.008),
                    _MetaRow(
                      icon: Icons.phone_outlined,
                      value: dealer.employeePhone,
                      sw: sw,
                    ),
                  ],
                ),
              ),

              SizedBox(width: sw * 0.02),

              // ── Chevron ──────────────────────────────
              Container(
                width: sw * 0.075,
                height: sw * 0.075,
                decoration: BoxDecoration(
                  color: const Color(0xFFF2F4F8),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: sw * 0.045,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _avatarInitials(double sw, String name) {
    return Container(
      color: avatarBg,
      child: Center(
        child: Text(
          _initials(name),
          style: TextStyle(
            fontSize: sw * 0.04,
            fontWeight: FontWeight.w800,
            color: avatarFg,
          ),
        ),
      ),
    );
  }
}

// ─── Meta Row ────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final IconData icon;
  final String value;
  final double sw;

  const _MetaRow(
      {required this.icon, required this.value, required this.sw});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon,
            size: sw * 0.038, color: const Color(0xFF1B4FD8)),
        SizedBox(width: sw * 0.015),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: sw * 0.032,
              color: const Color(0xFF374151),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}