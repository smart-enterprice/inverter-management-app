import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../core/media_query/media_query.dart';
import '../../../widgets/circle_button.dart';
import '../controller/brand_controller.dart';
import 'brand_create.dart';
import 'brand_details_page.dart';

// ── Zoho Books design tokens (mirrored from ProductsScreen) ───────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kPBd      = Color(0xFFBFD9F5);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Colors.white;
const _kBd       = Color(0xFFE5E7EB);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
const _kT3       = Color(0xFF6B7280);
const _kT4       = Color(0xFF9CA3AF);
const _kGreen    = Color(0xFF0F6E56);
const _kGreenBg  = Color(0xFFEDFAF5);
const _kGreenBd  = Color(0xFF9FE0C5);
const _kRed      = Color(0xFFDC2626);
const _kRedBg    = Color(0xFFFEF2F2);
const _kRedBd    = Color(0xFFFECACA);
const _kAmber    = Color(0xFFB45309);
const _kAmberBg  = Color(0xFFFFFBEB);
const _kAmberBd  = Color(0xFFFCD28A);
const _kPurple   = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBd = Color(0xFFDDD6FE);

// ── Filter tabs ───────────────────────────────────────────────────────────────
class _FilterTab {
  final String  label;
  final String? apiValue;
  const _FilterTab({required this.label, this.apiValue});
}

const _kTabs = [
  _FilterTab(label: 'All'),
  _FilterTab(label: 'Active',   apiValue: 'active'),
  _FilterTab(label: 'Inactive', apiValue: 'inactive'),
];

Color _dotColor(String? v) {
  switch (v) {
    case 'active':   return _kGreen;
    case 'inactive': return _kRed;
    default:         return _kT3;
  }
}

