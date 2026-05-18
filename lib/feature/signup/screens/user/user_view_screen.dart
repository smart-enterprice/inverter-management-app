import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/const/role.dart';
import '../../model/user_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../controller/signUp_controller.dart';
import '../dealer/dealerAssignmentScreen.dart';

// ── Design tokens (mirrors DealerView exactly) ────────────────────────────────
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
const _kRed     = Color(0xFFDC2626);

// ── Provider ──────────────────────────────────────────────────────────────────
final userProvider = FutureProvider.family<UserModel, String>((ref, userId) async {
  return ref.read(signupControllerProvider.notifier).getEmployeeById(userId);
});

// ── Role helpers ──────────────────────────────────────────────────────────────
String formatRole(String role) {
  if (role.startsWith('ROLE_')) {
    final c = role.replaceFirst('ROLE_', '');
    return c[0].toUpperCase() + c.substring(1).toLowerCase();
  }
  return role;
}

// ═════════════════════════════════════════════════════════════════════════════
class UserViewScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserViewScreen({super.key, required this.userId});
  @override ConsumerState<UserViewScreen> createState() => _UserViewScreenState();
}

class _UserViewScreenState extends ConsumerState<UserViewScreen> {

  void _snack(String msg, Color bg) => ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
          backgroundColor: bg, behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));

  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;
    final userAsync = ref.watch(userProvider(widget.userId));

    return userAsync.when(
        loading: () => const Scaffold(backgroundColor: _kBg,
            body: Center(child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5))),
        error: (e, _) => _errorScreen(context, sw, sh),
        data: (user) => Scaffold(backgroundColor: _kBg,
            body: SafeArea(child: RefreshIndicator(color: _kP, backgroundColor: _kWhite,
                onRefresh: () async => ref.invalidate(userProvider(widget.userId)),
                child: CustomScrollView(physics: const AlwaysScrollableScrollPhysics(), slivers: [
                  SliverToBoxAdapter(child: Column(children: [
                    // ── App bar ────────────────────────────────────────────────
                    Container(color: _kWhite,
                        padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
                        child: Row(children: [
                          CircularIconButton(icon: Icons.arrow_back_ios_rounded,
                              onTap: () => Navigator.pop(context)),
                          const Spacer(),
                          Text('Employee Details', style: TextStyle(
                              fontSize: (sw * 0.042).clamp(14.0, 20.0), fontWeight: FontWeight.w700,
                              color: _kT1, letterSpacing: -0.2)),
                          const Spacer(),
                          // Keeps symmetry — same width as back button
                          SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
                        ])),

                    // ── Profile card ───────────────────────────────────────────
                    _profileCard(sw, sh, user),
                    SizedBox(height: sh * 0.005),

                    Padding(padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                        child: Column(children: [
                          // Action buttons
                          _actionButtons(sw, sh, user),
                          SizedBox(height: sh * 0.012),

                          // Personal info
                          _infoSection(sw, Icons.person_outline_rounded, 'Personal Info',
                              onEdit: () => _editPersonalInfo(context, user),
                              rows: [
                                ('ID',    user.employeeId ?? 'N/A'),
                                ('Name',  user.employeeName.replaceAll('_', ' ')),
                                ('Email', user.employeeEmail ?? 'N/A'),
                                ('Phone', user.employeePhone ?? 'N/A'),
                                ('Role',  formatRole(user.role ?? 'N/A')),
                              ]),
                          SizedBox(height: sh * 0.012),

                          // Address
                          _infoSection(sw, Icons.home_outlined, 'Address',
                              onEdit: () => _editAddress(context, user),
                              featureGuard: AppFeature.handleUser,
                              rows: [
                                ('Address', user.address ?? 'N/A'),
                              ]),
                          SizedBox(height: sh * 0.012),
                          if (user.role == 'ROLE_SALESMAN') ...[
                            _dealersCard(sw, sh, user),
                            SizedBox(height: sh * 0.012),
                          ],
                        ])),
                  ])),
                ])))));
  }
  Widget _dealersCard(double sw, double sh, UserModel user) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DealerAssignmentScreen(salesman: user)),
      ),
      child: Container(
        padding: EdgeInsets.symmetric(
            horizontal: sw * 0.04, vertical: sw * 0.04),
        decoration: BoxDecoration(
            color: _kWhite,
            borderRadius:
            BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        child: Row(children: [
          Container(
            width: (sw * 0.075).clamp(26.0, 36.0),
            height: (sw * 0.075).clamp(26.0, 36.0),
            decoration: BoxDecoration(
                color: _kBg,
                borderRadius: BorderRadius.circular(
                    (sw * 0.022).clamp(6.0, 10.0))),
            child: Icon(Icons.storefront_outlined,
                size: (sw * 0.04).clamp(14.0, 20.0), color: _kT1),
          ),
          SizedBox(width: sw * 0.025),
          Expanded(
              child: Text('Dealers',
                  style: TextStyle(
                      fontSize: (sw * 0.035).clamp(12.0, 16.0),
                      fontWeight: FontWeight.w700,
                      color: _kT1))),
          Icon(Icons.arrow_forward_ios_rounded,
              size: (sw * 0.035).clamp(12.0, 16.0), color: _kT4),
        ]),
      ),
    );
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
                child: RoleGuard(feature: AppFeature.handleUser,
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

  // ── Action buttons ───────────────────────────────────────────────────────
  Widget _actionButtons(double sw, double sh, UserModel d) {
    return Container(
        padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.04),
        decoration: BoxDecoration(color: _kWhite,
            borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _actionBtn(sw: sw, icon: Icons.call_outlined, label: 'Call',
              color: _kP, bg: _kPBg,
              onTap: () => _makeCall(d.employeePhone ?? '')),
          _actionBtn(sw: sw, icon: Icons.email_outlined, label: 'Email',
              color: _kGreen, bg: _kGreenBg,
              onTap: () => _sendEmail(d.employeeEmail ?? '')),
          _actionBtn(sw: sw, icon: Icons.chat_bubble_outline_rounded, label: 'WhatsApp',
              color: const Color(0xFF25D366), bg: const Color(0xFFEAFAF1),
              onTap: () => _sendWhatsApp(d.employeePhone ?? '', d.employeeName ?? '')),
        ]));
  }

  Widget _actionBtn({required double sw, required IconData icon, required String label,
    required Color color, required Color bg, required VoidCallback onTap}) {
    return GestureDetector(onTap: onTap, child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
          width: (sw * 0.13).clamp(44.0, 60.0), height: (sw * 0.13).clamp(44.0, 60.0),
          decoration: BoxDecoration(color: bg,
              borderRadius: BorderRadius.circular((sw * 0.035).clamp(10.0, 16.0))),
          child: Icon(icon, color: color, size: (sw * 0.055).clamp(18.0, 26.0))),
      SizedBox(height: sw * 0.02),
      Text(label, style: TextStyle(fontSize: (sw * 0.03).clamp(10.0, 13.0),
          fontWeight: FontWeight.w600, color: _kT2)),
    ]));
  }

  // ── Info section ────────────────────────────────────────────────────────
  Widget _infoSection(double sw, IconData icon, String title,
      {required VoidCallback onEdit, required List<(String, String)> rows,
        String featureGuard = AppFeature.handleUser}) {
    return Container(
        decoration: BoxDecoration(color: _kWhite,
            borderRadius: BorderRadius.circular((sw * 0.04).clamp(10.0, 18.0)),
            border: Border.all(color: _kBd, width: 0.5)),
        child: Column(children: [
          _sectionHeader(sw, icon, title, trailing: RoleGuard(
              feature: featureGuard, child: _editPill(sw, onTap: onEdit))),
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

  // ══════════════════════════════════════════════════════════════════════════
  // Dialogs
  // ══════════════════════════════════════════════════════════════════════════

  void _editPersonalInfo(BuildContext ctx, UserModel d) {
    final nameC  = TextEditingController(text: d.employeeName);
    final emailC = TextEditingController(text: d.employeeEmail);
    final phoneC = TextEditingController(text: d.employeePhone);
    String? selectedRole = d.role;
    final fk = GlobalKey<FormState>();
    final sw = MediaQuery.sizeOf(ctx).width;
    final sh = MediaQuery.sizeOf(ctx).height;

    showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(ctx).bottom),
            child: Container(
                decoration: BoxDecoration(color: _kWhite,
                    borderRadius: BorderRadius.vertical(top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
                padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
                child: SingleChildScrollView(child: StatefulBuilder(builder: (bCtx, setS) =>
                    Form(key: fk, child: Column(mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start, children: [
                          _handleW(),
                          Text('Edit Personal Info', style: TextStyle(
                              fontSize: (sw * 0.045).clamp(15.0, 21.0), fontWeight: FontWeight.w800, color: _kT1)),
                          Text(d.employeeName ?? '', style: TextStyle(
                              fontSize: (sw * 0.032).clamp(11.0, 14.0), color: _kT4)),
                          SizedBox(height: sw * 0.05),

                          _sheetLabel('Full Name'),
                          const SizedBox(height: 6),
                          _sheetField(nameC, 'Full Name', Icons.person_outline,
                              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
                          SizedBox(height: sh * 0.015),

                          _sheetLabel('Email'),
                          const SizedBox(height: 6),
                          _sheetField(emailC, 'Enter email', Icons.email_outlined,
                              keyboard: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                if (!v.contains('@')) return 'Invalid email';
                                return null;
                              }),
                          SizedBox(height: sh * 0.015),

                          _sheetLabel('Phone'),
                          const SizedBox(height: 6),
                          _sheetField(phoneC, 'Enter phone', Icons.phone_outlined,
                              keyboard: TextInputType.phone,
                              digitsOnly: true,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) return 'Required';
                                if (v.length != 10) return 'Enter 10-digit number';
                                return null;
                              }),
                          SizedBox(height: sh * 0.015),

                          _sheetLabel('Role'),
                          const SizedBox(height: 6),
                          GestureDetector(
                              onTap: () => _showRolePicker(bCtx, selectedRole, (r) => setS(() => selectedRole = r)),
                              child: Container(
                                  padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
                                  decoration: BoxDecoration(color: _kBg,
                                      borderRadius: BorderRadius.circular((sw * 0.028).clamp(8.0, 12.0)),
                                      border: Border.all(color: _kBd, width: 0.5)),
                                  child: Row(children: [
                                    Icon(Icons.work_outline_rounded,
                                        size: (sw * 0.045).clamp(14.0, 20.0),
                                        color: selectedRole != null ? _kP : _kT4),
                                    SizedBox(width: sw * 0.025),
                                    Expanded(child: Text(
                                        selectedRole != null
                                            ? selectedRole!.replaceAll('ROLE_', '').replaceAll('_', ' ')
                                            : 'Select role',
                                        style: TextStyle(fontSize: (sw * 0.036).clamp(12.0, 16.0),
                                            fontWeight: FontWeight.w600,
                                            color: selectedRole != null ? _kT1 : _kT4))),
                                    Icon(Icons.keyboard_arrow_down_rounded, color: _kT4, size: (sw * 0.05).clamp(16.0, 22.0)),
                                  ]))),
                          SizedBox(height: sh * 0.025),

                          _sheetActions(onCancel: () => Navigator.pop(ctx), onSave: () {
                            if (fk.currentState!.validate()) {
                              _updateInfo(d, name: nameC.text.trim(), email: emailC.text.trim(),
                                  phone: phoneC.text.trim(), role: selectedRole);
                              Navigator.pop(ctx);
                            }
                          }),
                        ])))))));
  }

  void _showRolePicker(BuildContext ctx, String? current, void Function(String) onSelect) {
    final sw = MediaQuery.sizeOf(ctx).width;
    showModalBottomSheet(context: ctx, isScrollControlled: true, backgroundColor: Colors.transparent,
        builder: (_) => Container(
            decoration: BoxDecoration(color: _kWhite,
                borderRadius: BorderRadius.vertical(top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
            padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              _handleW(),
              Text('Select Role', style: TextStyle(
                  fontSize: (sw * 0.045).clamp(15.0, 21.0), fontWeight: FontWeight.w800, color: _kT1)),
              SizedBox(height: sw * 0.04),
              ConstrainedBox(
                  constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(ctx).height * 0.5),
                  child: SingleChildScrollView(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Column(children: roles.map((role) {
                        final isSel = current == role;
                        return GestureDetector(
                            onTap: () { onSelect(role); Navigator.pop(ctx); },
                            child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                margin: const EdgeInsets.only(bottom: 6),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                                decoration: BoxDecoration(
                                    color: isSel ? _kPBg : _kBg,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: isSel ? _kPBd : _kBd, width: 0.5)),
                                child: Row(children: [
                                  Expanded(child: Text(
                                      role.replaceAll('ROLE_', '').replaceAll('_', ' '),
                                      style: TextStyle(fontSize: (sw * 0.035).clamp(12.0, 15.0),
                                          fontWeight: isSel ? FontWeight.w700 : FontWeight.w500,
                                          color: isSel ? _kP : _kT2))),
                                  if (isSel) const Icon(Icons.check_rounded, color: _kP, size: 18),
                                ])));
                      }).toList()))),
            ])));
  }

  void _editAddress(BuildContext ctx, UserModel d) {
    final addrC = TextEditingController(text: d.address);
    final fk = GlobalKey<FormState>();
    _sheet(ctx, 'Edit Address', d.employeeName ?? '',
        child: Form(key: fk, child: Column(children: [
          _sheetField(addrC, 'Enter full address', Icons.home_outlined, maxLines: 3,
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
          const SizedBox(height: 22),
          _sheetActions(onCancel: () => Navigator.pop(ctx), onSave: () {
            if (fk.currentState!.validate()) {
              _updateInfo(d, address: addrC.text.trim());
              Navigator.pop(ctx);
            }
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
            borderSide: const BorderSide(color: _kP, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kRed, width: 1.0)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10),
            borderSide: const BorderSide(color: _kRed, width: 1.5)));
  }

  Widget _sheetField(TextEditingController c, String label, IconData icon,
      {TextInputType? keyboard, bool digitsOnly = false, int maxLines = 1,
        String? Function(String?)? validator}) {
    return TextFormField(controller: c, keyboardType: keyboard, maxLines: maxLines,
        validator: validator,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        inputFormatters: digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
        style: const TextStyle(fontSize: 14, color: _kT1),
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
  // Update helpers
  // ══════════════════════════════════════════════════════════════════════════

  void _updateInfo(UserModel d, {String? name, String? email, String? phone,
    String? address, String? role}) async {
    try {
      final r = await ref.read(signupControllerProvider.notifier).updateUser(
          oldUser: d, name: name, email: email, phone: phone,
          address: address, role: role);
      if (!mounted) return;
      if (r == null) { ref.invalidate(userProvider(widget.userId)); _snack('Updated', _kGreen); }
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
      if (ctx.mounted) {
        Navigator.pop(ctx);
        _snack(err != null ? 'Failed: $err' : 'Photo updated', err != null ? _kRed : _kGreen);
        if (err == null) ref.invalidate(userProvider(widget.userId));
      }
    } catch (e) { if (ctx.mounted) { Navigator.pop(ctx); _snack('Error: $e', _kRed); } }
  }

  // ── URL launchers ────────────────────────────────────────────────────────
  Future<void> _makeCall(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch call');
    }
  }

  Future<void> _sendEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch email');
    }
  }

  Future<void> _sendWhatsApp(String phone, String name) async {
    final uri = Uri.parse(
        'https://wa.me/$phone?text=${Uri.encodeComponent('Hi $name')}');
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      debugPrint('Could not launch WhatsApp');
    }
  }

  // ── Error screen ────────────────────────────────────────────────────────
  Widget _errorScreen(BuildContext ctx, double sw, double sh) {
    return Scaffold(backgroundColor: _kBg, body: SafeArea(child: Column(children: [
      Container(color: _kWhite,
          padding: EdgeInsets.fromLTRB(sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
          child: Row(children: [
            CircularIconButton(icon: Icons.arrow_back_ios_rounded, onTap: () => Navigator.pop(ctx)),
            const Spacer(),
            Text('Employee Details', style: TextStyle(
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
        ElevatedButton(onPressed: () => ref.invalidate(userProvider(widget.userId)),
            style: ElevatedButton.styleFrom(backgroundColor: _kP, foregroundColor: _kWhite,
                shape: const CircleBorder(), padding: const EdgeInsets.all(14), elevation: 0),
            child: const Icon(Icons.refresh_rounded)),
      ]))),
    ])));
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// Shared widget — mirrors DealerView's _Pill exactly
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