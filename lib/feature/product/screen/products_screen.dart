import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/feature/product/screen/product_create_screen.dart';
import 'package:inverter_management_app/feature/product/screen/product_view.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../core/const/icons.dart';
import '../../../core/theme/theme.dart';
import '../../../model/brand_model.dart';
import '../../../widgets/circle_button.dart';
import '../../brand/controller/brand_controller.dart';
import '../controller/product_controller.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kBlue        = Color(0xFF1B4FD8);
const _kBlueBg      = Color(0xFFEEF2FF);
const _kBlueBorder  = Color(0xFFC7D4FF);
const _kBg          = Color(0xFFF2F4F8);
const _kCard        = Colors.white;
const _kBorder      = Color(0xFFE5E7EB);
const _kDark        = Color(0xFF111827);
const _kMid         = Color(0xFF374151);
const _kMuted       = Color(0xFF9CA3AF);
const _kGreen       = Color(0xFF0A8A5C);
const _kGreenBg     = Color(0xFFEDFAF4);
const _kGreenBorder = Color(0xFF9FE0C5);
const _kRed         = Color(0xFFDC2626);
const _kRedBg       = Color(0xFFFEF2F2);
const _kRedBorder   = Color(0xFFFECACA);
const _kAmber       = Color(0xFFB45309);
const _kAmberBg     = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFCD28A);

// ─── Filter tab data ──────────────────────────────────────────────────────────
class _FilterTab {
  final String label;
  final String? apiValue; // null = All
  const _FilterTab({required this.label, this.apiValue});
}

const List<_FilterTab> _kStatusTabs = [
  _FilterTab(label: 'All',      apiValue: null),
  _FilterTab(label: 'Active',   apiValue: 'active'),
  _FilterTab(label: 'Inactive', apiValue: 'inactive'),
];

