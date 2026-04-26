import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/core/const/snackbar.dart';
import 'package:inverter_management_app/feature/authentication/controller/login_controller.dart';
import 'package:inverter_management_app/feature/authentication/screen/login_mobile_view.dart';
import 'package:inverter_management_app/feature/order/controller/order_controller.dart';
import 'package:inverter_management_app/feature/order/screen/order_view_page.dart';
import 'package:inverter_management_app/feature/signup/controller/signUp_controller.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import 'package:inverter_management_app/widgets/data_card.dart';

// ── Design tokens ─────────────────────────────────────────────────────────────
const _kPrimary    = Color(0xFF185FA5);
const _kPrimaryBg  = Color(0xFFEBF4FF);
const _kBg         = Color(0xFFF7F8FA);
const _kSurface    = Color(0xFFFFFFFF);
const _kBorder     = Color(0xFFE5E7EB);
const _kTextDark   = Color(0xFF111827);
const _kTextMid    = Color(0xFF374151);
const _kTextMuted  = Color(0xFF6B7280);
const _kGreen      = Color(0xFF0F6E56);
const _kGreenBg    = Color(0xFFEDFAF5);
const _kRed        = Color(0xFFDC2626);
const _kRedBg      = Color(0xFFFEF2F2);
const _kRedBorder  = Color(0xFFFECACA);

// ─────────────────────────────────────────────────────────────────────────────
// BaseDashboard
// ─────────────────────────────────────────────────────────────────────────────
/// Zoho Books inspired shared dashboard.
/// Every role screen passes its own [quickAccessPanel] and optional [statsPanel].
///
/// ```dart
/// BaseDashboard(
///   quickAccessPanel: const ControlPanel(),
///   statsPanel: const InfoCard(),         // optional
/// )
/// ```
class BaseDashboard extends ConsumerStatefulWidget {
  const BaseDashboard({
    super.key,
    required this.quickAccessPanel,
    this.statsPanel,
  });

  /// Role-specific quick-access grid / buttons shown in the middle section.
  final Widget quickAccessPanel;

  /// Optional role-specific stats card shown at the top (below the header).
  /// Omit for Packing / Production / Delivery / Accounts roles.
  final Widget? statsPanel;

  @override
  ConsumerState<BaseDashboard> createState() => _BaseDashboardState();
}

