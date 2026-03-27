import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../core/media_query/media_query.dart';
import '../../../widgets/circle_button.dart';
import '../controller/brand_controller.dart';
import 'brand_create.dart';
import 'brand_details_page.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kBlue       = Color(0xFF1B4FD8);
const _kBlueBg     = Color(0xFFEEF2FF);
const _kBlueBorder = Color(0xFFC7D4FF);
const _kBg         = Color(0xFFF2F4F8);
const _kBorder     = Color(0xFFE5E7EB);
const _kDark       = Color(0xFF111827);
const _kMid        = Color(0xFF374151);
const _kMuted      = Color(0xFF9CA3AF);
const _kGreen      = Color(0xFF0A8A5C);
const _kGreenBg    = Color(0xFFEDFAF4);
const _kGreenBorder = Color(0xFF9FE0C5);
const _kRed        = Color(0xFFDC2626);
const _kRedBg      = Color(0xFFFEF2F2);
const _kRedBorder  = Color(0xFFFECACA);

class BrandsScreen extends ConsumerStatefulWidget {
  const BrandsScreen({super.key});

  @override
  ConsumerState<BrandsScreen> createState() => _BrandsScreenState();
}

class _BrandsScreenState extends ConsumerState<BrandsScreen> {
  String _selectedFilter = 'All';
  final List<String> _filters = ['All', 'Active', 'Inactive'];