Color _statusDotColor(String? apiValue) {
  switch (apiValue) {
    case 'active':   return _kGreen;
    case 'inactive': return _kRed;
    default:         return const Color(0xFF6B7280);
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  int _selectedTabIndex = 0;

  List<String> _selectedBrands = [];
  String _searchQuery = '';
  bool _showSearch = false;
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final _chipScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    _chipScrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_selectedBrands.isNotEmpty) return;
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - 300) {
      ref.read(productControllerProvider.notifier).fetchMoreProducts();
    }
  }

  String get _brandKey => (List<String>.from(_selectedBrands)..sort()).join(',');

  String? get _currentStatus => _kStatusTabs[_selectedTabIndex].apiValue;

  void _scrollChipIntoView(int index) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_chipScrollController.hasClients) return;
      const itemW = 100.0;
      final target = (index * itemW) - 60.0;
      _chipScrollController.animateTo(
        target.clamp(0.0, _chipScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 280),
        curve: Curves.easeOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    final productState = _selectedBrands.isEmpty
        ? ref.watch(productControllerProvider)
        : ref.watch(productByBrandProvider(_brandKey));

    final brandState = ref.watch(loadBrandsControllerProvider);

    final isFetchingMore = _selectedBrands.isEmpty &&
        ref.watch(productControllerProvider.notifier.select((_) => _.isFetchingMore));

    final hasMore = _selectedBrands.isEmpty &&
        ref.watch(productControllerProvider.notifier.select((_) => _.hasMore));

    return productState.when(
      loading: () => const Scaffold(
        backgroundColor: _kBg,
        body: Center(child: GlobalLoader()),
      ),
      error: (err, stack) {
        if (_selectedBrands.isNotEmpty) {
          return _buildScaffold(context, sw, sh,
              filtered: const [], allCount: 0,
              hasMore: false, isFetchingMore: false, brandState: brandState);
        }
        return _buildError(context, sw, sh);
      },
      data: (products) {
        final allCount = _selectedBrands.isEmpty
            ? products.length
            : (ref.read(productControllerProvider).value?.length ?? products.length);

        final filtered = products.where((p) {
          final statusOk = _currentStatus == null ||
              p.status?.toLowerCase() == _currentStatus;
          if (!statusOk) return false;
          if (_searchQuery.isEmpty) return true;
          final q = _searchQuery.toLowerCase();
          return (p.productName?.toLowerCase().contains(q) ?? false) ||
              (p.brand?.toLowerCase().contains(q) ?? false) ||
              (p.model?.toLowerCase().contains(q) ?? false) ||
              (p.productType?.toLowerCase().contains(q) ?? false);
        }).toList();

        return _buildScaffold(context, sw, sh,
            filtered: filtered, allCount: allCount,
            hasMore: hasMore, isFetchingMore: isFetchingMore,
            brandState: brandState);
      },
    );
  }

  Widget _buildScaffold(
      BuildContext context, double sw, double sh, {
        required List filtered,
        required int allCount,
        required bool hasMore,
        required bool isFetchingMore,
        required AsyncValue<List<BrandModel>> brandState,
      }) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [

          // ── Header (white container) ──────────────────────────────────────
          Container(
            color: _kCard,
            child: Column(children: [

              // Top nav row
              Padding(
                padding: EdgeInsets.fromLTRB(
                    sw * 0.04, sw * 0.035, sw * 0.04, sw * 0.02),
                child: _showSearch
                    ? _buildSearchBar(sw)
                    : Row(children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('Products',
                      style: TextStyle(
                          fontSize: sw * 0.042,
                          fontWeight: FontWeight.w800,
                          color: _kDark,
                          letterSpacing: -0.3)),
                  const Spacer(),
                  CircularIconButton(
                    icon: Icons.search_rounded,
                    onTap: () => setState(() => _showSearch = true),
                  ),
                  SizedBox(width: sw * 0.02),
                  RoleGuard(
                    feature: AppFeature.createProduct,
                    child: CircularIconButton(
                      icon: Icons.add,
                      onTap: () => Navigator.push(context,
                          MaterialPageRoute(
                              builder: (_) => const ProductCreateScreen())),
                    ),
                  ),
                ]),
              ),

              // ── Chip row: Status tabs + Brand filter ──────────────────────
              SizedBox(
                height: sh * 0.052,
                child: ListView.builder(
                  controller: _chipScrollController,
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(sw * 0.04, 0, sw * 0.04, sh * 0.007),
                  // Status tabs + 1 brand chip
                  itemCount: _kStatusTabs.length + 1,
                  itemBuilder: (_, i) {
                    // Brand filter chip at the end
                    if (i == _kStatusTabs.length) {
                      final hasBrand = _selectedBrands.isNotEmpty;
                      return GestureDetector(
                        onTap: () => _showBrandFilterSheet(
                            context, sw, sh, brandState),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: EdgeInsets.only(right: sw * 0.022),
                          padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.032,
                              vertical: sw * 0.016),
                          decoration: BoxDecoration(
                            color: hasBrand ? _kAmberBg : const Color(0xFFF3F4F6),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: hasBrand ? _kAmberBorder : _kBorder,
                              width: hasBrand ? 1.5 : 1,
                            ),
                            boxShadow: hasBrand
                                ? [BoxShadow(
                                color: _kAmber.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 2))]
                                : [],
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Container(
                              width: sw * 0.018,
                              height: sw * 0.018,
                              decoration: BoxDecoration(
                                color: hasBrand ? _kAmber : _kMuted,
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: sw * 0.018),
                            Text(
                              hasBrand
                                  ? '${_selectedBrands.length} Brand${_selectedBrands.length > 1 ? 's' : ''}'
                                  : 'Brand',
                              style: TextStyle(
                                fontSize: sw * 0.03,
                                fontWeight: hasBrand
                                    ? FontWeight.w700
                                    : FontWeight.w500,
                                color: hasBrand ? _kDark : _kMuted,
                              ),
                            ),
                            if (hasBrand) ...[
                              SizedBox(width: sw * 0.016),
                              GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedBrands = []),
                                child: Icon(Icons.close_rounded,
                                    size: sw * 0.032, color: _kAmber),
                              ),
                            ],
                          ]),
                        ),
                      );
                    }

                    // Status tab chip
                    final tab = _kStatusTabs[i];
                    final isSelected = _selectedTabIndex == i;
                    final dotColor = _statusDotColor(tab.apiValue);

                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedTabIndex = i);
                        _scrollChipIntoView(i);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        curve: Curves.easeOut,
                        margin: EdgeInsets.only(right: sw * 0.022),
                        padding: EdgeInsets.symmetric(
                            horizontal: sw * 0.032, vertical: sw * 0.016),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? _kCard
                              : const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isSelected ? dotColor : _kBorder,
                            width: isSelected ? 1.5 : 1,
                          ),
                          boxShadow: isSelected
                              ? [BoxShadow(
                              color: dotColor.withValues(alpha: 0.18),
                              blurRadius: 8,
                              offset: const Offset(0, 2))]
                              : [],
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Container(
                            width: sw * 0.018,
                            height: sw * 0.018,
                            decoration: BoxDecoration(
                              color: dotColor,
                              shape: BoxShape.circle,
                            ),
                          ),
                          SizedBox(width: sw * 0.018),
                          Text(
                            tab.label,
                            style: TextStyle(
                              fontSize: sw * 0.03,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? _kDark
                                  : _kMuted,
                            ),
                          ),
                        ]),
                      ),
                    );
                  },
                ),
              ),

              Container(height: 1, color: const Color(0xFFF3F4F6)),
            ]),
          ),

          SizedBox(height: sw * 0.02),

          // ── Product List ──────────────────────────────────────────────────
          Expanded(
            child: filtered.isEmpty
                ? _buildEmpty(sw, sh)
                : RefreshIndicator(
              color: _kBlue,
              backgroundColor: _kCard,
              onRefresh: () async => ref
                  .read(productControllerProvider.notifier)
                  .fetchProducts(),
              child: ListView.builder(
                controller: _scrollController,
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    sw * 0.04, 0, sw * 0.04, sw * 0.06),
                itemCount:
                filtered.length + (_selectedBrands.isEmpty && hasMore ? 1 : 0),
                itemBuilder: (_, i) {
                  if (i == filtered.length) {
                    return Padding(
                      padding: EdgeInsets.symmetric(vertical: sw * 0.05),
                      child: const Center(
                        child: CircularProgressIndicator(color: _kBlue),
                      ),
                    );
                  }
                  final p = filtered[i];
                  return _ProductCard(
                    product: p,
                    sw: sw,
                    sh: sh,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            ProductDetailsScreen(productId: p.productId!),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────
  Widget _buildSearchBar(double sw) {
    return Row(children: [
      Expanded(
        child: TextField(
          controller: _searchController,
          autofocus: true,
          onChanged: (v) => setState(() => _searchQuery = v),
          style: TextStyle(
              fontSize: sw * 0.035,
              color: _kDark,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'Search products...',
            hintStyle: TextStyle(
                fontSize: sw * 0.033,
                color: _kMuted,
                fontWeight: FontWeight.w400),
            prefixIcon: Icon(Icons.search_rounded,
                color: _kMuted, size: sw * 0.048),
            filled: true,
            fillColor: _kBg,
            contentPadding: const EdgeInsets.symmetric(vertical: 0),
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.03),
                borderSide: const BorderSide(color: _kBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.03),
                borderSide: const BorderSide(color: _kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.03),
                borderSide: const BorderSide(color: _kBlue, width: 1.5)),
          ),
        ),
      ),
      SizedBox(width: sw * 0.02),
      CircularIconButton(
        icon: Icons.close_rounded,
        onTap: () => setState(() {
          _showSearch = false;
          _searchQuery = '';
          _searchController.clear();
        }),
      ),
    ]);
  }

  // ── Brand Filter Sheet ────────────────────────────────────────────────────
  void _showBrandFilterSheet(BuildContext context, double sw, double sh,
      AsyncValue<List<BrandModel>> brandState) {
    List<String> tempSelected = List<String>.from(_selectedBrands);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kCard,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModal) => DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          maxChildSize: 0.85,
          builder: (_, sc) => Padding(
            padding: EdgeInsets.fromLTRB(
                sw * 0.05, sw * 0.035, sw * 0.05, sw * 0.06),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              // Header
              Row(children: [
                Container(
                  width: sw * 0.1, height: sw * 0.1,
                  decoration: BoxDecoration(
                    color: _kAmberBg,
                    borderRadius: BorderRadius.circular(sw * 0.025),
                    border: Border.all(color: _kAmberBorder),
                  ),
                  child: Center(
                    child: SvgPicture.asset(AppIcons.brand,
                        width: sw * 0.05,
                        colorFilter: const ColorFilter.mode(
                            _kAmber, BlendMode.srcIn)),
                  ),
                ),
                SizedBox(width: sw * 0.03),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Filter by Brand',
                        style: TextStyle(
                            fontSize: sw * 0.042,
                            fontWeight: FontWeight.w800,
                            color: _kDark)),
                    Text('${tempSelected.length} selected',
                        style: TextStyle(
                            fontSize: sw * 0.028,
                            color: _kMuted,
                            fontWeight: FontWeight.w500)),
                  ]),
                ),
                if (tempSelected.isNotEmpty)
                  GestureDetector(
                    onTap: () => setModal(() => tempSelected = []),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _kRedBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kRedBorder),
                      ),
                      child: Text('Clear',
                          style: TextStyle(
                              fontSize: sw * 0.029,
                              fontWeight: FontWeight.w700,
                              color: _kRed)),
                    ),
                  ),
              ]),
              SizedBox(height: sw * 0.035),
              const Divider(height: 1, color: _kBorder),
              SizedBox(height: sw * 0.025),
              // Brand list
              Expanded(
                child: brandState.when(
                  loading: () => const Center(
                      child: CircularProgressIndicator(color: _kAmber)),
                  error: (_, __) => Center(
                      child: Text('Failed to load brands',
                          style: TextStyle(fontSize: sw * 0.034, color: _kRed))),
                  data: (brands) {
                    if (brands.isEmpty) {
                      return Center(
                          child: Text('No brands available',
                              style: TextStyle(
                                  fontSize: sw * 0.034, color: _kMuted)));
                    }
                    return ListView.builder(
                      controller: sc,
                      itemCount: brands.length,
                      itemBuilder: (_, i) {
                        final brand = brands[i];
                        final isSel =
                        tempSelected.contains(brand.brandName);
                        return GestureDetector(
                          onTap: () => setModal(() {
                            if (isSel) {
                              tempSelected = tempSelected
                                  .where((b) => b != brand.brandName)
                                  .toList();
                            } else {
                              tempSelected = [...tempSelected, brand.brandName];
                            }
                          }),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: EdgeInsets.only(bottom: sw * 0.02),
                            padding: EdgeInsets.symmetric(
                                horizontal: sw * 0.035,
                                vertical: sw * 0.028),
                            decoration: BoxDecoration(
                              color: isSel ? _kAmberBg : _kBg,
                              borderRadius:
                              BorderRadius.circular(sw * 0.028),
                              border: Border.all(
                                color: isSel ? _kAmberBorder : _kBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Row(children: [
                              Container(
                                width: sw * 0.042,
                                height: sw * 0.042,
                                decoration: BoxDecoration(
                                  color: isSel ? _kAmber : _kCard,
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: isSel ? _kAmber : _kBorder,
                                    width: 2,
                                  ),
                                ),
                                child: isSel
                                    ? Icon(Icons.check_rounded,
                                    size: sw * 0.028,
                                    color: _kCard)
                                    : null,
                              ),
                              SizedBox(width: sw * 0.03),
                              Expanded(
                                child: Column(
                                    crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                    children: [
                                      Text(brand.brandName,
                                          style: TextStyle(
                                            fontSize: sw * 0.034,
                                            fontWeight: isSel
                                                ? FontWeight.w700
                                                : FontWeight.w600,
                                            color: isSel ? _kAmber : _kDark,
                                          )),
                                      if (brand.brandModels.isNotEmpty) ...[
                                        SizedBox(height: sw * 0.004),
                                        Text(
                                          '${brand.brandModels.length} model${brand.brandModels.length > 1 ? 's' : ''}',
                                          style: TextStyle(
                                              fontSize: sw * 0.027,
                                              color: _kMuted,
                                              fontWeight: FontWeight.w500),
                                        ),
                                      ],
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
              // Apply button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    setState(
                            () => _selectedBrands = List<String>.from(tempSelected));
                    Navigator.pop(context);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kBlue,
                    foregroundColor: _kCard,
                    padding: EdgeInsets.symmetric(vertical: sh * 0.018),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(sw * 0.035)),
                    elevation: 0,
                  ),
                  child: Text('Apply Filters',
                      style: TextStyle(
                          fontSize: sw * 0.038, fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ),
        ),
      ),
    );
  }

  // ── Empty State ───────────────────────────────────────────────────────────
  Widget _buildEmpty(double sw, double sh) {
    final String message;
    final String subtitle;

    if (_searchQuery.isNotEmpty) {
      message = 'No results for "$_searchQuery"';
      subtitle = 'Try a different search term';
    } else if (_selectedBrands.isNotEmpty) {
      message =
      'No products from selected brand${_selectedBrands.length > 1 ? 's' : ''}';
      subtitle = 'Try selecting a different brand';
    } else if (_selectedTabIndex != 0) {
      message = 'No ${_kStatusTabs[_selectedTabIndex].label} products';
      subtitle = 'Try a different filter or add a new product';
    } else {
      message = 'No products found';
      subtitle = 'Try adjusting your filters or search';
    }

    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: sw * 0.2, height: sw * 0.2,
          decoration: BoxDecoration(
            color: _kBg, shape: BoxShape.circle,
            border: Border.all(color: _kBorder),
          ),
          child: Icon(Icons.inventory_2_outlined,
              size: sw * 0.1, color: const Color(0xFFD1D5DB)),
        ),
        SizedBox(height: sh * 0.025),
        Text(message,
            style: TextStyle(
                fontSize: sw * 0.038,
                fontWeight: FontWeight.w600,
                color: _kMid),
            textAlign: TextAlign.center),
        SizedBox(height: sh * 0.008),
        Text(subtitle,
            style: TextStyle(fontSize: sw * 0.03, color: _kMuted),
            textAlign: TextAlign.center),
        if (_selectedBrands.isNotEmpty) ...[
          SizedBox(height: sh * 0.025),
          GestureDetector(
            onTap: () => setState(() => _selectedBrands = []),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _kAmberBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kAmberBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.close_rounded, size: 15, color: _kAmber),
                const SizedBox(width: 6),
                Text('Clear brand filter',
                    style: TextStyle(
                        fontSize: sw * 0.03,
                        fontWeight: FontWeight.w700,
                        color: _kAmber)),
              ]),
            ),
          ),
        ],
        if (_selectedBrands.isEmpty && _selectedTabIndex != 0) ...[
          SizedBox(height: sh * 0.025),
          GestureDetector(
            onTap: () => setState(() => _selectedTabIndex = 0),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
              decoration: BoxDecoration(
                color: _kBlueBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _kBlueBorder),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.apps_rounded, size: 15, color: _kBlue),
                const SizedBox(width: 6),
                Text('View all products',
                    style: TextStyle(
                        fontSize: sw * 0.03,
                        fontWeight: FontWeight.w700,
                        color: _kBlue)),
              ]),
            ),
          ),
        ],
      ]),
    );
  }

  // ── Network Error ─────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, double sw, double sh) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.03),
            child: Row(children: [
              CircularIconButton(
                icon: Icons.arrow_back_ios_rounded,
                onTap: () => Navigator.pop(context),
              ),
              const Spacer(),
              Text('Products',
                  style: TextStyle(
                      fontSize: sw * 0.042,
                      fontWeight: FontWeight.w800,
                      color: _kDark)),
              const Spacer(),
              SizedBox(width: sw * 0.095),
            ]),
          ),
          Expanded(
            child: Center(
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(
                  width: sw * 0.2, height: sw * 0.2,
                  decoration: BoxDecoration(
                    color: _kRedBg, shape: BoxShape.circle,
                    border: Border.all(color: _kRedBorder),
                  ),
                  child: Icon(Icons.wifi_off_rounded,
                      size: sw * 0.1, color: _kRed),
                ),
                SizedBox(height: sh * 0.02),
                Text('No Internet Connection',
                    style: TextStyle(
                        fontSize: sw * 0.04,
                        fontWeight: FontWeight.w600,
                        color: _kMid)),
                SizedBox(height: sh * 0.008),
                Text('Check your connection and try again',
                    style:
                    TextStyle(fontSize: sw * 0.03, color: _kMuted)),
                SizedBox(height: sh * 0.025),
                GestureDetector(
                  onTap: () => ref
                      .read(productControllerProvider.notifier)
                      .fetchProducts(),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: _kBlueBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kBlueBorder),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.refresh_rounded,
                          size: 16, color: _kBlue),
                      const SizedBox(width: 8),
                      Text('Retry',
                          style: TextStyle(
                              fontSize: sw * 0.034,
                              fontWeight: FontWeight.w700,
                              color: _kBlue)),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─── Product Card (compact) ───────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final dynamic product;
  final double sw, sh;
  final VoidCallback onTap;

  const _ProductCard(
      {required this.product,
        required this.sw,
        required this.sh,
        required this.onTap});

  @override
  Widget build(BuildContext context) {
    final isActive = product.status?.toLowerCase() == 'active';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: sw * 0.025),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(sw * 0.038),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.035),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // ── Row 1: Name + status badge ──────────────────────────────────
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Blue icon badge
              Container(
                width: sw * 0.1,
                height: sw * 0.1,
                decoration: BoxDecoration(
                  color: _kBlueBg,
                  borderRadius: BorderRadius.circular(sw * 0.025),
                  border: Border.all(color: _kBlueBorder),
                ),
                child: Center(
                  child: SvgPicture.asset(AppIcons.product,
                      width: sw * 0.046,
                      colorFilter: const ColorFilter.mode(
                          _kBlue, BlendMode.srcIn)),
                ),
              ),
              SizedBox(width: sw * 0.03),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(
                    product.productName ?? 'Unnamed Product',
                    style: TextStyle(
                        fontSize: sw * 0.035,
                        fontWeight: FontWeight.w700,
                        color: _kDark,
                        letterSpacing: -0.2),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: sw * 0.008),
                  // Brand + Model inline
                  Row(children: [
                    _InlineTag(
                      label: product.brand ?? 'No brand',
                      color: _kAmber,
                      bg: _kAmberBg,
                      sw: sw,
                    ),
                    SizedBox(width: sw * 0.015),
                    _InlineTag(
                      label: product.model ?? 'No model',
                      color: _kMid,
                      bg: _kBg,
                      sw: sw,
                    ),
                  ]),
                ]),
              ),
              SizedBox(width: sw * 0.02),
              // Status pill
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.022, vertical: sw * 0.009),
                decoration: BoxDecoration(
                  color: isActive ? _kGreenBg : _kRedBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isActive ? _kGreenBorder : _kRedBorder),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Container(
                    width: sw * 0.016,
                    height: sw * 0.016,
                    decoration: BoxDecoration(
                      color: isActive ? _kGreen : _kRed,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: sw * 0.01),
                  Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                        fontSize: sw * 0.024,
                        fontWeight: FontWeight.w700,
                        color: isActive ? _kGreen : _kRed),
                  ),
                ]),
              ),
            ]),

            SizedBox(height: sw * 0.028),

            // ── Row 2: Type tag ─────────────────────────────────────────────
            Row(children: [
              Icon(Icons.category_outlined, size: sw * 0.032, color: _kMuted),
              SizedBox(width: sw * 0.015),
              Text(
                product.productType ?? 'No type',
                style: TextStyle(
                    fontSize: sw * 0.029,
                    color: _kMuted,
                    fontWeight: FontWeight.w500),
              ),
            ]),

            SizedBox(height: sw * 0.025),

            // ── Divider ─────────────────────────────────────────────────────
            Container(height: 1, color: const Color(0xFFF3F4F6)),
            SizedBox(height: sw * 0.025),

            // ── Row 3: Stock + Price ────────────────────────────────────────
            Row(children: [
              // Stock chips
              RoleGuard(
                feature: AppFeature.viewStock,
                child: Row(children: [
                  _StockChip(
                    sw: sw,
                    label: 'Packed',
                    value: product.packedStock?.toString() ?? '0',
                    color: _kGreen,
                    bg: _kGreenBg,
                  ),
                  SizedBox(width: sw * 0.015),
                  _StockChip(
                    sw: sw,
                    label: 'Unpacked',
                    value: product.unpackedStock?.toString() ?? '0',
                    color: _kRed,
                    bg: _kRedBg,
                  ),
                  SizedBox(width: sw * 0.015),
                  _StockChip(
                    sw: sw,
                    label: 'Total',
                    value: product.availableStock?.toString() ?? '0',
                    color: _kBlue,
                    bg: _kBlueBg,
                  ),
                ]),
              ),
              const Spacer(),
              // Price
              RoleGuard(
                feature: AppFeature.viewPrice,
                child: Row(children: [
                  Text('₹',
                      style: TextStyle(
                          fontSize: sw * 0.028,
                          fontWeight: FontWeight.w700,
                          color: _kBlue)),
                  Text(
                    '${product.price ?? '0'}',
                    style: TextStyle(
                        fontSize: sw * 0.038,
                        fontWeight: FontWeight.w800,
                        color: _kBlue,
                        letterSpacing: -0.3),
                  ),
                ]),
              ),
            ]),
          ]),
        ),
      ),
    );
  }
}

