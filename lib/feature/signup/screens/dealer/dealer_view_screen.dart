import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:inverter_management_app/feature/signup/model/user_model.dart';
import '../../../../core/const/district.dart';
import '../../../../core/const/roll_converter.dart';
import '../../../../feature/brand/model/brand_model.dart';
import '../../../../feature/discount/model/dealer_discount_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../../brand/controller/brand_controller.dart';
import '../../../discount/controller/discount_controller.dart';
import '../../../discount/screens/discount_create.dart';
import '../../../order/screens/dealer_orders_view.dart';
import '../../controller/signUp_controller.dart';

final dealerProvider = FutureProvider.family<UserModel, String>((ref, id) async {
  return ref.read(signupControllerProvider.notifier).getEmployeeById(id);
});


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
const _kPurpleBg= Color(0xFFF5F3FF);
const _kPurpleBd= Color(0xFFDDD6FE);

const _chipSets = [
  (_kP, _kPBg, _kPBd),
  (_kGreen, _kGreenBg, _kGreenBd),
  (_kPurple, _kPurpleBg, _kPurpleBd),
  (_kAmber, _kAmberBg, _kAmberBd),
];
(Color, Color, Color) _chipColor(int i) => _chipSets[i % _chipSets.length];

// ═════════════════════════════════════════════════════════════════════════════
class DealerView extends ConsumerStatefulWidget {
  final String dealerId;
  const DealerView({super.key, required this.dealerId});
  @override ConsumerState<DealerView> createState() => _DealerViewState();
}

