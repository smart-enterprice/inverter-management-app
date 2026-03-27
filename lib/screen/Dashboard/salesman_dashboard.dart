import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:inverter_management_app/model/user_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/media_query/media_query.dart';
import '../../feature/order/controller/order_controller.dart';
// Make sure to import this
import '../../feature/signup/controller/signUp_controller.dart';
import '../../widgets/data_card.dart';
import '../../widgets/info_card.dart';
import '../ControlPanel.dart';

class SalesManDashboardScreen extends ConsumerStatefulWidget {
  const SalesManDashboardScreen({super.key});

  @override
  ConsumerState<SalesManDashboardScreen> createState() => _SalesManDashboardScreenState();
}

class _SalesManDashboardScreenState extends ConsumerState<SalesManDashboardScreen> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('user_id');
    if (userId != null) {
      final user = await ref
          .read(signupControllerProvider.notifier)
          .getEmployeeById(userId);
      setState(() {
        _user = user;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the order provider
    final ordersAsync = ref.watch(orderControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: Screen.w(context) * 0.04,
              vertical: Screen.h(context) * 0.02,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // --- CUSTOM HEADER ---
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                                color: Colors.blueAccent.withValues(alpha: 0.3), width: 2),
                          ),
                          child: CircleAvatar(
                            radius: 24,
                            backgroundColor: Colors.white,
                            backgroundImage: NetworkImage(_user?.photo ?? 'https://via.placeholder.com/150'),
                          ),
                        ),
                        SizedBox(width: Screen.w(context) * 0.03),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Welcome back,',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey.shade600,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              _user?.employeeName.replaceAll('_', ' ') ?? 'Loading...',
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    Container(
                      padding: EdgeInsets.all(Screen.w(context) * 0.025),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.04),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                        border: Border.all(color: Colors.grey.shade100),
                      ),
                      child: Stack(
                        children: [
                          const Icon(
                            Icons.notifications_none_rounded,
                            color: Colors.black87,
                            size: 26,
                          ),
                          Positioned(
                            right: 2,
                            top: 2,
                            child: Container(
                              height: 10,
                              width: 10,
                              decoration: BoxDecoration(
                                color: Colors.redAccent,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                // --- END CUSTOM HEADER ---

                SizedBox(height: Screen.h(context) * 0.03),

                const InfoCard(),

                SizedBox(height: Screen.h(context) * 0.03),

                const Text(
                  'Quick Access',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                    letterSpacing: 0.3,
                  ),
                ),
                SizedBox(height: Screen.h(context) * 0.015),
                const ControlPanel(),

                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Recent Orders',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),
                    TextButton(
                      onPressed: () {},
                      child: const Text(
                        'View All',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Colors.blueAccent,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: Screen.h(context) * 0.01),

                // 2. Dynamic Order List
                ordersAsync.when(
                  loading: () => const Padding(
                    padding: EdgeInsets.symmetric(vertical: 20),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => Center(child: Text('Error: $error')),
                  data: (orders) {
                    final recentOrders = orders.take(5).toList();

                    if (recentOrders.isEmpty) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 20),
                        child: Center(child: Text("No recent orders found.")),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: recentOrders.length,
                      separatorBuilder: (context, index) => SizedBox(height: Screen.h(context) * 0.012),
                      itemBuilder: (context, index) {
                        final order = recentOrders[index];
                        return DataCard(order: order);
                      },
                    );
                  },
                ),

                SizedBox(height: Screen.h(context) * 0.04),
              ],
            ),
          ),
        ),
      ),
    );
  }
}