import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/feature/signup/controller/signUp_controller.dart';
import 'package:inverter_management_app/feature/signup/screen/dealer/dealer_view_screen.dart';
import 'package:inverter_management_app/feature/signup/screen/dealer/dealers_sign_up_screen.dart';
import '../../../../model/user_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../repository/signUp_repository.dart';

// ── Zoho tokens ───────────────────────────────────────────────────────────────
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

// ── Pagination notifier (unchanged) ───────────────────────────────────────
class DealerListNotifier extends StateNotifier<AsyncValue<List<UserModel>>> {
  final SignupRepository _repo;
  int _page = 1;
  final int _limit = 1000;
  final int _totalPages = 1;
  bool _isLoadingMore = false;

  DealerListNotifier(this._repo) : super(const AsyncLoading()) { loadDealers(reset: true); }

  Future<void> loadDealers({bool reset = false}) async {
    if (reset) { _page = 1; state = const AsyncLoading(); }
    try {
      final data = await _repo.getDealers(page: _page, limit: _limit);
      state = reset ? AsyncData(data) : AsyncData([...state.value ?? [], ...data]);
    } catch (e, st) { state = AsyncError(e, st); }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || _page >= _totalPages) return;
    _isLoadingMore = true; _page++; await loadDealers(); _isLoadingMore = false;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
class DealersScreen extends ConsumerStatefulWidget {
  const DealersScreen({super.key});
  @override ConsumerState<DealersScreen> createState() => _DealersScreenState();
}

class _DealersScreenState extends ConsumerState<DealersScreen> {
  final _scrollCtrl = ScrollController();
  final _searchCtrl = TextEditingController();
  String _query = '';
  bool _searching = false;

  @override void initState() { super.initState();
  _scrollCtrl.addListener(() {
    if (_scrollCtrl.position.pixels >= _scrollCtrl.position.maxScrollExtent - 200) {
      ref.read(dealerListProvider.notifier).loadMore();
    }
  }); }
  @override void dispose() { _scrollCtrl.dispose(); _searchCtrl.dispose(); super.dispose(); }

  void _toggleSearch() => setState(() {
    _searching = !_searching;
    if (!_searching) { _searchCtrl.clear(); _query = ''; }
  });

