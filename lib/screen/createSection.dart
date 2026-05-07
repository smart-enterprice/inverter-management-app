import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/core/media_query/media_query.dart';
import 'package:inverter_management_app/feature/order/screen/order_create_page.dart';
import 'package:inverter_management_app/feature/product/screen/product_create_screen.dart';
import '../core/role/app_role.dart';
import '../feature/brand/screen/brand_create.dart';
import '../feature/signup/screen/dealer/dealers_sign_up_screen.dart';
import '../feature/signup/screen/user/sign_up_screen.dart';

// ─── Colour tokens (matches dashboard palette) ────────────────────────────────
const _kBg        = Color(0xFFF0F2F5);
const _kCard      = Colors.white;
const _kBorder    = Color(0xFFE5E7EB);
const _kDark      = Color(0xFF0F1C3F);
const _kMid       = Color(0xFF374151);
const _kMuted     = Color(0xFF9CA3AF);

// ─── Item model ──────────────────────────────────────────────────────────────
class _CreateItem {
  final String icon;
  final String title;
  final String subtitle;
  final Color accent;
  final Color accentBg;
  final Color accentBorder;
  final VoidCallback onTap;
  final String feature; //

  const _CreateItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.accentBg,
    required this.accentBorder,
    required this.onTap,
    required this.feature//
  });
}

class CreateSection extends ConsumerWidget {
  const CreateSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sw = Screen.w(context);
    final sh = Screen.h(context);

