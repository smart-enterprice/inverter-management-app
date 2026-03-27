import 'dart:async';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/const/role.dart';
import '../../../../core/media_query/media_query.dart';
import '../../../../model/user_model.dart';
import '../../../../screen/loadingScreen.dart';
import '../../../../widgets/circle_button.dart';
import '../../controller/signUp_controller.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kBlue       = Color(0xFF1B4FD8);
const _kBlueBg     = Color(0xFFEEF2FF);
const _kBlueBorder = Color(0xFFC7D4FF);
const _kBg         = Color(0xFFF2F4F8);
const _kCard       = Colors.white;
const _kBorder     = Color(0xFFE5E7EB);
const _kDark       = Color(0xFF111827);
const _kMid        = Color(0xFF374151);
const _kMuted      = Color(0xFF9CA3AF);
const _kRed        = Color(0xFFDC2626);
const _kRedBg      = Color(0xFFFEF2F2);
const _kRedBorder  = Color(0xFFFECACA);

String _formatRole(String role) {
  if (role.startsWith('ROLE_')) {
    final c = role.replaceFirst('ROLE_', '');
    return c[0].toUpperCase() + c.substring(1).toLowerCase();
  }
  return role;
}

String _displayRole(String role) =>
    role.replaceAll('ROLE_', '').replaceAll('_', ' ');

// ─── Provider ─────────────────────────────────────────────────────────────────
final userProvider =
FutureProvider.family<UserModel, String>((ref, userId) async {
  return ref.read(signupControllerProvider.notifier).getEmployeeById(userId);
});

// ─── Screen ───────────────────────────────────────────────────────────────────
class UserViewScreen extends ConsumerStatefulWidget {
  final String userId;
  const UserViewScreen({super.key, required this.userId});

  @override
  ConsumerState<UserViewScreen> createState() => _UserViewScreenState();
}

class _UserViewScreenState extends ConsumerState<UserViewScreen> {
  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final userAsync = ref.watch(userProvider(widget.userId));

