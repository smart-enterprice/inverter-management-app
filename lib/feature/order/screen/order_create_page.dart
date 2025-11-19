import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:inverter_management_app/core/theme/theme.dart';
import 'package:inverter_management_app/screen/loadingScreen.dart';
import '../../../core/const/icons.dart';
import '../../../core/media_query/media_query.dart';
import '../../../model/brand_model.dart';
import '../../../model/dealer_discount_model.dart';
import '../../../model/order_model.dart';
import '../../../model/product_model.dart';
import '../../../model/user_model.dart';
import '../../brand/controller/brand_controller.dart';
import '../../discount/controller/discount_controller.dart';
import '../../product/controller/product_controller.dart';
import '../../signup/controller/signUp_controller.dart';
import '../controller/order_controller.dart';

class OrderCreatePage extends ConsumerStatefulWidget {
  const OrderCreatePage({super.key});

  @override
  ConsumerState<OrderCreatePage> createState() => _OrderCreatePageState();
}

class _OrderCreatePageState extends ConsumerState<OrderCreatePage> {
  UserModel? selectedDealer;
  BrandModel? selectedBrand;
  ProductModel? selectedProduct;
  UserModel? selectedSalesman;
  String selectedPriority = 'LOW';
  final priorities = ['HIGH', 'MEDIUM', 'LOW'];
  String paymentMethod = 'CASH';
  num amountPaid = 0;
  bool isCreatingOrder = false;

