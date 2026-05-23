import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/feature/product/screens/product_create_screen.dart';
import 'package:inverter_management_app/feature/product/screens/product_view.dart';
import '../../../core/const/icons.dart';
import '../../../feature/brand/model/brand_model.dart';
import '../../../widgets/circle_button.dart';
import '../../brand/controller/brand_controller.dart';
import '../controller/product_controller.dart';

// ── Zoho Books design tokens ──────────────────────────────────────────────────
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
const _kAmber   = Color(0xFFB45309);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBd = Color(0xFFFCD28A);
const _kPurple  = Color(0xFF7C3AED);
const _kTeal    = Color(0xFF0D6E6E);
const _kTealBg  = Color(0xFFECFCFC);
const _kTealBd  = Color(0xFF99E6E6);

class _FilterTab {
  final String label;
  final String? apiValue;
  const _FilterTab({required this.label, this.apiValue});
}

const _kTabs = [
  _FilterTab(label: 'All'),
  _FilterTab(label: 'Active', apiValue: 'active'),
  _FilterTab(label: 'Inactive', apiValue: 'inactive'),
];

const _kCategories = ['All Categories', 'BATTERY', 'INVERTER'];

Color _dotColor(String? v) {
  switch (v) {
    case 'active':   return _kGreen;
    case 'inactive': return _kRed;
    default:         return _kT3;
  }
}

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});
  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  int    _tabIdx           = 0;
  List<String> _brands     = [];
  String _selectedCategory = 'All Categories';
  String _query            = '';
  bool   _showSearch       = false;

  final _searchCtrl = TextEditingController();
  final _scrollCtrl = ScrollController();
  final _chipCtrl   = ScrollController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _scrollCtrl.addListener(_onScroll);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchCtrl.dispose();
    _scrollCtrl.removeListener(_onScroll);
    _scrollCtrl.dispose();
    _chipCtrl.dispose();
    super.dispose();
  }

  Future<void> _applyFilters() async {
    final notifier = ref.read(productControllerProvider.notifier);
    notifier.setFilters(
      search:   _query.isEmpty ? null : _query,
      category: _selectedCategory == 'All Categories' ? null : _selectedCategory,
      status:   _status,
      brands:   _brands.isEmpty ? null : _brands,
    );
    await notifier.fetchProducts();
  }

  void _onScroll() {
    final pos = _scrollCtrl.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(productControllerProvider.notifier).fetchMoreProducts();
    }
  }

  String? get _status      => _kTabs[_tabIdx].apiValue;
  bool    get _hasCategory => _selectedCategory != 'All Categories';

  void _scrollChip(int i) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chipCtrl.hasClients) return;
      _chipCtrl.animateTo(
        (i * 100.0 - 60).clamp(0.0, _chipCtrl.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  void _onSearchChanged(String v) {
    final trimmed = v.trim();
    setState(() => _query = trimmed);
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      if (!mounted) return;
      _applyFilters();
    });
  }

  void _closeSearch() {
    _debounce?.cancel();
    setState(() {
      _showSearch = false;
      _query = '';
      _searchCtrl.clear();
    });
    _applyFilters();
  }

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    final productState    = ref.watch(productControllerProvider);
    final brandState      = ref.watch(brandControllerProvider);
    final paginationState = ref.watch(productPaginationProvider);

    // ── ALWAYS render the same scaffold/header/chips. Only the LIST
    //    area changes based on state. This is what gives dealers the
    //    "card body only loading" feel.
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [
          _buildHeader(context, sw, sh),
          _buildChipsRow(sw, sh, brandState),
          Divider(height: 1, color: _kBd),
          Expanded(
            child: _buildBodyArea(
              context, sw, sh,
              productState: productState,
              hasMore: paginationState.hasMore,
              isFiltering: paginationState.isFiltering,
            ),
          ),
        ]),
      ),
    );
  }

  // ── Header (search bar swap or normal title row) ─────────────────────────
  Widget _buildHeader(BuildContext context, double sw, double sh) {
    return Container(
      color: _kWhite,
      padding: EdgeInsets.fromLTRB(
          sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.012),
      child: _showSearch
          ? _searchBar(sw)
          : Row(children: [
        CircularIconButton(
            icon: Icons.arrow_back_ios_rounded,
            onTap: () => Navigator.pop(context)),
        const Spacer(),
        Text('Products',
            style: TextStyle(
                fontSize: (sw * 0.042).clamp(14.0, 20.0),
                fontWeight: FontWeight.w700,
                color: _kT1,
                letterSpacing: -0.2)),
        const Spacer(),
        CircularIconButton(
            icon: Icons.search_rounded,
            onTap: () => setState(() => _showSearch = true)),
        SizedBox(width: sw * 0.02),
        RoleGuard(
          feature: AppFeature.createProduct,
          child: CircularIconButton(
              icon: Icons.add,
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ProductCreateScreen()))),
        ),
      ]),
    );
  }

  // ── Filter chips row ─────────────────────────────────────────────────────
  Widget _buildChipsRow(
      double sw, double sh, AsyncValue<List<BrandModel>> brandState) {
    return Container(
      color: _kWhite,
      child: SizedBox(
        height: sh * 0.048,
        child: ListView.builder(
          controller: _chipCtrl,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.fromLTRB(sw * 0.04, 0, sw * 0.04, sh * 0.006),
          itemCount: _kTabs.length + 2,
          itemBuilder: (_, i) {
            if (i < _kTabs.length) return _statusChip(sw, i);
            if (i == _kTabs.length) return _categoryChip(sw, sh);
            return _brandChip(sw, brandState);
          },
        ),
      ),
    );
  }

  // ── Body area — this is the only thing that changes based on state ───────
  Widget _buildBodyArea(
      BuildContext context,
      double sw,
      double sh, {
        required AsyncValue<List> productState,
        required bool hasMore,
        required bool isFiltering,
      }) {
    // Keep the list visible during re-fetch — only show a full spinner on
    // the very first load when there's no cached data yet.
    final cached = productState.value;
    if (cached == null) {
      if (productState.hasError) return _bodyErrorView(sw, sh);
      return const Center(
        child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5),
      );
    }
    return _buildProductsBody(
        context, sw, sh, cached, hasMore: hasMore, isFiltering: isFiltering);
  }

  Widget _buildProductsBody(
      BuildContext context, double sw, double sh,
      List products, {
        required bool hasMore,
        required bool isFiltering,
      }) {
    // Filter change in flight + we still have old data → show overlay
    if (isFiltering && products.isEmpty) {
      // Filter change cleared the list — show body spinner
      return const Center(
        child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5),
      );
    }

    if (products.isEmpty) return _emptyView(sw, sh);

    return Stack(
          children: [
            RefreshIndicator(
              color: _kP,
              backgroundColor: _kWhite,
              onRefresh: () => _applyFilters(),
              child: ListView.builder(
                controller: _scrollCtrl,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.04),
                itemCount: products.length + (hasMore ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == products.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: sw * 0.05),
                      child: const Center(
                        child: SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: _kP, strokeWidth: 2.2),
                        ),
                      ),
                    );
                  }
                  final p = products[i];
                  return _ProductCard(
                    product: p,
                    sw: sw,
                    sh: sh,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProductDetailsScreen(
                                productId: p.productId!))),
                  );
                },
              ),
            ),

            // ── Filter-change overlay — translucent veil + spinner ────────
            // Old data stays visible underneath so the user has context.
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
        );
  }

  // ── Body error (no app bar — header/chips already rendered above) ────────
  Widget _bodyErrorView(double sw, double sh) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
              width: (sw * 0.18).clamp(60.0, 90.0),
              height: (sw * 0.18).clamp(60.0, 90.0),
              decoration: BoxDecoration(
                  color: _kRedBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: _kRedBd, width: 0.5)),
              child: Icon(Icons.wifi_off_rounded,
                  size: (sw * 0.09).clamp(30.0, 44.0), color: _kRed)),
          SizedBox(height: sh * 0.02),
          Text('No Internet Connection',
              style: TextStyle(
                  fontSize: (sw * 0.04).clamp(13.0, 18.0),
                  fontWeight: FontWeight.w600,
                  color: _kT2)),
          SizedBox(height: sh * 0.008),
          Text('Check your connection and try again',
              style: TextStyle(
                  fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
          SizedBox(height: sh * 0.025),
          ElevatedButton.icon(
            onPressed: () => _applyFilters(),
            icon: Icon(Icons.refresh_rounded,
                size: (sw * 0.04).clamp(14.0, 18.0)),
            label: Text('Retry',
                style: TextStyle(
                    fontSize: (sw * 0.034).clamp(11.5, 15.0),
                    fontWeight: FontWeight.w700)),
            style: ElevatedButton.styleFrom(
                backgroundColor: _kP,
                foregroundColor: _kWhite,
                padding: EdgeInsets.symmetric(
                    horizontal: (sw * 0.06).clamp(20.0, 28.0),
                    vertical: (sw * 0.028).clamp(9.0, 14.0)),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
                elevation: 0),
          ),
        ],
      ),
    );
  }

  // ── Status chip ──────────────────────────────────────────────────────────
  Widget _statusChip(double sw, int i) {
    final tab = _kTabs[i];
    final sel = _tabIdx == i;
    final dot = _dotColor(tab.apiValue);
    return GestureDetector(
      onTap: () {
        setState(() => _tabIdx = i);
        _scrollChip(i);
        _applyFilters();
      },
      child: Container(
        margin: EdgeInsets.only(right: sw * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: (sw * 0.032).clamp(10.0, 16.0),
            vertical: (sw * 0.014).clamp(5.0, 8.0)),
        decoration: BoxDecoration(
            color: sel ? _kWhite : _kBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: sel ? dot : _kBd, width: sel ? 1.0 : 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: (sw * 0.016).clamp(5.0, 8.0),
              height: (sw * 0.016).clamp(5.0, 8.0),
              decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
          SizedBox(width: sw * 0.015),
          Text(tab.label,
              style: TextStyle(
                  fontSize: (sw * 0.03).clamp(10.0, 13.0),
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color: sel ? _kT1 : _kT4)),
        ]),
      ),
    );
  }

  Widget _categoryChip(double sw, double sh) {
    final has = _hasCategory;
    return GestureDetector(
      onTap: () => _showCategorySheet(context, sw, sh),
      child: Container(
        margin: EdgeInsets.only(right: sw * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: (sw * 0.032).clamp(10.0, 16.0),
            vertical: (sw * 0.014).clamp(5.0, 8.0)),
        decoration: BoxDecoration(
            color: has ? _kTealBg : _kBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: has ? _kTealBd : _kBd, width: has ? 1.0 : 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: (sw * 0.016).clamp(5.0, 8.0),
              height: (sw * 0.016).clamp(5.0, 8.0),
              decoration: BoxDecoration(
                  color: has ? _kTeal : _kT4, shape: BoxShape.circle)),
          SizedBox(width: sw * 0.015),
          Text(
            has ? _selectedCategory : 'Category',
            style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0),
                fontWeight: has ? FontWeight.w700 : FontWeight.w500,
                color: has ? _kT1 : _kT4),
          ),
          if (has) ...[
            SizedBox(width: sw * 0.012),
            GestureDetector(
              onTap: () {
                setState(() => _selectedCategory = 'All Categories');
                _applyFilters();
              },
              child: Icon(Icons.close_rounded,
                  size: (sw * 0.032).clamp(11.0, 14.0), color: _kTeal),
            ),
          ] else ...[
            SizedBox(width: sw * 0.008),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: (sw * 0.035).clamp(12.0, 16.0), color: _kT4),
          ],
        ]),
      ),
    );
  }

  void _showCategorySheet(BuildContext context, double sw, double sh) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.fromLTRB(
              sw * 0.05, sw * 0.035, sw * 0.05, sw * 0.06),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                        color: _kBd,
                        borderRadius: BorderRadius.circular(2))),
              ),
              Row(children: [
                Container(
                    width: (sw * 0.09).clamp(32.0, 42.0),
                    height: (sw * 0.09).clamp(32.0, 42.0),
                    decoration: BoxDecoration(
                        color: _kTealBg,
                        borderRadius: BorderRadius.circular(
                            (sw * 0.025).clamp(8.0, 12.0))),
                    child: Icon(Icons.category_outlined,
                        size: (sw * 0.045).clamp(15.0, 20.0), color: _kTeal)),
                SizedBox(width: sw * 0.03),
                Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Filter by Category',
                            style: TextStyle(
                                fontSize: (sw * 0.042).clamp(14.0, 19.0),
                                fontWeight: FontWeight.w700,
                                color: _kT1)),
                        Text('Select a product category',
                            style: TextStyle(
                                fontSize: (sw * 0.028).clamp(9.5, 12.5),
                                color: _kT4)),
                      ]),
                ),
              ]),
              SizedBox(height: sw * 0.035),
              Divider(height: 1, color: _kBd),
              SizedBox(height: sw * 0.025),
              ..._kCategories.map((cat) {
                final isAll = cat == 'All Categories';
                final sel   = _selectedCategory == cat;

                IconData catIcon;
                Color catColor;
                Color catBg;
                switch (cat) {
                  case 'BATTERY':
                    catIcon  = Icons.battery_charging_full_rounded;
                    catColor = _kGreen;
                    catBg    = _kGreenBg;
                    break;
                  case 'INVERTER':
                    catIcon  = Icons.bolt_rounded;
                    catColor = _kP;
                    catBg    = _kPBg;
                    break;
                  default:
                    catIcon  = Icons.apps_rounded;
                    catColor = _kT3;
                    catBg    = _kBg;
                }

                return GestureDetector(
                  onTap: () {
                    Navigator.pop(context);
                    setState(() => _selectedCategory = cat);
                    _applyFilters();
                  },
                  child: Container(
                    margin: EdgeInsets.only(bottom: sw * 0.025),
                    padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.04, vertical: sw * 0.032),
                    decoration: BoxDecoration(
                        color: sel ? catBg : _kBg,
                        borderRadius: BorderRadius.circular(
                            (sw * 0.028).clamp(8.0, 12.0)),
                        border: Border.all(
                            color: sel
                                ? catColor.withValues(alpha: 0.5)
                                : _kBd,
                            width: sel ? 1.5 : 0.5)),
                    child: Row(children: [
                      Container(
                          width: (sw * 0.085).clamp(30.0, 40.0),
                          height: (sw * 0.085).clamp(30.0, 40.0),
                          decoration: BoxDecoration(
                              color: sel
                                  ? catColor.withValues(alpha: 0.15)
                                  : _kWhite,
                              borderRadius: BorderRadius.circular(
                                  (sw * 0.02).clamp(6.0, 10.0)),
                              border: Border.all(
                                  color: sel
                                      ? catColor.withValues(alpha: 0.3)
                                      : _kBd,
                                  width: 0.5)),
                          child: Icon(catIcon,
                              size: (sw * 0.042).clamp(14.0, 20.0),
                              color: sel ? catColor : _kT4)),
                      SizedBox(width: sw * 0.03),
                      Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(cat,
                                  style: TextStyle(
                                      fontSize:
                                      (sw * 0.036).clamp(12.0, 15.5),
                                      fontWeight: sel
                                          ? FontWeight.w700
                                          : FontWeight.w600,
                                      color: sel ? catColor : _kT1)),
                              if (!isAll)
                                Text('Show ${cat.toLowerCase()} products only',
                                    style: TextStyle(
                                        fontSize: (sw * 0.026)
                                            .clamp(9.0, 11.5),
                                        color: _kT4)),
                            ]),
                      ),
                      Container(
                          width: (sw * 0.048).clamp(16.0, 22.0),
                          height: (sw * 0.048).clamp(16.0, 22.0),
                          decoration: BoxDecoration(
                              color: sel ? catColor : _kWhite,
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: sel ? catColor : _kBd, width: 1.5)),
                          child: sel
                              ? Icon(Icons.check_rounded,
                              size: (sw * 0.03).clamp(10.0, 13.0),
                              color: _kWhite)
                              : null),
                    ]),
                  ),
                );
              }),
              SizedBox(height: sw * 0.01),
            ],
          ),
        ),
      ),
    );
  }

  Widget _brandChip(double sw, AsyncValue<List<BrandModel>> brandState) {
    final has = _brands.isNotEmpty;
    return GestureDetector(
      onTap: () => _showBrandSheet(
          context, sw, MediaQuery.sizeOf(context).height, brandState),
      child: Container(
        margin: EdgeInsets.only(right: sw * 0.02),
        padding: EdgeInsets.symmetric(
            horizontal: (sw * 0.032).clamp(10.0, 16.0),
            vertical: (sw * 0.014).clamp(5.0, 8.0)),
        decoration: BoxDecoration(
            color: has ? _kAmberBg : _kBg,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
                color: has ? _kAmberBd : _kBd, width: has ? 1.0 : 0.5)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Container(
              width: (sw * 0.016).clamp(5.0, 8.0),
              height: (sw * 0.016).clamp(5.0, 8.0),
              decoration: BoxDecoration(
                  color: has ? _kAmber : _kT4, shape: BoxShape.circle)),
          SizedBox(width: sw * 0.015),
          Text(
            has
                ? '${_brands.length} Brand${_brands.length > 1 ? 's' : ''}'
                : 'Brand',
            style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0),
                fontWeight: has ? FontWeight.w700 : FontWeight.w500,
                color: has ? _kT1 : _kT4),
          ),
          if (has) ...[
            SizedBox(width: sw * 0.012),
            GestureDetector(
              onTap: () {
                setState(() => _brands = []);
                _applyFilters();
              },
              child: Icon(Icons.close_rounded,
                  size: (sw * 0.032).clamp(11.0, 14.0), color: _kAmber),
            ),
          ],
        ]),
      ),
    );
  }

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
            hintText: 'Search products...',
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

  void _showBrandSheet(
      BuildContext context,
      double sw,
      double sh,
      AsyncValue<List<BrandModel>> brandState,
      ) {
    var temp = List<String>.from(_brands);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          builder: (_, sc) => Padding(
            padding: EdgeInsets.fromLTRB(
                sw * 0.05, sw * 0.035, sw * 0.05, sw * 0.06),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                          color: _kBd,
                          borderRadius: BorderRadius.circular(2))),
                ),
                Row(children: [
                  Container(
                      width: (sw * 0.09).clamp(32.0, 42.0),
                      height: (sw * 0.09).clamp(32.0, 42.0),
                      decoration: BoxDecoration(
                          color: _kAmberBg,
                          borderRadius: BorderRadius.circular(
                              (sw * 0.025).clamp(8.0, 12.0))),
                      child: Icon(Icons.local_offer_outlined,
                          size: (sw * 0.045).clamp(15.0, 20.0),
                          color: _kAmber)),
                  SizedBox(width: sw * 0.03),
                  Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Filter by Brand',
                              style: TextStyle(
                                  fontSize:
                                  (sw * 0.042).clamp(14.0, 19.0),
                                  fontWeight: FontWeight.w700,
                                  color: _kT1)),
                          Text('${temp.length} selected',
                              style: TextStyle(
                                  fontSize:
                                  (sw * 0.028).clamp(9.5, 12.5),
                                  color: _kT4)),
                        ]),
                  ),
                  if (temp.isNotEmpty)
                    GestureDetector(
                      onTap: () => setModal(() => temp = []),
                      child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal:
                              (sw * 0.03).clamp(10.0, 14.0),
                              vertical:
                              (sw * 0.015).clamp(4.0, 7.0)),
                          decoration: BoxDecoration(
                              color: _kRedBg,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: _kRedBd, width: 0.5)),
                          child: Text('Clear',
                              style: TextStyle(
                                  fontSize:
                                  (sw * 0.029).clamp(9.5, 12.5),
                                  fontWeight: FontWeight.w700,
                                  color: _kRed))),
                    ),
                ]),
                SizedBox(height: sw * 0.035),
                Divider(height: 1, color: _kBd),
                SizedBox(height: sw * 0.025),
                Expanded(
                  child: brandState.when(
                    loading: () => const Center(
                        child: CircularProgressIndicator(
                            color: _kAmber, strokeWidth: 2.5)),
                    error: (_, __) => Center(
                        child: Text('Failed to load brands',
                            style: TextStyle(
                                fontSize:
                                (sw * 0.034).clamp(11.5, 15.0),
                                color: _kRed))),
                    data: (brands) {
                      if (brands.isEmpty) {
                        return Center(
                            child: Text('No brands available',
                                style: TextStyle(
                                    fontSize: (sw * 0.034)
                                        .clamp(11.5, 15.0),
                                    color: _kT4)));
                      }
                      return ListView.builder(
                        controller: sc,
                        itemCount: brands.length,
                        itemBuilder: (_, i) {
                          final b   = brands[i];
                          final sel = temp.contains(b.brandName);
                          return GestureDetector(
                            onTap: () => setModal(() {
                              if (sel) {
                                temp = temp.where((x) => x != b.brandName).toList();
                              } else {
                                temp = [...temp, b.brandName];
                              }
                            }),
                            child: Container(
                              margin: EdgeInsets.only(bottom: sw * 0.02),
                              padding: EdgeInsets.symmetric(
                                  horizontal: sw * 0.035,
                                  vertical: sw * 0.028),
                              decoration: BoxDecoration(
                                  color: sel ? _kAmberBg : _kBg,
                                  borderRadius: BorderRadius.circular(
                                      (sw * 0.028).clamp(8.0, 12.0)),
                                  border: Border.all(
                                      color: sel ? _kAmberBd : _kBd,
                                      width: sel ? 1.0 : 0.5)),
                              child: Row(children: [
                                Container(
                                    width: (sw * 0.042).clamp(14.0, 20.0),
                                    height: (sw * 0.042).clamp(14.0, 20.0),
                                    decoration: BoxDecoration(
                                        color: sel ? _kAmber : _kWhite,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                            color: sel ? _kAmber : _kBd,
                                            width: 1.5)),
                                    child: sel
                                        ? Icon(Icons.check_rounded,
                                        size: (sw * 0.028)
                                            .clamp(9.0, 12.0),
                                        color: _kWhite)
                                        : null),
                                SizedBox(width: sw * 0.03),
                                Expanded(
                                  child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(b.brandName,
                                            style: TextStyle(
                                                fontSize: (sw * 0.034)
                                                    .clamp(11.5, 15.0),
                                                fontWeight: sel
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                color: sel ? _kAmber : _kT1)),
                                        if (b.brandModels.isNotEmpty)
                                          Text(
                                              '${b.brandModels.length} model${b.brandModels.length > 1 ? 's' : ''}',
                                              style: TextStyle(
                                                  fontSize: (sw * 0.027)
                                                      .clamp(9.0, 11.5),
                                                  color: _kT4)),
                                      ]),
                                ),
                              ]),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
                SizedBox(height: sw * 0.03),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      setState(() => _brands = List<String>.from(temp));
                      Navigator.pop(context);
                      _applyFilters();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kP,
                        foregroundColor: _kWhite,
                        padding:
                        EdgeInsets.symmetric(vertical: sh * 0.018),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                (sw * 0.035).clamp(10.0, 16.0))),
                        elevation: 0),
                    child: Text('Apply Filters',
                        style: TextStyle(
                            fontSize: (sw * 0.038).clamp(13.0, 17.0),
                            fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _emptyView(double sw, double sh) {
    String msg, sub;
    if (_query.isNotEmpty) {
      msg = 'No results for "$_query"';
      sub = 'Try a different search term';
    } else if (_hasCategory) {
      msg = 'No $_selectedCategory products';
      sub = 'Try a different category';
    } else if (_brands.isNotEmpty) {
      msg = 'No products from selected brand${_brands.length > 1 ? 's' : ''}';
      sub = 'Try selecting a different brand';
    } else if (_tabIdx != 0) {
      msg = 'No ${_kTabs[_tabIdx].label} products';
      sub = 'Try a different filter';
    } else {
      msg = 'No products found';
      sub = 'Try adjusting your filters';
    }

    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
            width: (sw * 0.18).clamp(60.0, 90.0),
            height: (sw * 0.18).clamp(60.0, 90.0),
            decoration: BoxDecoration(
                color: _kWhite,
                shape: BoxShape.circle,
                border: Border.all(color: _kBd, width: 0.5)),
            child: Icon(Icons.inventory_2_outlined,
                size: (sw * 0.09).clamp(30.0, 44.0), color: _kT4)),
        SizedBox(height: sh * 0.02),
        Text(msg,
            style: TextStyle(
                fontSize: (sw * 0.036).clamp(12.0, 16.0),
                fontWeight: FontWeight.w600,
                color: _kT2),
            textAlign: TextAlign.center),
        SizedBox(height: sh * 0.006),
        Text(sub,
            style: TextStyle(
                fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4),
            textAlign: TextAlign.center),
      ]),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Product Card
// ═════════════════════════════════════════════════════════════════════════════
class _ProductCard extends StatelessWidget {
  const _ProductCard(
      {required this.product,
        required this.sw,
        required this.sh,
        required this.onTap});
  final dynamic product;
  final double sw, sh;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = product.status?.toLowerCase() == 'active';
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: sh * 0.01),
        decoration: BoxDecoration(
            color: _kWhite,
            borderRadius:
            BorderRadius.circular((sw * 0.035).clamp(10.0, 16.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.035),
          child:
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  width: (sw * 0.095).clamp(34.0, 46.0),
                  height: (sw * 0.095).clamp(34.0, 46.0),
                  decoration: BoxDecoration(
                      color: _kPBg,
                      borderRadius: BorderRadius.circular(
                          (sw * 0.025).clamp(8.0, 12.0)),
                      border: Border.all(color: _kPBd, width: 0.5)),
                  child: Center(
                      child: SvgPicture.asset(AppIcons.product,
                          width: (sw * 0.042).clamp(14.0, 20.0),
                          colorFilter: const ColorFilter.mode(
                              _kP, BlendMode.srcIn)))),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.productName ?? 'Unnamed',
                          style: TextStyle(
                              fontSize: (sw * 0.035).clamp(12.0, 15.0),
                              fontWeight: FontWeight.w700,
                              color: _kT1,
                              letterSpacing: -0.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                      SizedBox(height: sw * 0.006),
                      Row(children: [
                        Flexible(
                            child: _Tag(
                                sw: sw,
                                label: product.brand ?? '-',
                                color: _kAmber,
                                bg: _kAmberBg)),
                        SizedBox(width: sw * 0.012),
                        Flexible(
                            child: _Tag(
                                sw: sw,
                                label: product.model ?? '-',
                                color: _kT3,
                                bg: _kBg)),
                        SizedBox(width: sw * 0.008),
                        Flexible(
                          child: Text(
                            product.productCategory ?? '-',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: (sw * 0.028).clamp(9.5, 12.5),
                                color: _kPurple,
                                fontWeight: FontWeight.w500),
                          ),
                        ),
                      ]),
                    ]),
              ),
              SizedBox(width: sw * 0.015),
              Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: (sw * 0.02).clamp(6.0, 10.0),
                      vertical: (sw * 0.008).clamp(3.0, 5.0)),
                  decoration: BoxDecoration(
                      color: active ? _kGreenBg : _kRedBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: active ? _kGreenBd : _kRedBd, width: 0.5)),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Container(
                        width: (sw * 0.014).clamp(4.0, 7.0),
                        height: (sw * 0.014).clamp(4.0, 7.0),
                        decoration: BoxDecoration(
                            color: active ? _kGreen : _kRed,
                            shape: BoxShape.circle)),
                    SizedBox(width: sw * 0.008),
                    Text(active ? 'Active' : 'Inactive',
                        style: TextStyle(
                            fontSize: (sw * 0.024).clamp(8.5, 11.0),
                            fontWeight: FontWeight.w700,
                            color: active ? _kGreen : _kRed)),
                  ])),
            ]),
            SizedBox(height: sw * 0.02),
            Row(children: [
              Icon(Icons.category_outlined,
                  size: (sw * 0.03).clamp(10.0, 14.0), color: _kT4),
              SizedBox(width: sw * 0.012),
              Text(product.productType ?? '-',
                  style: TextStyle(
                      fontSize: (sw * 0.028).clamp(9.5, 12.5),
                      color: _kT4,
                      fontWeight: FontWeight.w500)),
            ]),
            SizedBox(height: sw * 0.02),
            Divider(height: 1, color: _kBd),
            SizedBox(height: sw * 0.02),
            Row(children: [
              RoleGuard(
                feature: AppFeature.viewStock,
                child: Row(children: [
                  _StockPill(
                      sw: sw,
                      label: 'P',
                      value: product.packedStock?.toString() ?? '0',
                      color: _kGreen,
                      bg: _kGreenBg),
                  SizedBox(width: sw * 0.012),
                  _StockPill(
                      sw: sw,
                      label: 'U',
                      value: product.unpackedStock?.toString() ?? '0',
                      color: _kRed,
                      bg: _kRedBg),
                  SizedBox(width: sw * 0.012),
                  _StockPill(
                      sw: sw,
                      label: 'T',
                      value: product.availableStock?.toString() ?? '0',
                      color: _kP,
                      bg: _kPBg),
                ]),
              ),
              const Spacer(),
              RoleGuard(
                feature: AppFeature.viewPrice,
                child: Text('₹${product.price ?? '0'}',
                    style: TextStyle(
                        fontSize: (sw * 0.038).clamp(13.0, 17.0),
                        fontWeight: FontWeight.w800,
                        color: _kP,
                        letterSpacing: -0.3)),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag(
      {required this.sw,
        required this.label,
        required this.color,
        required this.bg});
  final double sw;
  final String label;
  final Color color, bg;

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.018).clamp(5.0, 9.0),
          vertical: (sw * 0.005).clamp(2.0, 4.0)),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5)),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: (sw * 0.025).clamp(8.5, 11.0),
              fontWeight: FontWeight.w600,
              color: color)));
}

class _StockPill extends StatelessWidget {
  const _StockPill(
      {required this.sw,
        required this.label,
        required this.value,
        required this.color,
        required this.bg});
  final double sw;
  final String label, value;
  final Color color, bg;

  @override
  Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.018).clamp(5.0, 9.0),
          vertical: (sw * 0.008).clamp(3.0, 5.0)),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2), width: 0.5)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: TextStyle(
                fontSize: (sw * 0.028).clamp(9.5, 12.5),
                fontWeight: FontWeight.w800,
                color: color)),
        SizedBox(width: sw * 0.006),
        Text(label,
            style: TextStyle(
                fontSize: (sw * 0.022).clamp(7.5, 10.0),
                fontWeight: FontWeight.w500,
                color: color.withValues(alpha: 0.7))),
      ]));
}