import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/feature/signup/controller/signUp_controller.dart';
import 'package:inverter_management_app/feature/signup/screens/dealer/dealer_view_screen.dart';
import 'package:inverter_management_app/feature/signup/screens/dealer/dealers_sign_up_screen.dart';
import '../../model/user_model.dart';
import '../../../../widgets/circle_button.dart';

// ── Zoho tokens ───────────────────────────────────────────────────────────────
const _kP       = Color(0xFF185FA5);
const _kPBg     = Color(0xFFEBF4FF);
const _kPBd     = Color(0xFFBFD9F5);
const _kBg      = Color(0xFFF7F8FA);
const _kWhite   = Colors.white;
const _kBd      = Color(0xFFE5E7EB);
const _kT1      = Color(0xFF111827);
const _kT2      = Color(0xFF374151);
const _kT4      = Color(0xFF9CA3AF);

const _avatarSets = [
  (Color(0xFFEBF4FF), Color(0xFFBFD9F5), Color(0xFF185FA5)),
  (Color(0xFFEDFAF5), Color(0xFF9FE0C5), Color(0xFF0F6E56)),
  (Color(0xFFF5F3FF), Color(0xFFDDD6FE), Color(0xFF7C3AED)),
  (Color(0xFFFFFBEB), Color(0xFFFCD28A), Color(0xFFB45309)),
  (Color(0xFFFEF2F2), Color(0xFFFECACA), Color(0xFFDC2626)),
];

(Color, Color, Color) _avatarColors(int i) => _avatarSets[i % _avatarSets.length];
String _initials(String name) => name.trim().split(' ').take(2)
    .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();

// ═════════════════════════════════════════════════════════════════════════════
class DealersScreen extends ConsumerStatefulWidget {
  const DealersScreen({super.key});
  @override
  ConsumerState<DealersScreen> createState() => _DealersScreenState();
}

