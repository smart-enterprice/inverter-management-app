import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/model/user_model.dart';
import '../../../../core/const/district.dart';
import '../../../../core/const/icons.dart';
import '../../../../core/const/roll_converter.dart';
import '../../../../model/brand_model.dart';
import '../../../../model/dealer_discount_model.dart';
import '../../../../screen/loadingScreen.dart';
import '../../../../widgets/circle_button.dart';
import '../../../brand/controller/brand_controller.dart';
import '../../../discount/controller/discount_controller.dart';
import '../../../discount/screen/discount_create.dart' hide dealerBrandsProvider;
import '../../../order/screen/dealer_orders_view.dart';
import '../../controller/signUp_controller.dart';

final dealerProvider =
FutureProvider.family<UserModel, String>((ref, dealerId) async {
  return ref.read(signupControllerProvider.notifier).getEmployeeById(dealerId);
});

final dealerBrandsProvider =
FutureProvider.family<List<BrandModel>, String>((ref, dealerId) async {
  return ref
      .read(brandControllerProvider.notifier)
      .getBrandsByDealer(dealerId);
});

// ─────────────────────────────────────────────
//  Colour helpers
// ─────────────────────────────────────────────
const _kBlue = Color(0xFF1B4FD8);
const _kBlueBg = Color(0xFFEEF2FF);
const _kBlueBorder = Color(0xFFC7D4FF);

const _kGreen = Color(0xFF0A8A5C);
const _kGreenBg = Color(0xFFEDFAF4);
const _kGreenBorder = Color(0xFF9FE0C5);

const _kRed = Color(0xFFDC2626);
const _kRedBg = Color(0xFFFEF2F2);
const _kRedBorder = Color(0xFFFECACA);

const _kPurple = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF3EEFF);
const _kPurpleBorder = Color(0xFFC4A8FF);

const _kAmber = Color(0xFFB45309);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFCD28A);

const _kBg = Color(0xFFF2F4F8);
const _kCard = Colors.white;
const _kBorder = Color(0xFFE5E7EB);
const _kDark = Color(0xFF111827);
const _kMuted = Color(0xFF9CA3AF);

// ─────────────────────────────────────────────
//  Main Widget
// ─────────────────────────────────────────────
class DealerView extends ConsumerStatefulWidget {
  final String dealerId;
  const DealerView({super.key, required this.dealerId});

  @override
  ConsumerState<DealerView> createState() => _DealerViewState();
}

