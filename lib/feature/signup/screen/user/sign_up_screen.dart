import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../../../core/media_query/media_query.dart';
import '../../../../widgets/circle_button.dart';
import '../../controller/signUp_controller.dart';
import '../../../../model/user_model.dart';

// ─── Constants (same as dealer screen) ───────────────────────────────────────
const _kBlue       = Color(0xFF1B4FD8);
const _kBlueBg     = Color(0xFFEEF2FF);
const _kBlueBorder = Color(0xFFC7D4FF);
const _kBg         = Color(0xFFF2F4F8);
const _kCard       = Colors.white;
const _kBorder     = Color(0xFFE5E7EB);
const _kDark       = Color(0xFF111827);
const _kMuted      = Color(0xFF9CA3AF);
const _kRed        = Color(0xFFDC2626);

const _roles = [
  'ROLE_ADMIN',
  'ROLE_SALESMAN',
  'ROLE_PRODUCTION',
  'ROLE_PACKING',
  'ROLE_ACCOUNTS',
  'ROLE_DELIVERY',
];

String _displayRole(String role) =>
    role.replaceAll('ROLE_', '').replaceAll('_', ' ');

// ─── Screen ───────────────────────────────────────────────────────────────────
class AddUserScreen extends ConsumerStatefulWidget {
  const AddUserScreen({super.key});

  @override
  ConsumerState<AddUserScreen> createState() => _AddUserScreenState();
}

class _AddUserScreenState extends ConsumerState<AddUserScreen> {
  final _formKey          = GlobalKey<FormState>();
  final _nameCtrl         = TextEditingController();
  final _emailCtrl        = TextEditingController();
  final _phoneCtrl        = TextEditingController();
  final _passwordCtrl     = TextEditingController();
  final _addressCtrl      = TextEditingController();

