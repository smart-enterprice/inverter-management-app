import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:shimmer/shimmer.dart';

import '../../../../core/media_query/media_query.dart';
import '../../../../model/user_model.dart';
import '../../../../widgets/circle_button.dart';
import '../../../brand/controller/brand_controller.dart';
import '../../controller/signUp_controller.dart';

// ─── Constants ──────────────────────────────────────────────────────────────
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

const _keralaDistricts = [
  'Kasaragod', 'Kannur', 'Wayanad', 'Kozhikode', 'Malappuram',
  'Palakkad', 'Thrissur', 'Ernakulam', 'Idukki', 'Kottayam',
  'Alappuzha', 'Pathanamthitta', 'Kollam', 'Thiruvananthapuram',
];

// ─── Screen ──────────────────────────────────────────────────────────────────
class AddDealerScreen extends ConsumerStatefulWidget {
  const AddDealerScreen({super.key});

  @override
  ConsumerState<AddDealerScreen> createState() => _AddDealerScreenState();
}

class _AddDealerScreenState extends ConsumerState<AddDealerScreen> {
  final _formKey        = GlobalKey<FormState>();
  final _nameCtrl       = TextEditingController();
  final _emailCtrl      = TextEditingController();
  final _phoneCtrl      = TextEditingController();
  final _shopCtrl       = TextEditingController();
  final _townCtrl       = TextEditingController();
  final _addressCtrl    = TextEditingController();

