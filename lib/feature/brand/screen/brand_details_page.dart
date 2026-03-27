import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/brand_model.dart';
import '../../../model/user_model.dart';
import '../../../screen/loadingScreen.dart';
import '../../../widgets/circle_button.dart';
import '../../signup/controller/signUp_controller.dart';
import '../controller/brand_controller.dart';

// ─── Constants ────────────────────────────────────────────────────────────────
const _kBlue        = Color(0xFF1B4FD8);
const _kBlueBg      = Color(0xFFEEF2FF);
const _kBlueBorder  = Color(0xFFC7D4FF);
const _kBg          = Color(0xFFF2F4F8);
const _kCard        = Colors.white;
const _kBorder      = Color(0xFFE5E7EB);
const _kDark        = Color(0xFF111827);
const _kMid         = Color(0xFF374151);
const _kMuted       = Color(0xFF9CA3AF);
const _kRed         = Color(0xFFDC2626);
const _kRedBg       = Color(0xFFFEF2F2);
const _kRedBorder   = Color(0xFFFECACA);
const _kGreen       = Color(0xFF0A8A5C);
const _kGreenBg     = Color(0xFFEDFAF4);
const _kGreenBorder = Color(0xFF9FE0C5);
const _kAmber       = Color(0xFFB45309);
const _kAmberBg     = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFCD28A);

class BrandDetailsScreen extends ConsumerWidget {
  final String brandId;
  const BrandDetailsScreen({super.key, required this.brandId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final brandAsync = ref.watch(brandByIdProvider(brandId));

    return brandAsync.when(
      loading: () => const Scaffold(
          backgroundColor: _kBg, body: Center(child: GlobalLoader())),
      error: (e, _) => _BrandErrorScreen(brandId: brandId),
      data: (brand) => _BrandDetailView(brand: brand, brandId: brandId),
    );
  }
}

// ─── Main Detail View ─────────────────────────────────────────────────────────
class _BrandDetailView extends ConsumerStatefulWidget {
  final BrandModel brand;
  final String brandId;
  const _BrandDetailView({required this.brand, required this.brandId});