  String?  _selectedRole;
  File?    _selectedImage;
  bool     _passwordHidden = true;

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
      final file = await ImagePicker().pickImage(
        source: source, maxWidth: 512, maxHeight: 512, imageQuality: 85,
      );
      if (!mounted || file == null) return;
      setState(() => _selectedImage = File(file.path));
    } catch (e) {
      if (!mounted) return;
      _showSnack('Error picking image: $e', _kRed);
    }
  }

  void _showPhotoPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
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
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.camera); },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kBlue),
              title: const Text('Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () { Navigator.pop(context); _pickImage(ImageSource.gallery); },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: _kRed),
                title: const Text('Remove Photo',
                    style: TextStyle(fontWeight: FontWeight.w600, color: _kRed)),
                onTap: () {
                  Navigator.pop(context);
                  setState(() => _selectedImage = null);
                },
              ),
          ],
        ),
      ),
    );
  }

  // ── Role sheet ──────────────────────────────────────────────────────────────
  void _showRoleSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        // pushes sheet up when keyboard is open (not needed here but good practice)
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Handle + title ──────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 0),
              child: Column(
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
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _kDark)),
                  const SizedBox(height: 14),
                ],
              ),
            ),

            // ── Scrollable roles list ───────────────
            ConstrainedBox(
              constraints: BoxConstraints(
                // never taller than 55% of screen
                maxHeight: MediaQuery.of(context).size.height * 0.55,
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: _roles.map((role) {
                    final isSelected = _selectedRole == role;
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
                          color: isSelected ? _kBlueBg : _kBg,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: isSelected ? _kBlueBorder : _kBorder,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                _displayRole(role),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: isSelected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? _kBlue
                                      : const Color(0xFF374151),
                                ),
                              ),
                            ),
                            if (isSelected)
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

  // ── Submit ──────────────────────────────────────────────────────────────────
  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
      const Center(child: CircularProgressIndicator(color: _kBlue)),
    );

    final error = await ref.read(signupControllerProvider.notifier).signup(
      UserModel(
        employeeName: _nameCtrl.text.trim(),
        employeeEmail: _emailCtrl.text.trim(),
        employeePhone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        address: _addressCtrl.text.trim(),
        role: _selectedRole!,
        photo: _selectedImage?.path ?? '',
      ),
      photoFile: _selectedImage,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (error != null) {
      _showSnack(error, _kRed);
    } else {
      _showSnack('User created successfully!', Colors.green);
      Navigator.pop(context);
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

  // ── Build ───────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

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
                  Text('Add User',
                      style: TextStyle(
                          fontSize: sw * 0.042,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                          letterSpacing: -0.2)),
                  const Spacer(),
                  SizedBox(width: sw * 0.095),
                ],
              ),
            ),

            // ── Form ─────────────────────────────────
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  padding:
                  EdgeInsets.symmetric(horizontal: sw * 0.038),
                  child: Column(
                    children: [
                      // Photo
                      _buildPhotoSection(sw, sh),
                      SizedBox(height: sh * 0.012),

                      // Personal Info
                      _SectionCard(
                        icon: Icons.person_outline_rounded,
                        title: 'Personal Info',
                        children: [
                          _buildField(
                            sw: sw, sh: sh,
                            label: 'Full Name',
                            hint: 'Enter full name',
                            controller: _nameCtrl,
                            icon: Icons.person_outline,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Name is required' : null,
                          ),
                          _buildField(
                            sw: sw, sh: sh,
                            label: 'Email',
                            hint: 'Enter email address',
                            controller: _emailCtrl,
                            icon: Icons.email_outlined,
                            keyboard: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          _buildField(
                            sw: sw, sh: sh,
                            label: 'Phone',
                            hint: 'Enter phone number',
                            controller: _phoneCtrl,
                            icon: Icons.phone_outlined,
                            keyboard: TextInputType.phone,
                            digitsOnly: true,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Phone is required';
                              if (v.length != 10) return 'Enter a valid 10-digit number';
                              return null;
                            },
                          ),
                          // Password field
                          _buildFieldLabel(sw, 'Password'),
                          SizedBox(height: sh * 0.006),
                          TextFormField(
                            controller: _passwordCtrl,
                            obscureText: _passwordHidden,
                            autovalidateMode: AutovalidateMode.onUserInteraction,
                            style: TextStyle(
                                fontSize: sw * 0.036,
                                color: _kDark,
                                fontWeight: FontWeight.w500),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Password is required';
                              if (v.length < 6) return 'At least 6 characters';
                              return null;
                            },
                            decoration: InputDecoration(
                              hintText: 'Enter password',
                              hintStyle: TextStyle(
                                  fontSize: sw * 0.034,
                                  color: _kMuted,
                                  fontWeight: FontWeight.w400),
                              prefixIcon: Icon(Icons.lock_outline_rounded,
                                  color: _kMuted, size: sw * 0.045),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _passwordHidden
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: _kMuted,
                                  size: sw * 0.045,
                                ),
                                onPressed: () => setState(
                                        () => _passwordHidden = !_passwordHidden),
                              ),
                              filled: true,
                              fillColor: _kBg,
                              contentPadding: EdgeInsets.symmetric(
                                  horizontal: sw * 0.04),
                              border: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(sw * 0.028),
                                borderSide:
                                const BorderSide(color: _kBorder),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(sw * 0.028),
                                borderSide:
                                const BorderSide(color: _kBorder),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(sw * 0.028),
                                borderSide: const BorderSide(
                                    color: _kBlue, width: 1.5),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(sw * 0.028),
                                borderSide:
                                const BorderSide(color: _kRed),
                              ),
                              focusedErrorBorder: OutlineInputBorder(
                                borderRadius:
                                BorderRadius.circular(sw * 0.028),
                                borderSide: const BorderSide(
                                    color: _kRed, width: 1.5),
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: sh * 0.012),

                      // Address
                      _SectionCard(
                        icon: Icons.home_outlined,
                        title: 'Address',
                        children: [
                          _buildField(
                            sw: sw, sh: sh,
                            label: 'Street Address',
                            hint: 'Enter full address',
                            controller: _addressCtrl,
                            icon: Icons.location_on_outlined,
                            maxLines: 3,
                            isLast: true,
                            validator: (v) => v == null || v.trim().isEmpty
                                ? 'Address is required' : null,
                          ),
                        ],
                      ),
                      SizedBox(height: sh * 0.012),

                      // Role
                      _SectionCard(
                        icon: Icons.badge_outlined,
                        title: 'Role',
                        children: [
                          _buildFieldLabel(sw, 'Assign Role'),
                          SizedBox(height: sh * 0.006),
                          GestureDetector(
                            onTap: _showRoleSheet,
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  horizontal: sw * 0.04,
                                  vertical: sw * 0.035),
                              decoration: BoxDecoration(
                                color: _kBg,
                                borderRadius:
                                BorderRadius.circular(sw * 0.028),
                                border: Border.all(color: _kBorder),
                              ),
                              child: Row(
                                children: [
                                  Icon(Icons.work_outline_rounded,
                                      size: sw * 0.045,
                                      color: _selectedRole != null
                                          ? _kBlue
                                          : _kMuted),
                                  SizedBox(width: sw * 0.025),
                                  Expanded(
                                    child: Text(
                                      _selectedRole != null
                                          ? _displayRole(_selectedRole!)
                                          : 'Select role',
                                      style: TextStyle(
                                          fontSize: sw * 0.036,
                                          fontWeight: _selectedRole != null
                                              ? FontWeight.w600
                                              : FontWeight.w400,
                                          color: _selectedRole != null
                                              ? _kDark
                                              : _kMuted),
                                    ),
                                  ),
                                  Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: _kMuted,
                                      size: sw * 0.05),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      SizedBox(height: sh * 0.025),

                      // Submit
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _kBlue,
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(
                                vertical: sh * 0.018),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(sw * 0.035),
                            ),
                            elevation: 0,
                          ),
                          child: Text('Add User',
                              style: TextStyle(
                                  fontSize: sw * 0.04,
                                  fontWeight: FontWeight.w700)),
                        ),
                      ),

                      SizedBox(height: sh * 0.03),
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

  // ── Photo Section ───────────────────────────────────────────────────────────
  Widget _buildPhotoSection(double sw, double sh) {
    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: _kBorder),
      ),
      child: Row(
        children: [
          GestureDetector(
            onTap: _showPhotoPicker,
            child: Stack(
              children: [
                CircleAvatar(
                  radius: sw * 0.085,
                  backgroundColor: _kBlueBg,
                  backgroundImage: _selectedImage != null
                      ? FileImage(_selectedImage!) : null,
                  child: _selectedImage == null
                      ? Icon(Icons.person_outline_rounded,
                      size: sw * 0.09, color: _kBlue)
                      : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: sw * 0.062, height: sw * 0.062,
                    decoration: BoxDecoration(
                      color: _kBlue, shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                    child: Icon(Icons.camera_alt_outlined,
                        color: Colors.white, size: sw * 0.032),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: sw * 0.04),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Profile Photo',
                    style: TextStyle(
                        fontSize: sw * 0.038,
                        fontWeight: FontWeight.w700,
                        color: _kDark)),
                SizedBox(height: sh * 0.005),
                Text(
                  _selectedImage != null
                      ? 'Tap to change photo'
                      : 'Tap to add a photo',
                  style: TextStyle(
                      fontSize: sw * 0.031,
                      color: _kMuted,
                      fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Field helpers ───────────────────────────────────────────────────────────
  Widget _buildFieldLabel(double sw, String label) {
    return Text(
      label.toUpperCase(),
      style: TextStyle(
          fontSize: sw * 0.028,
          fontWeight: FontWeight.w700,
          color: _kMuted,
          letterSpacing: 0.5),
    );
  }

  Widget _buildField({
    required double sw,
    required double sh,
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboard = TextInputType.text,
    bool digitsOnly = false,
    int maxLines = 1,
    bool isLast = false,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : sh * 0.015),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFieldLabel(sw, label),
          SizedBox(height: sh * 0.006),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            maxLines: maxLines,
            inputFormatters:
            digitsOnly ? [FilteringTextInputFormatter.digitsOnly] : null,
            validator: validator,
            autovalidateMode: AutovalidateMode.onUserInteraction,
            style: TextStyle(
                fontSize: sw * 0.036,
                color: _kDark,
                fontWeight: FontWeight.w500),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  fontSize: sw * 0.034,
                  color: _kMuted,
                  fontWeight: FontWeight.w400),
              prefixIcon: Icon(icon, color: _kMuted, size: sw * 0.045),
              filled: true,
              fillColor: _kBg,
              contentPadding: EdgeInsets.symmetric(
                  horizontal: sw * 0.04,
                  vertical: maxLines > 1 ? sw * 0.035 : 0),
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
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kRed),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kRed, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Section Card (shared pattern) ───────────────────────────────────────────
class _SectionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final List<Widget> children;

  const _SectionCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: const Color(0xFFE5E7EB)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(
              children: [
                Container(
                  width: sw * 0.075, height: sw * 0.075,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF2F4F8),
                    borderRadius: BorderRadius.circular(sw * 0.022),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Icon(icon, size: sw * 0.04,
                      color: const Color(0xFF111827)),
                ),
                SizedBox(width: sw * 0.025),
                Text(title,
                    style: TextStyle(
                        fontSize: sw * 0.036,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF111827))),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: Color(0xFFE5E7EB)),
          Padding(
            padding: EdgeInsets.all(sw * 0.04),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}