    return userAsync.when(
      loading: () => const GlobalLoader(),
      error: (e, _) => _buildError(context, sw, sh),
      data: (user) => _buildView(context, user, sw, sh),
    );
  }

  // ── Main view ────────────────────────────────────────────────────────────────
  Widget _buildView(
      BuildContext context, UserModel user, double sw, double sh) {
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
                  Text('Employee Details',
                      style: TextStyle(
                          fontSize: sw * 0.042,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                          letterSpacing: -0.2)),
                  const Spacer(),
                  // No separate edit screen — edits happen inline via sheets
                  SizedBox(width: sw * 0.095),
                ],
              ),
            ),

            // ── Scrollable body ───────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _kBlue,
                backgroundColor: Colors.white,
                onRefresh: () async {
                  ref.invalidate(userProvider(widget.userId));
                },
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                  child: Column(
                    children: [
                      SizedBox(height: sh * 0.005),
                      _buildProfileCard(context, user, sw, sh),
                      SizedBox(height: sh * 0.012),
                      _buildActionButtons(context, user, sw),
                      SizedBox(height: sh * 0.012),
                      _buildInfoSection(
                        context: context,
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Info',
                        sw: sw,
                        onEdit: () =>
                            _showEditPersonalSheet(context, user),
                        rows: [
                          ('ID',    user.employeeId ?? 'N/A'),
                          ('Name',  user.employeeName),
                          ('Email', user.employeeEmail ?? 'N/A'),
                          ('Phone', user.employeePhone ?? 'N/A'),
                          ('Role',  _formatRole(user.role)),
                        ],
                      ),
                      SizedBox(height: sh * 0.012),
                      _buildInfoSection(
                        context: context,
                        icon: Icons.home_outlined,
                        title: 'Address',
                        sw: sw,
                        onEdit: () =>
                            _showEditAddressSheet(context, user),
                        rows: [
                          ('Address', user.address ?? 'N/A'),
                        ],
                      ),
                      SizedBox(height: sh * 0.04),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Profile Card ─────────────────────────────────────────────────────────────
  Widget _buildProfileCard(
      BuildContext context, UserModel user, double sw, double sh)
  {
    final initials = user.employeeName
        .trim()
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    return Container(
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
                radius: sw * 0.085,
                backgroundColor: _kBlueBg,
                backgroundImage: (user.photo != null && user.photo!.isNotEmpty)
                    ? NetworkImage(user.photo!)
                    : null,
                child: (user.photo == null || user.photo!.isEmpty)
                    ? Text(initials,
                    style: TextStyle(
                        fontSize: sw * 0.055,
                        fontWeight: FontWeight.w800,
                        color: _kBlue))
                    : null,
              ),
              Positioned(
                bottom: 0, right: 0,
                child: RoleGuard(
                  feature: AppFeature.handleUser,
                  child: GestureDetector(
                    onTap: () => _updatePhoto(context, user),
                    child: Container(
                      width: sw * 0.062, height: sw * 0.062,
                      decoration: BoxDecoration(
                        color: Colors.white, shape: BoxShape.circle,
                        border: Border.all(color: _kBorder),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4)
                        ],
                      ),
                      child: Icon(Icons.camera_alt_outlined,
                          size: sw * 0.032, color: _kBlue),
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(width: sw * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.employeeName.replaceAll('_', ' '),
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
                          horizontal: sw * 0.025, vertical: sw * 0.008),
                      decoration: BoxDecoration(
                        color: _kBlueBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kBlueBorder),
                      ),
                      child: Text(
                        _formatRole(user.role),
                        style: TextStyle(
                            fontSize: sw * 0.028,
                            fontWeight: FontWeight.w700,
                            color: _kBlue),
                      ),
                    ),
                    SizedBox(width: sw * 0.02),
                    Text(
                      user.employeeId ?? '',
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

  // ── Action Buttons ────────────────────────────────────────────────────────────
  Widget _buildActionButtons(
      BuildContext context, UserModel user, double sw) {
    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: sw * 0.04),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _actionBtn(
            sw: sw,
            icon: Icons.call_outlined,
            label: 'Call',
            color: _kBlue,
            bg: _kBlueBg,
            onTap: () => _makeCall(user.employeePhone ?? ''),
          ),
          _actionBtn(
            sw: sw,
            icon: Icons.email_outlined,
            label: 'Email',
            color: const Color(0xFF0A8A5C),
            bg: const Color(0xFFEDFAF4),
            onTap: () => _sendEmail(user.employeeEmail ?? ''),
          ),
          _actionBtn(
            sw: sw,
            icon: Icons.chat_bubble_outline_rounded,
            label: 'WhatsApp',
            color: const Color(0xFF25D366),
            bg: const Color(0xFFEAFAF1),
            onTap: () => _sendWhatsApp(
                user.employeePhone ?? '',
                user.employeeName),
          ),
        ],
      ),
    );
  }

  Widget _actionBtn({
    required double sw,
    required IconData icon,
    required String label,
    required Color color,
    required Color bg,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: sw * 0.13, height: sw * 0.13,
            decoration: BoxDecoration(
                color: bg, borderRadius: BorderRadius.circular(sw * 0.035)),
            child: Icon(icon, color: color, size: sw * 0.055),
          ),
          SizedBox(height: sw * 0.02),
          Text(label,
              style: TextStyle(
                  fontSize: sw * 0.03,
                  fontWeight: FontWeight.w600,
                  color: _kMid)),
        ],
      ),
    );
  }

  // ── Info Section Card ─────────────────────────────────────────────────────────
  Widget _buildInfoSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required double sw,
    required VoidCallback onEdit,
    required List<(String, String)> rows,
  }) {
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
                Container(
                  width: sw * 0.075, height: sw * 0.075,
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(sw * 0.022),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Icon(icon, size: sw * 0.04, color: _kDark),
                ),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Text(title,
                      style: TextStyle(
                          fontSize: sw * 0.035,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                ),
                RoleGuard(
                  feature: AppFeature.handleUser,
                  child: GestureDetector(
                    onTap: onEdit,
                    child: Container(
                      padding: EdgeInsets.symmetric(
                          horizontal: sw * 0.03, vertical: sw * 0.01),
                      decoration: BoxDecoration(
                        color: _kBlueBg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: _kBlueBorder),
                      ),
                      child: Text('Edit',
                          style: TextStyle(
                              fontSize: sw * 0.03,
                              fontWeight: FontWeight.w700,
                              color: _kBlue)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          // rows
          ...rows.asMap().entries.map((e) {
            final isLast = e.key == rows.length - 1;
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.04, vertical: sw * 0.028),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        width: sw * 0.2,
                        child: Text(e.value.$1,
                            style: TextStyle(
                                fontSize: sw * 0.03,
                                color: _kMuted,
                                fontWeight: FontWeight.w500)),
                      ),
                      Expanded(
                        child: Text(e.value.$2,
                            style: TextStyle(
                                fontSize: sw * 0.034,
                                color: _kDark,
                                fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  const Divider(height: 1, thickness: 1, color: _kBorder),
              ],
            );
          }),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Edit Sheets
  // ─────────────────────────────────────────────────────────────────────────────
  //  Edit Sheets — each uses a StatefulWidget so controllers have own lifecycle
  // ─────────────────────────────────────────────────────────────────────────────

  void _showEditPersonalSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditPersonalSheet(
        user: user,
        onSave: (name, email, phone, role) =>
            _updateUser(user, name: name, email: email, phone: phone, role: role),
      ),
    );
  }

  void _showEditAddressSheet(BuildContext context, UserModel user) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditAddressSheet(
        user: user,
        onSave: (address) => _updateUser(user, address: address),
      ),
    );
  }


  // ── Photo update ──────────────────────────────────────────────────────────────
  Future<void> _updatePhoto(BuildContext context, UserModel user) async {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36, height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                  color: _kBorder, borderRadius: BorderRadius.circular(2)),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _kBlue),
              title: const Text('Camera',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.camera, user);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kBlue),
              title: const Text('Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickAndUploadPhoto(ImageSource.gallery, user);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAndUploadPhoto(ImageSource source, UserModel user) async {
    try {
      final file = await ImagePicker().pickImage(
          source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (file == null || !mounted) return;

      showDialog(
          context: context,
          barrierDismissible: false,
          builder: (_) => const Center(
              child: CircularProgressIndicator(color: _kBlue)));

      final error = await ref
          .read(signupControllerProvider.notifier)
          .updateUser(oldUser: user, photoFile: File(file.path));

      if (!mounted) return;
      Navigator.pop(context);
      _showSnack(
        error != null ? 'Failed: $error' : 'Photo updated',
        error != null ? _kRed : Colors.green,
      );
      if (error == null) ref.invalidate(userProvider(widget.userId));
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      _showSnack('Error: $e', _kRed);
    }
  }

  // ── Update user helper ────────────────────────────────────────────────────────
  Future<void> _updateUser(
      UserModel user, {
        String? name,
        String? email,
        String? phone,
        String? address,
        String? role,
      }) async
  {
    showDialog(
        context: context,
        barrierDismissible: false,
        builder: (_) =>
        const Center(child: CircularProgressIndicator(color: _kBlue)));

    final error = await ref
        .read(signupControllerProvider.notifier)
        .updateUser(
      oldUser: user,
      name: name,
      email: email,
      phone: phone,
      address: address,
      role: role,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (error == null) {
      ref.invalidate(userProvider(widget.userId));
      _showSnack('Updated successfully', Colors.green);
    } else {
      _showSnack('Failed: $error', _kRed);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Error state ───────────────────────────────────────────────────────────────
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
                      onTap: () => Navigator.pop(context)),
                  const Spacer(),
                  Text('Employee Details',
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
                      width: sw * 0.18, height: sw * 0.18,
                      decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: _kBorder)),
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
                          ref.invalidate(userProvider(widget.userId)),
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

  // ─────────────────────────────────────────────────────────────────────────────
  //  Sheet helper widgets
  // ─────────────────────────────────────────────────────────────────────────────


  // ─────────────────────────────────────────────────────────────────────────────
  //  URL launchers
  // ─────────────────────────────────────────────────────────────────────────────
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
}

// ─── Edit Personal Info Sheet ─────────────────────────────────────────────────
class _EditPersonalSheet extends StatefulWidget {
  final UserModel user;
  final Future<void> Function(String name, String email, String phone, String? role) onSave;

  const _EditPersonalSheet({required this.user, required this.onSave});

  @override
  State<_EditPersonalSheet> createState() => _EditPersonalSheetState();
}

class _EditPersonalSheetState extends State<_EditPersonalSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late String? _selectedRole;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl  = TextEditingController(text: widget.user.employeeName);
    _emailCtrl = TextEditingController(text: widget.user.employeeEmail);
    _phoneCtrl = TextEditingController(text: widget.user.employeePhone);
    _selectedRole = widget.user.role;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    super.dispose();
  }

  void _showRolePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                    color: _kBorder,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const Text('Select Role',
                style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w800, color: _kDark)),
            const SizedBox(height: 14),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5),
              child: SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 32),
                child: Column(
                  children: roles.map((role) {
                    final isSel = _selectedRole == role;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedRole = role);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 13),
                        decoration: BoxDecoration(
                          color: isSel ? _kBlueBg : _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                              color: isSel ? _kBlueBorder : _kBorder),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                role.replaceAll('ROLE_', '').replaceAll('_', ' '),
                                style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: isSel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: isSel ? _kBlue : _kMid),
                              ),
                            ),
                            if (isSel)
                              const Icon(Icons.check_rounded,
                                  color: _kBlue, size: 18),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // handle
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                      color: _kBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Edit Personal Info',
                  style: TextStyle(
                      fontSize: sw * 0.045,
                      fontWeight: FontWeight.w800,
                      color: _kDark)),
              Text(widget.user.employeeName,
                  style: const TextStyle(
                      fontSize: 12, color: _kMuted, fontWeight: FontWeight.w500)),
              SizedBox(height: sw * 0.05),

              _FieldLabel(sw: sw, label: 'Full Name'),
              SizedBox(height: sh * 0.006),
              _SheetField(sw: sw, ctrl: _nameCtrl, hint: 'Enter full name',
                  icon: Icons.person_outline,
                  validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null),
              SizedBox(height: sh * 0.015),

              _FieldLabel(sw: sw, label: 'Email'),
              SizedBox(height: sh * 0.006),
              _SheetField(sw: sw, ctrl: _emailCtrl, hint: 'Enter email',
                  icon: Icons.email_outlined,
                  keyboard: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (!v.contains('@')) return 'Invalid email';
                    return null;
                  }),
              SizedBox(height: sh * 0.015),

              _FieldLabel(sw: sw, label: 'Phone'),
              SizedBox(height: sh * 0.006),
              _SheetField(sw: sw, ctrl: _phoneCtrl, hint: 'Enter phone',
                  icon: Icons.phone_outlined,
                  keyboard: TextInputType.phone,
                  digitsOnly: true,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Required';
                    if (v.length != 10) return 'Enter 10-digit number';
                    return null;
                  }),
              SizedBox(height: sh * 0.015),

              _FieldLabel(sw: sw, label: 'Role'),
              SizedBox(height: sh * 0.006),
              GestureDetector(
                onTap: _showRolePicker,
                child: Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.04, vertical: sw * 0.035),
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(sw * 0.028),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.work_outline_rounded,
                          size: sw * 0.045,
                          color: _selectedRole != null ? _kBlue : _kMuted),
                      SizedBox(width: sw * 0.025),
                      Expanded(
                        child: Text(
                          _selectedRole != null
                              ? _selectedRole!
                              .replaceAll('ROLE_', '')
                              .replaceAll('_', ' ')
                              : 'Select role',
                          style: TextStyle(
                              fontSize: sw * 0.036,
                              fontWeight: FontWeight.w600,
                              color: _selectedRole != null ? _kDark : _kMuted),
                        ),
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: _kMuted, size: sw * 0.05),
                    ],
                  ),
                ),
              ),

              SizedBox(height: sh * 0.025),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.pop(context);
                        await widget.onSave(
                          _nameCtrl.text.trim(),
                          _emailCtrl.text.trim(),
                          _phoneCtrl.text.trim(),
                          _selectedRole,
                        );
                      },
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit Address Sheet ───────────────────────────────────────────────────────
class _EditAddressSheet extends StatefulWidget {
  final UserModel user;
  final Future<void> Function(String address) onSave;