class _DealerViewState extends ConsumerState<DealerView> {
  bool _editingDiscounts = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(dealerDiscountControllerProvider.notifier).getDealerDiscounts(widget.dealerId);
    });
    ref.read(dealerBrandsProvider(widget.dealerId).future);
  }

  void _snack(String msg, Color bg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: bg, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final dealerAsync = ref.watch(dealerProvider(widget.dealerId));
    final discountsAsync = ref.watch(dealerDiscountControllerProvider);

    return dealerAsync.when(
        loading: () => const Scaffold(backgroundColor: _kBg,
            body: Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5))),
        error: (e, _) => _errorScreen(context, sw, sh),
        data: (dealer) => Scaffold(backgroundColor: _kBg,
            body: SafeArea(child: RefreshIndicator(color: _kP, backgroundColor: _kWhite,
                onRefresh: () async => ref.invalidate(dealerProvider(widget.dealerId)),
                child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
                  SliverToBoxAdapter(child: Column(children: [
                    // ── App bar ────────────────────────────────────────────────
                    Container(color: _kWhite,
                        padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
                        child: Row(children: [
                          CircularIconButton(icon: Icons.arrow_back_ios_rounded,
                              onTap: () => Navigator.pop(context)),
                          const Spacer(),
                          Text('Dealer Details', style: TextStyle(
                              fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w700,
                              color: _kT1, letterSpacing: -0.2)),
                          const Spacer(),
                          CircularIconButton(icon: Icons.history_rounded,
                              onTap: () => Navigator.push(context, MaterialPageRoute(
                                  builder: (_) => DealerOrdersScreen(
                                      dealerId: widget.dealerId, dealerName: dealer.employeeName)))),
                          SizedBox(width: sw * 0.02),
                          RoleGuard(feature: AppFeature.discountCreate,
                              child: CircularIconButton(icon: Icons.percent,
                                  onTap: () => Navigator.push(context, MaterialPageRoute(
                                      builder: (_) => DealerDiscountCreatePage(dealerId: widget.dealerId))))),
                        ])),

                    // ── Profile card ───────────────────────────────────────────
                    _profileCard(sw, sh, dealer),
                    SizedBox(height: sh * 0.005),

                    Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                        child: Column(children: [
                          // Personal info
                          _infoSection(sw, Icons.person_outline_rounded, 'Personal Info',
                              onEdit: () => _editPersonalInfo(context, dealer),
                              rows: [
                                ('Name', dealer.employeeName.replaceAll('_', ' ')),
                                ('Email', dealer.employeeEmail ?? 'N/A'),
                                ('Phone', dealer.employeePhone ?? 'N/A'),
                              ]),
                          SizedBox(height: sh * 0.012),

                          // Address
                          _infoSection(sw, Icons.location_on_outlined, 'Address',
                              onEdit: () => _editAddress(context, dealer),
                              rows: [
                                ('Street', dealer.address ?? 'N/A'),
                                ('District', dealer.district ?? 'N/A'),
                                ('Town', dealer.town ?? 'N/A'),
                              ]),
                          SizedBox(height: sh * 0.012),

                          // Business
                          _businessSection(sw, sh, dealer),
                          SizedBox(height: sh * 0.012),

                          // Discounts
                          RoleGuard(feature: AppFeature.discountView,
                              child: _discountsSection(sw, sh, discountsAsync)),
                          SizedBox(height: sh * 0.06),
                        ])),
                  ])),
                ])))));
  }

  // ── Profile card ────────────────────────────────────────────────────────
  Widget _profileCard(double sw, double sh, UserModel d) {
    final init = (d.employeeName ?? 'U').trim().split(' ').take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '').join();
    return Container(
        margin: EdgeInsets.symmetric(horizontal: sw * 0.038, vertical: sw * 0.02),
        padding: EdgeInsets.all(sw * 0.04),
        decoration: BoxDecoration(color: _kWhite,
            borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        child: Row(children: [
          Stack(children: [
            CircleAvatar(radius: (sw * 0.075).clamp(28.0, 36.0), backgroundColor: _kPBg,
                backgroundImage: (d.photo != null && d.photo!.isNotEmpty) ? NetworkImage(d.photo!) : null,
                child: (d.photo == null || d.photo!.isEmpty)
                    ? Text(init, style: TextStyle(fontSize: (sw * 0.05).clamp(16.0, 24.0),
                    fontWeight: FontWeight.w800, color: _kP)) : null),
            Positioned(bottom: 0, right: 0,
                child: RoleGuard(feature: AppFeature.editDealer,
                    child: GestureDetector(onTap: () => _updatePhoto(context, ref, d),
                        child: Container(
                            width: (sw * 0.05).clamp(18.0, 24.0), height: (sw * 0.05).clamp(18.0, 24.0),
                            decoration: BoxDecoration(color: _kWhite, shape: BoxShape.circle,
                                border: Border.all(color: _kBd, width: 0.5)),
                            child: Icon(Icons.camera_alt_outlined, size: (sw * 0.028).clamp(9.0, 13.0), color: _kP))))),
          ]),
          SizedBox(width: sw * 0.04),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(d.employeeName.replaceAll('_', ' '), style: TextStyle(
                fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w800,
                color: _kT1, letterSpacing: -0.3)),
            SizedBox(height: sw * 0.012),
            Row(children: [
              _Pill(label: formatRole(d.role ?? 'N/A'), fg: _kP, bg: _kPBg, bd: _kPBd),
              SizedBox(width: sw * 0.02),
              Flexible(child: Text(d.employeeId ?? '', overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: (sw * 0.028).clamp(9.5, 12.5), color: _kT4))),
            ]),
          ])),
        ]));
  }

  // ── Info section ────────────────────────────────────────────────────────
  Widget _infoSection(double sw, IconData icon, String title,
      {required VoidCallback onEdit, required List<(String, String)> rows}) {
    return Container(
        decoration: BoxDecoration(color: _kWhite,
            borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        child: Column(children: [
          _sectionHeader(sw, icon, title, trailing: RoleGuard(
              feature: AppFeature.editDealer, child: _editPill(sw, onTap: onEdit))),
          Divider(height: 1, color: _kBd),
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Column(children: [
              Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.028),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    SizedBox(width: sw * 0.2, child: Text(e.value.$1, style: TextStyle(
                        fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4, fontWeight: FontWeight.w500))),
                    Expanded(child: Text(e.value.$2, style: TextStyle(
                        fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1, fontWeight: FontWeight.w600))),
                  ])),
              if (!isLast) Divider(height: 1, color: _kBd),
            ]);
          }),
        ]));
  }

  // ── Business section ────────────────────────────────────────────────────
  Widget _businessSection(double sw, double sh, UserModel d) {
    return Container(
        decoration: BoxDecoration(color: _kWhite,
            borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader(sw, Icons.business_center_outlined, 'Business',
              trailing: RoleGuard(feature: AppFeature.editDealer,
                  child: _editPill(sw, onTap: () => _editBusiness(context, ref, d)))),
          Divider(height: 1, color: _kBd),
          // Shop row
          Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.028),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: sw * 0.2, child: Text('Shop', style: TextStyle(
                    fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4, fontWeight: FontWeight.w500))),
                Expanded(child: Text(d.shopName ?? 'N/A', style: TextStyle(
                    fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT1, fontWeight: FontWeight.w600))),
              ])),
          Divider(height: 1, color: _kBd),
          // Brands
          Padding(padding: EdgeInsets.fromLTRB(sw * 0.04, sw * 0.03, sw * 0.04, sw * 0.035),
              child: ref.watch(dealerBrandsProvider(widget.dealerId)).when(
                  data: (brands) {
                    if (brands.isEmpty) {
                      return Text('No brands assigned', style: TextStyle(
                        fontSize: (sw * 0.033).clamp(11.0, 14.0), color: _kT4));
                    }
                    return Wrap(spacing: sw * 0.02, runSpacing: sw * 0.02,
                        children: brands.asMap().entries.map((e) {
                          final c = _chipColor(e.key);
                          return _Pill(label: e.value.brandName, fg: c.$1, bg: c.$2, bd: c.$3);
                        }).toList());
                  },
                  loading: () => const SizedBox(height: 24, width: 24,
                      child: CircularProgressIndicator(strokeWidth: 2, color: _kP)),
                  error: (_, __) => Text('Error loading brands', style: TextStyle(
                      fontSize: (sw * 0.033).clamp(11.0, 14.0), color: _kRed)))),
        ]));
  }

  // ── Discounts section ───────────────────────────────────────────────────
  Widget _discountsSection(double sw, double sh,
      AsyncValue<List<DealerDiscountModel>> async) {
    return Container(
        decoration: BoxDecoration(color: _kWhite,
            borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _sectionHeader(sw, Icons.local_offer_outlined, 'Discounts',
              trailing: (async.asData?.value.isNotEmpty == true)
                  ? RoleGuard(feature: AppFeature.editDealer,
                  child: _editPill(sw, label: _editingDiscounts ? 'Done' : 'Edit',
                      onTap: () => setState(() => _editingDiscounts = !_editingDiscounts)))
                  : null),
          Divider(height: 1, color: _kBd),
          async.when(
              loading: () => const Padding(padding: EdgeInsets.all(24),
                  child: Center(child: CircularProgressIndicator(strokeWidth: 2, color: _kP))),
              error: (_, __) => Padding(padding: EdgeInsets.all(sw * 0.04),
                  child: _banner('Error loading discounts', _kRed, _kRedBg, _kRedBd)),
              data: (discounts) {
                if (discounts.isEmpty) {
                  return Padding(padding: EdgeInsets.all(sw * 0.05),
                    child: Center(child: Text('No discounts yet', style: TextStyle(
                        fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT4))));
                }
                return Padding(
                    padding: EdgeInsets.fromLTRB(sw * 0.035, sw * 0.03, sw * 0.035, sw * 0.035),
                    child: Column(children: discounts.map((d) => Padding(
                        padding: EdgeInsets.only(bottom: sw * 0.025),
                        child: _DiscountCard(discount: d, showEdit: _editingDiscounts,
                            onEdit: () => _editDiscount(context, d)))).toList()));
              }),
        ]));
  }

  // ── Section header ──────────────────────────────────────────────────────
  Widget _sectionHeader(double sw, IconData icon, String title, {Widget? trailing}) {
    return Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
        child: Row(children: [
          Container(width: (sw * 0.075).clamp(26.0, 36.0), height: (sw * 0.075).clamp(26.0, 36.0),
              decoration: BoxDecoration(color: _kBg,
                  borderRadius: BorderRadius.circular((sw * 0.022).clamp(6.0, 10.0))),
              child: Icon(icon, size: (sw * 0.04).clamp(14.0, 20.0), color: _kT1)),
          SizedBox(width: sw * 0.025),
          Expanded(child: Text(title, style: TextStyle(
              fontSize: (sw * 0.035).clamp(12.0, 16.0), fontWeight: FontWeight.w700, color: _kT1))),
          if (trailing != null) trailing,
        ]));
  }

  Widget _editPill(double sw, {String label = 'Edit', required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: (sw * 0.03).clamp(10.0, 14.0),
            vertical: (sw * 0.01).clamp(3.0, 6.0)),
        decoration: BoxDecoration(color: _kPBg, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kPBd, width: 0.5)),
        child: Text(label, style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0),
            fontWeight: FontWeight.w700, color: _kP))));
  }

  Widget _banner(String msg, Color c, Color bg, Color bd) {
    return Container(padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10),
            border: Border.all(color: bd, width: 0.5)),
        child: Row(children: [
          Icon(Icons.info_outline, size: 18, color: c),
          const SizedBox(width: 10),
          Expanded(child: Text(msg, style: TextStyle(fontSize: 13, color: c, fontWeight: FontWeight.w600))),
        ]));
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Dialogs — all logic unchanged, UI Zoho tokens + MediaQuery
  // ══════════════════════════════════════════════════════════════════════════

  void _editPersonalInfo(BuildContext ctx, UserModel d) {
    final nameC = TextEditingController(text: d.employeeName);
    final emailC = TextEditingController(text: d.employeeEmail);
    final phoneC = TextEditingController(text: d.employeePhone);
    final fk = GlobalKey<FormState>();
    _sheet(ctx, 'Edit Personal Info', d.employeeName ?? '',
        child: Form(key: fk, child: Column(children: [
          _sheetField(nameC, 'Full Name', Icons.person_outline,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          _sheetField(emailC, 'Email', Icons.email_outlined,
              keyboard: TextInputType.emailAddress,
              validator: (v) { if (v == null || v.trim().isEmpty) return 'Required';
              if (!v.contains('@')) return 'Invalid'; return null; }),
          const SizedBox(height: 14),
          _sheetField(phoneC, 'Phone', Icons.phone_outlined,
              keyboard: TextInputType.phone,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 22),
          _sheetActions(onCancel: () => Navigator.pop(ctx), onSave: () {
            if (fk.currentState!.validate()) {
              _updateInfo(d, name: nameC.text.trim(), email: emailC.text.trim(), phone: phoneC.text.trim());
              Navigator.pop(ctx);
            }
          }),
        ])));
  }

  void _editAddress(BuildContext ctx, UserModel d) {
    final addrC = TextEditingController(text: d.address);
    final townC = TextEditingController(text: d.town);
    final fk = GlobalKey<FormState>();
    String? dist;
    if (d.district != null && d.district!.isNotEmpty) {
      final n = d.district!.trim().toLowerCase();
      dist = keralaDistricts.firstWhere((x) => x.toLowerCase() == n, orElse: () => d.district!);
    }
    _sheet(ctx, 'Edit Address', d.shopName ?? '',
        child: StatefulBuilder(builder: (_, setS) => Form(key: fk, child: Column(children: [
          _sheetField(addrC, 'Street Address', Icons.home_outlined, maxLines: 2,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          DropdownButtonFormField<String>(
              initialValue: keralaDistricts.contains(dist) ? dist : null,
              decoration: _sheetDeco('District', Icons.map_outlined),
              items: keralaDistricts.map((x) => DropdownMenuItem(value: x, child: Text(x))).toList(),
              onChanged: (v) => setS(() => dist = v),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null),
          const SizedBox(height: 14),
          _sheetField(townC, 'Town', Icons.location_city_outlined,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 22),
          _sheetActions(onCancel: () => Navigator.pop(ctx), onSave: () {
            if (fk.currentState!.validate()) {
              _updateInfo(d, address: addrC.text.trim(), district: dist!, town: townC.text.trim());
              Navigator.pop(ctx);
            }
          }),
        ]))));
  }

  void _editBusiness(BuildContext ctx, WidgetRef ref, UserModel d) async {
    final sw = MediaQuery.sizeOf(ctx).width;
    final sh = MediaQuery.sizeOf(ctx).height;
    final allBrands = ref.read(activeBrandControllerProvider)
        .maybeWhen(data: (x) => x, orElse: () => <BrandModel>[]);
    final current = await ref.read(dealerBrandsProvider(widget.dealerId).future);
    if (!ctx.mounted) return;
    final currentNames = current.map((b) => b.brandName).toSet();
    final shopC = TextEditingController(text: d.shopName ?? '');
    final Set<BrandModel> toRemove = {};
    final Set<BrandModel> toAdd = {};
    await showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (bCtx) => StatefulBuilder(builder: (_, setS) {
          final available = allBrands.where((b) => !currentNames.contains(b.brandName)).toList();
          return DraggableScrollableSheet(initialChildSize: 0.75, maxChildSize: 0.92, minChildSize: 0.4,
              builder: (_, sc) => Container(
                  decoration: BoxDecoration(color: _kWhite,
                      borderRadius: BorderRadius.vertical(top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
                  child: Column(children: [
                    Padding(padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, 0),
                        child: Column(children: [
                          _handleW(),
                          Row(children: [
                            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                              Text('Edit Business Info', style: TextStyle(
                                  fontSize: (sw * 0.045).clamp(15.0, 21.0), fontWeight: FontWeight.w800, color: _kT1)),
                              Text(d.shopName ?? d.employeeId ?? '', style: TextStyle(
                                  fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4)),
                            ])),
                          ]),
                        ])),
                    Expanded(child: SingleChildScrollView(controller: sc,
                        padding: EdgeInsets.all(sw * 0.05),
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _sheetLabel('Shop Name'),
                          const SizedBox(height: 6),
                          TextField(controller: shopC, decoration: _sheetDeco('Shop name', Icons.storefront_outlined),
                              style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1)),
                          SizedBox(height: sh * 0.025),
                          if (current.isNotEmpty) ...[
                            _sheetLabel('Current Brands — tap to remove'),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: current.map((b) {
                              final marked = toRemove.contains(b);
                              return GestureDetector(
                                  onTap: () => setS(() => marked ? toRemove.remove(b) : toRemove.add(b)),
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(color: marked ? _kRedBg : _kGreenBg,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: marked ? _kRedBd : _kGreenBd, width: 0.5)),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(marked ? Icons.remove_circle_outline : Icons.check_circle_outline,
                                            size: 14, color: marked ? _kRed : _kGreen),
                                        const SizedBox(width: 5),
                                        Text(b.brandName, style: TextStyle(
                                            fontSize: (sw * 0.033).clamp(11.0, 14.0), fontWeight: FontWeight.w600,
                                            color: marked ? _kRed : _kGreen,
                                            decoration: marked ? TextDecoration.lineThrough : null)),
                                      ])));
                            }).toList()),
                            if (toRemove.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _banner('${toRemove.length} brand(s) will be removed', _kRed, _kRedBg, _kRedBd),
                            ],
                            SizedBox(height: sh * 0.025),
                            Divider(color: _kBd),
                            SizedBox(height: sh * 0.015),
                          ],
                          if (available.isNotEmpty) ...[
                            _sheetLabel('Add Brands'),
                            const SizedBox(height: 8),
                            Wrap(spacing: 8, runSpacing: 8, children: available.map((b) {
                              final sel = toAdd.contains(b);
                              return GestureDetector(
                                  onTap: () => setS(() => sel ? toAdd.remove(b) : toAdd.add(b)),
                                  child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                      decoration: BoxDecoration(color: sel ? _kPBg : _kBg,
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: sel ? _kPBd : _kBd, width: 0.5)),
                                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                                        Icon(sel ? Icons.check_circle : Icons.add_circle_outline,
                                            size: 14, color: sel ? _kP : _kT4),
                                        const SizedBox(width: 5),
                                        Text(b.brandName, style: TextStyle(
                                            fontSize: (sw * 0.033).clamp(11.0, 14.0), fontWeight: FontWeight.w600,
                                            color: sel ? _kP : _kT4)),
                                      ])));
                            }).toList()),
                            if (toAdd.isNotEmpty) ...[
                              const SizedBox(height: 8),
                              _banner('${toAdd.length} brand(s) will be added', _kP, _kPBg, _kPBd),
                            ],
                          ],
                          SizedBox(height: sh * 0.03),
                          _sheetActions(
                              onCancel: () { shopC.dispose(); Navigator.pop(bCtx); },
                              onSave: () async {
                                Navigator.pop(bCtx);
                                await _updateBusiness(d, shopName: shopC.text.trim(),
                                    addBrands: toAdd.map((b) => b.brandName).toList(),
                                    removeBrands: toRemove.map((b) => b.brandName).toList());
                                shopC.dispose();
                              }),
                        ]))),
                  ])));
        }));
  }

  void _editDiscount(BuildContext ctx, DealerDiscountModel disc) {
    bool isPct = disc.isPercentage;
    final valC = TextEditingController(text: disc.discountValue.toString());
    final descC = TextEditingController(text: disc.description);
    final sw = MediaQuery.sizeOf(ctx).width;
    _sheet(ctx, 'Update Discount', '${disc.brandName} · ${disc.modelName}',
        child: StatefulBuilder(builder: (_, setS) => Column(children: [
          _sheetField(valC, 'Discount Value', Icons.percent, keyboard: TextInputType.number),
          const SizedBox(height: 14),
          _sheetField(descC, 'Description', Icons.description_outlined),
          const SizedBox(height: 14),
          Container(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
              decoration: BoxDecoration(color: _kBg, borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _kBd, width: 0.5)),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Is Percentage?', style: TextStyle(
                    fontSize: (sw * 0.036).clamp(12.0, 16.0), fontWeight: FontWeight.w600, color: _kT1)),
                Switch(value: isPct, onChanged: (v) => setS(() => isPct = v), activeThumbColor: _kP),
              ])),
          const SizedBox(height: 22),
          _sheetActions(onCancel: () => Navigator.pop(ctx), onSave: () async {
            final updated = disc.copyWith(discountValue: num.tryParse(valC.text),
                description: descC.text, isPercentage: isPct, productId: disc.productId);
            await ref.read(dealerDiscountControllerProvider.notifier).updateDealerDiscount(updated);
            if (ctx.mounted) Navigator.pop(ctx);
          }),
        ])));
  }

  // ── Sheet helpers ───────────────────────────────────────────────────────
  void _sheet(BuildContext ctx, String title, String sub, {required Widget child}) {
    final sw = MediaQuery.sizeOf(ctx).width;
    showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: Container(
                decoration: BoxDecoration(color: _kWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
                padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
                child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _handleW(),
                      Text(title, style: TextStyle(
                          fontSize: (sw * 0.045).clamp(15.0, 21.0), fontWeight: FontWeight.w800, color: _kT1)),
                      Text(sub, style: TextStyle(
                          fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4)),
                      SizedBox(height: sw * 0.05),
                      child,
                    ])))));
  }

  Widget _handleW() => Center(child: Container(width: 36, height: 4,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(color: _kBd, borderRadius: BorderRadius.circular(2))));

  Widget _sheetLabel(String t) => Text(t.toUpperCase(), style: TextStyle(
      fontSize: 11, fontWeight: FontWeight.w700, color: _kT4, letterSpacing: 0.5));

  InputDecoration _sheetDeco(String hint, IconData icon) {
    return InputDecoration(hintText: hint, hintStyle: const TextStyle(fontSize: 14, color: _kT4),
        prefixIcon: Icon(icon, color: _kT4, size: 20), filled: true, fillColor: _kBg,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kBd, width: 0.5)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kP, width: 1.5)));
  }

  Widget _sheetField(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboard, int maxLines = 1, String? Function(String?)? validator}) {
    return TextFormField(controller: c, keyboardType: keyboard, maxLines: maxLines,
        validator: validator, style: const TextStyle(fontSize: 14, color: _kT1),
        decoration: _sheetDeco(label, icon));
  }

  Widget _sheetActions({required VoidCallback onCancel, required VoidCallback onSave}) {
    return Row(children: [
      Expanded(child: OutlinedButton(onPressed: onCancel,
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              side: const BorderSide(color: _kBd, width: 0.5)),
          child: const Text('Cancel', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _kT4)))),
      const SizedBox(width: 12),
      Expanded(flex: 2, child: ElevatedButton(onPressed: onSave,
          style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
          child: const Text('Save Changes', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)))),
    ]);
  }

  // ══════════════════════════════════════════════════════════════════════════
  // Update helpers — logic UNCHANGED
  // ══════════════════════════════════════════════════════════════════════════

  Future<void> _updateBusiness(UserModel d, {required String shopName,
    required List<String> addBrands, required List<String> removeBrands}) async {
    try {
      final r = await ref.read(signupControllerProvider.notifier).updateUser(
          oldUser: d, shopName: shopName.isEmpty ? null : shopName,
          addBrands: addBrands.isEmpty ? null : addBrands,
          removeBrands: removeBrands.isEmpty ? null : removeBrands);
      if (!mounted) return;
      if (r == null) {
        ref.invalidate(dealerProvider(widget.dealerId));
        ref.invalidate(dealerBrandsProvider(widget.dealerId));
        _snack('Business info updated', _kGreen);
      } else { _snack('Failed: $r', _kRed); }
    } catch (e) { if (mounted) _snack('Error: $e', _kRed); }
  }

  void _updateInfo(UserModel d, {String? name, String? email, String? phone,
    String? address, String? district, String? town}) async {
    try {
      final r = await ref.read(signupControllerProvider.notifier).updateUser(
          oldUser: d, name: name, email: email, phone: phone,
          address: address, district: district, town: town);
      if (!mounted) return;
      if (r == null) { ref.invalidate(dealerProvider(widget.dealerId)); _snack('Updated', _kGreen); }
      else { _snack('Failed: $r', _kRed); }
    } catch (e) { if (mounted) _snack('Error: $e', _kRed); }
  }

  Future<void> _updatePhoto(BuildContext ctx, WidgetRef ref, UserModel d) async {
    try {
      final src = await showModalBottomSheet<ImageSource>(context: ctx,
          backgroundColor: _kWhite,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
          builder: (_) => Padding(padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                _handleW(),
                ListTile(leading: const Icon(Icons.camera_alt_outlined, color: _kP),
                    title: const Text('Camera', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(ctx, ImageSource.camera)),
                ListTile(leading: const Icon(Icons.photo_library_outlined, color: _kP),
                    title: const Text('Gallery', style: TextStyle(fontWeight: FontWeight.w600)),
                    onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
              ])));
      if (src == null) return;
      final f = await ImagePicker().pickImage(source: src, imageQuality: 70, maxWidth: 1024);
      if (f == null) return;
      if (ctx.mounted) {
        showDialog(context: ctx, barrierDismissible: false,
          builder: (_) => const Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5)));
      }
      final err = await ref.read(signupControllerProvider.notifier)
          .updateUser(oldUser: d, photoFile: File(f.path));
      if (ctx.mounted) { Navigator.pop(ctx);
      _snack(err != null ? 'Failed: $err' : 'Photo updated', err != null ? _kRed : _kGreen); }
    } catch (e) { if (ctx.mounted) { Navigator.pop(ctx); _snack('Error: $e', _kRed); } }
  }

  // ── Error screen ────────────────────────────────────────────────────────
  Widget _errorScreen(BuildContext ctx, double sw, double sh) {
    return Scaffold(backgroundColor: _kBg, body: SafeArea(child: Column(children: [
      Container(color: _kWhite,
          padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
          child: Row(children: [
            CircularIconButton(icon: Icons.arrow_back_ios_rounded, onTap: () => Navigator.pop(ctx)),
            const Spacer(),
            Text('Dealer Details', style: TextStyle(
                fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w700, color: _kT1)),
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
        ElevatedButton(onPressed: () => ref.invalidate(dealerProvider(widget.dealerId)),
            style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
                shape: const CircleBorder(), padding: const EdgeInsets.all(14), elevation: 0),
            child: const Icon(Icons.refresh_rounded)),
      ]))),
    ])));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═════════════════════════════════════════════════════════════════════════════