// ─── Inline Tag ───────────────────────────────────────────────────────────────
class _InlineTag extends StatelessWidget {
  final String label;
  final Color color, bg;
  final double sw;

  const _InlineTag(
      {required this.label,
        required this.color,
        required this.bg,
        required this.sw});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: sw * 0.02, vertical: sw * 0.006),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
              fontSize: sw * 0.026,
              fontWeight: FontWeight.w600,
              color: color)),
    );
  }
}

// ─── Stock Chip ───────────────────────────────────────────────────────────────
class _StockChip extends StatelessWidget {
  final double sw;
  final String label, value;
  final Color color, bg;

  const _StockChip(
      {required this.sw,
        required this.label,
        required this.value,
        required this.color,
        required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: sw * 0.022, vertical: sw * 0.009),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text(value,
            style: TextStyle(
                fontSize: sw * 0.028,
                fontWeight: FontWeight.w800,
                color: color)),
        Text(label,
            style: TextStyle(
                fontSize: sw * 0.022,
                color: color.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500)),
      ]),
    );
  }
}

// ─── Meta Row (kept for compatibility, no longer used in card) ────────────────
class _MetaRow extends StatelessWidget {
  const _MetaRow(
      {required this.sw,
        required this.iconPath,
        required this.iconColor,
        required this.value});
  final double sw;
  final String iconPath;
  final Color iconColor;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      SvgPicture.asset(iconPath,
          width: sw * 0.035,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn)),
      SizedBox(width: sw * 0.018),
      Text(value,
          style: TextStyle(
              fontSize: sw * 0.03,
              color: _kMid,
              fontWeight: FontWeight.w500)),
    ]);
  }
}