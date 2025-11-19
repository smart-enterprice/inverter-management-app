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
    if (_searchQuery.isEmpty) {
      return orders;
    }

    final query = _searchQuery.toLowerCase();
    return orders.where((order) {
      final dealerName = order.dealer?.employeeName.toLowerCase() ?? '';
      final shopName = order.dealer?.shopName.toLowerCase() ?? '';
      final orderId = order.orderNumber.toString().toLowerCase() ?? '';
      final phone = order.dealer?.employeePhone.toString() ?? '';

      return dealerName.contains(query) ||
          shopName.contains(query) ||
          orderId.contains(query) ||
          phone.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(orderControllerProvider);

    return ordersAsync.when(
      loading: () => const Scaffold(body: GlobalLoader()),
      error: (err, st) {
        return Scaffold(
            body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.wifi_off, size: 50, color: Colors.grey),
              SizedBox(height: 10),
              Text(
                "No Internet Connection",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              SizedBox(height: screenHeight * 0.01),
              ElevatedButton(
                onPressed: () {
                  ref.refresh(orderControllerProvider.notifier).getAllOrders();
                },
                child: const Text("Retry"),
              ),
            ],
          ),
        ));
      },
      data: (orders) {
        final filteredOrders = _filterOrders(orders);
        if (orders.isEmpty) {
          return Scaffold(
            backgroundColor: Colors.grey[50],
            body: Center(
              child: Padding(
                padding: EdgeInsets.all(screenWidth * 0.05),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: screenWidth * 0.3,
                      height: screenWidth * 0.3,
                      decoration: BoxDecoration(
                        color: Colors.grey[100],
                        shape: BoxShape.circle,
                      ),
                      child: SvgPicture.asset(
                        AppIcons.box,
                        width: screenWidth * 0.15,
                        height: screenWidth * 0.15,
                        colorFilter: ColorFilter.mode(
                            Colors.grey[500]!, BlendMode.srcIn),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.025),
                    Text(
                      "No Orders Yet",
                      style: TextStyle(
                        fontSize: screenWidth * 0.045,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    Text(
                      "Your orders will appear here",
                      style: TextStyle(
                        fontSize: screenWidth * 0.035,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Scaffold(
          backgroundColor: Colors.grey[50],
          appBar: AppBar(
            title: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SvgPicture.asset(
                  AppIcons.orders,
                  width: screenWidth * 0.06,
                  height: screenWidth * 0.06,
                  colorFilter:
                      const ColorFilter.mode(Colors.black, BlendMode.srcIn),
                ),
                SizedBox(width: screenWidth * 0.02),
                const Text("Orders"),
              ],
            ),
            leading: IconButton(
              padding: EdgeInsets.only(left: screenWidth * 0.04),
              icon: SvgPicture.asset(
                AppIcons.back_Arrow,
                width: screenWidth * 0.07,
                colorFilter: ColorFilter.mode(
                    Theme.of(context).primaryColor, BlendMode.srcIn),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                padding: EdgeInsets.only(right: screenWidth * 0.02),
                onPressed: _toggleSearch,
                icon: SvgPicture.asset(
                  _isSearching ? AppIcons.close : AppIcons.search,
                  width: screenWidth * 0.07,
                  colorFilter: ColorFilter.mode(
                      Theme.of(context).primaryColor, BlendMode.srcIn),
                ),
              ),
              IconButton(
                  padding: EdgeInsets.only(right: screenWidth * 0.04),
                  onPressed: ()=>Navigator.push(context, MaterialPageRoute(builder: (context)=>OrderCreatePage())),
                  icon: SvgPicture.asset(
                    AppIcons.add,
                    width: screenWidth * 0.07,
                    colorFilter: ColorFilter.mode(
                        Theme.of(context).primaryColor, BlendMode.srcIn),
                  ))
            ],
            surfaceTintColor: Colors.transparent,
            centerTitle: true,
            elevation: 0,
            backgroundColor: Colors.white,
            foregroundColor: Colors.black,
            shadowColor: Colors.black12,
          ),
          body: Column(
            children: [
              // Search Bar - Only show when _isSearching is true
              if (_isSearching)
                Padding(
                  padding: EdgeInsets.all(screenWidth * 0.04),
                  child: TextField(
                    controller: _searchController,
                    autofocus: true,
                    onChanged: (value) {
                      setState(() {
                        _searchQuery = value;
                      });
                    },
                    decoration: InputDecoration(
                      hintText:
                          'Search by order number, dealer name, phone or shop',
                      prefixIcon: Icon(
                        Icons.search,
                        color: Theme.of(context).primaryColor,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
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
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Colors.grey.withValues(alpha: 0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                          color: Theme.of(context).primaryColor,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                ),

              // Results count
              if (_isSearching && _searchQuery.isNotEmpty)
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: screenWidth * 0.04),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      '${filteredOrders.length} result${filteredOrders.length != 1 ? 's' : ''} found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

              // Orders List
              Expanded(
                child: filteredOrders.isEmpty && _isSearching
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 64,
                              color: Colors.grey[400],
                            ),
                            SizedBox(height: screenHeight * 0.02),
                            Text(
                              _searchQuery.isEmpty
                                  ? 'Start typing to search'
                                  : 'No results found for "$_searchQuery"',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey[600],
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
                            horizontal: screenWidth * 0.04,
                            vertical: screenHeight * 0.02,
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
                                    bottom: screenHeight * 0.02),
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
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(16),
                                  child: GestureDetector(
                                    onTap: () {
                                      // Navigate to order details
                                    },
                                    child: Padding(
                                      padding:
                                          EdgeInsets.all(screenWidth * 0.04),
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
                                                          screenWidth * 0.045,
                                                      height:
                                                          screenWidth * 0.045,
                                                      colorFilter:
                                                          ColorFilter.mode(
                                                              Theme.of(context)
                                                                  .primaryColor,
                                                              BlendMode.srcIn),
                                                    ),
                                                    SizedBox(
                                                        width: screenWidth *
                                                            0.015),
                                                    Expanded(
                                                      child: Text(
                                                        "Order #${order.orderNumber}",
                                                        style: TextStyle(
                                                          fontWeight:
                                                              FontWeight.w700,
                                                          fontSize:
                                                              screenWidth *
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
                                                      screenWidth * 0.03,
                                                  vertical:
                                                      screenHeight * 0.005,
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
                                                      width: screenWidth * 0.03,
                                                      height:
                                                          screenWidth * 0.03,
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
                                                            screenWidth * 0.01),
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
                                                            screenWidth * 0.03,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.015),
                                          // Dealer Information
                                          Row(
                                            children: [
                                              SvgPicture.asset(
                                                AppIcons.dealers,
                                                width: screenWidth * 0.04,
                                                height: screenWidth * 0.04,
                                                colorFilter: ColorFilter.mode(
                                                    AppTheme.accentGreen,
                                                    BlendMode.srcIn),
                                              ),
                                              SizedBox(
                                                  width: screenWidth * 0.02),
                                              Expanded(
                                                child: Text(
                                                  "Dealer: ${order.dealer?.employeeName ?? "N/A"}",
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.008),
                                          Row(
                                            children: [
                                              SvgPicture.asset(
                                                AppIcons.shop,
                                                width: screenWidth * 0.04,
                                                height: screenWidth * 0.04,
                                                colorFilter: ColorFilter.mode(
                                                    Theme.of(context)
                                                        .primaryColor,
                                                    BlendMode.srcIn),
                                              ),
                                              SizedBox(
                                                  width: screenWidth * 0.02),
                                              Expanded(
                                                child: Text(
                                                  "Shop: ${order.dealer?.shopName ?? "-"}",
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.008),
                                          Row(
                                            children: [
                                              Icon(
                                                Icons.phone_rounded,
                                                size: screenWidth * 0.04,
                                                color: Theme.of(context)
                                                    .primaryColor,
                                              ),
                                              SizedBox(
                                                  width: screenWidth * 0.02),
                                              Expanded(
                                                child: Text(
                                                  "Phone: ${order.dealer?.employeePhone ?? "-"}",
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w400,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          SizedBox(
                                              height: screenHeight * 0.008),
                                          Row(
                                            children: [
                                              SvgPicture.asset(
                                                AppIcons.bills,
                                                width: screenWidth * 0.04,
                                                height: screenWidth * 0.04,
                                                colorFilter:
                                                    const ColorFilter.mode(
                                                        Colors.pink,
                                                        BlendMode.srcIn),
                                              ),
                                              SizedBox(
                                                  width: screenWidth * 0.02),
                                              Expanded(
                                                child: Text(
                                                  "Amount Paid: ₹${order.amountPaid}",
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                          // Order Summary
                                          SizedBox(
                                              height: screenHeight * 0.015),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.03,
                                              vertical: screenHeight * 0.01,
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
                                                  width: screenWidth * 0.035,
                                                  height: screenWidth * 0.035,
                                                  colorFilter: ColorFilter.mode(
                                                      AppTheme.accentBlue,
                                                      BlendMode.srcIn),
                                                ),
                                                SizedBox(
                                                    width: screenWidth * 0.015),
                                                Text(
                                                  "${order.orderDetails.length} item${order.orderDetails.length > 1 ? 's' : ''}",
                                                  style: TextStyle(
                                                    fontSize:
                                                        screenWidth * 0.035,
                                                    color: Colors.grey[700],
                                                    fontWeight: FontWeight.w500,
                                                  ),
                                                ),
                                                const Spacer(),
                                                Container(
                                                  padding: EdgeInsets.symmetric(
                                                    horizontal:
                                                        screenWidth * 0.03,
                                                    vertical:
                                                        screenHeight * 0.005,
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
                                                          screenWidth * 0.03,
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
                                ),
                              ),
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        );
      },
    );
  }
}