  @override
  Widget build(BuildContext context) {
    final sw         = Screen.w(context);
    final sh         = Screen.h(context);
    final brandState = ref.watch(loadBrandsControllerProvider);

    return brandState.when(
      loading: () => const Scaffold(
          backgroundColor: _kBg, body: Center(child: GlobalLoader())),

      error: (e, _) => _buildError(context, sw, sh),

      data: (brands) {
        final filtered = brands.where((b) {
          if (_selectedFilter == 'Active') {
            return b.status?.toLowerCase() == 'active';
          }
          if (_selectedFilter == 'Inactive') {
            return b.status?.toLowerCase() == 'inactive';
          }
          return true;
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
                  child: Row(
                    children: [
                      CircularIconButton(
                        icon: Icons.arrow_back_ios_rounded,
                        onTap: () => Navigator.pop(context),
                      ),
                      const Spacer(),
                      Text('Brands',
                          style: TextStyle(
                              fontSize: sw * 0.042,
                              fontWeight: FontWeight.w700,
                              color: _kDark,
                              letterSpacing: -0.2)),
                      const Spacer(),
                      RoleGuard(
                        feature: AppFeature.createBrand,
                        child: CircularIconButton(
                          icon: Icons.add,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const BrandCreateScreen()),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Filter chips ──────────────────────────
                SizedBox(
                  height: sw * 0.09,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.only(left: sw * 0.04),
                    itemCount: _filters.length,
                    itemBuilder: (_, i) {
                      final f = _filters[i];
                      final isSelected = f == _selectedFilter;
                      return Padding(
                        padding: EdgeInsets.only(right: sw * 0.02),
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _selectedFilter = f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            padding: EdgeInsets.symmetric(
                                horizontal: sw * 0.04,
                                vertical: sw * 0.015),
                            decoration: BoxDecoration(
                              color: isSelected ? _kBlue : Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                color: isSelected ? _kBlue : _kBorder,
                                width: 1.5,
                              ),
                            ),
                            child: Text(f,
                                style: TextStyle(
                                    fontSize: sw * 0.03,
                                    fontWeight: FontWeight.w700,
                                    color: isSelected
                                        ? Colors.white
                                        : _kMid)),
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // ── Count pill ────────────────────────────
                Padding(
                  padding: EdgeInsets.only(
                      left: sw * 0.04,
                      right: sw * 0.04,
                      top: sw * 0.025,
                      bottom: sw * 0.015),
                  child: Row(
                    children: [
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: sw * 0.03,
                            vertical: sw * 0.01),
                        decoration: BoxDecoration(
                          color: _kBlueBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kBlueBorder),
                        ),
                        child: Text(
                          '${filtered.length} of ${brands.length} brand${brands.length != 1 ? 's' : ''}',
                          style: TextStyle(
                              fontSize: sw * 0.029,
                              fontWeight: FontWeight.w700,
                              color: _kBlue),
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Grid ─────────────────────────────────
                Expanded(
                  child: filtered.isEmpty
                      ? _buildEmpty(sw, sh)
                      : RefreshIndicator(
                    color: _kBlue,
                    backgroundColor: Colors.white,
                    onRefresh: () async {
                      await Future.delayed(
                          const Duration(seconds: 1));
                      ref.invalidate(loadBrandsControllerProvider);
                    },
                    child: GridView.builder(
                      padding: EdgeInsets.symmetric(
                          horizontal: sw * 0.038,
                          vertical: sw * 0.01),
                      itemCount: filtered.length,
                      gridDelegate:
                      SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: sw > 600 ? 3 : 2,
                        crossAxisSpacing: sw * 0.035,
                        mainAxisSpacing: sw * 0.035,
                        childAspectRatio: 1.0,
                      ),
                      itemBuilder: (_, i) {
                        final brand = filtered[i];
                        final isActive = brand.status
                            ?.toLowerCase() ==
                            'active';
                        return _BrandCard(
                          brandName: brand.brandName,
                          modelCount:
                          brand.brandModels.length,
                          isActive: isActive,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => BrandDetailsScreen(
                                  brandId: brand.brandId!),
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

  // ── Empty state ─────────────────────────────────────────────────────────────
  Widget _buildEmpty(double sw, double sh) {
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
            child: Icon(Icons.storefront_outlined,
                size: sw * 0.09, color: _kMuted),
          ),
          SizedBox(height: sh * 0.02),
          Text(
            _selectedFilter == 'All'
                ? 'No brands yet'
                : 'No $_selectedFilter brands',
            style: TextStyle(
                fontSize: sw * 0.038,
                fontWeight: FontWeight.w600,
                color: _kMid),
          ),
        ],
      ),
    );
  }

  // ── Error state ──────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, double sw, double sh) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04, vertical: sw * 0.03),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('Brands',
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
                      child: Icon(Icons.wifi_off_rounded,
                          size: sw * 0.09, color: _kMuted),
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
                          ref.invalidate(loadBrandsControllerProvider),
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

// ─── Brand Card ───────────────────────────────────────────────────────────────
class _BrandCard extends StatelessWidget {
  final String brandName;
  final int modelCount;
  final bool isActive;
  final VoidCallback onTap;

  const _BrandCard({
    required this.brandName,
    required this.modelCount,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
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
          padding: EdgeInsets.all(sw * 0.035),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Brand icon
              Container(
                width: sw * 0.12,
                height: sw * 0.12,
                decoration: BoxDecoration(
                  color: _kBlueBg,
                  borderRadius: BorderRadius.circular(sw * 0.03),
                  border: Border.all(color: _kBlueBorder),
                ),
                child: Icon(Icons.storefront_outlined,
                    size: sw * 0.06, color: _kBlue),
              ),
              SizedBox(height: sw * 0.025),

              // Brand name
              Text(
                brandName,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: sw * 0.036,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: sw * 0.015),

              // Model count
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.category_outlined,
                      size: sw * 0.032, color: _kMuted),
                  SizedBox(width: sw * 0.01),
                  Text(
                    '$modelCount model${modelCount != 1 ? 's' : ''}',
                    style: TextStyle(
                        fontSize: sw * 0.028,
                        color: _kMuted,
                        fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              SizedBox(height: sw * 0.02),

              // Status badge
              Container(
                padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.025, vertical: sw * 0.008),
                decoration: BoxDecoration(
                  color: isActive ? _kGreenBg : _kRedBg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: isActive ? _kGreenBorder : _kRedBorder),
                ),
                child: Text(
                  isActive ? 'Active' : 'Inactive',
                  style: TextStyle(
                    fontSize: sw * 0.026,
                    fontWeight: FontWeight.w700,
                    color: isActive ? _kGreen : _kRed,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}