class _Pill extends StatelessWidget {
  const _Pill({required this.label, required this.fg, required this.bg, required this.bd});
  final String label; final Color fg, bg, bd;
  @override Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Container(
        padding: EdgeInsets.symmetric(
            horizontal: (sw * 0.025).clamp(8.0, 12.0),
            vertical: (sw * 0.008).clamp(3.0, 5.0)),
        decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
            border: Border.all(color: bd, width: 0.5)),
        child: Text(label, style: TextStyle(
            fontSize: (sw * 0.028).clamp(9.5, 12.5), fontWeight: FontWeight.w700, color: fg)));
  }
}

class _DiscountCard extends StatelessWidget {
  const _DiscountCard({required this.discount, required this.showEdit, required this.onEdit});
  final DealerDiscountModel discount; final bool showEdit; final VoidCallback onEdit;

  @override Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    return Container(
        decoration: BoxDecoration(color: _kGreenBg,
            borderRadius: BorderRadius.circular((sw * 0.03).clamp(8.0, 14.0)),
            border: Border.all(color: _kGreenBd, width: 0.5)),
        child: Column(children: [
          Padding(padding: EdgeInsets.all(sw * 0.035),
              child: Row(children: [
                Container(
                    width: (sw * 0.085).clamp(30.0, 40.0), height: (sw * 0.085).clamp(30.0, 40.0),
                    decoration: BoxDecoration(color: _kGreenBd.withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular((sw * 0.025).clamp(8.0, 12.0))),
                    child: Icon(Icons.local_offer_outlined, color: _kGreen,
                        size: (sw * 0.045).clamp(15.0, 20.0))),
                SizedBox(width: sw * 0.03),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(discount.brandName, style: TextStyle(
                      fontSize: (sw * 0.035).clamp(12.0, 15.0), fontWeight: FontWeight.w700, color: _kT1)),
                  Text(discount.modelName, style: TextStyle(
                      fontSize: (sw * 0.029).clamp(10.0, 13.0), color: _kGreen, fontWeight: FontWeight.w500)),
                ])),
                Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: (sw * 0.03).clamp(10.0, 14.0),
                        vertical: (sw * 0.012).clamp(4.0, 7.0)),
                    decoration: BoxDecoration(color: _kGreen, borderRadius: BorderRadius.circular(20)),
                    child: Text(discount.isPercentage ? '${discount.discountValue}%' : '₹${discount.discountValue}',
                        style: TextStyle(fontSize: (sw * 0.033).clamp(11.0, 14.0),
                            fontWeight: FontWeight.w700, color: _kWhite))),
                if (showEdit) ...[
                  SizedBox(width: sw * 0.02),
                  GestureDetector(onTap: onEdit, child: Container(
                      padding: EdgeInsets.all((sw * 0.018).clamp(6.0, 9.0)),
                      decoration: BoxDecoration(color: _kPBg,
                          borderRadius: BorderRadius.circular((sw * 0.02).clamp(6.0, 10.0)),
                          border: Border.all(color: _kPBd, width: 0.5)),
                      child: Icon(Icons.edit_outlined, size: (sw * 0.04).clamp(14.0, 18.0), color: _kP))),
                ],
              ])),
          if (discount.products.isNotEmpty) ...[
            Divider(height: 1, color: _kGreenBd, indent: sw * 0.035, endIndent: sw * 0.035),
            Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.035, vertical: sw * 0.025),
                child: Column(children: discount.products.map((p) {
                  final orig = (p.price ?? 0).toDouble();
                  final disc = discount.isPercentage
                      ? orig * (1 - discount.discountValue / 100) : orig - discount.discountValue;
                  return Padding(padding: EdgeInsets.only(bottom: sw * 0.015),
                      child: Row(children: [
                        Container(width: (sw * 0.015).clamp(4.0, 7.0), height: (sw * 0.015).clamp(4.0, 7.0),
                            decoration: const BoxDecoration(color: _kGreen, shape: BoxShape.circle)),
                        SizedBox(width: sw * 0.025),
                        Expanded(child: Text(p.productName ?? 'Unknown', overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0),
                                color: _kT1, fontWeight: FontWeight.w500))),
                        Text('₹${orig.toStringAsFixed(0)}', style: TextStyle(
                            fontSize: (sw * 0.028).clamp(9.5, 12.0), color: _kT4,
                            decoration: TextDecoration.lineThrough)),
                        Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.015),
                            child: Icon(Icons.arrow_forward, size: (sw * 0.03).clamp(10.0, 13.0), color: _kGreen)),
                        Text('₹${disc.toStringAsFixed(0)}', style: TextStyle(
                            fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kGreen, fontWeight: FontWeight.w700)),
                      ]));
                }).toList())),
          ],
        ]));
  }
}