import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import '../../../core/const/icons.dart';
import '../../../feature/brand/model/brand_model.dart';
import '../../signup/model/user_model.dart';
import '../../../widgets/circle_button.dart';
import '../../signup/controller/signup_controller.dart';
import '../controller/brand_controller.dart';

// ── Zoho Books design tokens ──────────────────────────────────────────────────
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

// ═════════════════════════════════════════════════════════════════════════════
class BrandDetailsScreen extends ConsumerWidget {
  final String brandId;
  const BrandDetailsScreen({super.key, required this.brandId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(brandByIdProvider(brandId)).when(
        loading: () => const Scaffold(backgroundColor: _kBg,
            body: Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5))),
        error: (_, __) => _ErrorScreen(brandId: brandId),
        data: (brand) => _DetailView(brand: brand, brandId: brandId));
  }
}

// ── Detail view ─────────────────────────────────────────────────────────────
class _DetailView extends ConsumerStatefulWidget {
  final BrandModel brand; final String brandId;
  const _DetailView({required this.brand, required this.brandId});
  @override ConsumerState<_DetailView> createState() => _DetailViewState();
}

class _DetailViewState extends ConsumerState<_DetailView> {
  void _snack(String msg, Color bg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: bg, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final b = widget.brand;
    final active = b.status?.toLowerCase() == 'active';

    return Scaffold(backgroundColor: _kBg,
        body: SafeArea(child: Column(children: [
          // ── App bar ──────────────────────────────────────────────────────
          Container(color: _kWhite,
              padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
              child: Row(children: [
                CircularIconButton(icon: Icons.arrow_back_ios_rounded,
                    onTap: () {
                  Navigator.pop(context);
                }),
                const Spacer(),
                Text('Brand Details', style: TextStyle(
                    fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w700,
                    color: _kT1, letterSpacing: -0.2)),
                const Spacer(),
                SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
              ])),

          // ── Body ─────────────────────────────────────────────────────────
          Expanded(child: RefreshIndicator(color: _kP, backgroundColor: _kWhite,
              onRefresh: () async => ref.invalidate(brandByIdProvider(widget.brandId)),
              child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.fromLTRB(sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.04),
                  child: Column(children: [
                    _headerCard(sw, sh, b),
                    SizedBox(height: sh * 0.012),
                    _statusCard(sw, b, active),
                    SizedBox(height: sh * 0.012),
                    _modelsCard(sw, sh, b),
                    SizedBox(height: sh * 0.012),
                    ref.watch(employeeByIdProvider(b.createdBy ?? '')).when(
                        data: (user) => _creatorCard(sw, sh, user),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => _creatorCard(sw, sh, null)),
                    SizedBox(height: sh * 0.012),
                    RoleGuard(feature: AppFeature.viewTimestamps, child: _dateRow(sw, sh, b)),
                    SizedBox(height: sh * 0.04),
                  ])))),
        ])));
  }

  // ── Header ──────────────────────────────────────────────────────────────
  Widget _headerCard(double sw, double sh, BrandModel b) {
    return Container(
        decoration: BoxDecoration(color: _kWhite,
            borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        padding: EdgeInsets.all(sw * 0.04),
        child: Row(children: [
          Container(
              width: (sw * 0.13).clamp(44.0, 60.0), height: (sw * 0.13).clamp(44.0, 60.0),
              decoration: BoxDecoration(color: _kPBg,
                  borderRadius: BorderRadius.circular((sw * 0.035).clamp(10.0, 16.0)),
                  border: Border.all(color: _kPBd, width: 0.5)),
              child: Center(child: SvgPicture.asset(AppIcons.brand,
                  width: (sw * 0.06).clamp(22.0, 30.0),
                  colorFilter: const ColorFilter.mode(_kP, BlendMode.srcIn)))),
          SizedBox(width: sw * 0.035),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(b.brandName, style: TextStyle(
                fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w800,
                color: _kT1, letterSpacing: -0.3)),
            SizedBox(height: sw * 0.008),
            Text(b.description ?? 'No description', maxLines: 2, overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
            SizedBox(height: sw * 0.012),
            _Pill(sw: sw,
                label: '${b.brandModels.length} model${b.brandModels.length != 1 ? 's' : ''}',
                fg: _kP, bg: _kPBg, bd: _kPBd),
          ])),
          RoleGuard(feature: AppFeature.updateBrand,
              child: GestureDetector(onTap: () => _showEditSheet(context, sw, b),
                  child: Container(
                      padding: EdgeInsets.all((sw * 0.022).clamp(7.0, 12.0)),
                      decoration: BoxDecoration(color: _kPBg,
                          borderRadius: BorderRadius.circular((sw * 0.025).clamp(8.0, 12.0)),
                          border: Border.all(color: _kPBd, width: 0.5)),
                      child: Icon(Icons.edit_outlined, size: (sw * 0.045).clamp(15.0, 20.0), color: _kP)))),
        ]));
  }

  // ── Status ──────────────────────────────────────────────────────────────
  Widget _statusCard(double sw, BrandModel b, bool active) {
    final c = active ? _kGreen : _kRed;
    final bg = active ? _kGreenBg : _kRedBg;
    final bd = active ? _kGreenBd : _kRedBd;
    return Container(
        decoration: BoxDecoration(color: bg,
            borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: bd, width: 0.5)),
        padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
        child: Row(children: [
          Container(width: (sw * 0.09).clamp(32.0, 42.0), height: (sw * 0.09).clamp(32.0, 42.0),
              decoration: BoxDecoration(color: c, shape: BoxShape.circle),
              child: Icon(active ? Icons.check_rounded : Icons.pause_rounded,
                  color: _kWhite, size: (sw * 0.045).clamp(15.0, 20.0))),
          SizedBox(width: sw * 0.03),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Brand Status', style: TextStyle(
                fontSize: (sw * 0.028).clamp(9.5, 12.5), color: c, fontWeight: FontWeight.w600)),
            Text(active ? 'Active' : 'Inactive', style: TextStyle(
                fontSize: (sw * 0.038).clamp(13.0, 17.0), fontWeight: FontWeight.w800, color: c)),
          ])),
          RoleGuard(feature: AppFeature.updateStatus,
              child: Switch(value: active, activeThumbColor: _kGreen, activeTrackColor: _kGreenBd,
                  inactiveThumbColor: _kRed, inactiveTrackColor: _kRedBd,
                  onChanged: (v) async {
                    try {
                      await ref.read(brandControllerProvider.notifier)
                          .updateBrand(b.copyWith(status: v ? 'active' : 'inactive'), b.brandName);
                      ref.invalidate(brandByIdProvider(widget.brandId));
                      _snack('Status updated to ${v ? 'Active' : 'Inactive'}', _kGreen);
                    } catch (e) { _snack('Failed: $e', _kRed); }
                  })),
        ]));
  }

  // ── Models ──────────────────────────────────────────────────────────────
  Widget _modelsCard(double sw, double sh, BrandModel b) {
    return _Section(sw: sw, icon: Icons.tag_rounded, iconBg: _kAmberBg,
        iconColor: _kAmber, title: 'Models',
        trailing: RoleGuard(feature: AppFeature.updateBrand,
            child: _ActionPill(sw: sw, label: 'Edit', color: _kP, bg: _kPBg, bd: _kPBd,
                onTap: () => _showModelsSheet(context, sw, sh, b))),
        child: b.brandModels.isEmpty
            ? Text('No models added yet', style: TextStyle(
            fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4))
            : Wrap(spacing: sw * 0.02, runSpacing: sw * 0.02,
            children: b.brandModels.map((m) => Container(
                padding: EdgeInsets.symmetric(
                    horizontal: (sw * 0.03).clamp(10.0, 14.0),
                    vertical: (sw * 0.013).clamp(4.0, 7.0)),
                decoration: BoxDecoration(color: _kAmberBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kAmberBd, width: 0.5)),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.tag_rounded, size: (sw * 0.03).clamp(10.0, 14.0), color: _kAmber),
                  SizedBox(width: sw * 0.012),
                  Text(m, style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0),
                      fontWeight: FontWeight.w600, color: _kAmber)),
                ]))).toList()));
  }

  // ── Creator ─────────────────────────────────────────────────────────────
  Widget _creatorCard(double sw, double sh, UserModel? user) {
    final init = user != null ? user.employeeName[0].toUpperCase() : '?';
    return _Section(sw: sw, icon: Icons.person_outline_rounded, iconBg: _kBg,
        iconColor: _kT1, title: 'Created By',
        child: user == null
            ? Text('Creator info not available', style: TextStyle(
            fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4))
            : Row(children: [
          CircleAvatar(radius: (sw * 0.06).clamp(22.0, 30.0), backgroundColor: _kPBg,
              child: Text(init, style: TextStyle(
                  fontSize: (sw * 0.04).clamp(14.0, 20.0), fontWeight: FontWeight.w800, color: _kP))),
          SizedBox(width: sw * 0.035),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(user.employeeName, style: TextStyle(
                fontSize: (sw * 0.036).clamp(12.0, 16.0), fontWeight: FontWeight.w700, color: _kT1)),
            SizedBox(height: sw * 0.006),
            Text(user.employeeEmail, style: TextStyle(
                fontSize: (sw * 0.029).clamp(10.0, 13.0), color: _kP, fontWeight: FontWeight.w500)),
            SizedBox(height: sw * 0.006),
            _Pill(sw: sw,
                label: user.role.replaceAll('ROLE_', '').replaceAll('_', ' ').toLowerCase(),
                fg: _kP, bg: _kPBg, bd: _kPBd),
          ])),
        ]));
  }

  // ── Date row ────────────────────────────────────────────────────────────
  Widget _dateRow(double sw, double sh, BrandModel b) {
    return Row(children: [
      Expanded(child: _DateTile(sw: sw, label: 'Created', icon: Icons.calendar_today_outlined, date: b.createdAt)),
      SizedBox(width: sw * 0.025),
      Expanded(child: _DateTile(sw: sw, label: 'Updated', icon: Icons.update_rounded, date: b.updatedAt)),
    ]);
  }

  // ── Sheets ──────────────────────────────────────────────────────────────
  void _showEditSheet(BuildContext ctx, double sw, BrandModel b) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: _kWhite,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
        builder: (_) => _EditBrandSheet(brand: b, onSave: (name, desc) async {
          try {
            await ref.read(brandControllerProvider.notifier)
                .updateBrand(b.copyWith(brandName: name, description: desc), b.brandName);
            ref.invalidate(brandByIdProvider(widget.brandId));
            _snack('Brand updated', _kGreen);
          } catch (e) { _snack('Failed: $e', _kRed); }
        }));
  }

  void _showModelsSheet(BuildContext ctx, double sw, double sh, BrandModel b) {
    showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: _kWhite,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
        builder: (_) => _ManageModelsSheet(brand: b,
            onSave: (renamed, deleted, added) async {
              try {
                final updated = BrandModel(brandId: b.brandId, brandName: b.brandName,
                    brandModels: b.brandModels, description: b.description, status: b.status,
                    createdBy: b.createdBy, createdAt: b.createdAt, updatedAt: b.updatedAt);
                await ref.read(brandControllerProvider.notifier).updateBrand(updated, b.brandName,
                    brandModelsUpdate: renamed.isNotEmpty ? renamed : null,
                    deletedModels: deleted.isNotEmpty ? deleted : null,
                    addModel: added.isNotEmpty ? added : null);
                ref.invalidate(brandByIdProvider(widget.brandId));
                _snack('Models updated', _kGreen);
              } catch (e) { _snack('Failed: $e', _kRed); }
            }));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared widgets