class _DealersScreenState extends ConsumerState<DealersScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _showSearch = false;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollCtrl.position.pixels >=
        _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(dealerListProvider.notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  void _onSearchChanged(String v) {
    setState(() => _query = v);
    ref.read(dealerListProvider.notifier).searchDealers(v);
  }

  void _closeSearch() {
    setState(() {
      _showSearch = false;
      _query = '';
      _searchCtrl.clear();
    });
    ref.read(dealerListProvider.notifier).searchDealers('');
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    final async = ref.watch(dealerListProvider);
    final isFiltering = ref.watch(dealerFilteringProvider);

    // ── ALWAYS render header. Only the body changes based on state.
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(context, sw, sh),
            Expanded(
              child: _buildBodyArea(
                context, sw, sh,
                async: async,
                isFiltering: isFiltering,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Header (search bar swap or normal title row) ─────────────────────────
  Widget _buildHeader(BuildContext context, double sw, double sh) {
    return Container(
      color: _kWhite,
      padding: EdgeInsets.fromLTRB(
          sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
      child: _showSearch
          ? _searchBar(sw)
          : Row(children: [
        CircularIconButton(
          icon: Icons.arrow_back_ios_rounded,
          onTap: () => Navigator.pop(context),
        ),
        const Spacer(),
        Text('Dealers',
            style: TextStyle(
              fontSize: (sw * 0.042).clamp(14.0, 20.0),
              fontWeight: FontWeight.w700,
              color: _kT1,
              letterSpacing: -0.2,
            )),
        const Spacer(),
        CircularIconButton(
          icon: Icons.search_rounded,
          onTap: () => setState(() => _showSearch = true),
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
      ]),
    );
  }

  // ── Body — only this changes between states ──────────────────────────────
  Widget _buildBodyArea(
      BuildContext context,
      double sw,
      double sh, {
        required AsyncValue<List<UserModel>> async,
        required bool isFiltering,
      }) {
    return async.when(
      // First-time load: full spinner is fine, no list yet
      loading: () => const Center(
        child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5),
      ),
      error: (_, __) => _bodyErrorView(sw, sh),
      data: (dealers) {
        // Empty state (search returned nothing OR no dealers at all)
        if (dealers.isEmpty) {
          return _showSearch && _query.isNotEmpty
              ? _emptySearch(sw, sh)
              : _emptyAll(sw, sh);
        }

        return Column(
          children: [
            _buildCountBadge(sw, dealers.length),
            Expanded(
              child: Stack(
                children: [
                  _buildList(context, sw, sh, dealers),

                  // ── Filter-change overlay ──────────────────────────────
                  // Old data visible underneath, translucent veil + spinner.
                  if (isFiltering)
                    Positioned.fill(
                      child: IgnorePointer(
                        child: Container(
                          color: _kWhite.withValues(alpha: 0.65),
                          child: const Center(
                            child: SizedBox(
                              width: 28,
                              height: 28,
                              child: CircularProgressIndicator(
                                color: _kP,
                                strokeWidth: 2.5,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Search bar (replaces title row when active) ──────────────────────────
  Widget _searchBar(double sw) {
    final r = (sw * 0.028).clamp(8.0, 12.0);
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _searchCtrl,
          autofocus: true,
          onChanged: _onSearchChanged,
          style: TextStyle(
              fontSize: (sw * 0.035).clamp(12.0, 15.0), color: _kT1),
          decoration: InputDecoration(
            hintText: 'Search by name, phone or location',
            hintStyle: TextStyle(
                color: _kT4, fontSize: (sw * 0.033).clamp(11.0, 14.0)),
            prefixIcon: Icon(Icons.search_rounded,
                color: _kT4, size: (sw * 0.048).clamp(16.0, 22.0)),
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
      CircularIconButton(
        icon: Icons.close_rounded,
        onTap: _closeSearch,
      ),
    ]);
  }

  // ── Count badge ──────────────────────────────────────────────────────────
  Widget _buildCountBadge(double sw, int count) {
    return Padding(
      padding: EdgeInsets.only(
        left: sw * 0.04,
        right: sw * 0.04,
        bottom: sw * 0.02,
        top: sw * 0.012,
      ),
      child: Row(children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: (sw * 0.03).clamp(10.0, 14.0),
            vertical: (sw * 0.01).clamp(3.0, 6.0),
          ),
          decoration: BoxDecoration(
            color: _kPBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kPBd, width: 0.5),
          ),
          child: Text(
            _showSearch && _query.isNotEmpty
                ? '$count result${count != 1 ? 's' : ''}'
                : '$count dealers',
            style: TextStyle(
              fontSize: (sw * 0.029).clamp(9.5, 12.5),
              fontWeight: FontWeight.w700,
              color: _kP,
            ),
          ),
        ),
      ]),
    );
  }

  // ── List with pagination footer ──────────────────────────────────────────
  Widget _buildList(
      BuildContext ctx, double sw, double sh, List<UserModel> dealers) {
    final isLoadingMore = ref.watch(dealerLoadingMoreProvider);
    final hasMore = ref.read(dealerListProvider.notifier).hasMore;
    final showFooter = hasMore || isLoadingMore;
    final itemCount = dealers.length + (showFooter ? 1 : 0);

    return RefreshIndicator(
      color: _kP,
      backgroundColor: _kWhite,
      onRefresh: () async {
        await ref.read(dealerListProvider.notifier).refresh();
      },
      child: ListView.builder(
        controller: _scrollCtrl,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
        itemCount: itemCount,
        itemBuilder: (_, i) {
          if (i >= dealers.length) {
            return _PaginationFooter(
              isLoading: isLoadingMore,
              hasMore: hasMore,
              sw: sw,
            );
          }

          final d = dealers[i];
          final c = _avatarColors(i);
          return _DealerCard(
            dealer: d,
            avatarBg: c.$1,
            avatarBd: c.$2,
            avatarFg: c.$3,
            onTap: () => Navigator.push(
              ctx,
              MaterialPageRoute(
                builder: (_) => DealerView(dealerId: d.employeeId.toString()),
              ),
            ),
          );
        },
      ),
    );
  }

  // ── Empty / error views ──────────────────────────────────────────────────
  Widget _emptySearch(double sw, double sh) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: (sw * 0.18).clamp(60.0, 90.0),
          height: (sw * 0.18).clamp(60.0, 90.0),
          decoration: BoxDecoration(
            color: _kWhite,
            shape: BoxShape.circle,
            border: Border.all(color: _kBd, width: 0.5),
          ),
          child: Icon(Icons.search_off_rounded,
              size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
        ),
        SizedBox(height: sh * 0.02),
        Text(
          'No results for "$_query"',
          style: TextStyle(
            fontSize: (sw * 0.036).clamp(12.0, 16.0),
            fontWeight: FontWeight.w600,
            color: _kT2,
          ),
          textAlign: TextAlign.center,
        ),
        SizedBox(height: sh * 0.006),
        Text(
          'Try a different name, phone or location',
          style: TextStyle(
            fontSize: (sw * 0.03).clamp(10.0, 13.0),
            color: _kT4,
          ),
        ),
      ],
    ),
  );

  Widget _emptyAll(double sw, double sh) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: (sw * 0.18).clamp(60.0, 90.0),
          height: (sw * 0.18).clamp(60.0, 90.0),
          decoration: BoxDecoration(
            color: _kWhite,
            shape: BoxShape.circle,
            border: Border.all(color: _kBd, width: 0.5),
          ),
          child: Icon(Icons.people_outline_rounded,
              size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
        ),
        SizedBox(height: sh * 0.02),
        Text(
          'No dealers yet',
          style: TextStyle(
            fontSize: (sw * 0.036).clamp(12.0, 16.0),
            fontWeight: FontWeight.w600,
            color: _kT2,
          ),
        ),
      ],
    ),
  );

  Widget _bodyErrorView(double sw, double sh) => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          width: (sw * 0.18).clamp(60.0, 90.0),
          height: (sw * 0.18).clamp(60.0, 90.0),
          decoration: BoxDecoration(
            color: _kWhite,
            shape: BoxShape.circle,
            border: Border.all(color: _kBd, width: 0.5),
          ),
          child: Icon(Icons.wifi_off_rounded,
              size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
        ),
        SizedBox(height: sh * 0.02),
        Text(
          'No Connection',
          style: TextStyle(
            fontSize: (sw * 0.04).clamp(13.0, 18.0),
            fontWeight: FontWeight.w600,
            color: _kT2,
          ),
        ),
        SizedBox(height: sh * 0.02),
        ElevatedButton(
          onPressed: () =>
              ref.read(dealerListProvider.notifier).refresh(),
          style: ElevatedButton.styleFrom(
            backgroundColor: _kP,
            foregroundColor: _kWhite,
            shape: const CircleBorder(),
            padding: const EdgeInsets.all(14),
            elevation: 0,
          ),
          child: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
  );
}

// ── Pagination footer ─────────────────────────────────────────────────────────
class _PaginationFooter extends StatelessWidget {
  const _PaginationFooter({
    required this.isLoading,
    required this.hasMore,
    required this.sw,
  });

  final bool isLoading;
  final bool hasMore;
  final double sw;

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sw * 0.05),
        child: Center(
          child: SizedBox(
            width: (sw * 0.05).clamp(18.0, 24.0),
            height: (sw * 0.05).clamp(18.0, 24.0),
            child: const CircularProgressIndicator(
              color: _kP,
              strokeWidth: 2.2,
            ),
          ),
        ),
      );
    }
    if (!hasMore) {
      return Padding(
        padding: EdgeInsets.symmetric(vertical: sw * 0.05),
        child: Center(
          child: Text(
            "You've reached the end",
            style: TextStyle(
              fontSize: (sw * 0.03).clamp(10.0, 13.0),
              color: _kT4,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      );
    }
    return const SizedBox.shrink();
  }
}

// ── Dealer card ───────────────────────────────────────────────────────────────
class _DealerCard extends StatelessWidget {
  const _DealerCard({
    required this.dealer,
    required this.avatarBg,
    required this.avatarBd,
    required this.avatarFg,
    required this.onTap,
  });
  final UserModel dealer;
  final Color avatarBg, avatarBd, avatarFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final hasPhoto = dealer.photo != null && dealer.photo!.isNotEmpty;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: sw * 0.025),
        decoration: BoxDecoration(
          color: _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
          border: Border.all(color: _kBd, width: 0.5),
        ),
        padding: EdgeInsets.all(sw * 0.038),
        child: Row(children: [
          Container(
            width: (sw * 0.12).clamp(42.0, 56.0),
            height: (sw * 0.12).clamp(42.0, 56.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: avatarBg,
              border: Border.all(color: avatarBd, width: 1.0),
            ),
            child: ClipOval(
              child: hasPhoto
                  ? CachedNetworkImage(
                imageUrl: dealer.photo!,
                fit: BoxFit.cover,
                placeholder: (_, __) => _initView(sw),
                errorWidget: (_, __, ___) => _initView(sw),
              )
                  : _initView(sw),
            ),
          ),
          SizedBox(width: sw * 0.035),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dealer.employeeName.replaceAll('_', ' '),
                  style: TextStyle(
                    fontSize: (sw * 0.036).clamp(12.0, 16.0),
                    fontWeight: FontWeight.w700,
                    color: _kT1,
                    letterSpacing: -0.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: sw * 0.012),
                _MetaRow(
                  icon: Icons.location_on_outlined,
                  value: dealer.town ?? 'N/A',
                  sw: sw,
                ),
                SizedBox(height: sw * 0.006),
                _MetaRow(
                  icon: Icons.phone_outlined,
                  value: dealer.employeePhone,
                  sw: sw,
                ),
              ],
            ),
          ),
          SizedBox(width: sw * 0.02),
          Container(
            width: (sw * 0.07).clamp(26.0, 34.0),
            height: (sw * 0.07).clamp(26.0, 34.0),
            decoration: BoxDecoration(
              color: _kBg,
              shape: BoxShape.circle,
              border: Border.all(color: _kBd, width: 0.5),
            ),
            child: Icon(
              Icons.chevron_right_rounded,
              size: (sw * 0.04).clamp(14.0, 18.0),
              color: _kT4,
            ),
          ),
        ]),
      ),
    );
  }

  Widget _initView(double sw) => Container(
    color: avatarBg,
    child: Center(
      child: Text(
        _initials(dealer.employeeName),
        style: TextStyle(
          fontSize: (sw * 0.036).clamp(12.0, 18.0),
          fontWeight: FontWeight.w800,
          color: avatarFg,
        ),
      ),
    ),
  );
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.value, required this.sw});
  final IconData icon;
  final String value;
  final double sw;

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: (sw * 0.035).clamp(12.0, 16.0), color: _kP),
    SizedBox(width: sw * 0.015),
    Expanded(
      child: Text(
        value,
        style: TextStyle(
          fontSize: (sw * 0.032).clamp(11.0, 14.0),
          color: _kT2,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ]);
}