  @override
  ConsumerState<_BrandDetailView> createState() => _BrandDetailViewState();
}

class _BrandDetailViewState extends ConsumerState<_BrandDetailView> {
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

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final brand = widget.brand;
    final isActive = brand.status?.toLowerCase() == 'active';

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
                    onTap: () {
                      ref.invalidate(loadBrandsControllerProvider);
                      Navigator.pop(context);
                    },
                  ),
                  const Spacer(),
                  Text('Brand Details',
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

            // ── Scrollable body ───────────────────────
            Expanded(
              child: RefreshIndicator(
                color: _kBlue,
                backgroundColor: Colors.white,
                onRefresh: () async =>
                    ref.invalidate(brandByIdProvider(widget.brandId)),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                  child: Column(
                    children: [
                      SizedBox(height: sh * 0.005),

                      // ── Brand header card ──────────────
                      _buildHeaderCard(context, sw, sh, brand),
                      SizedBox(height: sh * 0.012),

                      // ── Status card ────────────────────
                      _buildStatusCard(context, sw, brand, isActive),
                      SizedBox(height: sh * 0.012),

                      // ── Models card ────────────────────
                      _buildModelsCard(context, sw, sh, brand),
                      SizedBox(height: sh * 0.012),

                      // ── Creator card ───────────────────
                      ref
                          .watch(employeeByIdProvider(
                          brand.createdBy ?? ''))
                          .when(
                        data: (user) =>
                            _buildCreatorCard(sw, sh, user),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) =>
                            _buildCreatorCard(sw, sh, null),
                      ),
                      SizedBox(height: sh * 0.012),

                      // ── Date row ───────────────────────
                      RoleGuard(
                        feature: AppFeature.viewTimestamps,
                          child: _buildDateRow(sw, sh, brand)),
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

  // ── Header card ─────────────────────────────────────────────────────────────
  Widget _buildHeaderCard(
      BuildContext context, double sw, double sh, BrandModel brand) {
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
      child: Padding(
        padding: EdgeInsets.all(sw * 0.04),
        child: Row(
          children: [
            Container(
              width: sw * 0.14,
              height: sw * 0.14,
              decoration: BoxDecoration(
                color: _kBlueBg,
                borderRadius: BorderRadius.circular(sw * 0.035),
                border: Border.all(color: _kBlueBorder),
              ),
              child: Center(
                child: SvgPicture.asset(
                  AppIcons.brand,
                  width: sw * 0.07,
                  colorFilter:
                  const ColorFilter.mode(_kBlue, BlendMode.srcIn),
                ),
              ),
            ),
            SizedBox(width: sw * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(brand.brandName,
                      style: TextStyle(
                          fontSize: sw * 0.045,
                          fontWeight: FontWeight.w800,
                          color: _kDark,
                          letterSpacing: -0.3)),
                  SizedBox(height: sw * 0.01),
                  Text(
                    brand.description ?? 'No description',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: sw * 0.031,
                        color: _kMuted,
                        fontWeight: FontWeight.w500),
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
                          '${brand.brandModels.length} model${brand.brandModels.length != 1 ? 's' : ''}',
                          style: TextStyle(
                              fontSize: sw * 0.026,
                              fontWeight: FontWeight.w700,
                              color: _kBlue),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Edit button
            RoleGuard(
              feature: AppFeature.updateBrand,
              child: GestureDetector(
                onTap: () => _showEditBrandSheet(context, sw, brand),
                child: Container(
                  padding: EdgeInsets.all(sw * 0.022),
                  decoration: BoxDecoration(
                    color: _kBlueBg,
                    borderRadius: BorderRadius.circular(sw * 0.025),
                    border: Border.all(color: _kBlueBorder),
                  ),
                  child: SvgPicture.asset(
                    AppIcons.edit,
                    width: sw * 0.045,
                    colorFilter:
                    const ColorFilter.mode(_kBlue, BlendMode.srcIn),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Status card ──────────────────────────────────────────────────────────────
  Widget _buildStatusCard(BuildContext context, double sw, BrandModel brand,
      bool isActive) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? _kGreenBg : _kRedBg,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(
            color: isActive ? _kGreenBorder : _kRedBorder, width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
            horizontal: sw * 0.04, vertical: sw * 0.035),
        child: Row(
          children: [
            Container(
              width: sw * 0.1,
              height: sw * 0.1,
              decoration: BoxDecoration(
                color: isActive ? _kGreen : _kRed,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isActive ? Icons.check_rounded : Icons.pause_rounded,
                color: Colors.white,
                size: sw * 0.05,
              ),
            ),
            SizedBox(width: sw * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Brand Status',
                      style: TextStyle(
                          fontSize: sw * 0.028,
                          color: isActive ? _kGreen : _kRed,
                          fontWeight: FontWeight.w600)),
                  Text(
                    isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                        fontSize: sw * 0.038,
                        fontWeight: FontWeight.w800,
                        color: isActive ? _kGreen : _kRed),
                  ),
                ],
              ),
            ),
            RoleGuard(
              feature: AppFeature.updateStatus,
              child: Switch(
                value: isActive,
                activeColor: _kGreen,
                activeTrackColor: _kGreenBorder,
                inactiveThumbColor: _kRed,
                inactiveTrackColor: _kRedBorder,
                onChanged: (val) async {
                  try {
                    final updated = brand.copyWith(
                        status: val ? 'active' : 'inactive');
                    await ref
                        .read(brandControllerProvider.notifier)
                        .updateBrand(updated, brand.brandName);
                    ref.invalidate(brandByIdProvider(widget.brandId));
                    _showSnack(
                        'Status updated to ${val ? 'Active' : 'Inactive'}',
                        Colors.green);
                  } catch (e) {
                    _showSnack('Failed to update: $e', _kRed);
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Models card ──────────────────────────────────────────────────────────────
  Widget _buildModelsCard(BuildContext context, double sw, double sh,
      BrandModel brand) {
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
                Container(
                  width: sw * 0.075,
                  height: sw * 0.075,
                  decoration: BoxDecoration(
                    color: _kAmberBg,
                    borderRadius: BorderRadius.circular(sw * 0.022),
                    border: Border.all(color: _kAmberBorder),
                  ),
                  child: Center(
                    child: SvgPicture.asset(AppIcons.model,
                        width: sw * 0.04,
                        colorFilter: const ColorFilter.mode(
                            _kAmber, BlendMode.srcIn)),
                  ),
                ),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Text('Models',
                      style: TextStyle(
                          fontSize: sw * 0.035,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                ),
                RoleGuard(
                  feature: AppFeature.updateBrand,
                  child: GestureDetector(
                    onTap: () =>
                        _showManageModelsSheet(context, sw, sh, brand),
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
          Padding(
            padding: EdgeInsets.all(sw * 0.04),
            child: brand.brandModels.isEmpty
                ? Text('No models added yet',
                style: TextStyle(
                    fontSize: sw * 0.032,
                    color: _kMuted,
                    fontWeight: FontWeight.w500))
                : Wrap(
              spacing: sw * 0.02,
              runSpacing: sw * 0.02,
              children: brand.brandModels.map((m) {
                return Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: sw * 0.03,
                      vertical: sw * 0.015),
                  decoration: BoxDecoration(
                    color: _kAmberBg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _kAmberBorder),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SvgPicture.asset(AppIcons.model,
                          width: sw * 0.032,
                          colorFilter: const ColorFilter.mode(
                              _kAmber, BlendMode.srcIn)),
                      SizedBox(width: sw * 0.015),
                      Text(m,
                          style: TextStyle(
                              fontSize: sw * 0.03,
                              fontWeight: FontWeight.w600,
                              color: _kAmber)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  // ── Creator card ─────────────────────────────────────────────────────────────
  Widget _buildCreatorCard(double sw, double sh, UserModel? user) {
    final initials = user != null
        ? (user.employeeName ?? 'U').substring(0, 1).toUpperCase()
        : '?';

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
                  child: Icon(Icons.person_outline_rounded,
                      size: sw * 0.04, color: _kDark),
                ),
                SizedBox(width: sw * 0.025),
                Text('Created By',
                    style: TextStyle(
                        fontSize: sw * 0.035,
                        fontWeight: FontWeight.w700,
                        color: _kDark)),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          Padding(
            padding: EdgeInsets.all(sw * 0.04),
            child: user == null
                ? Text('Creator information not available',
                style: TextStyle(
                    fontSize: sw * 0.032, color: _kMuted))
                : Row(
              children: [
                CircleAvatar(
                  radius: sw * 0.065,
                  backgroundColor: _kBlueBg,
                  child: Text(initials,
                      style: TextStyle(
                          fontSize: sw * 0.045,
                          fontWeight: FontWeight.w800,
                          color: _kBlue)),
                ),
                SizedBox(width: sw * 0.035),
                Expanded(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.employeeName ?? 'Unknown',
                        style: TextStyle(
                            fontSize: sw * 0.036,
                            fontWeight: FontWeight.w700,
                            color: _kDark),
                      ),
                      SizedBox(height: sw * 0.008),
                      Text(
                        user.employeeEmail ?? '',
                        style: TextStyle(
                            fontSize: sw * 0.029,
                            color: _kBlue,
                            fontWeight: FontWeight.w500),
                      ),
                      SizedBox(height: sw * 0.005),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: sw * 0.02,
                            vertical: sw * 0.006),
                        decoration: BoxDecoration(
                          color: _kBlueBg,
                          borderRadius:
                          BorderRadius.circular(20),
                          border: Border.all(
                              color: _kBlueBorder),
                        ),
                        child: Text(
                          (user.role ?? '')
                              .replaceAll('ROLE_', '')
                              .toLowerCase(),
                          style: TextStyle(
                              fontSize: sw * 0.026,
                              fontWeight: FontWeight.w700,
                              color: _kBlue),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Date row ─────────────────────────────────────────────────────────────────
  Widget _buildDateRow(double sw, double sh, BrandModel brand) {
    return Row(
      children: [
        Expanded(
            child: _dateCard(sw, 'Created',
                Icons.calendar_today_outlined, brand.createdAt)),
        SizedBox(width: sw * 0.025),
        Expanded(
            child: _dateCard(
                sw, 'Updated', Icons.update_rounded, brand.updatedAt)),
      ],
    );
  }

  Widget _dateCard(
      double sw, String label, IconData icon, dynamic date) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: sw * 0.038, color: _kMuted),
              SizedBox(width: sw * 0.015),
              Text(label,
                  style: TextStyle(
                      fontSize: sw * 0.028,
                      color: _kMuted,
                      fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: sw * 0.015),
          Text(
            _formatDate(date),
            style: TextStyle(
                fontSize: sw * 0.03,
                fontWeight: FontWeight.w600,
                color: _kDark),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic date) {
    if (date == null) return '—';
    try {
      final d = date is String ? DateTime.parse(date) : date as DateTime;
      return DateFormat('MMM dd, yyyy\nHH:mm').format(d);
    } catch (_) {
      return 'Invalid date';
    }
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Edit Brand Bottom Sheet
  // ─────────────────────────────────────────────────────────────────────────────
  void _showEditBrandSheet(
      BuildContext context, double sw, BrandModel brand) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditBrandSheet(
        brand: brand,
        onSave: (name, desc) async {
          try {
            await ref
                .read(brandControllerProvider.notifier)
                .updateBrand(brand.copyWith(brandName: name, description: desc),
                brand.brandName);
            ref.invalidate(brandByIdProvider(widget.brandId));
            _showSnack('Brand updated successfully', Colors.green);
          } catch (e) {
            _showSnack('Failed to update: $e', _kRed);
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Manage Models Bottom Sheet
  // ─────────────────────────────────────────────────────────────────────────────
  void _showManageModelsSheet(
      BuildContext context, double sw, double sh, BrandModel brand) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _ManageModelsSheet(
        brand: brand,
        onSave: (renamed, deleted, added) async {
          try {
            final updated = BrandModel(
              brandId: brand.brandId,
              brandName: brand.brandName,
              brandModels: brand.brandModels,
              description: brand.description,
              status: brand.status,
              createdBy: brand.createdBy,
              createdAt: brand.createdAt,
              updatedAt: brand.updatedAt,
            );
            await ref
                .read(brandControllerProvider.notifier)
                .updateBrand(
              updated,
              brand.brandName,
              brandModelsUpdate: renamed.isNotEmpty ? renamed : null,
              deletedModels: deleted.isNotEmpty ? deleted : null,
              addModel: added.isNotEmpty ? added : null,
            );
            ref.invalidate(brandByIdProvider(widget.brandId));
            _showSnack('Models updated successfully', Colors.green);
          } catch (e) {
            _showSnack('Failed to update models: $e', _kRed);
          }
        },
      ),
    );
  }
}

// ─── Edit Brand Sheet ─────────────────────────────────────────────────────────
class _EditBrandSheet extends StatefulWidget {
  final BrandModel brand;
  final Future<void> Function(String name, String desc) onSave;
  const _EditBrandSheet({required this.brand, required this.onSave});

  @override
  State<_EditBrandSheet> createState() => _EditBrandSheetState();
}

class _EditBrandSheetState extends State<_EditBrandSheet> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _descCtrl;
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.brand.brandName);
    _descCtrl =
        TextEditingController(text: widget.brand.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Padding(
      padding:
      EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
            sw * 0.05, sw * 0.04, sw * 0.05, sw * 0.06),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Handle(),
              Text('Edit Brand',
                  style: TextStyle(
                      fontSize: sw * 0.045,
                      fontWeight: FontWeight.w800,
                      color: _kDark)),
              Text(widget.brand.brandName,
                  style: const TextStyle(
                      fontSize: 12,
                      color: _kMuted,
                      fontWeight: FontWeight.w500)),
              SizedBox(height: sw * 0.05),

              _SheetLabel(sw: sw, label: 'Brand Name'),
              SizedBox(height: sh * 0.006),
              _SheetInput(
                sw: sw,
                ctrl: _nameCtrl,
                hint: 'Enter brand name',
                icon: Icons.label_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Required'
                    : null,
              ),
              SizedBox(height: sh * 0.015),

              _SheetLabel(sw: sw, label: 'Description'),
              SizedBox(height: sh * 0.006),
              _SheetInput(
                sw: sw,
                ctrl: _descCtrl,
                hint: 'Enter description',
                icon: Icons.description_outlined,
                maxLines: 3,
                validator: (v) => v == null || v.trim().isEmpty
                    ? 'Required'
                    : null,
              ),

              SizedBox(height: sh * 0.025),
              _SheetActions(
                sw: sw,
                sh: sh,
                onCancel: () => Navigator.pop(context),
                onSave: () async {
                  if (!_formKey.currentState!.validate()) return;
                  Navigator.pop(context);
                  await widget.onSave(
                      _nameCtrl.text.trim(), _descCtrl.text.trim());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Manage Models Sheet ──────────────────────────────────────────────────────
class _ManageModelsSheet extends StatefulWidget {
  final BrandModel brand;
  final Future<void> Function(
      Map<String, String> renamed,
      List<String> deleted,
      List<String> added) onSave;

  const _ManageModelsSheet({required this.brand, required this.onSave});

  @override
  State<_ManageModelsSheet> createState() => _ManageModelsSheetState();
}

class _ManageModelsSheetState extends State<_ManageModelsSheet> {
  final _newModelCtrl = TextEditingController();
  final Map<String, String> _renamed  = {};
  final List<String>        _deleted  = [];
  final List<String>        _added    = [];

  @override
  void dispose() {
    _newModelCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final visibleModels = widget.brand.brandModels
        .where((m) => !_deleted.contains(m))
        .toList();

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.75,
      maxChildSize: 0.92,
      builder: (_, sc) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed header
          Padding(
            padding:
            EdgeInsets.fromLTRB(sw * 0.05, sw * 0.04, sw * 0.05, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(child: _Handle()),
                Text('Manage Models',
                    style: TextStyle(
                        fontSize: sw * 0.045,
                        fontWeight: FontWeight.w800,
                        color: _kDark)),
                Text(widget.brand.brandName,
                    style: const TextStyle(
                        fontSize: 12,
                        color: _kMuted,
                        fontWeight: FontWeight.w500)),
                SizedBox(height: sw * 0.04),

                // Add model row
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _newModelCtrl,
                        style: TextStyle(
                            fontSize: sw * 0.035,
                            color: _kDark,
                            fontWeight: FontWeight.w500),
                        decoration: InputDecoration(
                          hintText: 'New model name',
                          hintStyle: TextStyle(
                              fontSize: sw * 0.034,
                              color: _kMuted,
                              fontWeight: FontWeight.w400),
                          prefixIcon: Icon(Icons.add_circle_outline,
                              color: _kMuted, size: sw * 0.045),
                          filled: true,
                          fillColor: _kBg,
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: sw * 0.04),
                          border: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(sw * 0.028),
                              borderSide:
                              const BorderSide(color: _kBorder)),
                          enabledBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(sw * 0.028),
                              borderSide:
                              const BorderSide(color: _kBorder)),
                          focusedBorder: OutlineInputBorder(
                              borderRadius:
                              BorderRadius.circular(sw * 0.028),
                              borderSide: const BorderSide(
                                  color: _kBlue, width: 1.5)),
                        ),
                      ),
                    ),
                    SizedBox(width: sw * 0.025),
                    GestureDetector(
                      onTap: () {
                        final v = _newModelCtrl.text.trim();
                        if (v.isNotEmpty) {
                          setState(() {
                            _added.add(v);
                            _newModelCtrl.clear();
                          });
                        }
                      },
                      child: Container(
                        width: sw * 0.12,
                        height: sw * 0.12,
                        decoration: BoxDecoration(
                          color: _kBlueBg,
                          borderRadius:
                          BorderRadius.circular(sw * 0.028),
                          border: Border.all(color: _kBlueBorder),
                        ),
                        child: Icon(Icons.add_rounded,
                            color: _kBlue, size: sw * 0.055),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: sw * 0.04),
                const Divider(height: 1, color: _kBorder),
                SizedBox(height: sw * 0.015),
              ],
            ),
          ),

          // Scrollable models list
          Expanded(
            child: ListView(
              controller: sc,
              padding: EdgeInsets.fromLTRB(
                  sw * 0.05, 0, sw * 0.05, sw * 0.04),
              children: [
                // Existing models
                if (visibleModels.isNotEmpty) ...[
                  _SheetLabel(sw: sw, label: 'Existing Models'),
                  SizedBox(height: sw * 0.02),
                  ...visibleModels.map((m) {
                    final isRenamed = _renamed.containsKey(m);
                    return Container(
                      margin: EdgeInsets.only(bottom: sw * 0.025),
                      padding: EdgeInsets.symmetric(
                          horizontal: sw * 0.035,
                          vertical: sw * 0.025),
                      decoration: BoxDecoration(
                        color: isRenamed ? _kBlueBg : _kBg,
                        borderRadius:
                        BorderRadius.circular(sw * 0.028),
                        border: Border.all(
                            color: isRenamed
                                ? _kBlueBorder
                                : _kBorder),
                      ),
                      child: Row(
                        children: [
                          SvgPicture.asset(AppIcons.model,
                              width: sw * 0.04,
                              colorFilter: const ColorFilter.mode(
                                  _kAmber, BlendMode.srcIn)),
                          SizedBox(width: sw * 0.025),
                          Expanded(
                            child: isRenamed
                                ? Column(
                              crossAxisAlignment:
                              CrossAxisAlignment.start,
                              children: [
                                Text(m,
                                    style: TextStyle(
                                        fontSize: sw * 0.03,
                                        color: _kMuted,
                                        decoration:
                                        TextDecoration
                                            .lineThrough)),
                                Text(_renamed[m]!,
                                    style: TextStyle(
                                        fontSize: sw * 0.034,
                                        fontWeight:
                                        FontWeight.w700,
                                        color: _kBlue)),
                              ],
                            )
                                : Text(m,
                                style: TextStyle(
                                    fontSize: sw * 0.034,
                                    fontWeight: FontWeight.w600,
                                    color: _kDark)),
                          ),
                          // Rename
                          GestureDetector(
                            onTap: () =>
                                _showRenameDialog(context, sw, m),
                            child: Container(
                              width: sw * 0.08,
                              height: sw * 0.08,
                              decoration: BoxDecoration(
                                color: _kBlueBg,
                                borderRadius:
                                BorderRadius.circular(sw * 0.02),
                                border: Border.all(
                                    color: _kBlueBorder),
                              ),
                              child: Center(
                                child: SvgPicture.asset(AppIcons.edit,
                                    width: sw * 0.038,
                                    colorFilter:
                                    const ColorFilter.mode(
                                        _kBlue, BlendMode.srcIn)),
                              ),
                            ),
                          ),
                          SizedBox(width: sw * 0.02),
                          // Delete
                          GestureDetector(
                            onTap: () => setState(() {
                              _deleted.add(m);
                              _renamed.remove(m);
                            }),
                            child: Container(
                              width: sw * 0.08,
                              height: sw * 0.08,
                              decoration: BoxDecoration(
                                color: _kRedBg,
                                borderRadius:
                                BorderRadius.circular(sw * 0.02),
                                border: Border.all(
                                    color: _kRedBorder),
                              ),
                              child: Center(
                                child: SvgPicture.asset(AppIcons.delete,
                                    width: sw * 0.038,
                                    colorFilter:
                                    const ColorFilter.mode(
                                        _kRed, BlendMode.srcIn)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  SizedBox(height: sw * 0.03),
                ],

                // New models
                if (_added.isNotEmpty) ...[
                  _SheetLabel(sw: sw, label: 'New Models'),
                  SizedBox(height: sw * 0.02),
                  ..._added.map((m) => Container(
                    margin: EdgeInsets.only(bottom: sw * 0.025),
                    padding: EdgeInsets.symmetric(
                        horizontal: sw * 0.035,
                        vertical: sw * 0.025),
                    decoration: BoxDecoration(
                      color: _kGreenBg,
                      borderRadius:
                      BorderRadius.circular(sw * 0.028),
                      border: Border.all(color: _kGreenBorder),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.fiber_new_rounded,
                            color: _kGreen, size: sw * 0.045),
                        SizedBox(width: sw * 0.025),
                        Expanded(
                          child: Text(m,
                              style: TextStyle(
                                  fontSize: sw * 0.034,
                                  fontWeight: FontWeight.w700,
                                  color: _kGreen)),
                        ),
                        GestureDetector(
                          onTap: () =>
                              setState(() => _added.remove(m)),
                          child: Container(
                            width: sw * 0.08,
                            height: sw * 0.08,
                            decoration: BoxDecoration(
                              color: _kRedBg,
                              borderRadius:
                              BorderRadius.circular(sw * 0.02),
                              border: Border.all(
                                  color: _kRedBorder),
                            ),
                            child: Icon(
                                Icons.delete_outline_rounded,
                                size: sw * 0.038,
                                color: _kRed),
                          ),
                        ),
                      ],
                    ),
                  )),
                  SizedBox(height: sw * 0.03),
                ],

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                              vertical: sw * 0.035),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12)),
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
                          Navigator.pop(context);
                          await widget.onSave(
                              _renamed, _deleted, _added);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _kBlue,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                              vertical: sw * 0.035),
                          shape: RoundedRectangleBorder(
                              borderRadius:
                              BorderRadius.circular(12)),
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
        ],
      ),
    );
  }

  void _showRenameDialog(BuildContext context, double sw, String model) {
    final ctrl = TextEditingController(text: _renamed[model] ?? model);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(sw * 0.04)),
        title: Text('Rename Model',
            style: TextStyle(
                fontSize: sw * 0.04,
                fontWeight: FontWeight.w800,
                color: _kDark)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          style: TextStyle(
              fontSize: sw * 0.036,
              color: _kDark,
              fontWeight: FontWeight.w500),
          decoration: InputDecoration(
            hintText: 'New name',
            filled: true,
            fillColor: _kBg,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kBorder)),
            enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide: const BorderSide(color: _kBorder)),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(sw * 0.028),
                borderSide:
                const BorderSide(color: _kBlue, width: 1.5)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel',
                style: TextStyle(
                    color: _kMuted, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            onPressed: () {
              final v = ctrl.text.trim();
              if (v.isNotEmpty && v != model) {
                setState(() => _renamed[model] = v);
                Navigator.pop(context);
              }
            },
            style: ElevatedButton.styleFrom(
                backgroundColor: _kBlue,
                foregroundColor: Colors.white,
                elevation: 0),
            child: const Text('Rename',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    ).whenComplete(() => ctrl.dispose());
  }
}

// ─── Error Screen ─────────────────────────────────────────────────────────────
class _BrandErrorScreen extends ConsumerWidget {
  final String brandId;
  const _BrandErrorScreen({required this.brandId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
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
                  Text('Brand Details',
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
                          ref.invalidate(brandByIdProvider(brandId)),
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

// ─── Shared sheet sub-widgets ─────────────────────────────────────────────────
class _Handle extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Center(
    child: Container(
      width: 36, height: 4,
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
          color: _kBorder, borderRadius: BorderRadius.circular(2)),
    ),
  );
}

class _SheetLabel extends StatelessWidget {
  final double sw;
  final String label;
  const _SheetLabel({required this.sw, required this.label});
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

class _SheetInput extends StatelessWidget {
  final double sw;
  final TextEditingController ctrl;
  final String hint;
  final IconData icon;
  final int maxLines;
  final String? Function(String?)? validator;

  const _SheetInput({
    required this.sw,
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
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
          borderSide:
          const BorderSide(color: _kRed, width: 1.5)),
    ),
  );
}

class _SheetActions extends StatelessWidget {
  final double sw, sh;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  const _SheetActions({
    required this.sw,
    required this.sh,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => Row(
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