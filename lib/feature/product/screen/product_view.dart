import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:intl/intl.dart';
import 'package:inverter_management_app/core/role/app_role.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/product_model.dart';
import '../../../model/user_model.dart';
import '../../../widgets/circle_button.dart';
import '../../signup/controller/signUp_controller.dart';
import '../controller/product_controller.dart';
import 'product_price_history.dart';

// ─── THEME (consistent with brand) ─────────────────────────────
const _kBlue = Color(0xFF1B4FD8);
const _kBlueBg = Color(0xFFEEF2FF);
const _kBlueBorder = Color(0xFFC7D4FF);
const _kBg = Color(0xFFF2F4F8);
const _kCard = Colors.white;
const _kBorder = Color(0xFFE5E7EB);
const _kDark = Color(0xFF111827);
const _kMid = Color(0xFF374151);
const _kMuted = Color(0xFF9CA3AF);
const _kRed = Color(0xFFDC2626);
const _kRedBg = Color(0xFFFEF2F2);
const _kRedBorder = Color(0xFFFECACA);
const _kGreen = Color(0xFF0A8A5C);
const _kGreenBg = Color(0xFFEDFAF4);
const _kGreenBorder = Color(0xFF9FE0C5);
const _kAmber = Color(0xFFB45309);
const _kAmberBg = Color(0xFFFFFBEB);
const _kAmberBorder = Color(0xFFFCD28A);
const _kPurple = Color(0xFF7C3AED);
const _kPurpleBg = Color(0xFFF5F3FF);
const _kPurpleBorder = Color(0xFFDDD6FE);

// ─── SCREEN ─────────────────────────────────────────────────────
class ProductDetailsScreen extends ConsumerWidget {
  final String productId;
  const ProductDetailsScreen({super.key, required this.productId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final productAsync = ref.watch(productByIdProvider(productId));

    return productAsync.when(
      loading: () => const Scaffold(
          backgroundColor: _kBg,
          body: Center(child: CircularProgressIndicator(color: _kBlue))),
      error: (e, _) => _ProductErrorScreen(productId: productId),
      data: (product) => _ProductDetailView(product: product!, productId: productId),
    );
  }
}

// ─── Main Detail View ─────────────────────────────────────────────────────────
class _ProductDetailView extends ConsumerStatefulWidget {
  final ProductModel product;
  final String productId;
  const _ProductDetailView({required this.product, required this.productId});