  List<UserModel> _filter(List<UserModel> all) {
    if (_query.isEmpty) return all;
    final q = _query.toLowerCase();
    return all.where((d) => d.employeeName.toLowerCase().contains(q) ||
        d.employeePhone.toLowerCase().contains(q) ||
        (d.town ?? '').toLowerCase().contains(q)).toList();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final async = ref.watch(dealerListProvider);

    return async.when(
        loading: () => const Scaffold(backgroundColor: _kBg,
            body: Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5))),
        error: (_, __) => _errorView(context, sw, sh),
        data: (dealers) {
          final filtered = _filter(dealers);
          return Scaffold(backgroundColor: _kBg,
              body: SafeArea(child: Column(children: [
                // App bar
                Container(color: _kWhite,
                    padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
                    child: Row(children: [
                      CircularIconButton(icon: Icons.arrow_back_ios_rounded, onTap: () => Navigator.pop(context)),
                      const Spacer(),
                      Text('Dealers', style: TextStyle(fontSize: (sw * 0.042).clamp(14.0, 20.0),
                          fontWeight: FontWeight.w700, color: _kT1, letterSpacing: -0.2)),
                      const Spacer(),
                      CircularIconButton(icon: _searching ? Icons.close_rounded : Icons.search_rounded,
                          onTap: _toggleSearch),
                      SizedBox(width: sw * 0.025),
                      RoleGuard(feature: AppFeature.createDealer,
                          child: CircularIconButton(icon: Icons.add,
                              onTap: () => Navigator.push(context,
                                  MaterialPageRoute(builder: (_) => const AddDealerScreen())))),
                    ])),

                // Search
                if (_searching) Padding(
                    padding: EdgeInsets.fromLTRB(sw * 0.04, 0, sw * 0.04, sh * 0.012),
                    child: TextField(controller: _searchCtrl, autofocus: true,
                        onChanged: (v) => setState(() => _query = v),
                        style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
                        decoration: _searchDeco(sw))),

                // Count
                if (!(_searching && _query.isEmpty))
                  Padding(padding: EdgeInsets.only(left: sw * 0.04, right: sw * 0.04, bottom: sw * 0.02,top: sw*0.01),
                      child: Row(children: [
                        Container(
                            padding: EdgeInsets.symmetric(
                                horizontal: (sw * 0.03).clamp(10.0, 14.0),
                                vertical: (sw * 0.01).clamp(3.0, 6.0)),
                            decoration: BoxDecoration(color: _kPBg, borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: _kPBd, width: 0.5)),
                            child: Text(_searching
                                ? '${filtered.length} result${filtered.length != 1 ? 's' : ''}'
                                : '${dealers.length} dealers',
                                style: TextStyle(fontSize: (sw * 0.029).clamp(9.5, 12.5),
                                    fontWeight: FontWeight.w700, color: _kP))),
                      ])),

                // List
                Expanded(child: _buildList(context, sw, sh, filtered, dealers)),
              ])));
        });
  }

  Widget _buildList(BuildContext ctx, double sw, double sh,
      List<UserModel> filtered, List<UserModel> all) {
    if (_searching && filtered.isEmpty) return _emptySearch(sw, sh);
    if (all.isEmpty) return _emptyAll(sw, sh);
    return RefreshIndicator(color: _kP, backgroundColor: _kWhite,
        onRefresh: () async { await Future.delayed(const Duration(seconds: 1));
        ref.invalidate(dealerListProvider); },
        child: ListView.builder(controller: _scrollCtrl,
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
            itemCount: filtered.length,
            itemBuilder: (_, i) {
              final d = filtered[i]; final c = _avatarColors(i);
              return _DealerCard(dealer: d, avatarBg: c.$1, avatarBd: c.$2, avatarFg: c.$3,
                  onTap: () => Navigator.push(ctx, MaterialPageRoute(
                      builder: (_) => DealerView(dealerId: d.employeeId.toString()))));
            }));
  }

  Widget _emptySearch(double sw, double sh) => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: (sw * 0.18).clamp(60.0, 90.0), height: (sw * 0.18).clamp(60.0, 90.0),
        decoration: BoxDecoration(color: _kWhite, shape: BoxShape.circle,
            border: Border.all(color: _kBd, width: 0.5)),
        child: Icon(Icons.search_off_rounded, size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4)),
    SizedBox(height: sh * 0.02),
    Text(_query.isEmpty ? 'Start typing to search' : 'No results for "$_query"',
        style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), fontWeight: FontWeight.w600, color: _kT2),
        textAlign: TextAlign.center),
    SizedBox(height: sh * 0.006),
    Text('Try a different name, phone or location',
        style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
  ]));

  Widget _emptyAll(double sw, double sh) => Center(child: Column(
      mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(width: (sw * 0.18).clamp(60.0, 90.0), height: (sw * 0.18).clamp(60.0, 90.0),
        decoration: BoxDecoration(color: _kWhite, shape: BoxShape.circle,
            border: Border.all(color: _kBd, width: 0.5)),
        child: Icon(Icons.people_outline_rounded, size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4)),
    SizedBox(height: sh * 0.02),
    Text('No dealers yet', style: TextStyle(
        fontSize: (sw * 0.036).clamp(12.0, 16.0), fontWeight: FontWeight.w600, color: _kT2)),
  ]));

  Widget _errorView(BuildContext ctx, double sw, double sh) => Scaffold(
      backgroundColor: _kBg, body: SafeArea(child: Column(children: [
    Container(color: _kWhite,
        padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
        child: Row(children: [
          CircularIconButton(icon: Icons.arrow_back_ios_rounded, onTap: () => Navigator.pop(ctx)),
          const Spacer(),
          Text('Dealers', style: TextStyle(fontSize: (sw * 0.042).clamp(14.0, 20.0),
              fontWeight: FontWeight.w700, color: _kT1)),
          const Spacer(), SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
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
      ElevatedButton(onPressed: () => ref.invalidate(dealerListProvider),
          style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
              shape: const CircleBorder(), padding: const EdgeInsets.all(14), elevation: 0),
          child: const Icon(Icons.refresh_rounded)),
    ]))),
  ])));

  InputDecoration _searchDeco(double sw) {
    final r = (sw * 0.028).clamp(8.0, 12.0);
    return InputDecoration(
        hintText: 'Search by name, phone or location',
        hintStyle: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT4),
        prefixIcon: Icon(Icons.search_rounded, color: _kP, size: (sw * 0.05).clamp(16.0, 22.0)),
        suffixIcon: _query.isNotEmpty ? IconButton(
            icon: Icon(Icons.clear_rounded, size: (sw * 0.045).clamp(15.0, 20.0), color: _kT4),
            onPressed: () => setState(() { _searchCtrl.clear(); _query = ''; })) : null,
        filled: true, fillColor: _kWhite,
        contentPadding: EdgeInsets.symmetric(vertical: sw * 0.035, horizontal: sw * 0.04),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
            borderSide: const BorderSide(color: _kP, width: 1.5)));
  }
}