  String?      _selectedDistrict;
  File?        _selectedImage;
  List<String> _selectedBrands = [];   // stores brandId strings

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _shopCtrl.dispose();
    _townCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
  }

  // ── Image pick ─────────────────────────────────────────────────────────────
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
                color: _kBorder, borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: _kBlue),
              title: const Text('Camera',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: _kBlue),
              title: const Text('Gallery',
                  style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_selectedImage != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded,
                    color: _kRed),
                title: const Text('Remove Photo',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: _kRed)),
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

  // ── District sheet ─────────────────────────────────────────────────────────
  void _showDistrictSheet() {
    String query = '';
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => StatefulBuilder(
        builder: (ctx, setS) {
          final filtered = _keralaDistricts
              .where((d) => d.toLowerCase().contains(query.toLowerCase()))
              .toList();
          return DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.6,
            maxChildSize: 0.85,
            builder: (_, sc) => Padding(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 28),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      margin: const EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: _kBorder,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const Text('Select District',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _kDark)),
                  const SizedBox(height: 2),
                  const Text('Kerala',
                      style: TextStyle(
                          fontSize: 12,
                          color: _kMuted,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 14),
                  // search
                  TextField(
                    onChanged: (v) => setS(() => query = v),
                    style: const TextStyle(
                        fontSize: 13,
                        color: _kDark,
                        fontWeight: FontWeight.w500),
                    decoration: InputDecoration(
                      hintText: 'Search district...',
                      hintStyle: const TextStyle(
                          fontSize: 13,
                          color: _kMuted,
                          fontWeight: FontWeight.w400),
                      prefixIcon: const Icon(Icons.search_rounded,
                          color: _kMuted, size: 20),
                      filled: true,
                      fillColor: _kBg,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 11),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: _kBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                            color: _kBlue, width: 1.5),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.builder(
                      controller: sc,
                      itemCount: filtered.length,
                      itemBuilder: (_, i) {
                        final d = filtered[i];
                        final selected = _selectedDistrict == d;
                        return GestureDetector(
                          onTap: () {
                            setState(() => _selectedDistrict = d);
                            Navigator.pop(context);
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 150),
                            margin: const EdgeInsets.only(bottom: 4),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 13),
                            decoration: BoxDecoration(
                              color: selected ? _kBlueBg : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? _kBlueBorder
                                    : Colors.transparent,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(d,
                                      style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: selected
                                              ? FontWeight.w700
                                              : FontWeight.w500,
                                          color: selected ? _kBlue : _kMid)),
                                ),
                                if (selected)
                                  const Icon(Icons.check_rounded,
                                      color: _kBlue, size: 18),
                              ],
                            ),
                          ),
                        );
                      },
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

  // ── Submit ─────────────────────────────────────────────────────────────────
  void _handleSubmit() async {
    if (_selectedBrands.isEmpty) {
      _showSnack('Please select at least one brand', _kRed);
      return;
    }
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
        password: 'Shahulvm@123',
        address: _addressCtrl.text.trim(),
        role: 'ROLE_DEALER',
        brand: _selectedBrands,
        photo: '',
        town: _townCtrl.text.trim(),
        shopName: _shopCtrl.text.trim(),
        district: _selectedDistrict,
      ),
      photoFile: _selectedImage,
    );

    if (!mounted) return;
    Navigator.pop(context);

    if (error != null) {
      _showSnack(error, _kRed);
    } else {
      _showSnack('Dealer added successfully!', Colors.green);
      ref.invalidate(dealerListProvider);
      Navigator.pop(context);
    }
  }

  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  // ── Build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final brandState = ref.watch(loadBrandsControllerProvider);

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: brandState.when(
          loading: () => _buildShimmer(context, sw, sh),
          error: (e, _) => _buildError(context, sw, sh),
          data: (brands) => Column(
            children: [
              // ── Top Nav ────────────────────────────────
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
                    Text('Add Dealer',
                        style: TextStyle(
                            fontSize: sw * 0.042,
                            fontWeight: FontWeight.w700,
                            color: _kDark,
                            letterSpacing: -0.2)),
                    const Spacer(),
                    // balance space
                    SizedBox(width: sw * 0.095),
                  ],
                ),
              ),

              // ── Form ───────────────────────────────────
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
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
                                  ? 'Name is required'
                                  : null,
                            ),
                            _buildField(
                              sw: sw, sh: sh,
                              label: 'Email',
                              hint: 'Enter email address',
                              controller: _emailCtrl,
                              icon: Icons.email_outlined,
                              keyboard: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Email is required';
                                }
                                if (!v.contains('@')) {
                                  return 'Enter a valid email';
                                }
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
                              isLast: true,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Phone is required';
                                }
                                if (v.length != 10) {
                                  return 'Enter a valid 10-digit number';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        SizedBox(height: sh * 0.012),

                        // Address
                        _SectionCard(
                          icon: Icons.location_on_outlined,
                          title: 'Address',
                          children: [
                            // District picker
                            _buildFieldLabel(sw, 'District'),
                            SizedBox(height: sh * 0.006),
                            GestureDetector(
                              onTap: _showDistrictSheet,
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
                                    Icon(Icons.map_outlined,
                                        size: sw * 0.045,
                                        color: _selectedDistrict != null
                                            ? _kBlue
                                            : _kMuted),
                                    SizedBox(width: sw * 0.025),
                                    Expanded(
                                      child: Text(
                                        _selectedDistrict ?? 'Select district',
                                        style: TextStyle(
                                            fontSize: sw * 0.036,
                                            fontWeight: _selectedDistrict !=
                                                null
                                                ? FontWeight.w600
                                                : FontWeight.w400,
                                            color: _selectedDistrict != null
                                                ? _kDark
                                                : _kMuted),
                                      ),
                                    ),
                                    Icon(Icons.keyboard_arrow_down_rounded,
                                        color: _kMuted, size: sw * 0.05),
                                  ],
                                ),
                              ),
                            ),
                            SizedBox(height: sh * 0.015),

                            // Town + Shop row
                            Row(
                              children: [
                                Expanded(
                                  child: _buildField(
                                    sw: sw, sh: sh,
                                    label: 'Town',
                                    hint: 'Town',
                                    controller: _townCtrl,
                                    icon: Icons.location_city_outlined,
                                    validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                                SizedBox(width: sw * 0.025),
                                Expanded(
                                  child: _buildField(
                                    sw: sw, sh: sh,
                                    label: 'Shop',
                                    hint: 'Shop name',
                                    controller: _shopCtrl,
                                    icon: Icons.storefront_outlined,
                                    validator: (v) =>
                                    v == null || v.trim().isEmpty
                                        ? 'Required'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: sh * 0.002),

                            _buildField(
                              sw: sw, sh: sh,
                              label: 'Street Address',
                              hint: 'Enter full address',
                              controller: _addressCtrl,
                              icon: Icons.home_outlined,
                              maxLines: 3,
                              isLast: true,
                              validator: (v) =>
                              v == null || v.trim().isEmpty
                                  ? 'Address is required'
                                  : null,
                            ),
                          ],
                        ),
                        SizedBox(height: sh * 0.012),

                        // Brands
                        _SectionCard(
                          icon: Icons.local_offer_outlined,
                          title: 'Brands',
                          children: [
                            _buildFieldLabel(sw, 'Select brands'),
                            SizedBox(height: sh * 0.01),
                            Wrap(
                              spacing: sw * 0.02,
                              runSpacing: sw * 0.02,
                              children: brands.map((brand) {
                                final id = brand.brandId.toString();
                                final selected =
                                _selectedBrands.contains(id);
                                return GestureDetector(
                                  onTap: () => setState(() => selected
                                      ? _selectedBrands.remove(id)
                                      : _selectedBrands.add(id)),
                                  child: AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 180),
                                    padding: EdgeInsets.symmetric(
                                        horizontal: sw * 0.03,
                                        vertical: sw * 0.018),
                                    decoration: BoxDecoration(
                                      color: selected
                                          ? _kBlueBg
                                          : _kBg,
                                      borderRadius:
                                      BorderRadius.circular(20),
                                      border: Border.all(
                                        color: selected
                                            ? _kBlueBorder
                                            : _kBorder,
                                        width: 1.5,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          selected
                                              ? Icons.check_circle_rounded
                                              : Icons.add_circle_outline_rounded,
                                          size: sw * 0.038,
                                          color: selected
                                              ? _kBlue
                                              : _kMuted,
                                        ),
                                        SizedBox(width: sw * 0.015),
                                        Text(
                                          brand.brandName,
                                          style: TextStyle(
                                              fontSize: sw * 0.032,
                                              fontWeight: FontWeight.w600,
                                              color: selected
                                                  ? _kBlue
                                                  : _kMuted),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
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
                            child: Text(
                              'Add Dealer',
                              style: TextStyle(
                                  fontSize: sw * 0.04,
                                  fontWeight: FontWeight.w700),
                            ),
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
      ),
    );
  }

  // ── Photo Section ──────────────────────────────────────────────────────────
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
                      ? FileImage(_selectedImage!)
                      : null,
                  child: _selectedImage == null
                      ? Icon(Icons.person_outline_rounded,
                      size: sw * 0.09, color: _kBlue)
                      : null,
                ),
                Positioned(
                  bottom: 0, right: 0,
                  child: Container(
                    width: sw * 0.062,
                    height: sw * 0.062,
                    decoration: BoxDecoration(
                      color: _kBlue,
                      shape: BoxShape.circle,
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

  // ── Field helpers ──────────────────────────────────────────────────────────
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
              prefixIcon:
              Icon(icon, color: _kMuted, size: sw * 0.045),
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
                borderSide:
                const BorderSide(color: _kBlue, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kRed),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide:
                const BorderSide(color: _kRed, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Shimmer ────────────────────────────────────────────────────────────────
  Widget _buildShimmer(BuildContext context, double sw, double sh) {
    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(
          horizontal: sw * 0.038, vertical: sw * 0.04),
      child: Column(
        children: [
          // avatar shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: sw * 0.22,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(sw * 0.04),
              ),
            ),
          ),
          SizedBox(height: sh * 0.015),
          // section shimmers
          ...List.generate(3, (i) => Padding(
            padding: EdgeInsets.only(bottom: sh * 0.015),
            child: Shimmer.fromColors(
              baseColor: Colors.grey.shade300,
              highlightColor: Colors.grey.shade100,
              child: Container(
                height: sh * 0.22,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(sw * 0.04),
                ),
              ),
            ),
          )),
          // button shimmer
          Shimmer.fromColors(
            baseColor: Colors.grey.shade300,
            highlightColor: Colors.grey.shade100,
            child: Container(
              height: sh * 0.065,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(sw * 0.035),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Error ──────────────────────────────────────────────────────────────────
  Widget _buildError(BuildContext context, double sw, double sh) {
    return Column(
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
              Text('Add Dealer',
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
    );
  }
}

// ─── Section Card ─────────────────────────────────────────────────────────────
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // header
          Padding(
            padding: EdgeInsets.symmetric(
                horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(
              children: [
                Container(
                  width: sw * 0.075,
                  height: sw * 0.075,
                  decoration: BoxDecoration(
                    color: _kBg,
                    borderRadius: BorderRadius.circular(sw * 0.022),
                    border: Border.all(color: _kBorder),
                  ),
                  child: Icon(icon, size: sw * 0.04, color: _kDark),
                ),
                SizedBox(width: sw * 0.025),
                Text(title,
                    style: TextStyle(
                        fontSize: sw * 0.036,
                        fontWeight: FontWeight.w700,
                        color: _kDark)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
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