import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../screen/loadingScreen.dart';
import '../controller/order_controller.dart';
import '../../../model/order_model.dart';
import 'order_create_page.dart';
import 'order_view_page.dart';

class OrdersViewPage extends ConsumerStatefulWidget {
  const OrdersViewPage({super.key});

  @override
  ConsumerState<OrdersViewPage> createState() => _OrdersViewPageState();
}

class _OrdersViewPageState extends ConsumerState<OrdersViewPage> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  bool _isSearching = false;
  String _selectedStatus = 'ALL';
  final List<String> _statuses = [
    'ALL',
    'PENDING',
    'PRODUCTION',
    'PACKED',
    'INVOICE',
    'SHIPPED',
    'COMPLETED',
    'CANCELLED'
  ];
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _toggleSearch() {
    setState(() {
      _isSearching = !_isSearching;
      if (!_isSearching) {
        _searchController.clear();
        _searchQuery = '';
      }
    });
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    return orders.where((order) {
      // Check Status Match
      final matchesStatus = _selectedStatus == 'ALL' ||
          (order.status?.toUpperCase() == _selectedStatus);

      // Check Search Match
      final query = _searchQuery.toLowerCase();
      final matchesSearch = query.isEmpty ||
          (order.dealer?.employeeName.toLowerCase() ?? '').contains(query) ||
          (order.dealer?.shopName.toLowerCase() ?? '').contains(query) ||
          (order.orderNumber.toString().toLowerCase()).contains(query) ||
          (order.dealer?.employeePhone.toString() ?? '').contains(query);

      // Return true only if BOTH match
      return matchesStatus && matchesSearch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderControllerProvider);
    return ordersAsync.when(
      loading: () => const GlobalLoader(),
      error: (err, st) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                "No Internet Connection",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: Screen.h(context) * 0.01),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(orderControllerProvider.notifier).getAllOrders();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        );
      },
      data: (orders) {
        final filteredOrders = _filterOrders(orders);
        if (orders.isEmpty) {
          return  Center(
              child: Padding(
                padding: EdgeInsets.all(Screen.w(context) * 0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: Screen.w(context) * 0.3,
                      height: Screen.w(context) * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        AppIcons.box,
                        width: Screen.w(context) * 0.15,
                        height: Screen.w(context) * 0.15,
                        colorFilter: ColorFilter.mode(
                            Colors.grey[500]!, BlendMode.srcIn),
                      ),
                    ),
                    SizedBox(height: Screen.h(context) * 0.025),
                    Text(
                      "No Orders Yet",
                      style: TextStyle(
                        fontSize: Screen.w(context) * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: Screen.h(context) * 0.01),
                    Text(
                      "Your orders will appear here",
                      style: TextStyle(
                        fontSize: Screen.w(context) * 0.035,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            );
        }
          return Column(
            children: [
              // --- NEW CUSTOM HEADER WITH SEARCH TOGGLE ---
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: Screen.w(context) * 0.04,
                  vertical: Screen.h(context) * 0.015,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Orders',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                        letterSpacing: 0.3,
                      ),
                    ),

                    // Search Toggle Button
                    GestureDetector(
                      onTap: _toggleSearch,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _isSearching
                              ? Colors.redAccent.withValues(alpha: 0.1)
                              : Theme.of(context).primaryColor.withValues(alpha: 0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          _isSearching ? Icons.close_rounded : Icons.search_rounded,
                          color: _isSearching ? Colors.redAccent : Theme.of(context).primaryColor,
                          size: 24,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // --- Animated Search Bar ---
              AnimatedSize(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOut,
                child: _isSearching
                    ? Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: Screen.w(context) * 0.04,
                    vertical: Screen.h(context) * 0.01,
                  ),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true, // Automatically pops up keyboard
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText: 'Search by order number, dealer, phone...',
                      hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                        icon: const Icon(Icons.clear, size: 20),
                        onPressed: () {
                          setState(() {
                            _searchController.clear();
                            _searchQuery = '';
                          });
                        },
                      )
                          : null,
                      filled: true,
                      fillColor: Colors.white,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0), // Keeps it compact
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                )
                    : const SizedBox.shrink(),
              ),
              SizedBox(height: Screen.h(context) * 0.01),

              // --- ✅ NEW: Status Filter Chips ---
              SizedBox(
                height: 40, // Fixed height for the horizontal list
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: Screen.w(context) * 0.04),
                  itemCount: _statuses.length,
                  itemBuilder: (context, index) {
                    final status = _statuses[index];
                    final isSelected = _selectedStatus == status;

                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          _selectedStatus = status;
                        });
                      },
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: EdgeInsets.only(right: Screen.w(context) * 0.02),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? Theme.of(context).primaryColor
                              : Colors.grey[100],
                          borderRadius: BorderRadius.circular(20), // Pill shape
                          border: Border.all(
                            color: isSelected
                                ? Theme.of(context).primaryColor
                                : Colors.grey.shade300,
                            width: 1,
                          ),
                          boxShadow: isSelected
                              ? [
                            BoxShadow(
                              color: Theme.of(context).primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 3),
                            )
                          ]
                              : [],
                        ),
                        child: Center(
                          child: Text(
                            status,
                            style: TextStyle(
                              color: isSelected ? Colors.white : Colors.grey[700],
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w600,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              SizedBox(height: Screen.h(context) * 0.01),
              // Results count
              if (_isSearching && _searchQuery.isNotEmpty)
                Padding(
                  padding: EdgeInsets.only(
                      left: Screen.w(context) * 0.04,
                      right: Screen.w(context) * 0.04,
                      bottom: Screen.h(context) * 0.01
                  ),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredOrders.length} result${filteredOrders.length != 1 ? 's' : ''} found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ),

              // --- Orders List ---
              Expanded(
                child: filteredOrders.isEmpty && _isSearching
                    ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.search_off_rounded,
                        size: 64,
                        color: Colors.grey[300],
                      ),
                      SizedBox(height: Screen.h(context) * 0.02),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Start typing to search'
                            : 'No results found for "$_searchQuery"',
                        style: TextStyle(
                          fontSize: 15,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
                    : RefreshIndicator(
                        backgroundColor: Colors.white,
                        color: Theme.of(context).primaryColor,
                        onRefresh: () async {
                          await Future.delayed(const Duration(seconds: 2));
                          await ref
                              .read(orderControllerProvider.notifier)
                              .getAllOrders();
                        },
                        child: ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: Screen.w(context) * 0.04,
                            vertical: Screen.h(context) * 0.0,
                          ),
                          itemCount: filteredOrders.length,
                          itemBuilder: (context, index) {
                            final OrderModel order = filteredOrders[index];
                            final bool isDelivered =
                                order.status == "DELIVERED";
                            final Color priorityColor;
                            final Color priorityBg;

                            switch (order.priority.toUpperCase()) {
                              case 'HIGH':
                                priorityColor = Colors.red[700]!;
                                priorityBg = Colors.red[50]!;
                                break;
                              case 'MEDIUM':
                                priorityColor = Colors.yellow[900]!;
                                priorityBg = Colors.yellow[50]!;
                                break;
                              case 'LOW':
                                priorityColor = Colors.green[700]!;
                                priorityBg = Colors.green[50]!;
                                break;
                              default:
                                priorityColor = Colors.grey[700]!;
                                priorityBg = Colors.grey[100]!;
                            }
                            return GestureDetector(
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (context) => OrderViewPage(
                                            orderNumber:
                                                order.orderNumber.toString(),
                                          ))),
                              child: Container(
                                margin: EdgeInsets.only(
                                    bottom: Screen.h(context) * 0.02),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(16),
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color:
                                          Colors.black.withValues(alpha: 0.05),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    ),
                                  ],
                                ),
                                child: Padding(
                                  padding:
                                      EdgeInsets.all(Screen.w(context) * 0.04),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      // Header Row
                                      Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Row(
                                              children: [
                                                SvgPicture.asset(
                                                  AppIcons.orders,
                                                  width:
                                                  Screen.w(context) * 0.045,
                                                  height:
                                                  Screen.w(context) * 0.045,
                                                  colorFilter:
                                                      ColorFilter.mode(
                                                          Theme.of(context)
                                                              .primaryColor,
                                                          BlendMode.srcIn),
                                                ),
                                                SizedBox(
                                                    width: Screen.w(context) *
                                                        0.015),
                                                Expanded(
                                                  child: Text(
                                                    "#${order.orderNumber}",
                                                    style: TextStyle(
                                                      fontWeight:
                                                          FontWeight.w700,
                                                      fontSize:
                                                      Screen.w(context) *
                                                              0.04,
                                                      color:
                                                          Colors.grey[800],
                                                    ),
                                                    overflow: TextOverflow
                                                        .ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal:
                                              Screen.w(context) * 0.03,
                                              vertical:
                                              Screen.h(context) * 0.005,
                                            ),
                                            decoration: BoxDecoration(
                                              color: isDelivered
                                                  ? Colors.green[50]
                                                  : Colors.orange[50],
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                              border: Border.all(
                                                color: isDelivered
                                                    ? Colors.green[100]!
                                                    : Colors.orange[100]!,
                                                width: 1,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize:
                                                  MainAxisSize.min,
                                              children: [
                                                SvgPicture.asset(
                                                  isDelivered
                                                      ? AppIcons.delivery
                                                      : AppIcons.time,
                                                  width: Screen.w(context) * 0.03,
                                                  height:
                                                  Screen.w(context) * 0.03,
                                                  colorFilter:
                                                      ColorFilter.mode(
                                                    isDelivered
                                                        ? Colors.green[700]!
                                                        : Colors
                                                            .orange[700]!,
                                                    BlendMode.srcIn,
                                                  ),
                                                ),
                                                SizedBox(
                                                    width:
                                                    Screen.w(context) * 0.01),
                                                Text(
                                                  order.status??'',
                                                  style: TextStyle(
                                                    color: isDelivered
                                                        ? Colors.green[700]
                                                        : Colors
                                                            .orange[700],
                                                    fontWeight:
                                                        FontWeight.w600,
                                                    fontSize:
                                                    Screen.w(context) * 0.03,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                          height: Screen.h(context) * 0.015),
                                      // Dealer Information
                                      Row(
                                        children: [
                                          SvgPicture.asset(
                                            AppIcons.dealers,
                                            width: Screen.w(context) * 0.04,
                                            height: Screen.w(context) * 0.04,
                                            colorFilter: ColorFilter.mode(
                                                AppTheme.accentGreen,
                                                BlendMode.srcIn),
                                          ),
                                          SizedBox(
                                              width: Screen.w(context) * 0.02),
                                          Expanded(
                                            child: Text(
                                              "Dealer: ${order.dealer?.employeeName ?? "N/A"}",
                                              style: TextStyle(
                                                fontSize:
                                                Screen.w(context) * 0.035,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                          height: Screen.h(context) * 0.008),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.phone_rounded,
                                            size: Screen.w(context) * 0.04,
                                            color: Theme.of(context)
                                                .primaryColor,
                                          ),
                                          SizedBox(
                                              width: Screen.w(context) * 0.02),
                                          Expanded(
                                            child: Text(
                                              "Phone: ${order.dealer?.employeePhone ?? "-"}",
                                              style: TextStyle(
                                                fontSize:
                                                Screen.w(context) * 0.035,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w400,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      // Order Summary
                                      SizedBox(
                                          height: Screen.h(context) * 0.015),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                          horizontal: Screen.w(context) * 0.03,
                                          vertical: Screen.h(context) * 0.01,
                                        ),
                                        decoration: BoxDecoration(
                                          color: Colors.grey[50],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: Row(
                                          children: [
                                            SvgPicture.asset(
                                              AppIcons.box,
                                              width: Screen.w(context) * 0.035,
                                              height: Screen.w(context) * 0.035,
                                              colorFilter: ColorFilter.mode(
                                                  AppTheme.accentBlue,
                                                  BlendMode.srcIn),
                                            ),
                                            SizedBox(
                                                width: Screen.w(context) * 0.015),
                                            Text(
                                              "${order.orderDetails.length} item${order.orderDetails.length > 1 ? 's' : ''}",
                                              style: TextStyle(
                                                fontSize:
                                                Screen.w(context) * 0.035,
                                                color: Colors.grey[700],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            const Spacer(),
                                            Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal:
                                                Screen.w(context) * 0.03,
                                                vertical:
                                                Screen.h(context) * 0.005,
                                              ),
                                              decoration: BoxDecoration(
                                                color: priorityBg,
                                                borderRadius:
                                                    BorderRadius.circular(
                                                        8),
                                                border: Border.all(
                                                  color: priorityColor
                                                      .withValues(
                                                          alpha: 0.2),
                                                  width: 1,
                                                ),
                                              ),
                                              child: Text(
                                                order.priority,
                                                style: TextStyle(
                                                  color: priorityColor,
                                                  fontWeight:
                                                      FontWeight.w600,
                                                  fontSize:
                                                  Screen.w(context) * 0.03,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
      },
    );
  }
}
