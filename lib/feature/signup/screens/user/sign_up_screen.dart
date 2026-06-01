import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../widgets/circle_button.dart';
import '../../controller/signup_controller.dart';
import '../../model/user_model.dart';

// ── Zoho Books design tokens (mirrored from AddDealerScreen) ──────────────────
const _kP        = Color(0xFF185FA5);
const _kPBg      = Color(0xFFEBF4FF);
const _kBg       = Color(0xFFF7F8FA);
const _kWhite    = Colors.white;
const _kBd       = Color(0xFFE5E7EB);
const _kT1       = Color(0xFF111827);
const _kT2       = Color(0xFF374151);
const _kT4       = Color(0xFF9CA3AF);
const _kGreen    = Color(0xFF0F6E56);
const _kRed      = Color(0xFFDC2626);
const _kPurple   = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBd = Color(0xFFDDD6FE);

const _roles = [
  'ROLE_ADMIN',
  'ROLE_SALESMAN',
  'ROLE_PRODUCTION',
  'ROLE_PACKING',
  'ROLE_ACCOUNTS',
  'ROLE_DELIVERY',
  'ROLE_MANAGER',
];

String _displayRole(String role) =>
    role.replaceAll('ROLE_', '').replaceAll('_', ' ');

// ─────────────────────────────────────────────────────────────────────────────
class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _formKey      = GlobalKey<FormState>();
  final _nameCtrl     = TextEditingController();
  final _emailCtrl    = TextEditingController();
  final _phoneCtrl    = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _addressCtrl  = TextEditingController();

  String? _selectedRole;
  File?   _photo;
  bool    _passwordHidden = true;

  @override
  void initState() {
    super.initState();
    _selectedRole = _roles.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Image pick ──────────────────────────────────────────────────────────────
  Future<void> _pickImage(ImageSource source) async {
    try {
      final f = await ImagePicker().pickImage(
          source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85);
      if (!mounted || f == null) return;
      setState(() => _photo = File(f.path));
    } catch (e) {
      if (mounted) _snack('Error picking image: $e', _kRed);
    }
  }

  void _showPhotoPicker() {
    final sw = MediaQuery.sizeOf(context).width;
    showModalBottomSheet(
      context: context,
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          _handle(),
          ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _kP),
              title: const Text('Camera',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              }),
          ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kP),
              title: const Text('Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              }),
          if (_photo != null)
            ListTile(
                leading:
                const Icon(Icons.delete_outline_rounded, color: _kRed),
                title: const Text('Remove Photo',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: _kRed)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _photo = null);
                }),
        ]),
      ),
    );
  }

  // ── Role sheet ──────────────────────────────────────────────────────────────
  void _showRoleSheet() {
    final sw = MediaQuery.sizeOf(context).width;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _kWhite,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
              top: Radius.circular((sw * 0.05).clamp(14.0, 22.0)))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.fromLTRB(
                  sw * 0.05, sw * 0.04, sw * 0.05, 0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _handle(),
                    Text('Select Role',
                        style: TextStyle(
                            fontSize:   (sw * 0.042).clamp(14.0, 19.0),
                            fontWeight: FontWeight.w800,
                            color:      _kT1)),
                    SizedBox(height: sw * 0.008),
                    Text('Assign a role for this user',
                        style: TextStyle(
                            fontSize: (sw * 0.03).clamp(10.0, 13.0),
                            color:    _kT4)),
                    SizedBox(height: sw * 0.035),
                  ]),
            ),
            ConstrainedBox(
              constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.55),
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                    sw * 0.05, 0, sw * 0.05, sw * 0.06),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _roles.map((role) {
                    final sel = _selectedRole == role;
                    return GestureDetector(
                      onTap: () {
                        setState(() => _selectedRole = role);
                        Navigator.pop(context);
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        margin:   EdgeInsets.only(bottom: sw * 0.02),
                        padding:  EdgeInsets.symmetric(
                            horizontal: sw * 0.04,
                            vertical:   sw * 0.032),
                        decoration: BoxDecoration(
                          color:        sel ? _kPurpleBg : _kBg,
                          borderRadius: BorderRadius.circular(
                              (sw * 0.028).clamp(8.0, 12.0)),
                          border: Border.all(
                              color: sel ? _kPurpleBd : _kBd,
                              width: sel ? 1.0 : 0.5),
                        ),
                        child: Row(children: [
                          Expanded(
                            child: Text(_displayRole(role),
                                style: TextStyle(
                                    fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                                    fontWeight: sel
                                        ? FontWeight.w700
                                        : FontWeight.w500,
                                    color: sel ? _kPurple : _kT2)),
                          ),
                          if (sel)
                            Icon(Icons.check_circle_rounded,
                                color: _kPurple,
                                size: (sw * 0.045).clamp(15.0, 20.0)),
                        ]),
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

  // ── Submit ──────────────────────────────────────────────────────────────────
  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
          child: CircularProgressIndicator(color: _kP, strokeWidth: 2.5)),
    );

    final error =
    await ref.read(signupControllerProvider.notifier).signup(
      UserModel(
        employeeName:  _nameCtrl.text.trim(),
        employeeEmail: _emailCtrl.text.trim(),
        employeePhone: _phoneCtrl.text.trim(),
        password:      _passwordCtrl.text,
        address:       _addressCtrl.text.trim(),
        role:          _selectedRole!,
        photo:         _photo?.path ?? '',
      ),
      photoFile: _photo,
    );

    if (!mounted) return;
    Navigator.pop(context); // dismiss loader

    if (error != null) {
      _snack(error, _kRed);
    } else {
      _snack('User created successfully!', _kGreen);
      Navigator.pop(context);
    }
  }

  void _snack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape:
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw = MediaQuery.sizeOf(context).width;
    final sh = MediaQuery.sizeOf(context).height;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(child: Column(children: [

        // ── App Bar ────────────────────────────────────────────────────
        Container(
          color:   _kWhite,
          padding: EdgeInsets.fromLTRB(
              sw * 0.04, sh * 0.015, sw * 0.04, sh * 0.015),
          child: Row(children: [
            CircularIconButton(
                icon: Icons.arrow_back_ios_rounded,
                onTap: () => Navigator.pop(context)),
            const Spacer(),
            Text('Add User',
                style: TextStyle(
                    fontSize:     (sw * 0.042).clamp(14.0, 20.0),
                    fontWeight:   FontWeight.w700,
                    color:        _kT1,
                    letterSpacing: -0.2)),
            const Spacer(),
            SizedBox(width: (sw * 0.095).clamp(32.0, 44.0)),
          ]),
        ),

        // ── Form ───────────────────────────────────────────────────────
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                  sw * 0.038, sh * 0.012, sw * 0.038, sh * 0.04),
              child: Column(children: [

                // Photo
                _photoSection(sw, sh),
                SizedBox(height: sh * 0.012),

                // Personal Info
                _Sec(
                  sw: sw, icon: Icons.person_outline_rounded,
                  title: 'Personal Info',
                  child: Column(children: [
                    _field(sw, sh, 'Full Name', 'Enter full name',
                        _nameCtrl, Icons.person_outline,
                        validator: (v) => v == null || v.trim().isEmpty
                            ? 'Name is required'
                            : null),
                    _field(sw, sh, 'Email', 'Enter email address',
                        _emailCtrl, Icons.email_outlined,
                        keyboard: TextInputType.emailAddress,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!v.contains('@')) return 'Enter a valid email';
                          return null;
                        }),
                    _field(sw, sh, 'Phone', 'Enter phone number',
                        _phoneCtrl, Icons.phone_outlined,
                        keyboard:   TextInputType.phone,
                        digitsOnly: true,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone is required';
                          }
                          if (v.length != 10) {
                            return 'Enter a valid 10-digit number';
                          }
                          return null;
                        }),
                    // Password
                    _lbl(sw, 'Password'),
                    SizedBox(height: sh * 0.006),
                    TextFormField(
                      controller:       _passwordCtrl,
                      obscureText:      _passwordHidden,
                      autovalidateMode: AutovalidateMode.onUserInteraction,
                      style: TextStyle(
                          fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                          color:      _kT1,
                          fontWeight: FontWeight.w500),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) return 'At least 6 characters';
                        return null;
                      },
                      decoration: _inputDeco(
                        sw, 'Enter password',
                        prefix: Icon(Icons.lock_outline_rounded,
                            color: _kT4,
                            size: (sw * 0.045).clamp(15.0, 20.0)),
                        suffix: IconButton(
                          icon: Icon(
                              _passwordHidden
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: _kT4,
                              size: (sw * 0.045).clamp(15.0, 20.0)),
                          onPressed: () => setState(
                                  () => _passwordHidden = !_passwordHidden),
                        ),
                      ),
                    ),
                  ]),
                ),
                SizedBox(height: sh * 0.012),

                // Address
                _Sec(
                  sw: sw, icon: Icons.home_outlined,
                  title: 'Address',
                  child: _field(
                    sw, sh, 'Street Address', 'Enter full address',
                    _addressCtrl, Icons.location_on_outlined,
                    maxLines: 3, isLast: true,
                    validator: (v) => v == null || v.trim().isEmpty
                        ? 'Address is required'
                        : null,
                  ),
                ),
                SizedBox(height: sh * 0.012),

                // Role
                _Sec(
                  sw: sw, icon: Icons.badge_outlined, title: 'Role',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _lbl(sw, 'Assign Role'),
                      SizedBox(height: sh * 0.006),
                      GestureDetector(
                        onTap: _showRoleSheet,
                        child: Container(
                          padding: EdgeInsets.symmetric(
                              horizontal: sw * 0.04,
                              vertical:   sw * 0.035),
                          decoration: BoxDecoration(
                            color:        _kBg,
                            borderRadius: BorderRadius.circular(
                                (sw * 0.028).clamp(8.0, 12.0)),
                            border: Border.all(
                                color: _selectedRole != null
                                    ? _kPurpleBd
                                    : _kBd,
                                width: _selectedRole != null ? 1.0 : 0.5),
                          ),
                          child: Row(children: [
                            Icon(Icons.work_outline_rounded,
                                size:  (sw * 0.045).clamp(15.0, 20.0),
                                color: _selectedRole != null
                                    ? _kPurple
                                    : _kT4),
                            SizedBox(width: sw * 0.025),
                            Expanded(
                              child: Text(
                                  _selectedRole != null
                                      ? _displayRole(_selectedRole!)
                                      : 'Select role',
                                  style: TextStyle(
                                      fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                                      fontWeight: _selectedRole != null
                                          ? FontWeight.w600
                                          : FontWeight.w400,
                                      color: _selectedRole != null
                                          ? _kT1
                                          : _kT4)),
                            ),
                            Icon(Icons.keyboard_arrow_down_rounded,
                                color: _kT4,
                                size: (sw * 0.05).clamp(16.0, 22.0)),
                          ]),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: sh * 0.025),

                // Submit
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _handleSubmit,
                    style: ElevatedButton.styleFrom(
                        backgroundColor: _kP,
                        foregroundColor: _kWhite,
                        padding: EdgeInsets.symmetric(
                            vertical: sh * 0.018),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                                (sw * 0.035).clamp(10.0, 16.0))),
                        elevation: 0),
                    child: Text('Add User',
                        style: TextStyle(
                            fontSize:   (sw * 0.04).clamp(13.0, 18.0),
                            fontWeight: FontWeight.w700)),
                  ),
                ),
                SizedBox(height: sh * 0.03),
              ]),
            ),
          ),
        ),
      ])),
    );
  }

  // ── Photo section ───────────────────────────────────────────────────────────
  Widget _photoSection(double sw, double sh) => Container(
    padding: EdgeInsets.all(sw * 0.04),
    decoration: BoxDecoration(
        color:        _kWhite,
        borderRadius: BorderRadius.circular(
            (sw * 0.04).clamp(10.0, 18.0)),
        border: Border.all(color: _kBd, width: 0.5)),
    child: Row(children: [
      GestureDetector(
        onTap: _showPhotoPicker,
        child: Stack(children: [
          CircleAvatar(
            radius:          (sw * 0.085).clamp(30.0, 40.0),
            backgroundColor: _kPBg,
            backgroundImage:
            _photo != null ? FileImage(_photo!) : null,
            child: _photo == null
                ? Icon(Icons.person_outline_rounded,
                size:  (sw * 0.09).clamp(30.0, 42.0),
                color: _kP)
                : null,
          ),
          Positioned(
            bottom: 0, right: 0,
            child: Container(
              width:  (sw * 0.06).clamp(20.0, 28.0),
              height: (sw * 0.06).clamp(20.0, 28.0),
              decoration: BoxDecoration(
                  color:  _kP,
                  shape:  BoxShape.circle,
                  border: Border.all(color: _kWhite, width: 2)),
              child: Icon(Icons.camera_alt_outlined,
                  color: _kWhite,
                  size:  (sw * 0.03).clamp(10.0, 14.0)),
            ),
          ),
        ]),
      ),
      SizedBox(width: sw * 0.04),
      Expanded(
        child: Column(
            crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Profile Photo',
              style: TextStyle(
                  fontSize:   (sw * 0.038).clamp(13.0, 17.0),
                  fontWeight: FontWeight.w700,
                  color:      _kT1)),
          SizedBox(height: sh * 0.005),
          Text(_photo != null ? 'Tap to change' : 'Tap to add a photo',
              style: TextStyle(
                  fontSize: (sw * 0.031).clamp(10.5, 14.0),
                  color:    _kT4)),
        ]),
      ),
    ]),
  );

  // ── Field helpers ───────────────────────────────────────────────────────────
  Widget _lbl(double sw, String t) => Text(t.toUpperCase(),
      style: TextStyle(
          fontSize:   (sw * 0.028).clamp(9.5, 12.5),
          fontWeight: FontWeight.w700,
          color:      _kT4,
          letterSpacing: 0.5));

  Widget _field(
      double sw, double sh, String label, String hint,
      TextEditingController ctrl, IconData icon, {
        TextInputType keyboard    = TextInputType.text,
        bool          digitsOnly  = false,
        int           maxLines    = 1,
        bool          isLast      = false,
        String? Function(String?)? validator,
      }) =>
      Padding(
        padding: EdgeInsets.only(bottom: isLast ? 0 : sh * 0.015),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          _lbl(sw, label),
          SizedBox(height: sh * 0.006),
          TextFormField(
            controller:       ctrl,
            keyboardType:     keyboard,
            maxLines:         maxLines,
            inputFormatters:  digitsOnly
                ? [FilteringTextInputFormatter.digitsOnly]
                : null,
            validator:        validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
                fontSize:   (sw * 0.036).clamp(12.0, 16.0),
                color:      _kT1,
                fontWeight: FontWeight.w500),
            decoration: _inputDeco(sw, hint,
                prefix:   Icon(icon, color: _kT4,
                    size: (sw * 0.045).clamp(15.0, 20.0)),
                maxLines: maxLines),
          ),
        ]),
      );

  InputDecoration _inputDeco(double sw, String hint,
      {Widget? prefix, Widget? suffix, int maxLines = 1}) {
    final r = (sw * 0.028).clamp(8.0, 12.0);
    return InputDecoration(
      hintText:   hint,
      hintStyle:  TextStyle(
          fontSize:   (sw * 0.034).clamp(11.5, 15.0), color: _kT4),
      prefixIcon:  prefix,
      suffixIcon:  suffix,
      filled:      true,
      fillColor:   _kBg,
      contentPadding: EdgeInsets.symmetric(
          horizontal: sw * 0.04,
          vertical:   maxLines > 1 ? sw * 0.035 : 0),
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide:   const BorderSide(color: _kBd, width: 0.5)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide:   const BorderSide(color: _kBd, width: 0.5)),
      focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kP, width: 1.5)),
      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide:   const BorderSide(color: _kRed)),
      focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(r),
          borderSide: const BorderSide(color: _kRed, width: 1.5)),
    );
  }
}