class _DealerViewState extends ConsumerState<DealerView>
    with SingleTickerProviderStateMixin {
  bool _isEditingDiscounts = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnimation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeOut);
    _animationController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref
          .read(dealerDiscountControllerProvider.notifier)
          .getDealerDiscounts(widget.dealerId);
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  // ── Chip colour by index ──────────────────
  static const _chipSets = [
    (_kBlue, _kBlueBg, _kBlueBorder),
    (_kGreen, _kGreenBg, _kGreenBorder),
    (_kPurple, _kPurpleBg, _kPurpleBorder),
    (_kAmber, _kAmberBg, _kAmberBorder),
  ];

  (Color, Color, Color) _chipColors(int i) => _chipSets[i % _chipSets.length];

  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final dealerAsync = ref.watch(dealerProvider(widget.dealerId));
    final dealerDiscountsAsync = ref.watch(dealerDiscountControllerProvider);
    final brandAsync = ref.watch(loadBrandsControllerProvider);

    return dealerAsync.when(
      loading: () => const Scaffold(
          backgroundColor: _kBg, body: Center(child: GlobalLoader())),
      error: (e, _) =>
          _buildErrorState(context, e, brandAsync, sw, sh),
      data: (dealer) => FadeTransition(
        opacity: _fadeAnimation,
        child: Scaffold(
          backgroundColor: _kBg,
          body: SafeArea(
            child: RefreshIndicator(
              color: _kBlue,
              onRefresh: () async {
                ref.invalidate(dealerProvider(widget.dealerId));
              },
              child: CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        // ── Top Nav ──────────────────────────
                        _TopNav(
                          dealer: dealer,
                          brandAsync: brandAsync,
                          dealerId: widget.dealerId,
                          onBack: () => Navigator.pop(context),
                          onHistory: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DealerOrdersScreen(
                                dealerId: widget.dealerId,
                                dealerName: dealer.employeeName,
                              ),
                            ),
                          ),
                          onDiscount: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => DealerDiscountCreatePage(
                                dealerId: widget.dealerId,
                              ),
                            ),
                          ),
                        ),

                        // ── Profile Card ─────────────────────
                        _ProfileCard(
                          dealer: dealer,
                          onEditPhoto: () =>
                              _updateProfilePhoto(context, ref, dealer),
                        ),

                        SizedBox(height: sh * 0.005),

                        // ── Info Sections ────────────────────
                        Padding(
                          padding:
                          EdgeInsets.symmetric(horizontal: sw * 0.038),
                          child: Column(
                            children: [
                              _InfoSection(
                                icon: Icons.person_outline_rounded,
                                title: 'Personal Info',
                                onEdit: () =>
                                    _showEditPersonalInfoDialog(context, dealer),
                                rows: [
                                  ('Name',
                                  dealer.employeeName
                                      .replaceAll('_', ' ') ??
                                      'N/A'),
                                  ('Email',
                                  dealer.employeeEmail ?? 'N/A'),
                                  ('Phone',
                                  dealer.employeePhone ?? 'N/A'),
                                ],
                              ),
                              SizedBox(height: sh * 0.012),
                              _InfoSection(
                                icon: Icons.location_on_outlined,
                                title: 'Address',
                                onEdit: () =>
                                    _showEditAddressDialog(context, dealer),
                                rows: [
                                  ('Street', dealer.address ?? 'N/A'),
                                  ('District', dealer.district ?? 'N/A'),
                                  ('Town', dealer.town ?? 'N/A'),
                                ],
                              ),
                              SizedBox(height: sh * 0.012),
                              _buildBusinessSection(context, dealer, sw, sh),
                              SizedBox(height: sh * 0.012),
                              RoleGuard(
                                feature: AppFeature.discountView,
                                child: _buildDiscountsSection(
                                    context, dealerDiscountsAsync, sw, sh),
                              ),
                              SizedBox(height: sh * 0.06),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Business Section ────────────────────────
  Widget _buildBusinessSection(
      BuildContext context, UserModel dealer, double sw, double sh) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(
              children: [
                _SectionIconBox(icon: Icons.business_center_outlined),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Text('Business',
                      style: TextStyle(
                          fontSize: sw * 0.035,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                ),
                RoleGuard(
                  feature: AppFeature.editDealer,
                  child: _EditPill(
                      onTap: () =>
                          _showEditBusinessDialog(context, ref, dealer)),
                ),
              ],
            ),
          ),
          _divider(),

          // shop row
          _InfoRow(label: 'Shop', value: dealer.shopName ?? 'N/A'),
          _divider(),

          // brands
          Padding(
            padding: EdgeInsets.fromLTRB(
                sw * 0.04, sw * 0.03, sw * 0.04, sw * 0.035),
            child: ref.watch(dealerBrandsProvider(widget.dealerId)).when(
              data: (brands) {
                if (brands.isEmpty) {
                  return Text('No brands assigned',
                      style: TextStyle(
                          fontSize: sw * 0.033, color: _kMuted));
                }
                return Wrap(
                  spacing: sw * 0.02,
                  runSpacing: sw * 0.02,
                  children: brands.asMap().entries.map((e) {
                    final c = _chipColors(e.key);
                    return _BrandChip(
                        label: e.value.brandName,
                        fg: c.$1,
                        bg: c.$2,
                        border: c.$3);
                  }).toList(),
                );
              },
              loading: () => const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kBlue)),
              error: (_, __) => Text('Error loading brands',
                  style:
                  TextStyle(fontSize: sw * 0.033, color: _kRed)),
            ),
          ),
        ],
      ),
    );
  }

  // ── Discounts Section ───────────────────────
  Widget _buildDiscountsSection(
      BuildContext context,
      AsyncValue<List<DealerDiscountModel>> async,
      double sw,
      double sh) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(
              children: [
                _SectionIconBox(icon: Icons.local_offer_outlined),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Text('Discounts',
                      style: TextStyle(
                          fontSize: sw * 0.035,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                ),
                if (async.asData?.value.isNotEmpty == true)
                  RoleGuard(
                    feature: AppFeature.editDealer,
                    child: _EditPill(
                      label: _isEditingDiscounts ? 'Done' : 'Edit',
                      onTap: () =>
                          setState(() => _isEditingDiscounts = !_isEditingDiscounts),
                    ),
                  ),
              ],
            ),
          ),
          _divider(),

          async.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: _kBlue)),
            ),
            error: (_, __) => Padding(
              padding: EdgeInsets.all(sw * 0.04),
              child: _ErrorBanner(message: 'Error loading discounts'),
            ),
            data: (discounts) {
              if (discounts.isEmpty) {
                return Padding(
                  padding: EdgeInsets.all(sw * 0.05),
                  child: Center(
                    child: Text('No discounts yet',
                        style: TextStyle(
                            fontSize: sw * 0.034, color: _kMuted)),
                  ),
                );
              }
              return Padding(
                padding: EdgeInsets.fromLTRB(
                    sw * 0.035, sw * 0.03, sw * 0.035, sw * 0.035),
                child: Column(
                  children: discounts.map((d) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: sw * 0.025),
                      child: _DiscountCard(
                        discount: d,
                        showEditBtn: _isEditingDiscounts,
                        onEdit: () => _showUpdateDialog(context, d),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────
  //  Dialogs
  // ─────────────────────────────────────────

  void _showEditPersonalInfoDialog(BuildContext context, UserModel dealer) {
    final nameController =
    TextEditingController(text: dealer.employeeName);
    final emailController =
    TextEditingController(text: dealer.employeeEmail);
    final phoneController =
    TextEditingController(text: dealer.employeePhone);
    final formKey = GlobalKey<FormState>();

    _showBottomSheet(
      context: context,
      title: 'Edit Personal Info',
      subtitle: dealer.employeeName ?? '',
      child: Form(
        key: formKey,
        child: Column(
          children: [
            _SheetField(
                controller: nameController,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null),
            SizedBox(height: Screen.h(context) * 0.015),
            _SheetField(
                controller: emailController,
                label: 'Email',
                icon: Icons.email_outlined,
                keyboardType: TextInputType.emailAddress,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (!v.contains('@')) return 'Invalid email';
                  return null;
                }),
            SizedBox(height: Screen.h(context) * 0.015),
            _SheetField(
                controller: phoneController,
                label: 'Phone',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null),
            SizedBox(height: Screen.h(context) * 0.025),
            _SheetActions(
              onCancel: () => Navigator.pop(context),
              onSave: () {
                if (formKey.currentState!.validate()) {
                  _updateDealerInfo(dealer,
                      name: nameController.text.trim(),
                      email: emailController.text.trim(),
                      phone: phoneController.text.trim());
                  Navigator.pop(context);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditAddressDialog(BuildContext context, UserModel dealer) {
    final addressController =
    TextEditingController(text: dealer.address);
    final townController = TextEditingController(text: dealer.town);
    final formKey = GlobalKey<FormState>();
    String? selectedDistrict;

    if (dealer.district != null && dealer.district!.isNotEmpty) {
      final n = dealer.district!.trim().toLowerCase();
      selectedDistrict = keralaDistricts.firstWhere(
              (d) => d.toLowerCase() == n,
          orElse: () => dealer.district!);
    }

    _showBottomSheet(
      context: context,
      title: 'Edit Address',
      subtitle: dealer.shopName ?? '',
      isScrollable: true,
      child: StatefulBuilder(
        builder: (ctx, setS) => Form(
          key: formKey,
          child: Column(
            children: [
              _SheetField(
                  controller: addressController,
                  label: 'Street Address',
                  icon: Icons.home_outlined,
                  maxLines: 2,
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null),
              SizedBox(height: Screen.h(context) * 0.015),
              // District dropdown
              DropdownButtonFormField<String>(
                value: keralaDistricts.contains(selectedDistrict)
                    ? selectedDistrict
                    : null,
                decoration: _sheetInputDecoration(
                    'District', Icons.map_outlined, context),
                items: keralaDistricts
                    .map((d) =>
                    DropdownMenuItem(value: d, child: Text(d)))
                    .toList(),
                onChanged: (v) => setS(() => selectedDistrict = v),
                validator: (v) =>
                v == null || v.isEmpty ? 'Required' : null,
              ),
              SizedBox(height: Screen.h(context) * 0.015),
              _SheetField(
                  controller: townController,
                  label: 'Town',
                  icon: Icons.location_city_outlined,
                  validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Required' : null),
              SizedBox(height: Screen.h(context) * 0.025),
              _SheetActions(
                onCancel: () => Navigator.pop(context),
                onSave: () {
                  if (formKey.currentState!.validate()) {
                    _updateDealerInfo(dealer,
                        address: addressController.text.trim(),
                        district: selectedDistrict!,
                        town: townController.text.trim());
                    Navigator.pop(context);
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showEditBusinessDialog(
      BuildContext context, WidgetRef ref, UserModel dealer) async
  {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    final allBrandsAsync = ref.read(activeBrandControllerProvider);
    final List<BrandModel> allBrands =
    allBrandsAsync.maybeWhen(data: (d) => d, orElse: () => []);

    final List<BrandModel> currentDealerBrands = await ref
        .read(brandControllerProvider.notifier)
        .getBrandsByDealer(widget.dealerId);

    if (!context.mounted) return;

    final Set<String> currentBrandNames =
    currentDealerBrands.map((b) => b.brandName).toSet();
    final shopNameController =
    TextEditingController(text: dealer.shopName ?? '');
    final Set<BrandModel> brandsToRemove = {};
    final Set<BrandModel> brandsToAdd = {};

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) {
          final available = allBrands
              .where((b) => !currentBrandNames.contains(b.brandName))
              .toList();

          return DraggableScrollableSheet(
            initialChildSize: 0.75,
            maxChildSize: 0.92,
            minChildSize: 0.4,
            builder: (_, scrollController) => Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius:
                BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: Column(
                children: [
                  // handle + title
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                        sw * 0.05, sw * 0.04, sw * 0.05, 0),
                    child: Column(
                      children: [
                        Container(
                          width: 36,
                          height: 4,
                          margin: const EdgeInsets.only(bottom: 18),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                CrossAxisAlignment.start,
                                children: [
                                  Text('Edit Business Info',
                                      style: TextStyle(
                                          fontSize: sw * 0.045,
                                          fontWeight: FontWeight.w800,
                                          color: _kDark)),
                                  SizedBox(height: 2),
                                  Text(
                                      dealer.shopName ??
                                          ' · ${dealer.employeeId ?? ''}',
                                      style: TextStyle(
                                          fontSize: sw * 0.032,
                                          color: _kMuted,
                                          fontWeight:
                                          FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: scrollController,
                      padding: EdgeInsets.all(sw * 0.05),
                      child: Column(
                        crossAxisAlignment:
                        CrossAxisAlignment.start,
                        children: [
                          // shop name field
                          _SheetFieldLabel('Shop Name'),
                          SizedBox(height: 6),
                          TextField(
                            controller: shopNameController,
                            decoration: _sheetInputDecoration(
                                'Shop name',
                                Icons.storefront_outlined,
                                ctx),
                          ),
                          SizedBox(height: sh * 0.025),

                          // current brands
                          if (currentDealerBrands.isNotEmpty) ...[
                            _SheetFieldLabel(
                                'Current Brands — tap to remove'),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children:
                              currentDealerBrands.map((brand) {
                                final isMarked =
                                brandsToRemove.contains(brand);
                                return GestureDetector(
                                  onTap: () => setS(() => isMarked
                                      ? brandsToRemove.remove(brand)
                                      : brandsToRemove.add(brand)),
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 200),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isMarked
                                          ? _kRedBg
                                          : _kGreenBg,
                                      borderRadius:
                                      BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isMarked
                                            ? _kRedBorder
                                            : _kGreenBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isMarked
                                              ? Icons
                                              .remove_circle_outline
                                              : Icons
                                              .check_circle_outline,
                                          size: 14,
                                          color: isMarked
                                              ? _kRed
                                              : _kGreen,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          brand.brandName,
                                          style: TextStyle(
                                            fontSize: sw * 0.033,
                                            fontWeight:
                                            FontWeight.w600,
                                            color: isMarked
                                                ? _kRed
                                                : _kGreen,
                                            decoration: isMarked
                                                ? TextDecoration
                                                .lineThrough
                                                : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (brandsToRemove.isNotEmpty) ...[
                              SizedBox(height: 8),
                              _SummaryBanner(
                                  message:
                                  '${brandsToRemove.length} brand(s) will be removed',
                                  color: _kRed,
                                  bg: _kRedBg,
                                  borderColor: _kRedBorder),
                            ],
                            SizedBox(height: sh * 0.025),
                            Divider(color: _kBorder),
                            SizedBox(height: sh * 0.015),
                          ],

                          // add brands
                          if (available.isNotEmpty) ...[
                            _SheetFieldLabel('Add Brands'),
                            SizedBox(height: 8),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: available.map((brand) {
                                final isSel =
                                brandsToAdd.contains(brand);
                                return GestureDetector(
                                  onTap: () => setS(() => isSel
                                      ? brandsToAdd.remove(brand)
                                      : brandsToAdd.add(brand)),
                                  child: AnimatedContainer(
                                    duration: const Duration(
                                        milliseconds: 200),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 7),
                                    decoration: BoxDecoration(
                                      color: isSel
                                          ? _kBlueBg
                                          : _kBg,
                                      borderRadius:
                                      BorderRadius.circular(20),
                                      border: Border.all(
                                        color: isSel
                                            ? _kBlueBorder
                                            : _kBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isSel
                                              ? Icons.check_circle
                                              : Icons
                                              .add_circle_outline,
                                          size: 14,
                                          color: isSel
                                              ? _kBlue
                                              : _kMuted,
                                        ),
                                        SizedBox(width: 5),
                                        Text(
                                          brand.brandName,
                                          style: TextStyle(
                                            fontSize: sw * 0.033,
                                            fontWeight:
                                            FontWeight.w600,
                                            color: isSel
                                                ? _kBlue
                                                : _kMuted,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (brandsToAdd.isNotEmpty) ...[
                              SizedBox(height: 8),
                              _SummaryBanner(
                                  message:
                                  '${brandsToAdd.length} brand(s) will be added',
                                  color: _kBlue,
                                  bg: _kBlueBg,
                                  borderColor: _kBlueBorder),
                            ],
                          ],

                          SizedBox(height: sh * 0.03),
                          _SheetActions(
                            onCancel: () {
                              shopNameController.dispose();
                              Navigator.pop(ctx);
                            },
                            onSave: () async {
                              Navigator.pop(ctx);
                              await _updateDealerBusiness(
                                dealer,
                                shopName: shopNameController.text
                                    .trim(),
                                addBrands: brandsToAdd
                                    .map((b) => b.brandName)
                                    .toList(),
                                removeBrands: brandsToRemove
                                    .map((b) => b.brandName)
                                    .toList(),
                              );
                              shopNameController.dispose();
                            },
                          ),
                        ],
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

  void _showUpdateDialog(BuildContext context, DealerDiscountModel discount) {
    bool isPercentage = discount.isPercentage;
    final valueController =
    TextEditingController(text: discount.discountValue.toString());
    final descController =
    TextEditingController(text: discount.description);

    _showBottomSheet(
      context: context,
      title: 'Update Discount',
      subtitle:
      '${discount.brandName} · ${discount.modelName}',
      isScrollable: true,
      child: StatefulBuilder(
        builder: (ctx, setS) => Column(
          children: [
            _SheetField(
                controller: valueController,
                label: 'Discount Value',
                icon: Icons.percent,
                keyboardType: TextInputType.number),
            SizedBox(height: Screen.h(context) * 0.015),
            _SheetField(
                controller: descController,
                label: 'Description',
                icon: Icons.description_outlined),
            SizedBox(height: Screen.h(context) * 0.015),
            // toggle
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: Screen.w(context) * 0.04,
                  vertical: Screen.w(context) * 0.03),
              decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _kBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Is Percentage?',
                      style: TextStyle(
                          fontSize: Screen.w(context) * 0.036,
                          fontWeight: FontWeight.w600,
                          color: _kDark)),
                  Switch(
                      value: isPercentage,
                      onChanged: (v) => setS(() => isPercentage = v),
                      activeColor: _kBlue),
                ],
              ),
            ),
            SizedBox(height: Screen.h(context) * 0.025),
            _SheetActions(
              onCancel: () => Navigator.pop(context),
              onSave: () async {
                final updated = discount.copyWith(
                    discountValue:
                    num.tryParse(valueController.text),
                    description: descController.text,
                    isPercentage: isPercentage,
                    productId: discount.productId);
                await ref
                    .read(dealerDiscountControllerProvider.notifier)
                    .updateDealerDiscount(updated);
                if (!context.mounted) return;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── Generic bottom sheet helper ────────────
  void _showBottomSheet({
    required BuildContext context,
    required String title,
    required String subtitle,
    required Widget child,
    bool isScrollable = false,
  })
  {
    final sw = Screen.w(context);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(24)),
          ),
          padding: EdgeInsets.fromLTRB(
              sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    margin: const EdgeInsets.only(bottom: 18),
                    decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                Text(title,
                    style: TextStyle(
                        fontSize: sw * 0.045,
                        fontWeight: FontWeight.w800,
                        color: _kDark)),
                SizedBox(height: 2),
                Text(subtitle,
                    style: TextStyle(
                        fontSize: sw * 0.032,
                        color: _kMuted,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: sw * 0.05),
                child,
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Update helpers ──────────────────────────
  Future<void> _updateDealerBusiness(
      UserModel dealer, {
        required String shopName,
        required List<String> addBrands,
        required List<String> removeBrands,
      }) async
  {
    try {
      final result =
      await ref.read(signupControllerProvider.notifier).updateUser(
        oldUser: dealer,
        shopName: shopName.isEmpty ? null : shopName,
        addBrands: addBrands.isEmpty ? null : addBrands,
        removeBrands:
        removeBrands.isEmpty ? null : removeBrands,
      );
      if (!mounted) return;
      if (result == null) {
        ref.invalidate(dealerProvider(widget.dealerId));
        ref.invalidate(dealerBrandsProvider(widget.dealerId));
        _showSnack('Business info updated', Colors.green);
      } else {
        _showSnack('Update failed: $result', Colors.red);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    }
  }

  void _updateDealerInfo(
      UserModel dealer, {
        String? name,
        String? email,
        String? phone,
        String? address,
        String? district,
        String? town,
        String? shopName,
        List<String>? brand,
      }) async
  {
    try {
      final result =
      await ref.read(signupControllerProvider.notifier).updateUser(
        oldUser: dealer,
        name: name,
        email: email,
        phone: phone,
        address: address,
        district: district,
        town: town,
        shopName: shopName,
        brand: brand,
      );
      if (!mounted) return;
      if (result == null) {
        ref.invalidate(dealerProvider(widget.dealerId));
        _showSnack('Updated successfully', Colors.green);
      } else {
        _showSnack('Failed: $result', Colors.red);
      }
    } catch (e) {
      if (mounted) _showSnack('Error: $e', Colors.red);
    }
  }

  Future<void> _updateProfilePhoto(
      BuildContext context, WidgetRef ref, UserModel dealer) async
  {
    try {
      final source = await showModalBottomSheet<ImageSource>(
        context: context,
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
            borderRadius:
            BorderRadius.vertical(top: Radius.circular(20))),
        builder: (_) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                  width: 36,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                      color: _kBorder,
                      borderRadius: BorderRadius.circular(2))),
              ListTile(
                leading: const Icon(Icons.camera_alt_outlined,
                    color: _kBlue),
                title: const Text('Camera',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () =>
                    Navigator.pop(context, ImageSource.camera),
              ),
              ListTile(
                leading: const Icon(Icons.photo_library_outlined,
                    color: _kBlue),
                title: const Text('Gallery',
                    style: TextStyle(fontWeight: FontWeight.w600)),
                onTap: () =>
                    Navigator.pop(context, ImageSource.gallery),
              ),
            ],
          ),
        ),
      );
      if (source == null) return;

      final picker = ImagePicker();
      final file = await picker.pickImage(
          source: source, imageQuality: 70, maxWidth: 1024);
      if (file == null) return;

      if (context.mounted) {
        showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => const Center(
                child: CircularProgressIndicator(color: _kBlue)));
      }

      final error =
      await ref.read(signupControllerProvider.notifier).updateUser(
        oldUser: dealer,
        photoFile: File(file.path),
      );

      if (context.mounted) {
        Navigator.pop(context);
        _showSnack(
          error != null ? 'Failed: $error' : 'Photo updated',
          error != null ? Colors.red : Colors.green,
        );
      }
    } catch (e) {
      if (context.mounted) {
        Navigator.pop(context);
        _showSnack('Error: $e', Colors.red);
      }
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  Widget _buildErrorState(BuildContext context, Object error,
      AsyncValue<List<BrandModel>> brandAsync, double sw, double sh) {
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            _TopNav(
                dealer: null,
                brandAsync: brandAsync,
                dealerId: widget.dealerId,
                onBack: () => Navigator.pop(context),
                onHistory: () {},
                onDiscount: () {}),
            Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.wifi_off_rounded,
                        size: 48, color: _kMuted),
                    SizedBox(height: sh * 0.015),
                    Text('No Internet Connection',
                        style: TextStyle(
                            fontSize: sw * 0.04,
                            fontWeight: FontWeight.w600,
                            color: _kDark)),
                    SizedBox(height: sh * 0.025),
                    ElevatedButton(
                      onPressed: () =>
                          ref.invalidate(dealerProvider(widget.dealerId)),
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

// ═══════════════════════════════════════════════
//  Sub-widgets
// ═══════════════════════════════════════════════

class _TopNav extends ConsumerWidget {
  final UserModel? dealer;
  final AsyncValue<List<BrandModel>> brandAsync;
  final String dealerId;
  final VoidCallback onBack;
  final VoidCallback onHistory;
  final VoidCallback onDiscount;

  const _TopNav({
    required this.dealer,
    required this.brandAsync,
    required this.dealerId,
    required this.onBack,
    required this.onHistory,
    required this.onDiscount,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = Screen.w(context);
    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: sw * 0.03),
      child: Row(
        children: [
          CircularIconButton(
              icon: Icons.arrow_back_ios_rounded, onTap: onBack),
          const Spacer(),
          Text('Dealer Details',
              style: TextStyle(
                  fontSize: sw * 0.042,
                  fontWeight: FontWeight.w700,
                  color: _kDark,
                  letterSpacing: -0.2)),
          const Spacer(),
          CircularIconButton(
              icon: Icons.history_rounded, onTap: onHistory),
          SizedBox(width: sw * 0.02),
          RoleGuard(
            feature: AppFeature.discountCreate,
              child: CircularIconButton(icon: Icons.percent, onTap: onDiscount)),
        ],
      ),
    );
  }
}

// ── Profile Card ────────────────────────────────
class _ProfileCard extends StatelessWidget {
  final UserModel dealer;
  final VoidCallback onEditPhoto;

  const _ProfileCard(
      {required this.dealer, required this.onEditPhoto});

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final initials = (dealer.employeeName ?? 'U')
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: sw * 0.038, vertical: sw * 0.02),
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Row(
        children: [
          // avatar
          Stack(
            children: [
              CircleAvatar(
                radius: sw * 0.075,
                backgroundColor: _kBlueBg,
                backgroundImage: (dealer.photo != null &&
                    dealer.photo!.isNotEmpty)
                    ? NetworkImage(dealer.photo!)
                    : null,
                child: (dealer.photo == null || dealer.photo!.isEmpty)
                    ? Text(initials,
                    style: TextStyle(
                        fontSize: sw * 0.055,
                        fontWeight: FontWeight.w800,
                        color: _kBlue))
                    : null,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: RoleGuard(
                    feature: AppFeature.editDealer,
                  child: GestureDetector(
                    onTap: onEditPhoto,
                    child: Container(
                      width: sw * 0.055,
                      height: sw * 0.055,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        border: Border.all(color: _kBorder),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4)
                        ],
                      ),
                      child: Icon(Icons.camera_alt_outlined,
                          size: sw * 0.03, color: _kBlue),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: sw * 0.04),
          // info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  dealer.employeeName?.replaceAll('_', ' ') ?? 'N/A',
                  style: TextStyle(
                      fontSize: sw * 0.045,
                      fontWeight: FontWeight.w800,
                      color: _kDark,
                      letterSpacing: -0.3),
                ),
                SizedBox(height: sw * 0.015),
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: sw * 0.025,
                          vertical: sw * 0.008),
                      decoration: BoxDecoration(
                        color: _kBlueBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kBlueBorder),
                      ),
                      child: Text(
                        formatRole(dealer.role ?? 'N/A'),
                        style: TextStyle(
                            fontSize: sw * 0.028,
                            fontWeight: FontWeight.w700,
                            color: _kBlue),
                      ),
                    ),
                    SizedBox(width: sw * 0.02),
                    Text(
                      dealer.employeeId ?? '',
                      style: TextStyle(
                          fontSize: sw * 0.028,
                          color: _kMuted,
                          fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Info Section Card ────────────────────────────
class _InfoSection extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onEdit;
  final List<(String, String)> rows;

  const _InfoSection({
    required this.icon,
    required this.title,
    required this.onEdit,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
        boxShadow: [
          BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 6,
              offset: const Offset(0, 2))
        ],
      ),
      child: Column(
        children: [
          // header
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(
              children: [
                _SectionIconBox(icon: icon),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: sw * 0.035,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                ),
                RoleGuard(
                    feature: AppFeature.editDealer,
                    child: _EditPill(onTap: onEdit)),
              ],
            ),
          ),
          _divider(),
          // rows
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Column(
              children: [
                _InfoRow(label: e.value.$1, value: e.value.$2),
                if (!isLast) _divider(),
              ],
            );
          }),
        ],
      ),
    );
  }
}

// ── Discount Card ────────────────────────────────
class _DiscountCard extends StatelessWidget {
  final DealerDiscountModel discount;
  final bool showEditBtn;
  final VoidCallback onEdit;

  const _DiscountCard({
    required this.discount,
    required this.showEditBtn,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    return Container(
      decoration: BoxDecoration(
        color: _kGreenBg,
        borderRadius: BorderRadius.circular(sw * 0.03),
        border: Border.all(color: _kGreenBorder),
      ),
      child: Column(
        children: [
          // top row
          Padding(
            padding: EdgeInsets.all(sw * 0.035),
            child: Row(
              children: [
                Container(
                  width: sw * 0.09,
                  height: sw * 0.09,
                  decoration: BoxDecoration(
                      color: const Color(0xFFC5F0E0),
                      borderRadius: BorderRadius.circular(sw * 0.025)),
                  child: const Icon(Icons.local_offer_outlined,
                      color: _kGreen, size: 20),
                ),
                SizedBox(width: sw * 0.03),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(discount.brandName,
                          style: TextStyle(
                              fontSize: sw * 0.035,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0A3A28))),
                      Text(discount.modelName,
                          style: TextStyle(
                              fontSize: sw * 0.029,
                              color: const Color(0xFF2D7A54),
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.03, vertical: sw * 0.012),
                  decoration: BoxDecoration(
                      color: _kGreen,
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(
                    discount.isPercentage
                        ? '${discount.discountValue}%'
                        : '₹${discount.discountValue}',
                    style: TextStyle(
                        fontSize: sw * 0.033,
                        fontWeight: FontWeight.w700,
                        color: Colors.white),
                  ),
                ),
                if (showEditBtn) ...[
                  SizedBox(width: sw * 0.02),
                  GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: EdgeInsets.all(sw * 0.018),
                      decoration: BoxDecoration(
                          color: _kBlueBg,
                          borderRadius:
                          BorderRadius.circular(sw * 0.02),
                          border: Border.all(color: _kBlueBorder)),
                      child: Icon(Icons.edit_outlined,
                          size: sw * 0.04, color: _kBlue),
                    ),
                  ),
                ],
              ],
            ),
          ),
          // product rows
          if (discount.products.isNotEmpty) ...[
            Divider(
                height: 1,
                color: _kGreenBorder,
                indent: sw * 0.035,
                endIndent: sw * 0.035),
            Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: sw * 0.035, vertical: sw * 0.025),
              child: Column(
                children: discount.products.map((p) {
                  final orig = (p.price ?? 0).toDouble();
                  final disc = discount.isPercentage
                      ? orig * (1 - discount.discountValue / 100)
                      : orig - discount.discountValue;
                  return Padding(
                    padding:
                    EdgeInsets.only(bottom: sw * 0.015),
                    child: Row(
                      children: [
                        Container(
                            width: sw * 0.015,
                            height: sw * 0.015,
                            decoration: BoxDecoration(
                                color: _kGreen,
                                shape: BoxShape.circle)),
                        SizedBox(width: sw * 0.025),
                        Expanded(
                          child: Text(
                            p.productName ?? 'Unknown',
                            style: TextStyle(
                                fontSize: sw * 0.03,
                                color: const Color(0xFF1A4A30),
                                fontWeight: FontWeight.w500),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text('₹${orig.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: sw * 0.028,
                                color: _kMuted,
                                decoration:
                                TextDecoration.lineThrough)),
                        Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.015),
                          child: Icon(Icons.arrow_forward,
                              size: sw * 0.03,
                              color: _kGreen),
                        ),
                        Text('₹${disc.toStringAsFixed(0)}',
                            style: TextStyle(
                                fontSize: sw * 0.032,
                                color: _kGreen,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Small reusable widgets ───────────────────────

class _SectionIconBox extends StatelessWidget {
  final IconData icon;
  const _SectionIconBox({required this.icon});

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    return Container(
      width: sw * 0.075,
      height: sw * 0.075,
      decoration: BoxDecoration(
          color: _kBg,
          borderRadius: BorderRadius.circular(sw * 0.022),
          border: Border.all(color: _kBorder)),
      child: Icon(icon, size: sw * 0.04, color: _kDark),
    );
  }
}

class _EditPill extends StatelessWidget {
  final VoidCallback onTap;
  final String label;
  const _EditPill({required this.onTap, this.label = 'Edit'});

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: sw * 0.03, vertical: sw * 0.01),
        decoration: BoxDecoration(
          color: _kBlueBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _kBlueBorder),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: sw * 0.03,
                fontWeight: FontWeight.w700,
                color: _kBlue)),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    return Padding(
      padding:
      EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.028),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: sw * 0.2,
            child: Text(label,
                style: TextStyle(
                    fontSize: sw * 0.03,
                    color: _kMuted,
                    fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value,
                style: TextStyle(
                    fontSize: sw * 0.034,
                    color: _kDark,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _BrandChip extends StatelessWidget {
  final String label;
  final Color fg, bg, border;
  const _BrandChip(
      {required this.label,
        required this.fg,
        required this.bg,
        required this.border});

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sw * 0.012),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: border)),
      child: Text(label,
          style: TextStyle(
              fontSize: sw * 0.03, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}

class _SheetField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLines;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.controller,
    required this.label,
    required this.icon,
    this.keyboardType,
    this.maxLines,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines ?? 1,
      validator: validator,
      decoration: _sheetInputDecoration(label, icon, context),
    );
  }
}

class _SheetFieldLabel extends StatelessWidget {
  final String text;
  const _SheetFieldLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(text.toUpperCase(),
        style: TextStyle(
            fontSize: Screen.w(context) * 0.028,
            fontWeight: FontWeight.w700,
            color: _kMuted,
            letterSpacing: 0.5));
  }
}

class _SheetActions extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onSave;
  const _SheetActions(
      {required this.onCancel, required this.onSave});

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: onCancel,
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: sh * 0.016),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              side: const BorderSide(color: _kBorder),
            ),
            child: Text('Cancel',
                style: TextStyle(
                    fontSize: sw * 0.036,
                    fontWeight: FontWeight.w700,
                    color: _kMuted)),
          ),
        ),
        SizedBox(width: sw * 0.03),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: onSave,
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: sh * 0.016),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: Text('Save Changes',
                style: TextStyle(
                    fontSize: sw * 0.036,
                    fontWeight: FontWeight.w700)),
          ),
        ),
      ],
    );
  }
}

class _SummaryBanner extends StatelessWidget {
  final String message;
  final Color color, bg, borderColor;
  const _SummaryBanner(
      {required this.message,
        required this.color,
        required this.bg,
        required this.borderColor});

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    return Container(
      padding:
      EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sw * 0.025),
      decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor)),
      child: Row(
        children: [
          Icon(Icons.info_outline, size: sw * 0.04, color: color),
          SizedBox(width: sw * 0.02),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: sw * 0.031,
                    color: color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _ErrorBanner extends StatelessWidget {
  final String message;
  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
          color: _kRedBg,
          borderRadius: BorderRadius.circular(sw * 0.03),
          border: Border.all(color: _kRedBorder)),
      child: Row(
        children: [
          Icon(Icons.error_outline, size: sw * 0.05, color: _kRed),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: Text(message,
                style: TextStyle(
                    fontSize: sw * 0.034, color: _kRed)),
          ),
        ],
      ),
    );
  }
}

// ── Shared helpers ───────────────────────────────

Widget _divider() =>
    const Divider(height: 1, thickness: 1, color: _kBorder);

InputDecoration _sheetInputDecoration(
    String label, IconData icon, BuildContext context) {
  final sw = Screen.w(context);
  return InputDecoration(
    hintText: label,
    prefixIcon: Icon(icon, color: _kMuted, size: sw * 0.05),
    filled: true,
    fillColor: _kBg,
    contentPadding:
    EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(sw * 0.03),
      borderSide: const BorderSide(color: _kBorder),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(sw * 0.03),
      borderSide: const BorderSide(color: _kBorder),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(sw * 0.03),
      borderSide: const BorderSide(color: _kBlue, width: 1.5),
    ),
  );
}