// ═════════════════════════════════════════════════════════════════════════════
class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  int    _tabIdx     = 0;
  String _query      = '';
  bool   _showSearch = false;
  final _searchCtrl = TextEditingController();
  final _chipCtrl   = ScrollController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    _chipCtrl.dispose();
    super.dispose();
  }

  String? get _status => _kTabs[_tabIdx].apiValue;

  void _scrollChip(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chipCtrl.hasClients) return;
      _chipCtrl.animateTo(
          (i * 100.0 - 60).clamp(0.0, _chipCtrl.position.maxScrollExtent),
          duration: const Duration(milliseconds: 280),
          curve:    Curves.easeOut);
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw         = Screen.w(context);
    final sh         = Screen.h(context);
    final brandState = ref.watch(brandControllerProvider);

    return brandState.when(
      loading: () => const Scaffold(
          backgroundColor: _kBg,
          body: Center(
              child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5))),

      error: (error, stackTrace) {
        print('🖥️ UI ERROR: $error');
        print('🖥️ UI STACK: $stackTrace');
        return _errorScaffold(context, sw, sh);
      },

      data: (brands) {
        // Filter by status + search query
        final filtered = brands.where((b) {
          final statusOk =
              _status == null || b.status?.toLowerCase() == _status;
          if (!statusOk) return false;
          if (_query.isEmpty) return true;
          final q = _query.toLowerCase();
          return b.brandName.toLowerCase().contains(q) ||
              b.brandModels.any((m) => m.toLowerCase().contains(q));
        }).toList();

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(child: Column(children: [

            // ── Header ──────────────────────────────────────────────────
            Container(color: _kWhite, child: Column(children: [
              Padding(
                padding: EdgeInsets.fromLTRB(
                    sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.012),
                child: _showSearch
                    ? _searchBar(sw)
                    : Row(children: [
                  CircularIconButton(
                      icon: Icons.arrow_back_ios_rounded,
                      onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  Text('Brands',
                      style: TextStyle(
                          fontSize:     (sw * 0.042).clamp(14.0, 20.0),
                          fontWeight:   FontWeight.w700,
                          color:        _kT1,
                          letterSpacing: -0.2)),
                  const Spacer(),
                  CircularIconButton(
                      icon:  Icons.search_rounded,
                      onTap: () =>
                          setState(() => _showSearch = true)),
                  SizedBox(width: sw * 0.02),
                  RoleGuard(
                    feature: AppFeature.createBrand,
                    child: CircularIconButton(
                      icon:  Icons.add,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) =>
                            const BrandCreateScreen()),
                      ),
                    ),
                  ),
                ]),
              ),

              // ── Filter chips ─────────────────────────────────────────
              SizedBox(
                height: sh * 0.048,
                child: ListView.builder(
                    controller:      _chipCtrl,
                    scrollDirection: Axis.horizontal,
                    physics:         const BouncingScrollPhysics(),
                    padding: EdgeInsets.fromLTRB(
                        sw * 0.04, 0, sw * 0.04, sh * 0.006),
                    itemCount:   _kTabs.length,
                    itemBuilder: (_, i) => _statusChip(sw, i)),
              ),
              Divider(height: 1, color: _kBd),
            ])),

            // ── Brand list ───────────────────────────────────────────────
            Expanded(
              child: filtered.isEmpty
                  ? _emptyView(sw, sh)
                  : RefreshIndicator(
                color:           _kP,
                backgroundColor: _kWhite,
                onRefresh: () async =>
                    ref.invalidate(brandControllerProvider),
                child: ListView.builder(
                  physics:   const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(
                      sw * 0.038, sh * 0.012,
                      sw * 0.038, sh * 0.04),
                  itemCount:   filtered.length,
                  itemBuilder: (_, i) {
                    final brand    = filtered[i];
                    final isActive =
                        brand.status?.toLowerCase() == 'active';
                    return _BrandCard(
                      sw:         sw,
                      sh:         sh,
                      brandName:  brand.brandName,
                      modelCount: brand.brandModels.length,
                      isActive:   isActive,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BrandDetailsScreen(
                              brandId: brand.brandId!),
                        ),
                      ),
                    );
                    ref.invalidate(brandControllerProvider);
                  },
                ),
              ),
            ),
          ])),
        );
      },
    );
  }

  // ── Status chip ─────────────────────────────────────────────────────────
  Widget _statusChip(double sw, int i) {
    final tab = _kTabs[i];
    final sel = _tabIdx == i;
    final dot = _dotColor(tab.apiValue);
    return GestureDetector(
      onTap: () {
        setState(() => _tabIdx = i);
        _scrollChip(i);
      },
      child: Container(
        margin:  EdgeInsets.only(right: sw * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: (sw * 0.032).clamp(10.0, 16.0),
            vertical:   (sw * 0.014).clamp(5.0, 8.0)),
        decoration: BoxDecoration(
            color:        sel ? _kWhite : _kBg,
            borderRadius: BorderRadius.circular(20),
            border:       Border.all(
                color: sel ? dot : _kBd,
                width: sel ? 1.0 : 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width:  (sw * 0.016).clamp(5.0, 8.0),
              height: (sw * 0.016).clamp(5.0, 8.0),
              decoration:
              BoxDecoration(color: dot, shape: BoxShape.circle)),
          SizedBox(width: sw * 0.015),
          Text(tab.label,
              style: TextStyle(
                  fontSize:   (sw * 0.03).clamp(10.0, 13.0),
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color:      sel ? _kT1 : _kT4)),
        ]),
      ),
    );
  }

  // ── Search bar ──────────────────────────────────────────────────────────
  Widget _searchBar(double sw) {
    final r = (sw * 0.028).clamp(8.0, 12.0);
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _searchCtrl,
          autofocus:  true,
          onChanged:  (v) => setState(() => _query = v),
          style: TextStyle(
              fontSize:   (sw * 0.035).clamp(12.0, 15.0),
              color:      _kT1),
          decoration: InputDecoration(
            hintText:  'Search brands…',
            hintStyle: TextStyle(
                color:    _kT4,
                fontSize: (sw * 0.033).clamp(11.0, 14.0)),
            prefixIcon: Icon(Icons.search_rounded,
                color: _kT4,
                size:  (sw * 0.048).clamp(16.0, 22.0)),
            filled:         true,
            fillColor:      _kBg,
            contentPadding: EdgeInsets.zero,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(r),
                borderSide:   const BorderSide(color: _kBd, width: 0.5)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(r),
                borderSide:   const BorderSide(color: _kBd, width: 0.5)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(r),
                borderSide: const BorderSide(color: _kP, width: 1.5)),
          ),
        ),
      ),
      SizedBox(width: sw * 0.02),
      CircularIconButton(
          icon:  Icons.close_rounded,
          onTap: () => setState(() {
            _showSearch = false;
            _query      = '';
            _searchCtrl.clear();
          })),
    ]);
  }

  // ── Empty view ──────────────────────────────────────────────────────────
  Widget _emptyView(double sw, double sh) {
    final String msg, sub;
    if (_query.isNotEmpty) {
      msg = 'No results for "$_query"';
      sub = 'Try a different search term';
    } else if (_tabIdx != 0) {
      msg = 'No ${_kTabs[_tabIdx].label} brands';
      sub = 'Try a different filter';
    } else {
      msg = 'No brands yet';
      sub = 'Add a brand to get started';
    }

    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width:  (sw * 0.18).clamp(60.0, 90.0),
          height: (sw * 0.18).clamp(60.0, 90.0),
          decoration: BoxDecoration(
              color:  _kWhite,
              shape:  BoxShape.circle,
              border: Border.all(color: _kBd, width: 0.5)),
          child: Icon(Icons.storefront_outlined,
              size:  (sw * 0.09).clamp(30.0, 44.0), color: _kT4),
        ),
        SizedBox(height: sh * 0.02),
        Text(msg,
            style: TextStyle(
                fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                fontWeight: FontWeight.w600,
                color:      _kT2),
            textAlign: TextAlign.center),
        SizedBox(height: sh * 0.006),
        Text(sub,
            style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4),
            textAlign: TextAlign.center),
        if (_tabIdx != 0) ...[
          SizedBox(height: sh * 0.02),
          GestureDetector(
            onTap: () => setState(() => _tabIdx = 0),
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: (sw * 0.04).clamp(14.0, 20.0),
                  vertical:   (sw * 0.022).clamp(7.0, 12.0)),
              decoration: BoxDecoration(
                  color:        _kPBg,
                  borderRadius: BorderRadius.circular(20),
                  border:       Border.all(color: _kPBd, width: 0.5)),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.apps_rounded,
                    size:  (sw * 0.035).clamp(12.0, 16.0), color: _kP),
                SizedBox(width: sw * 0.015),
                Text('View all brands',
                    style: TextStyle(
                        fontSize:   (sw * 0.03).clamp(10.0, 13.0),
                        fontWeight: FontWeight.w700,
                        color:      _kP)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Error scaffold ──────────────────────────────────────────────────────
  Widget _errorScaffold(BuildContext context, double sw, double sh) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [
        Container(
          color:   _kWhite,
          padding: EdgeInsets.fromLTRB(
              sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
          child: Row(children: [
            CircularIconButton(
                icon: Icons.arrow_back_ios_rounded,
                onTap: () => Navigator.pop(context)),
            const Spacer(),
            Text('Brands',
                style: TextStyle(
                    fontSize:   (sw * 0.042).clamp(14.0, 20.0),
                    fontWeight: FontWeight.w700,
                    color:      _kT1,
                    letterSpacing: -0.2)),
            const Spacer(),
            SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
          ]),
        ),
        Expanded(
          child: Center(
            child:
            Column(mainAxisAlignment: MainAxisAlignment.center, children: [
              Container(
                width:  (sw * 0.18).clamp(60.0, 90.0),
                height: (sw * 0.18).clamp(60.0, 90.0),
                decoration: BoxDecoration(
                    color:  _kRedBg,
                    shape:  BoxShape.circle,
                    border: Border.all(color: _kRedBd, width: 0.5)),
                child: Icon(Icons.wifi_off_rounded,
                    size:  (sw * 0.09).clamp(30.0, 44.0), color: _kRed),
              ),
              SizedBox(height: sh * 0.02),
              Text('No Internet Connection',
                  style: TextStyle(
                      fontSize:   (sw * 0.04).clamp(13.0, 18.0),
                      fontWeight: FontWeight.w600,
                      color:      _kT2)),
              SizedBox(height: sh * 0.008),
              Text('Check your connection and try again',
                  style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
              SizedBox(height: sh * 0.025),
              ElevatedButton.icon(
                  onPressed: () =>
                      ref.invalidate(brandControllerProvider),
                  icon:  Icon(Icons.refresh_rounded,
                      size: (sw * 0.04).clamp(14.0, 18.0)),
                  label: Text('Retry',
                      style: TextStyle(
                          fontSize:   (sw * 0.034).clamp(11.5, 15.0),
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                      backgroundColor: _kP,
                      foregroundColor: _kWhite,
                      padding: EdgeInsets.symmetric(
                          horizontal: (sw * 0.06).clamp(20.0, 28.0),
                          vertical:   (sw * 0.028).clamp(9.0, 14.0)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                      elevation: 0)),
            ]),
          ),
        ),
      ])),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Brand Card — mirrors _ProductCard layout exactly
// ═════════════════════════════════════════════════════════════════════════════
class _BrandCard extends StatelessWidget {
  const _BrandCard({
    required this.sw,
    required this.sh,
    required this.brandName,
    required this.modelCount,
    required this.isActive,
    required this.onTap,
  });

  final double sw, sh;
  final String brandName;
  final int    modelCount;
  final bool   isActive;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: sh * 0.01),
        decoration: BoxDecoration(
            color:        _kWhite,
            borderRadius: BorderRadius.circular(
                (sw * 0.035).clamp(10.0, 16.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.035),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Row 1: icon + name + status ──────────────────────────
              Row(crossAxisAlignment: CrossAxisAlignment.start, children: [

                // Brand icon
                Container(
                  width:  (sw * 0.095).clamp(34.0, 46.0),
                  height: (sw * 0.095).clamp(34.0, 46.0),
                  decoration: BoxDecoration(
                      color:        _kPurpleBg,
                      borderRadius: BorderRadius.circular(
                          (sw * 0.025).clamp(8.0, 12.0)),
                      border: Border.all(color: _kPurpleBd, width: 0.5)),
                  child: Icon(Icons.storefront_outlined,
                      size:  (sw * 0.048).clamp(16.0, 22.0),
                      color: _kPurple),
                ),
                SizedBox(width: sw * 0.03),

                // Brand name
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(brandName,
                          style: TextStyle(
                              fontSize:   (sw * 0.035).clamp(12.0, 15.0),
                              fontWeight: FontWeight.w700,
                              color:      _kT1,
                              letterSpacing: -0.2),
                          maxLines:  2,
                          overflow:  TextOverflow.ellipsis),
                      SizedBox(height: sw * 0.006),
                      // Model count tag
                      _Tag(
                        sw:    sw,
                        label: '$modelCount model${modelCount != 1 ? 's' : ''}',
                        color: _kPurple,
                        bg:    _kPurpleBg,
                      ),
                    ],
                  ),
                ),
                SizedBox(width: sw * 0.015),

                // Status badge
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: (sw * 0.02).clamp(6.0, 10.0),
                      vertical:   (sw * 0.008).clamp(3.0, 5.0)),
                  decoration: BoxDecoration(
                      color:        isActive ? _kGreenBg : _kRedBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: isActive ? _kGreenBd : _kRedBd,
                          width: 0.5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width:  (sw * 0.014).clamp(4.0, 7.0),
                        height: (sw * 0.014).clamp(4.0, 7.0),
                        decoration: BoxDecoration(
                            color: isActive ? _kGreen : _kRed,
                            shape: BoxShape.circle)),
                    SizedBox(width: sw * 0.008),
                    Text(isActive ? 'Active' : 'Inactive',
                        style: TextStyle(
                            fontSize:   (sw * 0.024).clamp(8.5, 11.0),
                            fontWeight: FontWeight.w700,
                            color: isActive ? _kGreen : _kRed)),
                  ]),
                ),
              ]),

              SizedBox(height: sw * 0.02),
              Divider(height: 1, color: _kBd),
              SizedBox(height: sw * 0.02),

              // ── Row 2: model pills + chevron ──────────────────────────
              Row(children: [
                // First 3 model names as compact pills
                Expanded(
                  child: Wrap(
                    spacing:   sw * 0.012,
                    runSpacing: sw * 0.01,
                    children: [
                      // We don't have the model list here, so show the icon row
                      Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.category_outlined,
                            size:  (sw * 0.03).clamp(10.0, 14.0),
                            color: _kT4),
                        SizedBox(width: sw * 0.012),
                        Text(
                            '$modelCount model${modelCount != 1 ? 's' : ''} available',
                            style: TextStyle(
                                fontSize:   (sw * 0.028).clamp(9.5, 12.5),
                                color:      _kT4,
                                fontWeight: FontWeight.w500)),
                      ]),
                    ],
                  ),
                ),
                // Chevron
                Container(
                  padding: EdgeInsets.all((sw * 0.015).clamp(4.0, 8.0)),
                  decoration: BoxDecoration(
                      color:        _kBg,
                      borderRadius: BorderRadius.circular(
                          (sw * 0.018).clamp(5.0, 8.0)),
                      border: Border.all(color: _kBd, width: 0.5)),
                  child: Icon(Icons.chevron_right_rounded,
                      size:  (sw * 0.038).clamp(13.0, 17.0), color: _kT4),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Tag ───────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  const _Tag({
    required this.sw,
    required this.label,
    required this.color,
    required this.bg,
  });
  final double sw;
  final String label;
  final Color  color, bg;

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
        horizontal: (sw * 0.018).clamp(5.0, 9.0),
        vertical:   (sw * 0.005).clamp(2.0, 4.0)),
    decoration: BoxDecoration(
        color:        bg,
        borderRadius: BorderRadius.circular(6),
        border:
        Border.all(color: color.withValues(alpha: 0.2), width: 0.5)),
    child: Text(label,
        maxLines:  1,
        overflow:  TextOverflow.ellipsis,
        style: TextStyle(
            fontSize:   (sw * 0.025).clamp(8.5, 11.0),
            fontWeight: FontWeight.w600,
            color:      color)),
  );
}