// ═════════════════════════════════════════════════════════════════════════════

class _Section extends StatelessWidget {
  const _Section({required this.sw, required this.icon, required this.iconBg,
    required this.iconColor, required this.title, required this.child, this.trailing});
  final double sw; final IconData icon; final Color iconBg, iconColor;
  final String title; final Widget child; final Widget? trailing;

  @override Widget build(BuildContext context) => Container(
      decoration: BoxDecoration(color: _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
          border: Border.all(color: _kBd, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(children: [
              Container(width: (sw * 0.075).clamp(26.0, 36.0), height: (sw * 0.075).clamp(26.0, 36.0),
                  decoration: BoxDecoration(color: iconBg,
                      borderRadius: BorderRadius.circular((sw * 0.022).clamp(6.0, 10.0))),
                  child: Icon(icon, size: (sw * 0.04).clamp(14.0, 20.0), color: iconColor)),
              SizedBox(width: sw * 0.025),
              Expanded(child: Text(title, style: TextStyle(
                  fontSize: (sw * 0.035).clamp(12.0, 16.0), fontWeight: FontWeight.w700, color: _kT1))),
              if (trailing != null) trailing!,
            ])),
        Divider(height: 1, color: _kBd),
        Padding(padding: EdgeInsets.all(sw * 0.04), child: child),
      ]));
}

