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
const _kBlue = Color(0xFF1B4FD8);
const _kBlueBg = Color(0xFFEEF2FF);
const _kBlueBorder = Color(0xFFC7D4FF);
const _kBg = Color(0xFFF2F4F8);
const _kCard = Colors.white;
const _kBorder = Color(0xFFE5E7EB);
const _kDark = Color(0xFF111827);
const _kMid = Color(0xFF374151);
const _kMuted = Color(0xFF9CA3AF);
const _kGreen = Color(0xFF0A8A5C);
const _kGreenBg = Color(0xFFEDFAF4);
const _kGreenBorder = Color(0xFF9FE0C5);
const _kRed = Color(0xFFDC2626);
const _kRedBg = Color(0xFFFEF2F2);
const _kRedBorder = Color(0xFFFECACA);
const _kAmber = Color(0xFFB45309);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFCD28A);

class ProductsScreen extends ConsumerStatefulWidget {
  const ProductsScreen({super.key});

  @override
  ConsumerState<ProductsScreen> createState() => _ProductsScreenState();
}

class _ProductsScreenState extends ConsumerState<ProductsScreen> {
  String _statusFilter = 'All';
  final List<String> _statusFilters = ['All', 'Active', 'Inactive'];

  final List<String> _selectedBrands = []; // API filters by these brands
  String _searchQuery = '';
  bool _showSearch = false;
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    // Use API-based brand filtering when brands are selected
    final productState = _selectedBrands.isEmpty
        ? ref.watch(productControllerProvider)
        : ref.watch(productByBrandProvider(_selectedBrands));

    final brandState = ref.watch(loadBrandsControllerProvider);