  const _EditAddressSheet({required this.user, required this.onSave});

  @override
  State<_EditAddressSheet> createState() => _EditAddressSheetState();
}

class _EditAddressSheetState extends State<_EditAddressSheet> {
  late final TextEditingController _addressCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _addressCtrl = TextEditingController(text: widget.user.address);
  }

  @override
  void dispose() {
    _addressCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 18),
                  decoration: BoxDecoration(
                      color: _kBorder, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Text('Edit Address',
                  style: TextStyle(
                      fontSize: sw * 0.045,
                      fontWeight: FontWeight.w800,
                      color: _kDark)),
              Text(widget.user.employeeName,
                  style: const TextStyle(
                      fontSize: 12, color: _kMuted, fontWeight: FontWeight.w500)),
              SizedBox(height: sw * 0.05),

              _FieldLabel(sw: sw, label: 'Street Address'),
              SizedBox(height: sh * 0.006),
              _SheetField(
                sw: sw, ctrl: _addressCtrl,
                hint: 'Enter full address',
                icon: Icons.home_outlined,
                maxLines: 3,
                validator: (v) =>
                v == null || v.trim().isEmpty ? 'Required' : null,
              ),

              SizedBox(height: sh * 0.025),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
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
                      onPressed: () async {
                        if (!_formKey.currentState!.validate()) return;
                        Navigator.pop(context);
                        await widget.onSave(_addressCtrl.text.trim());
                      },
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Small reusable sheet sub-widgets ────────────────────────────────────────
class _FieldLabel extends StatelessWidget {
  final double sw;
  final String label;
  const _FieldLabel({required this.sw, required this.label});

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(
        fontSize: sw * 0.028,
        fontWeight: FontWeight.w700,
        color: _kMuted,
        letterSpacing: 0.5),
  );
}

class _SheetField extends StatelessWidget {
  final double sw;
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final TextInputType keyboard;
  final bool digitsOnly;
  final int maxLines;
  final String? Function(String?)? validator;

  const _SheetField({
    required this.sw,
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.keyboard = TextInputType.text,
    this.digitsOnly = false,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboard,
      maxLines: maxLines,
      inputFormatters:
      digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
      validator: validator,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      style: const TextStyle(
          fontSize: 14, color: _kDark, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(
            fontSize: 13, color: _kMuted, fontWeight: FontWeight.w400),
        prefixIcon: Icon(icon, color: _kMuted, size: sw * 0.045),
        filled: true,
        fillColor: _kBg,
        contentPadding: EdgeInsets.symmetric(
            horizontal: sw * 0.04,
            vertical: maxLines > 1 ? sw * 0.035 : 0),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.028),
            borderSide: const BorderSide(color: _kBorder)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.028),
            borderSide: const BorderSide(color: _kBorder)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.028),
            borderSide: const BorderSide(color: _kBlue, width: 1.5)),
        errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.028),
            borderSide: const BorderSide(color: _kRed)),
        focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(sw * 0.028),
            borderSide: const BorderSide(color: _kRed, width: 1.5)),
      ),
    );
  }
}