// ── Dealer card ───────────────────────────────────────────────────────────────
class _DealerCard extends StatelessWidget {
  const _DealerCard({required this.dealer, required this.avatarBg,
    required this.avatarBd, required this.avatarFg, required this.onTap});
  final UserModel dealer; final Color avatarBg, avatarBd, avatarFg;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final hasPhoto = dealer.photo != null && dealer.photo!.isNotEmpty;
    return GestureDetector(onTap: onTap,
        child: Container(
            margin: EdgeInsets.only(bottom: sw * 0.025),
            decoration: BoxDecoration(color: _kWhite,
                borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
                border: Border.all(color: _kBd, width: 0.5)),
            padding: EdgeInsets.all(sw * 0.038),
            child: Row(children: [
              Container(
                  width: (sw * 0.12).clamp(42.0, 56.0), height: (sw * 0.12).clamp(42.0, 56.0),
                  decoration: BoxDecoration(shape: BoxShape.circle, color: avatarBg,
                      border: Border.all(color: avatarBd, width: 1.0)),
                  child: ClipOval(child: hasPhoto
                      ? CachedNetworkImage(imageUrl: dealer.photo!, fit: BoxFit.cover,
                      placeholder: (_, __) => _initView(sw), errorWidget: (_, __, ___) => _initView(sw))
                      : _initView(sw))),
              SizedBox(width: sw * 0.035),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(dealer.employeeName.replaceAll('_', ' '),
                    style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0),
                        fontWeight: FontWeight.w700, color: _kT1, letterSpacing: -0.2),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                SizedBox(height: sw * 0.012),
                _MetaRow(icon: Icons.location_on_outlined, value: dealer.town ?? 'N/A', sw: sw),
                SizedBox(height: sw * 0.006),
                _MetaRow(icon: Icons.phone_outlined, value: dealer.employeePhone, sw: sw),
              ])),
              SizedBox(width: sw * 0.02),
              Container(
                  width: (sw * 0.07).clamp(26.0, 34.0), height: (sw * 0.07).clamp(26.0, 34.0),
                  decoration: BoxDecoration(color: _kBg, shape: BoxShape.circle,
                      border: Border.all(color: _kBd, width: 0.5)),
                  child: Icon(Icons.chevron_right_rounded,
                      size: (sw * 0.04).clamp(14.0, 18.0), color: _kT4)),
            ])));
  }

  Widget _initView(double sw) => Container(color: avatarBg,
      child: Center(child: Text(_initials(dealer.employeeName),
          style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 18.0),
              fontWeight: FontWeight.w800, color: avatarFg))));
}

class _MetaRow extends StatelessWidget {
  const _MetaRow({required this.icon, required this.value, required this.sw});
  final IconData icon; final String value; final double sw;

  @override Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: (sw * 0.035).clamp(12.0, 16.0), color: _kP),
    SizedBox(width: sw * 0.015),
    Expanded(child: Text(value, style: TextStyle(
        fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT2, fontWeight: FontWeight.w500),
        maxLines: 1, overflow: TextOverflow.ellipsis)),
  ]);
}