  @override
  ConsumerState<_ProductDetailView> createState() => _ProductDetailViewState();
}

class _ProductDetailViewState extends ConsumerState<_ProductDetailView> {
  void _showSnack(String msg, Color bg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontWeight: FontWeight.w600)),
      backgroundColor: bg,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);
    final product = widget.product;
    final isActive = product.status?.toLowerCase() == 'active';

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top Nav ──────────────────────────────
            Padding(
              padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('Product Details',
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
                onRefresh: () async => ref.invalidate(productByIdProvider(widget.productId)),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.038),
                  child: Column(
                    children: [
                      SizedBox(height: sh * 0.005),

                      // ── Product header card ──────────────
                      _buildHeaderCard(context, sw, sh, product),
                      SizedBox(height: sh * 0.012),

                      // ── Status card ────────────────────
                      _buildStatusCard(context, sw, product, isActive),
                      SizedBox(height: sh * 0.012),

                      // ── Stock card ─────────────────────
                      RoleGuard(
                          feature: AppFeature.viewStock,
                          child: _buildStockCard(context, sw, sh, product, isActive)),
                      SizedBox(height: sh * 0.012),

                      // ── Pricing card ───────────────────
                      RoleGuard(
                          feature: AppFeature.viewPrice,
                          child: _buildPricingCard(context, sw, sh, product)),
                      SizedBox(height: sh * 0.012),

                      // ── Creator card ───────────────────
                      ref.watch(employeeByIdProvider(product.createdBy ?? '')).when(
                        data: (user) => _buildCreatorCard(sw, sh, user),
                        loading: () => const SizedBox.shrink(),
                        error: (_, __) => _buildCreatorCard(sw, sh, null),
                      ),
                      SizedBox(height: sh * 0.012),

                      // ── Date row ───────────────────────
                      RoleGuard(
                          feature: AppFeature.viewTimestamps,
                          child: _buildDateRow(sw, sh, product)),
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
  Widget _buildHeaderCard(BuildContext context, double sw, double sh, ProductModel product) {
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
                color: _kPurpleBg,
                borderRadius: BorderRadius.circular(sw * 0.035),
                border: Border.all(color: _kPurpleBorder),
              ),
              child: Center(
                child: Icon(Icons.inventory_2_outlined, color: _kPurple, size: sw * 0.07),
              ),
            ),
            SizedBox(width: sw * 0.035),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(product.productName ?? 'Unnamed Product',
                      style: TextStyle(
                          fontSize: sw * 0.045,
                          fontWeight: FontWeight.w800,
                          color: _kDark,
                          letterSpacing: -0.3)),
                  SizedBox(height: sw * 0.01),
                  Text(
                    '${product.brand} • ${product.model}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        fontSize: sw * 0.031,
                        color: _kMuted,
                        fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: sw * 0.015),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: sw * 0.025, vertical: sw * 0.008),
                    decoration: BoxDecoration(
                      color: _kPurpleBg,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: _kPurpleBorder),
                    ),
                    child: Text(
                      product.productType ?? 'N/A',
                      style: TextStyle(
                          fontSize: sw * 0.026,
                          fontWeight: FontWeight.w700,
                          color: _kPurple),
                    ),
                  ),
                ],
              ),
            ),
            // Edit button
            RoleGuard(
              feature: AppFeature.updateProduct,
              child: GestureDetector(
                onTap: () => _showEditProductSheet(context, sw, product),
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
                    colorFilter: const ColorFilter.mode(_kBlue, BlendMode.srcIn),
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
  Widget _buildStatusCard(BuildContext context, double sw, ProductModel product, bool isActive) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? _kGreenBg : _kRedBg,
        borderRadius: BorderRadius.circular(sw * 0.04),
        border: Border.all(color: isActive ? _kGreenBorder : _kRedBorder, width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
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
                  Text('Product Status',
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
              feature:AppFeature.updateStatus,
              child: Switch(
                value: isActive,
                activeColor: _kGreen,
                activeTrackColor: _kGreenBorder,
                inactiveThumbColor: _kRed,
                inactiveTrackColor: _kRedBorder,
                onChanged: (val) async {
                  try {
                    final updated = product.copyWith(status: val ? 'active' : 'inactive');
                    await ref.read(productControllerProvider.notifier).updateProduct(widget.productId, updated);
                    ref.invalidate(productByIdProvider(widget.productId));
                    _showSnack('Status updated to ${val ? 'Active' : 'Inactive'}', Colors.green);
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

  // ── Stock card ───────────────────────────────────────────────────────────────
  Widget _buildStockCard(BuildContext context, double sw, double sh, ProductModel product, bool isActive) {
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
            padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
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
                  child: Icon(Icons.inventory_outlined, size: sw * 0.04, color: _kAmber),
                ),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Text('Stock Information',
                      style: TextStyle(
                          fontSize: sw * 0.035,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                ),
                if (isActive)
                  RoleGuard(
                    feature: AppFeature.updateStock,
                    child: GestureDetector(
                      onTap: () => _showUpdateStockSheet(context, sw, sh, product),
                      child: Container(
                        padding: EdgeInsets.symmetric(horizontal: sw * 0.03, vertical: sw * 0.01),
                        decoration: BoxDecoration(
                          color: _kBlueBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kBlueBorder),
                        ),
                        child: Text('Update',
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
            child: Row(
              children: [
                Expanded(child: _buildStockItem(sw, 'Packed', Icons.inventory, product.packedStock ?? 0, _kBlue)),
                Expanded(child: _buildStockItem(sw, 'Unpacked', Icons.inventory_2, product.unpackedStock ?? 0, _kAmber)),
                Expanded(child: _buildStockItem(sw, 'Total', Icons.summarize, product.availableStock ?? 0, _kGreen)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStockItem(double sw, String label, IconData icon, int value, Color color) {
    return Column(
      children: [
        Container(
          padding: EdgeInsets.all(sw * 0.03),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color, size: sw * 0.05),
        ),
        SizedBox(height: sw * 0.015),
        Text(
          value.toString(),
          style: TextStyle(fontSize: sw * 0.045, fontWeight: FontWeight.bold, color: color),
        ),
        Text(
          label,
          style: TextStyle(fontSize: sw * 0.028, color: _kMuted, fontWeight: FontWeight.w500),
        ),
      ],
    );
  }

  // ── Pricing card ─────────────────────────────────────────────────────────────
  Widget _buildPricingCard(BuildContext context, double sw, double sh, ProductModel product) {
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
            padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
            child: Row(
              children: [
                Container(
                  width: sw * 0.075,
                  height: sw * 0.075,
                  decoration: BoxDecoration(
                    color: _kGreenBg,
                    borderRadius: BorderRadius.circular(sw * 0.022),
                    border: Border.all(color: _kGreenBorder),
                  ),
                  child: Center(
                    child: Text('₹', style: TextStyle(fontSize: sw * 0.04, fontWeight: FontWeight.w900, color: _kGreen)),
                  ),
                ),
                SizedBox(width: sw * 0.025),
                Expanded(
                  child: Text('Pricing',
                      style: TextStyle(
                          fontSize: sw * 0.035,
                          fontWeight: FontWeight.w700,
                          color: _kDark)),
                ),
                RoleGuard(
                  feature: AppFeature.updatePrice,
                  child: GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => ProductPriceHistory(history: product.priceHistory ?? []))),
                    child: Container(
                      padding: EdgeInsets.all(sw * 0.02),
                      decoration: BoxDecoration(
                        color: _kBg,
                        borderRadius: BorderRadius.circular(sw * 0.02),
                        border: Border.all(color: _kBorder),
                      ),
                      child: Icon(Icons.history, size: sw * 0.038, color: _kMuted),
                    ),
                  ),
                ),
                SizedBox(width: sw * 0.02),
                RoleGuard(
                  feature: AppFeature.updatePrice,
                  child: GestureDetector(
                    onTap: () => _showEditPriceSheet(context, sw, product),
                    child: Container(
                      padding: EdgeInsets.all(sw * 0.02),
                      decoration: BoxDecoration(
                        color: _kBlueBg,
                        borderRadius: BorderRadius.circular(sw * 0.02),
                        border: Border.all(color: _kBlueBorder),
                      ),
                      child: SvgPicture.asset(AppIcons.edit, width: sw * 0.038, colorFilter: const ColorFilter.mode(_kBlue, BlendMode.srcIn)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, thickness: 1, color: _kBorder),
          Padding(
            padding: EdgeInsets.all(sw * 0.04),
            child: Container(
              padding: EdgeInsets.all(sw * 0.04),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [_kGreenBg, _kGreenBg.withValues(alpha: 0.3)],
                ),
                borderRadius: BorderRadius.circular(sw * 0.028),
                border: Border.all(color: _kGreenBorder),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Current Price',
                      style: TextStyle(fontSize: sw * 0.034, fontWeight: FontWeight.w600, color: _kMid)),
                  Text('₹${product.price ?? '0.00'}',
                      style: TextStyle(fontSize: sw * 0.05, fontWeight: FontWeight.w900, color: _kGreen)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Creator card ─────────────────────────────────────────────────────────────
  Widget _buildCreatorCard(double sw, double sh, UserModel? user) {
    final initials = user != null ? (user.employeeName ?? 'U').substring(0, 1).toUpperCase() : '?';

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
            padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.035),
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
                  child: Icon(Icons.person_outline_rounded, size: sw * 0.04, color: _kDark),
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
                style: TextStyle(fontSize: sw * 0.032, color: _kMuted))
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
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                            horizontal: sw * 0.02, vertical: sw * 0.006),
                        decoration: BoxDecoration(
                          color: _kBlueBg,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: _kBlueBorder),
                        ),
                        child: Text(
                          (user.role ?? '').replaceAll('ROLE_', '').toLowerCase(),
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
  Widget _buildDateRow(double sw, double sh, ProductModel product) {
    return Row(
      children: [
        Expanded(child: _dateCard(sw, 'Created', Icons.calendar_today_outlined, product.createdAt)),
        SizedBox(width: sw * 0.025),
        Expanded(child: _dateCard(sw, 'Updated', Icons.update_rounded, product.updatedAt)),
      ],
    );
  }

  Widget _dateCard(double sw, String label, IconData icon, dynamic date) {
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
                      fontSize: sw * 0.028, color: _kMuted, fontWeight: FontWeight.w600)),
            ],
          ),
          SizedBox(height: sw * 0.015),
          Text(
            _formatDate(date),
            style: TextStyle(fontSize: sw * 0.03, fontWeight: FontWeight.w600, color: _kDark),
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
  //  Edit Product Bottom Sheet
  // ─────────────────────────────────────────────────────────────────────────────
  void _showEditProductSheet(BuildContext context, double sw, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditProductSheet(
        product: product,
        onSave: (name) async {
          try {
            await ref.read(productControllerProvider.notifier).updateProduct(
                widget.productId, product.copyWith(productName: name));
            ref.invalidate(productByIdProvider(widget.productId));
            _showSnack('Product updated successfully', Colors.green);
          } catch (e) {
            _showSnack('Failed to update: $e', _kRed);
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Edit Price Bottom Sheet
  // ─────────────────────────────────────────────────────────────────────────────
  void _showEditPriceSheet(BuildContext context, double sw, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _EditPriceSheet(
        product: product,
        onSave: (price) async {
          try {
            await ref.read(productControllerProvider.notifier).updateProduct(
                widget.productId, product.copyWith(price: price));
            ref.invalidate(productByIdProvider(widget.productId));
            _showSnack('Price updated successfully', Colors.green);
          } catch (e) {
            _showSnack('Failed to update: $e', _kRed);
          }
        },
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  //  Update Stock Bottom Sheet
  // ─────────────────────────────────────────────────────────────────────────────
  void _showUpdateStockSheet(BuildContext context, double sw, double sh, ProductModel product) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _UpdateStockSheet(
        product: product,
        onSave: (packed, unpacked, notes) async {
          try {
            List<StockItem> stockItems = [];
            if (unpacked > 0) {
              stockItems.add(StockItem(
                  stock: unpacked,
                  stockType: "UNPACKED",
                  type: "ADD",
                  stockNotes: notes.isEmpty ? null : notes));
            }
            if (packed > 0) {
              stockItems.add(StockItem(
                  stock: packed,
                  stockType: "PACKED",
                  type: "ADD",
                  stockNotes: notes.isEmpty ? null : notes));
            }

            final stockUpdate = StockUpdate(stockMap: {widget.productId: stockItems});
            await ref.read(productControllerProvider.notifier).updateStock(stockUpdate);
            ref.invalidate(productByIdProvider(widget.productId));
            _showSnack('Stock updated successfully', Colors.green);
          } catch (e) {
            _showSnack('Failed to update stock: $e', _kRed);
          }
        },
      ),
    );
  }
}

// ─── Edit Product Sheet ───────────────────────────────────────────────────────
class _EditProductSheet extends StatefulWidget {
  final ProductModel product;
  final Future<void> Function(String name) onSave;
  const _EditProductSheet({required this.product, required this.onSave});

  @override
  State<_EditProductSheet> createState() => _EditProductSheetState();
}

class _EditProductSheetState extends State<_EditProductSheet> {
  late final TextEditingController _nameCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameCtrl = TextEditingController(text: widget.product.productName);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
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
              _Handle(),
              Text('Edit Product',
                  style: TextStyle(
                      fontSize: sw * 0.045, fontWeight: FontWeight.w800, color: _kDark)),
              Text(widget.product.productName ?? 'Product',
                  style: const TextStyle(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w500)),
              SizedBox(height: sw * 0.05),
              _SheetLabel(sw: sw, label: 'Product Name'),
              SizedBox(height: sh * 0.006),
              _SheetInput(
                sw: sw,
                ctrl: _nameCtrl,
                hint: 'Enter product name',
                icon: Icons.label_outline_rounded,
                validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              ),
              SizedBox(height: sh * 0.025),
              _SheetActions(
                sw: sw,
                sh: sh,
                isSaving: _isSaving,
                onCancel: () => Navigator.pop(context),
                onSave: () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isSaving = true);
                  Navigator.pop(context);
                  await widget.onSave(_nameCtrl.text.trim());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Edit Price Sheet ─────────────────────────────────────────────────────────
class _EditPriceSheet extends StatefulWidget {
  final ProductModel product;
  final Future<void> Function(double price) onSave;
  const _EditPriceSheet({required this.product, required this.onSave});

  @override
  State<_EditPriceSheet> createState() => _EditPriceSheetState();
}

class _EditPriceSheetState extends State<_EditPriceSheet> {
  late final TextEditingController _priceCtrl;
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _priceCtrl = TextEditingController(text: widget.product.price?.toString() ?? '');
  }

  @override
  void dispose() {
    _priceCtrl.dispose();
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
              _Handle(),
              Text('Edit Price',
                  style: TextStyle(
                      fontSize: sw * 0.045, fontWeight: FontWeight.w800, color: _kDark)),
              Text('${widget.product.productName}',
                  style: const TextStyle(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w500)),
              SizedBox(height: sw * 0.05),
              _SheetLabel(sw: sw, label: 'Price (₹)'),
              SizedBox(height: sh * 0.006),
              _SheetInput(
                sw: sw,
                ctrl: _priceCtrl,
                hint: 'Enter price',
                icon: Icons.currency_rupee,
                keyboard: TextInputType.number,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Required';
                  if (double.tryParse(v) == null) return 'Enter valid number';
                  if (double.parse(v) < 0) return 'Cannot be negative';
                  return null;
                },
              ),
              SizedBox(height: sh * 0.025),
              _SheetActions(
                sw: sw,
                sh: sh,
                isSaving: _isSaving,
                onCancel: () => Navigator.pop(context),
                onSave: () async {
                  if (!_formKey.currentState!.validate()) return;
                  setState(() => _isSaving = true);
                  Navigator.pop(context);
                  await widget.onSave(double.parse(_priceCtrl.text.trim()));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Update Stock Sheet ───────────────────────────────────────────────────────
class _UpdateStockSheet extends StatefulWidget {
  final ProductModel product;
  final Future<void> Function(int packed, int unpacked, String notes) onSave;
  const _UpdateStockSheet({required this.product, required this.onSave});

  @override
  State<_UpdateStockSheet> createState() => _UpdateStockSheetState();
}

class _UpdateStockSheetState extends State<_UpdateStockSheet> {
  final _packedCtrl = TextEditingController();
  final _unpackedCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isSaving = false;

  @override
  void dispose() {
    _packedCtrl.dispose();
    _unpackedCtrl.dispose();
    _notesCtrl.dispose();
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
              _Handle(),
              Text('Update Stock',
                  style: TextStyle(
                      fontSize: sw * 0.045, fontWeight: FontWeight.w800, color: _kDark)),
              Text(widget.product.productName ?? 'Product',
                  style: const TextStyle(fontSize: 12, color: _kMuted, fontWeight: FontWeight.w500)),
              SizedBox(height: sw * 0.05),
              _SheetLabel(sw: sw, label: 'Packed Stock to Add'),
              SizedBox(height: sh * 0.006),
              RoleGuard(
                feature: AppFeature.updatePackedStock,
                child: _SheetInput(
                  sw: sw,
                  ctrl: _packedCtrl,
                  hint: 'Enter quantity',
                  icon: Icons.inventory,
                  keyboard: TextInputType.number,
                ),
              ),
              SizedBox(height: sh * 0.015),
              _SheetLabel(sw: sw, label: 'Unpacked Stock to Add'),
              SizedBox(height: sh * 0.006),
              RoleGuard(
                feature: AppFeature.updateUnpackedStock,
                child: _SheetInput(
                  sw: sw,
                  ctrl: _unpackedCtrl,
                  hint: 'Enter quantity',
                  icon: Icons.inventory_2,
                  keyboard: TextInputType.number,
                ),
              ),
              SizedBox(height: sh * 0.015),
              _SheetLabel(sw: sw, label: 'Notes (Optional)'),
              SizedBox(height: sh * 0.006),
              _SheetInput(
                sw: sw,
                ctrl: _notesCtrl,
                hint: 'Add notes',
                icon: Icons.note_outlined,
                maxLines: 3,
              ),
              SizedBox(height: sh * 0.025),
              _SheetActions(
                sw: sw,
                sh: sh,
                isSaving: _isSaving,
                onCancel: () => Navigator.pop(context),
                onSave: () async {
                  final packed = int.tryParse(_packedCtrl.text) ?? 0;
                  final unpacked = int.tryParse(_unpackedCtrl.text) ?? 0;
                  if (packed == 0 && unpacked == 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                          content: Text('Enter at least one stock value'),
                          backgroundColor: _kRed),
                    );
                    return;
                  }
                  setState(() => _isSaving = true);
                  Navigator.pop(context);
                  await widget.onSave(packed, unpacked, _notesCtrl.text.trim());
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Error Screen ─────────────────────────────────────────────────────────────
class _ProductErrorScreen extends ConsumerWidget {
  final String productId;
  const _ProductErrorScreen({required this.productId});

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
              padding: EdgeInsets.symmetric(horizontal: sw * 0.04, vertical: sw * 0.03),
              child: Row(
                children: [
                  CircularIconButton(
                    icon: Icons.arrow_back_ios_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  const Spacer(),
                  Text('Product Details',
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
                          border: Border.all(color: _kBorder)),
                      child: Icon(Icons.wifi_off_rounded, size: sw * 0.09, color: _kMuted),
                    ),
                    SizedBox(height: sh * 0.02),
                    Text('No Internet Connection',
                        style: TextStyle(
                            fontSize: sw * 0.04,
                            fontWeight: FontWeight.w600,
                            color: _kMid)),
                    SizedBox(height: sh * 0.025),
                    ElevatedButton(
                      onPressed: () => ref.invalidate(productByIdProvider(productId)),
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
      width: 36,
      height: 4,
      margin: const EdgeInsets.only(bottom: 18),
      decoration:
      BoxDecoration(color: _kBorder, borderRadius: BorderRadius.circular(2)),
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
  final TextInputType keyboard;
  final String? Function(String?)? validator;

  const _SheetInput({
    required this.sw,
    required this.ctrl,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
    this.keyboard = TextInputType.text,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => TextFormField(
    controller: ctrl,
    maxLines: maxLines,
    keyboardType: keyboard,
    validator: validator,
    autovalidateMode: AutovalidateMode.onUserInteraction,
    style: TextStyle(fontSize: sw * 0.036, color: _kDark, fontWeight: FontWeight.w500),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(
          fontSize: sw * 0.034, color: _kMuted, fontWeight: FontWeight.w400),
      prefixIcon: Icon(icon, color: _kMuted, size: sw * 0.045),
      filled: true,
      fillColor: _kBg,
      contentPadding: EdgeInsets.symmetric(
          horizontal: sw * 0.04, vertical: maxLines > 1 ? sw * 0.035 : 0),
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

class _SheetActions extends StatelessWidget {
  final double sw, sh;
  final bool isSaving;
  final VoidCallback onCancel;
  final VoidCallback onSave;
  const _SheetActions({
    required this.sw,
    required this.sh,
    required this.isSaving,
    required this.onCancel,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: OutlinedButton(
          onPressed: isSaving ? null : onCancel,
          style: OutlinedButton.styleFrom(
            padding: EdgeInsets.symmetric(vertical: sh * 0.016),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
          onPressed: isSaving ? null : onSave,
          style: ElevatedButton.styleFrom(
            backgroundColor: _kBlue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(vertical: sh * 0.016),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 0,
          ),
          child: isSaving
              ? SizedBox(
            height: sw * 0.05,
            width: sw * 0.05,
            child: const CircularProgressIndicator(
              color: Colors.white,
              strokeWidth: 2.5,
            ),
          )
              : Text('Save Changes',
              style: TextStyle(
                  fontSize: sw * 0.036, fontWeight: FontWeight.w700)),
        ),
      ),
    ],
  );
}