class _Pill extends StatelessWidget {
  const _Pill({required this.sw, required this.label, required this.fg,
    required this.bg, required this.bd});
  final double sw; final String label; final Color fg, bg, bd;
  @override Widget build(BuildContext context) => Container(
      padding: EdgeInsets.symmetric(
          horizontal: (sw * 0.025).clamp(8.0, 12.0), vertical: (sw * 0.008).clamp(3.0, 5.0)),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
          border: Border.all(color: bd, width: 0.5)),
      child: Text(label, style: TextStyle(
          fontSize: (sw * 0.026).clamp(9.0, 11.5), fontWeight: FontWeight.w700, color: fg)));
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({required this.sw, required this.label, required this.color,
    required this.bg, required this.bd, required this.onTap});
  final double sw; final String label; final Color color, bg, bd; final VoidCallback onTap;
  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
      child: Container(
          padding: EdgeInsets.symmetric(
              horizontal: (sw * 0.03).clamp(10.0, 14.0), vertical: (sw * 0.01).clamp(3.0, 6.0)),
          decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20),
              border: Border.all(color: bd, width: 0.5)),
          child: Text(label, style: TextStyle(
              fontSize: (sw * 0.03).clamp(10.0, 13.0), fontWeight: FontWeight.w700, color: color))));
}