    return productState.when(
      loading: () => const Scaffold(
          backgroundColor: _kBg, body: Center(child: GlobalLoader())),
      error: (_, __) => _buildError(context, sw, sh),
      data: (products) {
        // Get total count for display (when brand filtering, show all products count)
        final allProductsCount = _selectedBrands.isEmpty
            ? products.length
            : (ref.read(productControllerProvider).value?.length ?? products.length);

        // Apply local filters (status and search)
        var filtered = products.where((p) {
          // Status filter
          bool statusMatch = true;
          if (_statusFilter == 'Active') {
            statusMatch = p.status?.toLowerCase() == 'active';
          } else if (_statusFilter == 'Inactive') {
            statusMatch = p.status?.toLowerCase() == 'inactive';
          }

          // Search filter
          bool searchMatch = true;
          if (_searchQuery.isNotEmpty) {
            final query = _searchQuery.toLowerCase();
            searchMatch = (p.productName?.toLowerCase().contains(query) ?? false) ||
                (p.brand?.toLowerCase().contains(query) ?? false) ||
                (p.model?.toLowerCase().contains(query) ?? false) ||
                (p.productType?.toLowerCase().contains(query) ?? false);
          }

          return statusMatch && searchMatch;
        }).toList();

        return Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: Column(
              children: [
                // ── Top Nav ──────────────────────────────
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.04, vertical: sw * 0.03),
                  child: _showSearch
                      ? _buildSearchBar(sw)
                      : Row(
                    children: [
                      CircularIconButton(
                        icon: Icons.arrow_back_ios_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text('Products',
                          style: TextStyle(
                              fontSize: sw * 0.042,
                              fontWeight: FontWeight.w700,
                              color: _kDark,
                              letterSpacing: -0.2)),
                      const Spacer(),
                      CircularIconButton(
                        icon: Icons.search_rounded,
                        onTap: () => setState(() => _showSearch = true),
                      ),
                      SizedBox(width: sw * 0.02),
                      RoleGuard(feature: AppFeature.createProduct, child:  CircularIconButton(
                        icon: Icons.add,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const ProductCreateScreen()),
                        ),
                      ),

                      )

                    ],
                  ),
                ),

                // ── Status Filter chips ──────────────────────────
                SizedBox(
                  height: sw * 0.09,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(left: sw * 0.04),
                    itemCount: _statusFilters.length,
                    itemBuilder: (_, i) {
                      final f = _statusFilters[i];
                      final sel = f == _statusFilter;
                      return Padding(
                        padding: EdgeInsets.only(right: sw * 0.02),
                        child: GestureDetector(
                          onTap: () => setState(() => _statusFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(
                                horizontal: sw * 0.04, vertical: sw * 0.015),
                            decoration: BoxDecoration(
                              color: sel ? _kBlue : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: sel ? _kBlue : _kBorder, width: 1.5),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                    fontSize: sw * 0.03,
                                    fontWeight: FontWeight.w700,
                                    color: sel ? Colors.white : _kMid)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: sw * 0.02),

                // ── Brand Filter + Count ──────────────────
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.04),
                  child: Row(
                    children: [
                      // Brand Filter Button
                      GestureDetector(
                        onTap: () => _showBrandFilterSheet(context, sw, sh, brandState),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.03, vertical: sw * 0.02),
                          decoration: BoxDecoration(
                            color: _selectedBrands.isEmpty ? Colors.white : _kAmberBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: _selectedBrands.isEmpty ? _kBorder : _kAmberBorder,
                              width: 1.5,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              SvgPicture.asset(
                                AppIcons.brand,
                                width: sw * 0.04,
                                colorFilter: ColorFilter.mode(
                                  _selectedBrands.isEmpty ? _kMuted : _kAmber,
                                  BlendMode.srcIn,
                                ),
                              ),
                              SizedBox(width: sw * 0.015),
                              Text(
                                _selectedBrands.isEmpty
                                    ? 'Filter by Brand'
                                    : '${_selectedBrands.length} Brand${_selectedBrands.length > 1 ? 's' : ''}',
                                style: TextStyle(
                                  fontSize: sw * 0.029,
                                  fontWeight: FontWeight.w700,
                                  color: _selectedBrands.isEmpty ? _kMuted : _kAmber,
                                ),
                              ),
                              if (_selectedBrands.isNotEmpty) ...[
                                SizedBox(width: sw * 0.015),
                                GestureDetector(
                                  onTap: () => setState(() => _selectedBrands.clear()),
                                  child: Icon(Icons.close_rounded,
                                      size: sw * 0.04, color: _kAmber),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Count pill
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: sw * 0.03, vertical: sw * 0.01),
                        decoration: BoxDecoration(
                          color: _kBlueBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kBlueBorder),
                        ),
                        child: Text(
                          _selectedBrands.isEmpty
                              ? '${filtered.length} of ${allProductsCount}'
                              : '${filtered.length} from brands',
                          style: TextStyle(
                              fontSize: sw * 0.029,
                              fontWeight: FontWeight.w700,
                              color: _kBlue),
                        ),
                      ),
                    ],
                  ),
                ),

                SizedBox(height: sw * 0.025),

                // ── List ─────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty(sw, sh)
                      : RefreshIndicator(
                    color: _kBlue,
                    backgroundColor: Colors.white,
                    onRefresh: () async => ref
                        .read(productControllerProvider.notifier)
                        .fetchProducts(),
                    child: ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final p = filtered[i];
                        return _ProductCard(
                          product: p,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductDetailsScreen(
                                  productId: p.productId!),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Search Bar ────────────────────────────────────────────────────────────────
  Widget _buildSearchBar(double sw) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            autofocus: true,
            onChanged: (value) => setState(() => _searchQuery = value),
            style: TextStyle(
              fontSize: sw * 0.036,
              color: _kDark,
              fontWeight: FontWeight.w500,
            ),
            decoration: InputDecoration(
              hintText: 'Search products...',
              hintStyle: TextStyle(
                fontSize: sw * 0.034,
                color: _kMuted,
                fontWeight: FontWeight.w400,
              ),
              prefixIcon: Icon(Icons.search_rounded, color: _kMuted, size: sw * 0.05),
              filled: true,
              fillColor: Colors.white,
              contentPadding: EdgeInsets.symmetric(horizontal: sw * 0.04),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kBlue, width: 1.5),
              ),
            ),
          ),
        ),
        SizedBox(width: sw * 0.02),
        CircularIconButton(
          icon: Icons.close_rounded,
          onTap: () {
            setState(() {
              _showSearch = false;
              _searchQuery = '';
              _searchController.clear();
            });
          },
        ),
      ],
    );
  }

  // ── Brand Filter Sheet ────────────────────────────────────────────────────────
  void _showBrandFilterSheet(BuildContext context, double sw, double sh, AsyncValue<List<BrandModel>> brandState) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setModalState) {
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            builder: (_, sc) => Padding(
              padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Handle
                  Center(
                    child: Container(
                      width: 36,
                      height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),

                  // Header
                  Row(
                    children: [
                      Container(
                        width: sw * 0.1,
                        height: sw * 0.1,
                        decoration: BoxDecoration(
                          color: _kAmberBg,
                          borderRadius: BorderRadius.circular(sw * 0.025),
                          border: Border.all(color: _kAmberBorder),
                        ),
                        child: Center(
                          child: SvgPicture.asset(
                            AppIcons.brand,
                            width: sw * 0.05,
                            colorFilter: const ColorFilter.mode(_kAmber, BlendMode.srcIn),
                          ),
                        ),
                      ),
                      SizedBox(width: sw * 0.03),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Filter by Brand',
                                style: TextStyle(
                                    fontSize: sw * 0.045,
                                    fontWeight: FontWeight.w800,
                                    color: _kDark)),
                            Text(
                              '${_selectedBrands.length} selected',
                              style: TextStyle(
                                fontSize: sw * 0.03,
                                color: _kMuted,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (_selectedBrands.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            setModalState(() => _selectedBrands.clear());
                            setState(() {});
                          },
                          child: Text('Clear All',
                              style: TextStyle(
                                  fontSize: sw * 0.032,
                                  fontWeight: FontWeight.w700,
                                  color: _kBlue)),
                        ),
                    ],
                  ),

                  SizedBox(height: sw * 0.04),
                  const Divider(height: 1, color: _kBorder),
                  SizedBox(height: sw * 0.03),

                  // Brand List
                  Expanded(
                    child: brandState.when(
                      data: (brands) {
                        if (brands.isEmpty) {
                          return Center(
                            child: Text('No brands available',
                                style: TextStyle(fontSize: sw * 0.034, color: _kMuted)),
                          );
                        }

                        return ListView.builder(
                          controller: sc,
                          itemCount: brands.length,
                          itemBuilder: (_, i) {
                            final brand = brands[i];
                            final isSelected = _selectedBrands.contains(brand.brandName);

                            return GestureDetector(
                              onTap: () {
                                setModalState(() {
                                  if (isSelected) {
                                    _selectedBrands.remove(brand.brandName);
                                  } else {
                                    _selectedBrands.add(brand.brandName);
                                  }
                                });
                                setState(() {});
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: EdgeInsets.only(bottom: sw * 0.02),
                                padding: EdgeInsets.symmetric(
                                    horizontal: sw * 0.035, vertical: sw * 0.03),
                                decoration: BoxDecoration(
                                  color: isSelected ? _kAmberBg : _kBg,
                                  borderRadius: BorderRadius.circular(sw * 0.028),
                                  border: Border.all(
                                    color: isSelected ? _kAmberBorder : _kBorder,
                                    width: 1.5,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: sw * 0.045,
                                      height: sw * 0.045,
                                      decoration: BoxDecoration(
                                        color: isSelected ? _kAmber : Colors.white,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: isSelected ? _kAmber : _kBorder,
                                          width: 2,
                                        ),
                                      ),
                                      child: isSelected
                                          ? Icon(Icons.check_rounded,
                                          size: sw * 0.03, color: Colors.white)
                                          : null,
                                    ),
                                    SizedBox(width: sw * 0.03),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            brand.brandName,
                                            style: TextStyle(
                                              fontSize: sw * 0.036,
                                              fontWeight: isSelected
                                                  ? FontWeight.w700
                                                  : FontWeight.w600,
                                              color: isSelected ? _kAmber : _kDark,
                                            ),
                                          ),
                                          if (brand.brandModels.isNotEmpty) ...[
                                            SizedBox(height: sw * 0.005),
                                            Text(
                                              '${brand.brandModels.length} model${brand.brandModels.length > 1 ? 's' : ''}',
                                              style: TextStyle(
                                                fontSize: sw * 0.028,
                                                color: _kMuted,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                      loading: () => const Center(child: CircularProgressIndicator(color: _kAmber)),
                      error: (_, __) => Center(
                        child: Text('Failed to load brands',
                            style: TextStyle(fontSize: sw * 0.034, color: _kRed)),
                      ),
                    ),
                  ),

                  SizedBox(height: sw * 0.03),

                  // Apply Button
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(vertical: sh * 0.018),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(sw * 0.035),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Apply Filters',
                        style: TextStyle(
                            fontSize: sw * 0.04, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(double sw, double sh) {
    String message = 'No products found';
    String subtitle = 'Try adjusting your filters or search';

    if (_searchQuery.isNotEmpty) {
      message = 'No results for "$_searchQuery"';
    } else if (_selectedBrands.isNotEmpty) {
      message = 'No products from selected brands';
    } else if (_statusFilter != 'All') {
      message = 'No $_statusFilter products';
      subtitle = 'Try a different filter or add a new product';
    }

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
              border: Border.all(color: _kBorder),
            ),
            child: Icon(Icons.inventory_2_outlined, size: sw * 0.09, color: _kMuted),
          ),
          SizedBox(height: sh * 0.02),
          Text(
            message,
            style: TextStyle(
                fontSize: sw * 0.038, fontWeight: FontWeight.w600, color: _kMid),
          ),
          SizedBox(height: sh * 0.008),
          Text(
            subtitle,
            style: TextStyle(fontSize: sw * 0.032, color: _kMuted),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildError(BuildContext context, double sw, double sh) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('Products',
                      style: TextStyle(
                          fontSize: sw * 0.042,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                  const Spacer(),
                  SizedBox(width: sw * 0.095),
                ],
              ),
            ),
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
                        border: Border.all(color: _kBorder),
                      ),
                      child: Icon(Icons.wifi_off_rounded, size: sw * 0.09, color: _kMuted),
                    ),
                    SizedBox(height: sh * 0.02),
                    Text('No Internet Connection',
                        style: TextStyle(
                            fontSize: sw * 0.04,
                            fontWeight: FontWeight.w600,
                            color: _kMid)),
                    SizedBox(height: sh * 0.025),
                    ElevatedButton(
                      onPressed: () =>
                          ref.read(productControllerProvider.notifier).fetchProducts(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kBlue,
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

// ─── Product Card ─────────────────────────────────────────────────────────────
class _ProductCard extends StatelessWidget {
  final dynamic product;
  final VoidCallback onTap;

  const _ProductCard({required this.product, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final isActive = product.status?.toLowerCase() == 'active';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: sw * 0.028),
        decoration: BoxDecoration(
          color: _kCard,
          borderRadius: BorderRadius.circular(sw * 0.04),
          border: Border.all(color: _kBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(sw * 0.04),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Top row: name + status ────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      product.productName ?? 'Unnamed Product',
                      style: TextStyle(
                        fontSize: sw * 0.038,
                        fontWeight: FontWeight.w700,
                        color: _kDark,
                        letterSpacing: -0.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  SizedBox(width: sw * 0.02),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.025, vertical: sw * 0.008),
                    decoration: BoxDecoration(
                      color: isActive ? _kGreenBg : _kRedBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: isActive ? _kGreenBorder : _kRedBorder),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: sw * 0.016,
                          height: sw * 0.016,
                          decoration: BoxDecoration(
                            color: isActive ? _kGreen : _kRed,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: sw * 0.012),
                        Text(
                          isActive ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: sw * 0.026,
                            fontWeight: FontWeight.w700,
                            color: isActive ? _kGreen : _kRed,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              SizedBox(height: sw * 0.025),

              // ── Meta rows ─────────────────────────
              _MetaRow(
                sw: sw,
                iconPath: AppIcons.brand,
                iconColor: AppTheme.accentRed,
                value: product.brand ?? 'No brand',
              ),
              SizedBox(height: sw * 0.012),
              _MetaRow(
                sw: sw,
                iconPath: AppIcons.model,
                iconColor: AppTheme.accentYellow,
                value: product.model ?? 'No model',
              ),
              SizedBox(height: sw * 0.012),
              _MetaRow(
                sw: sw,
                iconPath: AppIcons.type,
                iconColor: AppTheme.accentBlue,
                value: product.productType ?? 'No type',
              ),
              SizedBox(height: sw * 0.025),

              // ── Stock row ─────────────────────────
              RoleGuard(
                feature: AppFeature.viewStock,
                child: Container(
                  padding: EdgeInsets.symmetric(vertical: sw * 0.025),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(sw * 0.025),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StockCell(
                        sw: sw,
                        label: 'Packed',
                        value: product.packedStock?.toString() ?? '0',
                        iconPath: AppIcons.box,
                        color: AppTheme.accentGreen,
                      ),
                      Container(width: 1, height: sw * 0.1, color: _kBorder),
                      _StockCell(
                        sw: sw,
                        label: 'Unpacked',
                        value: product.unpackedStock?.toString() ?? '0',
                        iconPath: AppIcons.box,
                        color: AppTheme.accentRed,
                      ),
                      Container(width: 1, height: sw * 0.1, color: _kBorder),
                      _StockCell(
                        sw: sw,
                        label: 'Total',
                        value: product.availableStock?.toString() ?? '0',
                        iconPath: AppIcons.product,
                        color: AppTheme.accentBlue,
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: sw * 0.025),

              // ── Price + chevron ───────────────────
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  RoleGuard(
                    feature: AppFeature.viewPrice,
                    child: Text('Price',
                        style: TextStyle(
                            fontSize: sw * 0.03,
                            color: _kMuted,
                            fontWeight: FontWeight.w500)),
                  ),
                  Row(
                    children: [
                      RoleGuard(
                        feature: AppFeature.viewPrice,
                        child: Text(
                          '₹${product.price ?? '0'}',
                          style: TextStyle(
                            fontSize: sw * 0.042,
                            fontWeight: FontWeight.w800,
                            color: _kBlue,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                      SizedBox(width: sw * 0.02),
                      Container(
                        width: sw * 0.07,
                        height: sw * 0.07,
                        decoration: BoxDecoration(
                          color: _kBg,
                          shape: BoxShape.circle,
                          border: Border.all(color: _kBorder),
                        ),
                        child: Icon(Icons.chevron_right_rounded,
                            size: sw * 0.042, color: _kMuted),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Meta Row ─────────────────────────────────────────────────────────────────
class _MetaRow extends StatelessWidget {
  final double sw;
  final String iconPath;
  final Color iconColor;
  final String value;

  const _MetaRow({
    required this.sw,
    required this.iconPath,
    required this.iconColor,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        SvgPicture.asset(
          iconPath,
          width: sw * 0.038,
          colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
        ),
        SizedBox(width: sw * 0.02),
        Text(
          value,
          style: TextStyle(
              fontSize: sw * 0.032, color: _kMid, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }
}

// ─── Stock Cell ───────────────────────────────────────────────────────────────
class _StockCell extends StatelessWidget {
  final double sw;
  final String label;
  final String value;
  final String iconPath;
  final Color color;

  const _StockCell({
    required this.sw,
    required this.label,
    required this.value,
    required this.iconPath,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SvgPicture.asset(
          iconPath,
          width: sw * 0.06,
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
        ),
        SizedBox(height: sw * 0.01),
        Text(value,
            style: TextStyle(
                fontSize: sw * 0.038, fontWeight: FontWeight.w800, color: _kDark)),
        Text(label,
            style: TextStyle(
                fontSize: sw * 0.026, color: _kMuted, fontWeight: FontWeight.w500)),
      ],
    );
  }
}