// ── Handle ────────────────────────────────────────────────────────────────────
Widget _handle() => Center(
  child: Container(
    width: 36, height: 4,
    margin: const EdgeInsets.only(bottom: 16),
    decoration: BoxDecoration(
        color: _kBd, borderRadius: BorderRadius.circular(2)),
  ),
);

// ── Section card — identical to _Sec in AddDealerScreen ──────────────────────
class _Sec extends StatelessWidget {
  const _Sec({
    required this.sw,
    required this.icon,
    required this.title,
    required this.child,
  });
  final double   sw;
  final IconData icon;
  final String   title;
  final Widget   child;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
        color:        _kWhite,
        borderRadius: BorderRadius.circular(
            (sw * 0.04).clamp(10.0, 18.0)),
        border: Border.all(color: _kBd, width: 0.5)),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(
              horizontal: sw * 0.04, vertical: sw * 0.035),
          child: Row(children: [
            Container(
              width:  (sw * 0.075).clamp(26.0, 36.0),
              height: (sw * 0.075).clamp(26.0, 36.0),
              decoration: BoxDecoration(
                  color:        _kBg,
                  borderRadius: BorderRadius.circular(
                      (sw * 0.022).clamp(6.0, 10.0))),
              child: Icon(icon,
                  size:  (sw * 0.04).clamp(14.0, 20.0),
                  color: _kT1),
            ),
            SizedBox(width: sw * 0.025),
            Text(title,
                style: TextStyle(
                    fontSize:   (sw * 0.035).clamp(12.0, 16.0),
                    fontWeight: FontWeight.w700,
                    color:      _kT1)),
          ]),
        ),
        Divider(height: 1, color: _kBd),
        Padding(
            padding: EdgeInsets.all(sw * 0.04), child: child),
      ],
    ),
  );
}