class _DateTile extends StatelessWidget {
  const _DateTile({required this.sw, required this.label, required this.icon, required this.date});
  final double sw; final String label; final IconData icon; final dynamic date;

  String _fmt(dynamic d) {
    if (d == null) return '—';
    try { final dt = d is String ? DateTime.parse(d) : d as DateTime;
    return DateFormat('MMM dd, yyyy\nHH:mm').format(dt); } catch (_) { return 'Invalid'; }
  }

  @override Widget build(BuildContext context) => Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(color: _kWhite,
          borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
          border: Border.all(color: _kBd, width: 0.5)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, size: (sw * 0.035).clamp(12.0, 16.0), color: _kT4),
          SizedBox(width: sw * 0.015),
          Text(label, style: TextStyle(
              fontSize: (sw * 0.028).clamp(9.5, 12.5), color: _kT4, fontWeight: FontWeight.w600)),
        ]),
        SizedBox(height: sw * 0.015),
        Text(_fmt(date), style: TextStyle(
            fontSize: (sw * 0.03).clamp(10.0, 13.0), fontWeight: FontWeight.w600, color: _kT1)),
      ]));
}

// ═════════════════════════════════════════════════════════════════════════════
// Sheets
// ═════════════════════════════════════════════════════════════════════════════

InputDecoration _deco(double sw, String hint, IconData icon, {int maxLines = 1}) {
  final r = (sw * 0.028).clamp(8.0, 12.0);
  return InputDecoration(hintText: hint,
      hintStyle: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0), color: _kT4),
      prefixIcon: Icon(icon, color: _kT4, size: (sw * 0.045).clamp(15.0, 20.0)),
      filled: true, fillColor: _kBg,
      contentPadding: EdgeInsets.symmetric(horizontal: sw * 0.04,
          vertical: maxLines > 1 ? sw * 0.035 : 0),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kBd, width: 0.5)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kBd, width: 0.5)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kP, width: 1.5)),
      errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kRed)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kRed, width: 1.5)));
}