class _BaseDashboardState extends ConsumerState<BaseDashboard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _anim;
  late final Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _anim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _fade = CurvedAnimation(parent: _anim, curve: Curves.easeOut);
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  String get _greeting {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good morning';
    if (h < 17) return 'Good afternoon';
    return 'Good evening';
  }

  // ── Logout ──────────────────────────────────────────────────────────────────
  Future<void> _logout(BuildContext context) async {
    final result = await ref.read(loginControllerProvider).logout();
    if (!context.mounted) return;
    showAppSnackBar(
      context,
      result.message,
      isError: !result.success,
    );
    if (result.success) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginMobileView()),
            (_) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final mq          = MediaQuery.of(context);
    final sw          = mq.size.width;
    final sh          = mq.size.height;
    final isTablet    = sw >= 600;
    final hPad        = sw * (isTablet ? 0.05 : 0.045);

    final ordersAsync = ref.watch(recentOrdersProvider);
    final user        = ref.watch(currentUserProvider).asData?.value;

    final name = (user?.employeeName ?? '...')
        .replaceAll('_', ' ');
    final role = (user?.role ?? '...')
        .replaceAll('ROLE_', '')
        .replaceAll('_', ' ');
    final photoUrl = (user?.photo != null && (user!.photo?.isNotEmpty ?? false))
        ? user.photo!
        : null;

    return Scaffold(
      backgroundColor: _kBg,
      body: SafeArea(
        child: FadeTransition(
          opacity: _fade,
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ── App bar / header ─────────────────────────────────────────
              SliverToBoxAdapter(
                child: _Header(
                  sw: sw,
                  sh: sh,
                  isTablet: isTablet,
                  hPad: hPad,
                  name: name,
                  role: role,
                  photoUrl: photoUrl,
                  greeting: _greeting,
                  onLogout: () => _logout(context),
                ),
              ),

              SliverPadding(
                padding: EdgeInsets.symmetric(horizontal: hPad),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    SizedBox(height: sh * 0.025),

                    // ── Stats panel (role-specific, optional) ─────────────
                    if (widget.statsPanel != null) ...[
                      widget.statsPanel!,
                      SizedBox(height: sh * 0.025),
                    ],

                    // ── Quick access ──────────────────────────────────────
                    _SectionLabel(
                      text: 'Quick Access',
                      sw: sw,
                      sh: sh,
                    ),
                    SizedBox(height: sh * 0.015),
                    widget.quickAccessPanel,
                    SizedBox(height: sh * 0.03),

                    // ── Recent orders ─────────────────────────────────────
                    _SectionLabel(
                      text: 'Recent Orders',
                      sw: sw,
                      sh: sh,
                    ),
                    SizedBox(height: sh * 0.015),
                  ]),
                ),
              ),

              // ── Orders list ───────────────────────────────────────────────
              ordersAsync.when(
                loading: () => SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: sh * 0.06),
                    child: const Center(child: GlobalLoader()),
                  ),
                ),
                error: (_, __) => SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.symmetric(horizontal: hPad),
                    child: _ErrorState(sw: sw, sh: sh),
                  ),
                ),
                data: (orders) {
                  if (orders.isEmpty) {
                    return SliverToBoxAdapter(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: hPad),
                        child: _EmptyState(sw: sw, sh: sh),
                      ),
                    );
                  }
                  return SliverPadding(
                    padding: EdgeInsets.only(
                      left: hPad,
                      right: hPad,
                      bottom: sh * 0.04,
                    ),
                    sliver: SliverList.separated(
                      itemCount: orders.length,
                      separatorBuilder: (_, __) =>
                          SizedBox(height: sh * 0.012),
                      itemBuilder: (ctx, i) => GestureDetector(
                        onTap: () => Navigator.push(
                          ctx,
                          MaterialPageRoute(
                            builder: (_) => OrderViewPage(
                              orderNumber: orders[i].orderNumber.toString(),
                            ),
                          ),
                        ),
                        child: DataCard(order: orders[i]),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _Header  — Zoho Books white top bar style
// ─────────────────────────────────────────────────────────────────────────────
class _Header extends StatelessWidget {
  const _Header({
    required this.sw,
    required this.sh,
    required this.isTablet,
    required this.hPad,
    required this.name,
    required this.role,
    required this.photoUrl,
    required this.greeting,
    required this.onLogout,
  });

  final double sw, sh, hPad;
  final bool isTablet;
  final String name, role, greeting;
  final String? photoUrl;
  final VoidCallback onLogout;

  @override
  Widget build(BuildContext context) {
    final avatarR    = (sw * 0.055).clamp(20.0, 36.0);
    final nameFs     = (sw * 0.046).clamp(15.0, 22.0);
    final greetFs    = (sw * 0.030).clamp(10.0, 13.0);
    final roleFs     = (sw * 0.026).clamp(9.0, 12.0);
    final iconBtnSz  = (sw * 0.09).clamp(34.0, 46.0);
    final iconSz     = (sw * 0.05).clamp(18.0, 24.0);
    final pillH      = (sw * 0.018).clamp(2.0, 4.0);
    final pillR      = (sw * 0.04).clamp(3.0, 10.0);

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: _kSurface,
        border: Border(
          bottom: BorderSide(color: _kBorder, width: 0.5),
        ),
      ),
      padding: EdgeInsets.fromLTRB(
        hPad,
        sh * 0.018,
        hPad,
        sh * 0.018,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // ── Avatar ────────────────────────────────────────────────────────
          CircleAvatar(
            radius: avatarR,
            backgroundColor: _kPrimaryBg,
            backgroundImage:
            photoUrl != null ? NetworkImage(photoUrl!) : null,
            child: photoUrl == null
                ? Text(
              name.isNotEmpty ? name[0].toUpperCase() : 'U',
              style: TextStyle(
                fontSize: avatarR * 0.8,
                fontWeight: FontWeight.w700,
                color: _kPrimary,
              ),
            )
                : null,
          ),
          SizedBox(width: sw * 0.03),

          // ── Name + greeting + role pill ───────────────────────────────────
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  greeting,
                  style: TextStyle(
                    fontSize: greetFs,
                    color: _kTextMuted,
                    fontWeight: FontWeight.w400,
                    height: 1.2,
                  ),
                ),
                SizedBox(height: sh * 0.003),
                Text(
                  name,
                  style: TextStyle(
                    fontSize: nameFs,
                    color: _kTextDark,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.2,
                    height: 1.2,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: sh * 0.004),
                // Role pill
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: sw * 0.025,
                    vertical: pillH,
                  ),
                  decoration: BoxDecoration(
                    color: _kPrimaryBg,
                    borderRadius: BorderRadius.circular(pillR),
                    border: Border.all(
                      color: _kPrimary.withValues(alpha: 0.25),
                      width: 0.5,
                    ),
                  ),
                  child: Text(
                    role,
                    style: TextStyle(
                      fontSize: roleFs,
                      color: _kPrimary,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: sw * 0.02),

          // ── Logout button ─────────────────────────────────────────────────
          GestureDetector(
            onTap: onLogout,
            child: Container(
              width: iconBtnSz,
              height: iconBtnSz,
              decoration: BoxDecoration(
                color: _kRedBg,
                shape: BoxShape.circle,
                border: Border.all(color: _kRedBorder, width: 0.5),
              ),
              child: Icon(
                Icons.logout_rounded,
                size: iconSz,
                color: _kRed,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _SectionLabel
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  const _SectionLabel({
    required this.text,
    required this.sw,
    required this.sh,
  });

  final String text;
  final double sw, sh;

  @override
  Widget build(BuildContext context) {
    final fs        = (sw * 0.038).clamp(13.0, 17.0);
    final barW      = (sw * 0.008).clamp(3.0, 5.0);
    final barH      = (sh * 0.022).clamp(14.0, 20.0);
    final barR      = barW / 2;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: barW,
          height: barH,
          decoration: BoxDecoration(
            color: _kPrimary,
            borderRadius: BorderRadius.circular(barR),
          ),
        ),
        SizedBox(width: sw * 0.025),
        Text(
          text,
          style: TextStyle(
            fontSize: fs,
            fontWeight: FontWeight.w700,
            color: _kTextDark,
            letterSpacing: 0.1,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _EmptyState
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.sw, required this.sh});
  final double sw, sh;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: sh * 0.045),
      decoration: BoxDecoration(
        color: _kSurface,
        borderRadius: BorderRadius.circular(sw * 0.03),
        border: Border.all(color: _kBorder, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.inbox_outlined,
            size: (sw * 0.12).clamp(36.0, 56.0),
            color: const Color(0xFFD1D5DB),
          ),
          SizedBox(height: sh * 0.012),
          Text(
            'No recent orders',
            style: TextStyle(
              fontSize: (sw * 0.035).clamp(12.0, 16.0),
              color: _kTextMuted,
              fontWeight: FontWeight.w500,
              height: 1.2,
            ),
          ),
          SizedBox(height: sh * 0.005),
          Text(
            'Orders will appear here once created',
            style: TextStyle(
              fontSize: (sw * 0.028).clamp(10.0, 13.0),
              color: const Color(0xFF9CA3AF),
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _ErrorState
// ─────────────────────────────────────────────────────────────────────────────
class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.sw, required this.sh});
  final double sw, sh;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: _kRedBg,
        borderRadius: BorderRadius.circular(sw * 0.03),
        border: Border.all(color: _kRedBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Icon(
            Icons.wifi_off_rounded,
            color: _kRed,
            size: (sw * 0.055).clamp(18.0, 26.0),
          ),
          SizedBox(width: sw * 0.03),
          Expanded(
            child: Text(
              'Could not load orders. Check your connection.',
              style: TextStyle(
                fontSize: (sw * 0.032).clamp(11.0, 14.0),
                color: _kRed,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}