    final items = [
      _CreateItem(
        icon: AppIcons.orders,
        title: 'New Order',
        subtitle: 'Create an order for a dealer',
        accent: const Color(0xFF1B4FD8),
        accentBg: const Color(0xFFEEF2FF),
        accentBorder: const Color(0xFFC7D2FE),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const OrderCreatePage())),
        feature: AppFeature.createOrder,
      ),
      _CreateItem(
        icon: AppIcons.box,
        title: 'Add Product',
        subtitle: 'Register an inverter or battery',
        accent: const Color(0xFF7C3AED),
        accentBg: const Color(0xFFF5F3FF),
        accentBorder: const Color(0xFFDDD6FE),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const ProductCreateScreen())),
        feature: AppFeature.createProduct,
      ),
      _CreateItem(
        icon: AppIcons.brand,
        title: 'New Brand',
        subtitle: 'Add a brand to the system',
        accent: const Color(0xFFEA580C),
        accentBg: const Color(0xFFFFF7ED),
        accentBorder: const Color(0xFFFED7AA),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const BrandCreateScreen())),
        feature: AppFeature.createBrand,
      ),
      _CreateItem(
        icon: AppIcons.dealers,
        title: 'New Dealer',
        subtitle: 'Onboard a new dealer',
        accent: const Color(0xFF0A8A5C),
        accentBg: const Color(0xFFEDFAF4),
        accentBorder: const Color(0xFF9FE0C5),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddDealerScreen())),
        feature: AppFeature.createDealer,
      ),
      _CreateItem(
        icon: AppIcons.dealers,
        title: 'New Employee',
        subtitle: 'Add staff members to the app',
        accent: const Color(0xFF4338CA),
        accentBg: const Color(0xFFEEF2FF),
        accentBorder: const Color(0xFFC7D2FE),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AddUserScreen())),
        feature: AppFeature.createEmployee,
      ),
      _CreateItem(
        icon: AppIcons.bills,
        title: 'Reports',
        subtitle: 'View analytics and reports',
        accent: const Color(0xFF0369A1),
        accentBg: const Color(0xFFE0F2FE),
        accentBorder: const Color(0xFFBAE6FD),
        onTap: () {},
        feature: AppFeature.viewReports,
      ),
    ];
    final role = ref.watch(roleNotifierProvider);

    final visibleItems = items.where(
          (item) => AppPermissions.canAccess(role, item.feature),
    ).toList();
    final isTablet = sw >= 600;
    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              color: _kCard,
              padding: EdgeInsets.fromLTRB(
                  sw * 0.045, sh * 0.022, sw * 0.045, sh * 0.022),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // accent bar + title
                  Row(children: [
                    Container(
                      width: 4, height: 22,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1B4FD8),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    SizedBox(width: sw * 0.03),
                    Text('Create & Manage',
                        style: TextStyle(
                            fontSize: (sw * 0.055).clamp(18.0, 28.0),
                            fontWeight: FontWeight.w800,
                            color: _kDark,
                            letterSpacing: -0.5)),
                  ]),
                  SizedBox(height: sh * 0.006),
                  Padding(
                    padding: EdgeInsets.only(left: sw * 0.045 + 4),
                    child: Text('Add new records to the system',
                        style: TextStyle(
                            fontSize: (sw * 0.032).clamp(11.0, 15.0),
                            color: _kMuted,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),

            Container(height: 1, color: _kBorder),

            // ── List (mobile) / Grid (tablet) ────────────────────────────────
            Expanded(
              child: isTablet
                  ? GridView.builder(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    sw * 0.03, sh * 0.02, sw * 0.03, sh * 0.04),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: sw * 0.02,
                  mainAxisSpacing: sh * 0.018,
                  childAspectRatio: 2.8,
                ),
                itemCount: visibleItems.length,
                itemBuilder: (_, i) => _CreateCard(
                    item: visibleItems[i], sw: sw * 0.44, sh: sh),
              )
                  : ListView.separated(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.fromLTRB(
                    sw * 0.045, sh * 0.02, sw * 0.045, sh * 0.12),
                separatorBuilder: (_, __) => SizedBox(height: sh * 0.014),
                itemCount: visibleItems.length,
                itemBuilder: (_, i) => _CreateCard(
                    item: visibleItems[i], sw: sw, sh: sh),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Card ─────────────────────────────────────────────────────────────────────
class _CreateCard extends StatefulWidget {
  final _CreateItem item;
  final double sw, sh;

  const _CreateCard({
    required this.item,
    required this.sw,
    required this.sh,
  });

  @override
  State<_CreateCard> createState() => _CreateCardState();
}

class _CreateCardState extends State<_CreateCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween(begin: 1.0, end: 0.97)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final sw = widget.sw;
    final sh = widget.sh;

    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) { _ctrl.reverse(); item.onTap(); },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: _kCard,
            borderRadius: BorderRadius.circular(sw * 0.04),
            border: Border.all(color: _kBorder),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(children: [
            // ── Left accent bar ──────────────────────────────────────────
            Container(
              width: 4,
              height: sw * 0.185,
              decoration: BoxDecoration(
                color: item.accent,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  bottomLeft: Radius.circular(16),
                ),
              ),
            ),

            // ── Icon ─────────────────────────────────────────────────────
            SizedBox(width: sw * 0.04),
            Container(
              width: sw * 0.13,
              height: sw * 0.13,
              decoration: BoxDecoration(
                color: item.accentBg,
                borderRadius: BorderRadius.circular(sw * 0.032),
                border: Border.all(color: item.accentBorder),
              ),
              padding: EdgeInsets.all(sw * 0.028),
              child: SvgPicture.asset(
                item.icon,
                colorFilter: ColorFilter.mode(item.accent, BlendMode.srcIn),
              ),
            ),

            SizedBox(width: sw * 0.04),

            // ── Text ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.title,
                      style: TextStyle(
                          fontSize: sw * 0.038,
                          fontWeight: FontWeight.w700,
                          color: _kDark,
                          letterSpacing: -0.1)),
                  SizedBox(height: sh * 0.004),
                  Text(item.subtitle,
                      style: TextStyle(
                          fontSize: sw * 0.03,
                          fontWeight: FontWeight.w500,
                          color: _kMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),

            // ── Arrow ────────────────────────────────────────────────────
            Container(
              margin: EdgeInsets.only(right: sw * 0.04),
              width: sw * 0.07,
              height: sw * 0.07,
              decoration: BoxDecoration(
                color: item.accentBg,
                borderRadius: BorderRadius.circular(sw * 0.018),
                border: Border.all(color: item.accentBorder),
              ),
              child: Icon(Icons.arrow_forward_rounded,
                  size: sw * 0.036, color: item.accent),
            ),
          ]),
        ),
      ),
    );
  }
}