Widget _handle() => Center(child: Container(width: 36, height: 4,
    margin: const EdgeInsets.only(bottom: 18),
    decoration: BoxDecoration(color: _kBd, borderRadius: BorderRadius.circular(2))));

Widget _label(double sw, String t) => Text(t.toUpperCase(),
    style: TextStyle(fontSize: (sw * 0.028).clamp(9.5, 12.5),
        fontWeight: FontWeight.w700, color: _kT4, letterSpacing: 0.5));

Widget _actions(double sw, double sh, {required VoidCallback onCancel, required VoidCallback onSave}) {
  return Row(children: [
    Expanded(child: OutlinedButton(onPressed: onCancel,
        style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: sh * 0.016),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            side: const BorderSide(color: _kBd, width: 0.5)),
        child: Text('Cancel', style: TextStyle(
            fontSize: (sw * 0.036).clamp(12.0, 15.0), fontWeight: FontWeight.w700, color: _kT4)))),
    SizedBox(width: sw * 0.03),
    Expanded(flex: 2, child: ElevatedButton(onPressed: onSave,
        style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
            padding: EdgeInsets.symmetric(vertical: sh * 0.016),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)), elevation: 0),
        child: Text('Save Changes', style: TextStyle(
            fontSize: (sw * 0.036).clamp(12.0, 15.0), fontWeight: FontWeight.w700)))),
  ]);
}

// ── Edit brand sheet ──────────────────────────────────────────────────────
class _EditBrandSheet extends StatefulWidget {
  final BrandModel brand;
  final Future<void> Function(String name, String desc) onSave;
  const _EditBrandSheet({required this.brand, required this.onSave});
  @override State<_EditBrandSheet> createState() => _EditBrandSheetState();
}

class _EditBrandSheetState extends State<_EditBrandSheet> {
  late final TextEditingController _nameCtrl, _descCtrl;
  final _key = GlobalKey<FormState>();
  @override void initState() { super.initState();
  _nameCtrl = TextEditingController(text: widget.brand.brandName);
  _descCtrl = TextEditingController(text: widget.brand.description ?? ''); }
  @override void dispose() { _nameCtrl.dispose(); _descCtrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Padding(padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
            child: Form(key: _key, child: Column(mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _handle(),
                  Text('Edit Brand', style: TextStyle(
                      fontSize: (sw * 0.045).clamp(15.0, 21.0), fontWeight: FontWeight.w800, color: _kT1)),
                  Text(widget.brand.brandName, style: TextStyle(
                      fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
                  SizedBox(height: sw * 0.05),
                  _label(sw, 'Brand Name'), SizedBox(height: sh * 0.006),
                  TextFormField(controller: _nameCtrl,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      decoration: _deco(sw, 'Enter brand name', Icons.label_outline_rounded)),
                  SizedBox(height: sh * 0.015),
                  _label(sw, 'Description'), SizedBox(height: sh * 0.006),
                  TextFormField(controller: _descCtrl, maxLines: 3,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
                      validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
                      decoration: _deco(sw, 'Enter description', Icons.description_outlined, maxLines: 3)),
                  SizedBox(height: sh * 0.025),
                  _actions(sw, sh, onCancel: () => Navigator.pop(context),
                      onSave: () async {
                        if (!_key.currentState!.validate()) return;
                        Navigator.pop(context);
                        await widget.onSave(_nameCtrl.text.trim(), _descCtrl.text.trim());
                      }),
                ]))));
  }
}

// ── Manage models sheet ───────────────────────────────────────────────────
class _ManageModelsSheet extends StatefulWidget {
  final BrandModel brand;
  final Future<void> Function(Map<String, String> renamed, List<String> deleted, List<String> added) onSave;
  const _ManageModelsSheet({required this.brand, required this.onSave});
  @override State<_ManageModelsSheet> createState() => _ManageModelsSheetState();
}

class _ManageModelsSheetState extends State<_ManageModelsSheet> {
  final _newCtrl = TextEditingController();
  final Map<String, String> _renamed = {};
  final List<String> _deleted = [];
  final List<String> _added = [];
  @override void dispose() { _newCtrl.dispose(); super.dispose(); }

