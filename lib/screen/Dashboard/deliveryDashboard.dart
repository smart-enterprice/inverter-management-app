import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/const/icons.dart';
import 'package:inverter_management_app/feature/order/screen/order_view_page.dart';
import 'package:inverter_management_app/model/user_model.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import 'package:inverter_management_app/screen/rolesbasepanel/salesmanpanel.dart';
import 'package:inverter_management_app/widgets/rolebaseinfo/salesman_infocard.dart';

import '../../core/const/role.dart';
import '../../core/media_query/media_query.dart';
import '../../feature/authentication/controller/login_controller.dart';
import '../../feature/authentication/screen/login_mobile_view.dart';
import '../../feature/order/controller/order_controller.dart';
import '../../feature/signup/controller/signUp_controller.dart';
import '../../widgets/data_card.dart';
import '../../widgets/rolebaseinfo/info_card.dart';
import '../rolesbasepanel/ControlPanel.dart';
import '../rolesbasepanel/devileryPanal.dart';

class DeliveryDashboard extends ConsumerStatefulWidget {
  const DeliveryDashboard({super.key});

  @override
  ConsumerState<DeliveryDashboard> createState() =>
      _DeliveryDashboardState();
}

class _DeliveryDashboardState
    extends ConsumerState<DeliveryDashboard>
    with SingleTickerProviderStateMixin {
  UserModel? _user;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  static const String _avatarFallback =
      'https://plus.unsplash.com/premium_photo-1739786995646-480d5cfd83dc?q=80&w=880&auto=format&fit=crop&ixlib=rb-4.1.0&ixid=M3wxMjA3fDB8MHxwaG90by1wYWdlfHx8fGVufDB8fHx8fA%3D%3D';

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  String _greeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good morning';
    if (hour < 17) return 'Good afternoon';
    return 'Good evening';
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(recentOrdersProvider);
    final userAsync = ref.watch(currentUserProvider);
    _user = userAsync.asData?.value;

    final sw = Screen.w(context);
    final sh = Screen.h(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF0F2F5),
      body: SafeArea(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Hero header ─────────────────────────────────────────
                _buildHeader(context, sw, sh),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: sw * 0.045),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: sh * 0.025),
                      // ── Stats cards ────────────────────────────────────
                      SizedBox(height: sh * 0.03),
                      // ── Quick access ───────────────────────────────────
                      _sectionLabel('Quick Access'),
                      SizedBox(height: sh * 0.015),
                      const DeliveryPanel(),
                      SizedBox(height: sh * 0.03),

                      // ── Recent orders ──────────────────────────────────
                      _sectionLabel('Recent Orders'),
                      SizedBox(height: sh * 0.015),

                      ordersAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 30),
                          child: Center(child: GlobalLoader()),
                        ),
                        error: (e, _) => _buildErrorState(context, sw),
                        data: (orders) {
                          if (orders.isEmpty) {
                            return _buildEmptyState(sw, sh);
                          }
                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: orders.length,
                            separatorBuilder: (_, __) =>
                                SizedBox(height: sh * 0.012),
                            itemBuilder: (context, index) {
                              final order = orders[index];
                              return GestureDetector(
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => OrderViewPage(
                                        orderNumber:
                                        order.orderNumber.toString()),
                                  ),
                                ),
                                child: DataCard(order: order),
                              );
                            },
                          );
                        },
                      ),

                      SizedBox(height: sh * 0.04),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context, double sw, double sh) {
    final photoUrl = (_user?.photo != null && _user!.photo!.isNotEmpty)
        ? _user!.photo.toString()
        : _avatarFallback;
    final name = _user?.employeeName.replaceAll('_', ' ') ?? '...';
    final role = _user?.role.replaceAll('ROLE_', '').replaceAll('_', ' ') ?? '...';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0F1C3F), Color(0xFF1B3A7A)],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(32),
          bottomRight: Radius.circular(32),
        ),
      ),
      child: Stack(
        children: [
          // Decorative circles
          Positioned(
            right: -sw * 0.1,
            top: -sw * 0.1,
            child: Container(
              width: sw * 0.5,
              height: sw * 0.5,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.04),
              ),
            ),
          ),
          Positioned(
            right: sw * 0.05,
            top: sw * 0.12,
            child: Container(
              width: sw * 0.25,
              height: sw * 0.25,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF4C8FFF).withValues(alpha: 0.12),
              ),
            ),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(
                sw * 0.045, sh * 0.025, sw * 0.045, sh * 0.03),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Avatar
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                        color: const Color(0xFF4C8FFF).withValues(alpha: 0.6),
                        width: 2.5),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFF4C8FFF).withValues(alpha: 0.25),
                          blurRadius: 16,
                          offset: const Offset(0, 4)),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: sw * 0.065,
                    backgroundColor: const Color(0xFF1B3A7A),
                    backgroundImage: NetworkImage(photoUrl),
                  ),
                ),
                SizedBox(width: sw * 0.04),

                // Greeting text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        _greeting(),
                        style: TextStyle(
                          fontSize: sw * 0.032,
                          color: Colors.white.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.3,
                        ),
                      ),
                      SizedBox(height: sh * 0.004),
                      Text(
                        name,
                        style: TextStyle(
                          fontSize: sw * 0.048,
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: sh * 0.006),
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: sw * 0.025, vertical: sw * 0.008),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4C8FFF).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                              color: const Color(0xFF4C8FFF).withValues(alpha: 0.3)),
                        ),
                        child: Text(
                          role,
                          style: TextStyle(
                            fontSize: sw * 0.026,
                            color: const Color(0xFF90BAFF),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Logout button
                GestureDetector(
                  onTap: () async {
                    final result =
                    await ref.read(loginControllerProvider).logout();
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      backgroundColor:
                      result.success ? Colors.green : Colors.orange,
                      content: Text(result.message),
                    ));
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const LoginMobileView()),
                          (route) => false,
                    );
                  },
                  child: Container(
                    padding: EdgeInsets.all(sw * 0.03),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15)),
                    ),
                    child: SvgPicture.asset(
                      AppIcons.logout,
                      colorFilter: const ColorFilter.mode(
                          Color(0xFFFF6B6B), BlendMode.srcIn),
                      width: sw * 0.055,
                      height: sw * 0.055,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Row(children: [
      Container(
        width: 4,
        height: 18,
        decoration: BoxDecoration(
          color: const Color(0xFF1B4FD8),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
      const SizedBox(width: 10),
      Text(
        text,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w700,
          color: Color(0xFF0F1C3F),
          letterSpacing: 0.2,
        ),
      ),
    ]);
  }

  Widget _buildEmptyState(double sw, double sh) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(vertical: sh * 0.04),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(children: [
        Icon(Icons.inbox_outlined, size: sw * 0.12, color: Colors.grey[300]),
        SizedBox(height: sh * 0.015),
        Text('No recent orders',
            style: TextStyle(
                fontSize: sw * 0.038,
                color: Colors.grey[500],
                fontWeight: FontWeight.w500)),
      ]),
    );
  }

  Widget _buildErrorState(BuildContext context, double sw) {
    return Container(
      padding: EdgeInsets.all(sw * 0.04),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Row(children: [
        const Icon(Icons.wifi_off_rounded, color: Color(0xFFDC2626)),
        SizedBox(width: sw * 0.03),
        const Expanded(
          child: Text('No internet connection',
              style: TextStyle(
                  color: Color(0xFFDC2626), fontWeight: FontWeight.w500)),
        ),
      ]),
    );
  }
}