  // New list to hold selected products
  List<OrderDetailsModel> selectedProducts = [];
  final TextEditingController orderNoteController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      bottomNavigationBar: Container(
        padding: EdgeInsets.all(screenWidth * 0.05),
        child: ElevatedButton(
          onPressed: _canCreateOrder() ? _createOrder : null,
          style: ElevatedButton.styleFrom(
            minimumSize: Size.fromHeight(screenHeight * 0.06),
          ),
          child: isCreatingOrder
              ? const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.5,
                  ),
                )
              : const Text('Create'),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Existing dealer, brand, salesman selection buttons...
            Container(
              width: screenWidth * 0.9,
              height: screenHeight * 0.3,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(screenWidth * 0.04),
                  color: Colors.white),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: screenWidth * 0.8,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                        ),
                      ),
                      onPressed: () => _showSalesmanDialog(context),
                      child: Text(selectedSalesman == null
                          ? 'Select Salesman'
                          : selectedSalesman!.employeeName),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  SizedBox(
                    width: screenWidth * 0.8,
                    child: ElevatedButton(
                      onPressed: () => _showDealerDialog(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                        ),
                      ),
                      child: Text(
                        selectedDealer == null
                            ? 'Select Dealer'
                            : '${selectedDealer!.employeeName} (${selectedDealer!.shopName ?? 'No Shop'})',
                      ),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  SizedBox(
                    width: screenWidth * 0.8,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                        ),
                      ),
                      onPressed: selectedDealer == null
                          ? null
                          : () => _showBrandDialog(
                              context, selectedDealer!.employeeId!),
                      child: Text(selectedBrand == null
                          ? 'Select Brand'
                          : selectedBrand!.brandName),
                    ),
                  ),
                  SizedBox(height: screenWidth * 0.02),
                  SizedBox(
                    width: screenWidth * 0.8,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        elevation: 0,
                        side: BorderSide(color: Colors.grey, width: 1),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(screenWidth * 0.03),
                        ),
                      ),
                      onPressed: selectedBrand == null
                          ? null
                          : () => _showProductDialog(
                              context, [selectedBrand!.brandName]),
                      child: Text(selectedProduct == null
                          ? 'Select Product'
                          : selectedProduct!.productName.toString()),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: screenHeight * 0.03),
            // Selected Products List
            if (selectedProducts.isNotEmpty) ...[
              Container(
                width: screenWidth * 0.9,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    SizedBox(height: screenHeight * 0.03),
                    Center(
                      child: Text(
                        'Selected Products (${selectedProducts.length})',
                        style:
                            Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    // if (selectedProducts.isNotEmpty)
                    ListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      // prevent nested scroll
                      itemCount: selectedProducts.length,
                      itemBuilder: (context, index) {
                        return _buildProductItem(
                            selectedProducts[index], index);
                      },
                    ),
                    // divider
                    SizedBox(height: screenHeight * 0.01),
                    Center(
                      child:
                          SizedBox(width: screenWidth * 0.8, child: Divider()),
                    ),
                    SizedBox(height: screenHeight * 0.01),
                    // ▼▼▼ ORDER TOTAL ▼▼▼
                    Padding(
                      padding: EdgeInsets.only(right: screenWidth * 0.05),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "Order Total",
                            style: TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          Text(
                            '₹ ${_calculateOrderTotal().toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                  ],
                ),
              ),
            ],
            SizedBox(height: screenHeight * 0.015),
            Center(
              child: Container(
                padding: EdgeInsets.symmetric(
                    vertical: screenHeight * 0.02,
                    horizontal: screenWidth * 0.05),
                width: screenWidth * 0.9,
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(screenWidth * 0.04),
                    color: Colors.white),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Order Details',
                        style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 16)),
                    SizedBox(
                      height: screenHeight * 0.02,
                    ),
                    TextFormField(
                      controller: orderNoteController,
                      minLines: 2,
                      maxLines: 5,
                      keyboardType: TextInputType.multiline,
                      decoration: const InputDecoration(
                        // labelText: 'Order Note',
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.note_alt_outlined),
                        hintText:
                            'Add any special instruction or notes  (optional)',
                      ),
                    ),
                    // Priority selection
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Order Priority',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    SizedBox(height: screenHeight * 0.02),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: priorities.map((p) {
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              selectedPriority = p;
                            });
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Row(
                              children: [
                                Icon(
                                  selectedPriority == p
                                      ? Icons.radio_button_checked
                                      : Icons.radio_button_unchecked,
                                  color: p == 'HIGH'
                                      ? Colors.red
                                      : p == 'MEDIUM'
                                          ? Colors.orange
                                          : Colors.green,
                                  size: 26,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  p, // ← Show the name
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: p == 'HIGH'
                                        ? Colors.red
                                        : p == 'MEDIUM'
                                            ? Colors.orange
                                            : Colors.green,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),

                    // Amount field
                    SizedBox(height: screenHeight * 0.02),
                    TextFormField(
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        hintText: 'Amount paid',
                        border: OutlineInputBorder(borderSide: BorderSide.none),
                        prefixIcon: Icon(Icons.currency_rupee),
                      ),
                      onChanged: (value) {
                        setState(() {
                          amountPaid = num.tryParse(value) ?? 0;
                        });
                      },
                    ),
                    // Payment method
                    SizedBox(height: screenHeight * 0.02),
                    Text(
                      'Order Priority',
                      style: TextStyle(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Row(
                      children: [
                        Row(
                          children: [
                            Radio<String>(
                              value: 'CASH',
                              groupValue: paymentMethod,
                              activeColor: Colors.green,
                              onChanged: (value) {
                                setState(() {
                                  paymentMethod = value!;
                                });
                              },
                            ),
                            Text(
                              'Cash',
                              style: TextStyle(fontSize: 16,color:Colors.black,fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                        SizedBox(width: screenWidth*0.05), // spacing
                        Row(
                          children: [
                            Radio<String>(
                              value: 'BANK',
                              groupValue: paymentMethod,
                              activeColor: Colors.blue,
                              onChanged: (value) {
                                setState(() {
                                  paymentMethod = value!;
                                });
                              },
                            ),
                            Text(
                              'Bank',
                              style: TextStyle(fontSize: 16,color: Colors.black,fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ],
                    )

                  ],
                ),
              ),
            ),

            // Create Order Button
          ],
        ),
      ),
    );
  }

  // App Bar
  AppBar _buildAppBar() {
    return AppBar(
      surfaceTintColor: Colors.transparent,
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      elevation: 0,
      leading: IconButton(
        icon: SvgPicture.asset(
          AppIcons.back_Arrow,
          width: screenWidth * 0.07,
          colorFilter:
              ColorFilter.mode(Theme.of(context).primaryColor, BlendMode.srcIn),
        ),
        onPressed: () => Navigator.pop(context),
      ),
      centerTitle: true,
      title: Text('Create New Order',
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(fontWeight: FontWeight.bold)),
    );
  }

  // Dealer Dialog with Search
  Future<void> _showDealerDialog(BuildContext context) async {
    final dealerAsync = ref.watch(dealerListProvider);
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          title: Center(child: const Text('Select Dealer')),
          content: SizedBox(
            width: double.maxFinite,
            child: dealerAsync.when(
              data: (dealers) {
                ValueNotifier<String> query = ValueNotifier('');
                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name or shop',
                        prefixIcon: Icon(Icons.person_search_outlined),
                      ),
                      onChanged: (val) => query.value = val.toLowerCase(),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: query,
                        builder: (_, q, __) {
                          final filtered = dealers.where((d) {
                            final name = d.employeeName.toLowerCase();
                            final shop = (d.shopName ?? '').toLowerCase();
                            return name.contains(q) || shop.contains(q);
                          }).toList();
                          if (filtered.isEmpty) {
                            return const Center(
                                child: Text('No dealers found'));
                          }
                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final dealer = filtered[i];
                              return Container(
                                margin:
                                    EdgeInsets.only(bottom: screenWidth * 0.01),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.03),
                                  border: Border.all(
                                      color: Colors.grey, width: 0.8),
                                ),
                                child: ListTile(
                                  title: Text(dealer.employeeName),
                                  subtitle:
                                      Text(dealer.shopName ?? 'No shop name'),
                                  onTap: () {
                                    setState(() {
                                      selectedDealer = dealer;
                                      selectedBrand = null;
                                      selectedProduct = null;
                                      selectedProducts.clear();
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                );
              },
              loading: () => const Center(
                heightFactor: 2,
                child: GlobalLoader(),
              ),
              error: (e, _) => Center(child: Text(e.toString())),
            ),
          ),
        );
      },
    );
  }

  // Brand Dialog with Search
  Future<void> _showBrandDialog(BuildContext context, String dealerId) async {
    final brandAsync =
        ref.watch(brandControllerProvider.notifier).getBrandsByDealer(dealerId);
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<BrandModel>>(
          future: brandAsync,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                  backgroundColor: Colors.white, content: GlobalLoader());
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Products'),
                content: Text(snapshot.error.toString()),
              );
            }
            final brands = snapshot.data ?? [];
            ValueNotifier<String> query = ValueNotifier('');

            return AlertDialog(
              backgroundColor: Colors.white,
              title: Center(child: const Text('Select Brand')),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search brand name',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) => query.value = val.toLowerCase(),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: query,
                        builder: (_, q, __) {
                          final filtered = brands
                              .where(
                                  (b) => b.brandName.toLowerCase().contains(q))
                              .toList();

                          if (filtered.isEmpty) {
                            return const Center(child: Text('No brands found'));
                          }
                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final brand = filtered[i];
                              return Container(
                                margin:
                                    EdgeInsets.only(bottom: screenWidth * 0.01),
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(
                                        screenWidth * 0.03),
                                    border: Border.all(
                                        color: Colors.grey, width: 0.8)),
                                child: ListTile(
                                  title: Text(brand.brandName),
                                  leading: SvgPicture.asset(AppIcons.brand),
                                  onTap: () {
                                    setState(() {
                                      selectedBrand = brand;
                                      // Clear products when brand changes
                                      // orderItems.clear();
                                    });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Salesman Dialog with Search
  Future<void> _showSalesmanDialog(BuildContext context) async {
    const roleSalesman = 'ROLE_SALESMAN';
    final salesmanFuture = ref.read(usersByRoleProvider(roleSalesman).future);
    TextEditingController searchController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<UserModel>>(
          future: salesmanFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                  backgroundColor: Colors.white, content: GlobalLoader());
            }
            if (snapshot.hasError) {
              return AlertDialog(
                title: const Text('Products'),
                content: Text(snapshot.error.toString()),
              );
            }

            final salesmen = snapshot.data ?? [];
            ValueNotifier<String> query = ValueNotifier('');

            return AlertDialog(
              backgroundColor: Colors.white,
              title: Center(child: const Text('Select Salesman')),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search by name or phone',
                        prefixIcon: Icon(Icons.person_search_outlined),
                      ),
                      onChanged: (val) => query.value = val.toLowerCase(),
                    ),
                    SizedBox(height: screenWidth * 0.05),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: query,
                        builder: (_, q, __) {
                          final filtered = salesmen.where((s) {
                            final name = s.employeeName.toLowerCase();
                            final phone = s.employeePhone.toLowerCase();
                            return name.contains(q) || phone.contains(q);
                          }).toList();

                          if (filtered.isEmpty) {
                            return const Center(
                                child: Text('No salesmen found'));
                          }

                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final salesman = filtered[i];
                              return Container(
                                margin:
                                    EdgeInsets.only(bottom: screenWidth * 0.01),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.03),
                                  border: Border.all(
                                      color: Colors.grey, width: 0.8),
                                ),
                                child: ListTile(
                                  title: Text(salesman.employeeName),
                                  subtitle: Text(salesman.employeePhone),
                                  onTap: () {
                                    setState(() => selectedSalesman = salesman);
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProductItem(OrderDetailsModel selectedProduct, int index) {
    // ==========================
// PRICE CALCULATION SECTION
// ==========================
    double price =
        double.tryParse(selectedProduct.product?.price?.toString() ?? "0") ?? 0;

    int qty = selectedProduct.quantity;

// Base unit price
    double unitPrice = price;

// Step 1: calculate discount per unit
    double unitDiscount = 0;
    final discount = selectedProduct.dealerDiscount;

    if (selectedProduct.useDealerDiscount && discount != null) {
      if (discount.isPercentage == true) {
        unitDiscount = unitPrice * (discount.discountValue / 100);
      } else {
        unitDiscount = discount.discountValue.toDouble();
      }
    } else if (!selectedProduct.useDealerDiscount &&
        selectedProduct.discountAmount != null) {
      unitDiscount = selectedProduct.discountAmount!.toDouble();
    }

// Step 2: calculate totals
    double subtotal = unitPrice * qty;
    double discountAmount = unitDiscount * qty;
    double total = subtotal - discountAmount;

    return Card(
      color: Colors.white,
      margin: EdgeInsets.symmetric(
          horizontal: screenWidth * 0.05, vertical: screenWidth * 0.01),
      child: Padding(
        padding: EdgeInsets.all(screenWidth * 0.04),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product Info
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        selectedProduct.product?.brand?.toString() ??
                            selectedProduct.productBrand,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        selectedProduct.product?.productName?.toString() ??
                            selectedProduct.productName,
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            selectedProduct.product?.model?.toString() ??
                                selectedProduct.productModel,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: screenWidth * 0.02),
                          Text(
                            selectedProduct.product?.productType?.toString() ??
                                selectedProduct.productType,
                            style: TextStyle(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                      Text(
                        "PRICE: ${selectedProduct.product?.price?.toString() ?? selectedProduct.productPrice?.toString() ?? 'N/A'}",
                        style: TextStyle(
                          color: Colors.black,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: SvgPicture.asset(
                    AppIcons.delete,
                    colorFilter: ColorFilter.mode(Colors.red, BlendMode.srcIn),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedProducts.removeAt(index);
                    });
                  },
                ),
              ],
            ),

            SizedBox(height: screenHeight * 0.015),
            // Quantity
            const Text(
              'Quantity:',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            SizedBox(height: screenHeight * 0.015),
            Row(
              children: [
                GestureDetector(
                  onTap: () {
                    if (selectedProduct.quantity > 1) {
                      setState(() {
                        selectedProducts[index] = selectedProduct.copyWith(
                          qtyOrdered: selectedProduct.quantity - 1,
                        );
                      });
                    }
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.015,
                        vertical: screenWidth * 0.01),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        border: Border.all(width: 1, color: Colors.grey)),
                    child: Icon(Icons.remove),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                Container(
                  padding: EdgeInsets.symmetric(
                      horizontal: screenWidth * 0.05,
                      vertical: screenWidth * 0.01),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(screenWidth * 0.02)),
                  child: Text(
                    selectedProduct.quantity.toString(),
                    style: const TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
                SizedBox(width: screenWidth * 0.02),
                GestureDetector(
                  onTap: () {
                    setState(() {
                      selectedProducts[index] = selectedProduct.copyWith(
                        qtyOrdered: selectedProduct.quantity + 1,
                      );
                    });
                  },
                  child: Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: screenWidth * 0.015,
                        vertical: screenWidth * 0.01),
                    decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(screenWidth * 0.02),
                        border: Border.all(width: 1, color: Colors.grey)),
                    child: Icon(Icons.add),
                  ),
                ),
              ],
            ),
            // Scheme Toggle
            Row(
              children: [
                const Text('Scheme:',
                    style: TextStyle(
                      color: Colors.black,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    )),
                Spacer(),
                Switch(
                  value: selectedProduct.isScheme,
                  activeColor: Colors.white,
                  activeTrackColor: Colors.black,
                  inactiveThumbColor: Colors.white,
                  inactiveTrackColor: Colors.grey.shade300,
                  trackOutlineColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.selected)) {
                        return Colors.black; // Border when ON
                      }
                      return Colors.grey.shade300; // Border when OFF
                    },
                  ),
                  trackOutlineWidth: WidgetStateProperty.all(2.0),
                  onChanged: (value) {
                    setState(() {
                      selectedProducts[index] = selectedProduct.copyWith(
                        isProductScheme: value,
                      );
                    });
                  },
                )
              ],
            ),
            // Discount Options
            if (selectedDealer != null)
              _buildDiscountOptions(selectedProduct, index),
            SizedBox(
              height: screenHeight * 0.01,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 0,
                side: BorderSide(color: Colors.grey, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(screenWidth * 0.03),
                ),
              ),
              onPressed: () async {
                DateTime? pickedDate = await showDatePicker(
                  context: context,
                  initialDate: selectedProduct.deliveryDate ?? DateTime.now(),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (pickedDate != null) {
                  setState(() {
                    selectedProducts[index] = selectedProduct.copyWith(
                      deliveryDate: pickedDate,
                    );
                  });
                }
              },
              child: Row(
                children: [
                  SizedBox(width: screenWidth * 0.02),
                  Icon(Icons.calendar_month),
                  SizedBox(width: screenWidth * 0.02),
                  Text(
                    selectedProduct.deliveryDate != null
                        ? "${selectedProduct.deliveryDate!.day}/${selectedProduct.deliveryDate!.month}/${selectedProduct.deliveryDate!.year}"
                        : "Select Date",
                    style: const TextStyle(fontSize: 16),
                  ),
                ],
              ),
            ),
            if (!selectedProduct.isProductScheme && selectedProduct.deliveryDate == null)
              Text(
                "⚠ Delivery date required",
                style: TextStyle(color: Colors.red, fontSize: 12),
              ),
            Divider(),
            if (selectedProduct.isProductScheme == false)
              Column(
                children: [
                  SizedBox(height: screenHeight * 0.01),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Subtotal", style: TextStyle(fontSize: 14)),
                      Text(subtotal.toStringAsFixed(2),
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        (selectedProduct.useDealerDiscount &&
                                discount?.isPercentage == true)
                            ? "Discount (${discount?.discountValue}%)"
                            : "Discount",
                        style: const TextStyle(fontSize: 14),
                      ),
                      Text("- ${discountAmount.toStringAsFixed(2)}",
                          style: const TextStyle(fontSize: 14)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text("Total",
                          style: TextStyle(
                              fontSize: 16, fontWeight: FontWeight.bold)),
                      Text(
                        total.toStringAsFixed(2),
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: screenHeight * 0.01),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDiscountOptions(OrderDetailsModel selectedProduct, int index) {
    print('🟡 selectedDealer: ${selectedDealer?.employeeId}');
    print(
        '🟡 selectedProductId: ${selectedProduct.productId}'); // Use productId directly, not product.productId

    final discount = selectedProduct.dealerDiscount;

    // 🔹 If product is scheme → hide everything, use dealer discount by default
    if (selectedProduct.isScheme) {
      if (discount != null && selectedProduct.useDealerDiscount != true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          setState(() {
            selectedProducts[index] = selectedProduct.copyWith(
              useDealerDiscount: true,
              discountAmount: null,
              dealerDiscountId: discount.dealerDiscountId,
            );
          });
        });
      }
      return const SizedBox.shrink(); // nothing shows
    }

    // 🔹 No dealer discount found → manual input
    if (discount == null) {
      print('⚠️ No dealer discount found — showing manual discount input');
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Discount Amount:'),
          const SizedBox(height: 8),
          SizedBox(
            width: screenWidth * 0.4,
            child: TextFormField(
              initialValue: selectedProduct.discountAmount?.toString() ?? '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'discount amount',
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                print('📝 Manual discount entered: $value');
                setState(() {
                  selectedProducts[index] = selectedProduct.copyWith(
                    discountAmount: num.tryParse(value),
                    useDealerDiscount: false,
                  );
                });
              },
            ),
          ),
        ],
      );
    }

    // 🔹 Dealer discount exists
    print(
        '🎯 Dealer discount available -> ID: ${discount.dealerDiscountId}, Value: ${discount.discountValue}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Discount Option:',
            style: TextStyle(
              color: Colors.black,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            )),
        SizedBox(height: screenWidth * 0.02),
        Row(
          children: [
            Expanded(
                child: RadioListTile<bool>(
              title: Text(
                'Manual Discount',
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.black,
                    fontWeight: FontWeight.bold),
              ),
              value: false,
              dense: true,
              activeColor: Theme.of(context).primaryColor,
              visualDensity: VisualDensity.compact,
              // makes it even smaller
              groupValue: selectedProduct.useDealerDiscount,
              onChanged: (value) {
                print('🔘 Manual discount selected');
                setState(() {
                  selectedProducts[index] = selectedProduct.copyWith(
                    useDealerDiscount: false,
                    dealerDiscountId: null,
                  );
                });
              },
            )),
            Expanded(
              child: RadioListTile<bool>(
                title: const Text(
                  'Dealer Discount',
                  style: TextStyle(
                      fontSize: 12,
                      color: Colors.black,
                      fontWeight: FontWeight.bold),
                ),
                value: true,
                activeColor: Theme.of(context).primaryColor,
                groupValue: selectedProduct.useDealerDiscount,
                onChanged: (value) {
                  print('🔘 Dealer discount selected');
                  setState(() {
                    selectedProducts[index] = selectedProduct.copyWith(
                      useDealerDiscount: true,
                      discountAmount: null,
                      dealerDiscountId: discount.dealerDiscountId,
                    );
                  });
                },
              ),
            ),
          ],
        ),
        if (!selectedProduct.useDealerDiscount) ...[
          SizedBox(height: screenHeight * 0.01),
          SizedBox(
            width: screenWidth * 0.4,
            child: TextFormField(
              initialValue: selectedProduct.discountAmount?.toString() ?? '',
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: 'Enter discount amount',
                border: OutlineInputBorder(
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (value) {
                print('✏️ Manual discount field updated: $value');
                setState(() {
                  selectedProducts[index] = selectedProduct.copyWith(
                    discountAmount: num.tryParse(value),
                  );
                });
              },
            ),
          ),
        ],
        if (selectedProduct.useDealerDiscount) ...[
          SizedBox(height: screenHeight * 0.01),
          Card(
            color: Colors.white,
            child: ListTile(
              title: Text(
                '${discount.isPercentage == false ? '₹' : ''}${discount.discountValue}${discount.isPercentage ? '%' : ''}',
              ),
            ),
          ),
        ],
      ],
    );
  }

  // Update the product dialog to add to list
  Future<void> _showProductDialog(
      BuildContext context, List<String> brands) async {
    final productAsync = ref
        .watch(productControllerProvider.notifier)
        .fetchProductsByBrand(brands);
    TextEditingController searchController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) {
        return FutureBuilder<List<ProductModel>>(
          future: productAsync,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const AlertDialog(
                  backgroundColor: Colors.white, content: GlobalLoader());
            }
            if (snapshot.hasError) {
              return AlertDialog(
                backgroundColor: Colors.white,
                title: const Text('Products'),
                content: Text(snapshot.error.toString()),
              );
            }
            final products = snapshot.data ?? [];
            ValueNotifier<String> query = ValueNotifier('');
            return AlertDialog(
              backgroundColor: Colors.white,
              title: Center(child: const Text('Select Product')),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: searchController,
                      decoration: const InputDecoration(
                        hintText: 'Search product name or model',
                        prefixIcon: Icon(Icons.search),
                      ),
                      onChanged: (val) => query.value = val.toLowerCase(),
                    ),
                    SizedBox(height: screenHeight * 0.03),
                    Expanded(
                      child: ValueListenableBuilder<String>(
                        valueListenable: query,
                        builder: (_, q, __) {
                          final filtered = products.where((p) {
                            final name = p.productName?.toLowerCase() ?? '';
                            final model = p.model?.toLowerCase() ?? '';
                            return name.contains(q) || model.contains(q);
                          }).toList();

                          if (filtered.isEmpty) {
                            return const Center(
                                child: Text('No products found'));
                          }
                          return ListView.builder(
                            itemCount: filtered.length,
                            itemBuilder: (_, i) {
                              final product = filtered[i];
                              return Container(
                                margin:
                                    EdgeInsets.only(bottom: screenWidth * 0.01),
                                decoration: BoxDecoration(
                                  borderRadius:
                                      BorderRadius.circular(screenWidth * 0.03),
                                  border: Border.all(
                                      color: Colors.grey, width: 0.8),
                                ),
                                child: ListTile(
                                  leading: SvgPicture.asset(
                                    AppIcons.product,
                                    colorFilter: ColorFilter.mode(
                                        Theme.of(context).primaryColor,
                                        BlendMode.srcIn),
                                  ),
                                  title: Text(product.productName.toString()),
                                  subtitle: Text(product.model.toString()),
                                  trailing: _isProductAlreadyAdded(product)
                                      ? Icon(Icons.check,
                                          color: Theme.of(context).primaryColor)
                                      : null,
                                  onTap: () async {
                                      DealerDiscountModel? discount;
                                      try {
                                        discount = await ref.read(
                                            dealerProductDiscountProvider({
                                          'dealerId':
                                              selectedDealer!.employeeId!,
                                          'productId': product.productId!,
                                        }).future);
                                      } catch (e) {
                                        print('Error fetching discount: $e');
                                      }

                                      setState(() {
                                        // ✅ USE fromProduct factory method
                                        selectedProducts
                                            .add(OrderDetailsModel.fromProduct(
                                          product,
                                          dealerDiscount: discount,
                                        ));
                                      });
                                    Navigator.pop(context);
                                  },
                                ),
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  bool _isProductAlreadyAdded(ProductModel product) {
    return selectedProducts
        .any((sp) => sp.product?.productId == product.productId);
  }

  bool _canCreateOrder() {
    // Basic validation
    if (selectedDealer == null ||
        selectedSalesman == null ||
        selectedProducts.isEmpty ||
        amountPaid < 0) {
      return false;
    }

    // Delivery date validation (skip scheme items because they are free)
    final missingDate = selectedProducts.any((p) =>
    p.isProductScheme != true && p.deliveryDate == null);

    if (missingDate) return false;

    return true;
  }


  void _createOrder() async {
    // 🔍 VALIDATION FIRST – do NOT start loading yet
    final missingDeliveryDate = selectedProducts.any(
          (p) => !p.isProductScheme && p.deliveryDate == null,
    );

    if (missingDeliveryDate) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please select delivery date for all products"),
        ),
      );
      return; // ⛔ stops execution
    }

    // Now safe to show loader
    setState(() => isCreatingOrder = true);

    try {
      final order = OrderModel(
        dealerId: selectedDealer!.employeeId!,
        priority: selectedPriority,
        orderNote: orderNoteController.text,
        salesmanId: selectedSalesman!.employeeId!,
        paymentType: paymentMethod,
        amountPaid: amountPaid,
        orderDetails: selectedProducts,
      );

      print('Creating order: ${order.toJson()}');

      await ref.read(orderControllerProvider.notifier).createOrder(order);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 20),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Order created successfully!',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          backgroundColor: Colors.green[700],
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          margin: EdgeInsets.all(16),
        ),
      );

      // Refresh & exit
      await ref.read(orderControllerProvider.notifier).getAllOrders();
      if (mounted) Navigator.pop(context);
    } catch (e, s) {
      debugPrint('❌ Error creating order: $e\n$s');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to create order: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => isCreatingOrder = false);
    }
  }


  double _calculateOrderTotal() {
    double grandTotal = 0;

    for (var p in selectedProducts) {
      if (p.isProductScheme == true) {
        continue; // skip free products
      }

      double unitPrice =
          double.tryParse(p.product?.price?.toString() ?? "0") ?? 0;
      int qty = p.quantity;

      double unitDiscount = 0;
      final discount = p.dealerDiscount;

      // Dealer discount per unit
      if (p.useDealerDiscount && discount != null) {
        if (discount.isPercentage == true) {
          unitDiscount = unitPrice * (discount.discountValue / 100);
        } else {
          unitDiscount = discount.discountValue.toDouble();
        }
      }
      // Manual per-unit discount
      else if (!p.useDealerDiscount && p.discountAmount != null) {
        unitDiscount = p.discountAmount!.toDouble();
      }

      double itemTotal = (unitPrice - unitDiscount) * qty;

      grandTotal += itemTotal;
    }

    return grandTotal;
  }

}