  @override Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final visible = widget.brand.brandModels.where((m) => !_deleted.contains(m)).toList();

    return DraggableScrollableSheet(expand: false, initialChildSize: 0.75, maxChildSize: 0.92,
        builder: (_, sc) => Column(children: [
          // Header
          Padding(padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, 0),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Center(child: _handle()),
                Text('Manage Models', style: TextStyle(
                    fontSize: (sw * 0.045).clamp(15.0, 21.0), fontWeight: FontWeight.w800, color: _kT1)),
                Text(widget.brand.brandName, style: TextStyle(
                    fontSize: (sw * 0.03).clamp(10.0, 13.0), color: _kT4)),
                SizedBox(height: sw * 0.04),
                // Add row
                Row(children: [
                  Expanded(child: TextField(controller: _newCtrl,
                      style: TextStyle(fontSize: (sw * 0.035).clamp(12.0, 15.0), color: _kT1),
                      decoration: _deco(sw, 'New model name', Icons.add_circle_outline))),
                  SizedBox(width: sw * 0.025),
                  GestureDetector(
                      onTap: () { final v = _newCtrl.text.trim();
                      if (v.isNotEmpty) setState(() { _added.add(v); _newCtrl.clear(); }); },
                      child: Container(
                          width: (sw * 0.12).clamp(42.0, 52.0), height: (sw * 0.12).clamp(42.0, 52.0),
                          decoration: BoxDecoration(color: _kPBg,
                              borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                              border: Border.all(color: _kPBd, width: 0.5)),
                          child: Icon(Icons.add_rounded, color: _kP, size: (sw * 0.055).clamp(18.0, 24.0)))),
                ]),
                SizedBox(height: sw * 0.04),
                Divider(height: 1, color: _kBd),
                SizedBox(height: sw * 0.015),
              ])),

          // List
          Expanded(child: ListView(controller: sc,
              padding: EdgeInsets.fromLTRB(sw * 0.05, 0, sw * 0.05, sw * 0.04),
              children: [
                if (visible.isNotEmpty) ...[
                  _label(sw, 'Existing Models'), SizedBox(height: sw * 0.02),
                  ...visible.map((m) {
                    final renamed = _renamed.containsKey(m);
                    return Container(
                        margin: EdgeInsets.only(bottom: sw * 0.025),
                        padding: EdgeInsets.symmetric(horizontal: sw * 0.035, vertical: sw * 0.025),
                        decoration: BoxDecoration(color: renamed ? _kPBg : _kBg,
                            borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                            border: Border.all(color: renamed ? _kPBd : _kBd, width: 0.5)),
                        child: Row(children: [
                          Icon(Icons.tag_rounded, size: (sw * 0.04).clamp(14.0, 18.0), color: _kAmber),
                          SizedBox(width: sw * 0.025),
                          Expanded(child: renamed
                              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            Text(m, style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0),
                                color: _kT4, decoration: TextDecoration.lineThrough)),
                            Text(_renamed[m]!, style: TextStyle(
                                fontSize: (sw * 0.034).clamp(11.5, 15.0),
                                fontWeight: FontWeight.w700, color: _kP)),
                          ])
                              : Text(m, style: TextStyle(fontSize: (sw * 0.034).clamp(11.5, 15.0),
                              fontWeight: FontWeight.w600, color: _kT1))),
                          _SmallBtn(sw: sw, icon: Icons.edit_outlined, color: _kP, bg: _kPBg, bd: _kPBd,
                              onTap: () => _showRenameDialog(context, sw, m)),
                          SizedBox(width: sw * 0.02),
                          _SmallBtn(sw: sw, icon: Icons.delete_outline_rounded, color: _kRed, bg: _kRedBg, bd: _kRedBd,
                              onTap: () => setState(() { _deleted.add(m); _renamed.remove(m); })),
                        ]));
                  }),
                  SizedBox(height: sw * 0.03),
                ],
                if (_added.isNotEmpty) ...[
                  _label(sw, 'New Models'), SizedBox(height: sw * 0.02),
                  ..._added.map((m) => Container(
                      margin: EdgeInsets.only(bottom: sw * 0.025),
                      padding: EdgeInsets.symmetric(horizontal: sw * 0.035, vertical: sw * 0.025),
                      decoration: BoxDecoration(color: _kGreenBg,
                          borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                          border: Border.all(color: _kGreenBd, width: 0.5)),
                      child: Row(children: [
                        Icon(Icons.fiber_new_rounded, color: _kGreen, size: (sw * 0.045).clamp(15.0, 20.0)),
                        SizedBox(width: sw * 0.025),
                        Expanded(child: Text(m, style: TextStyle(
                            fontSize: (sw * 0.034).clamp(11.5, 15.0), fontWeight: FontWeight.w700, color: _kGreen))),
                        _SmallBtn(sw: sw, icon: Icons.delete_outline_rounded, color: _kRed, bg: _kRedBg, bd: _kRedBd,
                            onTap: () => setState(() => _added.remove(m))),
                      ]))),
                  SizedBox(height: sw * 0.03),
                ],
                _actions(sw, sh, onCancel: () => Navigator.pop(context),
                    onSave: () async { Navigator.pop(context); await widget.onSave(_renamed, _deleted, _added); }),
              ])),
        ]));
  }

  void _showRenameDialog(BuildContext ctx, double sw, String model) {
    final ctrl = TextEditingController(text: _renamed[model] ?? model);
    showDialog(context: ctx, builder: (_) => AlertDialog(
        backgroundColor: _kWhite,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0))),
        title: Text('Rename Model', style: TextStyle(
            fontSize: (sw * 0.04).clamp(13.0, 18.0), fontWeight: FontWeight.w800, color: _kT1)),
        content: TextField(controller: ctrl, autofocus: true,
            style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0), color: _kT1),
            decoration: _deco(sw, 'New name', Icons.label_outline_rounded)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx),
              child: Text('Cancel', style: TextStyle(color: _kT4, fontWeight: FontWeight.w700))),
          ElevatedButton(
              onPressed: () { final v = ctrl.text.trim();
              if (v.isNotEmpty && v != model) { setState(() => _renamed[model] = v); Navigator.pop(ctx); } },
              style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite, elevation: 0),
              child: const Text('Rename', style: TextStyle(fontWeight: FontWeight.w700))),
        ])).whenComplete(() => ctrl.dispose());
  }
}

// ── Small action button ───────────────────────────────────────────────────
class _SmallBtn extends StatelessWidget {
  const _SmallBtn({required this.sw, required this.icon, required this.color,
    required this.bg, required this.bd, required this.onTap});
  final double sw; final IconData icon; final Color color, bg, bd; final VoidCallback onTap;

  @override Widget build(BuildContext context) => GestureDetector(onTap: onTap,
      child: Container(
          width: (sw * 0.08).clamp(28.0, 36.0), height: (sw * 0.08).clamp(28.0, 36.0),
          decoration: BoxDecoration(color: bg,
              borderRadius: BorderRadius.circular((sw * 0.02).clamp(6.0, 10.0)),
              border: Border.all(color: bd, width: 0.5)),
          child: Icon(icon, size: (sw * 0.038).clamp(13.0, 17.0), color: color)));
}

// ── Error screen ──────────────────────────────────────────────────────────
class _ErrorScreen extends ConsumerWidget {
  final String brandId;
  const _ErrorScreen({required this.brandId});

  @override Widget build(BuildContext context, WidgetRef ref) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    return Scaffold(backgroundColor: _kBg,
        body: SafeArea(child: Column(children: [
          Container(color: _kWhite,
              padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
              child: Row(children: [
                CircularIconButton(icon: Icons.arrow_back_ios_rounded, onTap: () => Navigator.pop(context)),
                const Spacer(),
                Text('Brand Details', style: TextStyle(
                    fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w700, color: _kT1)),
                const Spacer(),
                SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
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
            ElevatedButton(
                onPressed: () => ref.invalidate(brandByIdProvider(brandId)),
                style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
                    shape: const CircleBorder(), padding: const EdgeInsets.all(14), elevation: 0),
                child: const Icon(Icons.refresh_rounded)),
          ]))),
        ])));
  }
}